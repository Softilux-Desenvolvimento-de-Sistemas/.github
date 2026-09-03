#!/usr/bin/env bash
#
# Deploy de produção da Softilux. Roda NA VM, como o usuário `deploy`, disparado
# por um runner self-hosted — ou à mão, pelo SSH, com as mesmas variáveis.
#
# ⚠️ Este script é o PIPELINE. O workflow que o chama é só o gatilho.
#
# Ele não sabe o que é pnpm, npm, Prisma ou TypeORM: o contrato é o **projeto
# compose** da aplicação, e tudo que é específico de stack mora no Dockerfile e
# no compose do app. A invariante que sustenta isso:
#
#   se este script precisar mudar para receber uma aplicação nova, o CONTRATO
#   estava errado, e a correção vai no contrato — nunca num `if` por app.
#
# O padrão inteiro (contrato, checklist de app nova, limites) está em
# devs/engineering/deploy-standard.md deste repositório.
#
# A ordem das fases existe para que a falha aconteça ANTES de produção trocar de
# versão:
#
#   config → disco → build → CVE → healthcheck → migrate → up → health → estado
#            └─ falhou? nada subiu           └─ falhou? api e worker não sobem
#
# ⚠️ Rollback reverte IMAGEM, nunca MIGRATION. É por isso que toda migration tem
# que funcionar com a versão anterior do código: imagem tem rollback trivial,
# banco não tem.

set -euo pipefail

# ─── Entrada ─────────────────────────────────────────────────────────────────
#
# Vem da action por `env:`, ou do shell quando alguém roda pelo SSH. Nunca
# interpolada de `${{ }}`: input de `workflow_dispatch` é texto de quem aperta o
# botão, e dentro de shell isso seria injeção de comando.

MODE=${DEPLOY_MODE:-deploy}                       # deploy | dry-run | doctor
SHA_INPUT=${DEPLOY_SHA:-}                         # preenchido = ROLLBACK
CONFIG_FILE=${DEPLOY_CONFIG:-deploy.conf}
SKIP_SCAN=${DEPLOY_SKIP_SCAN:-false}
HEALTH_TIMEOUT=${DEPLOY_HEALTH_TIMEOUT:-120}
LOCK_WAIT=${DEPLOY_LOCK_WAIT:-1800}
KEEP_IMAGES=${DEPLOY_KEEP_IMAGES:-5}
MIN_FREE_DISK=${DEPLOY_MIN_FREE_DISK:-15}

# ⚠️ O estado do deploy vive FORA da árvore de trabalho, e isso não é
# preferência: `.current-tag` dentro do repositório faz o próprio deploy sujar a
# árvore, e o deploy seguinte recusa subir de árvore suja. O primeiro funciona, o
# segundo falha — e cada repositório novo reintroduziria o bug.
STATE_ROOT=${DEPLOY_STATE_ROOT:-/srv/.deploy}
LOCK_FILE=$STATE_ROOT/deploy.lock

for pair in "HEALTH_TIMEOUT=$HEALTH_TIMEOUT" "LOCK_WAIT=$LOCK_WAIT" \
	"KEEP_IMAGES=$KEEP_IMAGES" "MIN_FREE_DISK=$MIN_FREE_DISK"; do
	[[ ${pair#*=} =~ ^[0-9]+$ ]] || {
		printf 'input %s tem que ser um número inteiro\n' "${pair%%=*}" >&2
		exit 1
	}
done

readonly COMPOSE_MIN=2.20
readonly CONF_KEYS=(COMPOSE_FILE ENV_FILE MIGRATE_SERVICE HEALTH_SERVICES BRANCH CHECKLIST_FILE)
readonly CONF_REQUIRED=(ENV_FILE MIGRATE_SERVICE HEALTH_SERVICES)

# ─── Saída ───────────────────────────────────────────────────────────────────

PHASE=entrada
SUMMARY=$(mktemp)
WARN_FILE=$(mktemp)
CONFIG_JSON=""
WARNINGS=0

log()   { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
md()    { printf '%s\n' "$*" >> "$SUMMARY"; }
phase() { PHASE=$1; }

# Aviso vai para um arquivo próprio: ele pode acontecer em qualquer fase, e no
# resumo tem que aparecer DEPOIS da tabela, não no meio dela.
warn() {
	WARNINGS=$((WARNINGS + 1))
	printf '\033[1;33m! %s\033[0m\n' "$*" >&2
	printf -- '- %s\n' "$*" >> "$WARN_FILE"
}

fail() {
	printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2
	md "- ❌ **falhou na fase \`$PHASE\`:** $*"
	exit 1
}

# Job cancelado, ou `timeout-minutes` estourando, mata o processo no meio. Sem
# isto, "produção em estado indefinido" e "morreu entre o migrate e o up -d"
# ficam indistinguíveis depois do fato.
on_signal() {
	printf '\n\033[1;31m✗ interrompido na fase %s\033[0m\n' "$PHASE" >&2
	[[ -n ${STATE_DIR:-} ]] && printf '%s\t%s\tinterrompido\n' "$(date -Iseconds)" "$PHASE" >> "$STATE_DIR/phase"
	exit 130
}

flush_summary() {
	if [[ -s $WARN_FILE ]]; then
		md ""
		md "### Avisos ($WARNINGS)"
		md ""
		cat "$WARN_FILE" >> "$SUMMARY"
	fi

	[[ -n ${GITHUB_STEP_SUMMARY:-} && -s $SUMMARY ]] && cat "$SUMMARY" >> "$GITHUB_STEP_SUMMARY"

	rm -f "$SUMMARY" "$WARN_FILE" ${CONFIG_JSON:+"$CONFIG_JSON"}
	return 0
}

trap on_signal TERM INT
trap flush_summary EXIT

# ─── Onde este script roda ───────────────────────────────────────────────────
#
# ⚠️ Runner hospedado não tem a VM, não tem o `.env.prod` e não tem as imagens.
# Alguém vai copiar o workflow trocando o `runs-on` por `ubuntu-latest`, e o erro
# que apareceria sem esta guarda seria "arquivo não encontrado".
[[ ${RUNNER_ENVIRONMENT:-} != github-hosted ]] ||
	fail "este deploy só roda em runner self-hosted na VM. Corrija o \`runs-on\` do workflow."

# ─── doctor: as pré-condições da MÁQUINA ─────────────────────────────────────
#
# ⚠️ Rode isto pelo runner (workflow_dispatch), não pelo seu shell: o PATH do
# serviço systemd não é o do login, e "trivy não instalado" com o trivy
# instalado é o erro mais confuso do conjunto.
if [[ $MODE == doctor ]]; then
	phase doctor
	log "Pré-condições da máquina"
	md '## Doctor'

	rc=0
	check() {
		local label=$1 detail=$2 ok=$3
		if [[ $ok == ok ]]; then
			printf '  \033[1;32m✓\033[0m %-22s %s\n' "$label" "$detail"
			md "- ✅ \`$label\` — $detail"
		else
			printf '  \033[1;31m✗\033[0m %-22s %s\n' "$label" "$detail"
			md "- ❌ \`$label\` — $detail"
			rc=1
		fi
	}

	for bin in docker git flock jq trivy; do
		if path=$(command -v "$bin"); then
			check "$bin" "$path" ok
		else
			check "$bin" "não está no PATH deste processo" no
		fi
	done

	if compose_version=$(docker compose version --short 2>/dev/null) && [[ -n $compose_version ]]; then
		if [[ $(printf '%s\n%s\n' "$COMPOSE_MIN" "$compose_version" | sort -V | head -1) == "$COMPOSE_MIN" ]]; then
			check "docker compose" "$compose_version (mínimo $COMPOSE_MIN)" ok
		else
			check "docker compose" "$compose_version é abaixo do mínimo $COMPOSE_MIN" no
		fi
	else
		check "docker compose" "plugin v2 ausente (\`docker compose\`, sem hífen)" no
	fi

	if docker info >/dev/null 2>&1; then
		check "socket do docker" "alcançável por $(id -un)" ok
	else
		check "socket do docker" "inalcançável — $(id -un) está no grupo docker?" no
	fi

	if [[ -n $(swapon --show --noheadings 2>/dev/null) ]]; then
		check swap "$(swapon --show=SIZE --noheadings | paste -sd, -)" ok
	else
		check swap "ausente — o pico do build morre por OOM sem dizer que é memória" no
	fi

	if [[ -d $STATE_ROOT && -w $STATE_ROOT ]]; then
		check "$STATE_ROOT" "existe e é gravável" ok
	else
		check "$STATE_ROOT" "crie: sudo install -d -o $(id -un) -g $(id -gn) -m 755 $STATE_ROOT" no
	fi

	# O PATH inteiro, uma vez e no fim: é a informação que resolve o caso
	# "instalei e ele não vê", e é ilegível repetida em cada linha.
	printf '\n  PATH deste processo:\n'
	printf '%s\n' "$PATH" | tr ':' '\n' | sed 's/^/    /'

	if ((rc != 0)); then
		md ""
		md "> Falta coisa na máquina. O PATH acima é o do **serviço systemd do runner**, não o do seu login — se você instalou e ele não vê, acrescente ao \`.env\` do diretório do runner."
	fi

	exit $rc
fi

# ─── O diretório da aplicação ────────────────────────────────────────────────
#
# Convenção: /srv/<nome-do-repositório>. É o que permite o workflow chamador não
# ter nenhuma string específica da aplicação além da label da máquina.
if [[ -n ${DEPLOY_ROOT:-} ]]; then
	ROOT=$DEPLOY_ROOT
elif [[ -n ${GITHUB_REPOSITORY:-} ]]; then
	ROOT=/srv/${GITHUB_REPOSITORY##*/}
else
	ROOT=$PWD
fi

phase pre-condições

cd "$ROOT" 2>/dev/null || fail "$ROOT não existe. Clone o repositório lá, como o usuário do deploy."
git rev-parse --git-dir >/dev/null 2>&1 || fail "$ROOT não é um repositório git. Produção sobe de commit, e só."

for bin in docker git jq; do
	command -v "$bin" >/dev/null || fail "$bin não está no PATH deste processo. Rode o modo doctor."
done

# ⚠️ Trava que se degrada sozinha não é trava. Sem `flock`, ou sem o diretório de
# estado, o deploy PARA — não cai para uma trava dentro do diretório do app, que
# não protegeria contra o deploy de outra aplicação na mesma máquina.
command -v flock >/dev/null || fail "flock não encontrado (util-linux). Sem ele não há um deploy por vez."
[[ -d $STATE_ROOT && -w $STATE_ROOT ]] ||
	fail "$STATE_ROOT não existe ou não é gravável. Rode o modo doctor."

# ─── deploy.conf: os fatos do repositório ────────────────────────────────────
#
# Fatos do repositório vêm daqui, ao lado do compose que eles descrevem; política
# da invocação vem dos inputs da action. Renomear um serviço e atualizar a
# declaração acontecem no mesmo diff.
declare -A CONF=()

[[ -f $CONFIG_FILE ]] ||
	fail "$CONFIG_FILE não existe. Ele é o marcador de que este repositório aderiu ao padrão de deploy — ausência não vira default."

lineno=0
while IFS= read -r line || [[ -n $line ]]; do
	lineno=$((lineno + 1))
	line=${line%$'\r'}

	[[ -z ${line//[[:space:]]/} || ${line:0:1} == "#" ]] && continue
	[[ $line == *=* ]] || fail "$CONFIG_FILE:$lineno: linha sem '=' — $line"

	key=${line%%=*}
	value=${line#*=}

	[[ $key =~ ^[A-Z][A-Z0-9_]*$ ]] || fail "$CONFIG_FILE:$lineno: chave inválida '$key'"

	# ⚠️ Chave desconhecida é ERRO, não aviso: `HEALTH_SERVICE=api` (singular)
	# com aviso deixaria HEALTH_SERVICES vazio, e o gate de saúde se desligaria
	# sozinho — que é exatamente o modo de falha que este padrão existe para
	# evitar.
	[[ " ${CONF_KEYS[*]} " == *" $key "* ]] ||
		fail "$CONFIG_FILE:$lineno: chave desconhecida '$key'. Conhecidas: ${CONF_KEYS[*]}"

	# Não há interpolação aqui de propósito: este arquivo é lido, nunca
	# executado.
	[[ $value != *'$'* ]] || fail "$CONFIG_FILE:$lineno: '\$' não é permitido — não há expansão neste arquivo"
	[[ $value =~ ^[A-Za-z0-9._/\ -]*$ ]] || fail "$CONFIG_FILE:$lineno: valor com caractere não permitido"

	CONF[$key]=$value
done < "$CONFIG_FILE"

# Vazio explícito ≠ ausente. `MIGRATE_SERVICE=` significa "esta aplicação não tem
# migration", e isso fica escrito no log; chave ausente é erro.
for key in "${CONF_REQUIRED[@]}"; do
	[[ -v CONF[$key] ]] || fail "$CONFIG_FILE: falta a chave obrigatória '$key' (pode ser vazia, mas tem que estar declarada)"
done

COMPOSE_FILE=${CONF[COMPOSE_FILE]:-docker-compose-prod.yml}
ENV_FILE=${CONF[ENV_FILE]}
MIGRATE_SERVICE=${CONF[MIGRATE_SERVICE]}
HEALTH_SERVICES=${CONF[HEALTH_SERVICES]}
BRANCH=${CONF[BRANCH]:-main}
CHECKLIST_FILE=${CONF[CHECKLIST_FILE]:-deploy-checklist.md}

[[ -f $COMPOSE_FILE ]] || fail "$COMPOSE_FILE não está em $ROOT"
[[ -n $HEALTH_SERVICES ]] || fail "$CONFIG_FILE: HEALTH_SERVICES vazio — sem serviço para conferir, o deploy não tem como saber se subiu"

compose_args=(-f "$COMPOSE_FILE")

if [[ -n $ENV_FILE ]]; then
	[[ -f $ENV_FILE ]] || fail "$ENV_FILE não existe. Copie o .env.prod.example e preencha."

	# Regra literal do handbook: um arquivo de ambiente legível por todos entrega
	# senha de banco e chave de API para qualquer processo do host.
	perms=$(stat -c '%a' "$ENV_FILE")
	[[ $perms == 600 ]] || fail "$ENV_FILE está $perms. Corrija: chmod 600 $ENV_FILE"

	# ⚠️ `--env-file` é OBRIGATÓRIO e não é conveniência: `env_file:` (runtime) e
	# interpolação `${...}` (parse) são coisas diferentes. Sem a flag, o compose
	# procura um `.env` que não existe e aborta com "defina SFX_DOMAIN".
	compose_args=(--env-file "$ENV_FILE" "${compose_args[@]}")
fi

compose() { docker compose "${compose_args[@]}" "$@"; }

# ─── Que versão vai subir ────────────────────────────────────────────────────

phase versão

STATE_DIR=$STATE_ROOT/${ROOT##*/}
mkdir -p "$STATE_DIR"
TAG_FILE=$STATE_DIR/current-tag
LOG_FILE=$STATE_DIR/deploy-log.jsonl

PREVIOUS=$(cat "$TAG_FILE" 2>/dev/null || echo "")

if [[ -n $SHA_INPUT ]]; then
	ROLLBACK=1
	GIT_SHA=$SHA_INPUT

	[[ $GIT_SHA =~ ^[0-9a-f]{7,40}$ ]] || fail "'$GIT_SHA' não é um SHA de git"

	log "ROLLBACK para $GIT_SHA (no ar: ${PREVIOUS:-desconhecido})"
else
	ROLLBACK=0

	# ⚠️ Sem esta checagem, um `git checkout` esquecido numa feature branch faz o
	# `git pull --ff-only` seguir a branch errada e deployá-la em silêncio.
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	[[ $current_branch == "$BRANCH" ]] ||
		fail "$ROOT está na branch '$current_branch', e o deploy é da '$BRANCH'. Produção não sobe de branch de trabalho."

	# Árvore suja aqui significa alguém editando em produção por SSH: o que
	# subisse não teria SHA que o descrevesse, e o rollback mentiria.
	[[ -z $(git status --porcelain) ]] ||
		fail "árvore de trabalho suja em $ROOT. Produção sobe do que está commitado, e só."

	if [[ $MODE == dry-run ]]; then
		info "dry-run: sem \`git pull\`; conferindo o HEAD que já está aqui"
	else
		log "Buscando a $BRANCH"
		git pull --ff-only
	fi

	GIT_SHA=$(git rev-parse --short HEAD)
fi

export GIT_SHA

# ─── Portão de configuração e derivação ──────────────────────────────────────

phase configuração

# ⚠️ Primeiro portão, e o mais barato: `config -q` interpola tudo. Variável de
# `.env.prod` faltando com guarda `${VAR:?}` falha AQUI, antes do build, em vez
# de virar string vazia e reaparecer como erro de runtime.
compose config -q ||
	fail "o compose de produção não valida. Normalmente é variável faltando no $ENV_FILE."

CONFIG_JSON=$(mktemp)
compose config --format json > "$CONFIG_JSON"

PROJECT=$(jq -r '.name' "$CONFIG_JSON")
mapfile -t SERVICES < <(jq -r '.services | keys[]' "$CONFIG_JSON")

# O que ESTA máquina construiu — é o que se escaneia, o que se exige no rollback
# e o que a retenção protege. Deriva do contrato "imagem construída é tagueada
# com o SHA": `redis:7-alpine` não casa, `softilux/api:<sha>` casa.
mapfile -t BUILT_IMAGES < <(
	jq -r --arg sha "$GIT_SHA" \
		'.services | to_entries[] | select(.value.build != null) | .value.image
		 | select(endswith(":" + $sha))' "$CONFIG_JSON" | sort -u
)
mapfile -t THIRD_PARTY < <(
	jq -r '.services | to_entries[] | select(.value.build == null) | .value.image' "$CONFIG_JSON" | sort -u
)

((${#BUILT_IMAGES[@]})) ||
	fail "nenhuma imagem construída está tagueada com o SHA. O contrato exige image: <nome>:\${GIT_SHA:?...} nos serviços com build."

log "Fatos derivados"
info "projeto compose ... $PROJECT"
info "versão .......... $GIT_SHA$([[ $ROLLBACK == 1 ]] && echo ' (rollback)')"
info "construídas ..... ${BUILT_IMAGES[*]}"
info "terceiros ....... ${THIRD_PARTY[*]:-nenhuma}"
info "migration ....... ${MIGRATE_SERVICE:-nenhuma}"
info "saúde ........... $HEALTH_SERVICES"

# ─── Lint de política: o que fere recurso compartilhado ──────────────────────
#
# Aviso hoje, erro na v2. São todas proteções de VM compartilhada: um app sem
# `mem_limit` derruba os vizinhos por OOM, e um sem rotação de log enche o disco
# de todos.
phase lint

while read -r svc; do
	[[ -n $svc ]] || continue
	warn "serviço '$svc' publica porta no host — quem publica porta é a borda compartilhada"
done < <(jq -r '.services | to_entries[] | select((.value.ports // []) | length > 0) | .key' "$CONFIG_JSON")

while read -r svc; do
	[[ -n $svc ]] || continue
	warn "serviço '$svc' sem mem_limit — sem teto, ele leva a VM inteira num pico"
done < <(jq -r '.services | to_entries[] | select(.value.mem_limit == null and .value.deploy == null) | .key' "$CONFIG_JSON")

while read -r svc; do
	[[ -n $svc ]] || continue
	warn "serviço '$svc' com privileged: true"
done < <(jq -r '.services | to_entries[] | select(.value.privileged == true) | .key' "$CONFIG_JSON")

for svc in $HEALTH_SERVICES $MIGRATE_SERVICE; do
	[[ " ${SERVICES[*]} " == *" $svc "* ]] ||
		fail "o serviço '$svc' declarado em $CONFIG_FILE não existe em $COMPOSE_FILE. Serviços: ${SERVICES[*]}"
done

# Mecaniza o item "env vars novas já configuradas no ambiente de destino" do
# checklist do handbook. Só nomes de chave — nunca valor.
if [[ -n $ENV_FILE && -f $ENV_FILE.example ]]; then
	missing=$(comm -23 \
		<(grep -oE '^[A-Z][A-Z0-9_]*=' "$ENV_FILE.example" | tr -d '=' | sort -u) \
		<(grep -oE '^[A-Z][A-Z0-9_]*=' "$ENV_FILE" | tr -d '=' | sort -u) | paste -sd, -)
	[[ -z $missing ]] || warn "chaves no $ENV_FILE.example que não estão no $ENV_FILE: $missing"
fi

# ─── Declaração de saúde ─────────────────────────────────────────────────────
#
# ⚠️ `docker compose config` NUNCA abre imagem, então um `HEALTHCHECK` de
# Dockerfile é invisível para ele — é por isso que HEALTH_SERVICES é declarado, e
# não derivado. Aqui se confere que o que foi declarado tem de fato healthcheck:
# sem isto, um serviço sem healthcheck reporta `running` para sempre, o loop gira
# até o timeout e a mensagem não explica nada.
#
# `strict` porque a checagem da IMAGEM só é possível depois do build: no dry-run
# a imagem pode ainda não existir, e aí vira aviso em vez de erro.
check_health_declarations() {
	local strict=$1 svc disabled has_compose_hc image has_image_hc

	for svc in $HEALTH_SERVICES; do
		disabled=$(jq -r --arg s "$svc" '.services[$s].healthcheck.disable // false' "$CONFIG_JSON")
		[[ $disabled != true ]] ||
			fail "'$svc' está em HEALTH_SERVICES e tem healthcheck.disable: true no compose. Escolha um dos dois."

		has_compose_hc=$(jq -r --arg s "$svc" '.services[$s].healthcheck.test // empty' "$CONFIG_JSON")
		[[ -z $has_compose_hc ]] || continue

		image=$(jq -r --arg s "$svc" '.services[$s].image' "$CONFIG_JSON")
		has_image_hc=$(docker image inspect "$image" --format '{{if .Config.Healthcheck}}ok{{end}}' 2>/dev/null || echo "")

		[[ $has_image_hc == ok ]] && continue

		if docker image inspect "$image" >/dev/null 2>&1 || [[ $strict == strict ]]; then
			fail "'$svc' não tem HEALTHCHECK (nem na imagem $image, nem no compose). Acrescente um, ou tire o serviço de HEALTH_SERVICES — o deploy não tem como saber se ele subiu."
		fi

		warn "não deu para conferir o HEALTHCHECK de '$svc': $image ainda não existe nesta máquina. O deploy de verdade confere depois do build."
	done
}

phase healthcheck
check_health_declarations frouxo

# ─── Trava da máquina ────────────────────────────────────────────────────────
#
# ⚠️ É da MÁQUINA, não do diretório: com um runner por repositório, o GitHub não
# serializa mais nada entre aplicações, e dois `next build` simultâneos disputam
# a memória da VM — que é o pico do ciclo inteiro.
#
# `-w` e não `-n`: com fila do GitHub fora do caminho, recusar na hora
# transformaria "dois merges juntos" em "uma aplicação não subiu".
if [[ $MODE != dry-run ]]; then
	phase trava

	exec {lock_fd}>"$LOCK_FILE"

	if ! flock -n "$lock_fd"; then
		holder=$(cat "$LOCK_FILE" 2>/dev/null || echo "desconhecido")
		log "Esperando a trava da máquina (até ${LOCK_WAIT}s) — em curso: $holder"
		flock -w "$LOCK_WAIT" "$lock_fd" ||
			fail "a trava da máquina não liberou em ${LOCK_WAIT}s. Em curso: $holder"
	fi

	printf '%s pid=%s desde=%s\n' "$PROJECT" "$$" "$(date -Iseconds)" > "$LOCK_FILE"
fi

# ─── Disco ───────────────────────────────────────────────────────────────────
#
# N aplicações × M SHAs de imagem enchem o disco, e disco cheio no meio do build
# dá erro que não fala de disco.
phase disco

DOCKER_ROOT=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)

if [[ $ROLLBACK == 0 && $MODE != dry-run ]]; then
	# Cache de build é reconstruível por definição, e NUNCA é caminho de volta —
	# podá-lo é seguro; podar imagem tagueada não é.
	docker builder prune -f --filter until=168h >/dev/null 2>&1 || true
fi

# ⚠️ O `|| true` não é preguiça: com `pipefail`, um `df` que falha (diretório
# que não existe, permissão) faria a atribuição falhar e o `set -e` mataria o
# deploy **sem imprimir nada** — a mesma falha silenciosa que este desenho
# combate.
free_gb=$(df -BG --output=avail "$DOCKER_ROOT" 2>/dev/null | tail -1 | tr -dc '0-9' || true)

[[ -n $free_gb ]] ||
	fail "não consegui medir o espaço livre em $DOCKER_ROOT. O diretório existe? \`docker info\` responde?"

if ((free_gb < MIN_FREE_DISK)); then
	fail "só ${free_gb}GiB livres em $DOCKER_ROOT (mínimo $MIN_FREE_DISK). Libere espaço — mas NUNCA com \`docker image prune -a\`, que apaga o caminho do rollback de todas as aplicações."
fi

info "disco ........... ${free_gb}GiB livres em $DOCKER_ROOT"

# ─── dry-run para aqui ───────────────────────────────────────────────────────

if [[ $MODE == dry-run ]]; then
	log "dry-run: as pré-condições passaram e nada foi tocado"
	md "## Deploy (dry-run)"
	md ""
	md "| | |"
	md "|---|---|"
	md "| projeto | \`$PROJECT\` |"
	md "| versão que subiria | \`$GIT_SHA\` |"
	md "| no ar agora | \`${PREVIOUS:-nenhuma}\` |"
	md "| imagens a construir | \`${BUILT_IMAGES[*]}\` |"
	md "| migration | \`${MIGRATE_SERVICE:-nenhuma}\` |"
	md "| saúde a conferir | \`$HEALTH_SERVICES\` |"
	md "| disco livre | ${free_gb}GiB |"
	md "| avisos | $WARNINGS |"
	exit 0
fi

# ─── Build ───────────────────────────────────────────────────────────────────

if [[ $ROLLBACK == 1 ]]; then
	# ⚠️ O rollback só alcança imagem que ainda está NESTE disco: não há registry.
	# E ele exige TODAS as imagens do SHA, inclusive a de migration — o `up -d`
	# dispara o serviço de migration por `depends_on`, e se aquela imagem foi
	# podada o rollback falha na hora em que mais se precisa dele.
	phase build

	for image in "${BUILT_IMAGES[@]}"; do
		docker image inspect "$image" >/dev/null 2>&1 ||
			fail "não há $image nesta máquina. Rollback só alcança imagem construída aqui, e \`docker image prune -a\` apaga o caminho de volta."
	done
else
	phase build

	# ⚠️ O pico de memória do ciclo inteiro é aqui. Sem swap, o OOM killer mata o
	# build no meio e o erro que aparece não fala de memória.
	log "Construindo (tag = $GIT_SHA)"
	compose build

	# ─── Gate de CVE ─────────────────────────────────────────────────────────
	#
	# ⚠️ Gate que se pula sozinho quando a ferramenta falta não é gate.
	phase cve

	if [[ $SKIP_SCAN == true ]]; then
		warn "varredura de CVE PULADA por skip-scan — risco assumido explicitamente"
	else
		command -v trivy >/dev/null ||
			fail "trivy não instalado. Instale-o, ou rode com skip-scan: true para assumir o risco."

		for image in "${BUILT_IMAGES[@]}"; do
			log "Varrendo $image"
			report=$(mktemp)

			# ⚠️ NÃO se usa o exit code do trivy como sinal de achado: ele sai 1
			# tanto para vulnerabilidade quanto para erro dele mesmo — e o
			# download do banco de CVE já foi rate-limitado no mundo real. Sem
			# esta separação, um problema de rede derruba o deploy alegando CVE.
			trivy image --quiet --scanners vuln --severity HIGH,CRITICAL \
				--ignore-unfixed --format json --exit-code 0 \
				--output "$report" "$image" ||
				fail "o trivy falhou ao varrer $image (ferramenta ou rede, não achado). Confira o banco de CVE."

			found=$(jq '[.Results[]?.Vulnerabilities // [] | length] | add // 0' "$report" || echo erro)

			[[ $found != erro ]] ||
				fail "não consegui ler o relatório do trivy de $image (jq falhou). O relatório está em $report."

			if ((found > 0)); then
				jq -r '.Results[]?.Vulnerabilities // [] | .[] | "  \(.Severity)\t\(.VulnerabilityID)\t\(.PkgName) \(.InstalledVersion) → \(.FixedVersion)"' "$report" >&2
				fail "$found CVE HIGH/CRITICAL com correção disponível em $image. Atualize a base ou a dependência."
			fi

			rm -f "$report"
		done

		# Terceiros entram como relatório, não como gate: não se conserta CVE do
		# redis a não ser bumpando a tag, e gate refém de upstream é gate que
		# alguém desliga.
		for image in "${THIRD_PARTY[@]:-}"; do
			[[ -n $image ]] || continue
			count=$(trivy image --quiet --scanners vuln --severity HIGH,CRITICAL \
				--ignore-unfixed --format json --exit-code 0 "$image" 2>/dev/null |
				jq '[.Results[]?.Vulnerabilities // [] | length] | add // 0' || echo "?")
			[[ $count == 0 || $count == "?" ]] || warn "imagem de terceiro $image tem $count CVE HIGH/CRITICAL com correção — considere bumpar a tag"
		done
	fi
fi

# ─── Declaração de saúde, agora com as imagens em disco ──────────────────────

phase healthcheck
check_health_declarations strict

# ─── Migration, em passo separado ────────────────────────────────────────────
#
# ⚠️ Nunca no entrypoint da aplicação: com mais de uma réplica, as duas tentariam
# migrar ao mesmo tempo. O container é efêmero e `api`/`worker` dependem dele com
# `service_completed_successfully`.
if [[ -n $MIGRATE_SERVICE ]]; then
	phase migrate

	log "Migration ($MIGRATE_SERVICE)"
	compose up --abort-on-container-exit --exit-code-from "$MIGRATE_SERVICE" "$MIGRATE_SERVICE" ||
		fail "a migration falhou. NADA foi trocado em produção."
fi

# ─── Subida ──────────────────────────────────────────────────────────────────

phase up

# Serviços explícitos, sem o de migration: `up -d` sem lista reavalia o
# `depends_on` e pode rodar a migration uma segunda vez. Para Prisma isso é
# inofensivo (advisory lock), para TypeORM não é — daí o contrato exigir
# migration idempotente E serializável.
mapfile -t UP_SERVICES < <(printf '%s\n' "${SERVICES[@]}" | grep -Fxv "${MIGRATE_SERVICE:-__nenhum__}" || true)

log "Subindo ${UP_SERVICES[*]}"
compose up -d --remove-orphans "${UP_SERVICES[@]}"

# ─── Health check ────────────────────────────────────────────────────────────

service_health() {
	local svc=$1 ids=() id state states=()

	mapfile -t ids < <(compose ps -q "$svc" 2>/dev/null)
	((${#ids[@]})) || { echo "sem-container"; return; }

	# `compose ps -q` devolve N ids com `--scale`: comparar a saída inteira com
	# "healthy" quebraria em silêncio no dia em que alguém escalar um serviço.
	for id in "${ids[@]}"; do
		state=$(docker inspect --format \
			'{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$id" 2>/dev/null || echo "sem-container")
		states+=("$state")
	done

	printf '%s\n' "${states[@]}" | sort -u | paste -sd, -
}

wait_healthy() {
	local deadline=$((SECONDS + HEALTH_TIMEOUT)) svc state all_ok

	while ((SECONDS < deadline)); do
		all_ok=1

		for svc in $HEALTH_SERVICES; do
			state=$(service_health "$svc")

			[[ $state == healthy ]] && continue

			all_ok=0

			# `restarting` é o estado do crash-loop com `restart: unless-stopped`
			# — ele nunca aparece como `exited`, então esperar por `exited` seria
			# esperar para sempre.
			if [[ $state == *exited* || $state == *dead* ]]; then
				printf '  %s=%s\n' "$svc" "$state"
				return 1
			fi
		done

		((all_ok)) && return 0

		for svc in $HEALTH_SERVICES; do printf '  %s=%s\n' "$svc" "$(service_health "$svc")"; done
		sleep 3
	done

	return 1
}

health_logs() {
	local svc id
	for svc in $HEALTH_SERVICES; do
		id=$(compose ps -q "$svc" 2>/dev/null | head -1 || true)
		[[ -n $id ]] || continue
		printf '\n--- %s: última saída do healthcheck ---\n' "$svc" >&2
		docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' "$id" 2>/dev/null | tail -5 >&2 || true
	done
	compose logs --tail=40 $HEALTH_SERVICES >&2 || true
}

phase health

log "Esperando $HEALTH_SERVICES ficarem saudáveis (até ${HEALTH_TIMEOUT}s)"

if ! wait_healthy; then
	printf '\n\033[1;31m✗ health check falhou\033[0m\n' >&2
	health_logs

	if [[ -n $PREVIOUS && $PREVIOUS != "$GIT_SHA" ]]; then
		phase revert

		log "Revertendo para $PREVIOUS"
		GIT_SHA=$PREVIOUS compose up -d "${UP_SERVICES[@]}"

		# ⚠️ Reverter e declarar vitória sem conferir é o pecado que este caminho
		# cometia: se o revert também não sobe, quem está no telefone precisa
		# saber AGORA, não descobrir pelo cliente.
		if GIT_SHA=$PREVIOUS wait_healthy; then
			echo "$PREVIOUS" > "$TAG_FILE"
			md "- ⚠️ **revertido para \`$PREVIOUS\`** — a migration NÃO foi revertida"
			fail "revertido para $PREVIOUS e ele está saudável. ⚠️ A MIGRATION NÃO FOI REVERTIDA."
		fi

		health_logs
		md "- 🔴 **o revert também não ficou saudável** — isto é INCIDENTE"
		fail "o revert para $PREVIOUS também não ficou saudável. Isto é INCIDENTE: siga devs/engineering/deploy-and-incidents.md."
	fi

	fail "sem versão anterior para reverter — é o primeiro deploy desta aplicação. Investigue com os logs acima."
fi

# ─── Registro ────────────────────────────────────────────────────────────────

phase registro

echo "$GIT_SHA" > "$TAG_FILE"

# JSONL e não TSV: os campos passaram de três para dez, e lista de tamanho
# variável em coluna separada por tab não sobrevive ao primeiro `awk`.
# Este bloco roda DEPOIS de produção já estar no ar: nada aqui pode derrubar o
# job, ou um deploy bom apareceria como falho.
image_ids=$(for image in "${BUILT_IMAGES[@]}"; do
	printf '%s@%s\n' "$image" "$(docker image inspect "$image" --format '{{.Id}}' 2>/dev/null || echo desconhecido)"
done | jq -R . | jq -sc . || echo '[]')

jq -nc \
	--arg at "$(date -Iseconds)" \
	--arg project "$PROJECT" \
	--arg sha "$GIT_SHA" \
	--arg previous "$PREVIOUS" \
	--arg mode "$([[ $ROLLBACK == 1 ]] && echo rollback || echo deploy)" \
	--arg actor "${GITHUB_ACTOR:-$(id -un)}" \
	--arg run "${GITHUB_RUN_ID:-}" \
	--arg scan "$([[ $SKIP_SCAN == true ]] && echo pulado || echo ok)" \
	--argjson images "$image_ids" \
	--argjson warnings "$WARNINGS" \
	'{at: $at, project: $project, sha: $sha, previous: $previous, mode: $mode,
	  actor: $actor, run: $run, scan: $scan, images: $images, warnings: $warnings}' >> "$LOG_FILE"

# ⚠️ Fila do Actions faz o deploy subir o HEAD do momento, que pode ser mais novo
# que o commit que disparou o job. Sem este aviso, "meu merge subiu?" não tem
# resposta.
if [[ -n ${GITHUB_SHA:-} && $ROLLBACK == 0 ]]; then
	[[ ${GITHUB_SHA:0:7} == "${GIT_SHA:0:7}" ]] ||
		warn "o commit que disparou este deploy foi ${GITHUB_SHA:0:7}, mas subiu $GIT_SHA (o HEAD da $BRANCH andou). Nada errado — só não é o mesmo commit."
fi

# ─── Retenção ────────────────────────────────────────────────────────────────
#
# ⚠️ Agrupa por SHA, nunca por repositório de imagem: manter `api:abc` e ter
# removido `api-migrate:abc` deixa um rollback que PARECE possível e falha.
phase retenção

mapfile -t IMAGE_REPOS < <(printf '%s\n' "${BUILT_IMAGES[@]}" | cut -d: -f1 | sort -u)

mapfile -t KNOWN_SHAS < <(
	for repo in "${IMAGE_REPOS[@]}"; do
		docker image ls --format '{{.Tag}}|{{.CreatedAt}}' "$repo" 2>/dev/null
	done | grep -E '^[0-9a-f]{7,40}\|' | sort -t'|' -k2 -r | cut -d'|' -f1 | awk '!seen[$0]++'
)

KEEP=("${KNOWN_SHAS[@]:0:$KEEP_IMAGES}" "$GIT_SHA")
[[ -n $PREVIOUS ]] && KEEP+=("$PREVIOUS")

removed=()

for sha in "${KNOWN_SHAS[@]}"; do
	[[ " ${KEEP[*]} " == *" $sha "* ]] && continue

	for repo in "${IMAGE_REPOS[@]}"; do
		docker image inspect "$repo:$sha" >/dev/null 2>&1 || continue
		# Imagem em uso por container o docker recusa remover, e isso é bom.
		docker image rm "$repo:$sha" >/dev/null 2>&1 && removed+=("$repo:$sha") || true
	done
done

((${#removed[@]} == 0)) || info "retenção ........ removidas ${#removed[@]} imagens de SHA antigo"

# ─── Resumo ──────────────────────────────────────────────────────────────────

log "No ar: $GIT_SHA (anterior: ${PREVIOUS:-nenhuma})"

md "## Deploy — \`$PROJECT\`"
md ""
md "| | |"
md "|---|---|"
md "| no ar | \`$GIT_SHA\`$([[ $ROLLBACK == 1 ]] && echo ' (rollback)') |"
md "| anterior | \`${PREVIOUS:-nenhuma}\` |"
md "| CVE | $([[ $SKIP_SCAN == true ]] && echo 'PULADA' || echo 'sem HIGH/CRITICAL com correção') |"
md "| avisos | $WARNINGS |"
md ""

# ⚠️ Pipeline verde não é conferência, e deploy automático não tem ninguém
# olhando o terminal. O checklist é do repositório da aplicação: só quem a
# escreveu sabe qual fluxo prova que ela está de pé.
if [[ -f $CHECKLIST_FILE ]]; then
	md "### Conferência à mão, que nenhum health check cobre"
	md ""
	cat "$CHECKLIST_FILE" >> "$SUMMARY"
	md ""
else
	md "> Sem \`$CHECKLIST_FILE\` neste repositório — escreva um: é o que diz qual fluxo provar depois de subir."
	md ""
fi

md "Rollback: rode este workflow com o SHA anterior no campo. ⚠️ Reverte **imagem**, nunca **migration**."

if [[ -n ${GITHUB_OUTPUT:-} ]]; then
	printf 'deployed-sha=%s\n' "$GIT_SHA" >> "$GITHUB_OUTPUT"
fi

# Deploy

Como o código chega em produção aqui, do PR ao cliente — e o que fazer para
manter isso de pé.

Esta página é o **mecanismo**. O *processo humano* — janela, o que conferir, o que
fazer quando cai — está em [Deploy e incidentes](deploy-and-incidents.md), e
continua valendo inteiro.

> [!IMPORTANT]
> **Deploy automatizado não é possível aqui:** as VMs de produção só são
> alcançáveis pela VPN, e nenhum runner do GitHub chega nelas. Por isso o deploy é
> **semiautomático**: uma pessoa autorizada entra na VM e roda **um comando**, e o
> resto é automático. Não há workflow de deploy, não há `scripts/deploy.sh` nos
> repositórios e não há runner na VM.

## Como funciona

```
branch → commits → PR para a main
                     └─ CI no GitHub: lint · typecheck · build · contrato · testes
                          └─ o sênior revisa; verde + aprovado, o AUTOR mergeia
                               └─ (merge NÃO é deploy: a main fica à frente de produção)

alguém do grupo deployers → VPN → SSH na VM → deploy --<app>
                     └─ pull → config → build → CVE → migrate → up -d → health
                          └─ health falhou? reverte a imagem sozinho
                               └─ imprime o deploy-checklist.md: conferência à mão
```

Duas peças, e nada além delas:

| Onde | Quem roda | O que faz |
|---|---|---|
| **CI** (`ci.yml`, no repositório da aplicação) | runner **hospedado** do GitHub | Verifica o PR, e **bloqueia** o merge |
| **Deploy** (`deploy`, na VM) | uma pessoa do grupo `deployers` | O pipeline inteiro, para qualquer aplicação da VM |

```bash
deploy --ilux-desk                 # sobe o HEAD da branch de deploy da aplicação
deploy --ilux-desk --sha <sha>     # ROLLBACK para um SHA já construído na VM
deploy --ilux-desk --dry-run       # confere tudo e não toca em nada
deploy --doctor                    # confere a máquina
deploy --list                      # as aplicações, o SHA no ar e quem subiu por último
```

**O pipeline mora no repositório privado `ops`** da organização, clonado na VM em
`/srv/ops`: um `deploy.sh` para todas as aplicações e um `apps/<app>.conf` por
aplicação. O repositório da aplicação só tem o que é dela: o compose de produção, o
`.env.prod.example` e o `deploy-checklist.md`. Mudar o pipeline é PR no `ops`, que
tem CI e um teste que sobe um projeto compose de verdade. O script não fica aqui
porque este repositório é público, e o `ops` descreve a VM de produção.

**Quem pode subir é regra da VM, não do GitHub.** O script só roda como o usuário
`deploy`. As pessoas entram pelo atalho `/usr/local/bin/deploy`, que faz
`sudo -u deploy`, e o `/etc/sudoers.d/deployers` libera **só esse comando** e **só**
para o grupo `deployers`. Quem tem write no repositório não sobe produção por
isso, e cada subida grava quem rodou.

**O CI impede o merge.** Os jobs do `ci.yml` entram como status check obrigatório
num ruleset **do próprio repositório**, separado do `PROTECT-MAIN` da organização
e **sem bypass**. Ver [proteção da `main`](git-and-github.md#o-ci-vira-status-check-obrigatório).

⚠️ O check exigido é a **string exata** do `name:` do job. Renomear um job solta a
guarda sem erro em lugar nenhum — o check passa a nunca reportar.

E porque merge **não** é deploy, a [janela de deploy](deploy-and-incidents.md#janelas)
vale para o momento em que se roda o `deploy`, e a `main` pode estar à frente de
produção. Antes de supor o que está no ar, `deploy --list`.

> [!TIP]
> Rode o `deploy` dentro de um `tmux`. Se a VPN cair, o SSH cai junto e o deploy
> morre na fase em que estava (ela fica registrada em `/srv/.deploy/<app>/phase`).

---

## A VM, uma vez

Feito uma vez por máquina, à mão. Assume Ubuntu 22.04/24.04.

**Tamanho.** O pico é `next build` + `nest build` na própria VM. Piso: 2 vCPU /
4 GB **com swap**. Confortável: 4 vCPU / 8 GB. Disco: cada aplicação guarda os
últimos SHAs de imagem (cada um é um rollback possível), e a imagem do estágio de
migration é gorda — estime ~3 GB por SHA por aplicação e peça **80 GB**.

**1. Docker, do repositório oficial** (não pelo `get.docker.com`, que é script
para máquina de desenvolvimento):

```bash
sudo apt-get update && sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker compose version    # >= 2.20
```

**2. As ferramentas que o deploy exige:**

```bash
sudo apt-get install -y git jq
# jq não é opcional: é como o ACHADO do trivy é separado do ERRO do trivy
```

⚠️ Sem `jq` e `trivy` o `deploy` **recusa** rodar. Gate de CVE que se pula sozinho
quando a ferramenta falta não é gate.

E o `trivy`, que é o gate de CVE (se o repositório do Aqua mudar, confira a página
oficial):

```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

**3. Swap — não é opcional.** Sem ela o OOM killer mata o build no meio, e o erro
que aparece **não fala de memória**:

```bash
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**4. Firewall:** 80, 443 e SSH. Nada mais — nenhuma aplicação publica porta.

```bash
sudo ufw allow OpenSSH && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw enable
```

**5. Usuário e diretório de estado:**

```bash
sudo adduser --disabled-password --gecos "" deploy
sudo usermod -aG docker deploy
sudo install -d -o deploy -g deploy -m 755 /srv/.deploy
```

`deploy` não tem senha e ninguém entra como ele por SSH: as pessoas usam a própria
conta, e o `deploy` (passo 8) troca de usuário.

> [!IMPORTANT]
> `/srv/.deploy/` guarda a **trava da máquina** (um deploy por VM, entre
> aplicações) e, por aplicação, o SHA no ar, o log e a fase de um deploy
> interrompido. Ele fica **fora de qualquer árvore de trabalho** de propósito:
> arquivo de estado criado dentro do repositório fazia o próprio deploy sujar a
> árvore, e o deploy seguinte recusa subir de árvore suja — o primeiro funcionava
> e o segundo falhava.

**6. Uma chave do `deploy` por repositório**, sem passphrase (o `git pull` roda
sem terminal):

```bash
sudo -iu deploy
ssh-keygen -t ed25519 -N "" -C "deploy@prd-apps-1:<repo>" -f ~/.ssh/id_ed25519_<repo>
cat ~/.ssh/id_ed25519_<repo>.pub
```

Essa pública entra **naquele** repositório como **Deploy key**, em Settings →
Deploy keys. **Sem** marcar "Allow write access": o deploy só faz `pull`.

> [!WARNING]
> **O GitHub recusa a mesma chave pública em dois repositórios** ("Key is already
> in use"). Cada repositório que a VM clona tem a sua, e o clone diz qual usar —
> o `-c` fica gravado no repositório, então os `git pull` seguintes já usam a
> chave certa:
>
> ```bash
> git clone -c core.sshCommand="ssh -i /home/deploy/.ssh/id_ed25519_<repo> -o IdentitiesOnly=yes" \
>   git@github.com:<org>/<repo>.git
> ```

**7. A borda, uma vez por VM.** Só um processo escuta a 443, e ele não é de
nenhuma aplicação: é o repositório `edge` da organização, clonado em `/srv/edge`.
Um Caddy que emite e renova os certificados sozinho, com **um arquivo por
aplicação** em `conf/sites/`, e uma rede Docker externa, `edge`, onde a borda e o
serviço público de cada aplicação se encontram.

```bash
sudo -iu deploy
docker network create edge
cd /srv && git clone -c core.sshCommand="ssh -i /home/deploy/.ssh/id_ed25519_edge -o IdentitiesOnly=yes" \
  git@github.com:<org>/edge.git edge
cd /srv/edge
cp .env.example .env && chmod 600 .env    # ACME_EMAIL: quem o Let's Encrypt avisa
docker compose up -d
```

> [!IMPORTANT]
> A borda é **ponto único de todas as aplicações da VM**. Site novo ou alterado é
> `caddy reload`, que não derruba ninguém e recusa configuração inválida mantendo
> a anterior. Recriar o container dela (`up -d` depois de mudar o compose, ou
> trocar a imagem) derruba **todos** os sites por alguns segundos — é trabalho de
> janela. E **nunca** `docker network rm edge` nem `docker network prune`.
>
> O README do `edge` tem o resto: como acrescentar um site, o diagnóstico de
> `502`, e a migração de 2026, quando o Caddy saiu de dentro da primeira
> aplicação (o porquê está na ADR 0008 do `ilux-desk`).

**8. O deploy central, uma vez por VM.** O repositório privado `ops`, clonado em
`/srv/ops` com uma deploy key própria (passo 6), e o `install.sh` dele, que cria o
grupo `deployers`, instala o atalho `/usr/local/bin/deploy` e o
`/etc/sudoers.d/deployers` (validado com `visudo` antes de entrar):

```bash
sudo -iu deploy
cd /srv && git clone -c core.sshCommand="ssh -i /home/deploy/.ssh/id_ed25519_ops -o IdentitiesOnly=yes" \
  git@github.com:<org>/ops.git ops
exit
sudo /srv/ops/install.sh <seu-usuário>     # e quem mais puder subir produção
# saia e entre de novo na VM: grupo novo só vale no próximo login
deploy --doctor
```

Tirar alguém: `sudo gpasswd -d <usuário> deployers`. Atualizar o `ops` na VM é
`git -C /srv/ops pull --ff-only` como `deploy` (e `sudo /srv/ops/install.sh` de
novo se o `install.sh` ou o `bin/deploy` mudaram).

> [!NOTE]
> **Não há runner na VM.** Até 11/2026 cada repositório tinha um runner
> self-hosted aqui, e ele saiu: a VM não é alcançável de fora da VPN, e runner na
> VM de produção é comando do GitHub executado nela. Se ainda houver um, remova
> (`sudo ./svc.sh uninstall` no diretório dele, apague o diretório e tire-o em
> Settings → Actions → Runners).

---

## Aplicação nova, passo a passo

### 1. DNS, antes de tudo

Registro **A** do hostname da aplicação apontando para o IP da VM. Um hostname
por aplicação — sem prefixo de rota, sem cookie compartilhado entre produtos.

```bash
dig +short <dominio>    # tem que devolver o IP da VM
```

> [!WARNING]
> Isto vem **primeiro** porque a borda pede o certificado assim que lê o site da
> aplicação (passo 6), e cada falha de emissão consome uma das **5 tentativas
> semanais** que o Let's Encrypt dá por domínio.

### 2. O que vai no repositório da aplicação

| Arquivo | O que é |
|---|---|
| `docker-compose-prod.yml` | Os serviços de produção, cumprindo [o contrato](#o-contrato-do-compose) |
| `.env.prod.example` | As chaves do ambiente de produção, sem valor |
| `.github/workflows/ci.yml` | A checagem do PR. O modelo é o do [template de monorepo](../templates/monorepo/) |
| `deploy-checklist.md` | O que provar depois de subir, nesta aplicação. O `deploy` o imprime no fim |

**Nada de deploy no repositório da aplicação:** nem `scripts/deploy.sh`, nem
`deploy.yml`.

### 3. A aplicação no `ops`

PR no repositório `ops` com `apps/<app>.conf`:

```ini
APP=minha-app                 # = nome do arquivo; estado em /srv/.deploy/minha-app
DIR=/srv/minha-app            # o clone de produção
BRANCH=main
COMPOSE_FILE=docker-compose-prod.yml
ENV_FILE=.env.prod
MIGRATE_SERVICE=migrate       # vazio = aplicação sem migration
HEALTH_SERVICES="api web"     # quem precisa ficar saudável para o deploy valer
CHECKLIST_FILE=deploy-checklist.md
```

O arquivo é **lido, não executado**: só essas chaves, e chave desconhecida é erro.
Depois do merge, na VM: `git -C /srv/ops pull --ff-only` como `deploy`.

### 4. O compose de produção cumprindo o contrato

Ver [a tabela abaixo](#o-contrato-do-compose). O `deploy --<app> --dry-run`
confere quase tudo isso e diz o que falta.

### 5. O lugar da aplicação na VM

```bash
sudo mkdir -p /srv/<app> && sudo chown deploy:deploy /srv/<app>
sudo -iu deploy
cd /srv/<app>
git clone -c core.sshCommand="ssh -i /home/deploy/.ssh/id_ed25519_<repo> -o IdentitiesOnly=yes" \
  git@github.com:<org>/<repo>.git .
cp .env.prod.example .env.prod && chmod 600 .env.prod   # o deploy RECUSA sem isto
nano .env.prod
```

A chave é a do passo 6 da VM, uma por repositório.

Gere segredo com `openssl rand -hex 32`. Variável nova entra no `.example` **no
mesmo PR** que a cria, e é preenchida na VM **antes** do próximo deploy — o
`deploy` avisa quando falta no `.env.prod` uma chave que está no `.example`.

### 6. O site na borda

PR no repositório `edge` com `conf/sites/<app>.caddy`, apontando para o **nome do
serviço na rede `edge`** ([o contrato](#o-contrato-do-compose)):

```
<dominio> {
	reverse_proxy <app>-web:3000

	import security-headers
	import json-log
}
```

O CI do `edge` confere a formatação (`caddy fmt`, com TAB) e se a configuração
carrega (`caddy validate`). Depois do merge, na VM:

```bash
sudo -iu deploy
cd /srv/edge
git pull --ff-only
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

O `reload` não derruba nenhum site, e nenhuma outra aplicação é tocada.

> [!TIP]
> O DNS ainda não aponta? O arquivo pode entrar com o bloco **comentado**: a borda
> o ignora e não pede certificado. Quando o DNS apontar, outro PR tira os `#`.

### 7. Provar antes de subir

Na VM, com um usuário do grupo `deployers`:

1. `deploy --doctor` — confere a máquina e se o clone de cada aplicação existe.
2. `deploy --<app> --dry-run` — confere a aplicação (compose, ambiente, disco,
   imagens que seriam construídas). Nada é tocado.
3. `deploy --<app>` — sobe o HEAD. É o mais lento de todos: constrói do zero.

### 8. Conferir à mão, e ensaiar o rollback

Pipeline verde não é conferência: siga o `deploy-checklist.md`, que o `deploy`
imprime no fim.

E **ensaie o rollback antes de precisar dele** — `deploy --<app> --sha
<sha-anterior>`. Plano de rollback testado, não imaginado.

---

## O contrato do compose

O `deploy` não sabe o que é pnpm, npm, Prisma ou TypeORM: o contrato é o projeto
compose. É isso que faz o mesmo script servir um monorepo com Postgres e um
serviço com MySQL.

| Exigência | Por que é contrato, e não conveniência |
|---|---|
| `name: <app>-prd` | O nome do projeto é a identidade da aplicação para trava, log e retenção. Sem ele, o nome sai do diretório e um `down` pode acertar outro projeto |
| Toda imagem construída tagueada `${GIT_SHA:?...}` | Sem registry, rollback é `up -d` com outro SHA. Se o nome da imagem não for função só do SHA, não há caminho de volta |
| **Toda** variável interpolada com `${VAR:?mensagem}` | É o que faz arquivo de ambiente incompleto falhar **no parse**, antes do build. Sem o `:?`, vira string vazia e o erro aparece em runtime, torto |
| Migration em serviço one-shot (`restart: "no"`), com os serviços de aplicação em `depends_on: service_completed_successfully` | Migration no entrypoint com duas réplicas = duas migrações ao mesmo tempo |
| Migration **idempotente e serializável** | O `up -d` pode disparar o serviço de migration outra vez. `prisma migrate deploy` toma advisory lock; `typeorm migration:run` **não** — aí a trava é trabalho do repositório |
| `HEALTHCHECK` em todo serviço citado em `HEALTH_SERVICES` | É o que o deploy consulta para decidir se reverte |
| Nenhuma porta publicada | Só a borda publica 80 e 443. Porta publicada numa aplicação é a API dela exposta sem TLS, ao lado das outras. Hoje o deploy **avisa**; a intenção é virar erro. Para testar de dentro da VM, no máximo `127.0.0.1:<porta>:<porta>` |
| O serviço público na rede externa `edge`, com nome `<app>-<serviço>` | É por ela que a borda chega na aplicação, e o arquivo do site aponta para esse nome. Use um alias de rede (`aliases: [minha-app-web]`) ou o próprio nome do serviço, **nunca** `web` ou `api` puros: o nome de um serviço vale em toda rede em que ele entra, e dois `api` na `edge` fazem o Docker distribuir o tráfego entre sistemas diferentes — inclusive o interno de uma aplicação que chama `http://api:3333` —, em silêncio |
| `mem_limit` e rotação de log em todo serviço | **Recurso compartilhado:** aplicação sem teto de memória derruba as vizinhas num pico; sem rotação, enche o disco de todas |
| Nenhum segredo em `build.args` | `build.args` fica no `docker history` da imagem para sempre |

---

## Manutenção

O que é automático, a cada deploy: guarda de disco antes do build, poda do cache
de build, retenção dos últimos SHAs por aplicação (agrupada **por SHA**, para não
sobrar rollback pela metade), e aviso quando falta chave no arquivo de ambiente ou
quando um serviço publica porta.

O que é seu:

| Cadência | O que | Por que não dá para automatizar hoje |
|---|---|---|
| **Semanal, 2 min** | `deploy --list`: o que está no ar é o HEAD da `main`? Há merge esperando subir? | **Merge não é deploy:** sem ninguém olhando, produção fica versões atrás e nada avisa |
| **Mensal** | `df -h`; **ensaiar um rollback**; olhar os PRs do Dependabot | Plano de rollback testado, não imaginado |
| **Trimestral** | Bumpar a base das imagens; atualizar a imagem da borda (`docker compose pull && docker compose up -d` em `/srv/edge`, **na janela**: derruba todos os sites por segundos); `apt upgrade` (e o `trivy`) + reboot da VM; `getent group deployers`: ainda é quem deveria? | A varredura de CVE é do momento do build: vulnerabilidade publicada depois só aparece no próximo deploy |
| **Antes de migration destrutiva** | Backup **verificado** — alguém tem que saber restaurar | Migration destrutiva não passa pelo pipeline: janela combinada, à mão |

> [!CAUTION]
> **`docker image prune -a` e `docker system prune -a` são proibidos nesta
> máquina.** Em script, em cron, em runbook, em sessão de SSH às 2h da manhã. Não
> há registry: essas imagens são o único caminho de volta, e o comando apaga o
> rollback de **todas** as aplicações de uma vez. Precisando de espaço, pode podar
> cache de build — ele é reconstruível por definição.

Duas regras a mais, que valem sempre: **não edite nada em `/srv/<app>` nem em
`/srv/ops` por SSH** (o deploy recusa árvore suja de propósito — o que subisse não
teria SHA que o descrevesse) e **swap sempre ligada**.

---

## Quando falha

| Falhou em | Produção está |
|---|---|
| Config, disco, build, CVE ou declaração de healthcheck | **Intacta**, na versão anterior. Nada subiu |
| Migration | **Intacta.** Os serviços de aplicação nem tentaram subir |
| Health check depois do `up -d` | O deploy **reverte a imagem e confere a saúde do revert**. ⚠️ A migration **não** volta |
| O revert também não ficou saudável | Isto é **incidente**: [Deploy e incidentes](deploy-and-incidents.md#incidentes) |

Rollback: `deploy --<app> --sha <sha-anterior>`. Ele não depende do GitHub: só
alcança imagem que ainda está no disco da VM.

Rollback à mão, se nem o `deploy` puder rodar:

```bash
sudo -iu deploy
cd /srv/<app>
GIT_SHA=<sha-anterior> docker compose --env-file .env.prod -f docker-compose-prod.yml up -d
echo <sha-anterior> > /srv/.deploy/<app>/current-tag
```

---

## Aplicação com MySQL

O deploy não muda: o contrato é o compose, e um serviço one-shot que roda
`migration:run` do TypeORM cumpre o mesmo papel que um que roda
`prisma migrate deploy`. O que muda é o **CI**:

| Eixo | Postgres + Prisma | MySQL + TypeORM |
|---|---|---|
| Serviço no CI | `pgvector/pgvector:pg17` (a extensão `vector` é criada pela primeira migration; com a imagem oficial do Postgres a suíte morre antes do primeiro teste) | `mysql:8` — e atenção ao collation, se as migrations fixarem um |
| Health do serviço | `pg_isready -U <user> -d <db>` | `mysqladmin ping` |
| Conexão | `DATABASE_URL` única | `DB_HOST`/`DB_PORT`/`DB_USER`/`DB_PASSWORD`/`DB_NAME` separados |
| Migration no CI | o `globalSetup` da suíte cria o banco e migra | idem, pelo `dataSource.runMigrations()` |
| Paralelismo | nomes de banco fixos → **exige `--concurrency=1`** | nome por execução → seguro em paralelo |

> [!NOTE]
> Se a aplicação com MySQL tiver banco **remoto e compartilhado** em vez de
> serviço no CI, a suíte de integração não cabe no PR sem uma decisão sobre
> concorrência de schema. Resolva isso antes, não no dia.

---

## O que este desenho não resolve

Escrito porque dívida que não está escrita vira folclore:

- **Merge não é deploy.** Alguém tem que lembrar de subir, e a `main` pode ficar
  versões à frente de produção. O antídoto é a conferência semanal.
- **Depende de uma pessoa do `deployers` com VPN.** Sem ela, nada sobe, nem hotfix.
  Mantenha pelo menos duas pessoas no grupo.
- **Não há homologação.** Um ambiente só significa que o primeiro a exercitar a
  mudança é o cliente. É a dívida mais cara daqui.
- **O build roda na máquina de produção**, disputando memória e disco com quem
  está usando o sistema.
- **A imagem do front não é promovível.** Variável pública entra no build, então a
  imagem fica presa ao domínio — trocar de domínio exige **rebuild**, não restart.
- **Migration não tem rollback.** A imagem volta, o schema não — daí a regra das
  [duas fases](deploy-and-incidents.md#migration-em-produção).
- **O deploy tem alguns segundos de indisponibilidade.** `up -d` recria container.
  Zero-downtime aqui é nenhum, e é isso que justifica as janelas.
- **Sem registry, o rollback é local.** Alcança só imagem que ainda está naquele
  disco. VM reconstruída = zero rollback.
- **Mudança de pipeline e de aplicação ficam em repositórios diferentes.** Um
  serviço novo que precisa de healthcheck é PR na aplicação **e** no `.conf` do `ops`.
- **A borda é ponto único de todas as aplicações.** Configuração errada o `reload`
  recusa, mas o container dela caído derruba todos os sites da VM juntos.
- **Nome na rede `edge` é regra escrita, não imposta.** Nada impede uma aplicação
  de entrar nela com um serviço chamado `api`; quem pega é o review.

## Quando revisitar

| Se... | Então |
|---|---|
| houver um jeito de alcançar a VM sem VPN que o time aceite manter (runner dentro da rede, por exemplo) | volta à mesa disparar o `deploy` pelo merge — o script já é o mesmo, só muda quem o chama |
| entrar registry e um segundo ambiente | o gatilho passa a **promover imagem validada**, e a homologação vem com ele |
| o `evaluate` de emergência virar rotina | pôr o ruleset do CI em `evaluate` para mergear no vermelho é a válvula; se for usada toda semana, o problema é o CI estar lento demais para hotfix, não a regra |
| o pico de build atrapalhar quem usa o sistema | buildar em outra máquina e carregar a imagem |
| as aplicações da VM passarem de umas dez, ou site novo virar rotina semanal | proxy configurado por *labels* no compose de cada aplicação (Traefik, caddy-docker-proxy) volta à mesa — com um proxy de socket filtrado no meio, porque o socket do Docker montado no proxy é controle da VM inteira, onde roda produção |
| entrar uma segunda VM | a borda deixa de ser da máquina, e o que fica na frente das duas é outra decisão |

---

← [Voltar a Engenharia](README.md) · [Team Handbook](../README.md)

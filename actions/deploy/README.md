# `actions/deploy` — o pipeline de deploy da Softilux

Uma implementação, N aplicações. O **padrão** (contrato, checklist de aplicação
nova, o que ele não resolve) está em
[Padrão de deploy](../../devs/engineering/deploy-standard.md); esta página é a
**referência da action**.

```yaml
- uses: Softilux-Desenvolvimento-de-Sistemas/.github/actions/deploy@v1.0.0
  with:
    sha: ${{ inputs.sha }}
```

O que ela faz, nesta ordem — e a ordem é o desenho, porque o que falha, falha
antes de produção trocar de versão:

```
config → disco → build → CVE → healthcheck → migrate → up -d → health → estado
         └─ falhou? nada subiu              └─ falhou? api e worker não sobem
```

> [!IMPORTANT]
> Esta action **não sabe** o que é pnpm, npm, Prisma ou TypeORM. O contrato é o
> projeto compose da aplicação. Se ela precisar mudar para receber uma aplicação
> nova, **o contrato estava errado** — a correção vai no contrato, nunca num `if`
> por aplicação.

## Inputs

| Input | Default | Para quê |
|---|---|---|
| `sha` | `''` | Preenchido = **rollback** para esse SHA, sem build. Vazio = sobe o HEAD da branch de deploy |
| `mode` | `deploy` | `dry-run` roda só as pré-condições e não toca em nada; `doctor` confere a máquina |
| `deploy-root` | `''` | Vazio = `/srv/<nome-do-repositório>` |
| `config` | `deploy.conf` | Onde estão os fatos do repositório |
| `skip-scan` | `false` | Sobe sem varredura de CVE. Fica no log e no resumo |
| `health-timeout` | `120` | Segundos esperando ficar saudável |
| `lock-wait` | `1800` | Segundos esperando a trava da máquina |
| `keep-images` | `5` | SHAs de imagem mantidos por aplicação — cada um é um rollback possível |
| `min-free-disk` | `15` | GiB livres exigidos antes do build |

**Output:** `deployed-sha` — o SHA que ficou no ar. É com ele que o repositório
acrescenta passos **depois** do deploy (um smoke test, por exemplo).

## `deploy.conf`, no repositório da aplicação

A partição é: **`deploy.conf` = fatos do repositório; `with:` = política da
invocação.** Assim o workflow chamador não tem nenhuma string específica da
aplicação além da label da máquina, e renomear um serviço no compose e atualizar
a declaração acontecem no mesmo diff.

```sh
# Quais serviços do compose de produção significam o quê. Fatos, não política.
COMPOSE_FILE=docker-compose-prod.yml
ENV_FILE=.env.prod
MIGRATE_SERVICE=migrate
HEALTH_SERVICES=api web
BRANCH=main
CHECKLIST_FILE=deploy-checklist.md
```

| Chave | Obrigatória | Default |
|---|---|---|
| `ENV_FILE` | **sim** (vazio permitido) | — |
| `MIGRATE_SERVICE` | **sim** (vazio = aplicação sem migration) | — |
| `HEALTH_SERVICES` | **sim**, não vazia | — |
| `COMPOSE_FILE` | não | `docker-compose-prod.yml` |
| `BRANCH` | não | `main` |
| `CHECKLIST_FILE` | não | `deploy-checklist.md` |

O parser é estrito de propósito, e cada regra paga uma dívida conhecida:

- **Chave desconhecida é erro, não aviso.** `HEALTH_SERVICE=api` (singular)
  aceito com aviso deixaria `HEALTH_SERVICES` vazio, e o gate de saúde se
  desligaria sozinho. Gate que se desliga em silêncio é o modo de falha que este
  padrão existe para evitar.
- **Vazio explícito ≠ ausente.** `MIGRATE_SERVICE=` diz "esta aplicação não tem
  migration", e isso aparece no log. Chave ausente é erro.
- **`$` é proibido no valor.** O arquivo é lido, nunca executado — não há `source`
  em lugar nenhum.
- **Todo serviço citado tem que existir no compose.** Renomear serviço sem
  atualizar a conf falha no portão, não em produção.

## O que é derivado, e o que é declarado

Regra: **derive o que falha alto, declare o que falha baixo.**

| Fato | De onde | Por quê |
|---|---|---|
| Nome do projeto compose | `config --format json` → `.name` | Identidade da aplicação para trava, log e retenção |
| Imagens que **esta máquina** construiu | serviços com `build:` cuja imagem termina em `:<sha>` | É o que se escaneia, o que o rollback exige e o que a retenção protege |
| Imagens de terceiro | serviços sem `build:` | Entram como **relatório**, não como gate |
| Serviços a subir | `config` menos o de migration | `up -d` sem lista reavalia `depends_on` e pode rodar a migration outra vez |
| **Quem tem healthcheck** | declarado em `HEALTH_SERVICES` | ⚠️ `docker compose config` **nunca abre imagem**: `HEALTHCHECK` de Dockerfile é invisível para ele. Derivar daria a lista errada |

## O que ela exige da máquina

`mode: doctor`, disparado **pelo runner** (não pelo seu shell — o PATH do serviço
systemd não é o do login), confere tudo isto e diz o que falta:

| Item | Observação |
|---|---|
| `docker` + compose v2 ≥ 2.20 | `--format json` do `config` é o que permite derivar |
| `git`, `flock`, `jq` | `jq` não é opcional: é como o achado do trivy é separado do erro do trivy |
| `trivy` | Sem ele o deploy **para**, salvo `skip-scan: true` |
| `swap` ativa | O pico é `next build` + `nest build`; sem swap o OOM mata o build e o erro não fala de memória |
| `/srv/.deploy` gravável | Estado e trava. `sudo install -d -o deploy -g deploy -m 755 /srv/.deploy` |

## Estado, fora da árvore de trabalho

Em `/srv/.deploy/`:

| Caminho | O que é |
|---|---|
| `deploy.lock` | Trava **da máquina** — um deploy por VM, entre aplicações |
| `<app>/current-tag` | O SHA no ar. É o alvo do revert automático |
| `<app>/deploy-log.jsonl` | Uma linha por deploy: SHA, imagens com ID, ator, run, avisos |
| `<app>/phase` | Em que fase um deploy interrompido morreu |

> [!IMPORTANT]
> Isto **não** fica dentro do repositório, e não é preferência: um `current-tag`
> na raiz do repositório faz o próprio deploy sujar a árvore de trabalho — e o
> deploy seguinte recusa subir de árvore suja. O primeiro funciona, o segundo
> falha. Cada repositório novo reintroduziria o bug.

## Trava: da máquina, e com espera

`flock` em `/srv/.deploy/deploy.lock`, com `-w` (espera, default 30min) e não
`-n` (recusa na hora).

Com **um runner por repositório**, o GitHub não serializa mais nada entre
aplicações: dois merges em aplicações diferentes viram dois `next build`
simultâneos disputando a memória da mesma VM. Recusar na hora transformaria isso
em "uma aplicação não subiu". O deploy que espera imprime quem está na frente e
desde quando.

## Retenção de imagem

Mantém os `keep-images` SHAs mais recentes, **mais** o atual e o anterior, e
agrupa **por SHA, não por repositório de imagem** — manter `api:abc` e ter
removido `api-migrate:abc` deixaria um rollback que parece possível e falha no
`up -d`.

> [!CAUTION]
> **`docker image prune -a` e `docker system prune -a` são proibidos nesta
> máquina**, em script, cron ou runbook. Não há registry: essas imagens são o
> único caminho de volta, e o comando apaga o rollback de **todas** as
> aplicações de uma vez. O deploy poda apenas cache de build (reconstruível) e
> SHAs fora da janela de retenção.

## Versão

**Fixe a tag exata** (`@v1.0.0`), nunca `@v1` móvel ou `@main`.

Tag móvel significa que um push neste repositório troca o código que roda como
`deploy` em **todas** as VMs, sem diff em lugar nenhum. Com tag fixa, o
[Dependabot](../../devs/workflow/repo-standards.md) abre o PR de bump por
repositório, e a adoção é escalonada: bump em um, um deploy de prova, depois os
outros.

`uses:` não aceita expressão — a versão é literal em cada repositório, e isso é
propriedade, não limitação.

> [!WARNING]
> A tag desta action é **código de produção de todas as aplicações**. Uma tag
> ruim quebra N sistemas. Só se cria tag quando `actions/` muda, e todo PR aqui é
> revisado como mudança de infraestrutura — porque é.

## Caminho manual, pelo SSH

O runner deixa a action em disco, e rodar aquele arquivo é rodar exatamente o
mesmo código do pipeline:

```bash
~deploy/actions-runner/_work/_actions/Softilux-Desenvolvimento-de-Sistemas/.github/<ref>/actions/deploy/deploy.sh
```

A `<ref>` no meio do caminho é a versão fixada no workflow — mais um motivo para
fixá-la. Rodando à mão, as variáveis são as mesmas com prefixo `DEPLOY_`
(`DEPLOY_SHA`, `DEPLOY_MODE`, …).

**Se o GitHub estiver fora do ar** e for preciso reverter, o caminho mais curto
não passa por script nenhum:

```bash
cd /srv/<app>
GIT_SHA=<sha-anterior> docker compose --env-file .env.prod -f docker-compose-prod.yml up -d
echo <sha-anterior> > /srv/.deploy/<app>/current-tag
```

## O que ela não faz

- **Não verifica o código.** Lint, typecheck e teste seguem nos hooks locais. Ela
  **sobe**, não **confere**.
- **Não tem zero-downtime.** `up -d` recria container; há alguns segundos de 502.
- **Não reverte migration.** Imagem volta, schema não.
- **Não escaneia depois do build.** CVE publicada amanhã só aparece no próximo
  deploy — e o gate depende do banco do trivy, que é rede.
- **Não sobrevive a cancelamento.** Job cancelado ou estourando `timeout-minutes`
  morre no meio; ela grava a fase em `phase`, mas não conserta o estado.

---

← [Padrão de deploy](../../devs/engineering/deploy-standard.md) ·
[Team Handbook](../../devs/README.md)

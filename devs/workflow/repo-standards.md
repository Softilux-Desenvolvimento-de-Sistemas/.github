# Padrão de repositório

Todo repositório nosso segue a mesma estrutura. O objetivo é um só: **qualquer dev do time consegue clonar um projeto que nunca viu e subir na própria máquina seguindo só o README**, sem precisar perguntar nada a ninguém.

Quando isso não acontece, o README está incompleto — não o dev.

**Monorepo é o padrão** — um repositório por produto, com os serviços dele em `apps/`. O porquê, o formato e as exceções estão em [Monorepo](../engineering/monorepo.md). Repositório de um app só continua existindo, e onde esta página distingue os dois, ela avisa.

## Arquivos na raiz

| Arquivo | Para quê |
|---|---|
| `README.md` | O que é, como rodar, como testar, como deployar |
| `AGENTS.md` + `CLAUDE.md` | [Contexto de agente](../engineering/agent-context.md). O `CLAUDE.md` é uma linha: `@AGENTS.md` |
| `package.json` | Privado, com `packageManager` e `engines` fixos |
| `pnpm-workspace.yaml` | Os workspaces e o catálogo (monorepo) |
| `turbo.json` | O pipeline de tarefas (monorepo) |
| `biome.json` | Lint e formatação, com `"root": true` |
| `.nvmrc` | Versão do Node |
| `.editorconfig` | Consistência entre editores |
| `docker-compose.yml` | Serviços locais (banco, cache, etc.) |
| `.husky/` | `pre-commit` e `pre-push`, **só na raiz** |
| `.github/dependabot.yml` | Atualização de dependência |
| `.github/workflows/ci.yml` | A checagem do PR ([Deploy](../engineering/deploy.md)) |
| `.github/workflows/deploy.yml` | O gatilho do deploy — 25 linhas, chama o script |
| `scripts/deploy.sh` | **O pipeline.** As 4 constantes do topo são o que muda entre apps |
| `deploy-checklist.md` | A conferência à mão depois de subir |
| `docker-compose-prod.yml` | Os serviços de produção ([contrato](../engineering/deploy.md#o-contrato-do-compose)) |
| `.vscode/extensions.json` | Extensões recomendadas |
| `docs/adr/` | [Decisões do workspace](../templates/adr-template.md) |

### Em cada app (monorepo)

| Arquivo | Para quê |
|---|---|
| `package.json` | Nome único no workspace, que **não colide com o do pacote raiz** |
| `AGENTS.md` + `CLAUDE.md` | As convenções deste app |
| `README.md` | Como subir só ele |
| `.env.example` | Todas as env vars **deste app**, sem valores |
| `Dockerfile` | Com `context: .` na raiz do monorepo |
| `biome.json` | `"root": false`, `"extends": "//"` |
| `turbo.json` | `"extends": ["//"]`, só o que difere |
| `docs/adr/` | Decisões que afetam **só** este app |

> [!NOTE]
> O template de pull request **não** precisa ficar no repositório: todo repo da organização já herda o [padrão da org](../../PULL_REQUEST_TEMPLATE.md) automaticamente. Só crie um `.github/pull_request_template.md` local se o projeto precisar de algo diferente.
>
> `dependabot.yml`, `AGENTS.md` e o que estiver em `.github/workflows/` **não se herdam** — precisam existir em cada repositório.

## README mínimo

Num monorepo são dois: o da raiz é o **mapa**, o de cada app é o **setup dele**.

### Raiz

````markdown
# <produto>

<uma frase do que é>

| Pacote | Nome no workspace | O que é |
| --- | --- | --- |
| `apps/api` | `@org/api` | <stack, porta> |
| `apps/web` | `@org/web` | <stack, porta> |

## Requisitos
Node <versão> (`.nvmrc`) · pnpm <versão> (`packageManager`) · Docker

## Setup
```bash
pnpm install
cp apps/<app>/.env.example apps/<app>/.env
docker compose up -d
pnpm --filter=./apps/<app> run db:migrate
pnpm dev
```

## Deploy
<como sobe, quem pode subir, como reverter>
````

`pnpm install`, não `pnpm ci` — que não existe. Em CI o `--frozen-lockfile` já é o padrão quando `CI=true`, então não se escreve à mão na máquina de dev.

### Por app

O setup específico, os scripts, e a seção que mais importa:

> A seção **"Particularidades e armadilhas"** é a mais valiosa do README. É onde mora o conhecimento que hoje só existe na cabeça de uma pessoa. Sempre que você descobrir algo do tipo depois de perder duas horas, escreva ali — foi exatamente por não estar escrito que você perdeu as duas horas.

**README é para humano subir o projeto; `AGENTS.md` é para agente escrever código.** Os dois falam de armadilha, mas a do README é "não consegui rodar" e a do `AGENTS.md` é "escrevi errado". Linke um no outro em vez de duplicar.

## O que verifica, e em que ordem

Três camadas, da mais rápida para a mais lenta: os **hooks locais** (segundos, na
sua máquina), o **CI do PR** (minutos, em runner hospedado do GitHub) e o
**deploy** no merge, que roda na VM. As duas últimas estão em
[Deploy](../engineering/deploy.md).

Os hooks são a primeira linha, e vivem só na raiz do repositório.

| Hook | O que roda |
|---|---|
| `pre-commit` | `pnpm exec lint-staged` → Biome no que está no stage |
| `pre-push` | `pnpm turbo run typecheck --affected` |

Instalados pelo `pnpm install` (script `prepare` da raiz). Clonou e o hook não disparou? Rode `pnpm exec husky` — ele grava `core.hooksPath=.husky/_`, que é config local e não vem no clone.

> [!IMPORTANT]
> `git commit --no-verify` existe para emergência, não para pressa. O CI ainda pega no PR, mas descobrir no Actions o que o hook mostraria em 30 segundos é tempo de todo mundo — e, como **merge é deploy**, o que passa pelo review chega no cliente.

Se o projeto tem um artefato gerado que precisa ficar em dia (um `openapi.json`, tipos derivados de schema), vale um step no `pre-push` que regenera e falha se o versionado divergir. É a checagem que mais se paga num monorepo, porque é a que prova que os dois apps continuam compatíveis.

## Quem revisa

**Quem avalia o PR é o sênior do projeto** — quem conhece o produto de perto, não uma regra de caminho de arquivo. Não usamos `CODEOWNERS` (não está disponível no nosso plano para repositório privado), então **quem marca o revisor é o autor do PR**.

Num monorepo isso pede um cuidado a mais: o PR toca `apps/api/` ou `apps/web/`, e quem revisa tem que ser de quem mexe naquele app. Diga no título ou no corpo qual app mudou — sem CODEOWNERS, ninguém é notificado por caminho.

Mudança nos arquivos de raiz (`pnpm-workspace.yaml`, `turbo.json`, `pnpm-lock.yaml`, `packages/`) afeta **todos** os apps de uma vez: essas passam por sênior e valem um aviso no canal.

Migration e mudança de infra passam por sênior sempre. Detalhes em [Code review](../engineering/code-review.md).

## Rigor por criticidade

Nem todo app merece o mesmo cuidado no deploy. **Classifique cada app**, não o repositório: um monorepo pode ter uma API crítica e uma ferramenta interna lado a lado.

| Nível | Significado | Deploy |
|---|---|---|
| **Alta** | Cliente para de trabalhar se cair | Janela combinada, plano de rollback obrigatório |
| **Média** | Impacto sentido, mas há contorno | Horário comercial, avisando o time |
| **Baixa** | Interno ou pouco usado | Livre |

A criticidade também define a urgência de resposta a incidente — ver [Deploy e incidentes](../engineering/deploy-and-incidents.md).

## Documentação de cada produto

**Não fica neste handbook.** Mora no `README.md` e no `AGENTS.md` do próprio repositório, perto de quem mexe no código — é a única forma de a documentação envelhecer junto com o projeto em vez de virar página morta aqui.

O mapa de quais produtos existem, quem é owner e onde cada um roda fica nos canais internos, não em repositório público.

## Checklist de repositório novo

Comece pelo template de monorepo — ele já traz a raiz montada. O que confirmar:

**Uma vez, na raiz**

- [ ] `pnpm-workspace.yaml` com `apps/*` e `packages/*`
- [ ] `package.json` privado, com `packageManager` e `engines` fixos
- [ ] `turbo.json` com `globalDependencies` e `globalPassThroughEnv`
- [ ] `biome.json` com `"root": true`
- [ ] `.nvmrc`
- [ ] `.husky/pre-commit` (lint-staged) e `pre-push` (`turbo run typecheck --affected`)
- [ ] `README.md` mapa
- [ ] `AGENTS.md` + `CLAUDE.md` ponteiro
- [ ] `dependabot.yml`
- [ ] Os arquivos de deploy, se a aplicação vai para a VM ([passo a passo](../engineering/deploy.md#aplicação-nova-passo-a-passo))

**Por app**

- [ ] `package.json` com nome único, que não colide com o do pacote raiz
- [ ] `AGENTS.md` + `CLAUDE.md` ponteiro
- [ ] `README.md` que permite subir o app sem ajuda
- [ ] `.env.example` completo, sem valores
- [ ] `Dockerfile` com `context: .` na raiz
- [ ] `turbo.json` estendendo `//`
- [ ] Criticidade definida

Detalhe de branch, commit e proteção da `main` em [Git e GitHub](../engineering/git-and-github.md).

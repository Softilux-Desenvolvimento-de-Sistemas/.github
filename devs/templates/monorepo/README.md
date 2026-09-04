# Monorepo: a raiz pronta

A raiz de um monorepo nosso em **arquivos de verdade**, mais o roteiro que um
agente segue para montá-la. É o "template de monorepo" que a
[checklist de repositório novo](../../workflow/repo-standards.md#checklist-de-repositório-novo)
manda usar.

Esta página é **procedimento**. O porquê mora em outro lugar, e não se repete
aqui:

| Quer saber | Leia |
|---|---|
| Por que monorepo, app × package, a fronteira, trazer repo existente | [Monorepo](../../engineering/monorepo.md) |
| O que vai no `AGENTS.md`, as camadas, orçamento, skill × rule | [Contexto de agente](../../engineering/agent-context.md) |
| O inventário do que tem que existir na raiz e por app | [Padrão de repositório](../../workflow/repo-standards.md) |
| Quando escrever ADR, e o modelo | [ADR](../adr-template.md) |
| Os arquivos de deploy, que **não** estão aqui | [Deploy](../../engineering/deploy.md#aplicação-nova-passo-a-passo) |

## Peça ao agente

> [!IMPORTANT]
> Abra o Claude Code **dentro do repositório de destino** e cole:
>
> ```
> Siga o padrão de monorepo da Softilux:
> https://raw.githubusercontent.com/Softilux-Desenvolvimento-de-Sistemas/.github/main/devs/templates/monorepo/README.md
> ```

A URL é a do `raw`, não a da página do GitHub — o `blob` devolve HTML, o `raw`
devolve o markdown. Este repositório é público, então não precisa de token nem
do `gh` instalado.

Serve aos dois casos, e a diferença está no que você pede:

- **Repositório novo** — "monte a raiz". O agente cria tudo.
- **Repositório que já existe** — "confira a conformidade". O agente compara
  arquivo por arquivo e **mostra** o que divergiu, em vez de sobrescrever o que
  você já ajustou de propósito.

À mão funciona igual: a tabela abaixo é o mapa de destino.

## Os arquivos

> [!WARNING]
> O que no destino começa com **ponto** está guardado aqui **sem** o ponto.
> Um `.gitignore` de verdade dentro deste diretório passaria a valer para o
> repositório `.github`, e um `.editorconfig` com `root = true` sobrescreveria
> o do handbook. **O nome do destino vem desta tabela, não do nome do arquivo.**

| `files/` | Destino | O que não se mexe |
|---|---|---|
| `package.json` | `package.json` | Privado. Scripts delegam ao turbo; `lint-staged` inline; `packageManager` e `engines` fixos |
| `pnpm-workspace.yaml` | `pnpm-workspace.yaml` | `allowBuilds` é MAPA, e `injectWorkspacePackages: true` |
| `turbo.json` | `turbo.json` | `build` e `typecheck` dependem de `^build` **e** do codegen; `test` e `dev` sem cache |
| `biome.json` | `biome.json` | `"root": true`, TAB, 80 colunas, LF |
| `biome.app.json` | `apps/<app>/biome.json` | `"root": false`, `"extends": "//"` |
| `turbo.app.json` | `apps/<app>/turbo.json` | `"extends": ["//"]`, só o que difere |
| `gitignore` | `.gitignore` | A negação `!.env*.example`, com o glob no **meio** |
| `editorconfig` | `.editorconfig` | `root = true`, TAB, 80 colunas |
| `gitattributes` | `.gitattributes` | `eol=lf` |
| `nvmrc` | `.nvmrc` | É a fonte da versão do Node para o CI e para os Dockerfiles |
| `dockerignore` | `.dockerignore` | — |
| `husky/pre-commit` | `.husky/pre-commit` | `lint-staged`. Hook **só na raiz** |
| `husky/pre-push` | `.husky/pre-push` | `typecheck --affected` |
| `dependabot.yml` | `.github/dependabot.yml` | — |
| `ci.yml` | `.github/workflows/ci.yml` | Biome numa invocação da raiz, nunca `turbo run lint` |
| `docker-compose.yml` | `docker-compose.yml` | Na raiz. `name:` fixo e healthcheck em todo serviço |
| `CLAUDE.md` | `CLAUDE.md`, e um por app | Uma linha: `@AGENTS.md` |
| `claude-rules-generated-files.md` | `.claude/rules/generated-files.md` | O frontmatter `paths:` |
| `adr/README.md` | `docs/adr/README.md` | Numeração independente por escopo |
| `typescript-config/*` | `packages/typescript-config/` | Sem build e sem dependência; entra em `globalDependencies` do turbo |
| `vscode-extensions.json` | `.vscode/extensions.json` | Só `recommendations` — `settings.json` do editor não se versiona |
| `zed-settings.json` | `.zed/settings.json` | Biome como language server |

O prefixo para baixar qualquer um deles:

```
https://raw.githubusercontent.com/Softilux-Desenvolvimento-de-Sistemas/.github/main/devs/templates/monorepo/files/
```

## O roteiro

1. **Nomeie.** Troque `<produto>` em `package.json`, `docker-compose.yml`,
   `ci.yml` e no escopo de `packages/typescript-config/package.json` — e nos
   `tsconfig.json` que o estendem. O placeholder é gritante de propósito:
   `"name": "<produto>"` não é nome npm válido, então copiar sem ler **falha no
   `pnpm install`** em vez de passar calado.
2. **Baixe os arquivos** para os destinos da tabela.
3. **`chmod +x .husky/pre-commit .husky/pre-push`.** O `curl` não preserva o
   modo, e hook sem bit de execução não roda — e não avisa.
4. **`AGENTS.md`.** O `CLAUDE.md` está aqui; o `AGENTS.md` sai de
   [agents-template.md](../agents-template.md), um na raiz e um por app.
5. **`docs/adr/`.** O `README.md` está aqui; o `0000-template.md` é o bloco
   `## Modelo` de [adr-template.md](../adr-template.md).
6. **Ajuste ao que o repositório é de fato** — sem isto o pacote está só
   instalado, não adotado:
   - `pnpm-workspace.yaml`: o catálogo e o `allowBuilds`. Aprove o que o install
     pedir e escreva **na linha** o que aquele script faz.
   - `turbo.json`: `globalPassThroughEnv` com as variáveis da aplicação. Sem ORM
     com codegen, tire `db:generate` do grafo.
   - `ci.yml`: **apague o job `contract`** se ainda não há artefato gerado.
   - `docker-compose.yml`: as imagens da stack.
   - `.claude/rules/generated-files.md`: se não há arquivo gerado, apague.
7. **`pnpm install`.** É ele que grava os hooks, pelo `prepare: husky`.
8. **Rode o gate.**

## O gate

| Comando | O que prova |
|---|---|
| `pnpm install` | `packageManager`, `engines`, `allowBuilds`, e os hooks gravados |
| `pnpm exec biome ci .` | A config da raiz **e** as aninhadas, numa invocação só |
| `pnpm turbo run typecheck` | O grafo de tarefas e o `packages/typescript-config` |
| `pnpm turbo run build` | Que o grafo chega no fim com um app de verdade dentro |

Os dois últimos só dizem algo depois do primeiro app existir. Numa raiz vazia
eles passam sem fazer nada, e isso não é sinal de nada.

## O que este pacote não traz

| O quê | Onde está | Por quê não aqui |
|---|---|---|
| `deploy.yml`, `scripts/deploy.sh`, `docker-compose-prod.yml`, `Caddyfile`, `.env.prod.example`, `deploy-checklist.md` | [Deploy](../../engineering/deploy.md#aplicação-nova-passo-a-passo) | São quatro arquivos com passo a passo próprio, e o script tem as constantes dele no topo, feitas para a cópia |
| O esqueleto do `AGENTS.md` | [agents-template.md](../agents-template.md) | Uma segunda cópia divergiria da primeira |
| O `0000-template.md` de ADR | [adr-template.md](../adr-template.md) | Idem — dois modelos de ADR é um a mais |
| Os apps | — | `apps/` nasce vazio. O que vai dentro é [Padrão de repositório](../../workflow/repo-standards.md#em-cada-app-monorepo) |

O `ci.yml` é a exceção da primeira linha: ele é um dos **quatro** arquivos que a
página de deploy conta, e o modelo dele está aqui porque a checagem do PR existe
mesmo num repositório que nunca vai para a VM.

## Fonte e sincronização

Extraído do monorepo `softilux`, commit `756b0b1`, despersonalizado.

Quando o padrão muda lá, **o PR que muda atualiza os dois lados**. Não há CI
aqui que confira isso, e cópia sem dono é cópia que diverge — se você encontrou
uma divergência entre este diretório e um repositório que está no padrão, ela é
o bug, não a variação.

---

← [Voltar aos Templates](../README.md)

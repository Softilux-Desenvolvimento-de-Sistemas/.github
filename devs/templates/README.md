# 📋 Templates

Modelos prontos para copiar. Cada um traz o template e as notas de uso.

| Página | O que é | Onde vive |
|---|---|---|
| [Monorepo](monorepo/) | A raiz do monorepo, em arquivos prontos | Raiz do repositório |
| [Pull request](pull-request-template.md) | Template de PR | `.github/pull_request_template.md` de cada repo |
| [Retrospectiva](retro-template.md) | Roteiro da retro | Documento da sprint |
| [ADR](adr-template.md) | Registro de decisão de arquitetura | `docs/adr/` do repo, ou do app |
| [AGENTS.md](agents-template.md) | Instrução para agente de IA | `AGENTS.md` da raiz e de cada app |

## O que chega sozinho, e o que não chega

O GitHub distribui automaticamente os *community health files* deste repositório para todo repo da organização que não tenha os seus próprios:

`CONTRIBUTING.md` · `CODE_OF_CONDUCT.md` · `SECURITY.md` · `SUPPORT.md` · `PULL_REQUEST_TEMPLATE.md` · `.github/ISSUE_TEMPLATE/`

**Nada além disso se herda.** Estes precisam existir em cada repositório, e é daí que vem a maior parte da confusão:

`.github/workflows/*` · `dependabot.yml` · `AGENTS.md` e `CLAUDE.md` · `.claude/skills/` · `README.md`

Os arquivos de deploy estão em
[Deploy](../engineering/deploy.md#aplicação-nova-passo-a-passo) — são quatro, e
copiar de uma aplicação que já está no padrão é o caminho previsto.

Os da raiz do monorepo — configuração, hooks, `dependabot.yml` e o **modelo do `ci.yml`**, que é um daqueles quatro — estão em [Monorepo](monorepo/), em arquivos de verdade e não em bloco de código: dá para baixar por URL, e é isso que permite pedir a um agente para montar a raiz, ou para conferir a de um repositório que já existe. Um **repositório template** com o botão "Use this template" continua sendo uma opção, e o conteúdo dele seria exatamente aquele diretório.

O texto normativo (as páginas de `devs/`) **não se distribui: se linka.** Sincronizar cópia de handbook para dentro dos repos é como handbook morre — a cópia diverge e ninguém sabe qual vale.

> [!NOTE]
> O PR template já é aplicado automaticamente pela organização — todo repositório que não tiver o seu próprio herda o [padrão da org](../../PULL_REQUEST_TEMPLATE.md).

---

← [Voltar ao Team Handbook](../README.md)

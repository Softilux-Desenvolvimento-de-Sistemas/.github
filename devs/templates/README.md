# 📋 Templates

Modelos prontos para copiar. Cada um traz o template e as notas de uso.

| Página | O que é | Onde vive |
|---|---|---|
| [Pull request](pull-request-template.md) | Template de PR | `.github/pull_request_template.md` de cada repo |
| [Retrospectiva](retro-template.md) | Roteiro da retro | Documento da sprint |
| [ADR](adr-template.md) | Registro de decisão de arquitetura | `docs/adr/` do repo, ou do app |
| [AGENTS.md](agents-template.md) | Instrução para agente de IA | `AGENTS.md` da raiz e de cada app |

## O que chega sozinho, e o que não chega

O GitHub distribui automaticamente os *community health files* deste repositório para todo repo da organização que não tenha os seus próprios:

`CONTRIBUTING.md` · `CODE_OF_CONDUCT.md` · `SECURITY.md` · `SUPPORT.md` · `PULL_REQUEST_TEMPLATE.md` · `.github/ISSUE_TEMPLATE/`

**Nada além disso se herda.** Estes precisam existir em cada repositório, e é daí que vem a maior parte da confusão:

`.github/workflows/*` · `dependabot.yml` · `AGENTS.md` e `CLAUDE.md` · `.claude/skills/` · `README.md`

Para esses, o veículo é um **repositório template** com a raiz de monorepo já montada — botão "Use this template" no GitHub, sem ferramenta nenhuma para manter. O conteúdo é o desta página mais os arquivos de configuração da raiz, com o catálogo vazio.

O texto normativo (as páginas de `devs/`) **não se distribui: se linka.** Sincronizar cópia de handbook para dentro dos repos é como handbook morre — a cópia diverge e ninguém sabe qual vale.

> [!NOTE]
> O PR template já é aplicado automaticamente pela organização — todo repositório que não tiver o seu próprio herda o [padrão da org](../../PULL_REQUEST_TEMPLATE.md).

---

← [Voltar ao Team Handbook](../README.md)

# Padrão de repositório

Todo repositório nosso segue a mesma estrutura. O objetivo é um só: **qualquer dev do time consegue clonar um projeto que nunca viu e subir na própria máquina seguindo só o README**, sem precisar perguntar nada a ninguém.

Quando isso não acontece, o README está incompleto — não o dev.

## Arquivos na raiz

| Arquivo | Para quê |
|---|---|
| `README.md` | O que é, como rodar, como testar, como deployar |
| `claude.md` | Convenções e regras específicas do projeto |
| `.env.example` | Todas as env vars, **sem valores** |
| `.nvmrc` | Versão do Node |
| `.editorconfig` | Consistência entre editores |
| `biome.json` | Configuração de lint e formatação |
| `docker-compose.yml` | Serviços locais (banco, cache, etc.) |
| `.github/workflows/ci.yml` | Pipeline ([CI/CD](../engineering/ci-cd.md)) |
| `.github/CODEOWNERS` | Revisor automático |
| `.vscode/extensions.json` | Extensões recomendadas |
| `docs/adr/` | [Decisões de arquitetura](../templates/adr-template.md) |

> [!NOTE]
> O template de pull request **não** precisa ficar no repositório: todo repo da organização já herda o [padrão da org](../../PULL_REQUEST_TEMPLATE.md) automaticamente. Só crie um `.github/pull_request_template.md` local se o projeto precisar de algo diferente.

## README mínimo

````markdown
# <repo>

<uma frase do que é>

## Requisitos
Node <versão> · pnpm · Docker

## Setup
```bash
pnpm install
cp .env.example .env
docker compose up -d
pnpm db:migrate
pnpm dev
```

## Scripts
| Comando | O que faz |
|---|---|
| `pnpm dev` | |
| `pnpm test` | |
| `pnpm build` | |

## Deploy
<como sobe, quem pode subir, como reverter>

## Particularidades e armadilhas
<o que quebra fácil, o que parece bug e não é, a decisão estranha que tem motivo>
````

> A seção **"Particularidades e armadilhas"** é a mais valiosa do README. É onde mora o conhecimento que hoje só existe na cabeça de uma pessoa. Sempre que você descobrir algo do tipo depois de perder duas horas, escreva ali — foi exatamente por não estar escrito que você perdeu as duas horas.

## CODEOWNERS

Define quem é revisor automático de cada área. Deixa a ownership explícita sem burocracia:

```
# .github/CODEOWNERS
*                       @org/team-devs
/src/billing/           @org/team-billing
/prisma/                @org/team-seniors
/.github/workflows/     @org/team-seniors
```

Migration e pipeline pedindo review de sênior por padrão é barato e evita a maior parte dos incidentes graves.

## Rigor por criticidade

Nem todo projeto merece o mesmo cuidado no deploy. Classifique e trate de acordo:

| Nível | Significado | Deploy |
|---|---|---|
| **Alta** | Cliente para de trabalhar se cair | Janela combinada, plano de rollback obrigatório |
| **Média** | Impacto sentido, mas há contorno | Horário comercial, avisando o time |
| **Baixa** | Interno ou pouco usado | Livre |

A criticidade também define a urgência de resposta a incidente — ver [Deploy e incidentes](../engineering/deploy-and-incidents.md).

## Documentação de cada produto

**Não fica neste handbook.** Mora no `README.md` e no `claude.md` do próprio repositório, perto de quem mexe no código — é a única forma de a documentação envelhecer junto com o projeto em vez de virar página morta aqui.

O mapa de quais produtos existem, quem é owner e onde cada um roda fica nos canais internos, não em repositório público.

## Checklist de repositório novo

- [ ] `README.md` que permite subir o projeto sem ajuda
- [ ] `claude.md` com as convenções do projeto
- [ ] `.env.example` completo, sem valores
- [ ] `.nvmrc`, `.editorconfig`, `biome.json`
- [ ] `docker-compose.yml` com os serviços locais
- [ ] `ci.yml` com lint, test e build
- [ ] Branch protection com os três como status checks obrigatórios
- [ ] `dependabot.yml`
- [ ] `CODEOWNERS`
- [ ] Environment `production` com required reviewer
- [ ] Criticidade definida

Detalhe de pipeline e proteção em [CI/CD](../engineering/ci-cd.md) e [Git e GitHub](../engineering/git-and-github.md).

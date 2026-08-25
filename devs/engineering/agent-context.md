# Contexto de agente: o `AGENTS.md`

Todo repositório nosso tem um `AGENTS.md`. Ele é o arquivo que um agente de IA lê
antes de escrever qualquer linha — e é o único lugar onde mora a regra específica
do projeto.

Esta página define **o que vai dentro dele**. O modelo pronto para copiar está em
[agents-template.md](../templates/agents-template.md).

## 1. `AGENTS.md` é o canônico; `CLAUDE.md` é ponteiro

Um arquivo, um conteúdo.

```
AGENTS.md     ← o conteúdo mora aqui
CLAUDE.md     ← uma linha: @AGENTS.md
```

`AGENTS.md` é lido por Claude Code, Codex, Cursor, Zed e Copilot. O Claude Code
lê `CLAUDE.md`, não `AGENTS.md` — por isso o ponteiro, que é o mecanismo de import
documentado dele. Manter dois arquivos **com conteúdo** é garantir que um envelhece
sem ninguém perceber.

> **Next.js 16.3+:** o `next dev` gera e reescreve sozinho um bloco delimitado por
> `<!-- BEGIN:nextjs-agent-rules -->`. Ele vive no topo do `AGENTS.md`; o
> `CLAUDE.md` (ponteiro) não o contém. Escreva o que é seu **fora** dos marcadores.

## 2. As camadas, e o que decide onde a regra mora

Três camadas. O critério é **quem quebra se a regra estiver errada**.

| Camada | Mora em | O que vai | Quem quebra |
|---|---|---|---|
| **Organização** | este handbook | Idioma, kebab-case, Biome, `any` proibido, Conventional Commits, PR < 400 linhas | Todo repositório |
| **Repositório** | `AGENTS.md` da raiz | Mapa de apps e packages, comandos que se roda da raiz, fronteira entre pacotes, contrato entre apps, catálogo de dependência | Mais de um app |
| **App** | `apps/<x>/AGENTS.md` | Stack real, arquitetura de pastas, convenção do framework, armadilha do app | Só aquele app |

Num repositório de um app só, as duas últimas camadas colapsam num `AGENTS.md` na
raiz.

> **A regra de ouro: nenhuma camada repete a de cima.** Se o `AGENTS.md` de um app
> diz "código em inglês", ele está errado — isso é da organização, e ele deve
> *linkar*. Repetição é o mecanismo de envelhecimento: a cópia diverge do original
> na primeira mudança, e ninguém sabe qual das duas vale.

## 3. Entra ou não entra

O teste, numa linha:

> **Um agente competente que já leu este handbook erraria isto sozinho?**

Se não erraria, não entra.

### Entra

- **O que é não-óbvio e contra-intuitivo.** *"Entrega e leitura são dois campos
  separados: `clientLastReadAt` e `operatorLastReadAt`."*
- **A decisão de produto que parece esquecimento.** *"Nota de ticket não se remove.
  Não existe `DELETE /tickets/:id/notes/:noteId`, e a ausência é decisão de
  produto."* Sem isso o agente implementa o endpoint achando que está consertando.
- **Onde o arquivo mora, e por quê.** "Quem usa decide": usado por uma rota, mora
  na rota; por duas, sobe para a feature.
- **A armadilha medida, com o sintoma.** *"É `apps/web/server.js`, não `server.js`
  — com o `outputFileTracingRoot` na raiz, o Next espelha o layout do workspace
  dentro do standalone."* Diga **quando acontece, o que se vê, e qual é a causa**.
- **A deriva de versão contra o treino do modelo.** "Zod 4, não Zod 3."
  "`proxy.ts` substituiu `middleware.ts`." "`cookies()` é assíncrono." É o que o
  modelo tem mais chance de errar com confiança.
- **Os comandos**, com o gerenciador certo.

### Não entra

- **O que já está neste handbook** (§2, a regra de ouro).
- **O que se lê no código em 30 segundos.** Lista de rotas, lista de campos,
  assinatura de função. Envelhece a cada PR, e o agente lê melhor no fonte.
- **Tutorial de framework.** O agente sabe React. O que ele não sabe é o *seu*
  React.
- **História e narrativa de migração.** Vai para um `MIGRATION.md` ou um ADR.
- **O trade-off de uma decisão.** Isso é ADR. O `AGENTS.md` diz *o que vale hoje*;
  o ADR diz *por que foi decidido*, e o `AGENTS.md` linka.
- **Backlog e pendência.** Isso é Planio. Um agente lendo "pendências conhecidas"
  pode entender que é escopo do que você pediu.
- **Procedimento passo a passo de tarefa que se repete.** Isso é skill (§6).

## 4. Orçamento

O `AGENTS.md` entra no contexto de **toda** conversa que toca aquele diretório.
Cada linha é paga sempre, inclusive nas conversas que não têm nada a ver com ela.
Arquivo grande também **reduz a aderência**: o agente segue pior um documento longo
do que um curto.

| Situação | Arquivos | Alvo |
|---|---|---|
| Repositório de um app | `AGENTS.md` na raiz | ~200 linhas |
| Monorepo, 2–3 apps | raiz + um por app | raiz ~150, app ~400 |
| Monorepo, 4+ apps | raiz + um por app + um por package com API própria | a raiz encolhe e vira mapa |

**Passou de ~400 linhas, alguma coisa ali é skill, é ADR, é README ou é backlog.**

O número não é arbitrário. No monorepo `softilux`, o guia do front tinha **3.991
linhas**; depois de tirar o que era design system, console de atendimento e
backlog, sobraram **646** — e nada de essencial se perdeu. A diferença era material
de referência que se pagava em toda conversa.

## 5. O esqueleto

Duas variantes, em [agents-template.md](../templates/agents-template.md).

**Raiz de monorepo** — `## Mapa`, `## Comandos` (só os da raiz), `## Fronteira` (o
que um app pode importar do outro), `## O contrato` (como os apps se falam e qual
comando regenera o artefato), `## Dependências`, `## Armadilhas do workspace`,
`## Onde continuar` (ponteiro para cada app).

**Por app** — `## Stack instalada` (versão real, e o que nela diverge do treino do
modelo), `## Comandos`, `## Convenções` (só as **deste** app), `## Estrutura`,
`## Arquitetura`, `## Contrato`, `## Armadilhas`, `## Skills`.

## 6. Quando o conteúdo vira skill

> **Regra** é o que vale para todo arquivo da pasta e fica no `AGENTS.md` — entra
> no contexto sempre. **Skill** é procedimento de uma tarefa que se repete e tem
> passo que se esquece; é carregada só quando o assunto aparece.

Três gatilhos operacionais:

1. **Passa de ~80 linhas e só vale para uma tarefa** → skill.
2. **É sequência de passos com ordem que importa** → skill. Descrição não tem
   ordem; procedimento tem.
3. **Tem material de referência longo** (tabela grande, catálogo, exemplo extenso)
   → skill com arquivos ao lado.

### Mecânica

```
.claude/skills/<nome>/
├── SKILL.md          ← curto: as invariantes + o índice
└── references/       ← o volume, lido só quando necessário
```

O `SKILL.md` é injetado inteiro quando a skill ativa; os `references/` só entram se
o agente os abrir. **Um `SKILL.md` de mil linhas anula o ganho.**

No frontmatter:

- **`description`** é o que fica sempre no contexto — e é o que decide se a skill
  ativa. Escreva **quando usar**, não o que ela faz, e termine com os gatilhos
  ("Use ao criar tela…", "Use quando a validação de um campo mudar"). Diga também o
  que ela **não** cobre. Cabem ~1.500 caracteres.
- **`paths`** limita a ativação a globs. Num monorepo é o que impede a skill do
  front de disparar em arquivo do backend.
- **`user-invocable: false`** para conhecimento de fundo que ninguém chama por
  `/nome`.
- **`allowed-tools`** pré-aprova comandos que a skill manda rodar.

Num monorepo, as skills ficam em `.claude/skills/` **da raiz**, escopadas por
`paths`: elas carregam mesmo quando alguém abre o agente de dentro de um app, e
aparecem no autocomplete desde o começo da sessão. Skill aninhada em
`apps/<x>/.claude/skills/` funciona, mas só é descoberta depois que o agente toca
um arquivo daquele diretório.

### Regra de caminho, sem custo de contexto

Para o aviso que só vale ao abrir um arquivo específico, existe `.claude/rules/`
com `paths` no frontmatter — ele entra no contexto só quando o agente toca um
arquivo que casa. É o lugar certo para "este arquivo é gerado, não edite à mão".

## 7. Manutenção

- **Mudou algo que invalida uma linha do `AGENTS.md`? Atualize no mesmo PR.** Entra
  na checklist de [code review](code-review.md) e no "pronto de verdade" do
  [CONTRIBUTING](../../CONTRIBUTING.md).
- **`AGENTS.md` desatualizado é pior que ausente.** Sem o arquivo o agente lê o
  código; com o arquivo errado, ele confia e erra com convicção.
- Deriva de conteúdo é `[bloqueante]` em review, como `.env.example` incompleto.
- **Conflito entre o `AGENTS.md` de um projeto e este handbook:** o projeto ganha
  **dentro do escopo dele** — stack, arquitetura, convenção de código. Sobre o que
  é da organização (conduta, segurança, fluxo de PR), quem manda é o handbook, e
  divergir é abrir PR aqui.

## 8. Convenções que não se negociam

Este é o piso da organização. **Nenhum `AGENTS.md` repete o que está aqui** — ele
linka.

- **Idioma:** identificador, nome de arquivo, pasta, branch e commit em **inglês**;
  comentário, documentação, mensagem de erro e texto de tela em **português**.
- **Nome de arquivo:** `kebab-case`.
- **Formatação:** Biome, sem discussão e sem comentário de formatação em review.
  Não existe Prettier nem ESLint em projeto novo.
- **Comentário existe onde a próxima pessoa erraria.** Explique o *porquê* não
  óbvio, a armadilha, a decisão que parece bug. Não narre o que o código já diz.
  Pendência marcada é `TODO [#1234]` ou `FIXME`, sempre com o ticket.
- **`any` é proibido.** Tipo derivado (`z.infer`, `Prisma.XGetPayload`) antes de
  tipo escrito à mão.
- **Validação por schema na borda.** O que entra na aplicação passa por Zod antes
  de virar objeto de domínio.
- **Erro tipado**, com código estável para o cliente ramificar. Nunca comparar
  trecho de mensagem: mensagem é para humano e muda sem aviso.

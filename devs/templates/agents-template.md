# Modelo de `AGENTS.md`

O que vai dentro de cada seção, e por quê, está em
[Contexto de agente](../engineering/agent-context.md). Esta página é só o esqueleto
para copiar.

**Onde vive:** `AGENTS.md` na raiz do repositório e um por app, em
`apps/<app>/AGENTS.md`. Ao lado de cada um, um `CLAUDE.md` com **uma linha**:

```
@AGENTS.md
```

---

## Raiz de um monorepo

Alvo: ~150 linhas. Este arquivo entra no contexto de **toda** conversa do
repositório — só entra aqui o que muda a primeira ação de quem chega.

````markdown
# <repo>

<uma frase: o que é o conjunto>. Doc, comentário e mensagem de erro em
**português**; identificador, arquivo, branch e commit em **inglês**.

## Mapa

| Diretório | Pacote | O que é | Guia |
|---|---|---|---|
| `apps/api` | `@org/api` | <stack, porta> | `apps/api/AGENTS.md` |
| `apps/web` | `@org/web` | <stack, porta> | `apps/web/AGENTS.md` |
| `packages/<x>` | `@org/<x>` | <o que é> | — |

**Fronteira:** um app não importa do outro. Eles se falam só por <o contrato>.
Código compartilhado vira `packages/*`.

## Comandos

O gerenciador é o **pnpm**, fixado em `packageManager`. Nunca `npm` ou `yarn`.

```bash
pnpm install                       # na raiz, instala tudo
pnpm dev
pnpm turbo run typecheck           # rode SEMPRE antes de concluir
pnpm exec biome ci .
pnpm turbo run test --filter=./apps/<app>
```

**Filtre por caminho, não por nome** (`--filter=./apps/api`): sobrevive a rename
de pacote.

## Workspace

<As armadilhas do gerenciador: catálogo de dependência e por que cada item está
lá; scripts de build aprovados; o que falha em silêncio.>

## O contrato entre os apps

<Qual é o artefato, qual comando o regenera, o que no CI falha quando ele
defasa.>

## Armadilhas do workspace

<O que quebra e não dá erro óbvio.>

## Git e processo

<O essencial em 5 linhas, com link para o CONTRIBUTING e para o handbook.>

## Onde a decisão mora

| Tipo | Lugar |
|---|---|
| O que vale hoje, por app | `apps/<app>/AGENTS.md` |
| Por que foi decidido | `docs/adr/` |
| Procedimento que se repete | `.claude/skills/` |

## Onde continuar

- `apps/api/AGENTS.md`
- `apps/web/AGENTS.md`
````

---

## Por app (ou repositório de um app só)

Alvo: ~400 linhas num monorepo, ~200 num repositório de um app. Carrega quando o
agente toca um arquivo daquele diretório.

````markdown
# <app> — <o que é>

<Stack com as versões REAIS.> Workspace do monorepo — o mapa e os comandos da raiz
estão no [`AGENTS.md` da raiz](../../AGENTS.md).

## Stack instalada

<Versão de cada peça central, e principalmente o que nela DIVERGE do que o modelo
aprendeu: API renomeada, função que virou assíncrona, versão major recente.>

## Comandos

<Só o que o `package.json` não diz sozinho: o que é destrutivo, o que precisa de
infra de pé, o que tem que rodar antes de concluir.>

## Convenções

<Só as DESTE app. O que é da organização está no handbook e não se repete aqui.
Aspas, ponto e vírgula, alias de import, onde a validação acontece.>

## Estrutura

| Caminho | O que vai |
|---|---|
| … | … |

**Onde o arquivo mora: quem usa decide.** Usado por uma rota, mora na rota; por
duas, sobe. Na dúvida, comece embaixo — promover é mover um arquivo, e adivinhar
errado para cima é manter abstração sem segundo usuário.

## Arquitetura

<As camadas, e principalmente o que cada uma NÃO faz.>

## Contrato

<Com quem este app fala, por qual artefato, e o que acontece quando ele defasa.>

## Armadilhas

<Uma por item, no formato: quando X, você vê Y, a causa é Z.>

## Skills

| Skill | Quando entra |
|---|---|
| `<nome>` | <o gatilho> |
````

---

## Modelo de `SKILL.md`

Quando um bloco do `AGENTS.md` passa de ~80 linhas e só vale para uma tarefa, ele
vira skill. Fica em `.claude/skills/<nome>/SKILL.md`, na raiz do repositório.

````markdown
---
name: <nome-em-kebab-case>
description: >-
  <O QUE cobre, em uma frase densa e específica — cite os nomes que aparecem no
  código.> Use ao <gatilho 1>, ao <gatilho 2>, e quando <gatilho 3>. Não cobre
  <o que fica de fora, e onde isso está>.
paths:
  - apps/<app>/src/**
---

# <título>

<As invariantes: o que vale em QUALQUER arquivo coberto por esta skill. Curto.>

| Arquivo | Quando abrir |
|---|---|
| `references/<x>.md` | <o recorte> |
````

A `description` é a única parte que fica sempre no contexto, e é ela que decide se
a skill ativa. Escreva **quando usar**, não o que ela faz. Cabem ~1.500 caracteres,
e vale usar: descrição vaga é skill que nunca dispara — ou que dispara sempre.

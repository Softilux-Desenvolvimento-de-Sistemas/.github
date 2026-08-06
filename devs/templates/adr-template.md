# ADR — Architecture Decision Record

Registro curto de uma decisão técnica com trade-off relevante.

Existe para responder, daqui a dois anos, a pergunta que mais aparece em base de código antiga: **"por que isso foi feito assim?"**. Sem ADR, a resposta é sempre "ninguém lembra" — e aí alguém refaz a decisão errada, ou tem medo de mexer numa que já não faz mais sentido.

## Quando escrever

- Escolha entre tecnologias (Prisma vs TypeORM, fila vs cron, REST vs eventos)
- Padrão que vai valer para o projeto inteiro
- Decisão difícil de reverter depois
- Decisão que parece estranha vista de fora, mas tem motivo
- Decisão consciente de assumir dívida técnica

## Quando **não** escrever

- Escolha óbvia sem alternativa real
- Detalhe de implementação de uma função
- Algo que já é padrão do time e está no handbook

Regra prática: se a discussão levou mais de 30 minutos, ou se você já explicou a decisão para duas pessoas diferentes, vira ADR.

## Onde fica

No repositório do projeto, não no Notion:

```
docs/adr/
├── 0001-use-prisma-as-orm.md
├── 0002-monorepo-with-pnpm-workspaces.md
└── 0003-background-jobs-with-bullmq.md
```

Numeração sequencial, nome em inglês e kebab-case. No repositório porque ele evolui junto com o código e aparece no review de quem for mexer ali.

ADR **não se edita**. Mudou de ideia? Escreva um novo, marcando o anterior como substituído.

---

## Modelo

```markdown
# ADR 0001 — <título curto da decisão>

**Data:** YYYY-MM-DD
**Status:** proposto | aceito | substituído por ADR-XXXX | descontinuado
**Decisores:** <quem participou>

## Contexto

<Qual problema estamos resolvendo? Que restrições existem — prazo, time,
custo, sistema legado, conhecimento da equipe? Escreva para alguém que
não estava na conversa.>

## Opções consideradas

### Opção A — <nome>
- **Prós:**
- **Contras:**

### Opção B — <nome>
- **Prós:**
- **Contras:**

## Decisão

<Escolhemos a opção X.>

<Por quê. Este é o núcleo do documento — o que pesou mais na escolha.>

## Consequências

**Positivas**
-

**Negativas**
- <Seja honesto. ADR que só lista vantagem é propaganda, não registro.
  O custo que você aceitou hoje é exatamente o que alguém vai encontrar
  daqui a um ano.>

**Neutras / o que muda no dia a dia**
-

## Quando revisitar

<Que condição faria a gente reconsiderar? "Se passarmos de X requisições/s",
"se o time crescer para 10 devs", "quando a versão Y sair".>
```

---

## Exemplo curto

```markdown
# ADR 0003 — Processamento assíncrono com BullMQ

**Data:** 2026-03-14
**Status:** aceito
**Decisores:** time de backend

## Contexto

A emissão de nota fiscal chama uma API externa que leva de 3 a 40 segundos e
falha de forma intermitente. Hoje isso acontece dentro do request HTTP: o
usuário espera, e quando dá timeout não sabemos se a nota foi emitida ou não.

Já usamos Redis em produção para cache.

## Opções consideradas

### Opção A — Cron lendo tabela de pendências
- **Prós:** sem dependência nova, simples de entender
- **Contras:** latência do intervalo do cron, controle de concorrência manual,
  retry e backoff feitos na mão

### Opção B — BullMQ sobre o Redis existente
- **Prós:** retry com backoff pronto, concorrência controlada, painel de
  monitoramento, dead-letter queue
- **Contras:** mais uma dependência, worker separado para operar e deployar

### Opção C — Fila gerenciada (SQS)
- **Prós:** operação zero, escala
- **Contras:** custo, latência de rede, mais uma conta de nuvem para gerenciar,
  ninguém no time tem experiência

## Decisão

Opção B — BullMQ.

O Redis já está em produção e monitorado, o que elimina o principal custo da
opção C. Retry com backoff e dead-letter queue prontos resolvem exatamente a
falha intermitente da API externa, que é o problema central. A opção A nos
faria reimplementar isso pior.

## Consequências

**Positivas**
- Request de emissão responde em ~200ms, devolvendo o status "processando"
- Falha da API externa não é mais perda: retry automático em 5 tentativas
- Fila visível — dá para saber quantas notas estão pendentes

**Negativas**
- Um processo de worker a mais para deployar e monitorar
- O fluxo virou assíncrono: a UI precisa de polling ou notificação, o que não
  existia antes
- Perda do Redis agora afeta emissão, não só cache. Precisa de persistência
  habilitada e de alerta

## Quando revisitar

Se passarmos de ~50k jobs/dia ou se precisarmos de fila entre serviços
diferentes, avaliar fila gerenciada de novo.
```

---

## Dicas

- **Escreva no calor da decisão.** Uma semana depois você já perdeu metade das razões.
- **Uma página.** ADR de cinco páginas ninguém lê, e o objetivo é justamente ser lido.
- **Seja honesto nas consequências negativas.** É a parte mais útil do documento.
- **Cite ADRs no review** quando alguém for contra uma decisão registrada. A conversa muda de "acho que" para "esse motivo ainda vale?".
- **ADRs retroativos valem a pena** em sistema antigo. As 5 a 10 decisões que explicam por que o sistema é como é — especialmente no ILUX, onde esse conhecimento hoje mora numa cabeça só.

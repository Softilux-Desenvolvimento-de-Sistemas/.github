# Sprints e rituais

Sprint de **2 semanas**, de segunda a sexta. Sprint de 1 semana gera cerimônia demais para um time de 5.

Cada sprint tem [número, nome e um objetivo declarado](../culture/sprints.md).

## Agenda fixa

| Quando | Ritual | Duração | Quem |
|---|---|---|---|
| Todo dia, 9h15 | Daily | 15 min | Time |
| Todo dia, 9h30 | Triagem | 20 min | Gestor (+ dev se houver dúvida técnica) |
| Quinta, 14h | Tech sync | 45 min | **Todos, incluindo ILUX** |
| Segunda (início), 9h30 | Planning | 1h | Time |
| Sexta (fim), 14h | Review / demo | 45 min | Time + solicitantes |
| Sexta (fim), 15h | Retrospectiva | 45 min | Time |
| Quinzenal | 1:1 | 30 min | Gestor com cada dev |

Total: cerca de 3h30 por semana em cerimônia. Se passar disso, alguma coisa está errada.

> **Toda reunião recorrente tem link remoto e câmera ligada**, mesmo que só uma pessoa esteja fora. Reunião com quatro pessoas na sala e uma no viva-voz é reunião em que o remoto não participa.

---

## Daily — 15 minutos

Não é relatório para o gestor. É sincronização entre devs.

Cada um responde três coisas, olhando o quadro do Planio:

1. O que concluí desde ontem
2. O que vou fazer hoje
3. O que está me travando

**Regras:**
- Em pé, 15 minutos, cronometrado.
- Discussão técnica que aparecer vira "vamos ver depois da daily" com as pessoas envolvidas. Não prende o time todo.
- Bloqueio anunciado na daily precisa ter dono definido antes de a reunião acabar.
- Faltou? Manda o texto no canal antes das 9h15.

O dev do ILUX tem daily própria (com o gestor, assíncrona por texto) — a daily da sede trata de produtos que ele não toca.

## Planning — 1h

Abre a sprint.

1. **Retrospectiva rápida do que sobrou** (5 min) — o que carrega da sprint anterior
2. **Objetivo da sprint** (15 min) — o gestor traz a proposta, o time discute e fecha. Ver critérios em [Sprints](../culture/sprints.md#o-objetivo-da-sprint)
3. **Seleção de tarefas** (25 min) — puxar do Backlog e confirmar DoR
4. **Capacidade** (10 min) — quem está de férias, quanto sobra
5. **Nome da próxima sprint** (5 min) — quem está na vez anuncia

**Capacidade:** reserve **20%** para imprevisto. Time de 5, sprint de 2 semanas ≈ 50 dias-dev brutos → planeje ~40. Time que planeja 100% da capacidade sempre falha o objetivo, e aí a comemoração nunca acontece.

## Review / demo — 45 min

O que foi feito, mostrado funcionando.

- **Quem fez, apresenta.** O gestor não demonstra o trabalho dos outros.
- Demonstração em ambiente real (homologação), não em slide.
- Solicitantes convidados — é o momento de eles verem o que pediram.
- Fechamento: o objetivo da sprint foi cumprido, renegociado ou não cumprido? Declarado em voz alta.
- Se foi cumprido: comemoração após o expediente ([Recompensas](../culture/rewards.md)).
- Se caiu por fator externo: **o gestor diz isso explicitamente**, para o time não sair com sensação de fracasso próprio.

## Retrospectiva — 45 min

Só o time. Sem coordenador, sem diretoria.

Formato em [Template de retro](../templates/retro-template.md). Regras:

- Foca em processo, nunca em pessoa.
- Sai com **no máximo 2 ações**, cada uma com dono e prazo. Retro que gera 8 ações não gera nenhuma.
- Primeiro item de toda retro: revisar as ações da retro anterior. Se elas nunca acontecem, a retro perdeu credibilidade e o time para de falar.
- Facilitação rotativa entre os devs.

## Tech sync — 45 min, toda quinta

**Esta é a reunião mais importante para a coesão do time.** É onde a pessoa remota deixa de ser ilha e onde todo mundo entende produto que não é o seu.

Um dev por semana apresenta algo, em rodízio:

- Uma decisão de arquitetura que tomou e por quê
- Um bug difícil e como foi caçado
- Um módulo de um produto que os outros não conhecem
- Uma biblioteca ou técnica nova
- Um trecho de código de que se orgulha (ou de que se envergonha)
- O que confundiu no onboarding, se for novo no time

**O dev do ILUX apresenta com a mesma frequência dos outros.** Não é opcional. É a principal ferramenta contra o bus factor 1 daquele produto.

Sem slide obrigatório. Compartilhar tela e falar 20 minutos, 25 de discussão, resolve.

## 1:1 — 30 min, quinzenal

Conversa do dev, não do gestor. Pauta sugerida:

- Como você está — de verdade, não a resposta automática
- O que está travando que eu posso destravar
- Feedback meu para você (específico, com exemplo)
- Feedback seu para mim
- Onde você está na [trilha de carreira](../culture/career-ladder.md) e o que falta

Nunca vira status report de tarefa. Isso é a daily.

---

## Calendário-modelo da sprint

```
SEMANA 1
Seg  09:15 Daily | 09:30 Planning (1h)
Ter  09:15 Daily | 09:30 Triagem
Qua  09:15 Daily | 09:30 Triagem
Qui  09:15 Daily | 09:30 Triagem | 14:00 Tech sync
Sex  09:15 Daily | 09:30 Triagem

SEMANA 2
Seg  09:15 Daily | 09:30 Triagem
Ter  09:15 Daily | 09:30 Triagem
Qua  09:15 Daily | 09:30 Triagem
Qui  09:15 Daily | 09:30 Triagem | 14:00 Tech sync
Sex  09:15 Daily | 09:30 Triagem | 14:00 Review | 15:00 Retro
     18:00 Comemoração, se a sprint foi cumprida
```

Fora dessa agenda, marcar reunião precisa de motivo. O padrão é assíncrono.

## Métricas que acompanhamos

Poucas, e nenhuma delas é meta individual:

| Métrica | O que indica | Como usar |
|---|---|---|
| **Lead time** | Tempo de `Backlog` até `Finalizada` | Está aumentando? Investigue gargalo |
| **Tempo em Code review** | Fila de PR | Passou de 1 dia? Review não está sendo prioridade |
| **Taxa de retrabalho** | Tarefas que voltam da homologação | Alta? O problema está no DoR, não no dev |
| **Objetivos cumpridos** | Qualidade do planejamento | Sempre falha? Planejamento otimista. Sempre sobra? Frouxo |

**Velocity não é meta.** Se virar meta, o time infla estimativa em duas sprints e a métrica morre.

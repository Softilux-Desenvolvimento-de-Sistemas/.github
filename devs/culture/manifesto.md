# Manifesto da equipe

Não é lista de valores de parede. É o combinado de como a gente trabalha no dia a dia.

## 1. Contexto antes de código

Ninguém aqui é executor de ticket. Se a tarefa não faz sentido, se o critério de aceite está estranho, se você acha que existe um caminho melhor — fale **antes** de codar. Perguntar cedo custa 5 minutos; descobrir tarde custa uma sprint.

Se a tarefa chegou até você sem contexto suficiente, ela não deveria ter chegado. Devolva.

## 2. Bloqueio é assunto do time, não seu

Ficar travado é normal. Ficar travado em silêncio não é.

**Regra prática:** 45 minutos batendo no mesmo problema sem progresso → pede ajuda no canal do time. Ninguém vai achar ruim. O que gera problema é o dev que passou dois dias travado e só contou na daily de quinta.

Pedir ajuda não é sinal de júnior. É sinal de quem entende que o custo do time é maior que o orgulho individual.

## 3. Review é prioridade sobre código novo

Um PR parado bloqueia outra pessoa. Seu código novo não bloqueia ninguém. Quando abrir o dia, olhe a fila de review antes de abrir o editor.

Detalhe do SLA e do que olhar em [Code review](../engineering/code-review.md).

## 4. Crítica é no código, nunca na pessoa

- ❌ "isso está errado"
- ❌ "quem escreveu isso?"
- ✅ "aqui a gente pode ter N+1 quando a lista crescer — que tal um `include` no Prisma?"

Toda crítica vem com alternativa ou com pergunta. Se você não tem sugestão, pergunta: "por que esse caminho?" — muitas vezes tem um motivo que você não viu.

E do outro lado: review não é ataque. Se te apontaram 8 coisas, foi porque leram com atenção.

## 5. Escrito > falado

Combinou algo no corredor ou no áudio? Registra na tarefa do Planio ou no PR. O time tem gente remota — o que não está escrito não existe para quem não estava na sala.

Isso vale principalmente para decisão técnica: virou decisão com trade-off, vira [ADR](../templates/adr-template.md).

## 6. Assíncrono por padrão

Reunião é o recurso mais caro do time. Antes de marcar uma, pergunte se um texto bem escrito resolveria. Nossa agenda fixa já está em [Sprints e rituais](../workflow/sprint-rituals.md) — fora dela, marcar reunião precisa de motivo.

Contrapartida: se é assíncrono, responda. Mensagem do time tem SLA de resposta dentro do mesmo dia útil.

## 7. Erro é insumo, não culpa

Quebrou produção? A pergunta é "o que no nosso processo permitiu isso passar?", não "quem foi?". Postmortem aqui é sem nome e sem culpado — o alvo é o processo, sempre.

O que **não** é aceitável é errar em silêncio ou esconder. Quebrou, avisa na hora.

## 8. O time cabe em uma sala, mas não mora todo lá

Temos dev fora da sede. Isso significa:

- Decisão importante não se fecha em conversa presencial sem registro.
- Toda reunião recorrente tem link remoto e câmera ligada.
- Ninguém é "o time" e "o remoto". Somos um time só, com uma pessoa em outro endereço.

## 9. Deixe melhor do que encontrou

Mexeu num arquivo e viu algo pequeno e errado? Corrige. Nome ruim, tipo `any` órfão, teste faltando, doc desatualizada.

Limite: não vire refatoração grande dentro de um PR de feature. Se o conserto passa de ~20 linhas ou muda comportamento, abre tarefa separada.

## 10. Simples primeiro

Não construa para o problema que talvez apareça daqui a um ano. Construa para o problema de hoje, de um jeito que não impeça a evolução de amanhã.

Abstração se ganha na terceira repetição, não na primeira.

---

## O que esperamos de você

- Entrega previsível: se vai atrasar, avise cedo — atraso avisado é replanejamento, atraso descoberto é crise.
- Autonomia crescente: você não precisa saber tudo, mas precisa saber onde procurar.
- Dono do que entrega: acompanhou o deploy, olhou o log, confirmou que funcionou.

## O que você pode esperar da gente

- Prioridade clara: você sempre sabe qual é a coisa mais importante agora.
- Proteção contra ruído: demanda externa passa pela triagem, não cai direto no seu colo.
- Feedback frequente: 1:1 a cada 15 dias, e crítica na hora, não guardada para a avaliação.
- Critério transparente de crescimento: [trilha de carreira](career-ladder.md) escrita, sem surpresa.

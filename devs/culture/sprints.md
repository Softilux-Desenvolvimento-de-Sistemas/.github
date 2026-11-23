# Sprints

Toda sprint aqui tem **número, nome e um objetivo declarado**.

A ideia é simples: sprint com nome próprio é sprint que o time lembra. "A Artemis" comunica mais que "a sprint de março", e o número contínuo conta há quanto tempo o time está entregando — sem ranking, sem competição entre pessoas e sem "funcionário do mês".

## Como funciona

**Formato:** `SPRINT/001 - ARTEMIS`

**Numeração sequencial e contínua.** `001`, `002`… A série nunca reinicia, nem por ano nem por produto. Quem entra no meio entra de onde o time está — e isso já conta a história de quem chegou quando.

**Nome de operação.** Estilo missão espacial: `ARTEMIS`, `AURORA`, `PERSEVERANCE`. Curto, pronunciável, sem relação com o conteúdo técnico da sprint.

**Quem nomeia rotaciona.** A cada sprint, um dev diferente escolhe o nome da **próxima**. A ordem é fixa e pública, e inclui todo mundo — sede e remoto. Se você não quiser nomear, passa a vez sem drama.

> Isso é o ponto crítico do sistema. Se o gestor nomear todas, vira coisa "da chefia" e morre na quarta sprint. O time precisa ser dono disso.

**O símbolo é da sprint.** Cada sprint tem o seu, providenciado pela gestão. Ele identifica a sprint — não é item de coleção individual, não é prêmio e não depende de desempenho de ninguém.

## O objetivo da sprint

Cada sprint tem **um objetivo declarado**, escrito em uma frase, definido no planning e visível durante toda a sprint.

Boas regras para o objetivo:

- É um **resultado**, não uma lista de tarefas. "Checkout do app funcionando ponta a ponta em homologação" é objetivo. "Fechar 12 tickets" não é.
- Cabe em 2 ou 3 entregas. Se precisa de 8 itens para descrever, não é objetivo, é backlog.
- É do time, não de uma pessoa.

### Sprint cumprida, renegociada ou não cumprida

| Situação | O que acontece |
|---|---|
| **Cumprida** | Objetivo entregue. Comemoração ao fim do expediente ([Recompensas](rewards.md)). |
| **Renegociada** | Prioridade externa mudou no meio da sprint e o time, junto com a gestão, redefiniu o objetivo. Conta como cumprida se o novo objetivo foi entregue. |
| **Não cumprida** | O objetivo era alcançável, não mudou nada de fora, e não saiu. Sem comemoração — mas com uma pergunta séria na retro: o que falhou no nosso planejamento? |

> Sprint que falhou por fator externo — cliente sumiu, ambiente caiu, urgência do chefe engoliu a semana — não é falha do time. O gestor tem obrigação de dizer isso em voz alta na review.

## Nota geral

No fim de cada sprint, na review, a gestão dá uma **nota geral de 0 a 10** à
sprint, com duas ou três linhas dizendo por quê. A nota é **da sprint, do time**,
e não de uma pessoa: não entra em avaliação individual nem vira ranking.

O que pesa, nesta ordem:

1. **O objetivo saiu?** Cumprida, renegociada ou não cumprida, como na tabela acima.
2. **Chegou ao cliente?** Tarefa finalizada que não está em produção conta pela metade.
3. **Qualidade da primeira entrega:** quantas passaram de primeira na revisão de
   código, e quanto tempo as devolvidas levaram para voltar.
4. **Previsibilidade:** horas apontadas ÷ estimadas, e quanto do planejado saiu.
5. **Higiene do processo:** PR dentro do limite de 400 linhas, prints, docs e
   skills em dia, CI verde de verdade.

Os números vêm do Planio (a versão da sprint) e do relatório de fim de sprint.

## Registro

O histórico vive nesta tabela, atualizada no fim de cada sprint:

| # | Nome | Período | Objetivo | Resultado | Nota | Nomeada por |
|---|---|---|---|---|---|---|
| **001** | VOYAGER | 13/10 – 28/10/2026 | Implementação completa do ILUX DESK em produção | Cumprida, com ressalvas | **5,0** | Renan Rosa Schlemper |
| **002** | APOLO | 04/11 – 20/11/2026 | Implementação e correções finais para deixar o ILUX DESK pronto para produção: resolver as pendências de Suporte e de Implantação, específicas de cada setor, levantadas na reunião pós-VOYAGER | Cumprida | **7,5** | Renan Rosa Schlemper |

### SPRINT/001 - VOYAGER — 5,0

O DESK foi para produção, mas a sprint fechou com 12 de 17 tarefas finalizadas,
4 de volta para ajuste e 1 não iniciada. Só 5 das 16 entregas passaram de primeira
na revisão (31%), e "Finalizada" queria dizer "na `main`", não "no ar". As duas
tarefas do Google (#15916 e #15933) ficaram abertas. O ponto bom foi a estimativa:
74 h estimadas e 74 h apontadas (1,00×), contra 2,7× na sprint de teste.

### SPRINT/002 - APOLO — 7,5

Escopo entregue: 17 de 18 tarefas finalizadas e **todas em produção** no fim da
sprint (a única não iniciada, #16027, entrou no dia 17/11). A primeira entrega
melhorou para 11 de 17 de primeira (65%), e as devolvidas voltaram corrigidas em
até dois dias, pelos próprios devs. O que segurou a nota: a estimativa piorou
(1,30× nas tarefas estimadas), vários PRs passaram de mil linhas contra um limite
de 400, e um defeito de segurança na importação da Biblioteca (#16011, conteúdo
interno podendo ir para pasta pública) só foi pego na revisão.

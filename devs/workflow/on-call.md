# Plantonista da sprint

Um dev por sprint, em rodízio, absorve tudo que é interrupção. Os outros quatro trabalham blindados.

Em time pequeno cuidando de vários produtos, este é provavelmente o mecanismo de maior impacto do handbook inteiro. Sem ele, todo mundo é interrompido o tempo todo e ninguém entra em foco profundo.

## O que o plantonista faz

- Atende bug urgente e chamado de produção
- Responde dúvida de outras áreas sobre sistemas
- Faz o primeiro diagnóstico de incidente ([Deploy e incidentes](../engineering/deploy-and-incidents.md))
- É o primeiro revisor padrão de PRs, para a fila não parar
- Cuida de tarefa pequena que apareceu no meio da sprint
- Registra no Planio tudo que chegou por fora

## O que o plantonista **não** faz

- Não assume tarefa grande da missão. A capacidade dele na sprint é planejada em **50%**, e o resto é reserva.
- Não vira suporte de nível 1 permanente. Se a demanda for recorrente e operacional, a resposta é automatizar, documentar ou devolver para a área correta — não absorver para sempre.
- Não fica sozinho num incidente grave. Ele é o primeiro a responder, não o único responsável.

## Rodízio

- Um plantonista por sprint, definido no planning.
- A ordem é pública e previsível, e todo mundo passa — inclusive sênior.
- Trocar é permitido, combinando entre os dois e avisando no canal.
- O dev do ILUX faz plantão apenas do ILUX; os produtos são diferentes demais para plantão cruzado hoje.

> Se um dia der para o plantão ser cruzado, é sinal de que o bus factor do ILUX foi resolvido. Bom indicador de meta.

| Missão | Plantonista |
|---|---|
| — | _Rodízio ainda não iniciado_ |

> [!NOTE]
> **Ainda não há escala de plantão.** Enquanto o rodízio não começar, toda interrupção fora do fluxo vai para o **responsável da equipe**, que absorve ou redireciona. A escala é montada e publicada aqui junto com a primeira sprint — o restante desta página já vale como o processo que será seguido.

## Como uma interrupção vira trabalho

1. Chegou pedido fora do fluxo → o plantonista atende
2. Leva menos de 30 min e é claramente necessário? Faz e registra a tarefa no Planio depois
3. Leva mais que isso? Abre tarefa e manda para triagem, avisando o solicitante do prazo
4. É urgência real (produção parada, cliente bloqueado)? Trata na hora e avisa o gestor **imediatamente**, porque isso pode custar o objetivo da missão

Nada é feito sem virar registro. Trabalho invisível é trabalho que não conta na capacidade da próxima sprint, e é assim que o time parece lento sem motivo aparente.

## Passagem de bastão

Na review de sexta, o plantonista que sai passa em 5 minutos:

- O que ficou pendente
- Qual sistema andou instável
- Qual demanda recorrente merece virar tarefa de verdade

## Sinal de alerta

Se o plantonista consome **mais de 50% do tempo** em interrupção por duas ou três sprints seguidas, o problema não é o plantão — é qualidade, ou é ausência de processo em outra área. Isso vira pauta de retro e conversa com a coordenação, com os números na mão.

O registro de tudo no Planio é o que permite ter esses números.

# Ciclo da demanda

Do momento em que alguém pede algo até o momento em que está em produção.

## O problema que este fluxo resolve

Coordenadores e diretoria abrem tarefas no Planio a qualquer momento. Sem um filtro, isso chega cru no colo do dev, e o time passa a ser reativo: trabalha no que gritou mais alto, não no que importa mais.

A triagem é esse filtro. **Nenhuma demanda vai direto do solicitante para o dev.**

## Estados no Planio

```
Nova → Triagem → Backlog → Selecionada (sprint) → Em desenvolvimento
     → Code review → Homologação → Pronta p/ deploy → Concluída
```

Estados laterais: `Aguardando informação`, `Bloqueada`, `Recusada / Arquivada`.

| Estado | Significado | Quem move |
|---|---|---|
| **Nova** | Recém-aberta por qualquer pessoa da empresa | Solicitante |
| **Triagem** | Sendo avaliada pela gestão do time | Gestor |
| **Backlog** | Aprovada, priorizada, pronta para entrar numa sprint | Gestor |
| **Selecionada (sprint)** | Faz parte da missão atual | Gestor no planning |
| **Em desenvolvimento** | Alguém está trabalhando nela agora | Dev |
| **Code review** | PR aberto aguardando revisão | Dev |
| **Homologação** | Em `main`/homologação, aguardando validação do solicitante | Dev |
| **Pronta p/ deploy** | Validada, aguardando janela de produção | Solicitante ou gestor |
| **Concluída** | Em produção e funcionando | Dev |
| **Aguardando informação** | Falta informação do solicitante | Qualquer um |
| **Bloqueada** | Dependência externa impede o andamento | Dev |
| **Recusada / Arquivada** | Não vamos fazer, com justificativa escrita | Gestor |

**Regra de ouro:** uma tarefa tem **um responsável** e **um estado**. Se você não sabe de quem é ou em que pé está, o processo falhou.

---

## Triagem

**Quando:** todo dia útil, 9h30, 20 minutos. Janela fixa.
**Quem:** gestor. Sênior de plantão pode participar quando houver dúvida técnica.

Toda tarefa em `Nova` sai da fila **no mesmo dia**. Não existe tarefa em Nova por mais de 24h.

Para cada uma, uma das quatro saídas:

| Saída | Quando | O que fazer |
|---|---|---|
| → **Backlog** | Faz sentido, é prioridade, dá para fazer | Preencher DoR, estimar tamanho, priorizar |
| → **Aguardando informação** | Falta contexto, critério ou acesso | Comentar exatamente o que falta e atribuir ao solicitante |
| → **Recusada** | Não faz sentido, duplicada, fora de escopo | Justificar por escrito. Sempre justificar |
| → **Escalada** | É grande, é estratégica ou muda prioridade de outra coisa | Levar para o coordenador/diretoria antes de aceitar |

O que a triagem entrega para o time é previsibilidade: o solicitante sabe que foi visto no mesmo dia, e o dev nunca recebe demanda crua.

### Urgência de verdade

Existe. Produção caiu, cliente parado, prazo legal. Nesses casos:

1. Vai direto para o **plantonista da sprint** ([ver página](on-call.md)).
2. A tarefa é criada no Planio **mesmo assim** — depois, se preciso, mas é criada.
3. Se a urgência engolir a sprint, o objetivo da missão é **renegociado** na hora, não silenciosamente abandonado.

O que **não** é urgência: "o diretor perguntou", "é rapidinho", "só mudar uma coisinha". Isso vai para a triagem como qualquer outra coisa.

---

## Definition of Ready (DoR)

Uma tarefa só entra no Backlog se tiver:

- [ ] **Objetivo claro** — o que se quer alcançar e por quê, em linguagem de negócio
- [ ] **Produto/sistema identificado** — em qual repositório isso acontece
- [ ] **Critério de aceite** — como saberemos que está pronto, testável
- [ ] **Solicitante identificado** — quem valida na homologação
- [ ] **Prioridade** e prazo real, se houver
- [ ] **Dependências mapeadas** — depende de outra tarefa, área ou terceiro?
- [ ] **Anexos** — print, log, exemplo, layout, quando aplicável

Sem isso: `Aguardando informação`. Não é burocracia — é o que evita o dev descobrir na sexta que entendeu errado na segunda.

### Exemplo

❌ **Ruim:** "Ajustar relatório de vendas"

✅ **Bom:**
> **Objetivo:** o setor comercial precisa comparar vendas por vendedor entre dois períodos, hoje isso é feito exportando dois relatórios e cruzando no Excel (~2h/semana).
>
> **Critério de aceite:**
> - Tela de relatório permite selecionar dois intervalos de data
> - Exibe, por vendedor: total do período A, do período B, variação absoluta e percentual
> - Exportação em XLSX mantendo as mesmas colunas
> - Vendedor sem venda em um dos períodos aparece com zero, não some da lista
>
> **Produto:** portal-comercial
> **Solicitante:** <!-- nome -->

---

## Definition of Done (DoD)

Uma tarefa só vai para `Concluída` com **tudo** abaixo:

- [ ] Código na `main` via PR aprovado
- [ ] CI verde (lint, testes, build)
- [ ] Testes cobrindo o comportamento novo, quando aplicável ([Testes](../engineering/testing.md))
- [ ] Critérios de aceite verificados um a um
- [ ] Validado pelo solicitante em homologação
- [ ] Deployado em produção e conferido (log limpo, funcionalidade testada em prod)
- [ ] Documentação atualizada, se mudou setup, env var ou contrato de API
- [ ] Tarefa do Planio atualizada com o que foi feito e link do PR

> "Terminei, só falta subir" não é concluída. "Subiu, mas não conferi" também não.

---

## Estimativa

Usamos **tamanho**, não hora:

| Tamanho | Referência | Sinal |
|---|---|---|
| **P** | Até meio dia | — |
| **M** | 1 a 2 dias | — |
| **G** | 3 a 5 dias | Avalie quebrar |
| **GG** | Mais de uma semana | **Quebre.** Sempre. |

Tarefa GG não entra em sprint. Ela vira um conjunto de tarefas menores, cada uma entregando algo verificável.

Estimativa é do **time**, não do gestor, e não é promessa contratual. Errou muito? Vira assunto de retro, não de cobrança individual.

---

## Fluxo do dev, na prática

1. Pego a próxima tarefa de `Selecionada (sprint)` e movo para `Em desenvolvimento`
2. Leio critério de aceite. Não entendi? Pergunto **antes** de começar
3. Crio a branch: `feature/1234-short-description` ([Git e GitHub](../engineering/git-and-github.md))
4. Desenvolvo, commitando pequeno e frequente
5. Abro o PR, movo a tarefa para `Code review`
6. Ajusto o que o review apontou
7. Merge → `Homologação`. Aviso o solicitante que está pronto para validar
8. Validado → `Pronta p/ deploy` → deploy → confiro em produção → `Concluída`

## Fluxo do ILUX

O ILUX (ERP) roda em **kanban contínuo**, não em sprint — manutenção de ERP tem demanda de fluxo, não de lote. Os estados do Planio são os mesmos, e a triagem também. O que muda:

- Sem planning quinzenal; a priorização é revisada semanalmente com o gestor.
- Limite de WIP: no máximo 2 tarefas em `Em desenvolvimento` ao mesmo tempo.
- Entra na mesma numeração de missões, para efeito de emblema, acompanhando o calendário das sprints do restante do time.
- Participa obrigatoriamente do tech sync semanal e da retro.

> **Risco conhecido:** hoje o ILUX tem um único dev com conhecimento profundo. Isso é bus factor 1 num produto crítico. Reduzir esse risco (documentação, ADRs, um segundo dev com familiaridade de leitura) é meta permanente, não projeto opcional.

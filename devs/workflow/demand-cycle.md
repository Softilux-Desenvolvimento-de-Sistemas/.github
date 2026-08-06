# Ciclo da demanda

Do momento em que alguém pede algo até o momento em que está em produção.

## O problema que este fluxo resolve

Coordenadores e diretoria abrem tarefas no Planio a qualquer momento. Sem um filtro, isso chega cru no colo do dev, e o time passa a ser reativo: trabalha no que gritou mais alto, não no que importa mais.

A triagem é esse filtro. **Nenhuma demanda vai direto do solicitante para o dev.**

## Estados no Planio

```
Nova → Analisar → Backlog → Em desenvolvimento
     → Desenv. finalizado → Em teste → Finalizada
```

Estado lateral: `Stand by`.

| Estado | Significado | Quem move |
|---|---|---|
| **Nova** | Recém-aberta por qualquer pessoa da empresa | Solicitante |
| **Analisar** | Sendo avaliada pela gestão do time | Gestor |
| **Backlog** | Aprovada e priorizada, pronta para alguém pegar | Gestor |
| **Em desenvolvimento** | Alguém está trabalhando nela agora | Dev |
| **Desenv. finalizado** | Código pronto, revisado e na `main` | Dev |
| **Em teste** | Onde a gente testa e o solicitante homologa | Dev, depois solicitante |
| **Finalizada** | Em produção e funcionando | Dev |
| **Stand by** | Parada: falta informação, ou trava numa dependência externa | Dev |

**Regra de ouro:** uma tarefa tem **um responsável** e **um estado**. Se você não sabe de quem é ou em que pé está, o processo falhou.

### Stand by

É o único estado lateral, e serve para os dois casos em que a tarefa para por motivo que não é você:

- **Falta informação** do solicitante para continuar.
- **Dependência externa** trava o andamento — outra área, terceiro, fornecedor.

Quem move para `Stand by` comenta na tarefa **o que falta e de quem depende**. Sem isso, ela vira tarefa fantasma: ninguém sabe por que parou nem quem destrava.

Tarefa em `Stand by` não conta no seu limite de trabalho em andamento — mas conta na sua responsabilidade de cobrar quem está devendo.

---

## Triagem

É o que acontece enquanto a tarefa está na coluna `Analisar`.

**Quando:** todo dia útil, 9h30, 20 minutos. Janela fixa.
**Quem:** gestor, com apoio de um dev quando houver dúvida técnica.

Toda tarefa em `Nova` sai da fila **no mesmo dia**. Não existe tarefa em Nova por mais de 24h.

Para cada uma, uma das quatro saídas:

| Saída | Quando | O que fazer |
|---|---|---|
| → **Backlog** | Faz sentido, é prioridade, dá para fazer | Preencher DoR e priorizar |
| → **Stand by** | Falta contexto, critério ou acesso | Comentar exatamente o que falta e atribuir ao solicitante |
| → **Recusada** | Não faz sentido, duplicada, fora de escopo | Justificar por escrito e arquivar. Sempre justificar |
| → **Escalada** | É grande, é estratégica ou muda prioridade de outra coisa | Levar para o coordenador/diretoria antes de aceitar |

O que a triagem entrega para o time é previsibilidade: o solicitante sabe que foi visto no mesmo dia, e o dev nunca recebe demanda crua.

### Urgência de verdade

Existe. Produção caiu, cliente parado, prazo legal. Nesses casos:

1. **A equipe se junta e resolve.** Quem estiver mais próximo do problema puxa, quem tiver contexto ajuda. O objetivo é encerrar o quanto antes, não proteger o planejamento de ninguém.
2. A tarefa é criada no Planio **mesmo assim** — depois, se preciso, mas é criada.
3. Se a urgência engolir a semana, o que estava planejado é **renegociado** na hora, não silenciosamente abandonado.

O que **não** é urgência: "o diretor perguntou", "é rapidinho", "só mudar uma coisinha". Isso vai para a análise como qualquer outra coisa.

---

## Definition of Ready (DoR)

Uma tarefa só entra no Backlog se tiver:

- [ ] **Objetivo claro** — o que se quer alcançar e por quê, em linguagem de negócio
- [ ] **Produto/sistema identificado** — em qual repositório isso acontece
- [ ] **Critério de aceite** — como saberemos que está pronto, testável
- [ ] **Solicitante identificado** — quem homologa em `Em teste`
- [ ] **Prioridade** e prazo real, se houver
- [ ] **Dependências mapeadas** — depende de outra tarefa, área ou terceiro?
- [ ] **Anexos** — print, log, exemplo, layout, quando aplicável

Sem isso: `Stand by`. Não é burocracia — é o que evita o dev descobrir na sexta que entendeu errado na segunda.

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

Uma tarefa só vai para `Finalizada` com **tudo** abaixo:

- [ ] Código na `main` via PR aprovado
- [ ] CI verde (lint, testes, build)
- [ ] Testes cobrindo o comportamento novo, quando aplicável ([Testes](../engineering/testing.md))
- [ ] Critérios de aceite verificados um a um em `Em teste`
- [ ] Homologado pelo solicitante
- [ ] Deployado em produção e conferido (log limpo, funcionalidade testada em prod)
- [ ] Documentação atualizada, se mudou setup, env var ou contrato de API
- [ ] Tarefa do Planio atualizada com o que foi feito e link do PR

> "Terminei, só falta subir" não é finalizada. "Subiu, mas não conferi" também não.

---

## Fluxo do dev, na prática

1. Pego a próxima tarefa de `Backlog` e movo para **`Em desenvolvimento`**
2. Leio o critério de aceite. Não entendi? Pergunto **antes** de começar
3. Crio a branch: `feature/1234-short-description` ([Git e GitHub](../engineering/git-and-github.md))
4. Desenvolvo, commitando pequeno e frequente
5. Abro o PR e peço review ([Code review](../engineering/code-review.md))
6. Ajusto o que o review apontou
7. Merge na `main` → movo para **`Desenv. finalizado`**
8. Movo para **`Em teste`**: confiro o critério de aceite um a um em homologação e chamo o solicitante para validar
9. Homologado → deploy → confiro em produção → **`Finalizada`**

**Travou no meio do caminho?** `Stand by`, com comentário dizendo o que falta e de quem depende. Não deixe a tarefa parada em `Em desenvolvimento` fingindo que anda.

> **`Em teste` é o estado que mais engana.** É onde a gente testa **e** onde o solicitante homologa — duas coisas, na ordem. Chamar o solicitante antes de você mesmo ter conferido o critério de aceite queima a confiança dele no time rápido. Confira primeiro.

## Fluxo do ILUX

O ILUX (ERP) roda em **kanban contínuo**, não em sprint — manutenção de ERP tem demanda de fluxo, não de lote. Os estados do Planio são os mesmos, e a triagem também. O que muda:

- Sem planning quinzenal; a priorização é revisada semanalmente com o gestor.
- Limite de WIP: no máximo 2 tarefas em `Em desenvolvimento` ao mesmo tempo.
- Acompanha o calendário das sprints do restante do time.
- Participa obrigatoriamente do tech sync semanal e da retro.

> **Risco conhecido:** hoje o ILUX tem um único dev com conhecimento profundo. Isso é bus factor 1 num produto crítico. Reduzir esse risco (documentação, ADRs, um segundo dev com familiaridade de leitura) é meta permanente, não projeto opcional.

# Deploy e incidentes

Esta página é o **processo**: quando pode subir, o que conferir, o que fazer
quando cai. O **mecanismo** — o que dispara o deploy, o contrato que cada
repositório cumpre e o que ele não resolve — está em
[Padrão de deploy](deploy-standard.md).

## Deploy

### Janelas

| Quando | Pode subir? |
|---|---|
| Segunda a quinta, 9h – 16h | Sim |
| Sexta antes das 12h | Só se necessário e com alguém acompanhando |
| Sexta após as 12h | Não |
| Véspera de feriado | Não |
| Fora do expediente | Só hotfix |

A regra não é superstição: é ter gente acordada e disponível quando o problema aparecer. Ninguém quer descobrir o bug no sábado de manhã.

> [!IMPORTANT]
> **Merge é deploy.** Push na branch principal dispara a subida sozinho ([Padrão de deploy](deploy-standard.md)), então a janela acima se aplica ao **botão de merge**. Não existe mais "mergeia agora, sobe depois": PR aprovado na sexta às 17h espera segunda.
>
> Quem faz o merge é o autor — logo, a janela é responsabilidade de quem aperta o botão.

### Atualização que exige parar a produção

Migration pesada, troca de infra, versão que derruba o sistema durante a subida — **nada disso sobe em horário de expediente.** Com o cliente trabalhando, uma janela de indisponibilidade de 20 minutos custa mais que a madrugada inteira de quem subiu.

Esse tipo de deploy é feito **fora do expediente, em plantão combinado**:

- **Combinado com antecedência**, não no mesmo dia. Quem participa sabe com dias de folga.
- **Escalado entre os devs que vão participar** — quem conhece a mudança e quem consegue reverter. Não é o time inteiro acordado sem função.
- **Papéis definidos antes de começar**: quem executa, quem confere, quem aciona o resto se der errado.
- **Plano de rollback testado**, não imaginado. Fora do expediente não há a quem perguntar.
- **O cliente é avisado** da janela de indisponibilidade antes, não durante.

Quem entra em plantão de deploy compensa as horas. Subir de madrugada é trabalho, não favor — e time que trata isso como favor para de se voluntariar na terceira vez.

### Antes de subir

- [ ] Lint, typecheck, build e teste limpos **na sua máquina** — não existe CI que os rode ([hooks locais](../workflow/repo-standards.md#os-hooks-são-a-única-verificação-automática))
- [ ] Validado com o solicitante **antes do merge** — não há homologação, então o merge já é o cliente
- [ ] Migration revisada, reversível, e que funciona **com a versão anterior do código**
- [ ] Env vars novas já no arquivo de ambiente do servidor **e** no `.example` do PR
- [ ] Plano de rollback claro, com o SHA anterior anotado
- [ ] Alguém além de você sabe que o deploy está acontecendo

> [!NOTE]
> As duas primeiras linhas já disseram "CI verde na `main`" e "validado em homologação". Nenhuma das duas existe no nosso plano, e checklist que treina o time a marcar caixinha falsa estraga o checklist inteiro. O que existe está em [Padrão de deploy](deploy-standard.md#o-que-este-padrão-não-resolve).

### Migration em produção

O ponto onde mais se erra feio.

- Migration destrutiva (drop, mudança de tipo) roda **separada** do deploy de código, nunca junto
- Mudança de coluna em tabela grande: avalie lock e tempo de execução antes
- Padrão de duas fases para mudança que quebra compatibilidade:
  1. Deploy do código que funciona com o schema antigo **e** com o novo
  2. Migration
  3. Deploy do código que só usa o novo
- Backup verificado antes de qualquer migration destrutiva. "Tem backup" não basta — alguém precisa saber restaurar

### Depois de subir

- [ ] Aplicação responde
- [ ] Fluxo alterado testado **em produção**, não só em homologação
- [ ] Log limpo nos primeiros 15 minutos
- [ ] Tarefa do Planio movida para `Finalizada`
- [ ] Time avisado no canal

Deploy sem conferência não é deploy, é aposta.

### Rollback

Reverter cedo é sempre melhor que investigar demorando. Ordem:

1. Reverter o deploy para a versão anterior
2. Confirmar que normalizou
3. **Só então** investigar, com calma

Se a migration não for reversível, o rollback de código pode não bastar — é por isso que migration reversível é obrigatória.

Como o rollback acontece na prática, e por que ele reverte **imagem** e nunca **migration**: [Padrão de deploy](deploy-standard.md#quando-falha).

---

## Incidentes

Incidente = produção com comportamento errado afetando usuário real.

### Severidade

| Nível | Definição | Resposta |
|---|---|---|
| **SEV1** | Sistema fora, cliente parado, perda de dados | Imediata, todos que forem necessários |
| **SEV2** | Funcionalidade importante quebrada, há contorno | Mesmo dia |
| **SEV3** | Problema pontual, impacto pequeno | Vira tarefa priorizada |

### Fluxo de SEV1 / SEV2

**1. Avisar (primeiro, sempre)**

No canal do time, antes de investigar:

```
🔴 SEV1 — <sistema>
Sintoma: <o que o usuário vê>
Início: <quando começou>
Impacto: <quem está afetado>
Investigando: <seu nome>
```

Avisar leva 30 segundos e evita três pessoas investigando a mesma coisa em silêncio.

**2. Estabilizar antes de entender**

A prioridade é o usuário voltar a trabalhar, não descobrir a causa. Rollback, feature flag, desligar a rotina problemática — o que resolver mais rápido.

Causa raiz vem depois, com o sistema de pé.

**3. Definir papéis, se for grande**

- **Condutor** — coordena, decide, comunica. Não põe a mão no código
- **Investigador** — mexe no sistema
- **Comunicador** — atualiza as áreas afetadas

Em incidente pequeno, uma pessoa acumula os três. Em SEV1 que passa de 30 minutos, separe — quem está com a cabeça no log não consegue responder a diretoria ao mesmo tempo.

**4. Atualizar a cada 30 minutos**, mesmo sem novidade. Silêncio faz todo mundo perguntar, e perguntar interrompe quem está resolvendo.

**5. Encerrar formalmente**

```
✅ Resolvido — <sistema>
Duração: <tempo>
Causa: <uma frase>
Correção: <o que foi feito>
Postmortem: <link, até 48h>
```

### Regras durante incidente

- Não mexa em produção sozinho e em silêncio
- Anote o que você fez, na hora. Depois ninguém lembra a ordem dos fatos
- Não faça mudança grande "já que estou aqui". Menor diff possível
- Cansaço causa erro. Incidente longo pede troca de pessoa

---

## Postmortem

Obrigatório para SEV1 e SEV2. Prazo: 48h.

**Blameless, de verdade.** Sem nome de pessoa no documento. A pergunta é sempre "o que no nosso processo permitiu isso chegar em produção?".

Se alguém sair de um postmortem sentindo que foi julgado, o próximo incidente será escondido — e aí você perdeu muito mais que um incidente.

### Modelo

```markdown
# Postmortem — <título> — <data>

## Resumo
<2 a 3 frases: o que aconteceu, quanto tempo durou, quem foi afetado>

## Impacto
- Duração:
- Usuários afetados:
- Perda de dados: sim/não
- Impacto financeiro estimado:

## Linha do tempo
| Hora | Evento |
|---|---|
| 14:02 | Deploy da versão X |
| 14:11 | Primeiro erro no log |
| 14:23 | Primeiro relato de usuário |
| 14:25 | Incidente aberto |
| 14:38 | Rollback concluído |
| 14:45 | Normalizado |

## Causa raiz
<o que de fato causou — técnico e de processo>

## Por que não pegamos antes
<esta é a seção mais importante do documento>
- O teste não cobria este caso porque...
- O review não pegou porque...
- O monitoramento não alertou porque...

## O que funcionou bem
<sério: o que evitou que fosse pior>

## Ações
| Ação | Dono | Prazo | Tarefa |
|---|---|---|---|
| | | | |
```

**Ações precisam ser concretas.** "Ter mais cuidado" e "melhorar a comunicação" não são ações. "Adicionar teste e2e para o fluxo de pagamento com cartão recusado" é.

Toda ação vira tarefa no Planio, com prioridade real. Postmortem cujas ações nunca são executadas é teatro, e o time percebe na segunda vez.

O postmortem é apresentado no tech sync seguinte. É a forma mais eficiente de todo mundo aprender com um erro que só uma pessoa cometeu.

---

## Monitoramento

O mínimo para cada produto em produção:

- [ ] Log centralizado e pesquisável
- [ ] Alerta de erro (Sentry ou equivalente)
- [ ] Healthcheck de disponibilidade
- [ ] Alerta chegando em canal que alguém realmente lê

**Ferramenta em uso:** Grafana — endereço e credenciais de acesso com o responsável do setor.

**Alerta que ninguém olha é pior que alerta nenhum** — ele treina o time a ignorar notificação. Se um alerta dispara direto sem indicar problema real, conserte o alerta ou apague.

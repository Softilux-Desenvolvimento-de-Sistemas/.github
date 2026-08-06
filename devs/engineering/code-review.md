# Code review

Review não é controle de qualidade do gestor. É como o conhecimento circula num time pequeno e como ninguém vira dono exclusivo de uma parte do sistema.

## SLA

| Situação | Prazo de primeira resposta |
|---|---|
| PR normal | **4 horas úteis** |
| Hotfix | Imediato, fura a fila |
| PR grande (>400 linhas) | Mesmo dia, avisando quando vai olhar |

**Review tem prioridade sobre código novo.** Seu PR parado não bloqueia ninguém; o PR do colega bloqueia ele. Abriu o dia: olhe a fila antes de abrir o editor.

Se você não vai conseguir revisar no prazo, diga no canal para outra pessoa pegar. Silêncio é o pior resultado.

## Quem revisa

- 1 aprovação é o mínimo
- `CODEOWNERS` sugere automaticamente
- Migration, pipeline e mudança de infra pedem review de sênior
- Ninguém pegou o PR? Cobre no grupo. Persistindo, o gestor designa o revisor — PR parado por falta de dono é problema do time, não de quem abriu
- Júnior pode e deve revisar PR de sênior. Aprender a ler código dos outros é metade da senioridade

## Como revisar

Ordem que funciona:

1. **Leia a descrição e a tarefa do Planio primeiro.** Entender o objetivo antes do diff.
2. **Olhe o desenho geral.** Os arquivos e a separação fazem sentido? Erro estrutural encontrado aqui custa barato; encontrado depois de 30 comentários de detalhe, custa caro.
3. **Depois o detalhe.** Lógica, edge case, nome, tipo.
4. **Rode se for relevante.** Mudança de UI ou fluxo crítico merece subir localmente.

### O que olhar

**Correção**
- Resolve o problema descrito na tarefa?
- Edge case: lista vazia, `null`, erro de rede, valor negativo, timeout, concorrência
- Tratamento de erro existe e é útil?

**Segurança**
- Entrada validada antes de chegar ao banco?
- Autorização checada, não só autenticação? (o usuário pode ver **este** registro?)
- Nada de segredo, chave ou token no código
- Sem query concatenando string de input

**Dados e performance**
- N+1 em loop de query
- Query sem índice em campo filtrado
- Migration reversível e segura em tabela grande
- Paginação onde a lista pode crescer

**Manutenção**
- Segue os [padrões de código](code-standards.md)?
- Nome diz o que a coisa faz?
- Abstração criada na primeira repetição? (não abstraia ainda)
- Teste cobrindo o comportamento novo? ([Testes](testing.md))

### O que **não** revisar

Formatação, aspas, ponto e vírgula, ordem de import, largura de linha. Isso é trabalho do Biome, e o CI reprova sozinho. Comentário humano sobre estilo é ruído.

## Como comentar

Marque a natureza do comentário. Isso elimina a maior parte do atrito:

| Prefixo | Significado |
|---|---|
| **[bloqueante]** | Precisa ser resolvido antes do merge |
| **[sugestão]** | Melhoraria, mas não impede o merge |
| **[dúvida]** | Não entendi, me explica |
| **[nit]** | Detalhe pequeno, fica a seu critério |
| **[elogio]** | Gostei disso. Use — review só com crítica desgasta |

Exemplos:

```
[bloqueante] Se `items` vier vazio, esse reduce quebra sem valor inicial.
Sugiro `reduce((acc, i) => ..., 0)`.

[sugestão] Dá para trocar esses dois finds por um Map e evitar o O(n²)
quando a lista crescer.

[dúvida] Por que a validação ficou no controller e não no DTO?
Talvez tenha um motivo que eu não vi.

[nit] `data` é bem genérico aqui — `invoiceItems` diria mais.

[elogio] Esse teste de timezone é exatamente o caso que já nos mordeu antes.
```

**Regras de tom:**
- Crítica vem com alternativa ou com pergunta. Nunca "isso está errado" seco.
- Fale do código, nunca da pessoa: "essa função faz duas coisas", não "você misturou responsabilidade".
- Não repita o mesmo apontamento em 10 lugares. Comente uma vez e diga "mesmo caso nos outros pontos".
- Se a discussão passar de três idas e voltas, chame no áudio de 5 minutos e depois registre a conclusão no PR.

## Recebendo review

- Review é sobre o código, não sobre você. Oito comentários significa que alguém leu com atenção.
- Responda a **todos** os comentários, nem que seja com 👍 ou "feito".
- Discordou? Argumente. Revisor não é chefe e pode estar errado. Se não convergirem, chamem um terceiro.
- Ajustou? Responda no comentário com o commit, não apenas resolva silenciosamente.
- Não force-push depois que o review começou — quebra a visualização de "mudanças desde a última revisão".

## Autorreview

Antes de marcar como "Ready for review", leia seu próprio diff no GitHub. Você vai encontrar sozinho `console.log` esquecido, arquivo que não devia estar ali, código comentado e trecho que não faz mais sentido.

Cinco minutos de autorreview economizam trinta de review alheio.

## Aprovação

| Estado | Quando usar |
|---|---|
| **Approve** | Pode ir. Ainda pode ter `[sugestão]` e `[nit]` pendentes |
| **Comment** | Deixei observação mas não sou eu quem decide |
| **Request changes** | Tem `[bloqueante]`. Use com moderação e sempre explicando |

Aprovar com "sugestão" pendente é bom sinal de maturidade: significa que você confia no colega para decidir o detalhe e não segurou o trabalho dele por preferência pessoal.

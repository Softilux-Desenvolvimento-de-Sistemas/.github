# Testes

Teste aqui não é meta de cobertura nem ritual de qualidade. É o que permite mexer em código que você não escreveu, num produto que roda em cliente, sem medo.

> **Precedência:** o `claude.md` de cada projeto manda. Esta página é o padrão para projeto novo e para o que não está especificado em lugar nenhum.

## Ferramenta

**Vitest** em todos os projetos TypeScript. Sem Jest em projeto novo — a configuração dupla (ESM, transform, path alias) custa mais do que entrega.

| Camada | Ferramenta |
|---|---|
| Unitário e integração | Vitest |
| Componente React | Vitest + Testing Library |
| HTTP (NestJS) | Vitest + Supertest |
| E2E | Playwright |
| Mobile | Vitest + React Native Testing Library |

Scripts padronizados em todo repositório:

```bash
npm test               # watch, uso local
npm run test:run       # execução única, é o que o CI roda
npm run test:cov       # relatório de cobertura
```

---

## O que testar

A pergunta não é "qual a porcentagem", é **"se isso quebrar, alguém percebe antes do cliente?"**.

**Sempre:**

- Regra de negócio — cálculo, desconto, imposto, prazo, permissão, transição de estado
- Bug corrigido — todo `fix` nasce com um teste que falha antes e passa depois. Sem exceção
- Fluxo crítico de dinheiro ou dado do cliente
- Contrato de API — status, formato da resposta, validação de entrada
- Função com muitos caminhos (`if` aninhado, `switch`, tratamento de erro)

**Normalmente não:**

- Getter, setter, DTO puro
- Componente que só recebe prop e renderiza texto
- Configuração e wiring de framework
- Código de terceiro. Não teste o Prisma, o Nest ou o React

**Nunca:**

- Teste que só existe para subir cobertura. Ele custa manutenção e não pega bug
- Teste que verifica implementação em vez de comportamento

### Comportamento, não implementação

O teste tem que sobreviver a uma refatoração. Se você renomeou um método privado e 12 testes quebraram, os testes estavam errados, não o código.

```ts
// ❌ testa como foi feito
expect(service.calculateTaxInternal).toHaveBeenCalledWith(100);

// ✅ testa o que acontece
expect(invoice.total).toBe(118.5);
```

---

## Como escrever

### Estrutura

Arquivo ao lado do código, com sufixo `.spec.ts`:

```
invoice-service.ts
invoice-service.spec.ts
```

E2E fica separado, em `e2e/`.

### Nome do teste

Descreve o comportamento em português, em uma frase que faz sentido lida em voz alta:

```ts
describe("InvoiceService.calculateTotal", () => {
  it("soma os itens e aplica o imposto do estado", () => { ... });
  it("retorna zero quando a fatura não tem item", () => { ... });
  it("lança NotFoundException quando o cliente não existe", () => { ... });
});
```

Não escreva `it("should work")` nem `it("test 1")`. O nome do teste é a documentação que aparece quando ele falha às 2h da manhã.

### Arrange, Act, Assert

Três blocos, separados por linha em branco:

```ts
it("aplica desconto progressivo acima de 10 itens", () => {
  const order = makeOrder({ items: 12, unitPrice: 100 });

  const total = calculateTotal(order);

  expect(total).toBe(1080);
});
```

Um `it` testa **uma** coisa. Se você precisa de três `expect` sobre assuntos diferentes, são três testes.

### Factory, não fixture gigante

```ts
// test/factories/order.ts
export function makeOrder(overrides: Partial<Order> = {}): Order {
  return {
    id: "ord_1",
    customerId: "cus_1",
    items: [],
    status: "pending",
    createdAt: new Date("2025-01-01T00:00:00Z"),
    ...overrides,
  };
}
```

O teste declara **só o que importa para ele**. `makeOrder({ status: "cancelled" })` deixa óbvio que o teste é sobre cancelamento.

### Edge case é o teste que vale

O caminho feliz raramente quebra. Cubra:

lista vazia · `null` e `undefined` · zero · valor negativo · string vazia · data no limite do fuso · erro de rede · timeout · duas requisições simultâneas na mesma linha

---

## Mock

**Mocke a borda, não o meio.** Banco em teste de integração é real (container). O que se mocka é o que está fora do nosso controle:

| Mockar | Não mockar |
|---|---|
| API de terceiro | Nosso próprio service |
| Envio de e-mail e SMS | Banco em teste de integração |
| Gateway de pagamento | Função pura |
| Relógio (`vi.useFakeTimers`) | Repositório em teste de integração |

Teste com mock demais passa a testar o mock. Se o setup do teste tem 30 linhas de `vi.mock`, o problema é o acoplamento do código, não o teste.

**Tempo é determinístico.** Nada de `new Date()` solto dentro de regra de negócio — injete o relógio ou congele com `vi.setSystemTime`. Teste que quebra em janeiro é teste que o time aprende a ignorar.

---

## Banco de dados

Teste de integração roda contra **Postgres de verdade**, em container, com o mesmo schema de produção. SQLite em memória "para ir mais rápido" testa um banco que você não usa.

- O CI já sobe o serviço Postgres e roda as migrations ([CI/CD](ci-cd.md))
- Cada teste limpa o que criou, ou roda dentro de transação com rollback
- Teste não depende da ordem de execução nem de dado deixado por outro
- Nunca aponte teste para banco de homologação

---

## React e componente

Teste o que o usuário vê e faz, não o estado interno.

```tsx
it("mostra o erro quando o e-mail é inválido", async () => {
  render(<LoginForm />);

  await userEvent.type(screen.getByLabelText("E-mail"), "invalido");
  await userEvent.click(screen.getByRole("button", { name: "Entrar" }));

  expect(await screen.findByText("E-mail inválido")).toBeVisible();
});
```

- Busque por **papel e texto acessível** (`getByRole`, `getByLabelText`), não por `data-testid` nem classe CSS. Se não dá para achar pelo papel, provavelmente tem problema de acessibilidade
- `userEvent`, não `fireEvent`
- Snapshot só para saída realmente estável. Snapshot grande ninguém lê, todo mundo aprova com `-u`

---

## E2E

Poucos e certeiros. E2E é caro para rodar e caro para manter.

- Cubra os **3 a 5 fluxos que, se quebrarem, o cliente para de trabalhar**: login, o fluxo principal do produto, o que envolve dinheiro
- Roda em `main` e antes do deploy de produção — não em todo PR, salvo com a label `run-e2e` ([CI/CD](ci-cd.md))
- Teste E2E instável (*flaky*) é pior que teste ausente: ensina o time a ignorar vermelho. Conserte no mesmo dia ou remova

---

## Cobertura

**Não temos meta numérica de cobertura, e isso é proposital.** Meta de porcentagem produz teste de getter.

O que olhamos:

- Cobertura **caiu** num PR que adicionou regra de negócio → pergunta no review
- Arquivo de regra crítica com cobertura baixa → tarefa, não bronca
- 100% num módulo → provavelmente tem teste inútil ali

Se um número ajuda a calibrar: regra de negócio tende a ficar acima de 80% naturalmente, sem ninguém perseguir isso.

---

## Quando o teste falha

1. **Não faça `skip`.** Teste pulado é dívida invisível. Se precisa pular, abra a tarefa e coloque o ID no `it.skip` ao lado
2. Falhou no CI e passa local? Suspeite de ordem, tempo, fuso ou estado compartilhado — nessa ordem
3. Teste falhando na `main` é bloqueio do time inteiro. Vale a mesma regra do pipeline: conserta em 30 min ou reverte

---

## No dia a dia

- Rode `npm test` em watch enquanto desenvolve. Feedback de 2 segundos muda como você escreve código
- Antes de abrir o PR: `npm run test:run` local. Deixar o CI descobrir é desperdício de fila
- Correção de bug: escreva o teste que falha **primeiro**. É a única forma de saber que o teste realmente pega aquele bug
- Revisando PR: "tem teste cobrindo isso?" é pergunta legítima, e é item do [code review](code-review.md) e da [DoD](../workflow/demand-cycle.md#definition-of-done-dod)

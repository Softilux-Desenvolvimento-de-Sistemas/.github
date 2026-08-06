# Padrões de código

> **Precedência:** o `claude.md` de cada projeto manda. Se ele contradiz esta página, siga o projeto. Isto aqui é o padrão para projeto novo e para o que não está especificado em lugar nenhum.

## Idioma

- **Código, nomes, variáveis, arquivos, branches e commits: inglês.**
- Documentação, comentário e comunicação: português.

Sem meio-termo tipo `calcularTotalOrder`.

## Nomes de arquivo e pasta

**kebab-case minúsculo**, sempre:

```
create-user.ts
user-table.tsx
app.service.ts
invoice-repository.ts
use-debounce.ts
```

Nunca `CreateUser.ts`, `userTable.tsx` ou `Invoice_Repository.ts`. Case-insensitive no Windows e case-sensitive no Linux é fonte garantida de bug que só aparece no deploy.

## Formatação

**Biome**, sem discussão. `pnpm biome check --write` resolve. O CI reprova o que estiver fora.

Não existe review sobre estilo — se você está comentando aspas ou indentação num PR, pare.

## Comentários

Raríssimos, em português, e **apenas** quando explicam o *porquê* de algo não óbvio:

```ts
// A API do fornecedor retorna a data em UTC-3 sem indicar o fuso,
// por isso normalizamos antes de comparar com o vencimento.
const dueDate = normalizeSupplierDate(payload.date);
```

Não escreva:

```ts
// incrementa o contador
counter++;
```

Se o código precisa de comentário para ser entendido, geralmente ele precisa é de nomes melhores ou de ser quebrado em funções.

**Marcadores:**
- `// TODO: <descrição> [#1234]` — só com tarefa aberta no Planio. TODO órfão é lixo
- `// FIXME:` — só se estiver indo para produção com dívida consciente e registrada

---

## TypeScript

**`any` é proibido.** Não sabe o tipo? Use `unknown` e faça o narrowing. Precisou mesmo de `any`? Justifique no PR.

```ts
// ❌
function parse(data: any) { ... }

// ✅
function parse(data: unknown) {
  const parsed = schema.parse(data);
  ...
}
```

**Prefira `type` a `interface`**, exceto quando precisar de declaration merging ou implementar em classe.

**Tipos derivados em vez de duplicados:**

```ts
type CreateUserInput = Omit<User, "id" | "createdAt" | "updatedAt">;
type UserSummary = Pick<User, "id" | "name" | "email">;
```

**Retorno explícito em função exportada.** Inferência é ótima internamente, mas em fronteira de módulo o tipo explícito é documentação e trava contra mudança acidental.

**Erro tipado, não string solta:**

```ts
// ❌
throw new Error("not found");

// ✅
throw new NotFoundException(`Invoice ${id} not found`);
```

**Validação de entrada externa com schema** (Zod ou class-validator, conforme o projeto). Nada vindo de rede, arquivo ou env entra no sistema sem validação — tipo do TS não existe em runtime.

---

## React / Next.js

**Estrutura por feature, não por tipo de arquivo:**

```
src/
├── features/
│   └── invoices/
│       ├── components/
│       │   ├── invoice-table.tsx
│       │   └── invoice-filters.tsx
│       ├── hooks/
│       │   └── use-invoices.ts
│       ├── services/
│       │   └── invoice-service.ts
│       └── types.ts
├── components/ui/      # componentes genéricos, sem regra de negócio
├── lib/                # utilitários
└── app/                # rotas
```

`components/`, `hooks/` e `services/` na raiz, com tudo dentro, funciona até uns 20 arquivos e depois vira lixeira.

**Componentes:**
- Função nomeada, não arrow anônima exportada como default
- Props tipadas explicitamente
- Um componente por arquivo (exceto subcomponente privado usado só ali)
- Componente acima de ~150 linhas é sinal de que tem lógica para extrair para hook

**Estado:**
- Estado de servidor é do React Query/SWR, não do `useState`. Não guarde resposta de API em estado local manualmente
- Estado de formulário: React Hook Form + schema
- Estado global só quando realmente compartilhado. Contexto para tudo é overhead

**Não faça:**
- `useEffect` para derivar valor que dá para calcular no render
- Lógica de negócio dentro do JSX
- `key={index}` em lista que pode reordenar

## React Native

Vale tudo acima, mais:

- Sem estilo inline em componente que renderiza em lista
- `FlatList` com `keyExtractor` e item memoizado em lista longa
- Teste em Android e iOS antes de marcar como pronto. "Funciona no meu emulador" não é validação

---

## NestJS

**Módulos, com responsabilidade separada:**

```
src/
├── modules/
│   └── invoices/
│       ├── dto/
│       │   ├── create-invoice.dto.ts
│       │   └── update-invoice.dto.ts
│       ├── invoices.controller.ts
│       ├── invoices.service.ts
│       ├── invoices.module.ts
│       └── invoices.repository.ts
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
└── config/
```

**Responsabilidade de cada camada:**

| Camada | Faz | Não faz |
|---|---|---|
| Controller | Recebe requisição, valida via DTO, delega, devolve resposta | Regra de negócio, acesso a banco |
| Service | Regra de negócio, orquestração | Conhecer HTTP (req, res, status) |
| Repository | Acesso a dados | Regra de negócio |

Se o controller tem `if` de regra de negócio, está errado. Se o service importa `Request` do Express, está errado.

**DTO sempre.** Toda entrada de rota passa por DTO com validação. `ValidationPipe` global com `whitelist: true` e `forbidNonWhitelisted: true`.

**API REST:**

```
GET    /invoices
GET    /invoices/:id
POST   /invoices
PATCH  /invoices/:id
DELETE /invoices/:id
```

- Substantivo no plural, sem verbo na URL (`/invoices/:id/cancel` é aceitável para ação que não é CRUD)
- Status correto: 200, 201, 204, 400, 401, 403, 404, 409, 422, 500
- Erro com corpo padronizado, via exception filter global
- Listagem sempre paginada. Endpoint que retorna "todos" quebra quando o cliente crescer

---

## Banco de dados

**Nomenclatura:**
- Tabela: `snake_case` plural — `invoice_items`
- Coluna: `snake_case` — `created_at`
- Chave estrangeira: `<entidade>_id` — `customer_id`
- Índice: `idx_<tabela>_<colunas>`

O mapeamento para camelCase é feito pelo ORM. No TS você usa `createdAt`, no banco é `created_at`.

**Migrations:**
- Sempre versionadas, nunca `db push` em ambiente compartilhado
- Uma migration por mudança lógica
- **Reversível.** Escreva o `down` e teste
- Migration destrutiva (drop de coluna, mudança de tipo) em tabela grande: PR separado, review de sênior, e combinada com a janela de deploy
- Nunca edite migration já aplicada em produção. Crie outra

**Modelagem:**
- Toda tabela com `id`, `created_at`, `updated_at`
- Dinheiro em `decimal`, jamais em `float`
- Timestamp em UTC, conversão na borda da aplicação
- Restrição no banco (`not null`, `unique`, FK), não só na aplicação. Aplicação tem bug; constraint não

---

## Estrutura e arquivos

- **Crie o mínimo de arquivos que faz sentido.** Não abra um arquivo para uma função de três linhas usada num lugar só
- Um arquivo com uma responsabilidade clara. Se o nome tem "and" ou "utils", provavelmente faz coisa demais
- `utils.ts` genérico vira depósito. Prefira `date-utils.ts`, `currency-utils.ts`
- Import absoluto (`@/features/...`), não relativo profundo (`../../../`)

## Tratamento de erro

- Não engula erro. `catch` vazio ou que só faz `console.log` é bug esperando acontecer
- Log com contexto: id da entidade, id do usuário, operação. `console.log(error)` sozinho não ajuda ninguém às 2h da manhã
- Erro esperado (validação, não encontrado) é fluxo, não exceção genérica
- Erro inesperado sobe e é capturado no handler global, com log completo
- Nunca vaze stack trace ou mensagem de banco para o cliente

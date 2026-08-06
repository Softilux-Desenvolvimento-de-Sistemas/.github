# CI/CD

**GitHub Actions** em todos os repositórios.

Princípio: **pipeline rápido é pipeline usado.** Meta de 5 minutos no CI de PR. Passou de 10, o time começa a fazer merge sem esperar — e aí o CI não serve para nada.

## Pipeline de PR

Roda em todo push para branch com PR aberto. Três jobs em paralelo:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm biome ci .
      - run: pnpm tsc --noEmit

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    env:
      DATABASE_URL: postgresql://test:test@localhost:5432/test
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm db:migrate:deploy
      - run: pnpm test:run

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
```

**Detalhes que importam:**

- `concurrency` com `cancel-in-progress`: push novo cancela a execução anterior. Economia real de tempo de fila
- `--frozen-lockfile`: falha se o lock estiver dessincronizado do `package.json`. É o que impede "na minha máquina funciona"
- `node-version-file: .nvmrc`: uma única fonte de verdade para a versão do Node
- `cache: pnpm`: sem isso o install domina o tempo do pipeline
- `tsc --noEmit` no job de lint: erro de tipo tem que reprovar o PR

Esses três jobs são os **status checks obrigatórios** na branch protection ([Git e GitHub](git-and-github.md#branch-protection-em-main)).

## Deploy

Merge em `main` → deploy automático em **homologação**.

Produção é **manual**, com aprovação:

```yaml
name: Deploy Production

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production   # exige aprovação configurada no GitHub
    steps:
      - uses: actions/checkout@v4
      # passos de deploy do projeto
```

Use **GitHub Environments** para produção, com required reviewers. É o que garante que ninguém sobe sozinho às 18h de sexta sem alguém saber.

## Segredos

- Segredo de pipeline vive em **GitHub Secrets** (repositório ou organização), nunca no YAML
- Segredo de organização para o que é compartilhado (registry, cloud); de repositório para o específico
- Nunca faça `echo` de segredo em step de debug — o mascaramento do Actions falha com valor transformado (base64, JSON)

## Boas práticas

**Fixe a versão das actions** por major (`actions/checkout@v4`). Para action de terceiro em pipeline com acesso a segredo, fixe pelo SHA do commit.

**Permissão mínima** no topo do workflow:

```yaml
permissions:
  contents: read
```

Só amplie no job que precisa.

**Não rode e2e em todo PR** se ele for lento. Rode em `main` e antes do deploy, ou em label específica:

```yaml
  e2e:
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e')
```

**Dependabot ativo**, com agrupamento para não gerar 15 PRs por semana:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    groups:
      minor-and-patch:
        update-types: [minor, patch]
```

Atualização de dependência entra como tarefa `chore` na sprint, não fica acumulando por seis meses até virar migração de major impossível.

## Quando o CI quebra na `main`

`main` vermelha é bloqueio do time inteiro — ninguém consegue fazer merge com confiança.

1. Quem quebrou conserta, com prioridade sobre qualquer outra coisa
2. Não dá para consertar em ~30 min? **Reverta** o PR e conserte com calma na branch
3. Avise no canal do time em qualquer um dos casos

Reverter não é vergonha. Deixar a `main` quebrada por meio dia é.

## Checklist de repositório novo

- [ ] `ci.yml` com lint, test e build
- [ ] Branch protection com os três como status checks obrigatórios
- [ ] `dependabot.yml`
- [ ] `pull_request_template.md`
- [ ] `CODEOWNERS`
- [ ] Environment `production` com required reviewer
- [ ] Secrets configurados
- [ ] Deploy automático em homologação funcionando

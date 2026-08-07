# CI/CD

**GitHub Actions** em todos os repositórios.

Princípio: **pipeline rápido é pipeline usado.** Meta de 5 minutos no CI de PR. Passou de 10, o time começa a fazer merge sem esperar — e aí o CI não serve para nada.

---

## Ambientes

| Ambiente | Onde roda | O que dispara | Quem acessa |
|---|---|---|---|
| **Local** | Máquina do dev | `docker compose up` | O dev |
| **Homologação** | APL-001, containers com sufixo `-stg` | Merge na `main`, automático | Time e solicitante, via VPN |
| **Produção** | APL-001 | Promoção manual com aprovação | Ninguém por SSH. Só o pipeline |

> [!NOTE]
> Chamamos de **homologação**. `stg` nos nomes de container e subdomínio é abreviação de *staging* — é a mesma coisa, mantida por ser convenção de mercado em ferramenta.

Homologação tem banco próprio, em container no APL-001, **nunca** apontando para os bancos de produção. Migration errada em homologação não pode virar incidente de produção.

---

## O princípio central: build único

A imagem é construída **uma vez**, no merge para a `main`, e a **mesma imagem** é promovida para produção depois.

```
merge na main → build da imagem → GHCR
                                    ├── deploy automático em homologação
                                    └── promoção manual para produção
```

Buildar de novo na hora de subir para produção publica um artefato que ninguém validou: a `main` avançou desde a homologação, uma dependência mudou de patch, a base image foi atualizada. O binário não é o mesmo que o solicitante aprovou — e aí a homologação não garante nada.

> [!IMPORTANT]
> Workflow de produção **não faz `checkout` e não faz build.** Se ele estiver fazendo, está errado.

Isso é o que sustenta o [DoD](../workflow/demand-cycle.md#definition-of-done-dod): "homologado pelo solicitante" só tem valor se o que ele homologou for exatamente o que subiu.

---

## Pipeline de PR

Roda em todo push para branch com PR aberto. Três jobs em paralelo:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npx biome ci .
      - run: npx tsc --noEmit

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
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run db:migrate:deploy
      - run: npm run test:run

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run build
```

**Detalhes que importam:**

- `concurrency` com `cancel-in-progress`: push novo cancela a execução anterior. Economia real de tempo de fila
- `npm ci`: instala exatamente o que está no `package-lock.json` e falha se ele estiver dessincronizado do `package.json`. É o que impede "na minha máquina funciona". Nunca use `npm install` no CI — ele reescreve o lock
- `node-version-file: .nvmrc`: uma única fonte de verdade para a versão do Node
- `cache: npm`: sem isso o install domina o tempo do pipeline
- `tsc --noEmit` no job de lint: erro de tipo tem que reprovar o PR
- Projeto com MySQL troca o `service` por `mysql:8.0` com `--health-cmd "mysqladmin ping"`

Esses três jobs são os **status checks obrigatórios** na branch protection ([Git e GitHub](git-and-github.md#branch-protection-em-main)).

---

## Build da imagem e deploy em homologação

Dispara no merge para a `main`, depois do CI passar.

```yaml
# .github/workflows/deploy-homolog.yml
name: Deploy Homologação

on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

permissions:
  contents: read
  packages: write

jobs:
  deploy:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    environment: homolog
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_sha }}

      - name: Define o nome da imagem
        id: image
        run: |
          echo "name=ghcr.io/$(echo '${{ github.repository }}' | tr '[:upper:]' '[:lower:]')" >> "$GITHUB_OUTPUT"

      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.image.outputs.name }}:${{ github.event.workflow_run.head_sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Deploy
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.APL_HOST }}
          username: deploy
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          envs: IMAGE_TAG
          script: |
            set -euo pipefail
            cd /srv/${{ github.event.repository.name }}
            IMAGE_TAG=$IMAGE_TAG docker compose -f compose.yml -f compose.stg.yml -p ${{ github.event.repository.name }}-stg pull
            IMAGE_TAG=$IMAGE_TAG docker compose -f compose.yml -f compose.stg.yml -p ${{ github.event.repository.name }}-stg run --rm api npm run db:migrate:deploy
            IMAGE_TAG=$IMAGE_TAG docker compose -f compose.yml -f compose.stg.yml -p ${{ github.event.repository.name }}-stg up -d
        env:
          IMAGE_TAG: ${{ github.event.workflow_run.head_sha }}
```

**Detalhes que importam:**

- O nome da imagem no GHCR precisa ser **minúsculo**. O nome da nossa organização tem maiúsculas, então o `tr` não é frescura — sem ele o push falha
- `-p <projeto>-stg` isola rede, volumes e nomes de container. É o que permite homologação e produção convivendo na mesma máquina sem se enxergar
- A tag é o **SHA do commit**, não `latest`. `latest` impossibilita saber o que está rodando e impossibilita rollback
- `cache-from/to: type=gha` reaproveita camadas entre builds. Sem isso o build domina o tempo do pipeline
- Migration roda como **step separado**, antes do `up -d`, nunca no entrypoint do container. No entrypoint, com mais de uma réplica, as duas tentam migrar ao mesmo tempo

---

## Promoção para produção

Recebe a tag da imagem **já validada em homologação**. Não faz checkout, não builda.

```yaml
# .github/workflows/deploy-production.yml
name: Deploy Produção

on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: "SHA da imagem validada em homologação"
        required: true

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy com verificação e rollback
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.APL_HOST }}
          username: deploy
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          envs: NEW_TAG,APP
          script: |
            set -euo pipefail
            cd /srv/$APP
            COMPOSE="docker compose -f compose.yml -f compose.prd.yml -p $APP-prd"

            PREVIOUS=$(cat .current-tag 2>/dev/null || echo "")

            IMAGE_TAG=$NEW_TAG $COMPOSE pull
            IMAGE_TAG=$NEW_TAG $COMPOSE run --rm api npm run db:migrate:deploy
            IMAGE_TAG=$NEW_TAG $COMPOSE up -d
            echo "$NEW_TAG" > .current-tag

            for i in $(seq 1 30); do
              if curl -fsS http://localhost:3000/health > /dev/null; then
                echo "Aplicação saudável na tentativa $i"
                exit 0
              fi
              sleep 2
            done

            echo "Health check falhou após 60s"
            if [ -n "$PREVIOUS" ]; then
              echo "Revertendo para $PREVIOUS"
              IMAGE_TAG=$PREVIOUS $COMPOSE up -d
              echo "$PREVIOUS" > .current-tag
            fi
            exit 1
        env:
          NEW_TAG: ${{ inputs.image_tag }}
          APP: ${{ github.event.repository.name }}
```

**Detalhes que importam:**

- `environment: production` é a linha que cria o gate de aprovação. Sem ela, não há aprovação
- `.current-tag` no servidor é o que permite o rollback saber para onde voltar
- Health check que só responde `200` fixo não serve. O `/health` precisa verificar conexão com o banco
- `appleboy/ssh-action` recebe segredo — pelo nosso padrão, **fixe pelo SHA do commit**, não pela major

Depois de subir, siga o checklist de [Deploy e incidentes](deploy-and-incidents.md#depois-de-subir). Pipeline verde não é conferência.

### Aprovação

Use **GitHub Environments** com *required reviewers* no environment `production`. É o que garante que ninguém sobe sozinho às 18h de sexta sem alguém saber.

O revisor aprova na interface do Actions. Aprovar significa: "vi o que está subindo e o horário é adequado" — não é carimbo.

---

## Cadência de promoção

Produção é manual, mas **manual não é esporádico**.

Padrão: **promoção diária, até as 16h**, respeitando as [janelas de deploy](deploy-and-incidents.md#janelas). Tarefa homologada de manhã sobe no mesmo dia.

O motivo é diagnóstico. Se cinco PRs acumulam entre promoções, o deploy leva cinco mudanças juntas e, quando algo quebra, você não sabe qual foi. Lote pequeno é o que torna o rollback útil.

Projeto de criticidade **alta** ([Padrão de repositório](../workflow/repo-standards.md#rigor-por-criticidade)) promove uma tarefa por vez, nunca em lote.

> [!WARNING]
> Tarefa só chega em `Finalizada` depois de subir em produção e ser conferida. Promoção acumulada segura o quadro inteiro do Planio em `Em teste` — o gargalo aparece no processo antes de aparecer no sistema.

---

## Migrations

Detalhe completo em [Deploy e incidentes](deploy-and-incidents.md#migration-em-produção). Do lado do pipeline:

- Sempre step separado, antes do `up -d`
- Migration **destrutiva** não roda pelo pipeline. Roda em janela combinada, manualmente, com backup verificado antes
- Mudança que quebra compatibilidade usa o padrão de duas fases. A regra prática: toda migration precisa funcionar com a versão anterior do código, senão o rollback de imagem não resolve nada

Imagem tem rollback trivial. Banco não tem.

---

## Segredos e variáveis de ambiente

- Segredo de pipeline vive em **GitHub Secrets** (repositório ou organização), nunca no YAML
- Segredo de organização para o que é compartilhado (registry, host); de repositório para o específico
- Secrets **separados por environment** (`homolog` e `production`). Mesmo nome, valores diferentes
- Variável de ambiente da aplicação vive no `.env` do servidor, com permissão `600` e dono `deploy`
- Nunca faça `echo` de segredo em step de debug — o mascaramento do Actions falha com valor transformado (base64, JSON)

**Variável nova é a segunda maior causa de deploy quebrado**, atrás só de migration. O `.env.example` precisa ser atualizado no mesmo PR que introduz a variável, e o CI deve comparar as chaves (não os valores) do `.env.example` com as do ambiente de destino.

---

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

---

## Quando o CI quebra na `main`

`main` vermelha é bloqueio do time inteiro — ninguém consegue fazer merge com confiança.

1. Quem quebrou conserta, com prioridade sobre qualquer outra coisa
2. Não dá para consertar em ~30 min? **Reverta** o PR e conserte com calma na branch
3. Avise no canal do time em qualquer um dos casos

Reverter não é vergonha. Deixar a `main` quebrada por meio dia é.

---

> [!TIP]
> Repositório novo? O checklist completo está em [Padrão de repositório](../workflow/repo-standards.md#checklist-de-repositório-novo).

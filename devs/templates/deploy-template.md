# Template de deploy

O que cada repositório precisa para subir pelo
[padrão de deploy](../engineering/deploy-standard.md): **quatro arquivos**, e só
dois deles têm conteúdo específico da aplicação.

| Arquivo | Onde vive | O que é |
|---|---|---|
| `deploy.yml` | `.github/workflows/` | O gatilho. Copie do modelo da organização, mexa em duas linhas |
| `deploy.conf` | raiz do repositório | Os fatos da aplicação: quais serviços significam o quê |
| `docker-compose-prod.yml` | raiz do repositório | O contrato de produção |
| `deploy-checklist.md` | raiz do repositório | A conferência à mão que nenhum health check cobre |

> [!TIP]
> O workflow tem um **modelo oficial** em
> [`workflow-templates/deploy.yml`](../../workflow-templates/deploy.yml) deste
> repositório — ele aparece no botão "New workflow" do GitHub, em Actions, na
> seção da organização. Prefira criar por lá em vez de copiar e colar: assim o
> arquivo nasce certo, e é um lugar só para corrigir.

## 1. `.github/workflows/deploy.yml`

Só duas coisas mudam por repositório: a **label da máquina** no `runs-on` e a
**versão** da action.

```yaml
name: deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      sha:
        description: SHA curto para ROLLBACK (vazio sobe o HEAD da main)
        required: false
        type: string
      mode:
        description: deploy | dry-run | doctor
        required: false
        default: deploy
        type: choice
        options: [deploy, dry-run, doctor]

concurrency:
  group: deploy-${{ github.repository }}
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  deploy:
    runs-on: [self-hosted, linux, prd-apps-1]
    timeout-minutes: 60
    steps:
      - uses: Softilux-Desenvolvimento-de-Sistemas/.github/actions/deploy@v1.0.0
        with:
          sha: ${{ inputs.sha }}
          mode: ${{ inputs.mode || 'deploy' }}
```

> [!WARNING]
> **Não acrescente `actions/checkout`.** O deploy sobe de `/srv/<repo>`, que é
> onde vivem o arquivo de ambiente e o estado. Um segundo clone no diretório de
> trabalho do runner seria uma segunda verdade sobre o que está no ar.

## 2. `deploy.conf`

Fatos do repositório, ao lado do compose que eles descrevem. **Chave desconhecida
é erro**, e vazio explícito é diferente de ausente.

```sh
# Contrato de deploy desta aplicação. Fatos, não política —
# política (rollback, timeout, retenção) vem dos inputs do workflow.

COMPOSE_FILE=docker-compose-prod.yml
ENV_FILE=.env.prod

# Vazio = esta aplicação não tem migration. A chave continua obrigatória.
MIGRATE_SERVICE=migrate

# Os serviços que precisam ficar saudáveis para o deploy ser considerado bom.
# Declarado, não derivado: HEALTHCHECK de Dockerfile é invisível ao compose.
HEALTH_SERVICES=api web

BRANCH=main
CHECKLIST_FILE=deploy-checklist.md
```

## 3. `docker-compose-prod.yml`

O esqueleto abaixo é o contrato mínimo. As âncoras no topo não são enfeite: elas
são o que faz cada serviço novo nascer com teto de memória e log rotacionado, que
é o que protege as **outras** aplicações da mesma VM.

```yaml
name: <app>-prd

x-logging: &logging
  driver: json-file
  options:
    max-size: 10m
    max-file: '3'

x-hardening: &hardening
  security_opt: [no-new-privileges:true]
  cap_drop: [ALL]

services:
  # Migration em serviço one-shot. NUNCA no entrypoint da aplicação: com duas
  # réplicas, as duas migram ao mesmo tempo.
  #
  # ⚠️ Tem que ser idempotente E serializável: o `up -d` pode disparar este
  # serviço outra vez. Se a sua ferramenta de migration não toma lock (TypeORM
  # não toma), a trava é trabalho deste repositório.
  migrate:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
      target: migrate
    image: <app>/api-migrate:${GIT_SHA:?defina GIT_SHA — quem faz isso é o deploy}
    env_file: [.env.prod]
    restart: 'no'
    mem_limit: 512m
    logging: *logging
    <<: *hardening

  api:
    build:
      context: .
      dockerfile: apps/api/Dockerfile
      target: production
    image: <app>/api:${GIT_SHA:?defina GIT_SHA — quem faz isso é o deploy}
    env_file: [.env.prod]
    depends_on:
      migrate: { condition: service_completed_successfully }
    # Sem `ports:` — quem publica porta é a borda compartilhada.
    mem_limit: 1g
    restart: unless-stopped
    logging: *logging
    <<: *hardening

  web:
    build:
      context: .
      dockerfile: apps/web/Dockerfile
    image: <app>/web:${GIT_SHA:?defina GIT_SHA — quem faz isso é o deploy}
    env_file: [.env.prod]
    depends_on:
      api: { condition: service_healthy }
    mem_limit: 1g
    restart: unless-stopped
    logging: *logging
    <<: *hardening
```

Quatro coisas que **não** são opcionais, e o que acontece quando faltam:

| Sem isto | O sintoma |
|---|---|
| `name:` fixo | O nome do projeto passa a sair do diretório, e um `down` pode acertar outro projeto da VM |
| `:?` em toda interpolação | Variável faltando vira string vazia e o erro aparece em runtime, torto, em vez de falhar no parse |
| Tag = `${GIT_SHA}` | Não há caminho de volta: rollback é subir outro SHA da mesma imagem |
| `HEALTHCHECK` na imagem dos serviços de `HEALTH_SERVICES` | O deploy não tem como saber se subiu, e o revert automático não dispara |

## 4. `deploy-checklist.md`

A action imprime este arquivo no resumo do job. É a parte que **só quem escreveu a
aplicação sabe**: qual fluxo, atravessando quais peças, prova que ela está de pé.

````markdown
1. login pelas duas portas (`/admin` e `/app`)
2. **um fluxo de ponta a ponta que atravesse a borda** — é o que prova o
   roteamento, e nenhum health check cobre
3. `curl https://<dominio>/<rota-interna>` **não** deve responder
4. log da borda sem erro de emissão de certificado
````

> [!NOTE]
> "A aplicação responde" já é o health check. Este arquivo é para o que ele
> **não** cobre: o caminho que passa pelo proxy, o WebSocket, o login, o upload —
> o que quebra sem derrubar o container.

## 5. O arquivo de ambiente

Dois arquivos, e a diferença entre eles é o que mais confunde:

| | Onde | Versionado? |
|---|---|---|
| `.env.prod.example` | repositório | **sim**, com todas as chaves e **nenhum valor** |
| `.env.prod` | só na VM, `600`, dono `deploy` | **nunca** |

O deploy compara as **chaves** dos dois e avisa quando o `.example` tem alguma
que falta na VM — é o que mecaniza o item "env vars novas já configuradas no
ambiente de destino" do
[checklist de deploy](../engineering/deploy-and-incidents.md#antes-de-subir).
Valor nenhum é impresso.

> [!IMPORTANT]
> Variável nova entra no `.example` **no mesmo PR** que a cria, e é preenchida na
> VM **antes** do merge. Merge é deploy: não há janela entre uma coisa e outra.

## Antes do primeiro deploy

O resto (DNS, runner, diretórios, `doctor`, `dry-run`, ensaio de rollback) está no
[checklist de aplicação nova](../engineering/deploy-standard.md#checklist-aplicação-nova-na-vm).

---

← [Voltar a Templates](README.md) · [Team Handbook](../README.md)

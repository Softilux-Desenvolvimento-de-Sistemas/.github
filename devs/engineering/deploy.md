# Deploy

Como o código chega em produção aqui, do PR ao cliente — e o que fazer para
manter isso de pé.

Esta página é o **mecanismo**. O *processo humano* — janela, o que conferir, o que
fazer quando cai — está em [Deploy e incidentes](deploy-and-incidents.md), e
continua valendo inteiro.

> [!IMPORTANT]
> Este padrão prescreve **só o que o nosso plano do GitHub sustenta**. Não há
> homologação, não há registry e não há branch protection. A página anterior de
> CI/CD foi deletada justamente por prescrever recursos que não temos: se você for
> acrescentar algo aqui, confira primeiro que dá para ligar.

## Como funciona

```
branch → commits → PR para a main
                     └─ CI no GitHub: lint · typecheck · build · contrato · testes
                          └─ verde? o sênior revisa e mergeia (na janela)
                               └─ push na main dispara o deploy no runner da VM
                                    └─ build → CVE → migrate → up -d → health
                                         └─ health falhou? reverte a imagem sozinho
```

Duas peças, e nada além delas:

| Onde | Quem roda | O que faz |
|---|---|---|
| **CI** (`ci.yml`) | runner **hospedado** do GitHub | Verifica o PR. Não bloqueia o merge |
| **Deploy** (`deploy.yml`) | runner **self-hosted**, na VM | Chama o `scripts/deploy.sh` do repositório. 25 linhas |

O **pipeline é o `scripts/deploy.sh`** que vive dentro de cada repositório. Não há
action compartilhada, não há versão a fixar: quem quiser entender como uma
aplicação sobe abre **um arquivo**, no repositório dela. As quatro constantes do
topo são tudo que muda entre aplicações.

> [!NOTE]
> Isso significa **uma cópia do script por repositório**, e cópias divergem. Foi
> escolha consciente: com todos os monorepos na mesma forma, `diff` entre dois
> arquivos resolve, e o custo de ter que entender action, tag e configuração
> própria era maior que o de copiar. Quando o modelo mudar, copie de novo — e
> `diff` entre as aplicações, de vez em quando, é rotina de manutenção.

**O CI não impede o merge.** Branch protection não está no nosso plano, então o
verde é sinal para quem revisa. **Não mergear com o CI vermelho é acordo do
time**, igual ao resto da [proteção da `main`](git-and-github.md#proteção-da-main).

E porque merge dispara deploy, a
[janela de deploy](deploy-and-incidents.md#janelas) passa a se aplicar ao **botão
de merge**. Não existe "mergeia agora, sobe depois".

---

## A VM, uma vez

Feito uma vez por máquina, à mão. Assume Ubuntu 22.04/24.04.

**Tamanho.** O pico é `next build` + `nest build` na própria VM. Piso: 2 vCPU /
4 GB **com swap**. Confortável: 4 vCPU / 8 GB. Disco: cada aplicação guarda os
últimos SHAs de imagem (cada um é um rollback possível), e a imagem do estágio de
migration é gorda — estime ~3 GB por SHA por aplicação e peça **80 GB**.

**1. Docker, do repositório oficial** (não pelo `get.docker.com`, que é script
para máquina de desenvolvimento):

```bash
sudo apt-get update && sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker compose version    # >= 2.20
```

**2. As ferramentas que o deploy exige:**

```bash
sudo apt-get install -y git jq
# jq não é opcional: é como o ACHADO do trivy é separado do ERRO do trivy
```

E o `trivy`, que é o gate de CVE (se o repositório do Aqua mudar, confira a página
oficial):

```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

**3. Swap — não é opcional.** Sem ela o OOM killer mata o build no meio, e o erro
que aparece **não fala de memória**:

```bash
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**4. Firewall:** 80, 443 e SSH. Nada mais — nenhuma aplicação publica porta.

```bash
sudo ufw allow OpenSSH && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw enable
```

**5. Usuário e diretório de estado:**

```bash
sudo adduser --disabled-password --gecos "" deploy
sudo usermod -aG docker deploy
sudo install -d -o deploy -g deploy -m 755 /srv/.deploy
```

> [!IMPORTANT]
> `/srv/.deploy/` guarda a **trava da máquina** (um deploy por VM, entre
> aplicações) e, por aplicação, o SHA no ar, o log e a fase de um deploy
> interrompido. Ele fica **fora de qualquer árvore de trabalho** de propósito:
> arquivo de estado criado dentro do repositório fazia o próprio deploy sujar a
> árvore, e o deploy seguinte recusa subir de árvore suja — o primeiro funcionava
> e o segundo falhava.

**6. A chave do `deploy`**, sem passphrase (o `git pull` roda sem terminal):

```bash
sudo -iu deploy
ssh-keygen -t ed25519 -C "deploy@prd-apps-1" -N ""
cat ~/.ssh/id_ed25519.pub
```

Essa pública entra em cada repositório como **Deploy key**, em Settings → Deploy
keys. **Sem** marcar "Allow write access": o deploy só faz `pull`.

---

## Aplicação nova, passo a passo

### 1. DNS, antes de tudo

Registro **A** do hostname da aplicação apontando para o IP da VM. Um hostname
por aplicação — sem prefixo de rota, sem cookie compartilhado entre produtos.

```bash
dig +short <dominio>    # tem que devolver o IP da VM
```

> [!WARNING]
> Isto vem **primeiro** porque o certificado é emitido na subida, e cada falha de
> emissão consome uma das **5 tentativas semanais** que o Let's Encrypt dá por
> domínio.

### 2. Os quatro arquivos no repositório

Copie de uma aplicação que já está no padrão e ajuste:

| Arquivo | O que ajustar |
|---|---|
| `scripts/deploy.sh` | as **4 constantes** do topo |
| `.github/workflows/deploy.yml` | nada, salvo a label da máquina |
| `.github/workflows/ci.yml` | o nome do banco de teste e, se a stack for outra, o serviço. O modelo é o do [template de monorepo](../templates/monorepo/) |
| `deploy-checklist.md` | o que provar depois de subir, nesta aplicação |

As quatro constantes:

```bash
APP=minha-app                 # vira /srv/minha-app e /srv/.deploy/minha-app
BRANCH=main
MIGRATE_SERVICE=migrate       # vazio = aplicação sem migration
HEALTH_SERVICES="api web"     # quem precisa ficar saudável para o deploy valer
```

> [!CAUTION]
> `HEALTH_SERVICES` é **declarado, não derivado**, e não é preguiça:
> `docker compose config` nunca abre imagem, então um `HEALTHCHECK` escrito no
> Dockerfile é invisível para ele. Derivar daria a lista errada — e serviço sem
> healthcheck reporta "running" para sempre, o que faria o gate girar até o
> timeout com uma mensagem que não explica nada. O script confere a declaração
> **antes** de tocar em produção.

### 3. O compose de produção cumprindo o contrato

Ver [a tabela abaixo](#o-contrato-do-compose). O `deploy.sh --dry-run` confere
quase tudo isso e diz o que falta.

### 4. O lugar da aplicação na VM

```bash
sudo mkdir -p /srv/<app> && sudo chown deploy:deploy /srv/<app>
sudo -iu deploy
cd /srv/<app> && git clone <repo> .
cp .env.prod.example .env.prod && chmod 600 .env.prod   # o deploy RECUSA sem isto
nano .env.prod
```

Gere segredo com `openssl rand -hex 32`. Variável nova entra no `.example` **no
mesmo PR** que a cria, e é preenchida na VM **antes** do merge — merge é deploy,
não há janela entre uma coisa e outra.

### 5. O runner, um por repositório

Como `deploy` (o runner se recusa a rodar como root, e não insista):

```bash
sudo -iu deploy
mkdir -p ~/actions-runner-<app> && cd ~/actions-runner-<app>
curl -fsSL -o runner.tar.gz \
  https://github.com/actions/runner/releases/download/v<versao>/actions-runner-linux-x64-<versao>.tar.gz
tar xzf runner.tar.gz

# o token sai de Settings → Actions → Runners → New self-hosted runner
# e EXPIRA em ~1h. Ele registra o runner; não é segredo de produção.
./config.sh --url https://github.com/<org>/<repo> --token <token> \
  --name prd-apps-1-<app> --labels prd-apps-1 --unattended --replace
```

Como serviço, de dentro do diretório do runner:

```bash
exit
cd /home/deploy/actions-runner-<app>
sudo ./svc.sh install deploy && sudo ./svc.sh start && sudo ./svc.sh status
systemctl is-enabled 'actions.runner.*'    # tem que dizer enabled
```

> [!CAUTION]
> **A label é da MÁQUINA (`prd-apps-1`), não da aplicação** — várias aplicações
> moram nesta VM, e uma label com nome de app mentiria. Errar a label **não dá
> erro**: o job fica enfileirado até o GitHub desistir dele em 24h.
>
> E **um runner por repositório, nunca no repositório `.github`**. Runner de
> organização vive num grupo que atende **todos** os repositórios da org — e em
> repositório público, PR de fork roda workflow, ou seja, comando na VM de
> produção.

### 6. Provar antes de subir

Tudo por Actions → **deploy** → *Run workflow*:

1. **`mode: doctor`** — confere a máquina. Rode **pelo runner**, não pelo seu
   shell: o PATH do serviço systemd não é o do login, e "trivy não instalado" com
   o trivy instalado é o erro mais confuso do conjunto. Se acusar, o lugar de
   acrescentar PATH é o arquivo `.env` do diretório do runner.
2. **`mode: dry-run`** — confere a aplicação (compose, ambiente, disco, imagens
   que seriam construídas). Nada é tocado.
3. **`mode: deploy`**, campo de SHA vazio — sobe o HEAD. É o mais lento de todos:
   constrói do zero.

### 7. Conferir à mão, e ensaiar o rollback

Pipeline verde não é conferência: siga o `deploy-checklist.md`, que o deploy
imprime no resumo do job.

E **ensaie o rollback antes de precisar dele** — rode o workflow com o SHA
anterior no campo. Plano de rollback testado, não imaginado.

---

## O contrato do compose

O script não sabe o que é pnpm, npm, Prisma ou TypeORM: o contrato é o projeto
compose. É isso que faz o mesmo arquivo servir um monorepo com Postgres e um
serviço com MySQL.

| Exigência | Por que é contrato, e não conveniência |
|---|---|
| `name: <app>-prd` | O nome do projeto é a identidade da aplicação para trava, log e retenção. Sem ele, o nome sai do diretório e um `down` pode acertar outro projeto |
| Toda imagem construída tagueada `${GIT_SHA:?...}` | Sem registry, rollback é `up -d` com outro SHA. Se o nome da imagem não for função só do SHA, não há caminho de volta |
| **Toda** variável interpolada com `${VAR:?mensagem}` | É o que faz arquivo de ambiente incompleto falhar **no parse**, antes do build. Sem o `:?`, vira string vazia e o erro aparece em runtime, torto |
| Migration em serviço one-shot (`restart: "no"`), com os serviços de aplicação em `depends_on: service_completed_successfully` | Migration no entrypoint com duas réplicas = duas migrações ao mesmo tempo |
| Migration **idempotente e serializável** | O `up -d` pode disparar o serviço de migration outra vez. `prisma migrate deploy` toma advisory lock; `typeorm migration:run` **não** — aí a trava é trabalho do repositório |
| `HEALTHCHECK` em todo serviço citado em `HEALTH_SERVICES` | É o que o deploy consulta para decidir se reverte |
| Nenhuma porta publicada | Porta publicada numa aplicação é a API dela exposta sem TLS, ao lado das outras. Hoje o deploy **avisa**; a intenção é virar erro |
| `mem_limit` e rotação de log em todo serviço | **Recurso compartilhado:** aplicação sem teto de memória derruba as vizinhas num pico; sem rotação, enche o disco de todas |
| Nenhum segredo em `build.args` | `build.args` fica no `docker history` da imagem para sempre |

---

## Manutenção

O que é automático, a cada deploy: guarda de disco antes do build, poda do cache
de build, retenção dos últimos SHAs por aplicação (agrupada **por SHA**, para não
sobrar rollback pela metade), e aviso quando falta chave no arquivo de ambiente ou
quando um serviço publica porta.

O que é seu:

| Cadência | O que | Por que não dá para automatizar hoje |
|---|---|---|
| **Semanal, 2 min** | O runner está *online* (Settings → Actions → Runners)? O que está no ar é o HEAD da `main`? | **Runner parado é falha silenciosa:** o push acontece, o job enfileira, produção fica uma versão atrás e nada avisa |
| **Mensal** | `df -h`; **ensaiar um rollback**; olhar os PRs do Dependabot | Plano de rollback testado, não imaginado |
| **Trimestral** | Bumpar a base das imagens; `apt upgrade` + reboot da VM e **conferir que o runner subiu**; `diff` do `scripts/deploy.sh` entre as aplicações | A varredura de CVE é do momento do build: vulnerabilidade publicada depois só aparece no próximo deploy |
| **Antes de migration destrutiva** | Backup **verificado** — alguém tem que saber restaurar | Migration destrutiva não passa pelo pipeline: janela combinada, à mão |

> [!CAUTION]
> **`docker image prune -a` e `docker system prune -a` são proibidos nesta
> máquina.** Em script, em cron, em runbook, em sessão de SSH às 2h da manhã. Não
> há registry: essas imagens são o único caminho de volta, e o comando apaga o
> rollback de **todas** as aplicações de uma vez. Precisando de espaço, pode podar
> cache de build — ele é reconstruível por definição.

Duas regras a mais, que valem sempre: **não edite nada em `/srv/<app>` por SSH**
(o deploy recusa árvore suja de propósito — o que subisse não teria SHA que o
descrevesse) e **swap sempre ligada**.

---

## Quando falha

| Falhou em | Produção está |
|---|---|
| Config, disco, build, CVE ou declaração de healthcheck | **Intacta**, na versão anterior. Nada subiu |
| Migration | **Intacta.** Os serviços de aplicação nem tentaram subir |
| Health check depois do `up -d` | O deploy **reverte a imagem e confere a saúde do revert**. ⚠️ A migration **não** volta |
| O revert também não ficou saudável | Isto é **incidente**: [Deploy e incidentes](deploy-and-incidents.md#incidentes) |

Rollback à mão, quando o GitHub estiver fora do ar:

```bash
cd /srv/<app>
GIT_SHA=<sha-anterior> docker compose --env-file .env.prod -f docker-compose-prod.yml up -d
echo <sha-anterior> > /srv/.deploy/<app>/current-tag
```

---

## Aplicação com MySQL

O deploy não muda: o contrato é o compose, e um serviço one-shot que roda
`migration:run` do TypeORM cumpre o mesmo papel que um que roda
`prisma migrate deploy`. O que muda é o **CI**:

| Eixo | Postgres + Prisma | MySQL + TypeORM |
|---|---|---|
| Serviço no CI | `pgvector/pgvector:pg17` (a extensão `vector` é criada pela primeira migration; com a imagem oficial do Postgres a suíte morre antes do primeiro teste) | `mysql:8` — e atenção ao collation, se as migrations fixarem um |
| Health do serviço | `pg_isready -U <user> -d <db>` | `mysqladmin ping` |
| Conexão | `DATABASE_URL` única | `DB_HOST`/`DB_PORT`/`DB_USER`/`DB_PASSWORD`/`DB_NAME` separados |
| Migration no CI | o `globalSetup` da suíte cria o banco e migra | idem, pelo `dataSource.runMigrations()` |
| Paralelismo | nomes de banco fixos → **exige `--concurrency=1`** | nome por execução → seguro em paralelo |

> [!NOTE]
> Se a aplicação com MySQL tiver banco **remoto e compartilhado** em vez de
> serviço no CI, a suíte de integração não cabe no PR sem uma decisão sobre
> concorrência de schema. Resolva isso antes, não no dia.

---

## O que este desenho não resolve

Escrito porque dívida que não está escrita vira folclore:

- **Não há homologação.** Um ambiente só significa que o primeiro a exercitar a
  mudança é o cliente. É a dívida mais cara daqui.
- **O CI não impede nada.** Ele informa; o que segura é a revisão.
- **O build roda na máquina de produção**, disputando memória e disco com quem
  está usando o sistema.
- **A imagem do front não é promovível.** Variável pública entra no build, então a
  imagem fica presa ao domínio — trocar de domínio exige **rebuild**, não restart.
- **Runner parado é falha silenciosa.** Enquanto não houver um vigia, é
  conferência humana semanal.
- **Migration não tem rollback.** A imagem volta, o schema não — daí a regra das
  [duas fases](deploy-and-incidents.md#migration-em-produção).
- **O deploy tem alguns segundos de indisponibilidade.** `up -d` recria container.
  Zero-downtime aqui é nenhum, e é isso que justifica as janelas.
- **Sem registry, o rollback é local.** Alcança só imagem que ainda está naquele
  disco. VM reconstruída = zero rollback.
- **Uma cópia do script por repositório vai divergir.** O antídoto é `diff`, e ele
  é rotina de manutenção, não automação.

## Quando revisitar

| Se... | Então |
|---|---|
| a divergência entre as cópias do script começar a doer | volta à mesa centralizar o pipeline — agora com o script maduro e o custo conhecido dos dois lados |
| entrar registry e um segundo ambiente | o gatilho passa a **promover imagem validada**, e a homologação vem com ele |
| o plano incluir branch protection | o CI vira status check obrigatório, e o acordo deixa de ser a única coisa que sustenta a `main` |
| o pico de build atrapalhar quem usa o sistema | buildar em outra máquina e carregar a imagem, antes de voltar o gatilho para manual |
| entrar a segunda aplicação que precise de TLS | só um processo escuta a 443: o proxy sai do compose de uma aplicação e vira **borda compartilhada**, com rede externa e um alias de rede por app (dois serviços chamados `web` na mesma rede fazem o proxy distribuir tráfego entre sistemas diferentes, em silêncio) |

---

← [Voltar a Engenharia](README.md) · [Team Handbook](../README.md)

# Padrão de deploy

Como o código chega em produção aqui: **merge na branch principal sobe**, por um
runner na própria VM, rodando uma action versionada que é a mesma para todas as
aplicações.

Esta página é o **mecanismo**. O *processo humano* — quando pode subir, o que
conferir, o que fazer quando cai — está em
[Deploy e incidentes](deploy-and-incidents.md), e continua valendo inteiro.

> [!IMPORTANT]
> Este padrão prescreve **só o que o nosso plano do GitHub sustenta**. Não há
> homologação, não há registry, não há status check obrigatório e não há branch
> protection. A página anterior de CI/CD foi deletada justamente por prescrever
> recursos que não temos — se você for acrescentar algo aqui, confira primeiro
> que dá para ligar.

## A topologia

Uma VM para as aplicações, uma máquina para o banco, uma borda para todas.

```
internet ──443──▶ caddy (borda compartilhada, quem publica porta)
                    ├─ softilux.dominio ──▶ web:3000 · /ws → api:3333
                    └─ outra.dominio    ──▶ web:3000

  VM das aplicações: a borda + N projetos compose, um por aplicação
  Máquina do banco:  Postgres/MySQL, rede privada, porta nunca na internet
  Nenhum serviço além da borda publica porta no host
```

| Peça | Regra |
|---|---|
| Hostname | **um por aplicação**. Sem `basePath`, sem prefixo de rota, sem cookie de sessão compartilhado entre produtos |
| Porta | **só a borda publica.** É o que torna rota interna (métrica, health) inalcançável de fora **por topologia**, não por token |
| Banco | máquina separada, rede privada. Um segundo banco na VM das aplicações é um segundo lugar para esquecer de fazer backup |
| Build | **na própria VM**, sem registry. A tag da imagem é o SHA do commit |
| Unidade | **uma unidade deployável = um repositório = um projeto compose** |

> [!WARNING]
> Produto partido em vários repositórios (uma API e um front que precisam se ver)
> **não cabe** neste padrão como está: um projeto compose por repositório os
> deixa em redes distintas. Resolva isso antes de aderir — unificando em
> [monorepo](monorepo.md), que já é o nosso padrão, ou declarando uma rede
> externa do produto.

## O gatilho: merge é deploy

Push na branch principal dispara o deploy. Com squash, merge commit ou
fast-forward, dá no mesmo: **merge de PR é push.**

A consequência que muda o dia a dia: a **janela de deploy** de
[Deploy e incidentes](deploy-and-incidents.md#janelas) passa a se aplicar ao
**botão de merge**. Não existe mais "mergeia agora, sobe depois" — mergear é
subir. Sexta às 17h, o PR espera segunda.

Quem dispara é um **runner self-hosted**, instalado na VM como o usuário do
deploy:

| | |
|---|---|
| **Não consome minuto** | O que o plano limita é runner hospedado. Self-hosted em repositório privado é ilimitado |
| **Não abre porta** | O runner faz long-poll de **saída** em HTTPS. Nada a liberar no firewall |
| **Não guarda segredo no GitHub** | Os segredos vivem no arquivo de ambiente da VM. A action não recebe `secrets` — composite action não tem acesso a eles |
| **Um runner por repositório** | Ver [Segurança](#segurança-o-que-sustenta-isto) — runner de organização atende **todos** os repositórios da org, inclusive público |

Rollback, redeploy e conferência saem do mesmo lugar: Actions → deploy →
**Run workflow**, com o SHA no campo (vazio sobe o HEAD).

## O contrato do repositório

A action **não sabe** o que é pnpm, npm, Prisma ou TypeORM: o contrato é o
projeto compose. É isso que faz o mesmo padrão servir um monorepo pnpm com
Postgres e um serviço npm com MySQL.

| Exigência | Por que é contrato, e não conveniência |
|---|---|
| `docker-compose-prod.yml` com `name:` fixo | O nome do projeto é a identidade da aplicação para a trava, o log e a retenção. Sem ele o nome sai do diretório, e um `down` pode acertar outro projeto |
| Toda imagem construída tagueada `${GIT_SHA:?...}` | Sem registry, rollback é `up -d` com outro SHA. Se o nome da imagem não for função só do SHA, não há caminho de volta |
| **Toda** variável interpolada com `${VAR:?mensagem}` | É o único mecanismo que faz arquivo de ambiente incompleto falhar **no parse**, antes do build. Sem o `:?`, vira string vazia e o erro aparece em runtime, torto |
| Serviço de migration one-shot (`restart: "no"`), com os serviços de aplicação em `depends_on: service_completed_successfully` | Migration no entrypoint com duas réplicas = duas migrações ao mesmo tempo |
| Migration **idempotente e serializável** | O `up -d` pode disparar o serviço de migration outra vez. `prisma migrate deploy` toma advisory lock; `typeorm migration:run` **não** — nesse caso a trava é trabalho do repositório |
| `HEALTHCHECK` em todo serviço citado em `HEALTH_SERVICES` | É o que o deploy consulta para decidir se reverte. Serviço sem healthcheck reporta "running" para sempre |
| Nenhuma porta publicada | Porta publicada numa aplicação é a API dela exposta sem TLS, ao lado das outras |
| `mem_limit` e rotação de log em todo serviço | **Recurso compartilhado**: aplicação sem teto de memória derruba as vizinhas num pico; sem rotação, enche o disco de todas |
| Nenhum segredo em `build.args` | `build.args` fica no `docker history` da imagem para sempre |
| Arquivo de ambiente na VM, `600`, e o `.example` versionado sem valores | Segredo não entra em imagem nem em GitHub Secrets |
| `deploy.conf` | É o marcador de que o repositório aderiu ao padrão. Ausência **não** vira default |

O que **não** entra no contrato, de propósito: gerenciador de pacote, ORM, banco,
linguagem e como a imagem é construída. Isso é do `Dockerfile` da aplicação.

Os detalhes de cada chave do `deploy.conf`, o que a action deriva do compose e
por quê estão no [README da action](../../actions/deploy/README.md).

## O contrato da máquina

| Item | Valor |
|---|---|
| Usuário | `deploy`, no grupo `docker`, com chave SSH **sem passphrase** (o `git pull` roda sem terminal) |
| Diretório da aplicação | `/srv/<nome-do-repositório>`, clone limpo, na branch de deploy |
| Estado e trava | `/srv/.deploy/` — **fora** de toda árvore de trabalho |
| No PATH do **serviço systemd** | `docker` + compose v2 ≥ 2.20, `git`, `flock`, `jq`, `trivy` |
| Swap | **obrigatória.** O pico do ciclo é o build, e sem swap o OOM killer o mata com um erro que não fala de memória |
| Firewall | 80, 443 e SSH. Nada mais — nenhuma aplicação publica porta |

> [!TIP]
> Não confira isso pelo seu shell: o PATH do serviço systemd não é o do login, e
> "trivy não instalado" com o trivy instalado é o erro mais confuso do conjunto.
> Rode `mode: doctor` **pelo runner**, por `workflow_dispatch`.

## A action, e a versão dela

Uma implementação, em
[`actions/deploy`](../../actions/deploy/README.md), consumida por um workflow de
~25 linhas em cada repositório — o modelo está em
[Template de deploy](../templates/deploy-template.md).

```
config → disco → build → CVE → healthcheck → migrate → up -d → health → estado
         └─ falhou? nada subiu              └─ falhou? api e worker não sobem
```

**Fixe a tag exata** (`@v1.0.0`). Tag móvel (`@v1`, `@main`) significa que um
push no repositório do handbook troca o código de deploy de **todas** as VMs sem
diff em lugar nenhum. Com tag fixa, o Dependabot abre o PR de bump por
repositório, e a adoção é escalonada: bump em um, um deploy de prova, depois os
outros.

## Checklist: aplicação nova na VM

- [ ] **DNS** do hostname apontando para a VM — **antes** do primeiro deploy. A
      borda resolve o desafio de certificado na subida, e falha de emissão
      consome uma das 5 tentativas semanais por domínio
- [ ] `/srv/<repo>` criado e o repositório clonado lá, **como o usuário do
      deploy**
- [ ] Arquivo de ambiente preenchido a partir do `.example`, em `600`
- [ ] `docker-compose-prod.yml` cumprindo [o contrato](#o-contrato-do-repositório)
- [ ] `deploy.conf` declarado
- [ ] `deploy-checklist.md` escrito — é o que a action imprime no resumo do job,
      e o que diz **qual fluxo provar** depois de subir
- [ ] Rota da aplicação no repositório da borda (PR próprio)
- [ ] **Runner self-hosted** registrado no repositório, com a label da máquina
- [ ] Workflow copiado do template, com a label e a versão da action
- [ ] `mode: doctor` verde, rodado pelo runner
- [ ] `mode: dry-run` verde
- [ ] Primeiro deploy, e a conferência à mão que nenhum health check cobre
- [ ] **Rollback ensaiado antes de precisar dele** — plano testado, não imaginado
- [ ] Criticidade da aplicação definida
      ([Padrão de repositório](../workflow/repo-standards.md#rigor-por-criticidade))

## A borda compartilhada

Só um processo escuta a 443, então a borda **não pertence a nenhuma aplicação**:
é um projeto compose próprio, num repositório próprio, e ela sobe pela mesma
action (sem migration, conferindo a saúde do próprio proxy).

| Peça | Regra |
|---|---|
| Rede | rede docker **externa**, criada uma vez na máquina; cada aplicação conecta nela os serviços que a borda alcança |
| Rota | um arquivo por aplicação, **no repositório da borda** |
| Reload | valida a configuração e só então recarrega. Reload que falha **mantém a configuração antiga no ar** — é essa propriedade que torna o desenho aceitável |

> [!CAUTION]
> **Alias de rede colide, e colide em silêncio.** Toda aplicação aqui tem
> serviço `web` e `api`. Na rede compartilhada, duas aplicações publicando o
> alias `web` fazem o proxy distribuir o tráfego **entre sistemas diferentes** —
> cliente de um caindo no outro, sem erro nenhum. Todo serviço ligado à rede da
> borda declara um alias prefixado com o nome da aplicação, e a rota usa **só** o
> alias.

Duas armadilhas mecânicas de quem extrai uma borda:

1. No momento em que um serviço ganha a chave `networks:`, o compose **para de
   anexá-lo à rede default implicitamente**. Todo serviço que precisa da rede
   interna passa a ter que listá-la. O sintoma é o front não achando a API.
2. Validar a configuração **não** resolve upstream: alias errado passa na
   validação e vira 502 em runtime. Por isso o repositório da borda tem um smoke
   test próprio, depois do deploy.

## Segurança: o que sustenta isto

| Regra | Por quê |
|---|---|
| **Repositório da aplicação privado, sempre** | Em repositório público, PR de fork roda workflow — e workflow aqui é comando executado na VM de produção. É a regra que o próprio GitHub documenta |
| **Um runner por repositório** | Runner de organização vive num grupo que atende **todos** os repositórios da org (grupo restrito depende de plano acima do nosso). Nunca registre runner no repositório `.github` |
| **Só action da própria organização** | Settings → Actions → "Allow \<org\> actions only". O padrão não usa nenhuma action de terceiro, então bloquear todas não custa nada e fecha a via de supply chain |
| **`permissions:` mínimo no workflow** | `contents: read` basta para baixar a action |
| **Segredo na VM, nunca em GitHub Secrets** | Arquivo de ambiente `600`, dono `deploy`. A action não tem acesso a `secrets` — e isso é propriedade do desenho, não limitação |
| **PR que toca `.github/workflows/`, `deploy.conf`, `Dockerfile` ou o compose de produção é controle de acesso** | Não é code review comum: esses arquivos são caminho de execução na VM. Passa por sênior, sempre |

> [!IMPORTANT]
> As consequências de segurança que esta escolha **aceita** — e elas existem —
> ficam registradas no ADR do repositório da aplicação, junto com o gatilho para
> revisitá-las. Trade-off mora no repositório do projeto, não aqui.

## Disco, retenção e o comando proibido

Cada deploy deixa imagens novas na VM, e cada SHA guardado é um rollback
possível. A action mantém uma janela de SHAs por aplicação e poda o resto,
agrupando **por SHA** — manter a imagem da API de um SHA e ter removido a de
migration dele deixaria um rollback que parece possível e falha.

> [!CAUTION]
> **`docker image prune -a` e `docker system prune -a` são proibidos nesta
> máquina.** Em script, em cron, em runbook, em sessão de SSH às 2h da manhã.
> Não há registry: essas imagens são o único caminho de volta, e o comando apaga
> o rollback de **todas** as aplicações de uma vez. Precisando de espaço, pode
> podar cache de build — ele é reconstruível por definição.

## Quando falha

| Situação | O que acontece |
|---|---|
| Build, CVE, migration ou pré-condição falha | Nada subiu. Produção segue na versão anterior |
| Health check falha depois de subir | A action **reverte para o SHA anterior e confere a saúde do revert**. ⚠️ A migration **não** volta |
| O revert também não fica saudável | Isto é **incidente**: [Deploy e incidentes](deploy-and-incidents.md#incidentes) |
| O runner está parado | O job **enfileira**, produção fica uma versão atrás e ninguém é avisado — ver a lista abaixo |

## O que este padrão não resolve

Escrito porque dívida que não está escrita vira folclore:

- **Não há CI de checagem.** O pipeline **sobe**, não **verifica**: lint,
  typecheck e teste seguem nos
  [hooks locais](../workflow/repo-standards.md#os-hooks-são-a-única-verificação-automática),
  e `--no-verify` os pula. Entre o merge e o cliente não há nada.
- **Não há homologação.** Um ambiente só significa que o primeiro a exercitar a
  mudança é o cliente. É a dívida mais cara daqui.
- **O build roda na máquina de produção**, disputando memória e disco com quem
  está usando o sistema, e o cache de build é compartilhado entre as aplicações.
- **A imagem do front não é promovível.** Variáveis públicas entram no build, e a
  imagem fica presa ao domínio — trocar de domínio exige **rebuild**, não
  restart.
- **Runner parado é falha silenciosa.** O push acontece, o job enfileira, e nada
  avisa. Enquanto não houver um vigia, é conferência humana.
- **Migration não tem rollback.** A imagem volta, o schema não — daí a regra de
  que toda migration funcione com a versão anterior do código
  ([duas fases](deploy-and-incidents.md#migration-em-produção)).
- **O deploy tem alguns segundos de indisponibilidade.** `up -d` recria
  container. Zero-downtime aqui é nenhum — e é isso que justifica as janelas.
- **Sem registry, o rollback é local.** Ele alcança só imagem que ainda está
  naquele disco. VM reconstruída = zero rollback.
- **A varredura de CVE é do momento do build.** Vulnerabilidade publicada amanhã
  só aparece no próximo deploy.

## Quem já está no padrão

| Aplicação | No padrão? | Observação |
|---|---|---|
| `softilux` | **primeiro consumidor** | A borda ainda vive no compose dele; sai quando a segunda aplicação precisar de TLS |
| Demais monorepos | não | Falta `Dockerfile`, compose de produção e healthcheck. O ticket de entrada é isso — uma frase, não um projeto |
| Serviços em PM2 | **não, e é dívida** | Deploy da Softilux é compose + esta action. PM2 sem container não é opção para coisa nova, e o que está nele migra quando for tocado |

> [!WARNING]
> Repositório em organização antiga **não consegue** consumir uma action desta
> organização. Migrar o repositório é pré-requisito de entrar no padrão, não
> detalhe de configuração.

## Quando revisitar

| Se... | Então |
|---|---|
| entrar registry e um segundo ambiente | o gatilho passa a **promover imagem já validada**, e a homologação — a dívida mais cara — vem com ele |
| o plano passar a incluir branch protection ou aprovação por ambiente | "quem mergeia" e "quem sobe" voltam a ser decisões separadas, sem voltar a ser manuais |
| o pico de build atrapalhar quem está usando o sistema | separar build de execução (buildar em outra máquina e carregar a imagem), antes de voltar o gatilho para manual |
| chegar a terceira ou quarta aplicação na VM | reavaliar a memória dos runners e o teto da máquina |

---

← [Voltar a Engenharia](README.md) · [Team Handbook](../README.md)

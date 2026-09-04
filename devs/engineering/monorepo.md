# Monorepo

**Monorepo é o padrão para projeto novo.** Um repositório por produto, com os
serviços dele dentro.

A razão é o tamanho da equipe. Com dois repositórios por produto, mudar um contrato
entre a API e o front vira dois PRs que precisam entrar na ordem certa, e uma
janela em que a `main` de um está incompatível com a do outro. Com um repositório
é **um PR**: os dois lados se movem juntos, e o commit que quebra o contrato é o
mesmo que o conserta.

O ganho de onboarding é o mesmo: clonar um repositório e rodar `pnpm install` põe o
produto inteiro de pé.

## O formato

```
<produto>/
├── apps/                  # o que sobe: api, web, worker, mobile
├── packages/              # o que é importado por mais de um app
├── docs/adr/              # decisões do workspace
├── AGENTS.md  CLAUDE.md   # ver Contexto de agente
├── pnpm-workspace.yaml    turbo.json    biome.json
└── docker-compose.yml
```

Esses arquivos estão prontos para copiar em
[Monorepo: a raiz pronta](../templates/monorepo/), com o roteiro para montar a
raiz à mão ou pedindo a um agente.

**App** é o que tem deploy próprio. **Package** é o que é importado. Um package só
existe quando **dois** apps precisam dele — antes disso, o código mora no app que o
usa. Package criado por antecipação é abstração sem segundo usuário.

**Fronteira: um app não importa do outro.** Eles se falam por contrato (HTTP, fila,
evento). Se você precisou importar, ou o código devia ser um package, ou a fronteira
entre os dois apps está no lugar errado.

## O gerenciador é o pnpm

Com turborepo por cima. As três coisas que dão trabalho na primeira vez:

- **Catálogo.** `pnpm-workspace.yaml` fixa a versão de uma dependência para todos os
  apps. A regra de entrada: a dependência é usada por mais de um pacote **e** duas
  cópias causariam um bug de verdade, não só disco a mais. O caso clássico é uma
  biblioteca com identidade de classe — duas cópias quebram `instanceof` e a falha
  não aponta para a causa. **O Dependabot não entende catálogo:** bump de item
  catalogado é tarefa manual na sprint.
- **Aprovação de build script.** No pnpm 11 a chave é `allowBuilds`, um mapa, e
  `strictDepBuilds` é `true` por padrão — uma dependência nova com script de build
  não aprovado **falha** o `pnpm install` de todo mundo. As chaves antigas
  (`onlyBuiltDependencies` e companhia) foram removidas e são ignoradas em silêncio.
- **`injectWorkspacePackages: true`** se você usa `pnpm deploy` no Dockerfile.

## Quando NÃO fazer monorepo

Repositório separado continua certo quando o ciclo de vida é outro:

- **Release versionada em cliente.** O ILUX entrega versão que fica rodando na
  máquina do cliente, e por isso mantém `main` + `release/x.y` — ver
  [Git e GitHub](git-and-github.md). Um produto assim não compartilha cadência com
  mais nada, e juntá-lo a outro só cria acoplamento sem ganho.
- **Público diferente.** Código aberto, ou algo que um terceiro precisa clonar
  sozinho.
- **Ciclo de deploy independente de verdade**, com times diferentes e nenhum
  contrato compartilhado.

Na dúvida, monorepo. Quebrar depois é `git subtree split`; juntar depois é o que
estamos fazendo agora, e dá mais trabalho.

## Trazer um repositório existente para o monorepo

O histórico entra com `git subtree add --prefix=apps/<app>`, sem squash. Depois
disso os commits antigos guardam os **caminhos antigos**, então
`git log -- apps/api/src/x.ts` não enxerga o passado — use
`git log --all -- src/x.ts`. Registre isso no `README.md`, porque todo mundo tropeça.

O que morde depois do enxerto, medido:

- **Nome de pacote não pode colidir com o do pacote raiz.** Se o app se chama `sfx`
  e o repositório também, `--filter=sfx` fica ambíguo. Renomeie o app.
  Melhor ainda: **filtre por caminho** (`--filter=./apps/api`), que não depende de
  nome nenhum.
- **`husky` e `lint-staged` passam a existir só na raiz.** Dois hooks brigando é
  hook que não roda.
- **`files` no `package.json` do app**, se você usa `pnpm deploy` no Dockerfile.
  Sem isso o deploy manda uma imagem **sem build** para produção: ele copia só os
  arquivos declarados do pacote, e `dist/` está no `.gitignore`. Só quebra em
  runtime, dentro do container.
- **Versão duplicada que o npm achatava e o pnpm não.** O npm resolvia duas
  exigências divergentes numa cópia só; o pnpm mantém as duas, e aí uma augmentação
  de tipo (`declare module '...'`) cai numa identidade de módulo diferente da que o
  código usa, e o build para com erro que não aponta para a causa. Alinhe o pin com
  o do pacote que o exige. Falha de build é o modo de falha certo aqui — ruidoso.

## O que muda no resto do handbook

| Assunto | Onde |
|---|---|
| Os arquivos da raiz, prontos para copiar | [Monorepo: a raiz pronta](../templates/monorepo/) |
| O que tem que existir na raiz e em cada app | [Padrão de repositório](../workflow/repo-standards.md) |
| `AGENTS.md` da raiz e por app | [Contexto de agente](agent-context.md) |
| ADR do workspace × ADR do app | [Modelo de ADR](../templates/adr-template.md) |

# Editores

O time não obriga editor. Obriga **resultado**: código formatado pelo Biome, sem discussão de estilo no review, e sem PR cheio de linha alterada só por formatação.

Padrão de referência: **VS Code**. Quem preferir Zed, Neovim ou WebStorm segue as mesmas regras de formatação.

---

## VS Code

### Extensões obrigatórias

| Extensão | ID | Para quê |
|---|---|---|
| Biome | `biomejs.biome` | Formatação e lint — é o padrão do time |
| EditorConfig | `editorconfig.editorconfig` | Respeita o `.editorconfig` do repo |
| Prisma | `prisma.prisma` | Syntax e formatação de schema |
| Docker | `ms-azuretools.vscode-docker` | Gerenciar containers pelo editor |
| GitLens | `eamodio.gitlens` | Blame inline, histórico de linha |
| Error Lens | `usernamehw.errorlens` | Mostra erro do TS na própria linha |

**Se você usa WSL:** `ms-vscode-remote.remote-wsl` é obrigatória. Abra o projeto sempre com `code .` **de dentro do WSL** — abrir pelo Windows apontando para `\\wsl$` funciona mal.

### Extensões recomendadas

| Extensão | ID | Para quê |
|---|---|---|
| Pretty TypeScript Errors | `yoavbls.pretty-ts-errors` | Torna erro de tipo legível |
| Vitest | `vitest.explorer` | Rodar teste pelo editor |
| REST Client | `humao.rest-client` | Testar API em arquivo `.http` versionado |
| Path Intellisense | `christian-kohler.path-intellisense` | Autocomplete de import |
| Conventional Commits | `vivaxy.vscode-conventional-commits` | Ajuda a montar a mensagem no padrão |

### Extensões que **não** devemos usar

| Extensão | Por quê |
|---|---|
| Prettier | Conflita com o Biome. Se as duas estiverem ativas, o arquivo formata diferente a cada save |
| ESLint | Idem — o Biome já cobre lint nos nossos projetos |
| Auto Import (terceiros) | O TS server nativo já faz isso melhor |

Se um projeto legado ainda usa Prettier/ESLint, o `claude.md` e o `README.md` dele dizem isso — nesse caso habilite as extensões **por workspace**, não globalmente.

### `settings.json` — base do time

Isto é o que garante o resultado que a página cobra. Não é opcional:

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  },
  "editor.rulers": [100],
  "editor.tabSize": 2,
  "files.eol": "\n",
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/dist": true,
    "**/.next": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.next": true,
    "**/package-lock.json": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "typescript.preferences.importModuleSpecifier": "non-relative",
  "js/ts.updateImportsOnFileMove.enabled": "always",
  "git.autofetch": true,
  "git.confirmSync": false,
  "terminal.integrated.defaultProfile.linux": "zsh",
  "json.schemaDownload.trustedDomains": {
    "https://json.schemastore.org/": true,
    "https://www.schemastore.org/": true,
    "https://json-schema.org/": true,
    "https://raw.githubusercontent.com/": true,
    "https://biomejs.dev": true
  },
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescriptreact]": { "editor.defaultFormatter": "biomejs.biome" },
  "[javascript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[json]": { "editor.defaultFormatter": "biomejs.biome" },
  "[jsonc]": { "editor.defaultFormatter": "biomejs.biome" },
  "[prisma]": { "editor.defaultFormatter": "prisma.prisma" }
}
```

`typescript.tsdk` apontando para o `node_modules` é importante: garante que o editor use a mesma versão de TS do projeto, e não a embutida no VS Code. Ao abrir o projeto, aceite o prompt "Use Workspace Version".

> Não use `source.fixAll.eslint` no `codeActionsOnSave`. Em repositório com Biome, isso liga a extensão do ESLint no save e você acaba com duas ferramentas reescrevendo o mesmo arquivo.

### Desligando o ruído de IA e o resto da interface

O VS Code virou um cliente de agente. Cada release recente acrescenta superfície: menu de chat na barra de título, lista de sessões de agente, janela de Agents, browser integrado com anotação de elemento, ditado por voz, sugestão inline e *next edit suggestions* aparecendo enquanto você digita.

Nada disso é proibido. Mas quem usa agente **pelo terminal** — que é como a maioria do time trabalha — está pagando o custo visual de uma coisa que não usa. Os dois caminhos abaixo resolvem.

#### Caminho curto

Um ajuste desliga o pacote inteiro de IA embutida — chat, sugestão inline e as extensões do Copilot:

```json
{
  "chat.disableAIFeatures": true
}
```

**Isso não afeta a extensão do Claude Code.** Ela registra a própria view (webview em container próprio), não se pluga no chat nativo do VS Code — verificado na v2.1.215. Quem roda o Claude no terminal também não é afetado, obviamente.

Vale como padrão para quem não usa Copilot. Se você usa o autocomplete do Copilot e só quer silêncio no resto, vá pelo caminho granular.

#### Caminho granular

```json
{
  // chat e sessões de agente
  "chat.commandCenter.enabled": false,
  "chat.viewSessions.enabled": false,
  "chat.agentHost.enabled": false,

  // browser integrado — as ferramentas que deixam o agente navegar e
  // ler elementos da página
  "workbench.browser.enableChatTools": false,
  "chat.sendElementsToChat.enabled": false,

  // sugestão inline e next edit suggestions
  "github.copilot.enable": { "*": false },
  "github.copilot.nextEditSuggestions.enabled": false,
  "editor.inlineSuggest.enabled": false,

  // voz e ditado
  "dictation.enabled": false,
  "accessibility.voice.keywordActivation": "off",
  "accessibility.voice.autoSynthesize": "off"
}
```

`chat.agentSessionsViewLocation` aparece em tutorial antigo, mas a view isolada foi substituída por `chat.viewSessions.*`. Não use a antiga.

#### Interface

```json
{
  "workbench.startupEditor": "none",
  "workbench.layoutControl.enabled": false,
  "workbench.secondarySideBar.defaultVisibility": "hidden",
  "window.commandCenter": false,
  "window.menuBarVisibility": "compact",
  "editor.minimap.enabled": false,
  "breadcrumbs.enabled": false,
  "editor.renderLineHighlight": "gutter",
  "editor.lineHeight": 1.8,
  "explorer.compactFolders": false,
  "workbench.editor.labelFormat": "short",
  "terminal.integrated.stickyScroll.enabled": false
}
```

`workbench.secondarySideBar.defaultVisibility` é o que mais rende: desde a 1.104 a barra lateral direita abre sozinha em todo workspace, e é ali que o chat mora. `"hidden"` resolve.

`explorer.compactFolders: false` parece contraintuitivo num setup enxuto, mas evita o `src/app/api` colapsado numa linha só — em monorepo isso atrapalha mais do que economiza espaço.

#### Preferências pessoais

Tema, fonte e ícone são gosto seu — ninguém revisa isso. Como referência, o setup que boa parte do time usa:

```json
{
  "workbench.colorTheme": "Min Dark",
  "workbench.iconTheme": "symbols",
  "workbench.productIconTheme": "fluent-icons",
  "editor.fontFamily": "JetBrains Mono",
  "editor.fontLigatures": true,
  "symbols.hidesExplorerArrows": false
}
```

Um aviso sobre um ajuste que circula em config de "IDE limpa": `editor.semanticHighlighting.enabled: false` deixa o código mais monocromático, mas você perde a coloração que vem do TS server — a que distingue tipo de valor, parâmetro de variável, e mostra import não usado esmaecido. É bem mais informação do que parece. Se quiser menos cor, prefira um tema de baixo contraste com o semantic ligado.

### Claude Code no VS Code

Se você usa a extensão em vez do terminal puro, o que vale a pena ajustar:

```json
{
  "claudeCode.useTerminal": true
}
```

Isso abre o Claude no terminal integrado em vez da UI nativa — coerente com quem já trabalha assim e não quer mais um painel.

Duas coisas que aparecem em config copiada por aí e não fazem nada: `claudeCode.selectedModel` não existe no schema da extensão (o modelo se escolhe dentro dela, com `/model`), e `claudeCode.preferredLocation` já vem como `"panel"` e se atualiza sozinho quando você move o painel — declarar não muda nada.

> A versão do VS Code muda rápido e nem todo ajuste acima existe em build antiga. Configuração desconhecida só recebe um aviso no `settings.json` e é ignorada — não quebra nada.

### `.vscode/extensions.json` no repositório

Todo repositório nosso deve ter este arquivo, para o VS Code sugerir as extensões certas ao clonar:

```json
{
  "recommendations": [
    "biomejs.biome",
    "editorconfig.editorconfig",
    "prisma.prisma",
    "yoavbls.pretty-ts-errors",
    "vitest.explorer"
  ],
  "unwantedRecommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
```

### `.vscode/settings.json` no repositório

Só o que é específico do projeto — não replique preferência pessoal aqui:

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

### Debug de API NestJS (`.vscode/launch.json`)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Attach NestJS",
      "port": 9229,
      "restart": true,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

Suba a API com `npm run start:debug` e conecte. Debugger com breakpoint resolve em minutos o que `console.log` leva uma hora.

---

## Zed

Configuração equivalente (`~/.config/zed/settings.json`):

```json
{
  "format_on_save": "on",
  "formatter": {
    "external": {
      "command": "biome",
      "arguments": ["format", "--stdin-file-path", "{buffer_path}"]
    }
  },
  "code_actions_on_format": {
    "source.organizeImports.biome": true
  },
  "tab_size": 2,
  "preferred_line_length": 100,
  "ensure_final_newline_on_save": true,
  "remove_trailing_whitespace_on_save": true,
  "languages": {
    "TypeScript": { "formatter": { "language_server": { "name": "biome" } } },
    "TSX": { "formatter": { "language_server": { "name": "biome" } } }
  },
  "lsp": {
    "biome": { "settings": { "require_config_file": true } }
  }
}
```

---

## `.editorconfig` (todo repositório)

Garante consistência entre editores diferentes:

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
```

---

## Regra final

Se o seu editor está gerando diff de formatação em arquivo que você não alterou, ele está mal configurado. Pare e conserte antes de abrir o PR — diff de formatação misturado com mudança real torna o review inútil.

O CI roda `biome ci` e reprova o PR nesse caso, então não adianta ignorar.

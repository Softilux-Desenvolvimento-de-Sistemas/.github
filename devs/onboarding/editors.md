# Editores

O time não obriga editor. Obriga **resultado**: código formatado pelo Biome, sem discussão de estilo no review, e sem PR cheio de linha alterada só por formatação.

Padrão de referência: **VS Code**. Quem preferir Zed, Neovim ou WebStorm segue as mesmas regras de formatação.

## Para baixar

| O quê | Onde |
|---|---|
| VS Code | [code.visualstudio.com/download](https://code.visualstudio.com/download) |
| Zed | [zed.dev/download](https://zed.dev/download) |
| JetBrains Mono (fonte) | [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/) |

No WSL, instale o VS Code **no Windows**, não dentro do Ubuntu. Ele se conecta à distro pela extensão Remote WSL.

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

O que está comentado como "a sua escolha" é gosto pessoal e ninguém revisa. O resto é o que garante o resultado que esta página cobra.

```jsonc
{
  // ─── Aparência ───────────────────────────────────────────
  "workbench.colorTheme": "Min Dark", // Tema a sua escolha
  "workbench.iconTheme": "symbols",
  "workbench.productIconTheme": "fluent-icons", // Ícones a sua escolha
  "editor.fontFamily": "JetBrains Mono", // Fonte a sua escolha
  "editor.fontLigatures": true, // liga `=>`, `!==`, `>=` num glifo só
  "editor.lineHeight": 1.8, // respiro entre linhas; 0 usa o padrão da fonte
  "editor.renderLineHighlight": "gutter", // destaca a linha atual só na margem
  "editor.semanticHighlighting.enabled": false, // código mais monocromático — o custo é perder a cor que vem do TS server (tipo vs. valor, import não usado esmaecido)

  // ─── Interface limpa ─────────────────────────────────────
  // Tudo que é cromo do editor e não é código.
  "workbench.startupEditor": "none", // abre sem a tela de boas-vindas
  "workbench.layoutControl.enabled": false, // tira os botões de layout do título
  "workbench.secondarySideBar.defaultVisibility": "hidden", // a barra da direita abre sozinha em todo workspace desde a 1.104; é onde o chat mora
  "window.commandCenter": false, // tira a barra de busca do meio do título
  "window.menuBarVisibility": "compact", // menu vira um botão só
  "editor.minimap.enabled": false,
  "editor.scrollbar.vertical": "visible", // sem minimap, a barra vira sua referência de posição
  "breadcrumbs.enabled": false,
  "terminal.integrated.stickyScroll.enabled": false,

  // ─── IA e agentes ────────────────────────────────────────
  // Desliga chat, sugestão inline e extensões do Copilot.
  // Não afeta a extensão do Claude Code: ela usa view própria.
  "chat.disableAIFeatures": true,
  "chat.titleBar.openInAgentsWindow.enabled": false, // tira o atalho de janela de agentes do título

  // ─── Explorer e navegação ────────────────────────────────
  "explorer.compactFolders": false, // não colapsa `src/app/api` numa linha só — em monorepo atrapalha mais do que economiza
  "workbench.editor.labelFormat": "short", // aba mostra só o nome do arquivo
  "explorer.fileNesting.enabled": true, // agrupa arquivo satélite embaixo do principal
  "explorer.fileNesting.expand": false, // agrupado começa fechado
  "explorer.fileNesting.patterns": {
    "package.json": "package-lock.json, .npmrc, .nvmrc, biome.json*, .editorconfig, tsconfig*.json, vitest.config*.ts",
    ".env": ".env.*",
    "*.ts": "${capture}.spec.ts, ${capture}.e2e-spec.ts",
    "docker-compose.yml": "docker-compose.*.yml, Dockerfile*, .dockerignore",
    "README.md": "CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, LICENSE*"
  },
  "symbols.hidesExplorerArrows": false,
  "symbols.files.associations": {
    // ícone por sufixo do Nest — dá para ver a camada sem ler o nome inteiro
    "*.controller.ts": "nest",
    "*.module.ts": "nest",
    "*.pipe.ts": "nest",
    "*.service.ts": "typescript",
    "*.guard.ts": "typescript",
    "*.spec.ts": "ts-test",
    "*.e2e-spec.ts": "ts-test",
    "vitest.config.e2e.ts": "vite",
    ".env.example": "gear"
  },

  // ─── Formatação e lint (Biome) ───────────────────────────
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    // `explicit` = roda no save, não em cima de qualquer edição
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  },
  "files.eol": "\n", // LF sempre, em qualquer plataforma
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  // ─── TypeScript ──────────────────────────────────────────
  "typescript.tsdk": "node_modules/typescript/lib", // usa o TS do projeto, não o embutido no VS Code
  "typescript.enablePromptUseWorkspaceTsdk": true, // pergunta ao abrir o projeto; aceite "Use Workspace Version"
  "js/ts.updateImportsOnFileMove.enabled": "always", // renomear arquivo já conserta os imports
  "editor.linkedEditing": true, // editar a tag de abertura muda a de fechamento

  // ─── Git ─────────────────────────────────────────────────
  "git.autofetch": true,
  "git.confirmSync": false,

  // ─── Busca ───────────────────────────────────────────────
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.next": true,
    "**/package-lock.json": true
  },

  // ─── Extensões ───────────────────────────────────────────
  "[prisma]": {
    "editor.formatOnSave": true
  },
  "prisma.hidePrisma6Prompts": true,
  "claudeCode.preferredLocation": "panel",

  // ─── Remote / WSL ────────────────────────────────────────
  "remote.autoForwardPortsSource": "hybrid", // detecta porta pelo processo e pela saída do terminal

  // ─── Perfis e schemas ────────────────────────────────────
  "workbench.settings.applyToAllProfiles": [],
  "window.newWindowProfile": "Default",
  "json.schemaDownload.trustedDomains": {
    "https://schemastore.azurewebsites.net/": true,
    "https://raw.githubusercontent.com/": true,
    "https://www.schemastore.org/": true,
    "https://json.schemastore.org/": true,
    "https://json-schema.org/": true,
    "https://biomejs.dev": true
  }
}
```

Três observações que valem de verdade:

- **Não use `source.fixAll.eslint` no `codeActionsOnSave`.** Em repositório com Biome, isso liga a extensão do ESLint no save e você acaba com duas ferramentas reescrevendo o mesmo arquivo.
- **`chat.disableAIFeatures` não afeta o Claude Code.** A extensão registra a própria view e não se pluga no chat nativo do VS Code — verificado na v2.1.215. Quem roda o Claude no terminal também não é afetado. Se você usa o autocomplete do Copilot e quer manter só ele, tire essa linha.
- **Configuração desconhecida não quebra nada.** O VS Code muda rápido; chave que não existe na sua build recebe um aviso no `settings.json` e é ignorada.

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

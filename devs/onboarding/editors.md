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

### `settings.json` do usuário

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
  "editor.bracketPairColorization.enabled": true,
  "editor.inlineSuggest.enabled": true,
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
    "**/pnpm-lock.yaml": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "typescript.preferences.importModuleSpecifier": "non-relative",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "javascript.updateImportsOnFileMove.enabled": "always",
  "git.autofetch": true,
  "git.confirmSync": false,
  "terminal.integrated.defaultProfile.linux": "zsh",
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescriptreact]": { "editor.defaultFormatter": "biomejs.biome" },
  "[javascript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[json]": { "editor.defaultFormatter": "biomejs.biome" },
  "[jsonc]": { "editor.defaultFormatter": "biomejs.biome" },
  "[prisma]": { "editor.defaultFormatter": "prisma.prisma" }
}
```

`typescript.tsdk` apontando para o `node_modules` é importante: garante que o editor use a mesma versão de TS do projeto, e não a embutida no VS Code. Ao abrir o projeto, aceite o prompt "Use Workspace Version".

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

Suba a API com `pnpm start:debug` e conecte. Debugger com breakpoint resolve em minutos o que `console.log` leva uma hora.

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

# Ambiente de desenvolvimento

Duas plataformas suportadas: **Windows com WSL2 (Ubuntu)** e **macOS**. Windows nativo sem WSL não é suportado — path, permissão e ferramenta de build quebram de formas que ninguém vai querer depurar.

Escolha a sua plataforma abaixo, siga a seção inteira de cima para baixo, e depois vá para [Configuração comum](#configuração-comum) — que vale para as duas.

---

# Windows + WSL2

## 1. Pré-requisitos

- **Windows 10 versão 2004 (build 19041) ou superior**, ou Windows 11. Confira rodando `winver`.
- **Virtualização habilitada na BIOS/UEFI** (VT-x na Intel, AMD-V na AMD). Sem isso a instalação falha com `0x80370102` ou `0x80070003`. A opção costuma estar nas configurações de CPU e o nome muda de fabricante para fabricante.

## 2. Instalar o WSL

No PowerShell **como administrador**:

```powershell
wsl --install
```

Reinicie a máquina. Na primeira abertura do Ubuntu, crie usuário e senha do Linux (não têm relação com a conta do Windows).

Alguns pontos que costumam gerar dúvida:

- **É tudo pelo terminal.** Você não precisa abrir a Microsoft Store, criar conta Microsoft nem baixar nada manualmente. O comando habilita os componentes do Windows, baixa o kernel e instala o Ubuntu.
- **`wsl --set-default-version 2` não é necessário.** Instalação nova via `wsl --install` já vem como WSL2.
- **Se o download travar em 0.0%** — ou se a Store estiver bloqueada por política da empresa — use `wsl --install --web-download -d Ubuntu`, que baixa a distro direto do GitHub em vez do backend da Store.
- **Se `wsl --install` imprimir o texto de ajuda**, o WSL já está instalado nessa máquina. Rode `wsl --list --online` para ver as distros e depois `wsl --install -d Ubuntu`.

Confirme no final:

```powershell
wsl -l -v
```

Precisa aparecer `Ubuntu` com `VERSION 2`.

## 3. Regra mais importante do WSL

> **Todo código fica dentro do sistema de arquivos do Linux** (`~/projects`), **nunca** em `/mnt/c/...`.

Projeto em `/mnt/c` roda de 5 a 10 vezes mais lento e o file watcher do Vite/Next falha em hot reload. Se você já colocou lá, mova.

## 4. Configurar o `.wslconfig`

Em `C:\Users\<seu-usuario>\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

Ajuste conforme a máquina (regra: metade da RAM física). Depois rode `wsl --shutdown` no PowerShell para aplicar.

## 5. Pacotes base

Dentro do Ubuntu:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl git unzip zsh
```

Para usar zsh como shell padrão:

```bash
chsh -s $(which zsh)
```

Feche e reabra o terminal.

## 6. Node.js via nvm

Não instale Node pelo apt nem pelo instalador oficial. Use gerenciador de versão — projetos diferentes exigem versões diferentes.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
```

O instalador já acrescenta ao seu `~/.zshrc` (ou `~/.bashrc`):

```bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Reabra o terminal e instale as versões que usamos:

```bash
nvm install 22
nvm install 20
nvm alias default 22
```

Todo repositório nosso tem um `.nvmrc` na raiz, que o nvm lê nativamente: `nvm use` dentro da pasta do projeto já seleciona a versão certa. Para trocar automaticamente ao entrar na pasta, veja [troca automática de versão](#troca-automática-de-versão-opcional).

## 7. npm

O npm vem junto com o Node — não precisa instalar nada. Confira com `npm -v`.

`npm` é o padrão do time, em todos os repositórios. Não existe projeto nosso em pnpm ou yarn.

> Nunca rode outro gerenciador num repositório nosso. `pnpm install` ou `yarn` geram um lock paralelo ao `package-lock.json`, e aí duas pessoas passam a instalar árvores de dependência diferentes. Se acontecer, apague o lock errado e não commite.

## 8. Docker

Duas opções:

**Docker Desktop no Windows** (recomendado) com a integração WSL ativada: Settings → Resources → WSL Integration → habilite a sua distro.

**Engine direto no Ubuntu**, sem Docker Desktop:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Reabra o terminal e teste: `docker run hello-world`.

Bancos locais sobem sempre por Docker, nunca instalados na máquina. Cada repositório traz seu `docker-compose.yml`.

## 9. Ferramentas auxiliares

```bash
# GitHub CLI — útil para abrir PR pelo terminal
sudo apt install gh
gh auth login
```

Se o pacote `gh` não existir na sua versão do Ubuntu, siga o [repositório oficial do GitHub CLI](https://github.com/cli/cli/blob/trunk/docs/install_linux.md).

Cliente de banco: DBeaver, TablePlus ou o que você preferir. Não é padronizado.

**Próximo passo:** [Configuração comum](#configuração-comum).

---

# macOS

## 1. Ferramentas de linha de comando e Homebrew

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Em Apple Silicon, adicione ao `~/.zprofile`:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## 2. Pacotes base

```bash
brew install git
```

O zsh já é o shell padrão do macOS — não precisa instalar.

## 3. Node.js via nvm

Não instale Node pelo brew nem pelo instalador oficial. Use gerenciador de versão — projetos diferentes exigem versões diferentes.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
```

O instalador já acrescenta ao seu `~/.zshrc`:

```bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Reabra o terminal e instale as versões que usamos:

```bash
nvm install 22
nvm install 20
nvm alias default 22
```

Todo repositório nosso tem um `.nvmrc` na raiz, que o nvm lê nativamente: `nvm use` dentro da pasta do projeto já seleciona a versão certa. Para trocar automaticamente ao entrar na pasta, veja [troca automática de versão](#troca-automática-de-versão-opcional).

## 4. npm

O npm vem junto com o Node — não precisa instalar nada. Confira com `npm -v`.

`npm` é o padrão do time, em todos os repositórios. Não existe projeto nosso em pnpm ou yarn.

> Nunca rode outro gerenciador num repositório nosso. `pnpm install` ou `yarn` geram um lock paralelo ao `package-lock.json`, e aí duas pessoas passam a instalar árvores de dependência diferentes. Se acontecer, apague o lock errado e não commite.

## 5. Docker

```bash
brew install --cask docker
```

Abra o Docker Desktop uma vez para ele terminar a configuração e teste: `docker run hello-world`.

Bancos locais sobem sempre por Docker, nunca instalados na máquina. Cada repositório traz seu `docker-compose.yml`.

## 6. Ferramentas auxiliares

```bash
# GitHub CLI — útil para abrir PR pelo terminal
brew install gh
gh auth login
```

Cliente de banco: DBeaver, TablePlus ou o que você preferir. Não é padronizado.

**Próximo passo:** [Configuração comum](#configuração-comum).

---

# Configuração comum

Vale para as duas plataformas, e roda dentro do Ubuntu no caso do WSL.

## Git

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@empresa.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf input
git config --global push.autoSetupRemote true
```

`pull.rebase true` evita merge commit de sincronização poluindo o histórico.
`core.autocrlf input` evita a guerra de CRLF/LF entre Windows e Linux.

## Chave SSH para o GitHub

```bash
ssh-keygen -t ed25519 -C "seu.email@empresa.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Cole a chave em GitHub → Settings → SSH and GPG keys. Teste com `ssh -T git@github.com`.

Use sempre a URL SSH ao clonar (`git@github.com:...`). Com a URL HTTPS o push pede credencial toda vez.

## Troca automática de versão (opcional)

O nvm não troca de versão sozinho ao entrar numa pasta — quem quiser esse comportamento adiciona o hook oficial ao final do `~/.zshrc`, **depois** das linhas do nvm:

```zsh
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

Para bash, o equivalente está no [README do nvm](https://github.com/nvm-sh/nvm#deeper-shell-integration). Sem o hook, é só rodar `nvm use` ao entrar no projeto.

O nvm é um script de shell e acrescenta algo em torno de meio segundo à abertura do terminal. É o custo conhecido da ferramenta; se isso te incomodar muito, fale com o time antes de trocar por conta própria — versão de Node é coisa que a gente prefere manter igual entre todo mundo.

---

# Subindo um projeto pela primeira vez

O fluxo é o mesmo em praticamente todos os repositórios:

```bash
git clone git@github.com:<org>/<repo>.git
cd <repo>

nvm use                    # lê o .nvmrc
npm ci                     # instalação limpa, respeitando o package-lock.json

cp .env.example .env       # preencha o que faltar
docker compose up -d       # banco e serviços locais

npm run db:migrate         # ou prisma migrate dev / typeorm migration:run
npm run db:seed            # se houver seed

npm run dev
```

Use `npm ci` no clone inicial: ele instala exatamente o que está no lock e é mais rápido. `npm install` só quando você for de fato adicionar ou atualizar dependência — é ele que reescreve o `package-lock.json`.

Se algum passo falhar, **primeiro** cheque o `README.md` do repositório — ele manda mais que esta página. Se o README estiver errado, corrija-o no mesmo PR da sua próxima tarefa.

# Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `wsl --install` falha com `0x80370102` | Virtualização desabilitada na BIOS | Habilitar VT-x/AMD-V na BIOS/UEFI |
| `wsl --install` só imprime o texto de ajuda | WSL já instalado na máquina | `wsl --list --online` e depois `wsl --install -d Ubuntu` |
| Download da distro travado em 0.0% | Acesso à Store bloqueado ou instável | `wsl --install --web-download -d Ubuntu` |
| Hot reload não dispara no WSL | Projeto está em `/mnt/c` | Mover para `~/projects` |
| `EACCES` ao instalar pacote global | Node instalado como root | Reinstalar via nvm, nunca usar `sudo npm` |
| Porta já em uso | Container antigo de outro projeto | `docker ps` e `docker compose down` no projeto anterior |
| Migration falha ao subir do zero | Volume do banco com estado antigo | `docker compose down -v` e subir de novo |
| Lock file com conflito gigante | Merge do lock | Não resolva à mão: `git checkout main -- package-lock.json && npm install` |
| Docker não responde no WSL | Integração desabilitada | Docker Desktop → Resources → WSL Integration |
| `nvm: command not found` após instalar | Terminal não recarregou o `~/.zshrc` | Fechar e reabrir o terminal, ou `source ~/.zshrc` |

# Padrão de organização local

```
~/projects/
├── <produto-a>/
├── <produto-b>/
└── ilux/
```

Sem espaço, sem acento e sem caminho longo. Ajuda script, ajuda o terminal e ajuda quem for te dar suporte.

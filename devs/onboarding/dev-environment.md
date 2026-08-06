# Ambiente de desenvolvimento

Duas plataformas suportadas: **Windows com WSL2 (Ubuntu)** e **macOS**. Windows nativo sem WSL não é suportado — path, permissão e ferramenta de build quebram de formas que ninguém vai querer depurar.

---

## Windows + WSL2

### 1. Instalar o WSL

No PowerShell **como administrador**:

```powershell
wsl --install -d Ubuntu
wsl --set-default-version 2
```

Reinicie. Na primeira abertura do Ubuntu, crie usuário e senha.

### 2. Regra mais importante do WSL

> **Todo código fica dentro do sistema de arquivos do Linux** (`~/projects`), **nunca** em `/mnt/c/...`.

Projeto em `/mnt/c` roda de 5 a 10 vezes mais lento e o file watcher do Vite/Next falha em hot reload. Se você já colocou lá, mova.

### 3. Configurar o `.wslconfig`

Em `C:\Users\<seu-usuario>\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

Ajuste conforme a máquina (regra: metade da RAM física). Depois: `wsl --shutdown` no PowerShell.

### 4. Pacotes base

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl git unzip zsh
```

---

## macOS

### 1. Ferramentas de linha de comando e Homebrew

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Em Apple Silicon, adicione ao `~/.zprofile`:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 2. Pacotes base

```bash
brew install git zsh
```

---

## Comum às duas plataformas

### Node.js via fnm

Não instale Node pelo apt, pelo brew nem pelo instalador oficial. Use gerenciador de versão — projetos diferentes exigem versões diferentes.

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

Adicione ao `~/.zshrc` (ou `~/.bashrc`):

```bash
eval "$(fnm env --use-on-cd --shell zsh)"
```

Instalar as versões que usamos:

```bash
fnm install 22
fnm install 20
fnm default 22
```

Todo repositório nosso tem um `.nvmrc` na raiz. Com `--use-on-cd`, entrar na pasta já troca a versão automaticamente.

### pnpm

`pnpm` é o padrão do time. `npm` só onde o projeto ainda não migrou.

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

Verifique: `pnpm -v`.

> Nunca misture gerenciadores no mesmo repositório. Se existe `pnpm-lock.yaml`, é pnpm. Rodar `npm install` ali gera um `package-lock.json` conflitante — se acontecer, apague o lock errado e não commite.

### Git

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

### Chave SSH para o GitHub

```bash
ssh-keygen -t ed25519 -C "seu.email@empresa.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Cole a chave em GitHub → Settings → SSH and GPG keys. Teste com `ssh -T git@github.com`.

### Docker

**macOS:** Docker Desktop via `brew install --cask docker`.

**WSL2:** Docker Desktop no Windows com a integração WSL ativada (Settings → Resources → WSL Integration → habilitar sua distro). Alternativa sem Docker Desktop, instalando o engine direto no Ubuntu:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Reabra o terminal e teste: `docker run hello-world`.

Bancos locais sobem sempre por Docker, nunca instalados na máquina. Cada repositório traz seu `docker-compose.yml`.

### Ferramentas auxiliares

```bash
# GitHub CLI — útil para PR pelo terminal
brew install gh          # macOS
sudo apt install gh      # WSL

gh auth login
```

Cliente de banco: DBeaver, TablePlus ou o que você preferir. Não é padronizado.

---

## Subindo um projeto pela primeira vez

O fluxo é o mesmo em praticamente todos os repositórios:

```bash
git clone git@github.com:<org>/<repo>.git
cd <repo>

fnm use                    # lê o .nvmrc
pnpm install

cp .env.example .env       # preencha o que faltar
docker compose up -d       # banco e serviços locais

pnpm db:migrate            # ou prisma migrate dev / typeorm migration:run
pnpm db:seed               # se houver seed

pnpm dev
```

Se algum passo falhar, **primeiro** cheque o `README.md` do repositório — ele manda mais que esta página. Se o README estiver errado, corrija-o no mesmo PR da sua próxima tarefa.

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Hot reload não dispara no WSL | Projeto está em `/mnt/c` | Mover para `~/projects` |
| `EACCES` ao instalar pacote global | Node instalado como root | Reinstalar via fnm, nunca usar `sudo npm` |
| Porta já em uso | Container antigo de outro projeto | `docker ps` e `docker compose down` no projeto anterior |
| Migration falha ao subir do zero | Volume do banco com estado antigo | `docker compose down -v` e subir de novo |
| Lock file com conflito gigante | Merge do lock | Não resolva à mão: `git checkout main -- pnpm-lock.yaml && pnpm install` |
| Docker não responde no WSL | Integração desabilitada | Docker Desktop → Resources → WSL Integration |

## Padrão de organização local

```
~/projects/
├── <produto-a>/
├── <produto-b>/
└── ilux/
```

Sem espaço, sem acento e sem caminho longo. Ajuda script, ajuda o terminal e ajuda quem for te dar suporte.

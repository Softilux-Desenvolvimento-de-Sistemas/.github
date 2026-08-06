# Git e GitHub

## Estratégia de branch

Usamos **GitHub Flow** (trunk-based com branches curtas). Git Flow clássico, com `develop`, `release/*` e merge duplo, é peso morto para produto web e mobile com deploy contínuo.

```
main ← sempre deployável, protegida
 ├── feature/1234-user-export
 ├── fix/1235-login-redirect
 └── hotfix/1236-payment-timeout
```

**`main` é a única branch permanente.** Não temos `develop`.

### Exceção: ILUX

O ILUX, por ter release versionada em cliente, pode usar Git Flow reduzido com `main` + `release/x.y`. A decisão está registrada no `claude.md` e no ADR do repositório dele. Nos demais produtos, GitHub Flow sem exceção.

### Nomenclatura de branch

```
<tipo>/<id-planio>-<descricao-curta-em-ingles>
```

| Tipo | Quando |
|---|---|
| `feature/` | Funcionalidade nova |
| `fix/` | Correção de bug |
| `hotfix/` | Correção urgente indo direto para produção |
| `chore/` | Manutenção, dependência, config |
| `refactor/` | Refatoração sem mudança de comportamento |
| `docs/` | Só documentação |

Exemplos:

```
feature/1234-sales-report-comparison
fix/1289-null-customer-on-invoice
chore/1301-bump-nest-11
```

O ID do Planio no nome não é enfeite — é a rastreabilidade entre o *porquê* (Planio) e o *como* (código).

### Ciclo de vida

- Branch vive **no máximo 3 dias**. Passou disso, ou a tarefa era grande demais (devia ter sido quebrada) ou você travou e não avisou.
- Sincronize com a `main` diariamente: `git pull --rebase origin main`.
- Branch é apagada automaticamente no merge.

---

## Commits

**Conventional Commits**, mensagem em inglês:

```
<tipo>(<escopo>): <descrição no imperativo>
```

| Tipo | Uso |
|---|---|
| `feat` | Funcionalidade nova |
| `fix` | Correção de bug |
| `refactor` | Mudança sem alterar comportamento |
| `perf` | Melhoria de performance |
| `test` | Testes |
| `docs` | Documentação |
| `chore` | Build, dependência, config |
| `ci` | Pipeline |

```bash
feat(billing): add invoice export to xlsx
fix(auth): prevent redirect loop on expired session
refactor(user): extract address validation to service
chore(deps): bump prisma to 6.2
```

**Regras:**
- Imperativo (`add`, não `added` nem `adds`)
- Sem ponto final
- Até ~72 caracteres na primeira linha
- Breaking change: `feat(api)!: ...` e explique no corpo
- Commit pequeno e frequente. `wip` e `ajustes` são aceitáveis durante o desenvolvimento — o squash no merge limpa

---

## Pull Requests

### Título

Mesmo padrão do commit, com o ID do Planio:

```
feat(billing): add invoice export to xlsx [#1234]
```

### Corpo

Use o [template](../templates/pull-request-template.md), que já vive em `.github/pull_request_template.md`.

### Tamanho

**Meta: menos de 400 linhas alteradas.** Não é regra rígida, é física: review de PR grande é ruim, sempre. Acima de ~800 linhas, o revisor aprova sem ler de verdade, e todo mundo sabe disso.

Ficou grande? Quebre em PRs empilhados: um de refatoração/preparo, outro com a funcionalidade.

Renomeação em massa ou geração de arquivo? **PR separado**, sempre — não misture com mudança de lógica.

### Draft PR

Abra como draft assim que tiver o primeiro commit. Serve para:

- Deixar visível o que você está fazendo
- Rodar o CI cedo
- Receber comentário de direção antes de terminar

Marque como "Ready for review" quando o CI estiver verde e você tiver relido o próprio diff.

### Merge

- **Squash and merge** é o padrão. Histórico da `main` = uma linha por PR
- A mensagem do squash é o título do PR
- Merge só com CI verde e ao menos 1 aprovação
- **Quem faz o merge é o autor**, não o revisor — o autor sabe se ainda falta algo

---

## Configuração do repositório

### Branch protection em `main`

- [x] Require a pull request before merging
- [x] Require approvals: **1**
- [x] Dismiss stale approvals when new commits are pushed
- [x] Require review from Code Owners
- [x] Require status checks to pass: `lint`, `test`, `build`
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Do not allow bypassing the above settings *(vale para todos, inclusive gestão)*
- [ ] ~~Allow force pushes~~
- [ ] ~~Allow deletions~~

### Configurações gerais

- Allow squash merging: **sim** (padrão)
- Allow merge commits: **não**
- Allow rebase merging: **não**
- Automatically delete head branches: **sim**

---

## Hotfix

Quando produção está quebrada:

```bash
git checkout main && git pull
git checkout -b hotfix/1299-payment-timeout
# corrige, o menor diff possível
git push -u origin hotfix/1299-payment-timeout
```

- PR normal, mas com review **imediato** — hotfix fura a fila
- Ainda exige aprovação. Produção quebrada não é motivo para pular review; é justamente quando mais se erra
- Se ninguém estiver disponível e o prejuízo for real, o gestor pode aprovar. Isso fica registrado e vira item de postmortem
- Após subir: [postmortem](deploy-and-incidents.md), sempre

## Erros comuns

| Situação | O que fazer |
|---|---|
| Commitou na `main` local | `git reset --soft HEAD~1`, cria a branch, commita nela |
| Commitou segredo | **Avise imediatamente.** A credencial precisa ser rotacionada — remover do histórico não basta |
| Conflito no lock file | `git checkout main -- pnpm-lock.yaml && pnpm install` |
| Precisa desfazer merge já na `main` | `git revert -m 1 <sha>` via PR. Nunca reescreva histórico da `main` |
| Branch muito atrás da `main` | `git fetch && git rebase origin/main`, resolve, `git push --force-with-lease` (só na sua branch) |

`--force-with-lease` em vez de `--force`: se alguém tiver empurrado algo na sua branch, ele falha em vez de destruir o trabalho.

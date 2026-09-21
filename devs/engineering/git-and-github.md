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

O ILUX, por ter release versionada em cliente, pode usar Git Flow reduzido com `main` + `release/x.y`. A decisão está registrada no `AGENTS.md` e no ADR do repositório dele — é também o exemplo canônico de [quando não fazer monorepo](monorepo.md#quando-não-fazer-monorepo). Nos demais produtos, GitHub Flow sem exceção.

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
- Receber comentário de direção antes de terminar

Marque como "Ready for review" quando lint, typecheck e build estiverem limpos na sua máquina e você tiver relido o próprio diff.

### Merge

- **Squash and merge** — e é o único método oferecido. Histórico da `main` = uma linha por PR
- A mensagem do squash é o título do PR
- **Quem faz o merge é o autor**, não o revisor — o autor sabe se ainda falta algo
- O caminho curto é armar o **Auto-merge** quando o PR sai do draft: ele entra sozinho quando a aprovação chega e o CI fecha verde, sem ninguém vigiando
- Aprovação e CI verde não são mais lembrete: são o botão cinza ([Proteção da `main`](#proteção-da-main))

---

## Configuração do repositório

### Proteção da `main`

Desde 15/09/2026 isto é **configuração, não acordo**. O ruleset `PROTECT-MAIN` vive **na organização** e mira a **branch default de todo repositório dela** — não há nada a configurar por repo, e não há como um repo novo nascer desprotegido.

> [!IMPORTANT]
> O ruleset não mora no repositório que ele protege. Para ler o que vale num repo:
> `gh api repos/<owner>/<repo>/rules/branches/main`
> Para ver de onde cada regra vem: `gh api repos/<owner>/<repo>/rulesets`

O que ele exige:

- **Nada entra na `main` sem PR.** Nem hotfix, nem "é uma linha só"
- **1 aprovação** — e o GitHub não deixa ninguém aprovar o próprio PR
- **Review de code owner** — ver [CODEOWNERS](../workflow/repo-standards.md#codeowners)
- **Conversa resolvida antes do merge.** Comentário `[bloqueante]` aberto é PR que não merge
- **Push novo invalida a aprovação** que já veio
- **Squash é o único método de merge**
- **Deleção e force-push bloqueados.** Em branch sua, `--force-with-lease`

### Bypass: quem escapa, e de quê

Quem é **owner da organização** ignora as regras acima — mas **só mergeando PR**. O modo é `pull_request`, nunca `always`. Na prática: o gestor mergeia sem esperar aprovação, e **continua sem conseguir** empurrar direto na `main`, force-pushar ou apagá-la.

> [!WARNING]
> `always` é o modo que **não** se usa. Ele devolve ao owner o push direto em produção — o atalho que a proteção existe para fechar. A diferença entre os dois modos é a diferença entre "não espero aprovação" e "não passo por review nenhum".

Usar o bypass fica registrado no PR e no audit log da organização.

Isto é uma mudança de posição, e está registrada: a versão anterior desta página dizia "a regra vale para todos, inclusive gestão". Ela vale, menos a aprovação — porque com equipe pequena o gestor costuma ser o único code owner, e sem exceção ele vira o gargalo do próprio time. Quando houver um segundo code owner, é para reconsiderar.

### O CI vira status check obrigatório

Repositório com `ci.yml` põe os jobs dele num **ruleset do próprio repositório**, separado do da organização, e **sem bypass**.

São duas razões, e as duas importam:

- **nome de job é específico do repositório.** No ruleset da organização, um check chamado `contrato · suíte da api` seria exigido dos repos que não têm esse job — e check obrigatório que nunca reporta é PR que nunca merge
- **sem bypass, a regra alcança o gestor.** É o desenho: *owner pula a aprovação e não pula o CI*

O `context` exigido é a string exata do `name:` do job. **Renomear um job solta a guarda sem erro em lugar nenhum** — o check exigido simplesmente nunca mais reporta.

Emergência de verdade: ponha esse ruleset em `evaluate`, mergeie e devolva para `active`. Fica no audit log, e é para ficar.

### Configurações gerais

- Allow squash merging: **sim** (padrão)
- Allow merge commits: **não**
- Allow rebase merging: **não**
- Allow auto-merge: **sim** — com check obrigatório, é o que deixa o fluxo fluido: o autor arma o merge e ele acontece sozinho quando a aprovação chega e o CI fecha
- Allow "Update branch": **sim** — o check obrigatório exige a branch em dia com a `main`
- Automatically delete head branches: **sim**
- Squash commit title: **título do PR**

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
- Se ninguém estiver disponível e o prejuízo for real, o gestor mergeia pelo bypass. Isso fica registrado no PR e no audit log, e vira item de postmortem
- **O CI continua valendo**, inclusive para o gestor. Hotfix com CI vermelho exige pôr o ruleset do CI em `evaluate` e devolver para `active` — e isso também é item de postmortem
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

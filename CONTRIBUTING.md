<div align="center">

# Como contribuir

**Este arquivo vale para todos os repositórios da Softilux.**

[![Team Handbook](https://img.shields.io/badge/📖_Team_Handbook-1E6FEB?style=for-the-badge)](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/README.md)

</div>

---

Esta é a versão curta. A regra completa está sempre no **[Team Handbook](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/README.md)** — se houver divergência, o handbook manda.

> [!NOTE]
> Regras específicas de um projeto moram no `claude.md` do repositório e **têm precedência** sobre o handbook.

---

## Antes de escrever código

1. **A demanda existe no Planio e passou pela triagem.** Nenhuma tarefa vai direto do solicitante para o dev — [Ciclo da demanda](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/workflow/demand-cycle.md).
2. **Leia o critério de aceite.** Não entendeu? Pergunte **antes** de começar. Perguntar cedo custa 5 minutos.
3. **Tarefa GG não entra em sprint.** Se não cabe em uma semana, quebre.

## Branch

```
<tipo>/<id-planio>-<descricao-curta-em-ingles>
```

`feature/` · `fix/` · `hotfix/` · `chore/` · `refactor/` · `docs/`

```bash
git checkout main && git pull
git checkout -b feature/1234-sales-report-comparison
```

Branch vive **no máximo 3 dias**. Sincronize diariamente com `git pull --rebase origin main`.

📖 [Git e GitHub](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/git-and-github.md)

## Commit

**Conventional Commits**, em inglês, no imperativo:

```bash
feat(billing): add invoice export to xlsx
fix(auth): prevent redirect loop on expired session
chore(deps): bump prisma to 6.2
```

## Código

| Regra | Detalhe |
|---|---|
| Código em inglês, documentação em português | Sem `calcularTotalOrder` |
| Arquivos em `kebab-case` | `invoice-repository.ts` |
| `any` é proibido | Use `unknown` e faça o narrowing |
| Formatação é do Biome | `npx biome check --write` |
| Toda entrada externa é validada | Zod ou class-validator |

📖 [Padrões de código](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/code-standards.md)

## Testes

Todo `fix` nasce com um teste que falha antes e passa depois. Regra de negócio sempre tem teste.

```bash
npm run test:run
```

📖 [Testes](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/testing.md)

## Pull Request

- Abra como **draft** no primeiro commit — dá visibilidade e roda o CI cedo
- Título no padrão do commit, com o ID do Planio: `feat(billing): add invoice export to xlsx [#1234]`
- **Meta: menos de 400 linhas alteradas**
- Preencha o template. O campo **"Por quê"** é o mais importante
- Releia o próprio diff antes de marcar "Ready for review"
- **Squash and merge**, e **quem faz o merge é o autor**

📖 [Code review](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/code-review.md)

## Revisando o PR de outra pessoa

**Review tem prioridade sobre código novo.** Seu PR parado não bloqueia ninguém; o do colega bloqueia ele.

| Situação | Primeira resposta em |
|---|---|
| PR normal | 4 horas úteis |
| Hotfix | Imediato, fura a fila |
| PR grande (>400 linhas) | Mesmo dia, avisando quando vai olhar |

Marque a natureza do comentário: `[bloqueante]` · `[sugestão]` · `[dúvida]` · `[nit]` · `[elogio]`

Toda crítica vem com alternativa ou com pergunta. Crítica é sempre no código, nunca na pessoa.

**Não comente formatação.** Isso é trabalho do Biome.

## Pronto de verdade

- [ ] Código na `main` via PR aprovado
- [ ] CI verde (lint, testes, build)
- [ ] Testes cobrindo o comportamento novo
- [ ] Critérios de aceite verificados um a um
- [ ] Validado pelo solicitante em homologação
- [ ] Deployado em produção **e conferido**
- [ ] Documentação atualizada, se mudou setup, env var ou contrato de API
- [ ] Tarefa do Planio atualizada com o link do PR

> "Terminei, só falta subir" não é concluída. "Subiu, mas não conferi" também não.

---

## Travou?

**45 minutos** batendo no mesmo problema sem progresso → peça ajuda no canal do time. Pedir ajuda não é sinal de júnior.

Outras formas de conseguir ajuda: [SUPPORT.md](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/SUPPORT.md).

## Encontrou um problema neste handbook?

Corrija. Não peça permissão — abra um PR. Documentação que só o gestor edita morre em dois meses.

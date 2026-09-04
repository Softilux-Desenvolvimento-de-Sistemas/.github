# ADRs

Registro curto de decisão técnica com trade-off relevante — a resposta, daqui a
dois anos, para "por que isso foi feito assim?".

As regras e o modelo completo estão no [handbook][adr]. O que este arquivo
registra é só o que é **deste** repositório.

## Onde o ADR mora

O escopo da decisão decide a pasta:

| A decisão afeta | Mora em | Exemplos |
|---|---|---|
| O workspace inteiro | `docs/adr/` (aqui) | entrar um app novo, política do catalog, formato do contrato entre os apps |
| Um app só | `apps/<app>/docs/adr/` | escolha de ORM, fila vs cron, retenção de dado de um domínio |

Numeração **independente por escopo** — a raiz e cada app têm a sua sequência. O
caminho já desambigua, e sequência única exigiria coordenação entre PRs de apps
diferentes, que é justamente o atrito que monorepo elimina.

Nome em inglês e kebab-case. O modelo é o [`0000-template.md`](0000-template.md)
deste diretório — os apps referenciam este, não têm cópia própria.

```
docs/adr/                            ← workspace
├── 0000-template.md
└── 0001-....md

apps/<app>/docs/adr/                 ← só aquele app
└── 0001-....md
```

**ADR não se edita.** Mudou de ideia? Escreva um novo e marque o anterior como
substituído.

[adr]: https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/templates/adr-template.md

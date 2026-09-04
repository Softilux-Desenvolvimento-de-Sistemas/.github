---
paths:
  - "<caminho/do/arquivo/gerado>"
  - "<apps/*/outro-gerado.json>"
---

# Este arquivo é gerado — não edite à mão

A mudança some na próxima geração.

| Arquivo | Quem gera | Comando |
|---|---|---|
| `<caminho>` | `<a origem: um schema, um DTO, um CLI>` | `<o comando exato>` |

**Precisa mudar o comportamento?** Mude a origem:

- `<sintoma>` → `<o arquivo de origem>`, depois regenere e commite o diff.

Arquivo gerado normalmente fica **fora do Biome**, então editar não acusa erro
nenhum — a ausência de erro não é permissão.

Diga também qual deles o CI confere e qual segue **sem guarda**: a lista honesta
é o que evita alguém confiar numa proteção que não existe.

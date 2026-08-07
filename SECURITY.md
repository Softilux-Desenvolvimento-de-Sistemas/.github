# Política de segurança

**Este arquivo vale para todos os repositórios da Softilux.**

---

## Reportando uma vulnerabilidade

> [!CAUTION]
> **Não abra issue pública, PR ou mensagem em canal aberto descrevendo uma falha de segurança.** A descrição do problema é, por definição, o roteiro para explorá-lo.

| Quem é você | Como reportar |
|---|---|
| Do time | Fale **direto com o responsável do setor**. Não use canal aberto |
| De fora | [suporte@prodb.com.br](mailto:suporte@prodb.com.br) |

Em repositório privado, use também **Security → Report a vulnerability** (GitHub Private Vulnerability Reporting).

### O que incluir

- Qual produto e ambiente (produção, homologação)
- O que a falha permite fazer, em uma frase
- Passos para reproduzir
- Se há indício de que já foi explorada

### O que esperar

| Etapa | Prazo |
|---|---|
| Confirmação de recebimento | 1 dia útil |
| Avaliação inicial e classificação de severidade | 3 dias úteis |
| Correção de falha crítica | Tratada como incidente de produção |

Falha crítica entra pelo fluxo de [deploy e incidentes](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/deploy-and-incidents.md), com postmortem — sem nome e sem culpado, o alvo é o processo.

---

## Vazamento de credencial

**Commitou segredo, chave ou token? Avise imediatamente.** Não tente resolver sozinho e não apague o commit em silêncio.

> [!IMPORTANT]
> **Remover do histórico não basta.** A partir do momento em que a credencial foi enviada para o GitHub, ela tem que ser considerada comprometida e **rotacionada**. O histórico pode já ter sido clonado, indexado ou cacheado.

Ordem das coisas:

1. Avise o time e quem administra o serviço afetado — **agora**, não depois de tentar limpar
2. **Rotacione a credencial**
3. Depois disso, limpe o histórico
4. Verifique os logs do serviço no período em que a chave esteve exposta

Isso não é motivo de bronca. Erro é insumo, não culpa — errar em silêncio é que não é aceitável.

---

## O básico que evita a maior parte disso

| Prática | Onde está documentado |
|---|---|
| Segredo em GitHub Secrets, nunca no YAML ou no código | [CI/CD](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/ci-cd.md#segredos-e-variáveis-de-ambiente) |
| `.env` fora do versionamento; só `.env.example` sem valores | [Padrão de repositório](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/workflow/repo-standards.md) |
| Entrada externa validada por schema antes de chegar ao banco | Zod ou class-validator, sempre na borda |
| Autorização checada, não só autenticação | [Code review](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/code-review.md) |
| Nunca vazar stack trace ou erro de banco para o cliente | Mensagem genérica para o cliente, detalhe só no log |
| `permissions: contents: read` no topo do workflow | [CI/CD](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/ci-cd.md) |
| Action de terceiro com acesso a segredo fixada por SHA | [CI/CD](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/ci-cd.md) |
| Dependabot ativo, atualização entra como `chore` na sprint | [CI/CD](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/devs/engineering/ci-cd.md) |

**Segurança é item de code review**, não uma fase separada no fim. Está na lista do que se olha em todo PR.

---

## Escopo

Esta política cobre os repositórios da organização e os produtos que a equipe mantém.

Estes repositórios são internos e não têm programa de bug bounty. Pesquisadores externos de boa-fé são bem-vindos a reportar pelo contato acima.

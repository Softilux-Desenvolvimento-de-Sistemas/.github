<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../profile/assets/logo-banner-dark.png">
  <img src="../profile/assets/logo-banner-light.png" alt="Softilux" width="320" />
</picture>

# Team Handbook

**Tudo que um dev precisa saber para trabalhar aqui.**

<br/>

[![Cultura](https://img.shields.io/badge/Cultura-F26522?style=for-the-badge&logoColor=white)](culture/)
[![Onboarding](https://img.shields.io/badge/Onboarding-1E6FEB?style=for-the-badge&logoColor=white)](onboarding/)
[![Fluxo de trabalho](https://img.shields.io/badge/Fluxo_de_trabalho-2E9BD6?style=for-the-badge&logoColor=white)](workflow/)
[![Engenharia](https://img.shields.io/badge/Engenharia-134E8F?style=for-the-badge&logoColor=white)](engineering/)
[![Templates](https://img.shields.io/badge/Templates-5A6B7B?style=for-the-badge&logoColor=white)](templates/)

</div>

---

> [!IMPORTANT]
> **Este handbook é vivo.** Encontrou algo errado, desatualizado ou faltando? Corrija. Não peça permissão — abra um PR ou edite a página e avise no canal do time.
>
> Documentação que só o gestor edita morre em dois meses.

---

## 🚀 Comece por aqui

Se você é novo no time, siga nesta ordem. São ~40 minutos de leitura no total.

| # | Página | Por quê |
|:---:|---|---|
| 1 | **[Primeiro dia](onboarding/first-day.md)** | Checklist das primeiras 48h |
| 2 | **[Manifesto da equipe](culture/manifesto.md)** | Como trabalhamos e o que esperamos um do outro |
| 3 | **[Ambiente de desenvolvimento](onboarding/dev-environment.md)** | Instalação e setup da máquina |
| 4 | **[Editores](onboarding/editors.md)** | VS Code, Zed, extensões e configurações |
| 5 | **[Acessos e ferramentas](onboarding/access-and-tools.md)** | Contas, permissões e onde fica cada coisa |
| 6 | **[Ciclo da demanda](workflow/demand-cycle.md)** | Como uma tarefa nasce, anda e termina |
| 7 | **[Git e GitHub](engineering/git-and-github.md)** | Branches, commits, PRs |

> [!TIP]
> Só tem 10 minutos? Leia o **[Manifesto](culture/manifesto.md)**. É o item mais importante da lista.

---

## 📚 Índice completo

### 🧭 [Cultura](culture/)

Como o time se comporta, se reconhece e cresce.

| Página | O que é |
|---|---|
| [Manifesto](culture/manifesto.md) | Princípios de trabalho, comunicação e postura |
| [Sprints](culture/sprints.md) | Número, nome, símbolo e objetivo de cada sprint |
| [Recompensas](culture/rewards.md) | Manto Sagrado, comemorações e reconhecimento |
| [Trilha de carreira](culture/career-ladder.md) | Matriz Jr → Pl → Sr e como subir de nível |

### 🎒 [Onboarding](onboarding/)

Do primeiro dia até a máquina rodando.

| Página | O que é |
|---|---|
| [Primeiro dia](onboarding/first-day.md) | Checklist de chegada |
| [Ambiente de desenvolvimento](onboarding/dev-environment.md) | WSL, macOS, Node, npm, Docker, banco |
| [Editores](onboarding/editors.md) | Configuração padrão de VS Code e Zed |
| [Acessos e ferramentas](onboarding/access-and-tools.md) | Planio, GitHub, ambientes, credenciais |

### 🔄 [Fluxo de trabalho](workflow/)

Como uma demanda vira software em produção.

| Página | O que é |
|---|---|
| [Ciclo da demanda](workflow/demand-cycle.md) | Planio, triagem, DoR, DoD |
| [Sprints e rituais](workflow/sprint-rituals.md) | Agenda fixa, planning, review, retro, tech sync |
| [Padrão de repositório](workflow/repo-standards.md) | Estrutura padrão, README, criticidade |

### ⚙️ [Engenharia](engineering/)

O padrão técnico: como se escreve, revisa, testa e sobe código aqui.

| Página | O que é |
|---|---|
| [Git e GitHub](engineering/git-and-github.md) | Estratégia de branch, commits, proteções |
| [Code review](engineering/code-review.md) | SLA, o que olhar, como criticar |
| [Testes](engineering/testing.md) | Vitest, o que testar, cobertura |
| [CI/CD](engineering/ci-cd.md) 🚧 | GitHub Actions, pipelines, ambientes — **em construção** |
| [Deploy e incidentes](engineering/deploy-and-incidents.md) | Como subir e o que fazer quando cai |

### 📋 [Templates](templates/)

Modelos prontos para copiar.

| Página | O que é |
|---|---|
| [Pull request](templates/pull-request-template.md) | Template de PR |
| [Retrospectiva](templates/retro-template.md) | Roteiro da retro |
| [ADR](templates/adr-template.md) | Registro de decisão de arquitetura |

---

## 🔎 Preciso de uma resposta rápida

<table>
<tr><td width="50%">

**"Como eu nomeio esta branch?"**
→ [Git e GitHub](engineering/git-and-github.md#nomenclatura-de-branch)

**"Em quanto tempo preciso revisar um PR?"**
→ [Code review](engineering/code-review.md#sla)

**"Quando uma tarefa está realmente pronta?"**
→ [DoD](workflow/demand-cycle.md#definition-of-done-dod)

**"Preciso escrever teste para isso?"**
→ [Testes](engineering/testing.md#o-que-testar)

</td><td width="50%">

**"Produção caiu, e agora?"**
→ [Deploy e incidentes](engineering/deploy-and-incidents.md)

**"Me pediram algo fora da sprint"**
→ [Ciclo da demanda](workflow/demand-cycle.md#triagem)

**"Estou travado há 45 minutos"**
→ [Manifesto, regra 2](culture/manifesto.md#2-bloqueio-é-assunto-do-time-não-seu)

**"O que preciso num repositório novo?"**
→ [Checklist](engineering/ci-cd.md#checklist-de-repositório-novo)

</td></tr>
</table>

---

## 📞 Contatos rápidos

| Preciso de… | Onde |
|---|---|
| Prioridade, escopo, 1:1 | Responsável da equipe |
| Acesso, credencial, ambiente | Responsável do setor · [suporte@prodb.com.br](mailto:suporte@prodb.com.br) |
| Abrir ou acompanhar uma demanda | [Planio](https://softilux.planio.com) |
| Monitoramento e status | [Grafana](https://status.prodb.com.br/login) |
| Destravar de um problema técnico | Canal do time — [regra dos 45 minutos](culture/manifesto.md#2-bloqueio-é-assunto-do-time-não-seu) |
| Falha de segurança | Não use canal aberto — ver [SECURITY.md](https://github.com/Softilux-Desenvolvimento-de-Sistemas/.github/blob/main/SECURITY.md) |

> Este repositório é público, então aqui ficam **papéis**, não nomes. Seu buddy te apresenta a todo mundo na primeira semana.

---

## 📐 Convenções deste handbook

- `<!-- PREENCHER -->` marca informação que ainda falta. **Se você sabe a resposta, preencha.**
- Decisão de engenharia com trade-off relevante vira um [ADR](templates/adr-template.md) no repositório correspondente, não uma página aqui.
- Regras específicas de um projeto moram no `claude.md` do repositório dele e **têm precedência** sobre este handbook.
- Uma página por assunto. Se você precisa de duas, o assunto eram dois.

<div align="center">

---

_Feito com 💙 em Florianópolis._

</div>

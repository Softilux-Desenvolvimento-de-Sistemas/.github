# Primeiro dia

Esta é a sua lista. Não tem prazo por item nem dia marcado — você se organiza com o que já está feito e o que falta. O que importa é a ordem: cada bloco depende do anterior.

Se a máquina ou algum acesso não estiverem prontos, isso é bloqueio e não é seu problema resolver — reporte na daily.

## Buddy

Todo novo dev tem um **buddy** nas duas primeiras semanas: um dev do time (não o gestor) que é o canal de pergunta boba, o par no primeiro PR e a pessoa que apresenta os outros.

Se você é o buddy: reserve ~1h/dia da sua primeira semana com essa pessoa. Isso é trabalho, não favor — está contabilizado na sua capacidade da sprint.

---

## Chegando

- [ ] Recepção, mesa, Manto Sagrado, apresentação ao time
- [ ] Ler o [Manifesto](../culture/manifesto.md) — 10 minutos, é o mais importante desta lista
- [ ] Ler [Sprints](../culture/sprints.md) e [Recompensas](../culture/rewards.md)
- [ ] Conferir todos os acessos, um por um ([Acessos e ferramentas](access-and-tools.md))

## Máquina de pé

- [ ] Setup do ambiente ([Ambiente de desenvolvimento](dev-environment.md))
- [ ] Configuração do editor ([Editores](editors.md))
- [ ] Clonar o monorepo do produto em que você vai mexer — estrutura padrão em [Padrão de repositório](../workflow/repo-standards.md). Um clone põe o produto inteiro de pé: `pnpm install && docker compose up -d && pnpm dev`
- [ ] Subir o ambiente completo de um produto: banco via Docker, migrations, seed, API e front conversando
- [ ] Rodar a suíte de testes local e ver tudo verde

> Até aqui não existe meta de código. Máquina funcionando e um projeto rodando localmente já é entrega.

## Como se trabalha aqui

- [ ] Ler [Ciclo da demanda](../workflow/demand-cycle.md) e [Git e GitHub](../engineering/git-and-github.md)
- [ ] Ler [Code review](../engineering/code-review.md)
- [ ] Acompanhar a daily e a triagem só observando
- [ ] Participar de todos os rituais ([Sprints e rituais](../workflow/sprint-rituals.md))

## Primeira entrega

- [ ] Pegar a primeira tarefa (pequena, real, com valor — nunca tarefa de mentirinha)
- [ ] Abrir o primeiro PR, mesmo que minúsculo. Passar pelo fluxo inteiro é o objetivo, não o tamanho da entrega
- [ ] Fazer review em PR de outra pessoa (mesmo que só perguntando)
- [ ] 1:1 com o gestor

## Rodando sozinho

- [ ] Ter mexido em pelo menos dois produtos diferentes
- [ ] Ter feito um deploy acompanhado
- [ ] Ter apresentado algo no tech sync — pode ser "o que me confundiu no onboarding"
- [ ] Ter corrigido algo neste handbook

> O último item é sério. Ninguém enxerga as lacunas da documentação melhor que quem acabou de chegar. Depois de um mês você já normalizou tudo e não vê mais.

---

## Suas primeiras perguntas, respondidas

**Posso perguntar isso?** Sim. A regra dos 45 minutos vale desde o primeiro dia, e para você vale ainda mais.

**Vou quebrar alguma coisa?** Você não tem acesso de escrita direto em `main` nem em produção. Erre à vontade em branch.

**Quanto tempo até eu ser produtivo?** Não é medido. Espera-se que você entregue coisas pequenas logo no começo e comece a pegar tarefa normal quando o ambiente e o fluxo já estiverem naturais.

**Preciso saber todos os produtos?** Não. Vamos te expor a eles aos poucos.

**A quem eu peço prioridade?** Ao gestor, sempre. Se um coordenador ou outra área te pedir algo direto, redirecione educadamente para a triagem. Isso te protege — detalhes em [Ciclo da demanda](../workflow/demand-cycle.md).

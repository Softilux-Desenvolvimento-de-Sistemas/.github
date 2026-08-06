# Acessos e ferramentas

## Onde fica cada coisa

| Ferramenta | Para que serve | O que **não** fazer nela |
|---|---|---|
| **Planio** | Fonte da verdade de demanda: o quê, por quê, para quem, prazo | Discussão técnica profunda, revisão de código |
| **GitHub** | Código, PR, review, CI, ADR | Registrar prioridade de negócio |
| **Notion** | Este handbook e documentação de processo | Duplicar o que está no Planio ou no README do repo |
| **Canal do time** | Conversa do dia, bloqueio, aviso rápido | Decisão que não fica registrada em lugar nenhum |
| **Gerenciador de segredos** | Credencial, chave de API, `.env` de ambiente | — |

> **A regra que evita 80% da confusão:** Planio = *o quê* e *por quê*. GitHub = *como*. Notion = *como a gente trabalha*. A ponte entre Planio e GitHub é o ID da tarefa no nome da branch e no título do PR. Nunca duplique informação entre eles.

## Checklist de acessos do dia 1

- [ ] E-mail corporativo
- [ ] Planio — permissão nos projetos do time
- [ ] GitHub — convite para a organização e para os times de repositório
- [ ] Canal de comunicação do time
- [ ] Gerenciador de segredos
- [ ] VPN, se aplicável
- [ ] Acesso de leitura ao banco de homologação
- [ ] Acesso ao painel de deploy / hospedagem
- [ ] Acesso ao monitoramento e logs

**Quem provisiona:** o responsável do setor. Solicitações e dúvidas: **suporte@prodb.com.br**

**Prazo esperado:** tudo no primeiro dia. Acesso pendente é bloqueio — reporte na daily.

## Níveis de acesso por nível de senioridade

| Recurso | Júnior | Pleno | Sênior |
|---|---|---|---|
| Repositórios | Write | Write | Write / Maintain |
| Merge em `main` | Via PR aprovado | Via PR aprovado | Via PR aprovado |
| Banco de homologação | Leitura | Leitura/escrita | Leitura/escrita |
| Banco de produção | Nenhum | Leitura sob demanda | Leitura |
| Deploy em produção | Não | Acompanhado | Sim |
| Console de infraestrutura | Não | Leitura | Escrita |

Ninguém, em nenhum nível, tem push direto em `main`. Inclusive o gestor.

## Segredos e credenciais

**Regras invioláveis:**

1. Segredo nunca vai para o Git. Nem em branch, nem comentado, nem "só por um minuto".
2. Segredo nunca vai para o canal de mensagem, nem para o Planio, nem para o Notion.
3. Todo repositório tem um `.env.example` com as chaves **sem valores**. É ele que documenta o que é preciso.
4. Precisou de uma credencial? **Fale com o responsável do setor.** Credencial não se pede em canal aberto nem se repassa entre colegas.

Se você commitou um segredo por acidente: **avise imediatamente**, não tente esconder reescrevendo o histórico sozinho. A credencial precisa ser rotacionada — remover do histórico não basta, porque ela já vazou.

## Planio — o que você precisa saber

Fluxo completo em [Ciclo da demanda](../workflow/demand-cycle.md). O essencial:

- Você trabalha a partir de tarefas em **Selecionada (sprint)** e **Em desenvolvimento**.
- Você não pega tarefa direto de **Nova** ou **Backlog** sem falar com o gestor.
- Atualize o status da sua tarefa **no dia em que ela muda**, não na sexta.
- Registre na tarefa qualquer decisão de negócio tomada durante a execução.
- Alguém de fora te pediu algo direto? Peça para abrir tarefa no Planio. Sem exceção — é isso que impede o time de virar balcão.

### Como recusar demanda direta sem criar atrito

> "Consigo sim, mas abre uma tarefa no Planio para eu não perder e o [gestor] conseguir encaixar na prioridade? Se for urgente me avisa que eu falo com ele agora."

Funciona porque não diz não, registra a demanda e move a decisão de prioridade para quem tem que tomá-la.

## GitHub

- Autenticação por chave SSH ([setup](dev-environment.md#chave-ssh-para-o-github)).
- 2FA obrigatório na organização.
- Seu usuário deve ter nome real e foto — review anônimo é ruim de ler.
- Times por produto, com `CODEOWNERS` apontando para eles.

## Ambientes

| Ambiente | Para que serve | Quem pode subir |
|---|---|---|
| Local | Desenvolvimento | Todos |
| Homologação | Validação com solicitante antes de produção | Todos, via merge em `main` |
| Produção | Cliente real | Ver [Deploy e incidentes](../engineering/deploy-and-incidents.md) |

URLs, painéis e credenciais de cada ambiente: com o responsável do setor.

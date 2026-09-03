# Acessos e ferramentas

## Onde fica cada coisa

| Ferramenta | Para que serve | O que **não** fazer nela |
|---|---|---|
| **Planio** | Fonte da verdade de demanda: o quê, por quê, para quem, prazo | Discussão técnica profunda, revisão de código |
| **GitHub** | Código, PR, review, CI, ADR e este handbook | Registrar prioridade de negócio |
| **Grafana** | Monitoramento e status dos ambientes ([Deploy e incidentes](../engineering/deploy-and-incidents.md#monitoramento)) | — |
| **Grupo de WhatsApp** | Conversa do dia, bloqueio, aviso rápido | Decisão que não fica registrada em lugar nenhum, e qualquer credencial |
| **Obsidian** | As senhas e credenciais que você usa no trabalho | Compartilhar credencial com colega |
| **VPN** | Acesso à rede interna | — |

> **A regra que evita 80% da confusão:** Planio = *o quê* e *por quê*. GitHub = *como* e *como a gente trabalha*. A ponte entre os dois é o ID da tarefa no nome da branch e no título do PR. Nunca duplique informação entre eles.

**Quem provisiona:** o responsável do setor. **Os endereços de acesso e as credenciais de cada ferramenta você pega com ele** — nada disso fica escrito aqui.

**Problema com a VPN** — não conecta, cai, credencial não funciona — é com o suporte da Prodb: **suporte@prodb.com.br**.

**Prazo esperado:** tudo no primeiro dia. Acesso pendente é bloqueio — reporte na daily.

## Segredos e credenciais

Existem dois tipos de segredo, e cada um tem um lugar só:

| O quê | Onde fica |
|---|---|
| **Variável de aplicação** — `DATABASE_URL`, chave de API, token de serviço | No `.env` do projeto, na sua máquina. Nunca versionado |
| **Senha de ferramenta** — Planio, VPN, painel, banco de homologação | No **Obsidian**, no seu vault pessoal, na sua máquina |

**Regras invioláveis:**

1. Segredo nunca vai para o Git. Nem em branch, nem comentado, nem "só por um minuto".
2. Segredo nunca vai para o grupo de WhatsApp nem para o Planio.
3. Todo repositório tem um `.env.example` com as chaves **sem valores**. É ele que documenta o que é preciso — o `.env` de verdade fica fora do versionamento e você preenche na sua máquina.
4. **Nada de compartilhar.** Nem `.env` por WhatsApp, nem print da senha, nem vault repassado. Precisou de uma credencial? **Fale com o responsável do setor** — é dele que vem, sempre.

Se você commitou um segredo por acidente: **avise imediatamente**, não tente esconder reescrevendo o histórico sozinho. A credencial precisa ser rotacionada — remover do histórico não basta, porque ela já vazou.

### Guardando suas senhas no Obsidian

Como o Obsidian guarda nota em markdown puro, sem criptografia própria, quatro cuidados são obrigatórios:

1. **O vault não pode ficar dentro de pasta versionada.** Nunca em `~/projects` nem em qualquer diretório que tenha um `.git`. É o jeito mais fácil de mandar credencial para o repositório sem perceber — exatamente o que a regra 1 proíbe.
2. **Não sincronize o vault por Drive, Dropbox ou OneDrive comum.** A nota chega legível do outro lado. Se precisar sincronizar entre máquinas, use o **Obsidian Sync**, que é criptografado ponta a ponta.
3. **Criptografia de disco ligada** — FileVault no macOS, BitLocker no Windows. Sem isso, notebook perdido é credencial perdida.
4. **O vault é pessoal.** Ele guarda a *sua* cópia das credenciais que você já tem acesso. Não é canal de distribuição: credencial nova continua vindo do responsável do setor, nunca de um vault repassado.

> O vault é para senha de ferramenta. Segredo de aplicação não entra ali: no seu desenvolvimento ele vive no `.env` do projeto, e **em produção vive num arquivo de ambiente na própria VM**, com permissão `600` e dono `deploy`. Não usamos GitHub Secrets para segredo de produção — o pipeline roda na máquina que já tem o arquivo, então o segredo nunca passa pelo GitHub ([Padrão de deploy](../engineering/deploy-standard.md#segurança-o-que-sustenta-isto)).

## Planio — o que você precisa saber

Fluxo completo em [Ciclo da demanda](../workflow/demand-cycle.md). O essencial:

- Você puxa tarefa do **Backlog** e move para **Em desenvolvimento**.
- Você não pega tarefa direto de **Nova** ou **Analisar** — elas ainda não passaram pela triagem.
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
- Quem revisa PR de um produto são os sêniors daquele projeto ([Code review](../engineering/code-review.md)).

**Ninguém tem push direto em `main`. Inclusive o gestor.** Tudo entra por PR aprovado.

## Ambientes

| Ambiente | Para que serve | Quem pode subir |
|---|---|---|
| Local | Desenvolvimento | Todos |
| Produção | Cliente real | **Quem faz o merge** — push na `main` dispara o deploy |

> [!WARNING]
> **Não há homologação.** O plano contratado não nos dá o segundo ambiente, então
> o primeiro a exercitar uma mudança é o cliente. É a dívida mais cara do nosso
> desenho, e ela é de plano, não de descuido — está registrada em
> [Padrão de deploy](../engineering/deploy-standard.md#o-que-este-padrão-não-resolve).
>
> Consequência prática: **validar com o solicitante acontece antes do merge**, não
> depois.

URLs, painéis e credenciais de cada ambiente: com o responsável do setor.

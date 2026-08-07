# Template de Pull Request

Salve o conteúdo abaixo em `.github/pull_request_template.md` na raiz de cada repositório.

---

```markdown
## O que muda

<!-- Uma ou duas frases. O revisor precisa entender o objetivo sem abrir o Planio. -->

Tarefa: #0000

## Por quê

<!-- Contexto e decisão. Se você escolheu entre dois caminhos, diga qual e por quê.
     É aqui que o review deixa de ser sobre sintaxe e passa a ser sobre desenho. -->

## Como testar

<!-- Passo a passo. Dado, quando, então. Se precisa de dado específico, diga qual. -->

1.
2.
3.

## Checklist

- [ ] Testei localmente
- [ ] Reli o próprio diff
- [ ] Testes cobrindo a mudança (ou justificativa de por que não)
- [ ] CI verde
- [ ] Critérios de aceite da tarefa atendidos
- [ ] Sem `console.log`, código comentado ou arquivo sobrando
- [ ] Sem segredo, chave ou credencial no diff

## Impacto

- [ ] Tem migration
- [ ] Tem env var nova (adicionada ao `.env.example`)
- [ ] Muda contrato de API
- [ ] É breaking change
- [ ] Exige passo manual no deploy

<!-- Se marcou qualquer um acima, explique aqui: -->

## Evidência

<!-- Print, gif ou vídeo curto para mudança de UI. Response de exemplo para API. -->
```

---

## Notas de uso

**"Por quê" é o campo mais importante.** O diff mostra o que mudou; só você sabe por que aquele caminho foi escolhido. Um parágrafo aqui economiza cinco idas e voltas no review.

**"Como testar" não é opcional.** O revisor não deveria ter que adivinhar como reproduzir. Em mudança de fluxo, seja específico sobre o dado necessário.

**A seção "Impacto" existe para uma coisa só:** garantir que ninguém descubra a migration ou a env var nova durante o deploy. Marcar uma dessas caixas aumenta o rigor do review automaticamente.

**Marcar checkbox sem ter feito** é pior que não ter template. O checklist só funciona se o time levar a sério — e, quando alguém marca sem fazer, isso aparece no primeiro incidente.

# Retrospectiva

45 minutos, sexta de fim de missão. Só o time — sem coordenador, sem diretoria.

Facilitação **rotativa** entre os devs. Quando é sempre o gestor que conduz, a retro vira reunião de status e as pessoas param de falar o que importa.

## Regras

1. **Processo, não pessoa.** "Nossa estimativa foi otimista" e não "o Fulano estimou errado".
2. **Máximo 2 ações.** Retro com 8 ações não gera nenhuma.
3. **Toda ação tem dono e prazo.** Sem isso é desabafo, não retro.
4. **Começa revisando as ações da retro anterior.** Se elas nunca acontecem, o time para de levar a sério — e com razão.
5. **O que é dito na retro fica na retro**, exceto as ações.

---

## Roteiro padrão (45 min)

| Tempo | Etapa |
|---|---|
| 5 min | Revisar ações da retro anterior — feito? não feito? por quê? |
| 5 min | Números da missão: objetivo cumprido? lead time? o que entrou fora do plano? |
| 10 min | Coleta individual, em silêncio, cada um escrevendo |
| 15 min | Discussão dos temas agrupados |
| 8 min | Definir até 2 ações, com dono e prazo |
| 2 min | Fechamento |

Os 10 minutos de escrita em silêncio antes da discussão não são desperdício: sem eles, a primeira opinião falada ancora todas as outras, e quem é mais quieto não contribui.

---

## Formatos

Alterne. O mesmo formato quatro vezes seguidas produz as mesmas respostas automáticas.

### 1. Clássico

- **Continuar** — o que funcionou e queremos manter
- **Parar** — o que atrapalhou
- **Começar** — o que queremos experimentar

### 2. Barco à vela

- **Vento** — o que nos impulsionou
- **Âncora** — o que nos segurou
- **Rochas** — riscos que enxergamos à frente
- **Ilha** — para onde queremos ir

Bom para retro em que o time precisa olhar adiante, não só para trás.

### 3. Quatro Ls

- **Liked** — gostei
- **Learned** — aprendi
- **Lacked** — faltou
- **Longed for** — senti falta

Bom depois de missão difícil: dá espaço para o aprendizado sem virar sessão de reclamação.

### 4. Linha do tempo

Desenhe a sprint dia a dia e cada um marca os momentos altos e baixos. Excelente quando o time sente que "foi caótico" mas ninguém sabe apontar onde.

### 5. Retro do incidente

Depois de SEV1/SEV2, use o formato de [postmortem](../engineering/deploy-and-incidents.md#postmortem).

---

## Registro

```markdown
# Retro — Missão <número> — <nome> — <data>

**Facilitador:**
**Presentes:**
**Objetivo da missão:** cumprido / renegociado / não cumprido

## Ações da retro anterior
| Ação | Dono | Status |
|---|---|---|
| | | |

## Temas discutidos

### <tema>
<resumo do que se falou e da conclusão>

## Ações desta retro
| Ação | Dono | Prazo | Tarefa Planio |
|---|---|---|---|
| | | | |
```

Guarde no Notion, uma página por retro. Ler seis meses de retro de uma vez é a melhor ferramenta de diagnóstico de time que existe — os padrões que ninguém enxerga no dia a dia ficam óbvios.

---

## Quando a retro está morrendo

Sinais:

- Todo mundo diz "foi tudo bem" e acaba em 15 minutos
- As mesmas queixas reaparecem há três retros sem nenhuma ação
- Só uma ou duas pessoas falam
- O time trata como obrigação

O que fazer:

- Trocar de formato
- Trocar de facilitador
- **Executar uma ação até o fim.** Nada revive uma retro como o time ver uma reclamação antiga virar mudança real
- Se o silêncio for por desconforto com a presença de alguém, a retro tem que acontecer sem essa pessoa. Retro em que ninguém fala é pior que retro nenhuma

# Júri — Onboarding "Seu primeiro passo"

Três lentes julgaram as três direções. Este arquivo registra o placar, o que cada lente disse,
o que a versão final enxertou e o que ficou vetado.

**Entrega final:** `docs/design/mockups/onboarding/final/index.html` · PNGs na mesma pasta ·
mapa de funções em `final/mapa-de-funcoes.md`.

---

## Placar (soma das três lentes)

| direção | primeira impressão | uso real | identidade BrewTact | **total** |
|---|---:|---:|---:|---:|
| A — Mesa de escolha | 5 | 6 | 5 | **16** |
| **B — Três batidas** | **8** | **8** | **8** | **24** |
| C — Bancada viva | 4 | 5 | 4 | **13** |

**Vencedora: B — "Três batidas"**, unânime nas três lentes. É a base da final.

---

## Vereditos resumidos

### Primeira impressão (1 segundo, olho do dono)

- **A — 5.** A faixa-herói de latão e a dupla do rodapé (0 tracejado × 99 com artes reais) são as
  melhores peças isoladas do julgamento, mas ocupam ~25% da tela. Os outros 75% são quatro legendas
  de banda em caixa alta sobre colunas de caixas escuras com subtítulo cinza: a folha de configurações
  que o dono já reprovou. *Pior defeito:* as quatro bandas empilhadas + a sopa de chips em `#negado`
  e `#retomado`.
- **B — 8.** A única direção em que o jurado quis tocar na tela. `#vazio` tem cinco azulejos com
  miniatura real e um herói claramente maior; `#preenchido` acende o resumo em vitral e deixa um único
  latão. Trocar a parede de latão por vitral foi "a melhor decisão de design do conjunto".
  *Pior defeito:* as duas peças de modo da batida 3 são **ocas** — ~110px de nada entre o título e o
  estado — e a tira cinza de parágrafo se repete em quase todo estado.
- **C — 4.** É a tela de hoje repintada de latão: três bandas **numeradas** sobre 11–15 caixas quase
  idênticas com subtítulo cinza. A Home borrada, que deveria ser a defesa da direção, lê como
  artefato de renderização. *Pior defeito:* `formato.png` — sete linhas de ícone + rótulo + legenda
  cinza + parágrafo. Rejeição de 1 segundo.

### Uso real (Commander, com pressa, uma mão só)

- **A — 6.** A mais completa em função, mas a ação primária mora no **topo** enquanto as decisões
  descem até o rodapé; e em `#vazio` o latão do formato grita mais alto que o objetivo.
- **B — 8.** A única que se entende sem ler. Herói sempre no rodapé, escolha valendo no toque,
  `#carregando` é o melhor estado dos nove. *Pior defeito:* a batida 2 carrega **duas** decisões e
  avança sozinha — o momento está acima do formato, então o toque avança e as sete peças de formato
  nunca são alcançadas. ON-03/ON-77 vira função inalcançável.
- **C — 5.** Melhor ✕ e melhor tela de formato em conteúdo, mas descritores **não tocáveis** com a
  mesma roupa dos azulejos tocáveis, dois latões com significados diferentes na mesma fileira e
  ON-10 virando textura atrás do blur.

### Identidade BrewTact

- **A — 5.** Tire as três miniaturas de 28px e nada ali é Magic. Voz de especificação nas legendas.
- **B — 8.** A única que não poderia ser outro app: leque de artes, prévia de lista, fichário com
  lugar tracejado, mesa com as cores dos jogadores, oficina. *Pior defeito:* os sete formatos da
  batida 2 são sete retângulos iguais com o nome centralizado — o único lugar onde B para de ser
  objeto. Mais o rótulo cortado pela borda em dois azulejos de momento (bloqueio de entrega).
- **C — 4.** A melhor ideia isolada ("na Home") e o herói mais fiel à régua, debaixo da tela mais
  parecida com configurações das três, com o mapa de significado quebrado em cinco lugares.

**Nenhuma das três chegou ao nível do contador.** Só a batida 1 de B ficaria ao lado de `menu.png`
sem envergonhar.

---

## Enxertos aplicados na final

### De A — "Mesa de escolha"

1. **A rima 0 · 99** (obrigatória nas três lentes). "Criar do zero" = três lugares **tracejados**
   com numeral **0**; "Gerar uma base" = três **artes reais** no mesmo leque, com numeral **99**.
   Resolve de uma vez o pior defeito de B (as peças de modo ocas) e o "falta numeral" das três lentes.
2. **A coluna esquerda do herói**: numeral + palavra pequena + filete vertical + título Fraunces +
   botão redondo. É o "TURNO 3 | PASSAR A VEZ | Léo" de `menu.png`.
3. **O numeral do formato** dentro da peça (100 · Commander), no resumo e no nível 2.
4. **O herói tracejado** para `#negado`: moldura tracejada em latão com numeral 0, a ação e o estado
   dentro. A moldura, **não** os chips que vinham junto.
5. **A copy do ✕**: "PULAR / FICA SALVO" — entrega a promessa de ON-75 em duas palavras.
6. **A frase de fecho de `#negado`**: "Só dá para pular agora", no lugar do parágrafo de três linhas.
7. **O ícone do objetivo e a frase de confirmação (ON-67) dentro do herói** da batida 3.

### De C — "Bancada viva"

8. **O bloco aceso "Oficina · na Home"** — vitral com arte real dizendo para onde o app já se
   preparou. Único momento do conjunto em que o onboarding **faz** algo com o app em vez de só
   perguntar. Condicionado pela lente 3 a "só vale se a Home atrás for legível como Home": a final
   redesenhou o fundo para cumprir a condição (ver abaixo).
9. **O ✕ de tamanho cheio** (`.bt-x`, 64px) no lugar da variante de cabeçalho de 44px.
10. **O segundo nível do formato**, que tira o formato da batida 2 e conserta o pior defeito de uso
    de B: a batida 2 passa a ter **uma decisão só** e o avanço automático fica honesto. Desenhado
    como **objetos** (peça-faixa do kit com glifo próprio e a própria linha de valor), não como as
    sete linhas de legenda cinza que a lente 1 e a lente 3 vetaram.
11. **A disciplina de cobrir estado com desenho, não com descrição**: a final entrega sete PNGs
    mobile, incluindo o nível `#formato` que ninguém tinha provado.

---

## Enxertos recusados, e por quê

| enxerto pedido | decisão | motivo |
|---|---|---|
| "3 PASSO" como numeral do herói (lente 1, de C) | **recusado** | As lentes 2 e 3 vetam numeral **oco** no maior tipo da tela: na régua o numeral do herói é sempre valor real (40 de vida, 4 jogadores, o 5 do d8). Placar 2×1 contra. Na final o numeral do herói é sempre real: **99** cartas, **100** cartas, **0** caminhos. |
| Pips dentro do herói (lente 1, de C) | **recusado** | Veto da lente 3: pip de latão sobre latão vira borrão; em `menu.png` o pontinho só existe na cor do jogador. Os três pips ficam no alto, sobre o escuro. |
| "ESTREANDO / JÁ JOGUEI / SEMANAL" (lentes 1 e 2) | **substituído** | A lente 3 vetou: palavra de estado que só repete o rótulo. A final usa "Mais explicação / O que mudou / Direto ao ponto" — o que a escolha **muda**, que é ON-70 dentro do objeto. ⚠ copy nova. |
| Herói tracejado também em `#vazio` (lente 1) | **recusado em `#vazio`** | `#vazio` já tem um herói claramente maior: o azulejo gigante "Montar um deck" que as três lentes elogiaram. Dois heróis quebram a regra de um herói por tela. A moldura tracejada foi para `#negado`, onde a lente 1 apontou a ausência de dono. |
| `dir-c/formato.png` inteiro (lente 2) | **enxertado só na ideia** | As lentes 1 e 3 vetam o desenho (sete linhas de ícone + rótulo + legenda cinza + caixa de texto). A final leva o **conteúdo** (glifo próprio e a linha de valor de cada formato) numa grade de peças-faixa, com Commander em largura total e sem parágrafo informativo. |

---

## Vetos — o que a final não faz

1. **Banda numerada ou rotulada em caixa alta como estrutura da tela.** Máximo **uma** legenda por
   tela — e a final usa uma só: "Seu plano" (`#preenchido`), "Conte sobre seu momento" (`#retomado`).
   Nenhuma é numerada e nenhuma carrega cláusula de inventário.
2. **Sopa de chips.** Nenhum chip tracejado empilhado, nenhuma pílula cinza resumindo o plano. O
   caminho bloqueado é **uma** peça tracejada com numeral.
3. **Tira cinza flutuante com ícone e 2–3 linhas de texto corrido.** Morreu. A informação entrou nos
   objetos (a promessa de ON-72 é "Você revisa antes", dentro da peça).
4. **Ícone de equalizador/sliders para "Melhorar um deck".** Substituído por dois chevrons de subida.
5. **Erro que apaga o herói.** Em `#erro` o herói **sobrevive**, ganha aro de brasa, diz o que falhou
   e o botão redondo dele tenta de novo. Nada de barra larga de "Tentar novamente" sobre painel de
   brasa sobre caixa de dica.
6. **Carregando que lava a tela inteira.** Em `#carregando` um objeto continua aceso — o herói de
   latão com a rosca — e **o ✕ continua aceso**: não se trabalha sem saída (corrige ON-87).
7. **Seis a sete peças idênticas numa fileira.** No nível 2, Commander ocupa a linha inteira em latão
   com numeral 100; os outros seis são menores, cada um com glifo próprio e a própria linha de valor.
8. **Latão em peça não selecionada, e mais de duas superfícies de latão por tela.** Em `#preenchido`
   há exatamente duas: a peça de modo selecionada e o herói. O formato do resumo é **vitral** (maré),
   porque está valendo — não selecionado-como-jogada-principal.
9. **Azulejo descritivo não tocável com roupa de azulejo tocável.** O bloco "na Home" não é peça: não
   tem filete de azulejo, tem brilho externo, a arte sangra na borda esquerda e ele sai do desfoque
   da Home. Não é `<button>`.
10. **Copy de engenharia sobre o vidro.** "Sem resposta do serviço", "Armazenamento indisponível
    neste aparelho", "A navegação foi pausada" e "Contexto do caminho" saíram. ⚠ A passada de voz de
    mesa mexe em texto de ON-78: precisa do martelo do dono (lista em `final/mapa-de-funcoes.md`).
11. **Barra de erro encostada na borda de baixo.** A área segura é reservada: 44px no alto (ilha
    dinâmica) e 58px embaixo — e nessa faixa de baixo é a **barra de navegação da Home** que aparece,
    com o indicador de gestos desenhado por cima.

---

## O que a final resolve do "o que falta"

| pendência dos jurados | como ficou |
|---|---|
| **Numeral** — "B tem exatamente um 100 em nove telas" | Sete numerais serifados na batida 3 e no nível 2: 0, 99, 100 (resumo), 99 (herói), 100 (Commander), 0 e 100 nos heróis de `#negado` e `#retomado`. |
| **Mesa viva** — "ninguém resolveu; o véu precisa deixar a forma legível sem o texto" | A **Home** está embaixo, montada só com **formas**: barra de cima, faixa com arte, quatro cards de deck com miniatura, barra de navegação com cinco glifos. **Nenhum texto** na camada de fundo — por isso o desfoque não pode virar mancha de letra, que foi o que derrubou C. Véu forte em cima (.88) e fraco embaixo (.18): a barra de navegação da Home é reconhecível no rodapé de todas as telas. |
| **Respiro no topo** | Uma linha de pergunta por batida; `#preenchido` cabe em duas linhas de Fraunces, não três. |
| **A tira cinza de parágrafo** | Sumiu em todos os estados. |
| **`#erro` e `#negado` "corretos, não bonitos"** | `#erro`: recuperação dentro do herói. `#negado`: tabuleiro tracejado + peça de brasa de uma linha + herói tracejado com numeral 0. |
| **ON-94 (320×568, texto a 200%)** | **Regra escrita e provada**: abaixo de 360px de largura ou 660px de altura a batida volta a rolar e os azulejos viram uma coluna. `final/vazio-320.png` é a prova em 320×568. ⚠ A prova com `textScaler` 2,0× continua sendo do teste de widget — Chromium não simula textScaler. |
| **ON-11/ON-61/ON-92 (desktop)** | Desenhado: rail de 92px, duas colunas, herói ao lado, tabuleiro em quatro colunas, arte maior. `preenchido-1440.png`, `vazio-1440.png`, `carregando-1440.png`, `preenchido-1920.png`. |
| **Alvos de toque** | ✕ 64px, glifos do shell **44px** (eram 34 em B), seta de volta 44px, botão do herói 50px. |
| **Prova de aparelho** | ⚠ **Continua pendente.** Tudo aqui é Chromium. A área segura foi **reservada** (44px no alto, 58px embaixo, com o indicador de gestos desenhado), mas o simulador do iPhone e a medição de contraste no pixel (`tools/contrast.py`, `shot_check.py`) ainda não passaram por estes layouts. Enquanto não passarem, a final não pode ser declarada no nível do contador pelo padrão do próprio projeto. |

---

## PNGs da entrega

| arquivo | perfil | estado |
|---|---|---|
| `final/vazio-390.png` | 390×844 | batida 1, primeira execução |
| `final/preenchido-390.png` | 390×844 | batida 3, pronto para a ação |
| `final/carregando-390.png` | 390×844 | salvando o plano |
| `final/erro-390.png` | 390×844 | falha recuperável |
| `final/retomado-390.png` | 390×844 | batida 2 com o plano retomado |
| `final/negado-390.png` | 390×844 | zero caminhos |
| `final/formato-390.png` | 390×844 | nível 2 do formato (extra) |
| `final/vazio-320.png` | 320×568, página inteira | prova da regra do piso (ON-94) |
| `final/vazio-1440.png` | 1440×900 | desktop, batida 1 |
| `final/preenchido-1440.png` | 1440×900 | desktop, batida 3 |
| `final/carregando-1440.png` | 1440×900 | desktop, salvando |
| `final/preenchido-1920.png` | 1920×1080 | wide, batida 3 |

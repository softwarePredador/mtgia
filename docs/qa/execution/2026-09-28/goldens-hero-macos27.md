# Goldens do hero da Home — baseline refeita no macOS 27 (2026-09-28)

Arquivo **não commitado** enquanto o gate de UI está vermelho.

## O que falhava

Quatro goldens, não três como o relato inicial dizia:

```
home_hero_1440     home_hero_1920     home_hero_sma135m     home_hero_web
```

Diferenças medidas: 0,14% e 304 px no `home_hero_web` e no `_1440`/`_1920`;
0,42% e 286 px no `home_hero_sma135m`.

## Por que não era defeito do produto

Medido antes de tocar em qualquer coisa:

- nem os goldens nem o código da Home mudaram nesta branch — os dois últimos
  tocados em `b2d3fc04f`, de 13/08, e limpos na árvore;
- as minhas edições do dia foram em `battle_coach_screen.dart`, que não entra
  no hero;
- o Flutter é o pinado de sempre, 3.44.6;
- a única variável nova é o sistema: `macOS 27.0 (26A428)`.

## O que o diff mostrou, aberto imagem por imagem

`isolatedDiff`: apenas contornos fantasma dos mesmos glifos, nas mesmas
posições. Se houvesse deslocamento de layout, o diff traria texto dobrado e
sólido, não contorno.

`masterImage` × `testImage`, comparadas a olho: idênticas em texto
("Olá, Planeswalker", "Sua próxima jogada começa aqui.", "Jogar agora"), em
layout, em cor, na posição do logo e na curva pontilhada. A diferença é
subpixel na borda do glifo.

Nenhum deslocamento, nenhuma troca de texto, nenhuma cor nova — as três coisas
que a coordenação pediu para barrar a regeneração.

## A regeneração

Decisão da coordenação: é manutenção de baseline de teste, e golden não vale
como aprovação visual pelo contrato. Não há máquina no SO anterior para
confirmar, então esperar não traria ganho.

```
SHA-256, antes                     depois
277be4514bd6c4ef  home_hero_1440   ccfafadad055accf
277be4514bd6c4ef  home_hero_1920   ccfafadad055accf
4a172d4f2d20934a  home_hero_sma..  a025709bd3f32576
277be4514bd6c4ef  home_hero_web    ccfafadad055accf
```

Baseline refeita no **macOS 27.0 (26A428)**, com o Flutter pinado 3.44.6.
`home_screen_test.dart` passa nos 28 testes.

## Também nesta passagem

`app/test/ui/fixtures/ui_surface_inventory.json` e
`app/test/ui/ui_surface_inventory_test.dart`: o `profile_screen` tem sete
diálogos, não seis — o sétimo é a reverificação de senha para exportar dados
(BT-AUTH-004), que entrou nesta branch antes de hoje. Atualizei os três lugares
que precisavam acompanhar: a entrada do arquivo (6→7), o agregado
`expected_totals.dialog` (51→52) e a baseline fixada no teste (266→267), esta
com comentário dizendo de onde veio a superfície nova.

## Adendo (2026-09-29): um quinto golden, da galeria de decks

`deck_list_responsive_test.dart`, teste "wide gallery has a deterministic
reviewed visual baseline", acusou
`goldens/deck_gallery_card_1880.png` — "0.00%, 4px diff".

Medi pixel a pixel, e são quatro mesmo, todos no contorno de um ícone quadrado
pequeno no topo direito do cartão:

```
x=277 y=21   130,137,148 -> 128,135,146
x=286 y=21   130,137,148 -> 128,135,146
x=277 y=30   172,180,192 -> 172,179,191
x=286 y=30   172,180,192 -> 172,179,191
```

Diferença máxima de 2 em 255, em 4 pixels de 123.778. Ampliei master e teste
lado a lado em 8× e o ícone é o mesmo desenho: o que muda é a suavização dos
quatro cantos. É a mesma deriva de renderização do macOS 27 dos goldens do
hero, não mudança de layout, de cor nem de conteúdo.

Baseline refeita: `6f408b223db65be6…` -> `d1586579a389c3c1…`, com os 23 testes
do arquivo verdes depois. O digest de UI não se mexeu — `app/test/features`
não é raiz.

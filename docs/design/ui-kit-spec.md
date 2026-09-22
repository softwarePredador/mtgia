# Kit de UI compartilhado do BrewTact — especificação

> **Documentação de apoio, não autoritativa.** Não é lida por gates, digest de UI nem manifesto. O contrato oficial continua sendo `docs/project_logic_contracts.json` e a fila em `docs/execution/`.
>
> **Data:** 2026-09-21 · **Régua:** `docs/design/life-counter-prototype/` (mantido por outra sessão; aqui só foi lido).
>
> **Condição de entrada.** Nada desta spec vira código em `app/lib` antes de: (1) o gate de evidência de UI **`BT-UIEV-001`** estar verde; (2) worktree próprio; (3) ok do dono para reordenar a fila WIP-1; (4) as decisões de **§11** respondidas. Esta spec é o desenho, não a autorização.
>
> **Revisão de 2026-09-21 (segunda passada).** Dois revisores céticos conferiram esta spec contra o protótipo, `tokens.json`, `primitive-counts.json`, `app_theme.dart` e as provas. Cada achado foi **reconferido na fonte** antes de ser aplicado. O corpo da spec — a extração de tokens — sobreviveu inteiro; o que mudou foi o **texto normativo** (§2), a **regra de tinta** (§4.1f), a **limpeza de tema** (§7), a **guarda** (§9) e o **livro-caixa de divergências** (§10.3). Todo contraste que não passa foi movido para **§11 · Decisões em aberto para o dono**, com par, razão e saída proposta. **Nenhuma cor do protótipo foi alterada** — o protótipo é mantido por outra sessão e aqui só foi lido.

## 0 · O que foi olhado

| Insumo | Papel |
|---|---|
| `docs/design/life-counter-prototype/mesa-brewtact.html` | **A régua.** Quando ele e `design/vitral/menu.html` divergem, manda ele. |
| `design/vitral/menu.png` · `design/vitral/jogadores.png` | O desenho alvo do azulejo, do herói, da peça com miniatura e da peça-numeral. |
| `provas-iphone/vt-04-regras.png` | Peça-regra acesa + peça-numeral + peça-regra pequena, no aparelho. |
| `provas-iphone/vt-05-jogador.png` | Bloco vivo do dono, brasa cheia "valendo", placa de texto, fileira de cores. |
| `provas-iphone/vt-06-dados.png` · `vt-07-quem-comeca.png` | Resultado herói, peça-forma, faixa de ação, fileira de jogadores com valor. |
| `docs/design/ui-kit/kit.css` · `tokens.json` | 133 tokens extraídos e conferidos. Os **valores** são citados, não recalculados; os **contrastes** foram recalculados nesta revisão (§11) porque a amostragem anterior do gradiente estava no ponto errado. |
| `docs/design/ui-kit/specimen-390.png` · `specimen-1440.png` | As 11 seções do kit renderizadas nos dois extremos. |
| `app/lib/core/theme/app_theme.dart` | O tema atual (1.025 linhas). |
| `app/test/core/theme/app_theme_token_usage_test.dart` | Proíbe cor local fora de 5 caminhos de exceção. |
| `docs/design/visual-audit-2026-09-21/README.md` | A nota das telas fora do contador: 4–5 de 10. |
| `docs/design/sequencia-e-esforco.md` | 949 pontos de conversão, em 6 ondas. |

**O kit é tradução, não reinterpretação.** Todo valor abaixo sai do protótipo. O que não sai está marcado **DERIVADO** e vem com a regra do mapa que o gerou.

---

## 1 · Mapa de significado

Vale em toda tela do app, não só no contador.

| Aparência | Valor no kit | Quer dizer |
|---|---|---|
| Vidro escuro com filete marfim | `--bt-grad-azulejo` + `--bt-sombra-azulejo` | Ação neutra, sem estado. |
| Cor cheia (vitral, brilho diagonal 115°) | classe `.bt-tile--lit` (kit.css:210) + `--bt-brilho-diagonal` | Algo está **valendo agora** (é noite, o plano está ligado, a coroa tem dono). |
| Latão cheio | `--bt-grad-latao` / `--bt-grad-latao-peca` | A jogada principal da tela **e** tudo que está **selecionado**. |
| Contorno tracejado em latão | `--bt-tracejado` sobre `--bt-grad-livre` | Vazio, **sem dono**. |
| Brasa como tinta | `--bt-brasa` `#FF8A80` no ícone e no rótulo | Encerra ou destrói; o aro da classe `.bt-tile--armado` (kit.css:244) pede o segundo toque. |
| Brasa cheia | `--bt-brasa-cheia` `#B5402B` em vitral | Destruir como herói da tela **ou** um estado ruim que está valendo. |

**Dois refinamentos que as provas novas acrescentaram** (registrados em `NOTAS-PARA-O-PROTOTIPO.md`, ainda não no README do protótipo):

1. **Brasa cheia também é "está pegando fogo".** `.rt.bad.on` (`mesa-brewtact.html:466-468`) pinta em brasa cheia uma peça-regra que diz um estado **ruim que está valendo**, sem ser botão de destruir. Continua sendo brasa porque continua sendo dano.
   - **Correção de fonte (conferida).** A única peça marcada `bad` no protótipo é **`Concedeu`** (`mesa-brewtact.html:1938`). **"Envenenado" não existe como peça de brasa cheia**: veneno é contador (`:866`) e motivo de derrota (`:1130`). A palavra veio da nota de `tokens.json` e foi promovida a regra do mapa por engano.
   - **E a prova citada não mostra o estado aceso.** Em `vt-05-jogador.png` a peça `Concedeu` está em `JOGANDO` — apagada. A regra CSS existe; o **estado aceso ainda não tem prova de aparelho**. Fonte correta a citar: o seletor `mesa-brewtact.html:466`, não a prova.
2. **Latão = selecionado, exceto numa fileira de cores.** Em `.swatches` o escolhido ganha aro de **marfim** (`0 0 0 4px #F3EFE3`), porque numa fileira de cores o latão seria só mais uma cor.

**Colisão conhecida dentro do mapa.** `--bt-brasa-cheia` `#B5402B` e `--bt-assento-brasa` `#A83A27` estão a **1,13** de contraste uma da outra — o mínimo para distinguir dois significados por cor é 3,0 (WCAG 1.4.11). Uma quer dizer "estado ruim valendo", a outra "este jogador é o vermelho", e elas são visualmente a mesma cor. Em `vt-05-jogador.png` o primeiro círculo da fileira é `#A83A27`; uma `.rt.bad.on` ao lado seria `#B5402B`. §10.3 registra que o kit trocou o hex do assento e deixou o do vitral — a colisão é consequência conhecida e continua **sem regra**. Vai para §11.

## 2 · As cinco regras

1. **Objeto, não campo.** Cada opção é uma peça tocável que mostra o próprio valor dentro dela — numeral gigante, miniatura real, ícone próprio. A escolha vale no toque. Sem linha de lista, rótulo com caixa, controle segmentado, interruptor ou botão "confirmar".
2. **Cor só carrega significado.** Cor cheia = valendo. Latão = principal/selecionado. As cores de jogador (`--bt-assento-*`) pertencem a pessoas, nunca a botões. Nada é colorido por decoração.
3. **Um único ✕ — e ele tem dois desenhos.** Uma tela secundária tem exatamente uma saída, nunca duas. **No board** (menu por cima da mesa) a saída é o hub virado ✕: **64×64**, obsidiana, `--bt-sombra-x`, ícone 24px `stroke 2.6`, no buraco de 80px do centro da linha do herói (`.hubwrap.open .rail .hub`, `.band .x`) — é o ✕ de `menu.png`. **No `AppTileOverlay`** (folha) a saída é o ✕ de cabeçalho: **44×44** redondo, ardósia-850, filete `inset 0 0 0 1px` ardósia-750, ícone 18px, no canto superior direito (`mesa-brewtact.html:562-565`) — é o ✕ que aparece nas quatro provas de folha (`vt-04`, `vt-05`, `vt-06`, `vt-07`). Se veio do menu, a seta `bt-back` (44×44, névoa) volta para o menu — ela não é uma segunda saída.
4. **Um herói por tela — herói é *ação*, não seleção.** Exatamente uma superfície de `--bt-grad-latao` (parada do meio em **40%**) por tela: `AppHeroTile`, `bt-result` ou `bt-action--principal`. Dois heróis = nenhum herói. **Latão de seleção não disputa essa vaga:** `.p.on`, `.v.on`, `.rt.on` usam `--bt-grad-latao-peca` (parada do meio em **42%**) e podem se repetir quantas vezes houver coisa selecionada. O README do protótipo diz a mesma coisa: "um herói claramente maior por tela" (`README.md:49`).
   - *Por que a redação antiga ("exatamente uma superfície de latão cheio por tela") estava errada:* `vt-04-regras.png` tem **quatro** superfícies de latão cheio ao mesmo tempo (duas peças-regra em `VALE`, a peça-numeral `10`, a peça-regra `Noite`) e `vt-05-jogador.png` tem **duas** (`Coroa / COM ELA` e a face `Vida`). A régua falsificava a própria regra, e §1 e §4.1c já diziam o contrário ("latão = a jogada principal **e** tudo que está selecionado").
5. **A superfície continua viva embaixo.** Toda tela secundária abre **sobre** a tela anterior, escurecida (`--bt-veu-folha`) e desfocada (`--bt-blur-folha`, `blur(8px) saturate(.8)`). Nunca uma rota opaca nova, nunca um `Dialog` com `barrierColor` chapado.

**O dono julga pelo olho em 1 segundo e rejeita como feia qualquer superfície estilo configurações.** Uma tela com título, subtítulo cinza, linhas com rótulo à esquerda e controle à direita já está reprovada antes de ser lida.

---

## 3 · Tokens: o que já existe em `AppTheme` e o que é novo

### 3.1 · Já existe — usar o token do `AppTheme`, não criar outro

| Token do kit | Valor | Token existente em `app_theme.dart` |
|---|---|---|
| `--bt-obsidiana-950` | `#0B0D12` | `AppTheme.backgroundAbyss` (:35) |
| `--bt-obsidiana-900` | `#151821` | `AppTheme.surfaceSlate` (:36) |
| `--bt-ardosia-850` | `#1D222C` | `AppTheme.surfaceElevated` (:37) |
| `--bt-ardosia-750` | `#293041` | `AppTheme.outlineMuted` (:59) |
| `--bt-marfim` | `#F3EFE3` | `AppTheme.textPrimary` (:54) |
| `--bt-nevoa` | `#B8C0CC` | `AppTheme.textSecondary` (:55) |
| `--bt-nevoa-fraca` | `#8A93A3` | `AppTheme.textHint` (:56) · também `AppTheme.disabled` |
| `--bt-latao-400` | `#E0A93B` | `AppTheme.brass400` (:41) · alias `mythicGold` |
| `--bt-latao-500` | `#C58B2A` | `AppTheme.brass500` (:40) · alias `manaViolet` |
| `--bt-latao-700` | `#8E641B` | `AppTheme.brass700` (:42) |
| `--bt-gelo-400` | `#6FA8DC` | `AppTheme.frost400` (:44) |
| `--bt-brasa` | `#FF8A80` | `AppTheme.error` (:155) |
| `--bt-ui` (Inter) | — | `AppTheme.uiFontFamily` (:27) |
| `--bt-display` (Fraunces) | — | `AppTheme.displayFontFamily` (:28) |
| `--bt-raio-azulejo` | 22px | `AppTheme.radiusLifeCounterXl` (:301) |
| `--bt-raio-regra` | 20px | `AppTheme.radiusXl` (:202) |
| `--bt-raio-painel` | 18px | `AppTheme.radiusLifeCounterLg` (:299) |
| `--bt-raio-dica` | 16px | `AppTheme.radiusLg` (:201) |
| `--bt-raio-mini` | 12px | `AppTheme.radiusMd` (:200) |
| `--bt-raio-mini-tile` | 10px | `AppTheme.radiusLifeCounterSm` (:297) |
| `--bt-raio-pilula` | 999px | `AppTheme.radiusPill` (:203) |
| `--bt-gap-mesa` / `-azulejo` / `-peca` / `-regra` | 6 / 8 / 10 / 10 px | `space6` / `space8` / `space10` |
| Paddings 9/11/12/13/14/16/18 px | — | `space9`…`space18` |

**12 das 13 cores do kit e as duas famílias tipográficas já estão no tema.** A ponte é real: o protótipo nasceu da mesma paleta.

### 3.2 · Novos — precisam entrar em `app_theme.dart`

| Novo token | Valor | Origem no protótipo |
|---|---|---|
| `bt.latao.claro` | `#F4CB6C` | 1ª parada de `.menu .hero { background }` (não nomeada lá) |
| `bt.latao.rotulo` | `#EBCB8B` | `.menu .t.livre .lb { color }` |
| `bt.brasaCheia` | `#B5402B` | `.menu .t.danger { --c }` |
| `bt.azulejoRepouso` | `#2A3142` | `.menu .t { --c }` |
| `bt.vitralNoite` / `-2` | `#2B3274` / `#12163F` | `#btnDayNight.is-night` |
| `bt.vitralDia` / `-2` | `#3E8FC9` / `#E0A24A` | `#btnDayNight.is-day` |
| `bt.vitralPlano` / `-2` | `#5B3A8C` / `#23163F` | `#btnPlane.lit` |
| `bt.vitralCoroa` / `-2` / `-ic` | `#9A6A1E` / `#4E2C10` / `#FFD98A` | `.tok-tile.lit[data-k="crown"]` |
| `bt.vitralIniciativa` / `-2` | `#2F6C8C` / `#12303F` | `.tok-tile.lit[data-k="init"]` |
| `bt.assento[10]` | `#A83A27` `#855614` `#356B45` `#1D6985` `#3B4699` `#7A3B86` `#4A5260` `#7A2340` `#8A4A20` `#245C58` | `var PALETTE` aplicado em `.panel { --bg }` |
| `bt.gradAzulejo` | `linear-gradient(160deg, rgba(41,48,65,.88), rgba(21,24,33,.95))` | `.menu .t { background }` |
| `bt.gradPeca` | `linear-gradient(160deg, rgba(41,48,65,.84), rgba(21,24,33,.94))` | `.p`, `.rt` |
| `bt.gradLatao` | `linear-gradient(158deg, #F4CB6C 0%, #E0A93B 40%, #C58B2A 100%)` | `.menu .hero` |
| `bt.gradLataoPeca` | idem, parada do meio em **42%** | `.p.on`, `.v.on`, `.rt.on` |
| `bt.gradLivre` | `linear-gradient(158deg, #2b2114, #1a1610)` | `.menu .t.livre` |
| *(duas sombras entram logo abaixo — `bt.sombraPeca` e `bt.sombraLivre` existem em `tokens.json` e faltavam nesta tabela)* | | |
| `bt.brilhoDiagonal` | `115deg rgba(255,255,255,.13) 0→34%` + `200deg rgba(0,0,0,.10) 72.2%→` | `.menu .t.lit::before` |
| `bt.sombraAzulejo` | `inset 0 0 0 1.5px rgba(243,239,227,.10), inset 0 1.5px 0 rgba(255,255,255,.10), 0 8px 18px rgba(0,0,0,.45)` | `.menu .t` |
| `bt.sombraPeca` | idem, mas o filete inset é **`.09`**, não `.10` | `.p`, `.rt` (`--bt-sombra-peca` em `tokens.json`) |
| `bt.sombraLivre` | `0 8px 18px rgba(0,0,0,.45)` — **sem filete inset** | `.menu .t.livre` (`--bt-sombra-livre` em `tokens.json`) |
| `bt.sombraLit` | 5 camadas, `.17` / `.30` / `-10px 22px` / `0 10px 22px` / aro obsidiana `.85` | `.menu .t.lit` |
| `bt.sombraLatao` | `inset 0 1.5px 0 rgba(255,255,255,.45), 0 10px 22px rgba(0,0,0,.5), 0 0 0 3px rgba(11,13,18,.85)` | `.menu .hero` |
| `bt.sombraSelecionado` | + `0 0 0 5px rgba(224,169,59,.55), 0 12px 30px rgba(224,169,59,.28)` | `.p.on` |
| `bt.sombraArmado` | `inset 0 0 0 2px #E0A93B, 0 0 0 3px #0B0D12, 0 0 0 5px rgba(224,169,59,.35)` | `.p.is-armed` |
| `bt.sombraX` | `inset 0 0 0 2px #E0A93B, 0 0 0 7px #0B0D12, 0 0 0 8.5px rgba(224,169,59,.28), 0 10px 26px rgba(0,0,0,.7)` | `.hubwrap.open .rail .hub` |
| `bt.tracejado` | `2px dashed rgba(224,169,59,.5)` | `.menu .t.livre::before` |
| `bt.filete` | `1px solid rgba(243,239,227,.10)` | `.sheet > .btns` |
| `bt.veuFolha` / `bt.veuMenu` | radiais `.80→.93` / `.42→.78` de obsidiana | `.sheet` / `.menu` |
| `bt.blurFolha` / `bt.blurMenu` | `8px` / `3px`, saturação `.8` | `backdrop-filter` |
| `bt.numeral*` | 56 / 70 / 32 / 38 / 44 / 36 / 40 / 30 / 92 / 64 px | ver §4.2 |
| `bt.colConteudo` / `bt.colMesa` | 560px / 780px | `.sheet-body` / `.mrow` |
| `bt.opacidadeDesabilitado` | `.38` | `.menu .t:disabled` |
| `bt.raioPad` | **14px** | `.pf-pad { border-radius }` · também `.bt-action` (kit.css:630) |

**Conflito a resolver na entrada:** `AppTheme.lifeCounterPlayerColors` (**:67-74**) é outra paleta (`#FFB51E`, `#FF0A5B`, `#CF7AEF`, `#4B57FF`, `#44E063`, `#40B9FF`) — 6 cores saturadas que **não** são os 10 assentos do protótipo. O kit substitui essa lista por `bt.assento[10]`. Ela está entre os tokens `lifeCounter*` sem uso em `lib` (ver §7.2 para a contagem medida).

**Três armadilhas desta tabela, conferidas hoje:**

1. **`bt.sombraPeca` não é `bt.sombraAzulejo`.** O filete inset da peça é `rgba(243,239,227,.09)`; o do azulejo é `.10`. Quem implementar reaproveitando o token do azulejo engrossa o filete de toda peça de escolha e de toda peça-regra.
2. **`bt.sombraLivre` não tem filete nenhum.** `.menu .t.livre` só carrega `0 8px 18px rgba(0,0,0,.45)` — o contorno dela é o **tracejado**, não um fio marfim. Reaproveitar `bt.sombraAzulejo` aqui desenha um filete que o protótipo não tem.
3. **O raio 14 não tinha token.** A escala de raio de `tokens.json` é 22/20/18/16/12/10/999, mas `.pf-pad` (`AppLiveBlock`) e `.bt-action` (rodapé) usam **14px**. Sem `bt.raioPad` o 14 entra em `bt_tokens.dart` como número solto ou desaparece — as duas saídas são ruins.

---

## 4 · As cinco primitivas

---

### 4.1 · `AppTile` — o azulejo

O objeto base do kit. Tudo que é escolha, estado ou entrada de tela é um azulejo.

#### (a) Anatomia

```
┌──────────────────────────────────────────┐ ← raio 22 · pad 12/14/11
│  ┌────┐                     ┌──────────┐ │
│  │ ic │ 34×34               │  estado  │ │ ← top 12 · right 13
│  └────┘                     └──────────┘ │    Fraunces 700 17px
│                                          │
│                  (espaço livre: o        │
│                   `justify-content:      │
│                   space-between` empurra │
│                   o rodapé para baixo)   │
│                                          │
│  ┌──────────┐          ┌──────────────┐  │
│  │ numeral? │ 56px     │   rótulo     │  │ ← Inter 800 11.5px
│  └──────────┘          │   SUBRÓTULO  │  │    tracking .085em
│                        └──────────────┘  │    CAIXA ALTA
└──────────────────────────────────────────┘
   ↑ 5 slots: icon · estado · numeral · label · sublabel
     Nenhum é obrigatório exceto `label`.
```

#### (b) Tokens

| Propriedade | Valor | Origem |
|---|---|---|
| Raio | 22px | `.menu .t { border-radius }` |
| Padding | `12px 14px 11px` | `.menu .t { padding }` — divergência arbitrada (vitral usa 13/14/12) |
| Fundo neutro | `linear-gradient(160deg, rgba(41,48,65,.88), rgba(21,24,33,.95))` | `.menu .t { background }` |
| Sombra neutra | `inset 0 0 0 1.5px rgba(243,239,227,.10), inset 0 1.5px 0 rgba(255,255,255,.10), 0 8px 18px rgba(0,0,0,.45)` | `.menu .t { box-shadow }` |
| Fundo aceso | `linear-gradient(158deg, mix(c,#fff,78%) 0%, c 42%, c2 100%)` | `.menu .t.lit` |
| Brilho do vitral | `linear-gradient(115deg, rgba(255,255,255,.13) 0 34%, transparent 34.2%)` + `linear-gradient(200deg, transparent 0 72%, rgba(0,0,0,.10) 72.2%)` | `.menu .t.lit::before` |
| Fundo latão | `linear-gradient(158deg, #F4CB6C 0%, #E0A93B 40%, #C58B2A 100%)` | `.menu .hero { background }` |
| Fundo livre | `linear-gradient(158deg, #2b2114, #1a1610)` + `2px dashed rgba(224,169,59,.5)` | `.menu .t.livre` |
| Ícone | 34×34, `stroke-width 1.9`, `drop-shadow(0 2px 3px rgba(0,0,0,.35))` | `.menu .t .ic` (:301) — **não** `.menu .t svg`, que também casaria `.menu .go svg` (27px, stroke 2.4) e `.menu .dicerow svg` (38px, stroke 1.6) |
| Rótulo | Inter 800 11.5px/1.18, tracking .085em, caixa alta, `text-shadow 0 1px 2px rgba(0,0,0,.35)` | `.menu .lb` |
| Subrótulo | Inter 700 11px/1, tracking .06em, caixa alta, `rgba(243,239,227,.72)` | `.menu .sub` |
| Estado (ligado) | Fraunces 700 17px/1, top 12 / right 13, máx. 62% da largura, elipse | `.menu .state` |
| Estado (desligado) | Inter 700 10.5px/1, tracking .1em, caixa alta, `#8A93A3`, top 15 | `.menu .state.off` |
| Numeral | Fraunces 700 56px/.8, **`lining-nums`**, tracking -.02em | `.menu .num` (:306). O `tabular-nums` é **DERIVADO** — ver §4.2e |
| Toque | `scale .97`, transição `.12s` | `.menu .t:active` |

#### (c) Estados

| Estado | Aparência | Origem |
|---|---|---|
| **normal** | vidro escuro + filete marfim `.10` | protótipo (`.menu .t`) |
| **ativo / "valendo"** | `--bt-c` em vitral 158°, brilho diagonal, `--bt-sombra-lit` | protótipo (`.menu .t.lit`) |
| **selecionado** | latão cheio + brilho diagonal + `--bt-sombra-latao`; tinta obsidiana | protótipo (`.menu .hero`) |
| **desabilitado** | `opacity .38`, sem `scale` no toque | protótipo (`.menu .t:disabled`) |
| **carregando** | vidro escuro + varredura `115deg` de latão, faixa ~24% de 210px, `1.35s linear infinite`; o valor vira um fio de latão 3px | **DERIVADO** — o ângulo e a cor são do vitral; a faixa é estreita de propósito: se engorda, lê como latão cheio e mente ("carregar não é valer") |
| **erro** | `linear-gradient(160deg, rgba(61,38,42,.88), rgba(26,20,24,.95))` + filete `rgba(255,138,128,.34)`; ícone, rótulo e estado em brasa | **DERIVADO** — é o `.quiet-danger` do protótipo virando estado |
| **vazio** | `--bt-grad-livre` + tracejado em latão + rótulo `#EBCB8B` | **DERIVADO** da peça `.livre` |
| **sem dono (livre)** | idem vazio, mas é o estado *de domínio* da peça, não de carregamento | protótipo (`.menu .t.livre`) |
| **perigo / armado** | 1º toque: `inset 0 0 0 2px #FF8A80, 0 8px 18px rgba(0,0,0,.45)`; o estado vira `DE NOVO`; 2º toque executa | protótipo (`.menu .t.is-armed`) |

**Regra do armado:** o azulejo armado **não** muda de cor de fundo. Só ganha o aro de brasa e troca a palavra do canto. **Desarma sozinho em 6 s** — `ARM_MS = 6000` em `mesa-brewtact.html:897`, testado em `:1853`, `:1876`, `:2296`, `:2334`, `:2356` e limpo pelos `setTimeout` de `:1882` e `:2361` — **ou quando outra peça arma** (o protótipo guarda um `armedFor` só: armar a segunda desarma a primeira). Não é derivado e não precisa de aval. *(A versão anterior desta spec dizia "3 s ou perda de foco"; o protótipo não faz nem uma coisa nem a outra.)*

**Onde o armamento mora.** `armed` é **estado com relógio**, e §4.1d declara `AppTile` como `StatelessWidget` recebendo `armed` de fora. Um `StatelessWidget` não tem `Timer` e não enxerga "tocar em qualquer outro lugar". Sem dono declarado, cada um dos ~35 pontos de confirmação do app reimplementa o desarme e nenhum faz igual. **Contrato:** um `BtArmedScope` (`InheritedWidget` + `StatefulWidget` interno) por tela, que guarda **uma** chave armada, dispara o `Timer` de 6 s e desarma ao armar outra peça. `AppTile` continua sem estado e lê o escopo. `onTap` dispara quando `armed == false` (e arma, se `onArmedConfirm != null`); `onArmedConfirm` dispara quando `armed == true`.

#### (d) API Flutter

```dart
enum AppTileTone { vidro, vitral, latao, livre, brasaTinta, brasaCheia }
enum AppTileStatus { normal, carregando, erro, vazio }

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.label,              // String — sempre caixa alta na pintura
    this.icon,                        // Widget?  slot 34×34
    this.sublabel,                    // String?
    this.estado,                      // Widget?  canto superior direito
    this.numeral,                     // Widget?  normalmente um AppNumeral
    this.tone = AppTileTone.vidro,
    this.vitralColor,                 // Color?   --bt-c   (exigido em tone.vitral)
    this.vitralColorDeep,             // Color?   --bt-c2  (default: mix(c, preto, 66%))
    this.status = AppTileStatus.normal,
    this.selected = false,            // latão cheio
    this.armed = false,               // aro de brasa, pede o 2º toque
    this.onTap,                       // VoidCallback?  null => desabilitado
    this.onArmedConfirm,              // VoidCallback?  só dispara com armed == true
    this.semanticsValue,              // String?  o que o leitor de tela diz do estado
    this.autofocus = false,
  });
}
```

**Precedência entre os quatro eixos.** `tone` (6) × `status` (4) × `selected` × `armed` dá 96 combinações e a maioria é ilegal. Sem ordem escrita, dez implementações divergem e a guarda de §9 não pega nenhuma. A ordem é:

```
carregando  >  erro  >  armado  >  selecionado  >  tone
```

- `status: carregando` **ignora** `tone`, `selected` e `armed` — a peça é vidro escuro com a varredura, e `onTap` é nulo.
- `status: erro` ignora `tone` e `selected`; mantém o rótulo e troca o canto de estado para `DE NOVO`.
- `armed: true` ignora `selected` (o aro de brasa vence o aro de latão) e mantém o fundo do `tone`.
- `selected: true` força latão-peça e ignora `tone`, **exceto** `tone: livre` (peça sem dono não pode estar selecionada: é `assert`).
- `tone: brasaCheia` + `status: erro` é **proibido** (`assert`): brasa cheia já quer dizer "estado ruim valendo"; empilhar erro em cima é redundante e ilegível.
- `status: vazio` e `tone: livre` pintam igual mas dizem coisas diferentes (§4.1c). `vazio` = não há dado; `livre` = há dado e ele é "sem dono". Quando os dois chegam juntos, manda `livre`.

```dart
AppTile(
  icon: const BtIcon(BtGlyph.moon),
  label: 'Dia / Noite',
  tone: AppTileTone.vitral,
  vitralColor: BtColors.vitralNoite,      // #2B3274
  vitralColorDeep: BtColors.vitralNoite2, // #12163F
  estado: const AppTileEstado('noite'),   // Fraunces 17px, canto
  semanticsValue: 'noite',
  onTap: () => context.read<MesaCubit>().alternarDiaNoite(),
)

AppTile(
  icon: const BtIcon(BtGlyph.flag),
  label: 'Encerrar partida',
  tone: AppTileTone.brasaTinta,
  armed: _armado,
  estado: _armado ? const AppTileEstado.off('de novo') : null,
  onTap: () => setState(() => _armado = true),
  onArmedConfirm: () => context.read<MesaCubit>().encerrar(),
)
```

#### (e) Uso e anti-padrões

- Um azulejo diz **uma** coisa. Se precisa de dois estados no canto, são dois azulejos.
- O estado mora **dentro** do azulejo (canto superior direito). Nunca vira um subtítulo cinza embaixo do rótulo.
- **Anti-padrão:** grade de N azulejos iguais. O protótipo sempre mistura tamanhos — `flex 1` e `flex 2`, linha alta e linha do herói. Doze peças do mesmo tamanho é a grade de configurações com outra pele.
- **Anti-padrão:** cor de vitral escolhida por gosto. `--bt-c` só existe quando o azulejo está *valendo*; se é só decoração, é vidro escuro.
- **Anti-padrão:** azulejo com texto corrido. O rótulo é uma linha de até ~18 caracteres em caixa alta. Frase longa é `bt-hint`.
- **Anti-padrão:** `AppTile` dentro de `ListView` vertical de 30 itens. O azulejo é peça de grade visível de uma vez; lista longa é outro problema (ver §10, limites conhecidos).

#### (f) Acessibilidade

Contrastes conferidos com `python3` (fórmula WCAG 2.x, luminância relativa).

**Correção de método.** A versão anterior media o gradiente aceso **na parada do meio (42%)**, alegando que é ali que o rótulo cai. Não é. Projetando cada slot sobre o eixo do gradiente de 158° (o rótulo no canto inferior esquerdo, o estado no canto superior direito, o ícone no canto superior esquerdo), num azulejo de 112–128 de altura e 70–200 de largura:

| Slot | Onde cai na rampa (t) | Entre que paradas |
|---|---|---|
| Ícone (topo esquerdo) | **0,17 – 0,25** | topo clareado → 42% · **e é o único slot debaixo do brilho 115°** |
| Estado (topo direito) | **0,25 – 0,41** | topo clareado → 42% · **fora do brilho** |
| Rótulo / subrótulo (rodapé esquerdo) | **0,59 – 0,78** | 42% → `--bt-c2` |

*(O brilho `115deg rgba(255,255,255,.13) 0→34%` corre da esquerda para a direita, não de cima para baixo: ele clareia o canto do **ícone**. O estado, que fica na direita, cai em t 0,42–0,66 daquele eixo e **não** recebe o brilho.)*

Nenhum slot cai na parada do meio. **A tinta tem de ser decidida por slot, não por cor**, porque um gradiente claro→escuro com texto nas duas pontas não tem tinta única.

**Os números por slot** (pior ponto da faixa de cada slot; os `c2` declarados foram usados onde existem):

| Vitral | Ícone · marfim (≥3,0) | Estado 17px/700 · marfim (≥4,5) | Rótulo 11,5px/800 · marfim (≥4,5) | Obsidiana no mesmo lugar |
|---|---:|---:|---:|---|
| noite `#2B3274` / `#12163F` | 5,43 ✔ | **7,65** ✔ | **12,03** ✔ | ícone 3,11 · estado 1,83 · rótulo 1,28 |
| plano `#5B3A8C` / `#23163F` | 4,36 ✔ | **5,87** ✔ | **9,98** ✔ | 3,88 · 2,44 · 1,46 |
| iniciativa `#2F6C8C` / `#12303F` | 3,24 ✔ | **4,10 ✘** | **7,11** ✔ | 5,22 · 3,61 ✘ · 1,95 |
| brasa-cheia `#B5402B` | 3,35 ✔ | **4,14 ✘** | **6,08** ✔ | 5,05 · 3,65 ✘ · 2,45 |
| coroa `#9A6A1E` / `#4E2C10` | **2,81 ✘** | **3,44 ✘** | **5,97** ✔ | 6,02 · 4,37 ✘ · 2,27 |
| dia `#3E8FC9` / `#E0A24A` | **2,29 ✘** | **2,68 ✘** | **2,43 ✘** | **7,39 ✔ · 5,78 ✔ · 6,23 ✔** |
| 10 assentos (`--bt-assento-*`) | 3,3 a 4,8 ✔ | — | 5,1 a 8,0 ✔ | **2,1 a 3,4 — reprova em todos** |

**A regra `inkFor(c)` da versão anterior está errada e não pode entrar como estava.** Ela dizia: obsidiana quando `contraste(obsidiana, mix(c,#fff,78%)) > contraste(marfim, mesmo topo)`, e prometia que isso "muda o desenho de `dia` e `coroa`". Aplicada honestamente sobre os 16 vitrais do kit, ela escolhe **obsidiana em 13 deles** — `dia`, `coroa`, `iniciativa`, `brasa-cheia` e **9 dos 10 assentos** (só `noite`, `plano` e `vinho` ficam em marfim). Isso repinta em tinta escura o card do jogador (`AppScoreRow`, `.dx-p`), o bloco vivo (`AppLiveBlock`, `.pf-life`) e a peça-regra ruim (`.rt.bad.on`) — contra o protótipo (`.rt.bad.on b { color: var(--ivory) }`, `.dx-p` e `.pf-life` herdam marfim) e contra `vt-05` (o `27` branco sobre âmbar) e `vt-07` (nomes e valores brancos). No fim do gradiente do assento a obsidiana cai para **1,82–1,88**: o nome e a vida do jogador somem. A regra não mudava 2 superfícies — mudava 11. **Está revogada.**

**A regra que entra no lugar** (medida, não estimada):

> **`inkFor` só existe para `dia`.** A tinta do azulejo aceso é **marfim** em todo vitral e em todo assento. A única exceção é `--bt-vitral-dia`, cujo gradiente vai de azul claro (`#3E8FC9`) para âmbar claro (`#E0A24A`) e é claro nas duas pontas: nele a tinta é **obsidiana** nos três slots. Nenhuma cor de assento e nenhuma peça em brasa cheia jamais troca de tinta.

> **O estado vira texto grande.** A palavra do canto sobe de **17px para 19px** Fraunces 700. Acima de 18,66px em negrito o mínimo WCAG é 3,0, não 4,5 — e aí `coroa` (3,44), `iniciativa` (4,10) e `brasa-cheia` (4,14) passam em marfim sem trocar cor nenhuma. É a menor mudança que fecha o buraco. **DERIVADO** (o protótipo tem 17px) e vai para §11.

O que sobra sem resposta — o ícone em marfim sobre `coroa` (2,81) e o próprio `dia` — está registrado em §11.

**Os pares que não dependem do vitral:**

| Par | Razão | AA 4.5 | AAA 7 |
|---|---:|:---:|:---:|
| marfim `#F3EFE3` sobre vidro do azulejo (pior ponto, `#252C3B`) | **12,16** | ✔ | ✔ |
| marfim sobre vidro do azulejo (base, `#141720`) | **15,57** | ✔ | ✔ |
| subrótulo `rgba(243,239,227,.72)` sobre vidro | **7,04** | ✔ | ✔ |
| névoa `#B8C0CC` sobre obsidiana `#0B0D12` | **10,60** | ✔ | ✔ |
| névoa-fraca `#8A93A3` sobre vidro do azulejo (estado desligado) | **4,52** | ✔ | ✘ |
| obsidiana sobre latão-400 `#E0A93B` (meio do gradiente) | **9,17** | ✔ | ✔ |
| obsidiana sobre latão-claro `#F4CB6C` (topo) | **12,59** | ✔ | ✔ |
| obsidiana sobre latão-500 `#C58B2A` (fim) | **6,57** | ✔ | ✘ |
| latão-rótulo `#EBCB8B` sobre vidro livre `#2B2114` | **10,11** | ✔ | ✔ |
| brasa `#FF8A80` sobre vidro do azulejo | **6,12** | ✔ | ✘ |
| brasa sobre fundo de erro `#372327` | **6,42** | ✔ | ✘ |
| **desabilitado** (tudo a `.38` sobre obsidiana): marfim `#636361` sobre `#151922` | **2,92** | ✘ | ✘ |
| **desabilitado**: névoa `#4D5159` sobre `#151922` | **2,21** | ✘ | ✘ |
| **desabilitado**: obsidiana sobre latão a `.38` | **2,23** | ✘ | ✘ |

*(O `15,57` é a razão do hex arredondado `#141720` que a tabela cita; sem arredondar a parada composta, 15,51. A diferença não muda veredito nenhum.)*

**Sobre o desabilitado:** 2,2–2,9 fica abaixo de AA. A WCAG 2.2 isenta controle desabilitado (1.4.3, exceção "Inactive"), mas a isenção só vale se o leitor de tela souber. Por isso `onTap == null` **tem** de emitir `Semantics(enabled: false, button: true)`; nunca apagar visualmente sem marcar.

**O azulejo é semitransparente — e a mesa viva embaixo é colorida.** Todos os números acima assumem obsidiana atrás. O vidro é `rgba(41,48,65,.88)` → `rgba(21,24,33,.95)`: 5–12% do que está atrás atravessa, e no board o véu é só `.42`→`.78` (§4.3b), bem mais fino que o da folha. Recompus o pior caso — um card de jogador claro (`#E0A24A`) ou o herói de latão atrás, no centro do véu `.42`: o topo do vidro sai de `#252C3B` para `#34363F`; marfim cai de 12,16 para **10,44** (folgado) mas a **névoa-fraca do estado desligado cai de 4,52 para 3,73–4,24 — abaixo de AA** para um rótulo de 10,5px. É exatamente a cena de `menu.png`. **Regra:** dentro de um `AppTileBoard` com `veil: true`, o estado desligado usa `--bt-nevoa` (`#B8C0CC`), não `--bt-nevoa-fraca`. **DERIVADO.**

**Semântica por papel — um molde só não serve.** `Semantics(button:, label:, value:, selected:, enabled:)` é o molde do azulejo genérico. §8 manda converter widgets que têm papéis próprios, e perder o papel não é detalhe de leitura:

| O que o azulejo está substituindo | Semântica obrigatória |
|---|---|
| `Switch` / `SwitchListTile` (13) → `AppRuleTile` | `Semantics(toggled: <on>, …)` — sem isso o leitor não anuncia ligado/desligado |
| `Checkbox` / `CheckboxListTile` (4) → `AppRuleTile` | `Semantics(checked: <on>, …)`. Uma delas é o consentimento de `register_screen.dart:519`: perder o papel de caixa de seleção é problema legal, não de leitura |
| `Radio` → `AppChoiceTile` | `Semantics(inMutuallyExclusiveGroup: true, checked: <sel>, …)` |
| `TabBar` (10) → fileira de `AppTile` | `Semantics(selected: <atual>, value: '<n> de <total>')` — o Flutter não tem papel de aba, a posição precisa ser dita |
| Ação normal | `Semantics(button: true, …)`, como acima |

Toda peça derivada de §5 herda o papel do widget que ela substitui, não o papel de `AppTile`.

**Alvo de toque.** O azulejo mede no mínimo 112 de altura útil (`flex 112`, `max-height 128`) — folgado. O `bt-x--head` (44×44) e o `bt-back` (44×44) atendem iOS mas ficam **4dp abaixo** do mínimo Android de 48dp. **Correção da receita:** crescer o alvo com `Padding` transparente + `ConstrainedBox(minWidth: 48, minHeight: 48)`, **sem** mudar o desenho. `MaterialTapTargetSize.padded` **não serve aqui** — ele só existe em `ButtonStyle.tapTargetSize` e `ThemeData.materialTapTargetSize` e não tem efeito nenhum sobre um `GestureDetector`/`InkWell` solto.

**`InkWell` ou `GestureDetector`?** `GestureDetector` (ou `Listener`) + `AnimatedScale`, por padrão. A régua não tem *ripple* em lugar nenhum e cada peça pinta o próprio gradiente e a própria sombra; o splash do `InkWell` desenha no `Material` ancestral e ou some debaixo do gradiente ou aparece fora da linguagem. Se algum caso exigir `InkWell` (por `onLongPress` + feedback de plataforma), ele entra com `splashFactory: NoSplash.splashFactory` e `highlightColor: Colors.transparent`.

**Foco por teclado (web):** o kit pinta `outline: 2px solid #E0A93B; outline-offset: 2px`. Em Flutter: `FocusableActionDetector` + um `CustomPaint` de aro 2px em `brass400` a 2px do raio 22. Contraste do aro sobre o vidro: **6,60** (mínimo não-texto é 3,0 ✔).

**Rótulo e estado sob escala de fonte.** O rótulo é caixa alta com tracking `.085em` — o pior caso de largura que existe. Ele é `maxLines: 2, overflow: TextOverflow.ellipsis`, e a segunda linha só aparece quando precisa. O **estado** é o problema real: `.menu .state` limita a palavra a `max-width: 62%` com elipse, e a 200% de escala, num azulejo `flex 1` de uma linha de cinco dentro de 780px (~140px), 62% dá ~87px para uma palavra Fraunces de 34px — `noite` vira `no…`. **A única coisa que diz em palavra que algo está valendo desaparece justamente para quem aumentou a fonte.** Regra: acima de ~160% de escala o azulejo troca o estado do canto por uma segunda linha do rótulo (`DIA / NOITE · NOITE`), em vez de elipsar. **DERIVADO**, vai para §11.

**Acessibilidade de plataforma além de movimento:**

- **`MediaQuery.disableAnimationsOf(context)`** (o nome correto; `MediaQuery.disableAnimations` não existe como acessor estático) desliga a varredura de carregando — a peça fica em vidro escuro com o fio de latão parado — e o `scale .97` do toque. O kit já faz isso em CSS via `prefers-reduced-motion`.
- **`MediaQuery.highContrastOf(context)`** (o "Aumentar contraste" do iOS) é exatamente o interruptor que engrossa os filetes de `.10` para `.22` e **abolir a tinta marginal sobre vitral**: com ele ligado, todo azulejo aceso ganha um scrim local `rgba(11,13,18,.28)` atrás do estado e do rótulo. Não estava na spec.
- **`MediaQuery.boldTextOf(context)`**: o kit já vive em Inter 800. Decisão: é **no-op** (não há 900 útil em caixa alta de 11,5px), e o eixo `wght` fica onde está.
- **`MediaQuery.invertColorsOf(context)`**: o *Smart Invert* do iOS destrói uma linguagem de gradiente escuro. O kit **não** tenta compensar; os ícones e miniaturas entram em `ExcludeSemantics`-equivalente visual (`Image` com `matchTextDirection` falso e sem inversão) só onde o Flutter permite. Limite conhecido, vai para §10.1.
- **Transparência reduzida:** o Flutter **não** expõe `prefers-reduced-transparency` em `MediaQueryData`, e o kit inteiro é blur + rgba + véu. Ou se assume o custo, ou se abre um canal de plataforma. Vai para §11.
- **Escala de fonte até 200%:** rótulo e subrótulo escalam normalmente e o azulejo cresce (`flex`, `max-height` vira `minHeight`). O **numeral não escala com o sistema** — ele é objeto, não texto: fica em `FittedBox(fit: BoxFit.scaleDown)` com piso (§4.2).
- **`Directionality` / RTL:** nada no kit está declarado como direcional e tudo é direcional — gradientes a 158°/160°, ícone no alto à **esquerda**, rótulo embaixo à **esquerda**, estado à **direita**, seta `‹`, `padding: 12px 10px 6px 18px` assimétrico. Regra mínima: todo padding do kit é `EdgeInsetsDirectional`, o ângulo do gradiente espelha para 202°/200° em RTL e a seta de volta espelha. **Não medido, não provado** — vai para §10.1.

#### (g) Responsivo

| Largura | Comportamento |
|---|---|
| **390** (compact) | Azulejo ocupa `flex 1` ou `flex 2` dentro da linha; 2 a 5 por linha. Rótulo em 2 linhas quando preciso. |
| **834** (tablet) | Mesmo layout; a linha atinge `--bt-col-mesa` 780px e para de crescer. O azulejo fica mais alto (`flex 112/120`), não mais largo. |
| **1440** (desktop) | Linha travada em 780px, centrada. O azulejo **não** vira retângulo largo. Sobra de tela = a mesa viva aparecendo nas laterais (ver `specimen-1440.png`, seção 1). |
| **1920** (wide) | Idem 1440. Nada de uma 6ª coluna. |
| **Hover (web)** | `scale 1.012` + `--bt-sombra-lit` no lugar de `--bt-sombra-azulejo`. **DERIVADO** — o protótipo é só toque. |
| **Cursor** | `SystemMouseCursors.click` quando `onTap != null`; `basic` quando desabilitado. |

---

### 4.2 · `AppNumeral` — o numeral serifado

#### (a) Anatomia

```
        ┌───────────────────────────┐
        │                           │  Fraunces 700
        │   ██  ██████              │  lining-nums tabular-nums
        │  ███ ██    ██             │  font-optical-sizing: auto
        │   ██ ██    ██             │  letter-spacing -.02em
        │   ██ ██    ██             │  line-height .72–.8
        │   ██  ██████              │  text-shadow 0 3px 8px rgba(0,0,0,.35)
        │                           │
        └───────────────────────────┘
          ↑ um único slot: o valor. Sem rótulo, sem unidade, sem sufixo.
            O que o numeral significa é dito pelo objeto que o contém.
```

#### (b) Tokens

| Escala | Valor | Origem |
|---|---|---|
| `azulejo` | 700 **56px**/.8 | `.menu .num` |
| `heroi` | 700 **70px**/.8, `text-shadow 0 1px 0 rgba(255,255,255,.35)` | `.menu .hero .num` — divergência arbitrada (vitral usa 78) |
| `canto` | 700 **32px**/1, cor névoa, sem sombra | `.menu .num.small` |
| `peca` | 700 **38px**/.85 → **44px** quando selecionada | `.p .num` / `.p.on .num` |
| `pecaNumeral` | 700 **36px**/1 → **40px** selecionada → **30px** na variante "outro" | `.v .num` |
| `resultado` | 700 **92px**/.85, tracking -.03em → **46px**/1 na variante longa | `.dx-hero output` |
| `vivo` | 700 **64px**/.9, `lining+tabular`, `text-shadow 0 3px 8px rgba(0,0,0,.3)` | `.pf-row output` |
| `mesa` | 600, `line-height .72`, tracking -.03em, `min((100cqh − 2×38px) × 1.38, 38cqw)`; três dígitos: `26cqw` | `.life` — **medido pelo card do jogador, não pela tela** |
| `vazio` | 700 **44px**/.8, `rgba(224,169,59,.55)` | **DERIVADO** (`.bt-empty__num`) |

**Eixo óptico em `auto`.** `mesa-brewtact.html` não fixa `opsz`, então o numeral engorda junto com o tamanho. O mock `vitral/menu.html` fixa `"opsz" 144` e produz um desenho de hairline fina — é o que se vê em `jogadores.png`. Como a arbitragem manda `mesa-brewtact.html`, o kit fica em `auto`. Em Flutter: `FontVariation('opsz', <tamanho em px>)` — não uma constante.

**O eixo que faltava: `wght`. Hoje o app não consegue entregar nem Inter 800 nem Fraunces 700.** Conferido no `fvar` dos dois arquivos e no `pubspec.yaml`:

| Fonte | Eixos | Default da instância |
|---|---|---|
| `assets/lotus/fonts/Inter.ttf` | `opsz` 14–32 · `wght` 100–900 | **`wght` 400**, `opsz` 14 |
| `assets/lotus/fonts/Fraunces.ttf` | `opsz` 9–144 · `wght` 100–900 · `SOFT` 0–100 · `WONK` 0–1 | **`wght` 900**, `opsz` 9, `SOFT` 0, **`WONK` 1** |

`app/pubspec.yaml:118-126` registra cada família com **um único asset e nenhum descritor `weight:`**. Com uma face só e sem descritor, o Flutter usa a instância *default* da variável: **todo Fraunces sai em 900 no `opsz` 9 e todo Inter em 400**. `fontWeight:` sozinho **não move** o eixo `wght` de uma fonte variável. Consequências para o kit:

- Todo estilo do kit precisa de `fontVariations: [FontVariation('wght', <peso>), FontVariation('opsz', <tamanho>)]`, não só `fontWeight`.
- `opsz` precisa de **clamp**: Fraunces aceita [9, 144] e Inter para em **32**. O numeral `mesa` num card de tablet e os tokens antigos de 184/246px estouram o eixo do Fraunces; qualquer Inter acima de 32px estoura o do Inter.
- `lining-nums` / `tabular-nums` do CSS viram `FontFeature.liningFigures()` e `FontFeature.tabularFigures()` em `TextStyle.fontFeatures`.
- **`WONK` tem de ser fixado explicitamente.** O default é 1, e é o que desenha o `4` e o `5` de `menu.png` e `vt-06`. Se o eixo não for fixado, uma troca de asset muda o glifo e o numeral deixa de bater com a régua. O kit fixa `WONK 1` e `SOFT 0`.

Isso é trabalho de Onda 0 e **não estava em lugar nenhum desta spec**.

#### (c) Estados

| Estado | Aparência | Origem |
|---|---|---|
| **normal** | marfim sobre vidro; névoa na escala `canto` e `peca` | protótipo |
| **ativo / valendo** | herda a tinta do objeto aceso (marfim ou obsidiana, §4.1f) | protótipo |
| **selecionado** | tinta obsidiana + **um degrau de tamanho** (38→44, 36→40) | protótipo (`.p.on .num`, `.v.on .num`) |
| **desabilitado** | `opacity .38` no objeto inteiro; o numeral não muda de cor | protótipo |
| **carregando** | o numeral **não existe**: no lugar dele, `bt-carga--num` — fio de latão 3px × 64px, raio 999 | **DERIVADO** |
| **erro** | numeral em brasa `#FF8A80` | **DERIVADO** |
| **vazio** | `0` em `rgba(224,169,59,.55)`, 44px | **DERIVADO** |
| **sem dono** | mesmo que vazio, dentro de peça tracejada | protótipo (`.livre`) |
| **armado** | numeral em latão-400 sobre vidro (`.bt-piece--armado .bt-piece__num`) | protótipo |

#### (d) API Flutter

```dart
enum AppNumeralScale { azulejo, heroi, canto, peca, pecaNumeral, resultado, vivo, mesa, vazio }

class AppNumeral extends StatelessWidget {
  const AppNumeral(
    this.value, {                      // String — já formatado; o widget não formata
    super.key,
    this.scale = AppNumeralScale.azulejo,
    this.color,                        // Color?  default: a tinta do ancestral
    this.minFontSize,                  // double? piso REAL, medido com TextPainter
    this.semanticsLabel,               // String? "27 de vida", não "27"
    this.live = false,                 // liveRegion — ver a regra abaixo: um por tela
  });

  final String value;
  final AppNumeralScale scale;
  final Color? color;
  final double? minFontSize;
  final String? semanticsLabel;
  final bool live;
}

/// Mede pelo contêiner, não pela tela. Equivale a `.life` do protótipo.
/// É uma CLASSE PRÓPRIA, não um construtor nomeado de AppNumeral: os dois
/// widgets têm contratos diferentes (um recebe escala, o outro mede o pai).
class AppNumeralMesa extends StatelessWidget {
  const AppNumeralMesa(
    this.value, {
    super.key,
    this.reservaVertical = 38,         // o que fica acima/abaixo dentro do card
    this.fatorAltura = 1.38,
    this.fatorLargura = 0.38,          // 0.26 quando value.length >= 3
    this.minFontSize = 28,
    this.semanticsLabel,
  });

  final String value;
  final double reservaVertical;
  final double fatorAltura;
  final double fatorLargura;
  final double minFontSize;
  final String? semanticsLabel;
}
```

```dart
// Numeral que enche o card do jogador, como `.life` no protótipo.
LayoutBuilder(
  builder: (context, c) {
    assert(c.hasBoundedHeight,
        'AppNumeralMesa precisa de altura limitada: dentro de um Flex ela '
        'pode vir infinita e a conta estoura.');
    final alvoAltura  = (c.maxHeight - 2 * 38) * 1.38;
    final alvoLargura = c.maxWidth * (vida.length >= 3 ? 0.26 : 0.38);
    return AppNumeralMesa(
      vida,
      // O TAMANHO É A CONTA — não uma escala fixa com FittedBox por cima.
      // fontSize: math.min(alvoAltura, alvoLargura), aplicado com
      // FontVariation('opsz', <esse mesmo valor>), e nunca abaixo de minFontSize.
      minFontSize: 28,
      semanticsLabel: '$vida pontos de vida de ${jogador.nome}',
    );
  },
)
```

**Três correções ao exemplo anterior, que não funcionava:**

1. **Ele calculava `alvoAltura` e `alvoLargura` e jogava as duas fora** — passava ao `AppNumeral` só `scale`, `minFontSize`, `semanticsLabel` e `live`. O numeral saía no tamanho fixo da escala e o `FittedBox` só evitava o estouro; a regra `min((100cqh − 2×38px) × 1.38, 38cqw)` do protótipo **não era reproduzida**. O tamanho tem de virar `fontSize`.
2. **`FittedBox` não tem piso.** Ele escala por transformação e não para em `minFontSize` — esse parâmetro é do widget, e para respeitá-lo é preciso medir com `TextPainter` (ou aceitar um pacote novo, que esta spec não declara). Pior: escalar por transformação **contradiz §4.2b** — um glifo de 92px reduzido a 0,5 não é o mesmo desenho que um glifo de 46px com `opsz` 46, e §10.3 diz que é exatamente essa diferença de peso "o que mais muda o olho". O `FittedBox` fica como rede de segurança de último recurso, não como o mecanismo.
3. **`const AppNumeral.mesa(...)` como estava não compila:** inicializava três campos que não existiam no corpo da classe, o construtor principal não os inicializava, e `...` não é sintaxe Dart em lista de parâmetros. Virou classe própria.

**`live: true` saiu do exemplo de propósito.** Numa mesa de Commander há de 2 a 10 cards vivos e o valor muda a cada toque na borda. Dez `liveRegion` simultâneos fazem o VoiceOver/TalkBack anunciar e se interromper a cada dedo. **Regra:** o valor vai em `Semantics(value:)` do **card** (que o leitor relê ao focar); quando a mudança precisa ser falada, sai por `SemanticsService.announce` com *debounce* — **nunca** `liveRegion` em N numerais ao mesmo tempo. `live` fica reservado para o numeral único de uma tela (o `resultado` de `vt-06`, por exemplo).

#### (e) Uso e anti-padrões

- O numeral é **o objeto**, não o rótulo de um dado. Se ele precisa de "Vida:" na frente, o desenho está errado: quem diz é a peça.
- Sempre `tabular-nums` — **DERIVADO, e é uma boa regra que não é do protótipo.** No protótipo `font-variant-numeric: lining-nums tabular-nums` existe só em `.life`, `.pf-row output` e `.log li`; `.menu .num` (:306), `.p .num` (:372), `.v .num` (:391), `.dx-hero output` (:418) e `.dx-p .num` (:437) são **só `lining-nums`**. O kit estende `tabular-nums` a todos porque 19→20 não pode fazer a peça pular de largura, mas a extensão vai marcada.
- **Anti-padrão:** numeral com sufixo (`40 pts`, `R$ 12`). Unidade vai no rótulo em caixa alta, 11px.
- **Anti-padrão:** numeral medido pela tela. Na mesa ele é medido pelo **card**; num azulejo, pelo azulejo. `MediaQuery.size` aqui é bug.
- **Anti-padrão:** usar `AppNumeral` para texto que não é número. Nome de jogador é `Fraunces 700 30px` (`bt-hero__quem`), outra coisa.

#### (f) Acessibilidade

| Par | Razão | Veredito |
|---|---:|---|
| marfim sobre vidro do azulejo | 12,16 | ✔ AAA |
| névoa sobre vidro do azulejo (escala `canto`/`peca`) | **7,62** | ✔ AAA |
| obsidiana sobre latão-400 (selecionado) | 9,17 | ✔ AAA |
| numeral vazio `rgba(224,169,59,.55)` sobre `#2B2114` | **3,27** | ✔ AA-large (44px/700 é texto grande; mínimo 3,0) |
| marfim sobre assento (onde o numeral realmente cai, §4.1f) | 5,78 a 9,11 | ✔ AA |
| marfim sobre brasa-cheia, zona do **numeral** (meio) | **4,89** | ✔ para numeral ≥ 24px (mínimo 3,0) |
| marfim sobre brasa-cheia, zona do **título 14px/700** | **3,27** topo · **2,70** com o brilho · **4,89** no meio | ✘ — ver o veredito unificado abaixo |

**Veredito unificado do título 14px/700 sobre brasa cheia** (a versão anterior desta spec dava dois vereditos opostos para o mesmo pixel: §4.1f aprovava com 4,89, §4.2f reprovava com 3,27). Os dois números estão certos e são de **pontos diferentes da mesma peça**. O `.rt` empilha `grid-template-rows: auto 1fr auto` — ícone em cima, título no meio, palavra de estado embaixo — numa caixa de 96px. Projetando na rampa: o ícone e o topo da caixa de texto caem na zona clareada (**3,27**, e **2,70** com o brilho diagonal por cima), o corpo do título cai perto do meio (**4,89**). Como 14px em negrito **não é texto grande** (o limiar é 18,66px), o mínimo é 4,5 e a faixa superior reprova. A palavra de estado da mesma peça (`rgba(243,239,227,.8)`) tem o mesmo problema: **2,64** no topo, **2,25** com o brilho. **Veredito único: reprova**, e a correção (subir a tinta do estado para opacidade 1 e baixar o título para a faixa do meio, ou escurecer a parada de topo da brasa cheia de 78% para 66% de branco) vai para §11. Esta é a peça `Concedeu` que §1 promoveu a refinamento novo do mapa: ela merece número próprio, não herdar o do vitral.

- **Escala de fonte até 200%:** o numeral **não** multiplica pelo `textScaler` — `TextStyle(fontSize: n)` dentro de `MediaQuery(textScaler: TextScaler.noScaling)`. O tamanho já é o maior elemento da tela; dobrá-lo estoura o card. O que escala é tudo em volta (rótulo, estado, subrótulo), e a sobra é absorvida pela conta de tamanho de §4.2d (o `FittedBox` é rede de segurança, não o mecanismo — ele não tem piso).
- **Piso:** `minFontSize` por escala — 28 (`mesa`), 24 (`heroi`/`resultado`), 20 (`azulejo`), 16 (`peca`/`pecaNumeral`/`canto`). Abaixo do piso o numeral **para de encolher** e o contêiner é que precisa crescer. Nunca elipse, nunca quebra de linha, nunca estouro.
- **Semantics:** o numeral sozinho lê "27", o que não diz nada. `semanticsLabel` obrigatório em toda escala ≥ `heroi`. Mudança de valor sem navegação: o valor vai em `Semantics(value:)` da **peça** e, quando precisa ser falado, sai por `SemanticsService.announce` com *debounce*. `liveRegion: true` só quando há **um** numeral vivo na tela (ver §4.2d — dez `liveRegion` simultâneos numa mesa de Commander inundam o leitor).
- **`MediaQuery.disableAnimationsOf(context)`:** a transição de tamanho selecionado (38→44) vira corte seco.
- **Foco:** o numeral nunca é focável sozinho — quem recebe foco é a peça.

#### (g) Responsivo

| Largura | Comportamento |
|---|---|
| **390** | `mesa` resolve em ~38% da largura do card. Três dígitos caem para 26%. |
| **834 / 1440 / 1920** | O card do jogador cresce, o numeral cresce junto (é `cqw`/`cqh`, não `vw`). Em Flutter: `LayoutBuilder` do card, nunca `MediaQuery`. |
| **Desktop** | `resultado` (92px) e `heroi` (70px) são fixos: a coluna de conteúdo trava em 560px, então não há espaço extra para gastar. |
| **Hover / cursor** | Nenhum. O numeral não é alvo; o objeto é. |

---

### 4.3 · `AppTileBoard` — a grade por linhas

#### (a) Anatomia

```
┌─ AppTileBoard ── width: min(100%, 780) ── gap 8 ─────────────────┐
│                                                                   │
│  ┌─ row(alta) ── flex 112 · maxHeight 128 ────────────────────┐   │
│  │ ┌──f1──┐ ┌────f2────┐ ┌──f1──┐ ┌──f1──┐ ┌──f1──┐           │   │
│  │ │ tile │ │   tile   │ │ tile │ │ tile │ │ tile │           │   │
│  │ └──────┘ └──────────┘ └──────┘ └──────┘ └──────┘           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─ row(heroi) ── flex 120 · maxHeight 136 ───────────────────┐   │
│  │ ┌──── 1fr ────┐   ┌ 80px ┐   ┌──── 1fr ────┐               │   │
│  │ │  AppHeroTile│   │  ✕   │   │ tile  tile  │               │   │
│  │ └─────────────┘   └──────┘   └─────────────┘               │   │
│  │                      ↑ o buraco onde o hub/✕ mora           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─ row(alta) ─────────────────────────────────────────────────┐   │
│  │ ┌────f2────┐ ┌──f1──┐ ┌──f1──┐ ┌──f1──┐ ┌──f1──┐           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────┘
   Tudo visível de uma vez. Nada rola. Nada é igual ao vizinho.
```

#### (b) Tokens

| Propriedade | Valor | Origem |
|---|---|---|
| Largura máxima | `min(100%, 780px)` | `.mrow { width }` |
| Gap entre azulejos e entre linhas | 8px | `.menu { gap }`, `.mrow { gap }` |
| Linha alta | `flex: 112 1 0`, `max-height: 128px` | `.mrow.r1`, `.mrow.r3` |
| Linha do herói | `flex: 120 1 0`, `max-height: 136px`, colunas `1fr 80px 1fr` | `.mrow.r2` |
| Peso f1 / f2 | `flex: 1 1 0` / `flex: 2 1 0` | `.f1`, `.f2` |
| Véu por cima da mesa | `radial-gradient(ellipse at 50% 50%, rgba(11,13,18,.42), rgba(11,13,18,.78))` | `.menu { background }` |
| Desfoque | `blur(3px) saturate(.8)` | `.menu { backdrop-filter }` |
| Entrada | `fade .16s ease` (só opacidade) | `@keyframes fade` |

#### (c) Estados

| Estado | Aparência | Origem |
|---|---|---|
| **normal** | linhas montadas, véu fino sobre a mesa viva | protótipo (`.menu`) |
| **ativo** | é o board inteiro que está aberto; ele não tem "aceso" | — |
| **selecionado** | não se aplica ao board; mora no azulejo | — |
| **desabilitado** | não se aplica; azulejos individuais desabilitam | — |
| **carregando** | azulejos em `bt-is-carregando`, **a grade não muda de forma** — o esqueleto tem exatamente o layout final | **DERIVADO** |
| **erro** | o azulejo que falhou vira `bt-is-erro`; os outros seguem normais. O board nunca vira uma tela de erro | **DERIVADO** |
| **vazio** | board com menos linhas, não board com placeholders. Se não há nada, é `bt-empty` (§5) | **DERIVADO** |
| **sem dono** | o azulejo individual fica tracejado | protótipo |
| **perigo / armado** | só o azulejo arma; o board não | protótipo |

#### (d) API Flutter

```dart
class AppTileRowSpec {
  const AppTileRowSpec({
    required this.children,       // List<Widget>
    this.weights = const <int>[], // 1 ou 2 por filho; vazio => tudo 1
    this.flexWeight = 112,        // 112 (alta) · 120 (herói)
    this.maxHeight = 128,         // 128 (alta) · 136 (herói)
  });
}

class AppTileBoard extends StatelessWidget {
  const AppTileBoard({
    super.key,
    required this.rows,           // List<AppTileRowSpec>
    this.heroRow,                 // int?    índice da linha 1fr/80/1fr
    this.center,                  // Widget? o ✕ ou o hub, no buraco de 80px
    this.maxWidth = 780,
    this.veil = true,             // véu + blur sobre a superfície viva
    this.onDismiss,               // VoidCallback? toque no véu
  });
}
```

```dart
AppTileBoard(
  heroRow: 1,
  center: AppCloseX(onTap: Navigator.of(context).pop),
  rows: [
    AppTileRowSpec(children: [
      AppTile(label: 'Desfazer', icon: BtIcon(BtGlyph.undo), onTap: _undo),
      AppTile(label: 'Dados', icon: BtIcon(BtGlyph.dice), onTap: _dados),
      AppTile(label: 'Quem começa', icon: BtIcon(BtGlyph.compass), onTap: _quem),
    ], weights: const [1, 2, 1]),
    AppTileRowSpec(flexWeight: 120, maxHeight: 136, children: [
      AppHeroTile(label: 'Passar a vez', title: 'Léo', onGo: _passar),
      AppTile(label: 'Dia / Noite', tone: AppTileTone.vitral,
              vitralColor: BtColors.vitralNoite, estado: AppTileEstado('noite'),
              onTap: _alternar),
    ]),
  ],
)
```

#### (e) Uso e anti-padrões

- **Tudo visível de uma vez.** Se não cabe, a resposta é menos azulejo ou mais linha — nunca rolagem. Conteúdo que rola é `AppTileOverlay`, não board.
- Pesos misturados por linha: `[1,2,1]`, `[2,1,1,1]`. Uma linha inteira de `1` é permitida, um board inteiro de `1` não.
- **Anti-padrão:** `GridView` com `childAspectRatio` fixo. A régua é linha de flex com altura própria, não célula quadrada.
- **Anti-padrão:** board sem herói. Toda tela de board tem um latão. Se não há jogada principal, a tela não precisava existir.
- **Anti-padrão:** board sobre fundo opaco. O véu é radial e a superfície de baixo continua visível.

#### (f) Acessibilidade

- Os contrastes são os dos azulejos (§4.1f); o board não pinta texto.
- **Ordem de foco:** ordem de leitura visual — linha a linha, esquerda para direita, com o `center` (✕) logo após o herói. `FocusTraversalGroup(policy: OrderedTraversalPolicy())` com `FocusTraversalOrder` explícito, porque o `center` fica no meio do `Row` mas é a saída.
- **Escape:** `Shortcuts` mapeando `LogicalKeyboardKey.escape` → `onDismiss`. Obrigatório na web.
- **Semantics:** o board é `Semantics(container: true, explicitChildNodes: true)`. Não tem label próprio — quem tem título é o `AppTileOverlay`.
- **`MediaQuery.disableAnimationsOf(context)`:** o `fade .16s` de entrada vira imediato.
- **Escala de fonte 200%:** `maxHeight` vira `minHeight` e o board passa a poder exceder a altura da tela. Nesse único caso ele ganha rolagem — é a saída de emergência, não o layout.
- **Alvo de toque:** cada azulejo tem ≥ 112 de altura útil ✔; o `center` (✕ 64×64) ✔ nos dois sistemas.

#### (g) Responsivo

| Largura | Colunas por linha | Largura do board | Observação |
|---|---|---|---|
| **390** | 2–5 (pesos 1/2) | 100% − 2×12 de goteira | Como em `specimen-390.png`, seção 1. |
| **834** | 2–5, as mesmas | `min(100%, 780)` | O board para de crescer aos 780; centraliza. |
| **1440** | 2–5, as mesmas | 780, centrado | A mesa viva aparece nas laterais. Não abrir 6ª coluna. |
| **1920** | idem 1440 | 780, centrado | idem. |
| **Hover** | por azulejo (§4.1g) | — | O board não reage. |
| **Cursor** | `basic` no véu; `click` nos azulejos | — | Toque no véu fecha, se `onDismiss != null`. |

---

### 4.4 · `AppTileOverlay` — a tela secundária

#### (a) Anatomia

```
┌─ AppTileOverlay ─ inset 0 ─ véu radial .80→.93 ─ blur 8px ───────┐
│                                                                   │
│   ┌─ head ── width min(100%, 560) ── pad 12/10/6/18 ──────────┐   │
│   │  ‹      Regras da mesa                             ( ✕ )  │   │
│   │  ↑44×44 ↑ Fraunces 600 22px/1.15          44×44 ardósia↑   │   │
│   └────────────────────────────────────────────────────────────┘   │
│                                                                   │
│   ┌─ body ── min(100%, 560) ── overflow-y auto ── gap 16 ─────┐   │
│   │   ┌──────────────┐  ┌──────────────┐                      │   │
│   │   │  AppTile     │  │  AppTile     │   ← slots livres      │   │
│   │   └──────────────┘  └──────────────┘                      │   │
│   │   ┌────────────────────────────────────────────┐          │   │
│   │   │  bt-hint: texto curto com ícone de latão   │          │   │
│   │   └────────────────────────────────────────────┘          │   │
│   └────────────────────────────────────────────────────────────┘   │
│   ══════════════ filete 1px rgba(243,239,227,.10) ═══════════════   │
│   ┌─ footer ── fora da rolagem ── auto-fit minmax(140, 1fr) ──┐   │
│   │      [  AÇÃO NEUTRA  ]        [  AÇÃO PRINCIPAL  ]         │   │
│   └────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────┘
      A superfície anterior continua viva, escurecida e desfocada.
```

#### (b) Tokens

| Propriedade | Valor | Origem |
|---|---|---|
| Véu | `radial-gradient(ellipse at 50% 40%, rgba(11,13,18,.80), rgba(11,13,18,.93))` | `.sheet { background }` |
| Desfoque | `blur(8px) saturate(.8)` | `.sheet { backdrop-filter }` |
| Coluna de conteúdo | `min(100%, 560px)`, centrada | `.sheet-head`, `.sheet-body` |
| Cabeçalho | padding `12px 10px 6px 18px`, gap 10 | `.sheet-head` |
| Título | Fraunces 600 22px/1.15, `text-wrap: balance`, elipse | `.sheet-head h2` |
| Corpo | padding `4px 18px 18px`, gap 16, `overscroll-behavior: contain` | `.sheet-body` |
| Seta de volta | 44×44 redondo, ícone 20px, cor névoa; `stroke-width` **2** | `.back` (:559-561) + `ICON.chev` (:845). O `stroke 2.2` que estava aqui é invenção do kit (`kit.css:332`) e `tokens.json` não registra stroke nenhum — ou volta para 2, ou vai marcado **DERIVADO** |
| ✕ no cabeçalho | 44×44, ardósia-850, `inset 0 0 0 1px` ardósia-750, ícone 18px | `.x` |
| ✕ único (na mesa) | 64×64, obsidiana, `--bt-sombra-x`, ícone 24px `stroke 2.6` | `.hubwrap.open .rail .hub` |
| Rodapé | fora da rolagem, `max-width 560`, padding `10px 18px 14px`, filete no topo | `.sheet > .btns` |
| Ação do rodapé | `min-height 46px`, raio 14, padding `0 16`, Inter 800 11.5px tracking .085em | **PARCIALMENTE DERIVADO** — `.btn` (`mesa-brewtact.html:597`) é `min-height: 46px; border-radius: 12px; padding: 0 16px; font: 600 14px/1`. Vieram dele a **altura 46 e o padding `0 16`**. O **raio 14 diverge do 12 do `.btn`** (é coerente com `kit.css:630`, não com a régua) e a tipografia é derivada |
| Entrada | `fade .16s ease` | `@keyframes fade` |

#### (c) Estados

| Estado | Aparência | Origem |
|---|---|---|
| **normal** | véu + cabeçalho + corpo + rodapé | protótipo (`.sheet`) |
| **ativo** | não se aplica — o overlay ou está aberto ou não existe | — |
| **selecionado** | não se aplica | — |
| **desabilitado** | não se aplica; o rodapé desabilita a ação individualmente | — |
| **carregando** | o corpo mostra as **mesmas peças** em `bt-is-carregando`; cabeçalho e rodapé já estão completos | **DERIVADO** |
| **erro** | uma peça `bt-is-erro` no lugar do bloco que falhou, com a palavra `DE NOVO` no canto de estado. Nunca uma tela de erro inteira | **DERIVADO** |
| **vazio** | uma peça `bt-empty` (136px, tracejado em latão, numeral `0`) ocupando o corpo | **DERIVADO** |
| **sem dono** | não se aplica ao overlay | — |
| **perigo / armado** | a ação de brasa do rodapé arma: `bt-action--brasa` + aro, rótulo troca para `TOCAR DE NOVO` | **DERIVADO** de `.is-armed` |

#### (d) API Flutter

```dart
enum AppOverlayVeil { folha, menu }   // blur 8 / blur 3

class AppTileOverlay extends StatelessWidget {
  const AppTileOverlay({
    super.key,
    required this.title,              // String — Fraunces 22px
    required this.body,               // List<Widget> — gap 16 entre eles
    this.footer,                      // Widget?  AppActionBar, fora da rolagem
    this.onBack,                      // VoidCallback? seta ‹ (voltou do menu)
    required this.onClose,            // VoidCallback  o ✕ único — obrigatório
    this.veil = AppOverlayVeil.folha,
    this.maxContentWidth = 560,
    this.leading,                     // Widget? ponto de cor + nome (vt-05)
  });
}

/// Abre por cima da superfície viva. NUNCA usa showDialog/showModalBottomSheet.
Future<T?> showAppTileOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,                 // a superfície de baixo continua viva
        barrierColor: null,            // o véu é do widget, não da rota
        barrierDismissible: true,
        barrierLabel: 'Fechar',        // OBRIGATÓRIO quando barrierDismissible
                                       // é true (contrato do ModalRoute)
        transitionDuration: const Duration(milliseconds: 160),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        pageBuilder: (c, _, __) => builder(c),
      ),
    );
```

```dart
showAppTileOverlay<void>(
  context: context,
  builder: (c) => AppTileOverlay(
    title: 'Regras da mesa',
    onBack: () => Navigator.of(c).pop(),        // volta ao menu
    onClose: () => Navigator.of(c).pop(),        // o ✕ fecha O OVERLAY
    body: [
      AppRuleGrid(children: [
        AppRuleTile(title: 'Dano de comandante tira vida', on: _danoVale,
                    onTap: () => setState(() => _danoVale = !_danoVale)),
        AppRuleTile(title: 'Tocar no número abre o teclado', on: _tecladoVale,
                    onTap: () => setState(() => _tecladoVale = !_tecladoVale)),
      ]),
      AppNumberRow(caption: 'Segurar muda de', values: const [5, 10, 20],
                   selected: _passo, onChanged: (v) => setState(() => _passo = v)),
      const AppHint('Toque na direita soma 1, na esquerda tira 1.'),
    ],
    footer: AppActionBar(primary: AppAction('Salvar regras', onTap: _salvar)),
  ),
);
```

#### (e) Uso e anti-padrões

- **Um único ✕.** `onClose` é obrigatório; `onBack` é opcional e **não** é uma segunda saída — a seta volta ao menu, o ✕ fecha o overlay.
- **`onClose` fecha o overlay, não a pilha.** A versão anterior escrevia `Navigator.of(c).popUntil((r) => r.isFirst)`. Isso funciona no contador, onde a mesa é a primeira rota — e **derruba toda a navegação do usuário** em qualquer outro lugar. §0 e §8 põem o `AppTileOverlay` no lugar dos 24 `showModalBottomSheet` e dos 51 `showDialog` do app inteiro, abertos de dentro de decks, binder e battle com três ou quatro rotas embaixo; `popUntil((r) => r.isFirst)` volta para a raiz do app. O ✕ é `Navigator.of(c).pop()`. Se a intenção for "sair de toda a pilha de overlays", isso precisa de um `RoutePredicate` próprio que pare na primeira rota **não-overlay** (`AppOverlayRoute`), e ele tem de nascer junto com a rota.
- O rodapé fica **fora** da área que rola e nunca cobre conteúdo. `padding-bottom` do corpo já conta com ele.
- No máximo **uma** ação principal por rodapé (um herói por tela).
- **Anti-padrão:** `showDialog` / `AlertDialog` / `showModalBottomSheet`. Os três desenham caixa própria com barreira chapada e matam a regra 5.
- **Anti-padrão:** overlay com título, subtítulo cinza e uma lista de linhas. Isso é exatamente a superfície de configurações que o dono rejeita.
- **Anti-padrão:** dois overlays empilhados com dois ✕ visíveis. Se o segundo precisa existir, ele substitui o primeiro e a seta volta.
- **Anti-padrão:** overlay para confirmar. Confirmação é o segundo toque no próprio objeto (`armed`), não uma caixa nova.

#### (f) Acessibilidade

| Par | Razão | Veredito |
|---|---:|---|
| marfim sobre véu no centro (`rgba(11,13,18,.80)` sobre a mesa) | ≥ 12,16 (o véu só escurece) | ✔ AAA |
| título marfim sobre obsidiana | **16,91** | ✔ AAA |
| névoa (seta ‹, títulos de faixa) sobre obsidiana | **10,60** | ✔ AAA |
| marfim (✕) sobre ardósia-850 `#1D222C` | **13,87** | ✔ AAA |
| névoa em `bt-hint`: sobre ardósia-850 **opaca** 8,69 · composto a `.6` sobre obsidiana **9,54** | **8,69** (pior caso) | ✔ AAA |
| latão-400 (ícone do hint, aro do ✕) sobre obsidiana | **9,17** | ✔ (não-texto ≥ 3) |

- **Alvo de toque:** ✕ único 64×64 ✔; ✕ do cabeçalho 44×44 e seta 44×44 → **crescer o alvo para 48** com `Padding` transparente no Android, sem mudar o desenho. Ação do rodapé 46 → idem.
- **Semantics:** a rota é `Semantics(scopesRoute: true, namesRoute: true, label: title)`. O ✕ é `Semantics(button: true, label: 'Fechar')`, a seta `label: 'Voltar ao menu'` — nunca os dois com o mesmo nome.
- **Foco por teclado:** `FocusScope` com `autofocus` no primeiro elemento do corpo (não no ✕ — o ✕ é saída, não destino). `Escape` → `onClose`. `Shift+Tab` a partir do primeiro elemento chega ao ✕.
- **`MediaQuery.disableAnimationsOf(context)`:** transição de rota sem fade, `BackdropFilter` mantido (é estático, não é animação).
- **Escala de fonte 200%:** título em `maxLines: 2` + elipse; o corpo rola (já rola); o rodapé cresce em altura e o `auto-fit minmax(140px, 1fr)` quebra para uma coluna.
- **`BackdropFilter` e leitor de tela:** o conteúdo desfocado atrás continua na árvore e precisa sair dela. **Mas o mecanismo não é do overlay:** com `opaque: false` a rota de baixo continua montada e semanticamente visível, e o overlay não tem handle nenhum sobre ela. Quem envolve a si mesma em `ExcludeSemantics` é a **superfície de baixo**, escutando um `RouteObserver` (ou um `ValueNotifier` compartilhado) que diz "há overlay aberto". É trabalho no lado de baixo, e sem ele a exigência não é implementável.
- **`BackdropFilter`: custo, recorte e o `saturate(.8)` que o Flutter não tem.** A regra 5 de §2 manda blur em **toda** tela secundária (`blur(8px)` na folha, `blur(3px)` no board) por cima de uma mesa que está animando. Três coisas concretas que faltavam:
  1. `BackdropFilter` força um `saveLayer` da tela inteira por frame. É o item mais caro do kit e precisa de **orçamento medido** antes de virar padrão de 500+ telas (medição é item de Onda 0, junto com o numeral por contêiner).
  2. Sem `ClipRect` o filtro vaza para toda a camada pai. O overlay sempre embrulha o `BackdropFilter` em `ClipRect`.
  3. `ImageFilter.blur` **não tem saturação**. O `saturate(.8)` exige `ColorFilter.matrix` composto (`ImageFilter.compose`) ou um `ColorFiltered` por cima do borrado — e o `TileMode` precisa ser declarado (o default `clamp` espalha a borda e mancha o canto).

#### (g) Responsivo

| Largura | Comportamento |
|---|---|
| **390** | Coluna = 100% − 2×18. Cabeçalho, corpo e rodapé todos na mesma largura. |
| **834** | Coluna trava em **560px**, centrada. Sobra vira véu com a superfície viva aparecendo. |
| **1440** | Idem 560px centrado (é o que `specimen-1440.png` mostra: as peças **não** se espalham). O overlay **não** vira painel lateral nem diálogo centrado com moldura. |
| **1920** | Idem. |
| **Hover** | Nas peças do corpo (§4.1g). ✕ e seta: `scale 1.05` + tinta marfim. **DERIVADO**. |
| **Cursor** | `click` no ✕, na seta e nas peças; `basic` no véu quando `barrierDismissible` está desligado. |

---

### 4.5 · `AppHeroTile` — o herói de latão

Um por tela. É a jogada principal, e é a única superfície grande de latão cheio.

#### (a) Anatomia

```
┌─ AppHeroTile ── raio 22 · pad 10/14/10/16 · gap 12 ──────────────────┐
│                                                                       │
│  ┌─ turno ──┐ │ ┌─ mid (flex 1) ─────────────┐   ┌─── go ───┐        │
│  │  TURNO   │ │ │ PASSAR A VEZ               │   │          │        │
│  │  ↑11px   │ │ │ ↑ Inter 800 11.5 .085em    │   │    →     │ 56×56  │
│  │          │ │ │                            │   │  obsid.  │        │
│  │    3     │ │ │ Léo                        │   │ aro latão│        │
│  │  ↑70px   │ │ │ ↑ Fraunces 700 30px/1      │   └──────────┘        │
│  │ Fraunces │ │ │                            │      ↑ flex: none     │
│  └──────────┘ │ │ ● ▬▬ ● ●   ← pips 13px     │                       │
│    min 56×64  │ │   ↑ o da vez: 28px          │                       │
│               │ └────────────────────────────┘                       │
│         divisor 2px rgba(11,13,18,.18)                                │
│                                                                       │
│  brilho diagonal 115° por cima de tudo (::before)                     │
└───────────────────────────────────────────────────────────────────────┘
   5 slots: leadingCaption · leadingNumeral · label · title · pips · onGo
   Variante `is-idle` (`idle: true` na API): o bloco de turno some e o divisor sai.
```

#### (b) Tokens

| Propriedade | Valor | Origem |
|---|---|---|
| Raio | 22px | `.menu .hero` |
| Padding | `10px 14px 10px 16px`, gap 12 | `.menu .hero` |
| Fundo | `linear-gradient(158deg, #F4CB6C 0%, #E0A93B 40%, #C58B2A 100%)` | `.menu .hero { background }` |
| Brilho | `--bt-brilho-diagonal` (115° claro + 200° escuro) | `.menu .hero::before` |
| Sombra | `inset 0 1.5px 0 rgba(255,255,255,.45), 0 10px 22px rgba(0,0,0,.5), 0 0 0 3px rgba(11,13,18,.85)` | `.menu .hero { box-shadow }` |
| Tinta | obsidiana `#0B0D12` | `.menu .hero { color }` |
| Numeral do turno | Fraunces 700 **70px**/.8, `text-shadow 0 1px 0 rgba(255,255,255,.35)` | `.menu .hero .num` — divergência arbitrada (vitral usa 78) |
| Legenda do turno | Inter 700 11px/1, tracking .06em, caixa alta, `rgba(11,13,18,.7)` | `.menu .hero .sub` |
| Divisor | `border-left: 2px solid rgba(11,13,18,.18)`, padding-left 12 | `.menu .hero .mid` |
| Rótulo | Inter 800 11.5px/1.18, tracking .085em, caixa alta, **sem** text-shadow | `.menu .hero .lb` |
| Nome | Fraunces 700 **30px**/1, tracking -.01em, elipse | `.menu .hero .quem` — divergência arbitrada (vitral usa 34) |
| Pips | 13×13, raio 5, `0 0 0 2px rgba(11,13,18,.85)`; o da vez vira **28px**; fora = `opacity .3` | `.menu .ordem i` — divergência arbitrada (vitral usa 14/30) |
| Botão redondo | 56×56, obsidiana, `0 6px 14px rgba(0,0,0,.4), inset 0 0 0 2px rgba(224,169,59,.55)`; seta 27px em latão `stroke 2.4` | `.menu .go` — divergência arbitrada (vitral usa 58) |
| Bloco do turno | `min-width 56`, `min-height 64` | `.menu .hero .turno` |

**Variante multi-ação** (`provas-iphone/vt-08-turnos.png`, publicada 2026-09-21 19:32): o herói aceita até **três** botões redondos à direita — os secundários (‹, ‖) escavados no próprio latão, o principal (→) em obsidiana com o aro. Só o principal é obsidiana: continua um herói. Os valores exatos ainda não foram extraídos de `mesa-brewtact.html` (ver §10).

#### (c) Estados

| Estado | Aparência | Origem |
|---|---|---|
| **normal** | latão cheio, brilho diagonal, tinta obsidiana | protótipo (`.menu .hero`) |
| **ativo / valendo** | não se aplica — o herói já é a cor cheia máxima | — |
| **selecionado** | não se aplica — o herói não é opção, é ação | — |
| **desabilitado** | `opacity .38` no herói inteiro | **DERIVADO** (extensão do `.menu .t:disabled`) |
| **carregando** | latão **apagado**: fundo `--bt-grad-peca` (vidro) + varredura; o herói só volta a ser latão quando há o que fazer. *Latão em carregamento mentiria: nada está valendo.* | **DERIVADO** |
| **erro** | o herói **não** vira brasa. O erro aparece na peça que falhou; o herói vira `bt-action` neutro com o rótulo `TENTAR DE NOVO` | **DERIVADO** |
| **vazio** | o herói some e no lugar entra `bt-empty` com o convite dentro | **DERIVADO** |
| **sem dono** | nome vira o tracejado de `.livre` + rótulo `#EBCB8B` (ex.: `SEM DONO / INICIATIVA`) | protótipo (`.menu .t.livre`) |
| **perigo / armado** | **proibido.** O herói é a jogada principal, não a destruição. Destruir é azulejo de brasa com dois toques | regra do mapa |
| **ocioso** (`idle` na API, `--ocioso` no CSS do kit) | sem bloco de turno, sem divisor, `padding-left 2` no meio | protótipo — a classe é **`.menu .hero.is-idle`** (`mesa-brewtact.html:332`), não `.hero.ocioso`. Os efeitos conferem; só o nome estava errado |

#### (d) API Flutter

```dart
class AppHeroTile extends StatelessWidget {
  const AppHeroTile({
    super.key,
    required this.label,            // String   Inter 800 caixa alta
    required this.title,            // String   Fraunces 30px — o nome
    this.leadingNumeral,            // Widget?  AppNumeral(scale: heroi)
    this.leadingCaption,            // String?  "TURNO"
    this.subtitle,                  // String?  "RODADA 1" (vt-08)
    this.pips = const <AppHeroPip>[],
    this.onGo,                      // VoidCallback?  o botão redondo obsidiana
    this.goIcon = BtGlyph.arrowRight,
    this.secondaryActions = const <AppHeroAction>[], // no máx. 2, escavadas
    this.idle = false,              // sem bloco de turno nem divisor
    this.loading = false,
    this.semanticsHint,             // String?  "toca duas vezes para passar a vez"
  });
}

class AppHeroPip {
  const AppHeroPip({required this.color, this.current = false, this.out = false});
}
class AppHeroAction {
  const AppHeroAction({required this.icon, required this.label, this.onTap});
}
```

```dart
AppHeroTile(
  leadingCaption: 'Turno',
  leadingNumeral: const AppNumeral('3', scale: AppNumeralScale.heroi),
  label: 'Passar a vez',
  title: mesa.jogadorDaVez.nome,
  pips: [
    for (final j in mesa.jogadores)
      AppHeroPip(
        color: j.corDoAssento,
        current: j.id == mesa.jogadorDaVez.id,
        out: j.forasDaPartida,
      ),
  ],
  onGo: () => context.read<MesaCubit>().passarAVez(),
  semanticsHint: 'passa a vez para o próximo jogador',
)
```

#### (e) Uso e anti-padrões

- **Exatamente um por tela.** Se aparecem dois, o segundo vira `AppTile` de vidro.
- O botão redondo é **obsidiana**, nunca claro. Um botão claro sobre latão claro some.
- O nome é o maior texto não-numérico da tela: 30px Fraunces. Se cabe em 14px, não era um herói.
- **Anti-padrão:** `FilledButton` largo, de ponta a ponta, com rótulo. É exatamente o que o herói substitui — ele tem numeral, nome, pips e ação num objeto só.
- **Anti-padrão:** herói de latão para uma ação destrutiva. Destruir é brasa e dois toques.
- **Anti-padrão:** herói com três linhas de texto explicativo. Máx.: rótulo + nome + subtítulo.
- **Anti-padrão:** herói em estado de carregamento pintado de latão. Latão quer dizer "vale agora".

#### (f) Acessibilidade

| Par | Razão | Veredito |
|---|---:|---|
| obsidiana sobre latão-claro `#F4CB6C` (topo, onde cai o numeral 70px) | **12,59** | ✔ AAA |
| obsidiana sobre latão-400 `#E0A93B` (meio, onde cai o nome) | **9,17** | ✔ AAA |
| obsidiana sobre latão-500 `#C58B2A` (fim, canto inferior direito) | **6,57** | ✔ AA · ✘ AAA |
| legenda `rgba(11,13,18,.7)` sobre latão-400 | **5,04** | ✔ AA (11px/700) |
| **legenda `rgba(11,13,18,.7)` sobre latão-500** (fim do gradiente) | **4,12** | ✘ **AA por 0,38** |
| latão-400 (seta) sobre obsidiana (miolo do botão) | **9,17** | ✔ |
| aro `rgba(224,169,59,.55)` sobre obsidiana | ~4,4 | ✔ (não-texto ≥ 3) |
| desabilitado (herói a `.38`): obsidiana sobre `#5C4822` | **2,23** | ✘ — exige `enabled: false` |

**A regra do `.7` está certa — e o kit a quebra em dois outros lugares.** A legenda do herói `rgba(11,13,18,.7)` em 11px dá **6,01** sobre latão-claro, **5,06** sobre latão-400 e cai para **4,12** no fim do gradiente. No protótipo ela fica no canto **superior esquerdo**, onde o latão ainda está claro — o desenho do herói já está certo. **Regra:** texto a `.7` de obsidiana só é permitido na metade superior-esquerda de uma superfície de latão.

**Quem quebra a regra** (os dois estão em provas publicadas e a versão anterior desta spec não olhou para eles):

| Onde | Valor | Razão | Veredito |
|---|---|---:|---|
| `.bt-tile--sel .bt-tile__sub` (kit.css:230) — subrótulo do azulejo **selecionado**, canto **inferior** esquerdo | `rgba(11,13,18,.7)` Inter 700 11px | **4,12** sobre o fim do latão | ✘ AA |
| `.bt-rule--on .bt-rule__st` (kit.css:452) — a palavra **`VALE`** de `vt-04-regras.png`, no rodapé de um `AppRuleTile` de 96px | `rgba(11,13,18,.72)` Inter 800 11px | **4,30** sobre `#C58B2A` | ✘ AA |

Nos dois a correção é a mesma e é barata: **opacidade 1**. Obsidiana cheia sobre `#C58B2A` dá **6,57**. `subtitle` do herói (vt-08, "RODADA 1") mora no meio, também acima do fim; se algum dia for para o canto inferior direito, sobe para opacidade 1 pela mesma regra.

- **Alvo de toque:** botão redondo 56×56 ✔ nos dois sistemas. O herói inteiro é tocável (altura ≥ 120) ✔. As ações secundárias de vt-08 aparentam ~48 e precisam de medição antes de virar código. Onde for preciso crescer, vale a receita corrigida de §4.1f (`Padding` + `ConstrainedBox`, **não** `MaterialTapTargetSize`).
- **Semantics:** um `Semantics(button: true, label: '$label, $title', hint: semanticsHint)` para o herói e **outro** para o botão redondo — são dois alvos, não um. Os pips são `ExcludeSemantics` (a informação já está em `title`).
- **Foco por teclado:** o herói é o primeiro na ordem de foco da linha do herói; o botão redondo vem logo depois. Aro de foco em latão-400 **não funciona sobre latão** — sobre o herói o aro de foco é **obsidiana 2px + 1px de marfim por fora**. **DERIVADO**, e é a única inversão de aro do kit.
- **`MediaQuery.disableAnimationsOf(context)`:** sem o `scale .97`; a troca de pip (13→28px) vira corte seco.
- **Escala de fonte 200%:** `label` até 2 linhas, `title` em `maxLines: 1` + elipse (é nome próprio — elipse é melhor que quebra). O numeral em `FittedBox` com piso 24. Acima de ~170% o bloco do turno colapsa para a variante `idle` automaticamente.

#### (g) Responsivo

| Largura | Comportamento |
|---|---|
| **390** | Ocupa `1fr` da linha do herói (`1fr 80px 1fr`); altura 120–136. Nome com elipse. |
| **834** | Mesma proporção; a linha trava em 780, o herói fica com ~350px. |
| **1440 / 1920** | Idem 834. O herói **não** vira faixa de ponta a ponta — em `specimen-1440.png` ele continua com a mesma largura do 390 dentro do board de 780. |
| **No `AppTileOverlay`** | O herói ocupa a largura da coluna (560px) e ganha as ações secundárias (vt-08). |
| **Hover** | `scale 1.012` + `0 12px 28px rgba(224,169,59,.22)` na sombra externa. **DERIVADO**. |
| **Cursor** | `click` no herói e no botão redondo. |

---

## 5 · Peças derivadas — composições das cinco primitivas

Nenhuma delas é primitiva nova: cada uma é `AppTile` / `AppNumeral` / `AppHeroTile` com slots preenchidos.

| Peça | Composição | Valores | Onde está na régua |
|---|---|---|---|
| **Peça com miniatura** `AppChoiceTile` | `AppTile` com o slot `icon` trocado por uma miniatura real + `AppNumeral(peca)` no rodapé | raio 22, pad `11px 12px 9px`, numeral 38→**44** quando selecionada, miniatura `100% × 30–66px` raio 12 sobre `rgba(11,13,18,.8)`; selecionada = latão-peça + `--bt-sombra-selecionado` | `.p` + `.seats` · `jogadores.png` |
| **Peça-numeral** `AppNumberTile` | `AppTile` que **não pinta** ícone nem rótulo: só `AppNumeral(pecaNumeral)`. O `label` continua **obrigatório** e vira o nome acessível (ver §5.1) | **70×58**, raio 20, `rgba(29,34,44,.8)` + `inset 0 0 0 1.5px rgba(243,239,227,.13)`; numeral 36→**40**; variante "outro" 30 | `.v` · `vt-04-regras.png` |
| **Peça-regra que acende** `AppRuleTile` | `AppTile` com três faixas (`auto 1fr auto`): ícone 26, título Inter 700 14px/1.2 marfim, palavra de estado Inter 800 11px tracking .1em | `min-height 96`, pad `12px 14px`; acesa = latão-peça + tinta obsidiana + `VALE`; variante `--sm` 84×58 centrada; variante `--estado` 74px, três por linha | `.rt`, `.rt.sm` · `vt-04`, `vt-05` |
| **Peça-regra ruim** `AppRuleTile(bad:)` | idem, com `--bt-c = #B5402B` | acesa em brasa cheia, tinta marfim, aro `0 0 0 5px rgba(255,138,128,.45)` | `.rt.bad.on` · `vt-05-jogador.png` |
| **Rodapé de ação** `AppActionBar` | `Row`/`Wrap` de `AppAction`, fora da rolagem | `min-height 46`, raio 14, pad `0 16`, `auto-fit minmax(140px, 1fr)`, gap 8; principal = `--bt-grad-latao` + brilho; neutra = `--bt-grad-peca`; brasa = tinta `#FF8A80` | **DERIVADO** — o `.btn` do protótipo ainda é da linguagem antiga; só a altura 46 veio dele |
| **Resultado herói** `AppResultHero` | `AppTile` que **não pinta** rótulo: o conteúdo é um `AppNumeral(resultado)`. O `label` continua obrigatório e vira o nome acessível | `min-height 172`, raio 22, numeral 700 **92px**/.85 (variante longa 46px); apagado com `?` enquanto não há valor, latão-peça quando há | `.dx-hero` · `vt-06-dados.png` |
| **Peça-forma** `AppShapeTile` | `AppTile` com a **forma do objeto** em SVG no lugar do ícone | `min-height 82`, raio 20, forma 40px `fill rgba(243,239,227,.07)`, rótulo Inter 800 11px tracking .1em; toque = `scale .95` | `.dx-die` · `vt-06-dados.png` |
| **Faixa de ação** `AppLane` | `AppTile` deitado: ícone 28 em latão + título Fraunces 700 17px + linha Inter 600 11px tracking .08em em névoa | `min-height 64`, raio 20, pad `0 18` | `.dx-start` · `vt-06`, `plano.png` |
| **Fileira com valor** `AppScoreRow` | `AppTile` na cor do jogador + `AppNumeral` 30px + etiqueta-pílula | `min-height 64`, raio 18, pad `8px 10px`, vitral 158° (80/45/68%), filete `rgba(243,239,227,.16)`; nome Inter 700 11px/1.1; etiqueta Inter 800 9px tracking .08em em latão-400, top 7 right 8; vencedor = `0 0 0 3px` obsidiana + `0 0 0 5px` latão-400 | `.dx-p`, `.dx-p.win` · `vt-07-quem-comeca.png` |
| **Bloco vivo do dono** `AppLiveBlock` | `AppTile` em vitral da cor do jogador com os controles **escavados dentro** | raio 22, pad `12px 14px`, vitral 158° (80/45/66%); numeral 700 **64px**/.9; controle redondo 48×48 em `rgba(11,13,18,.34)`; pad `min-height 44`, raio 14 | `.pf-life`, `.pf-st`, `.pf-pad` · `vt-05-jogador.png` |
| **Fileira de cores** `AppSwatchRow` | círculos 44×44, miolo `inset 4px` | selecionado = `0 0 0 2px` obsidiana-900 + `0 0 0 4px` **marfim** (exceção consciente ao "latão = selecionado") | `.swatches` · `vt-05-jogador.png` |
| **Pílulas do histórico** `AppLogPills` | `Wrap` de pílulas | Inter 600 12px `tabular-nums`, ardósia-850, raio 999, pad `6px 10px`, cor névoa, gap 6 | `.log li` · `vt-07-quem-comeca.png` |
| **Cartão de dica** `AppHint` | ícone 20 em latão + parágrafo Inter 500 12px/1.4 em névoa (`<b>` em marfim) | raio 16, pad `10px 12px`, `rgba(29,34,44,.6)` | `.gt` · `vt-04-regras.png` |
| **Repetir** `AppAgainButton` | `AppTile` estreito | 56px de largura, raio 18, `rgba(29,34,44,.8)` + filete `.10`, ícone 22 | `.dx-again` · `vt-07-quem-comeca.png` |

### 5.1 · Acessibilidade das peças derivadas

A versão anterior desta spec entregava as 14 peças com valores completos e **zero contraste** — e é exatamente nelas que as falhas moram, porque §4 mediu as primitivas e as peças mudam as paradas do gradiente, o tamanho da tinta e o lugar onde o texto cai. Medido hoje, pelo método de §4.1f (projeção do slot sobre a rampa), não pela parada do meio:

| Peça | Slot medido | Razão | Veredito |
|---|---|---:|---|
| `AppScoreRow` (`.dx-p`, vt-07) | nome Inter 700 11px, marfim, conteúdo centrado | **5,05 a 8,00** nos 10 assentos | ✔ AA |
| `AppScoreRow` | numeral 30px, marfim | **5,78 a 9,11** | ✔ AA |
| `AppLiveBlock` (`.pf-life`, vt-05) | numeral 64px, marfim | **5,78 a 9,01** | ✔ AA |
| **`AppLiveBlock` · legenda** (`.bt-live__cap`, o `VIDA · COMEÇOU COM 40` de vt-05) | `rgba(243,239,227,.8)` Inter 800 11px, **no topo clareado** do assento | **3,40 a 4,94** — reprova em **9 dos 10 assentos** | ✘ AA |
| **`AppRuleTile` aceso** | a palavra `VALE`, `rgba(11,13,18,.72)` Inter 800 11px | **4,30** | ✘ AA |
| **`AppRuleTile(bad:)` aceso** (`.rt.bad.on`) | título marfim 14px/700 | **3,27** no topo · **2,70** com o brilho · 4,89 no meio | ✘ AA (ver §4.2f) |
| **`AppRuleTile(bad:)` aceso** | estado `rgba(243,239,227,.8)` | **2,64** no topo · **2,25** com o brilho | ✘ AA |
| `AppHint` (`.gt`) | névoa Inter 500 12px sobre `rgba(29,34,44,.6)` | **9,54** (8,69 sobre ardósia opaca) | ✔ AAA |
| `AppLogPills` (`.log li`) | névoa Inter 600 12px sobre ardósia-850 | **8,69** | ✔ AAA |
| `AppLane` (`.dx-start`) | título marfim 17px / linha névoa 11px sobre vidro | 12,16 / 8,3 | ✔ |
| `AppAgainButton` (`.dx-again`) | ícone névoa 22px sobre `rgba(29,34,44,.8)` | 8,9 (não-texto ≥ 3) | ✔ |

As quatro reprovações e os remédios propostos estão em **§11**. Nenhuma delas se resolve trocando a tinta por obsidiana — em todas as quatro a obsidiana é pior.

**Semântica das peças derivadas.** Cada peça herda o papel do widget que ela substitui (§4.1f), não o papel genérico de `AppTile`. Duas precisam de contrato explícito porque não têm texto nenhum:

- **`AppSwatchRow` (a fileira de 10 cores de `vt-05-jogador.png`)** tem dez círculos e **nenhum texto**. Para quem usa leitor de tela são dez botões idênticos sem nome, e para quem não distingue cor a escolha é impossível — WCAG 1.4.1 (uso de cor) e 4.1.2 (nome/papel/valor). Cada assento precisa do **nome em palavra** (`brasa`, `âmbar`, `musgo`, `maré`, `índigo`, `ameixa`, `ferro`, `vinho`, `cobre`, `pinho`) em `Semantics(label:)`, mais `inMutuallyExclusiveGroup: true` e `selected:`. O aro marfim do selecionado já é o segundo sinal não-cromático exigido — desde que **declarado como tal** e não confundido com foco.
- **`AppNumberTile` e `AppResultHero`** não pintam rótulo, mas o número sozinho não diz nada: em `vt-04` o `10` selecionado só faz sentido com a legenda `SEGURAR MUDA DE`, que é um **irmão fora da peça**. Por isso `label` continua obrigatório em `AppTile` e vira `Semantics(label: '<legenda>: <valor>')` mesmo quando não é desenhado.
- **`AppLogPills` nunca é tocável.** A pílula tem ~24px de altura (Inter 12px + pad 6/10); ela só passa porque é passiva. A primeira que virar filtro nasce com alvo de 24px. Se precisar ser tocável, deixa de ser pílula e vira `AppTile` pequeno.

**Três peças vistas nas provas de 19:32 e ainda não extraídas** (`plano.png`, `vt-08-turnos.png` — publicadas depois de `kit.css`/`tokens.json`):

- **Contador com ± e numeral** (`.pl-count`): rótulo em caixa alta em cima, numeral serifado entre dois botões redondos escavados, nota embaixo. É `AppLiveBlock` sem a cor do dono.
- **Barra de proporção por pessoa** (`.tn-p`): nome + barra na cor do jogador + valor `tabular-nums`; a linha da vez ganha halo de latão e a palavra `NA VEZ` em latão. Não existe equivalente no kit.
- **Herói de comando** (`.tn-hero`): `AppHeroTile` com subtítulo e três botões redondos (dois escavados, um obsidiana).

Os valores das três **não estão nesta spec** porque não foram extraídos do HTML. Ver §10.

---

## 6 · Entrada de texto livre — o padrão que o protótipo não tem

**O protótipo não tem campo de texto de formulário.** O que ele tem é a **placa** (`.plaque`, `vt-05-jogador.png`): serifa grande sobre um fio, sem caixa, que acende em latão no foco. Todo o resto abaixo é **DERIVADO** a partir dela e das cinco regras.

### 6.1 · `AppPlaque` — a placa (o padrão)

```
      NOME NA MESA                    ← Inter 800 11px, tracking .12em, névoa
      Bia                             ← Fraunces 600 22px/1.2, marfim
      ──────────────────────────────  ← fio 2px rgba(243,239,227,.22)
                                         no foco: latão-400 #E0A93B
```

| Propriedade | Valor | Origem |
|---|---|---|
| Texto | Fraunces 600 22px/1.2, `font-optical-sizing: auto`, marfim | `.plaque input` |
| Fio | `border-bottom: 2px solid rgba(243,239,227,.22)`, padding `2px 0 7px` | `.plaque input` |
| Fio no foco | `#E0A93B` (latão-400) | `.plaque input:focus` |
| Placeholder | névoa-fraca `#8A93A3`, itálico | `.plaque input::placeholder` |
| Rótulo | Inter 800 11px, tracking .12em, caixa alta, névoa | `.rband__cap` |
| Sem caixa | sem `background`, sem `border`, `border-radius: 0` | `.plaque input` |

### 6.2 · As cinco entradas do app

| Entrada | Peça | Por quê |
|---|---|---|
| **Nome de deck / nome na mesa** | `AppPlaque` direto | É um nome próprio, curto, e a serifa o trata como objeto. Erro aparece como o fio virando brasa `#FF8A80` + uma palavra em caixa alta abaixo, nunca uma caixa vermelha. |
| **Busca** | `AppPlaque` com o ícone de lupa à esquerda do fio, **sem** caixa | O resultado aparece embaixo como peças. A busca vazia é `bt-empty`, não texto centralizado. Nenhuma borda arredondada de campo de busca. |
| **Prompt de IA** (`deck_generate_screen.dart:1204`) | `AppPlaque.multiline`: Fraunces 600 22px, **até 4 linhas**, fio embaixo de tudo, contador de caracteres como pílula de `AppLogPills` no canto inferior direito | É o texto mais importante da tela — merece a serifa grande. O `helperText` do Material vira `AppHint` abaixo. |
| **Senha** | `AppPlaque.obscured`: pontos em **Inter 600 22px** `tabular-nums` (não Fraunces: ponto serifado não existe), o olho de mostrar/esconder é um `AppTile` redondo 44×44 de vidro à direita do fio | Senha não pode ser bonita à custa de ser ilegível. `autofillHints`, `obscuringCharacter: '•'`. O olho a 44×44 é mais um alvo abaixo de 48dp (§10.1). |
| **E-mail** *(faltava nesta tabela e é metade de `login_screen.dart:146,174`)* | `AppPlaque.email`: Fraunces 600 22px como o nome, mas `keyboardType: TextInputType.emailAddress`, `textCapitalization: none`, `autocorrect: false`, `autofillHints: [AutofillHints.email]` | E-mail é nome próprio de conta: mesma placa do nome, teclado e correção diferentes. Sem `autocorrect: false` o iOS capitaliza e corrige o endereço. |

### 6.3 · API

```dart
enum AppPlaqueKind { nome, busca, prompt, senha }

class AppPlaque extends StatelessWidget {
  const AppPlaque({
    super.key,
    required this.controller,
    this.kind = AppPlaqueKind.nome,
    this.caption,                 // String?  o rótulo em caixa alta acima
    this.placeholder,             // String?  itálico, névoa-fraca
    this.leading,                 // Widget?  lupa, ponto de cor
    this.trailing,                // Widget?  olho, contador
    this.errorWord,               // String?  "JÁ EXISTE" — caixa alta, brasa
    this.errorLine,               // String?  a frase inteira, quando a palavra
                                  //          não cabe (regra de senha, erro de
                                  //          servidor). Inter 500 12px em brasa.
    this.maxLines = 1,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    // ── o que faltava para fechar um formulário legítimo ──
    this.focusNode,               // FocusNode?  sem ele não há encadeamento e
                                  //             textInputAction.next não leva
                                  //             a lugar nenhum
    this.onChanged,               // ValueChanged<String>?  validação ao vivo
    this.validator,               // FormFieldValidator<String>?
    this.keyboardType,            // TextInputType?
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enabled = true,
    this.readOnly = false,
  });
}
```

```dart
AppPlaque(
  controller: _nome,
  caption: 'Nome do deck',
  placeholder: 'Rafa · Atraxa',
  errorWord: _jaExiste ? 'já existe' : null,
  textInputAction: TextInputAction.done,
  onSubmitted: (_) => _salvar(),
)
```

### 6.4 · Regras e anti-padrões

- **Nunca** `InputDecoration` com `filled: true`, `border: OutlineInputBorder`, `labelText` flutuante ou `prefixIcon` dentro da caixa. A placa não tem caixa.
- O rótulo fica **acima**, fixo, em caixa alta. Rótulo que flutua e encolhe é gramática de formulário.
- Erro = fio em brasa + uma palavra em caixa alta. Nunca parágrafo vermelho, nunca ícone de alerta dentro do campo.
- **Um teclado por tela.** Se a tela precisa de 6 campos (cadastro, checkout), a moldura muda mas os campos ficam: são as duas únicas telas do app onde formulário é legítimo (`docs/design/sequencia-e-esforco.md`, onda 6). O que muda é tudo em volta.
- **A exceção do parágrafo.** `errorWord` é "uma palavra em caixa alta" e não cabe `e-mail ou senha incorretos` nem `a senha precisa de 8 caracteres com um número`. Mensagem vinda do servidor e regra de senha **precisam de uma linha de texto**, e ela mora em `errorLine`: Inter 500 12px/1.4 em brasa, abaixo do fio, `maxLines: 2`. Continua proibido: caixa vermelha, ícone de alerta dentro do campo e parágrafo decorativo. A placa sem essa saída simplesmente não fecha login nem cadastro.
- Contraste: marfim sobre obsidiana **16,91** ✔ AAA; placeholder névoa-fraca sobre obsidiana **6,28** ✔ AA; fio em repouso `rgba(243,239,227,.22)` = **1,84** contra obsidiana — **abaixo de 3,0 para componente não-textual**. Subir para `.35` dá **2,91** (não "≈2,6", como esta spec publicava — a conta não reproduzia: `.35` sobre obsidiana compõe `#5C5C5B`). **2,91 continua abaixo de 3,0**, por 0,09 — e a 0,09 do limite a conversa com o dono é outra. `.45` daria 4,08. **É um defeito do protótipo herdado pelo kit** e vai para §11.
- Alvo de toque: a área tocável da placa é a linha inteira com `min-height 48`, não só o texto.
- `Semantics(textField: true, label: caption, hint: placeholder)`; o `errorWord` vira `Semantics(liveRegion: true)`.

---

## 7 · O que muda em `app_theme.dart`

### 7.1 · Quatro revogações obrigatórias

O tema atual **proíbe por contrato** a linguagem do contador. Sem revogar, o kit não compila conceitualmente. A versão anterior desta spec listava duas; conferindo o arquivo linha a linha, são quatro.

**(1) Linha 18 — a regra 4:**

```dart
///   4. Gradients only for hero sections and primary buttons.
```

O azulejo neutro **é** um gradiente (`160deg, rgba(41,48,65,.88) → rgba(21,24,33,.95)`) e ele é a superfície mais comum do kit. Texto novo proposto:

```dart
///   4. Gradientes carregam significado: vidro (160°) em toda peça neutra,
///      vitral (158°) no que está valendo, latão (158°) no herói e no
///      selecionado. Gradiente decorativo continua proibido.
```

**(2) Linhas 183–188 — `cardGradient`:**

```dart
  /// Intentionally flat — no visible gradient on cards/list items.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceSlate, surfaceSlate],
  );
```

É a origem literal do "formulário" apontado pela auditoria: as outras telas são chapadas **por regra**, não por descuido. Substituir por `bt.gradAzulejo` (o vidro do azulejo, 160°), mantendo o nome `cardGradient` como alias depreciado para não quebrar as 58 caixas chapadas de decks de uma vez.

**(3) Linhas 20–22 — o orçamento de cor:**

```dart
/// COLOR BUDGET (24 tokens):
///   10 brand/layout + 5 semantic + 6 WUBRG + 1 hint + 2 format extras = 24
///   Qualquer cor fora deste arquivo é violação.
```

O kit acrescenta 10 assentos + 11 cores de vitral + latão-claro + latão-rótulo + brasa-cheia + azulejo-repouso ≈ **25 valores novos**: o orçamento vai de 24 para ~50 e a frase que o fixa continua no arquivo. Texto novo proposto: `COLOR BUDGET: 24 tokens de produto + a paleta do kit BrewTact (bt_tokens.dart, docs/design/ui-kit-spec.md §3.2). Cor fora desses dois arquivos é violação.`

**(4) Linhas 717–731 e 858–872 — `inputDecorationTheme`:**

```dart
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceSlate,
    border: OutlineInputBorder(...),
    enabledBorder: OutlineInputBorder(...),
    focusedBorder: OutlineInputBorder(...),
  ),
```

É **exatamente** o que §6.4 proíbe ("nunca `InputDecoration` com `filled: true`, `border: OutlineInputBorder`") e exatamente o que o regex `\bOutlineInputBorder\b|filled:\s*true` de §9.1 pega — são os **8 ofensores** que fazem a guarda entrar vermelha (§9.3). Sem revogar isto, **todo `TextField` do app continua com caixa por padrão do tema**, mesmo depois de `AppPlaque` existir: a placa teria de desligar a caixa campo a campo. As duas declarações (tema claro e tema escuro) saem juntas quando a onda 6 entrar; até lá, `lib/core/theme/app_theme.dart` entra na lista de isenção de §9.2, como o teste de token já faz.

### 7.2 · Os tokens `lifeCounter*` sem uso

**A contagem, medida hoje, com o glob explícito.** A frase "52 dos 62 tokens `lifeCounter*`" vem de `docs/design/visual-audit-2026-09-21/README.md:92` e `:129`, que conta a família mais larga **`lifeCounter*` + `life*`** e inclui as faixas de linha 66–142, 297–302 e 316–329. Medindo em `app/lib/core/theme/app_theme.dart` (1.025 linhas) só pelo glob `*LifeCounter*`: há **47 declarações** (27 `lifeCounter*`, 14 `fontLifeCounter*`, 6 `radiusLifeCounter*`), das quais **37 não têm nenhum uso fora do próprio arquivo**. Os 10 usados: `fontLifeCounterInputValue`, `fontLifeCounterStormValue`, `lifeCounterBlack`, `lifeCounterPinkSoft`, `lifeCounterPinkSubtle`, `lifeCounterPinkText`, `lifeCounterSetLifeDanger`, `lifeCounterWhite`, `radiusLifeCounterLg`, `radiusLifeCounterSm`. Escrever as duas contagens, não uma só. Entre os sem uso:

- `lifeCounterPlayerColors` (:67-74) — 6 cores saturadas (`#FFB51E`, `#FF0A5B`, `#CF7AEF`, `#4B57FF`, `#44E063`, `#40B9FF`) que **não** são os 10 assentos do protótipo. **Substituir** pelos `bt.assento[10]`.
- `lifeCounterWinnerGradient` (:109) — arco-íris pastel de 4 paradas, fora da paleta. A auditoria já registra que recomendá-lo foi um erro. **Apagar**; o vencedor é `AppScoreRow` com aro de latão.
- `lifeCounterTieGradient`, `lifeCounterConfettiColors`, `lifeCounterHub*Gradient`, `lifeCounterSettings*` — herança do contador nativo antigo, conferidos um a um: nenhum tem uso fora do `app_theme.dart`. **Apagar.**
- **`lifeCounterPink*` NÃO pode ser apagado agora — o glob quebra o build.** `lifeCounterPinkSoft` está em uso em `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:467` e `:520`, `lifeCounterPinkSubtle` em `:511` e `lifeCounterPinkText` em `:514`. Só o `lifeCounterPink` puro está sem uso. **Marcar como "sai junto com a conversão de `life_counter_native_set_life_sheet.dart`"**, que é da sessão do protótipo, não desta fila.
- **`radiusLifeCounter*` fica.** `radiusLifeCounterXl` (:301), `radiusLifeCounterLg` (:299) e `radiusLifeCounterSm` (:297) são justamente os tokens que §3.1 aponta como a ponte já pronta para os raios 22/18/10 do kit. Apagá-los quebra §3.1.
- `fontLifeCounter*` (:316-329, de 13,4 a 246px) — declarados e quase todos sem uso. **Substituir** pela escala do kit (56/70/32/38/44/36/40/30/92/64) mais o numeral medido por contêiner, que não é constante.

A limpeza é a etapa 4 da **Onda 0** em `docs/design/sequencia-e-esforco.md`. Ela é separada da entrada do kit: apagar token sem uso e adicionar token novo são dois commits.

### 7.3 · Onde o kit mora

- `app/lib/core/theme/bt_tokens.dart` — os tokens novos, como `abstract final class BtColors` / `BtGradients` / `BtShadows` / `BtNumerals`, referenciando `AppTheme` sempre que o valor já existe (§3.1). **Não duplicar cor.**
- `app/lib/core/widgets/bt/` — as 5 primitivas e as 14 peças derivadas.
- `app/lib/core/theme/app_theme.dart` — continua sendo o único lugar com literal de cor (o teste de token exige).

**A contradição que precisa ser decidida antes de escrever a primeira linha.** As duas frases acima são incompatíveis: `bt_tokens.dart` "não duplica cor" e referencia `AppTheme`, mas os **~25 valores novos de §3.2** (10 assentos, 11 vitrais, latão-claro, latão-rótulo, brasa-cheia, azulejo-repouso) **não têm casa no `AppTheme`**. Ou:

- **(a)** os 25 entram em `app_theme.dart` e `bt_tokens.dart` vira só um conjunto de *alias* semânticos — respeita o teste de token como está, mas incha o arquivo que §7.2 está tentando limpar; ou
- **(b)** `bt_tokens.dart` tem literais de cor e **precisa entrar nas exceções de `app_theme_token_usage_test.dart`**, que hoje tem quatro caminhos além do próprio tema (`lib/features/scanner/`, `lib/features/home/life_counter/`, `lib/features/home/lotus/`, `lotus_life_counter_screen.dart`).

A spec **não escolhe** — a escolha é do dono e está em §11. O que não pode é a entrada começar sem a escolha feita, porque (a) e (b) produzem árvores de arquivo diferentes.

---

## 8 · Mapa de substituição — padrão antigo → peça nova

Toda linha tem um exemplo real, verificado por leitura no commit `d26f23a16`.

| Padrão antigo | Vira | Regra de conversão | Exemplo real no app |
|---|---|---|---|
| `DropdownButton` / `DropdownButtonFormField` | **Fileira de `AppChoiceTile`** (≤ 6 opções) · **`AppTileOverlay` de azulejos** (> 6) | A escolha escondida vira visível. Cada opção mostra o próprio valor dentro dela; a atual está em latão cheio. Nunca lista suspensa. | `binder_screen.dart:1838-1839` (condição) · `marketplace_screen.dart:416-417` · `battle_replays_screen.dart:1255` (objetivo do teste) |
| `SwitchListTile` / `Switch` | **`AppRuleTile`** | O interruptor vira peça que acende: apagada em vidro com a palavra `NÃO VALE`; acesa em latão com `VALE`. Estado em palavra, não em posição de botão. | `life_counter_native_turn_tracker_sheet.dart:202,228` · `life_counter_native_player_state_sheet.dart:369` |
| `Checkbox` / `CheckboxListTile` / `Radio` | **`AppRuleTile`** (consentimento) · **`AppChoiceTile`** (exclusivo) | Checkbox = regra que acende. Radio = fileira de peças com uma em latão. O rótulo legal continua legível: ele vira o título Inter 700 14px da peça. | `register_screen.dart:519` (consentimento do cadastro) |
| `SegmentedButton` | **`AppNumberTile`** (números) · **`AppShapeTile`** (formas) · **`AppChoiceTile`** (o resto) | 2–4 opções lado a lado, tamanhos diferentes, a escolhida em latão e **maior** (36→40px). Nunca uma barra dividida em partes iguais. | `life_counter_native_day_night_sheet.dart:120` (Sem/Dia/Noite — já existe como `.rt.sm` em `vt-04-regras.png`) · `battle_replays_screen.dart:3060` |
| Sopa de `Chip` / `FilterChip` / `ActionChip` | **`AppTile` pequeno em fileira** (filtro) · **`AppLogPills`** (informação passiva) | Chip que **faz** algo vira azulejo com ícone e estado. Chip que só **informa** vira pílula do histórico (Inter 600 12px, ardósia-850, raio 999). Nunca 11 chips iguais na mesma tela. | `binder_import_screen.dart:752,802,924` (11 chips: status + ação + filtro no mesmo lugar) |
| `FilledButton` largo | **`AppHeroTile`** (1 por tela) ou **`AppAction(principal)`** no rodapé | Se é a jogada principal, ganha numeral/nome/pips e vira herói. Se é só confirmar, vira a ação principal do rodapé — e aí a pergunta é por que precisa de confirmação (a escolha devia valer no toque). | `home_screen.dart:948,1332` · 35 ocorrências nos sheets do próprio contador |
| `ElevatedButton` *(36 ocorrências — a linha que faltava neste mapa)* | **`AppAction`** neutra no rodapé · **`AppTile`** quando a ação tem estado ou valor | `ElevatedButton` é o botão com sombra e cor de fundo do Material: é a caixa chapada com elevação, e o kit não tem elevação decorativa. Regra igual à do `FilledButton`, mas ele quase nunca é a jogada principal: por padrão vira ação **neutra**, e só vira herói se for mesmo a única jogada da tela. **Ele também não está no `_proibidos` de §9** — hoje atravessa o mapa e a guarda. | `deck_*` (17) · `trades` (5) · `community` (4) · `commercial` (3) · `binder` (2) · `retention` (2) · `profile`, `cards`, `scanner` (1 cada) |
| `OutlinedButton` | **`AppAction`** neutra (vidro escuro) ou **`AppTile`** | Contorno vira vidro escuro com filete marfim `.10`. Se a ação é importante o bastante para ter contorno, ela é um objeto. | `deck_workshop_tab.dart:600` ("Desfazer aplicação") |
| `TextButton` | **sobrevive** quando é navegação inline · **`AppAction` de brasa** quando destrói | Metade dos 122 são "ver mais"/"cancelar" e continuam como estão, com `AppTheme.accessibleTextButtonStyle`. Os destrutivos viram brasa com dois toques. | `profile_screen.dart` (13 ocorrências) |
| `showModalBottomSheet` | **`AppTileOverlay`** (`veil: folha`) | A folha que sobe vira tela sobre a superfície viva, com véu radial, blur 8px e **um único ✕**. O rodapé de ação fica fora da rolagem. | `life_counter_native_table_state_sheet.dart:11` · `life_counter_native_set_life_sheet.dart:12` · `life_counter_native_commander_damage_sheet.dart:12` |
| `showDialog` / `AlertDialog` | **`AppTileOverlay`** · **azulejo armado** quando é só confirmar | Diálogo de confirmação **não vira overlay**: vira o segundo toque no próprio objeto (`armed`). Diálogo com escolha vira overlay de azulejos. | `battle_replays_screen.dart:1544,5618,5690` · `deck_details_dialogs.dart` (22 `showDialog` em decks) |
| `ListTile` | **`AppTile`** (ação) · **`AppScoreRow`** (pessoa/valor) · **`AppChoiceTile`** (escolha com miniatura) | Ícone-esquerda / título / chevron-direita é a linha de configurações. Vira peça com o valor dentro. | `set_cards_screen.dart:430` · `life_counter_native_player_appearance_sheet.dart:1018` · `battle_replays_screen.dart:1868` |
| `ExpansionTile` | **`AppTile` que abre um `AppTileOverlay`** | Nada sanfona. O que estava escondido vira tela própria sobre a superfície viva; o azulejo mostra no canto de estado quantos itens há dentro. | `battle_replays_screen.dart:1164,3236,3461` (3 das 4 do battle) |
| `TabBar` | **Fileira de `AppTile`** com a aba atual em **latão cheio** | Abas em `1fr 1fr` com sublinhado viram 2–3 azulejos de tamanhos diferentes, a atual em latão. Nada de indicador deslizante. | `binder_screen.dart:108` (Tenho/Quero) · `collection_screen.dart:240` · `trade_inbox_screen.dart:74` |
| `Slider` | **Fileira de `AppNumberTile`** quando os valores são poucos · **`AppLiveBlock`** (− numeral +) quando são contínuos | Arrastar não mostra o valor até soltar. A peça-numeral mostra sempre. `.pl-count` do `plano.png` é exatamente esse controle. | `deck_optimize_sections.dart:168` · `battle_coach_screen.dart:2556` · `battle_replays_screen.dart:4567` |
| `PopupMenuButton` | **`AppTileOverlay`** com 2–4 azulejos | O menu de três pontinhos vira uma tela pequena sobre a superfície viva. Se só há uma opção, ela vira um azulejo direto e o menu some. | `deck_list_screen.dart:1046` · `chat_screen.dart:301` · `battle_replays_screen.dart:4520` |
| `TextField` / `TextFormField` | **`AppPlaque`** (§6) | Sem caixa, sem borda, sem rótulo flutuante: serifa 22px sobre um fio que acende em latão no foco. Senha e cadastro mantêm o campo e trocam a moldura. | `deck_generate_screen.dart:1204,1239` (prompt de IA) · `login_screen.dart:146,174` |

**Três padrões que o mapa não cobre — e que aparecem em quase toda tela de rede:**

| O que falta | Por que importa | Estado |
|---|---|---|
| **Texto corrido** | A escala tipográfica inteira é 9 / 10,5 / 11 / 11,5 / 12 / 13 / 14 / 17 / 22 / 30 px mais os numerais. O maior bloco de leitura previsto é o `AppHint` (Inter 500 12px/1.4), e §4.1e proíbe "azulejo com texto corrido". Ficam **sem token nenhum**: termos de uso, política de privacidade, texto de regras de carta (`features/cards`, `set_cards_screen`), descrição de deck e **a saída do gerador de IA — que é o produto de `deck_generate_screen.dart`**. §10.1 registra "lista longa" e não registrava "texto corrido longo". | **Buraco aberto**, §10.1 |
| **Link dentro de texto** | A linha `Checkbox`/`CheckboxListTile` manda `register_screen.dart:519` (consentimento do cadastro) virar `AppRuleTile`, cuja superfície inteira é **um alvo de toque só**. Um consentimento real é "Li e aceito os **Termos de Uso** e a **Política de Privacidade**" com dois links tocáveis dentro da frase — dentro de um `AppRuleTile` eles ficam inalcançáveis. O kit não tem `RichText`/`TextSpan` com `recognizer`, nem estilo de link, em lugar nenhum. **Trava justamente o consentimento legal que o mapa manda converter.** | **Buraco aberto**, §10.1 |
| **`SnackBar`, progresso bloqueante, *pull-to-refresh*, faixa de offline** | §8 proíbe `showDialog` sem oferecer substituto para o **diálogo de progresso bloqueante**. E o `SnackBar` — a superfície padrão de retorno do Material, presente em praticamente toda ação de rede — **não está neste mapa, não está na contagem de §8.1 e não estava nos limites de §10.1**. O mais próximo no protótipo é `AppLogPills`, que é passivo. | **Buraco aberto**, §10.1 |

### 8.1 · Contagem por feature

Copiada de [`docs/design/ui-kit/primitive-counts.json`](ui-kit/primitive-counts.json), **sem recontar**. É **contagem por expressão regular** sobre `app/lib`: conta ocorrências no código, não telas, e é um **teto aproximado** — a mesma tela pode aparecer em várias colunas e widget montado à mão não aparece em nenhuma.

| Área | Arq. | Linhas | Drop | DMenu | Sw | Chk | Seg | Chip | Fill | Elev | Out | Txt | Sheet | Dlg | Alert | Field | List | Exp | Tab | Slid | Pop | Σ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `features/decks` | 40 | 35.002 | 8 | · | 6 | 3 | · | 5 | 10 | 17 | 14 | 36 | 4 | 22 | 10 | 16 | 14 | 3 | 1 | 1 | 3 | **173** |
| `home/contador (life_counter+lotus)` | 54 | 23.959 | · | · | 4 | · | 1 | 7 | 35 | · | 18 | 17 | 15 | 3 | 3 | 8 | 1 | · | · | · | · | **112** |
| `features/battle` | 16 | 16.825 | 6 | · | · | · | 1 | · | 17 | · | 14 | 19 | · | 7 | 5 | 9 | 1 | 4 | · | 2 | 1 | **86** |
| `features/binder` | 8 | 8.443 | 4 | · | 3 | · | · | 11 | 7 | 2 | 9 | 7 | 1 | 3 | 3 | 6 | 1 | 1 | 1 | · | · | **59** |
| `features/profile` | 2 | 2.446 | 2 | · | · | · | · | · | 6 | 1 | 3 | 13 | · | 6 | 6 | 10 | 1 | · | · | · | · | **48** |
| `features/trades` | 7 | 5.931 | 1 | · | · | · | · | 1 | 1 | 5 | 1 | 7 | 1 | 3 | 3 | 4 | 1 | · | 2 | · | · | **30** |
| `features/social` | 4 | 3.033 | 1 | · | · | · | · | · | 3 | · | 1 | 3 | 1 | 2 | 2 | 2 | 4 | · | 2 | · | 1 | **22** |
| `features/auth` | 13 | 3.177 | · | · | · | 1 | · | · | 4 | · | 1 | 6 | · | · | · | 9 | · | · | · | · | · | **21** |
| `features/community` | 3 | 3.785 | 1 | · | · | · | · | 1 | 1 | 4 | 1 | 1 | · | 1 | 1 | 3 | 3 | · | 2 | · | 1 | **20** |
| `features/home` | 5 | 9.220 | 1 | · | · | · | · | 1 | 5 | · | 3 | 4 | 1 | · | · | · | · | · | · | · | · | **15** |
| `features/retention` | 3 | 2.844 | · | · | · | · | · | 3 | 1 | 2 | 1 | 3 | · | · | · | 4 | · | · | · | · | · | **14** |
| `features/messages` | 3 | 1.389 | · | · | · | · | · | · | 1 | · | · | 1 | · | 1 | 1 | 1 | 3 | · | · | · | 1 | **9** |
| `features/cards` | 5 | 3.914 | · | · | · | · | · | · | 2 | 1 | 1 | · | 1 | 2 | · | 1 | · | · | 1 | · | · | **9** |
| `features/commercial` | 11 | 1.538 | · | · | · | · | · | · | · | 3 | 1 | 3 | · | 1 | 1 | · | · | · | · | · | · | **9** |
| `features/collection` | 6 | 1.785 | · | · | · | · | · | 1 | · | · | · | · | · | · | · | 1 | 2 | · | 1 | · | · | **5** |
| `features/scanner` | 11 | 4.587 | · | · | · | · | · | · | · | 1 | 1 | 1 | · | · | · | 1 | · | · | · | · | · | **4** |
| `core` | 35 | 8.636 | · | · | · | · | · | · | 1 | · | 1 | · | · | · | · | · | · | · | · | · | · | **2** |
| `features/notifications` | 3 | 762 | · | · | · | · | · | · | · | · | · | 1 | · | · | · | · | · | · | · | · | · | **1** |
| `main.dart` · `firebase_options.dart` · `features/growth` · `features/market` | 6 | 1.613 | · | · | · | · | · | · | · | · | · | · | · | · | · | · | · | · | · | · | · | **0** |
| **Total** | **235** | **138.889** | **24** | **·** | **13** | **4** | **2** | **30** | **94** | **36** | **70** | **122** | **24** | **51** | **35** | **75** | **31** | **8** | **10** | **3** | **7** | **639** |

Legenda: Drop=`DropdownButton` · DMenu=`DropdownMenu` (existe em `primitive-counts.json`, é **0 em todas as 22 áreas** e faltava nesta tabela — a cópia precisa ser fiel) · Sw=`Switch`/`SwitchListTile` · Chk=`Checkbox`/`Radio` · Seg=`SegmentedButton` · Fill=`FilledButton` · Elev=`ElevatedButton` · Out=`OutlinedButton` · Txt=`TextButton` · Sheet=`showModalBottomSheet` · Dlg=`showDialog` · Alert=`AlertDialog` · Field=`TextField`/`TextFormField` · List=`ListTile` · Exp=`ExpansionTile` · Tab=`TabBar` · Slid=`Slider` · Pop=`PopupMenuButton`.

**Leitura:** 639 ocorrências, das quais **112 estão nos sheets nativos do próprio contador** — que contradizem a régua do contador e estão sendo convertidos pela sessão do protótipo. As 527 restantes são as 949 pontos de esforço de `docs/design/sequencia-e-esforco.md`.

---

## 9 · Guarda de regressão

Sem um teste, a régua volta a depender de revisão manual e o app volta a ser formulário no próximo PR. O molde é `app/test/core/theme/app_theme_token_usage_test.dart`, que já usa exatamente esta forma: varre `lib`, acumula ofensores como `caminho:linha: trecho`, e falha com `expect(offenders, isEmpty)`.

### 9.1 · O teste proposto

`app/test/core/widgets/bt_kit_adoption_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Padrões da linguagem antiga. Cada um tem uma peça do kit que o substitui
/// (docs/design/ui-kit-spec.md §8). A lista de exceções encolhe a cada onda
/// convertida de docs/design/sequencia-e-esforco.md.
const _proibidos = <String, String>{
  r'\bshowModalBottomSheet\b': 'AppTileOverlay(veil: folha)',
  r'\bshowDialog\b': 'AppTileOverlay ou azulejo armado (2 toques)',
  r'\bAlertDialog\b': 'AppTileOverlay ou azulejo armado (2 toques)',
  r'\bDropdownButton(FormField|HideUnderline)?\b': 'fileira de AppChoiceTile',
  r'\bSwitchListTile\b|\bSwitch\.adaptive\b|(?<!Animated)\bSwitch\(': 'AppRuleTile',
  r'\bCheckboxListTile\b|\bCheckbox\(|\bRadioListTile\b|\bRadio<': 'AppRuleTile / AppChoiceTile',
  r'\bSegmentedButton<': 'AppNumberTile / AppShapeTile',
  r'\bExpansionTile\b': 'AppTile que abre AppTileOverlay',
  r'\bSlider\(': 'AppNumberTile ou AppLiveBlock',
  r'\bPopupMenuButton<': 'AppTileOverlay pequeno',
  r'\bTabBar\(': 'fileira de AppTile (a atual em latão)',
  r'\bListTile\(': 'AppTile / AppScoreRow / AppChoiceTile',
  r'\b(Filter|Action|Input|Choice)?Chip\(': 'AppTile pequeno ou AppLogPills',
  r'\bTextFormField\(|\bTextField\(': 'AppPlaque',
  // Material puro que o kit substitui por superfície própria
  r'\bOutlineInputBorder\b|filled:\s*true': 'AppPlaque: campo sem caixa',
};

void main() {
  test('features convertidas não voltam à linguagem antiga', () {
    final offenders = <String>[];
    final regras = {
      for (final e in _proibidos.entries) RegExp(e.key): e.value,
    };

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll('\\', '/');
      if (_isento(path)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final entry in regras.entries) {
          if (entry.key.hasMatch(line)) {
            offenders.add('$path:${i + 1}: ${line.trim()}  →  use ${entry.value}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use as peças do kit (docs/design/ui-kit-spec.md §8). Se a tela ainda '
          'não foi convertida, ela precisa estar em _isento() — e sair de lá '
          'quando a onda dela for feita.',
    );
  });

  test('a lista de isenção só encolhe', () {
    // Trava de catraca: o número NASCE igual ao comprimento atual da lista
    // e só desce. Com teto de 48 sobre uma lista de 24, qualquer PR poderia
    // isentar 24 caminhos novos sem o teste piscar — que é exatamente o
    // buraco que §9.3 item 3 diz que esta catraca existe para fechar.
    expect(_isentos.length, lessThanOrEqualTo(24));
  });
}
```

### 9.2 · A lista de exceções inicial

Hoje **nada** em `app/lib` usa o kit, então a lista inicial precisa cobrir tudo que existe — e a catraca do segundo teste é o que faz ela encolher. Ela é por **caminho**, não por arquivo solto, para não virar uma lista de 200 linhas:

```dart
const _isentos = <String>[
  // ── O próprio tema. O molde (app_theme_token_usage_test.dart:37) já o
  //    isenta pelo mesmo motivo: é onde InputDecorationTheme legitimamente
  //    mora. Sai quando a revogação (4) de §7.1 entrar.
  'lib/core/theme/app_theme.dart',

  // ── Sistemas visuais independentes (já isentos no teste de token) ──
  'lib/features/scanner/',
  'lib/features/home/lotus/',
  'lib/features/home/lotus_life_counter_screen.dart',

  // ── Sheets nativos do contador: 112 ocorrências, convertidos pela
  //    sessão dona do protótipo, não por esta fila. Saem quando ela terminar.
  'lib/features/home/life_counter/',

  // ── Onda 1 — porta de entrada (sai primeiro) ──
  //    ATENÇÃO: 'lib/features/decks/' (abaixo) já cobre os três arquivos de
  //    decks desta onda. Eles ficam aqui como DOCUMENTO da onda, e por isso
  //    a onda 1 não encolhe a lista do lado de decks — quem encolhe é a
  //    onda 2. Se a catraca precisar de folga, são estes três que saem.
  'lib/features/home/onboarding_core_flow_screen.dart',
  'lib/features/decks/screens/deck_generate_screen.dart',   // ⊂ decks/
  'lib/features/decks/widgets/ai_usage_gate.dart',          // ⊂ decks/
  'lib/features/decks/widgets/ai_usage_meter.dart',         // ⊂ decks/
  'lib/features/home/home_screen.dart',

  // ── Onda 2 — núcleo (decks) ──
  'lib/features/decks/',            // 173 ocorrências, 40 arquivos

  // ── Onda 3 — coleção ──
  'lib/features/binder/',
  'lib/features/collection/',

  // ── Onda 4 — social e trocas ──
  'lib/features/trades/',
  'lib/features/social/',
  'lib/features/community/',
  'lib/features/messages/',

  // ── Onda 5 — battle ──
  'lib/features/battle/',

  // ── Onda 6 — conta, planos e entrada.
  //    Formulário é legítimo em login/senha/legal: o que muda é a moldura.
  //    Estes NÃO saem inteiros — só os padrões que não são campo de texto.
  'lib/features/auth/',
  'lib/features/profile/',
  'lib/features/commercial/',

  // ── Pega carona no kit, sem redesenho dedicado ──
  'lib/features/cards/',
  'lib/features/retention/',
  'lib/features/notifications/',
];

bool _isento(String path) => _isentos.any(path.startsWith);
```

### 9.3 · Como o teste é usado

1. **Entra vermelho-zero — depois de isentar o tema.** Rodei o algoritmo de §9.1 com os 15 regexes e a lista de §9.2 **sem** `lib/core/theme/app_theme.dart` sobre a árvore real: **8 ofensores**, todos em `app/lib/core/theme/app_theme.dart` — linhas **718, 720, 724, 728, 859, 861, 865, 869** (`filled: true` e `OutlineInputBorder` dentro dos dois `InputDecorationTheme`). A afirmação anterior ("com a lista acima o teste passa no primeiro dia") era falsa. Com o `app_theme.dart` na lista — como o molde `app_theme_token_usage_test.dart:37` já faz —, ou depois da revogação (4) de §7.1, aí sim entra verde. **Bom sinal do resto:** fora isso a varredura ficou limpa, inclusive `features/home` fora dos arquivos isentos, e não existe `RawChip` no repositório.
2. **Cada onda convertida remove um caminho** da lista e baixa o número da catraca. O PR que converte `home_screen.dart` é o mesmo que tira a linha dele.
3. **A catraca é o que dá o dente:** sem o segundo teste, alguém adiciona um caminho novo e a régua evapora em silêncio.
4. **Falsos positivos conhecidos:** `TabBar(` pega `TabBarView(`? Não — o regex é `\bTabBar\(`, e `TabBarView(` não casa. `Chip(` pega `_CoachTrustChip(` (`battle_coach_screen.dart:793`), que é classe privada da feature: por isso o regex só aceita os prefixos do Material (`Filter|Action|Input|Choice` ou nada) **precedido de `\b`**, e `_CoachTrustChip` não casa `\bChip\(`. Estes dois foram conferidos no código; os demais precisam de uma primeira rodada real.
   - **Correção:** a explicação do `AnimatedSwitcher` estava errada. A spec dizia "`Switch(` pegaria `AnimatedSwitcher(`? Não — está com `(?<!Animated)`". Não é por isso: `AnimatedSwitcher(` contém a sequência `Switcher(`, **não** `Switch(`, então `\bSwitch\(` nunca casaria de qualquer jeito; e mesmo que casasse, não há fronteira de palavra entre o `d` de `Animated` e o `S` de `Switch`. **O `(?<!Animated)` não exerce função nenhuma** — é código morto que dá ao regex mais crédito do que ele merece. Pode sair.
5. **Metade do mapa fica de fora da guarda, e isso precisa estar escrito.** `_proibidos` tem regra para Sheet (24), Dlg (51), Alert (35), Drop (24), Sw (13), Chk (4), Seg (2), Exp (8), Slid (3), Pop (7), Tab (10), List (31), Chip (30) e Field (75) = **317 ocorrências**. Ficam **fora** da guarda `FilledButton` (94), `ElevatedButton` (36), `OutlinedButton` (70) e `TextButton` (122) = **322** — **mais da metade das 639**, todas mapeadas em §8 e nenhuma vigiada. Como esses quatro são os padrões mais fáceis de reintroduzir num PR, a catraca não protege o que mais importa. Não dá para simplesmente proibi-los (o próprio §8 diz que metade dos 122 `TextButton` **sobrevive** como navegação inline), então o complemento é o do item 6.
6. **O que o teste NÃO pega:** tela que fez as próprias linhas de formulário à mão — `_GoalRail`, `_GoalRow`, `_BuildModeTile` do onboarding. Esse é o ponto cego já registrado em `sequencia-e-esforco.md`, e ele continua dependendo do olho. **Complemento sugerido:** um segundo teste que falhe quando um arquivo de feature declara `BoxDecoration` com `color:` e sem `gradient:` acima de N vezes — a assinatura da "caixa chapada". É também a única forma proposta de cobrir os 322 botões do item 5, porque ela pega a *superfície*, não o nome da classe. **Ainda não medido**; fica como proposta, e a spec não afirma que ele entraria verde.

---

## 10 · Limites conhecidos

### 10.1 · O que o kit não cobre

| Buraco | Por quê | O que fazer |
|---|---|---|
| **Peça de duas faixas** | `w4-04-dano-nas-duas-faixas.png` mostra o card do jogador dividido em duas faixas de dano simultâneo. O kit tem a peça inteira e a peça com miniatura, não a peça partida. | Extrair de `mesa-brewtact.html` quando a sessão do protótipo estabilizar a tela. |
| **Teclado de vida** | Segundo o README do protótipo, a tela do teclado ainda está na linguagem antiga. Um teclado numérico é a antítese de "objeto, não campo" e não tem resposta no mapa hoje. | Esperar a conversão. Até lá, entrada numérica usa `AppNumberTile` para valores comuns e `AppLiveBlock` (− numeral +) para o resto. |
| **Numeral medido por contêiner** | `AppNumeral.mesa` depende de `container-type: size` (CSS `cqh`/`cqw`). Flutter não tem query de contêiner: precisa de `LayoutBuilder` em cada card, e o resultado não é idêntico — `cqh` mede o **contêiner de consulta**, `LayoutBuilder` mede as **constraints**, que num `Flex` podem ser infinitas. | Provar num widget-test com três tamanhos de card antes de assumir paridade. É o item de maior risco técnico da Onda 0. |
| **Fio da placa em repouso** | `rgba(243,239,227,.22)` sobre obsidiana = **1,84**, abaixo de 3,0 para componente não-textual (WCAG 1.4.11). Subir para `.35` dá **2,91** (a spec publicava "≈2,6", que não reproduz), ainda abaixo — por 0,09. | Decisão do dono em §11: `.45` (4,08) resolve o número mas engrossa o fio; ou o campo ganha um segundo indicador de limite. **Defeito herdado do protótipo.** |
| **Tinta sobre vitral e sobre assento** | Marfim reprova no **estado 17px** de `iniciativa` (4,10), `brasa-cheia` (4,14), `coroa` (3,44) e `dia` (2,68), e no ícone de `coroa` (2,81) e `dia` (2,29). A regra `inkFor(c)` da versão anterior, aplicada como estava escrita, **virava 13 dos 16 vitrais para obsidiana** e apagava o card do jogador — está revogada (§4.1f). | §11: a proposta medida é `inkFor` só para `dia` + estado em 19px (vira texto grande, mínimo 3,0). Precisa do aval do dono porque muda o desenho da régua em dois pontos. |
| **Alvo de 48dp no Android** | ✕ do cabeçalho (44), seta de volta (44), swatches (44), ação do rodapé (46), **o `pad` do `AppLiveBlock`** (`min-height 44`, §5) e **o olho de mostrar/esconder senha** de `AppPlaque.obscured` (`AppTile` redondo 44×44, §6.2) — os dois últimos faltavam nesta lista. | Crescer o alvo com `Padding` transparente + `ConstrainedBox(minWidth: 48, minHeight: 48)` — **não** `MaterialTapTargetSize`, que é no-op fora de botão do Material. Resolvido no código, não na régua. |
| **Texto corrido longo** | A escala para no `AppHint` (Inter 500 12px/1.4) e §4.1e proíbe azulejo com texto corrido. Termos de uso, política de privacidade, regras de carta, descrição de deck e **a saída do gerador de IA** ficam sem token de parágrafo. | Precisa de um `AppProse` nascido da régua (a placa é a única superfície de texto que o protótipo tem, e ela é de **uma linha**). Não inventar antes de a sessão do protótipo desenhar uma tela de leitura. |
| **Link dentro de texto** | Não existe estilo de link nem `RichText`/`TextSpan` com `recognizer` em lugar nenhum do kit. Trava o consentimento legal de `register_screen.dart:519`, que §8 manda virar `AppRuleTile` — uma superfície com **um** alvo de toque. | O consentimento precisa de dois alvos dentro da frase. Ou o `AppRuleTile` ganha um slot de texto rico com alvos próprios, ou o consentimento é a exceção declarada em que a peça não se aplica. Decisão em §11. |
| **`SnackBar`, progresso bloqueante, *pull-to-refresh*, faixa de offline** | Nenhum dos quatro está no mapa de §8, na contagem de §8.1 ou no kit. O `SnackBar` é a superfície padrão de retorno de toda ação de rede do app. | O mais próximo no protótipo é `AppLogPills` (passivo). Precisa nascer da régua. Até lá, o `SnackBar` do Material continua, e isso é dívida conhecida, não omissão. |
| **Custo do `BackdropFilter`** | A regra 5 de §2 põe blur em **toda** tela secundária, sobre uma mesa animando. `BackdropFilter` força um `saveLayer` da tela inteira por frame. | **Medir antes** de virar padrão de 500+ telas. Item de Onda 0, junto com o numeral por contêiner. |
| **RTL** | Nada no kit está declarado como direcional e tudo é direcional: gradientes a 158°/160°, ícone no alto à esquerda, rótulo embaixo à esquerda, estado à direita, seta `‹`, `padding 12px 10px 6px 18px`. | `EdgeInsetsDirectional` em todo padding, ângulos espelhados (158°→202°), seta espelhada. **Não medido, não provado.** |
| **Alto contraste, inversão e transparência reduzida** | §4.1f agora cobre `highContrast` e `boldText`. `invertColors` (Smart Invert do iOS) destrói uma linguagem de gradiente escuro, e o Flutter **não** expõe `prefers-reduced-transparency` em `MediaQueryData` — o kit inteiro é blur + rgba + véu. | Inversão: limite aceito, sem compensação. Transparência reduzida: ou se assume o custo, ou se abre um canal de plataforma. Decisão em §11. |
| **Tema claro** | O kit é `color-scheme: dark`. As 439 capturas do repo são escuras; ninguém sabe como o app está no claro. | Fora de escopo. Se o tema claro existir, o kit precisa de uma segunda rodada inteira. |
| **Lista longa** | O board é grade visível de uma vez. Uma lista de 300 cartas do fichário não é board e o kit não tem resposta. | A peça de lista longa precisa nascer da régua, não do Material. Ainda não existe no protótipo. |
| **Movimento** | O kit só tem `fade .16s`, `scale .97` no toque e a varredura de carregando. Nenhuma transição entre telas, nenhuma animação de valor. | O protótipo também não tem. Não inventar. |

### 10.2 · O que muda quando a sessão do protótipo converter mais telas

O README do protótipo mudou **duas vezes durante a escrita desta spec**. Em 2026-09-21 19:32 ele passou a registrar **Plano** e **Turnos e tempo** como convertidos, com duas provas novas (`plano.png`, `vt-08-turnos.png`) e **quatro peças reutilizáveis novas** que `kit.css` e `tokens.json` **não contêm**:

| Peça nova | Prova | Impacto nesta spec |
|---|---|---|
| **Contador com ± e numeral** (`.pl-count`) | `plano.png` (CAOS: − 1 +) | É `AppLiveBlock` sem a cor do dono. Substitui `Slider` em §8. **Valores não extraídos.** |
| **Barra de proporção por pessoa** (`.tn-p`) | `vt-08-turnos.png` | **Não tem equivalente no kit.** Nome + barra na cor do jogador + valor `tabular-nums`, com halo de latão e `NA VEZ` na linha ativa. É a peça que faltava para gráfico/proporção fora do contador. |
| **Herói de comando** (`.tn-hero`) | `vt-08-turnos.png` | Estende `AppHeroTile` com `subtitle` e até 2 ações secundárias escavadas. Já está na API de §4.5d, **sem os valores medidos**. |
| **Modo ligado/desligado** (`.rt` em `.pl-modes`) | `plano.png` (Planechase LIGADO / Arqui-inimigo DESLIGADO) | Confirma `AppRuleTile` como substituto de `Switch`. Nenhuma mudança. |

O protótipo também **corrigiu o defeito `--frost-400`** que esta sessão reportou em `docs/design/ui-kit/NOTAS-PARA-O-PROTOTIPO.md`: a checagem 75 da suíte agora compara todo `var(--x)` com o que está declarado. `--bt-gelo-400` (`#6FA8DC` → `AppTheme.frost400`) deixa de ser divergência arbitrada e passa a ser valor do protótipo.

**Ainda na linguagem antiga** (README de 19:32): Partidas guardadas, escolha de peça, teclado de vida e resumo.

**O que isso quer dizer para a implementação:** as **cinco primitivas são estáveis** — as quatro peças novas são composições delas, não primitivas novas, e é exatamente o que esta spec previa. O que muda é a lista de peças derivadas (§5) e os valores de três delas. **Antes de abrir a Onda 0, reextrair `kit.css` e `tokens.json` de `mesa-brewtact.html`** e conferir se `.pl-count`, `.tn-p` e `.tn-hero` cabem nas primitivas sem forçar. Se `.tn-p` não couber, ela é a sexta primitiva.

### 10.3 · Divergências arbitradas que continuam de pé

Todas resolvidas a favor de `mesa-brewtact.html`, conforme a regra escrita em `tokens.json`. Se o dono quiser o desenho do mock, quem muda é o protótipo — não o kit.

| O quê | `vitral/menu.html` | **Adotado** |
|---|---|---|
| Eixo óptico do numeral | `"opsz" 144` | `auto` |
| 4 assentos (brasa/âmbar/musgo/maré) | `#B5402B` `#94621A` `#3E7A4C` `#1F6F8C` | `#A83A27` `#855614` `#356B45` `#1D6985` |
| Padding do azulejo | `13px 14px 12px` | `12px 14px 11px` |
| Numeral do herói | 78px | **70px** |
| Peça-numeral | 82×68, numeral 44/50 | **70×58**, numeral 36/40 |
| Tracejado do "sem dono" | `rgba(224,169,59,.55)` | `rgba(224,169,59,.5)` |
| Pips de ordem | 14 / 30px | **13 / 28px** |
| Botão redondo do herói | 58px | **56px** |
| Nome do herói | 34px | **30px** |
| **Ícone do azulejo** *(faltava)* | `.ic` 38×38 (`menu.html:44`) | **34×34** (`.menu .t .ic`, :301) |
| **Numeral da peça de escolha** *(faltava)* | `.p .num` 40 → 46 quando selecionada (`menu.html:116,121`) | **38 → 44** (`mesa-brewtact.html:372, 375`) |
| **Rótulo do herói** *(faltava)* | `.hero .lb` com `font-size: 12px` (`menu.html:66`) | **herda 11,5px** (`.menu .hero .lb` só tira o `text-shadow`) |
| **Geometria do herói** *(faltava)* | gap 14 · padding `12 16 12 18` · `.mid` padding-left 14 · `.turno` gap 7 · `.ordem` gap 6 (`menu.html:60-68`) | **gap 12 · padding `10 14 10 16` · padding-left 12 · gap 6 · gap 5** (`mesa-brewtact.html:323-333`) |
| **Aparência da peça-numeral selecionada** *(faltava — e é a mais visível)* | `.v.on` é **vitral de brasa com tinta marfim** (`menu.html:134,136`): é o `40` vermelho de aro branco de `jogadores.png` | **latão-peça com tinta obsidiana** (`mesa-brewtact.html:393,395`): é o `10` dourado de `vt-04-regras.png` |

A linha "Peça-numeral" acima registrava só o **tamanho** (82×68 → 70×58, numeral 44/50 → 36/40). A troca de **cor e de tinta** é o que o olho vê em um segundo e não estava no livro-caixa.

O `opsz` é o que mais muda o olho: em `jogadores.png` (144) o numeral tem hairline fina e contraste alto; em `vt-04-regras.png` (`auto`) o mesmo `20` de 36px sai bem mais encorpado. São dois desenhos da mesma fonte, e o kit adotou o segundo.

---

## 11 · Decisões em aberto para o dono

> **Nota de 2026-09-22 (coordenação).** O protótipo mudou depois desta seção. Medido com `life-counter-prototype/tools/contrast.py` em 2026-09-22, os 43 pares estão todos no mínimo: ícone da `coroa` 3,49 (o vitral da coroa escureceu para `#8A5E18` → `#46270E`), fio da placa 4,09 (`.45`, 2px) e "Concedeu" 10,27, agora em vinho `#6E1B2A`, a ΔE ≥ 25 de toda cor de jogador. A7, C2/C3, D1 e E1 estão resolvidos no protótipo e foram **ratificados pelo dono em 2026-09-22** (D-44 em `docs/status/DECISOES_PENDENTES_2026-09-22.md`). Na mesma data ele aprovou as saídas derivadas A1–A6, A8, B1–B3 e C1 (pela saída ii) e decidiu F1 (literais de cor no `app_theme.dart`), F2 (estado em segunda linha acima de 160%), F3 (custo da transparência assumido na beta), F4 (`AppRuleTile` com texto rico e alvos próprios), F5 e F6 (alinhados à régua: traço 2, raio 12), com alvo de toque de 48 dp. As tabelas abaixo guardam as contas antigas, como histórico.

**Nada aqui foi mudado no protótipo.** Esta seção é o lugar onde cada contraste que não passa fica registrado com o **par**, a **razão calculada** e a **saída proposta** — para o dono decidir. Método: fórmula WCAG 2.x (luminância relativa), com o gradiente amostrado **no ponto onde o texto realmente cai** (projeção do slot sobre o eixo de 158°, §4.1f), não na parada do meio. Toda saída marcada **DERIVADO** é invenção do kit e precisa de aval antes de entrar em `app/lib`.

Limiares usados: texto normal **4,5** · texto grande (≥ 18,66px em negrito ou ≥ 24px) **3,0** · componente não-textual **3,0** (WCAG 1.4.3 e 1.4.11).

### 11.1 · Tinta sobre vitral aceso — o azulejo (§4.1f)

| # | Par exato | Razão | Limiar | Saída proposta |
|---|---|---:|---:|---|
| **A1** | palavra de estado, marfim `#F3EFE3`, Fraunces **700 17px**, sobre `coroa` `#9A6A1E` na zona do estado | **3,44** | 4,5 | **Peso/tamanho maior:** estado sobe de 17px para **19px** Fraunces 700. Acima de 18,66px em negrito o limiar cai para 3,0 e o par passa sem trocar cor. **DERIVADO** (o protótipo tem 17px) |
| **A2** | idem, sobre `iniciativa` `#2F6C8C` | **4,10** | 4,5 | Mesma saída A1 → passa com folga |
| **A3** | idem, sobre `brasa-cheia` `#B5402B` | **4,14** | 4,5 | Mesma saída A1 → passa com folga |
| **A4** | idem, sobre `dia` `#3E8FC9` | **2,68** | 4,5 | **Tom alternativo:** tinta **obsidiana** `#0B0D12` só neste vitral → **5,78**. É a única troca de tinta que o kit propõe. **DERIVADO** |
| **A5** | rótulo marfim Inter **800 11,5px** sobre `dia`, zona do rótulo | **2,43** | 4,5 | Mesma saída A4 (obsidiana) → **6,23** |
| **A6** | ícone marfim `stroke 1.9` 34×34 sobre `dia`, zona do ícone (debaixo do brilho 115°) | **2,29** | 3,0 | Mesma saída A4 (obsidiana) → **7,39** |
| **A7** | ícone marfim sobre `coroa`, zona do ícone | **2,81** | 3,0 | **Sem saída boa.** Obsidiana no ícone de `coroa` daria 6,02 **mas exigiria trocar a tinta do rótulo também** (que em marfim está em 5,97 e passa), e aí `coroa` vira um vitral de tinta escura — o que o protótipo não é. Alternativas: (i) aceitar 2,81 como limite conhecido, a 0,19 do mínimo; (ii) escurecer a parada de topo da `coroa` de 78% para **66%** de branco, o que sobe o ícone para ~3,4 e é mudança **no protótipo**, não no kit. **Decisão do dono.** |
| **A8** | estado desligado, névoa-fraca `#8A93A3` 10,5px, sobre azulejo com a **mesa colorida atravessando o véu `.42`** do board | **3,73 – 4,24** | 4,5 | **Tom alternativo:** dentro de `AppTileBoard(veil: true)` o estado desligado usa `--bt-nevoa` `#B8C0CC` em vez de `--bt-nevoa-fraca`. **DERIVADO** |

**O que fica decidido sem o dono:** a regra `inkFor(c)` como estava escrita **está revogada** — ela virava 13 dos 16 vitrais para obsidiana, incluindo 9 dos 10 assentos, e no fim do gradiente do assento a obsidiana cai para **1,82–1,88**, apagando nome e vida do jogador em `AppScoreRow` e `AppLiveBlock`. Isso não é decisão de acessibilidade, é defeito, e sai.

### 11.2 · Tinta escura sobre latão (§4.5f, §5.1)

| # | Par exato | Razão | Limiar | Saída proposta |
|---|---|---:|---:|---|
| **B1** | `.bt-rule--on .bt-rule__st` — a palavra **`VALE`** de `vt-04-regras.png`, `rgba(11,13,18,.72)` Inter **800 11px**, sobre `#C58B2A` (fim do latão-peça) | **4,30** | 4,5 | **Opacidade 1** (obsidiana cheia) → **6,57**. Custo visual quase nulo; é a correção mais barata da spec |
| **B2** | `.bt-tile--sel .bt-tile__sub` — subrótulo do azulejo selecionado, `rgba(11,13,18,.7)` Inter **700 11px**, canto inferior esquerdo | **4,12** | 4,5 | **Opacidade 1** → 6,57 |
| **B3** | legenda do herói `rgba(11,13,18,.7)` Inter 700 11px **se chegar ao fim do gradiente** | **4,12** | 4,5 | Já resolvido pelo desenho (ela mora no canto superior esquerdo, onde dá **6,01**). A **regra escrita** é a saída: texto a `.7` de obsidiana só na metade superior-esquerda de latão |

### 11.3 · Peças derivadas (§5.1)

| # | Par exato | Razão | Limiar | Saída proposta |
|---|---|---:|---:|---|
| **C1** | `.bt-live__cap` — a legenda `VIDA · COMEÇOU COM 40` de `vt-05-jogador.png`, `rgba(243,239,227,.8)` Inter **800 11px**, no **topo clareado** do assento (`mix(c, #fff, 80%)`) | **3,40 – 4,94** · reprova em **9 dos 10 assentos** | 4,5 | Três saídas, em ordem de custo: **(i) opacidade 1** sobe para **4,36 – 6,75** e ainda deixa `maré` 4,36, `musgo` 4,41 e `âmbar` 4,43 marginalmente abaixo; **(ii) opacidade 1 + mover a legenda para fora do canto mais claro** (ela é a primeira linha de um `grid`, basta inverter com o numeral) resolve os dez; **(iii)** escurecer a parada de topo de 80% para **70%** de branco — mudança **no protótipo**. Proposta do kit: **(ii)**, marcada **DERIVADO** |
| **C2** | `.rt.bad.on b` — título marfim Inter **700 14px** da peça `Concedeu` em brasa cheia, faixa **superior** da peça de 96px | **3,27** · **2,70** com o brilho diagonal | 4,5 (14px negrito **não** é texto grande) | **Peso/tamanho maior não resolve sozinho** (precisaria ir de 14px para 18,66px, que quebra a peça de 96px). Proposta: **escurecer a parada de topo da brasa cheia de 78% para 66% de branco** — sobe o título para ~4,6 e o ícone junto. É mudança **no protótipo** (`.rt.bad.on`, `mesa-brewtact.html:466`), por isso está aqui e não foi aplicada |
| **C3** | `.rt.bad.on .st` — palavra de estado da mesma peça, `rgba(243,239,227,.8)` Inter 800 11px, topo | **2,64** · **2,25** com o brilho | 4,5 | **Opacidade 1** (marfim cheio) sobe para 3,27/2,70 — **ainda reprova**. Só a saída de C2 resolve. Os dois andam juntos |

**Nota sobre a prova.** O estado aceso de `.rt.bad.on` **não aparece em nenhuma prova de aparelho** (em `vt-05` a peça `Concedeu` está apagada, em `JOGANDO`). Os números de C2 e C3 saem do CSS. Antes de decidir, vale pedir à sessão do protótipo uma captura com a peça acesa.

### 11.4 · A placa (§6.4)

| # | Par exato | Razão | Limiar | Saída proposta |
|---|---|---:|---:|---|
| **D1** | fio em repouso `rgba(243,239,227,.22)` sobre obsidiana `#0B0D12` | **1,84** | 3,0 (componente não-textual, WCAG 1.4.11) | `.35` → **2,91** (a spec publicava "≈2,6"; a conta não reproduzia). Ainda reprova, por **0,09**. `.45` → **4,08**, passa, mas engrossa visualmente o fio. Alternativa sem mexer na cor: **um segundo indicador de limite** (o rótulo em caixa alta já é fixo acima; bastaria ele ficar em `--bt-nevoa` em vez de névoa-fraca e ganhar um ponto de latão à esquerda no foco). **Decisão do dono: `.45` ou o segundo indicador.** Defeito herdado do protótipo |

### 11.5 · Colisão de significado (§1)

| # | Par exato | Razão | Limiar | Saída proposta |
|---|---|---:|---:|---|
| **E1** | `--bt-brasa-cheia` `#B5402B` (estado ruim valendo) contra `--bt-assento-brasa` `#A83A27` (o jogador vermelho), lado a lado | **1,13** entre as duas | 3,0 para distinguir dois significados por cor (WCAG 1.4.11) | Duas saídas: **(i)** afastar a brasa cheia do assento brasa (escurecer para `#8E2F1E`, contraste 1,5 — ainda insuficiente; ou ir para um tom claramente distinto); **(ii)** regra de composição: **brasa cheia nunca aparece na mesma tela que um card do jogador brasa**. §10.3 já registra que o kit adotou `#A83A27` para o assento e deixou `#B5402B` no vitral — a colisão é consequência conhecida e continua sem regra. **Decisão do dono** |

### 11.6 · Decisões que não são de contraste, mas travam a entrada

| # | Questão | Por que trava | Opções |
|---|---|---|---|
| **F1** | **Onde moram os ~25 valores de cor novos** (§7.3) | `bt_tokens.dart` "não duplica cor" e `app_theme.dart` é "o único lugar com literal de cor". Os 25 não têm casa no `AppTheme` | (a) entram no `app_theme.dart` e `bt_tokens.dart` vira alias; (b) `bt_tokens.dart` tem literais e entra nas exceções de `app_theme_token_usage_test.dart` |
| **F2** | **Estado do azulejo em 200% de escala** (§4.1f) | A palavra de estado é a única coisa que diz **em palavra** que algo está valendo, e a 200% ela elipsa (`noite` → `no…`) dentro do `max-width: 62%` | Proposta **DERIVADA**: acima de ~160% o estado desce para uma segunda linha do rótulo em vez de elipsar |
| **F3** | **Transparência reduzida** (§4.1f) | O Flutter não expõe `prefers-reduced-transparency`; o kit inteiro é blur + rgba + véu | Assumir o custo, ou abrir canal de plataforma. Não há meio-termo |
| **F4** | **Consentimento legal com links** (§8, §10.1) | `register_screen.dart:519` vira `AppRuleTile`, que tem **um** alvo de toque; um consentimento real tem dois links dentro da frase | (a) `AppRuleTile` ganha slot de texto rico com alvos próprios; (b) o consentimento é exceção declarada onde a peça não se aplica |
| **F5** | **Stroke da seta de volta** (§4.4b) | O protótipo tem `stroke-width 2`; o kit escreveu 2,2 e `tokens.json` não registra stroke | Voltar para 2, ou marcar 2,2 como **DERIVADO**. Trivial, mas é fidelidade à régua |
| **F6** | **Raio da ação do rodapé** (§4.4b) | O `.btn` do protótipo tem raio **12**; o kit escreveu **14** | Igual a F5: alinhar com a régua ou assumir como derivado |

### 11.7 · O que esta rodada mudou no texto normativo (para o dono conferir)

1. **§2 regra 3** — o ✕ passou a ter dois desenhos (64×64 no board, 44×44 no cabeçalho da folha), porque as quatro provas de folha mostram o de 44.
2. **§2 regra 4** — "uma superfície de latão cheio por tela" virou "um **herói** por tela"; latão de seleção pode se repetir. `vt-04` tem quatro superfícies de latão e falsificava a regra antiga.
3. **§4.1c** — o armado desarma em **6 s** (`ARM_MS`), não em 3 s nem na perda de foco, e ganhou dono (`BtArmedScope`).
4. **§4.1d** — os quatro eixos de estado ganharam ordem de precedência.
5. **§4.1f** — a medição passou a ser **por slot**; `inkFor(c)` foi revogada e substituída pela regra de `dia` + estado em 19px.
6. **§7.1** — de duas revogações para **quatro** (entraram o orçamento de cor e o `inputDecorationTheme`).
7. **§9** — o `app_theme.dart` entrou na isenção e a catraca desceu de 48 para **24**, senão a guarda entra vermelha no dia 1 e não cateia nada.

---

## Referências

- Régua: `docs/design/life-counter-prototype/` — `README.md`, `mesa-brewtact.html`, `design/vitral/{menu,jogadores}.png`, `provas-iphone/vt-0{4,5,6,7,8}*.png`, `provas-iphone/plano.png`
- Tokens e CSS: `docs/design/ui-kit/{kit.css,tokens.json,specimen-390.png,specimen-1440.png,specimen.html}`
- Achados devolvidos ao protótipo: `docs/design/ui-kit/NOTAS-PARA-O-PROTOTIPO.md`
- Contagem: `docs/design/ui-kit/primitive-counts.json`
- Nota das telas: `docs/design/visual-audit-2026-09-21/README.md`
- Sequência e esforço: `docs/design/sequencia-e-esforco.md`
- Tema e guarda atuais: `app/lib/core/theme/app_theme.dart`, `app/test/core/theme/app_theme_token_usage_test.dart`

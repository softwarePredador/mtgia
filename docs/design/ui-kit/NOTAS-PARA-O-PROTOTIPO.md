# Notas para a sessão dona do protótipo

Escrito pela sessão do **kit visual** (`docs/design/ui-kit`). **Nada foi editado no protótipo** —
`docs/design/life-counter-prototype` é da outra sessão. São só achados, para quem manda lá decidir.

Data: 2026-09-21.

---

## 1 · `--frost-400` é usada mas nunca declarada em `mesa-brewtact.html` — CONFIRMADO

**Onde.** `docs/design/life-counter-prototype/mesa-brewtact.html`, linha **264**:

```css
.hubwrap.dn-night .rail .hub { box-shadow: inset 0 0 0 1.5px var(--frost-400), 0 0 0 4px var(--obsidian-950); }
```

**A prova.** `--frost-400` só aparece uma vez no arquivo — nesse uso. O `:root` de
`mesa-brewtact.html` declara `--obsidian-950`, `--obsidian-900`, `--slate-850`, `--slate-750`,
`--ivory`, `--mist`, `--mist-dim`, `--brass-400`, `--brass-500`, `--brass-700` e `--danger`, e
**não** declara `--frost-400`. A declaração existe apenas nos dois mocks:

```
design/vitral/menu.html:14         --brass-400:#E0A93B; --brass-500:#C58B2A; --frost-400:#6FA8DC; --danger:#FF8A80;
design/azulejos-vivos/menu.html:13 --brass-400:#E0A93B; --brass-500:#C58B2A; --frost-400:#6FA8DC; --danger:#FF8A80;
```

**O que acontece na tela.** `var(--frost-400)` sem fallback resolve para o valor *guaranteed-invalid*;
como `box-shadow` não é herdável, a declaração inteira vira `unset` → **`initial`** → `box-shadow: none`.
Ou seja: quando é **noite**, o hub perde o aro de gelo *e* perde o aro-base da linha 253
(`box-shadow: inset 0 0 0 1.5px var(--brass-500), 0 0 0 4px var(--obsidian-950)`), porque a regra da
linha 264 ganha a cascata e só depois vira `none`. Não é "o aro sai com outra cor": a regra inteira some, silenciosamente, sem erro de
console e sem quebrar nenhum teste.

**Por que passa despercebido.** A regra da linha 265 (`.hubwrap.mode …`) reescreve `box-shadow` quando
o hub está em modo de dano de comandante, então o defeito só aparece na combinação **noite sem modo**.

**Sugestão (de vocês, não nossa).** Declarar `--frost-400: #6FA8DC;` no `:root` de
`mesa-brewtact.html`, igual aos mocks. É o valor que o kit adotou como `--bt-gelo-400`, justamente
porque o protótipo não tinha de onde tirar.

---

## 2 · Divergências que o kit precisou arbitrar (só registro, nada a corrigir)

O kit seguiu a regra escrita em `tokens.json`: **quando `vitral/menu.html` e `mesa-brewtact.html`
divergem, manda `mesa-brewtact.html`**. Onde isso mordeu:

| O quê | `vitral/menu.html` | `mesa-brewtact.html` (adotado) |
|---|---|---|
| Eixo óptico do numeral | `font-variation-settings: "opsz" 144` | não fixa (fica em `auto`) |
| Assentos brasa/âmbar/musgo/maré | `#B5402B` `#94621A` `#3E7A4C` `#1F6F8C` | `#A83A27` `#855614` `#356B45` `#1D6985` |
| Padding do azulejo | `13px 14px 12px` | `12px 14px 11px` |
| Numeral do herói | `78px` | `70px` |
| Peça-numeral | `82 × 68`, numeral 44/50 | `70 × 58`, numeral 36/40 |
| Tracejado do "sem dono" | `rgba(224,169,59,.55)` | `rgba(224,169,59,.5)` |
| Pips de ordem | `14px` / `30px` | `13px` / `28px` |
| Botão redondo do herói | `58px` | `56px` |

O **opsz** é o que mais muda o olho: em `design/vitral/jogadores.png` (144) o numeral tem hairline
fina e contraste alto; em `provas-iphone/vt-04-regras.png` (auto) o mesmo `20` de 36px sai bem mais
encorpado. São dois desenhos diferentes da mesma fonte. Se a intenção era o desenho de alto contraste
em toda parte, aí o protótipo é que precisa fixar `"opsz" 144` — hoje ele não fixa.

---

## 3 · Um sentido a mais no mapa de significado (achado nas provas novas)

`vt-05-jogador.png` mostra `.rt.bad.on` — **brasa cheia** num estado que está *valendo*
(envenenado, concedeu), não num botão de destruir. E `.swatches button[aria-pressed="true"]`
usa aro de **marfim**, não de latão, para dizer "selecionado".

Nenhum dos dois é erro: são dois refinamentos que o mapa curto ("brasa = encerra ou destrói",
"latão = tudo que está selecionado") ainda não diz. O kit os registrou assim:

- **brasa cheia** = dano que está valendo **ou** a destruição como herói da tela;
- **latão** = selecionado, **exceto** numa fileira de cores, onde o latão seria só mais uma cor e
  quem marca a escolha é o marfim.

Vale a pena a linha entrar no `README.md` do protótipo, que é onde o mapa mora.

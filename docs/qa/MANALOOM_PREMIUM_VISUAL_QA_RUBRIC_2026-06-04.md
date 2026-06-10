# ManaLoom Premium Visual QA Rubric

Data: 2026-06-04

Status: protocolo ativo para validar layout premium e uniformidade visual.

## Objetivo

Este protocolo existe para validar o nivel que a auditoria estatica antiga nao
consegue cobrir sozinha:

- proporcao de cards, heros, modais e listas;
- plano de fundo, seams de imagem e transparencias indevidas;
- cores reais de textos, botoes, tabs, chips e bordas;
- tipografia e escala de fonte entre telas;
- bordas, raios, sombras e formato de cards;
- densidade/poluicao visual;
- coerencia com o baseline visual de `Meus Decks`;
- legibilidade real no iPhone Simulator.

## Veredito correto

Um fluxo visual so pode receber `PASS` quando os dois pontos forem verdadeiros:

1. `server/bin/premium_visual_audit.py` foi executado e os sinais relevantes
   foram revisados/corrigidos ou aceitos com justificativa.
2. A prova viva no iPhone Simulator foi executada e os screenshots foram
   revisados contra o checklist deste documento.

Se so houver auditoria estatica, o maximo permitido e `PASS_STATIC_ONLY` ou
`PASS_WITH_RISKS`, nunca `PASS` visual.

## Comando base

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
python3 server/bin/premium_visual_audit.py \
  --include-life-counter \
  --output docs/qa/manaloom_premium_visual_audit_latest.md
```

Wrapper equivalente:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
server/bin/premium_visual_audit.sh \
  --include-life-counter \
  --output docs/qa/manaloom_premium_visual_audit_latest.md
```

## Prova viva obrigatoria

Substituir `<IPHONE_SIMULATOR_UDID>` pelo simulator atual de `flutter devices`.

### App non-Life-Counter

```bash
cd app
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d <IPHONE_SIMULATOR_UDID> \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

### Life Counter / Lotus

```bash
cd app
flutter test \
  integration_test/life_counter_lotus_visual_capture_smoke_test.dart \
  integration_test/life_counter_native_card_search_smoke_test.dart \
  integration_test/life_counter_set_life_live_smoke_test.dart \
  integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart \
  -d <IPHONE_SIMULATOR_UDID> \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

## Checklist de screenshot

### 1. Proporcao

- Hero, cards e modais ocupam area coerente com a tela.
- Nenhum card parece imagem crua solta.
- Conteudo nao fica esmagado, cortado ou com sobra vazia artificial.
- Grid/lista nao cria buracos visuais quando ha pouco conteudo.

### 2. Background e superficie

- Fundo geral segue Obsidian/slate.
- Nao existe bloco claro Material solto.
- Imagem de hero nao mostra seam, transparencia errada ou diferenca brusca de
  cor com o fundo.
- Cards e sheets parecem da mesma familia visual de `Meus Decks`.

### 3. Cor

- CTA principal usa brass.
- Acoes secundarias usam slate/frost/ivory discretos.
- Tabs e filtros usam um unico acento por estado.
- Texto principal usa ivory; texto secundario usa mist.
- Nao ha branco/preto/cinza Material por acidente.

### 4. Tipografia

- Titulo/brand/deck identity podem usar display serifado.
- Listas, forms, tabs e botoes usam fonte de UI.
- Tamanhos seguem a escala `AppTheme.font*`.
- Labels e placeholders nao ficam pequenos demais no iPhone.

### 5. Bordas, raios e sombras

- Cards usam raio suave e consistente.
- Borda brass/frost aparece apenas quando ajuda hierarquia.
- Sombra/glow nao vira ruido.
- Inputs, modais e chips nao parecem componentes de outra familia.

### 6. Hierarquia e densidade

- A tela deixa claro qual e a acao principal.
- Informacao tecnica vira escolha guiada quando afeta decisao do usuario.
- Nao ha muitos icones, chips ou cores competindo no mesmo nivel.
- Empty/loading/error states mantem personalidade e instrucao clara.

### 7. Acessibilidade visual

- Texto e botao tem contraste real no screenshot.
- Touch targets principais aparentam pelo menos 48x48.
- Texto longo usa ellipsis/wrap controlado.
- Contadores, badges e labels criticos sao legiveis sem zoom.

## Matrizes e sources

A lista de surfaces, arquivos e capturas obrigatorias fica em:

```text
server/config/premium_visual_qa_surfaces.json
```

Fontes de verdade:

- `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md`
- `docs/qa/manaloom_layout_uniformity_audit_iphone15_2026-05-22.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/lib/core/theme/app_theme.dart`

## Regra operacional

Para qualquer ajuste visual app-facing:

1. Rode o `premium_visual_audit.py`.
2. Corrija P1 obvio de cor/botao/token.
3. Rode screenshot no iPhone Simulator.
4. Revise screenshots usando este checklist.
5. Documente no handoff se o veredito foi `PASS`, `PASS_WITH_RISKS` ou
   `PASS_STATIC_ONLY`.

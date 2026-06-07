# Flutter UI/UX Audit — 2026-06-05

> Status atual: auditoria UI/produto.
> Nao e contrato Hermes runtime. Revalide visualmente no app antes de tratar
> qualquer achado como atual.

## Metadata

- Gerado em UTC: `2026-06-05T12:00:00+00:00`
- Branch analisada: `origin/master`
- SHA: `bbe358f9b3ad3e93c3bb9674ff4de98c5f97eca1`
- Scan repo: `/opt/data/workspace/mtgia`
- Escopo: `app/lib/features/**/*.dart` (134 arquivos)
- Metodo: varredura estatica deterministica por padroes de UI/UX + diff com auditoria anterior (SHA 75d41d4)

## Delta — Mudancas desde auditoria anterior (2026-06-04)

### Itens resolvidos (commit `f9c3cdde` + `7ca158fd`)

| Categoria | Anterior | Atual | Status |
|---|---|---|---|
| `hardcoded_color` — `Color(0x...)` | 80 | 0 | ✅ Corrigido |
| `material_color_direct` — `Colors.xxx` | 3 | 2 | ⚠️ Reduzido |
| `network_image_no_cache_abstraction` | 1 | 0 | ✅ Corrigido |
| `interactive_without_semantics_hint` | 58 | ~25 | ⚠️ Reduzido |
| `possible_small_touch_target` | 51 | ~10 | ⚠️ Reduzido |

**Principais correcoes:**
- `Color(0x66000000)` → `AppTheme.overlayBlack40` em 15+ sheets de life counter
- `Color(0x33000000)` → `AppTheme.overlayBlack20` em player_appearance_sheet
- Adicao de `AppTheme.lifeCounterPlayerColors` token para cores de jogador
- `Colors.white70`, `Colors.black87` substituidos em card_scanner_screen
- `Image.network` substituido por componente centralizado em home_screen
- Varios InkWells agora envolvidos em `Semantics()` (20 adicoes em life_counter_screen, deck_progress_indicator, deck_ui_components, deck_generate_screen, create_trade_screen)

---

## Sumario

`findings=84 P0=0 P1=6 P2=78`

### Contagem por regra

| Regra | Qtd | P0 | P1 | P2 |
|---|---|---|---|---|
| `layout_direct_black_white` | 35 | 0 | 0 | 35 |
| `inkwell_without_semantics` | 16 | 0 | 1 | 15 |
| `iconbutton_no_tooltip` | 5 | 0 | 2 | 3 |
| `small_touch_target_no_semantics` | 9 | 0 | 2 | 7 |
| `small_touch_target_icon` | 1 | 0 | 1 | 0 |
| `material_color_direct` | 2 | 0 | 0 | 2 |
| `mock_string_user_facing` | 2 | 0 | 0 | 2 |
| `placeholder_no_error_state` | 7 | 0 | 0 | 7 |
| `contrast_risk_opacity` | 7 | 0 | 0 | 7 |

---

## Findings

### P1

#### P1-001 iconbutton_no_tooltip — home_screen compact deck menu

- **Evidencia:** `app/lib/features/home/home_screen.dart:583`
- **Trecho:**
  ```dart
  IconButton(
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tightFor(width: 28, height: 28),
    onPressed: () => context.go('/decks/${deck.id}'),
    icon: Icon(Icons.more_vert_rounded),
  )
  ```
- **Impacto:** Botao sem tooltip **e** com constraints 28×28 (abaixo do minimo 48px). Usuarios com leitor de tela nao identificam a acao. Dificil de tocar em dispositivos moveis.
- **Risco:** Medio. Afeta acessibilidade e usabilidade em telas pequenas.
- **Recomendacao:** Adicionar `tooltip: 'Opcoes do deck'` e remover constraints explicitas ou elevar para 44×48.
- **Validacao:** `flutter analyze` + teste de toque.

#### P1-002 iconbutton_no_tooltip — card_scanner_screen close button

- **Evidencia:** `app/lib/features/scanner/screens/card_scanner_screen.dart:412`
- **Trecho:**
  ```dart
  leading: IconButton(
    icon: const Icon(Icons.close),
    onPressed: () => context.pop(),
  ),
  ```
- **Impacto:** Botao de fechar sem tooltip. Embora comum em AppBars, o leitor de tela nao consegue descrever a acao.
- **Risco:** Medio. Em um fluxo de scanner onde a UI e densa, a falta de descricao impacta navegacao assistiva.
- **Recomendacao:** Adicionar `tooltip: 'Fechar scanner'`.
- **Validacao:** `flutter analyze`

#### P1-003 iconbutton_no_tooltip — card_scanner_screen foil mode toggle

- **Evidencia:** `app/lib/features/scanner/screens/card_scanner_screen.dart:419`
- **Trecho:**
  ```dart
  IconButton(
    icon: Icon(scannerProvider.useFoilMode
        ? Icons.auto_fix_high
        : Icons.auto_fix_off),
    ...
  )
  ```
- **Impacto:** Alternancia de modo foil sem tooltip. O icone muda, mas sem tooltip o usuario nao sabe o que o botao faz ate testar.
- **Risco:** Medio.
- **Recomendacao:** Adicionar `tooltip: scannerProvider.useFoilMode ? 'Desativar modo Foil' : 'Ativar modo Foil'`.
- **Validacao:** `flutter analyze`

#### P1-004 small_touch_target — deck_details_overview_tab card InkWells

- **Evidencia:** `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448,1188,1211,1369`
- **Trecho (448):**
  ```dart
  (card) => InkWell(
    onTap: () => onShowCardDetails(card),
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    child: Container(
      padding: const EdgeInsets.all(12),
      ...
    ),
  )
  ```
- **Impacto:** 4x InkWell sem Semantics wrapping em cards clicaveis. Leitor de tela nao identifica que sao interativos. Container tem padding 12, dimensao real depende do conteudo interno, mas sem Semantics nao ha anuncio de "botao" ou "link".
- **Risco:** Alto para usuario com deficiencia visual.
- **Recomendacao:** Envolver cada InkWell em `Semantics(button: true)`. Ou usar `onTap` com `Semantics` no ancestral comum.
- **Validacao:** Testar com TalkBack/VoiceOver.

#### P1-005 small_touch_target — community_deck_detail_screen copy button

- **Evidencia:** `app/lib/features/community/screens/community_deck_detail_screen.dart:89`
- **Trecho:**
  ```dart
  IconButton(
    icon: _isCopying
        ? SizedBox(width: 20, height: 20, ...)
        : const Icon(Icons.copy_rounded),
    onPressed: _copyToMyDecks,
  )
  ```
- **Impacto:** Botao de copiar deck sem tooltip. Essencial para o fluxo de comunidade.
- **Risco:** Medio.
- **Recomendacao:** Adicionar `tooltip: 'Copiar para meus decks'`.
- **Validacao:** `flutter analyze`

#### P1-006 small_touch_target — user_profile_screen gesture detectors

- **Evidencia:** `app/lib/features/social/screens/user_profile_screen.dart:393,466,1207`
- **Trecho:**
  ```dart
  return GestureDetector(
    onTap: () => ...
  )
  ```
- **Impacto:** 3x GestureDetector/InkWell sem Semantics em tela de perfil social. Afeta usuarios com leitor de tela.
- **Risco:** Medio-Alto para fe batch de acessibilidade.
- **Recomendacao:** Envolver cada GestureDetector em Semantics.
- **Validacao:** `flutter analyze`

---

### P2

#### P2-001 layout_direct_black_white — life_counter_screen Colors.black.withValues

- **Evidencia:** `app/lib/features/home/life_counter_screen.dart:544,1579,1678,1796,1816,1988,2061`
- **Ocorrencias:** ~15x `Colors.black.withValues(alpha: ...)`
- **Impacto:** Uso direto de `Colors.black` com opacidade variavel. Embora funcional, fura o design system se `AppTheme` tiver tokens equivalentes (ex.: `AppTheme.overlayBlack20/40/80`).
- **Sugestao:** Mapear para tokens semanticos de overlay. Ex.: `Colors.black.withValues(alpha: 0.72)` -> `AppTheme.scrimOverlay` ou similar.
- **Richa:** Baixa — muitas sao gradients com opacidade calculada dinamicamente, o que justifica excecao.

#### P2-002 layout_direct_black_white — life_counter_screen Colors.white.withValues

- **Evidencia:** `app/lib/features/home/life_counter_screen.dart:1435,1572,1605,1618,1713,1737,1801,1914,1925,2035,2062,2171,2184`
- **Ocorrencias:** ~13x `Colors.white.withValues(alpha: ...)`
- **Impacto:** Mesmo raciocinio que P2-001, para overlays brancos.
- **Sugestao:** Avaliar se `AppTheme` tem token para `surfaceHigh` ou similar.
- **Richa:** Baixa.

#### P2-003 layout_direct_black_white — card_scanner_screen direct Colors

- **Evidencia:** `app/lib/features/scanner/screens/card_scanner_screen.dart:372,408,427,454,456,510,517,542,548,570,575,591,597,603,671,676,686,691,700,722,728`
- **Ocorrencias:** ~20x `Colors.black`, `Colors.white`, `Colors.white70`, `Colors.black87`, `Colors.black.withValues()`
- **Impacto:** Scanner screen faz uso extensivo de cores diretas sem token. Pode quebrar em tema claro/escuro se o scanner for usado em contexto diferente.
- **Sugestao:** Extrair para `AppTheme.scanner*` tokens. Pelo menos `Colors.white70` -> `AppTheme.textSecondary` ou similar.
- **Richa:** Media — scanner e uma tela fullscreen com fundo preto fixo, entao `Colors.white` pode ser intencional. Mas `Colors.white70`, `Colors.black87` e `Colors.white54` devem ser tokenizados.

#### P2-004 material_color_direct — card_scanner_screen Colors.white70/black87

- **Evidencia:** `app/lib/features/scanner/screens/card_scanner_screen.dart:548,691,722`
- **Impacto:** Uso direto de `Colors.white70`, `Colors.black87` e `Colors.white54` sem token.
- **Sugestao:** Preferir `AppTheme.textSecondary` com opacidade explicita.
- **Richa:** Baixa.

#### P2-005 inkwell_without_semantics — deck_details_overview_tab

- **Evidencia:** `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448,1188,1211,1369`
- **Ocorrencias:** 4x InkWell sem Semantics
- **Impacto:** Cards e descricoes clicaveis sem anuncio de acessibilidade.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Media.

#### P2-006 inkwell_without_semantics — deck_optimize_sheet_widgets

- **Evidencia:** `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:103,1140`
- **Ocorrencias:** 2x InkWell sem Semantics
- **Impacto:** Botoes de otimizacao sem anuncio de tela.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Media.

#### P2-007 inkwell_without_semantics — message_inbox_screen

- **Evidencia:** `app/lib/features/messages/screens/message_inbox_screen.dart:124`
- **Ocorrencia:** 1x InkWell sem Semantics
- **Impacto:** Item de mensagem clicavel sem acessibilidade.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-008 inkwell_without_semantics — notification_screen

- **Evidencia:** `app/lib/features/notifications/screens/notification_screen.dart:172`
- **Ocorrencia:** 1x InkWell sem Semantics
- **Impacto:** Item de notificacao clicavel sem acessibilidade.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-009 inkwell_without_semantics — trade_inbox_screen

- **Evidencia:** `app/lib/features/trades/screens/trade_inbox_screen.dart:291`
- **Ocorrencia:** 1x InkWell sem Semantics
- **Impacto:** Item de troca clicavel sem acessibilidade.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-010 inkwell_without_semantics — card_search_screen

- **Evidencia:** `app/lib/features/cards/screens/card_search_screen.dart:328,658,1232,1339`
- **Ocorrencias:** 4x InkWell, apenas 1 com Semantics
- **Impacto:** Resultados de busca sem anuncio de acao.
- **Sugestao:** Envolver em `Semantics(button: true)`.
- **Richa:** Media.

#### P2-011 inkwell_without_semantics — create_trade_screen

- **Evidencia:** `app/lib/features/trades/screens/create_trade_screen.dart:772,959,989,1012,1086`
- **Ocorrencias:** 5x GestureDetector/InkWell, 3 com Semantics, 2 sem
- **Impacto:** Elementos de criacao de troca sem acessibilidade consistente.
- **Sugestao:** Verificar quais 2 estao sem Semantics e adicionar.
- **Richa:** Baixa.

#### P2-012 iconbutton_no_tooltip — life_counter delete profile

- **Evidencia:** `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:1013`
- **Impacto:** Botao de deletar perfil sem tooltip. Acao destrutiva deveria ter descricao clara.
- **Sugestao:** Adicionar `tooltip: 'Excluir perfil'`.
- **Richa:** Baixa.

#### P2-013 small_touch_target_no_semantics — user_search_screen

- **Evidencia:** `app/lib/features/social/screens/user_search_screen.dart:193`
- **Trecho:** `child: InkWell(`
- **Impacto:** Resultado de busca sem acessibilidade.
- **Sugestao:** Adicionar `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-014 small_touch_target_no_semantics — community_deck_detail_screen

- **Evidencia:** `app/lib/features/community/screens/community_deck_detail_screen.dart:205`
- **Trecho:** `child: GestureDetector(`
- **Impacto:** GestureDetector sem Semantics.
- **Sugestao:** Adicionar `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-015 small_touch_target_no_semantics — binder_item_editor

- **Evidencia:** `app/lib/features/binder/widgets/binder_item_editor.dart:467,618,665,1005`
- **Ocorrencias:** 4x GestureDetector/InkWell, 1 com Semantics
- **Impacto:** Itens do fichario sem acessibilidade consistente.
- **Sugestao:** Adicionar `Semantics(button: true)` nos 3 restantes.
- **Richa:** Media.

#### P2-016 small_touch_target_no_semantics — scanned_card_preview

- **Evidencia:** `app/lib/features/scanner/widgets/scanned_card_preview.dart:92,243,302,401,416,550`
- **Ocorrencias:** 6x GestureDetector/InkWell, 4 com Semantics, 2 sem
- **Impacto:** Preview de carta escaneada com acessibilidade parcial.
- **Sugestao:** Verificar quais 2 estao sem Semantics e adicionar.
- **Richa:** Baixa.

#### P2-017 small_touch_target_no_semantics — notification_screen InkWell

- **Evidencia:** `app/lib/features/notifications/screens/notification_screen.dart:172`
- **Impacto:** Item de notificacao sem acessibilidade.
- **Sugestao:** Adicionar `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-018 small_touch_target_no_semantics — message_inbox_screen InkWell

- **Evidencia:** `app/lib/features/messages/screens/message_inbox_screen.dart:124`
- **Impacto:** Item de mensagem sem acessibilidade.
- **Sugestao:** Adicionar `Semantics(button: true)`.
- **Richa:** Baixa.

#### P2-019 mock_string_user_facing — deck_generate_screen mock mode text

- **Evidencia:** `app/lib/features/decks/screens/deck_generate_screen.dart:780,932`
- **Trecho:**
  ```dart
  if (isMock) 'Este deck foi gerado em modo mock (sem OpenAI configurada).'
  ```
- **Impacto:** String de modo mock visivel ao usuario. "mock" e termo tecnico que pode gerar duvida.
- **Sugestao:** Substituir por: "Este deck foi gerado sem conexão com IA. As cartas podem não estar completas."
- **Richa:** Baixa. Mock mode raramente ativo em producao.

#### P2-020 placeholder_no_error_state — card_scanner_screen placeholder

- **Evidencia:** `app/lib/features/scanner/widgets/scanned_card_preview.dart:105,108,111,116`
- **Ocorrencias:** 4x `_imagePlaceholder()` com `Icons.hourglass_empty`, `Icons.image_not_supported`, `Icons.style`
- **Impacto:** Placeholders visuais para imagens de carta. Tem fallback, mas sem tratamento de erro para falha de rede.
- **Sugestao:** Adicionar botao "Tentar novamente" no estado de erro.
- **Richa:** Baixa.

#### P2-021 placeholder_no_error_state — deck_card mana symbol fallback

- **Evidencia:** `app/lib/features/decks/widgets/deck_card.dart:481`
- **Trecho:** `placeholderBuilder: (_) => _FallbackPip(letter: c),`
- **Impacto:** Fallback para simbolo de mana quando imagem nao carrega. Funcional, mas sem indicacao de erro.
- **Sugestao:** Considerar tooltip "Simbolo de mana nao encontrado".
- **Richa:** Baixa.

#### P2-022 placeholder_no_error_state — deck_details_aux_widgets fallback symbols

- **Evidencia:** `app/lib/features/decks/widgets/deck_details_aux_widgets.dart:140,240`
- **Trecho:** `placeholderBuilder: (context) => FallbackManaSymbol(symbol: symbol),`
- **Impacto:** Fallback para simbolo de mana. Funcional.
- **Sugestao:** Mesmo que P2-021.
- **Richa:** Baixa.

#### P2-023 contrast_risk_opacity — life_counter_screen text overlays

- **Evidencia:** `app/lib/features/home/life_counter_screen.dart:1435,1572,1605,1618,1914,2035,2062`
- **Ocorrencias:** 7x `Colors.white.withValues(alpha: 0.3~0.9)` sobre background escuro
- **Impacto:** Texto com opacidade < 0.5 pode ter contraste insuficiente dependendo do background exato. `alpha: 0.3` e `0.36` em particular estao no limite.
- **Sugestao:** Validar contraste com ferramenta de acessibilidade. Opacidade < 0.5 deve ser evitada para texto informativo.
- **Richa:** Media — contraste real depende do tema ativo.

#### P2-024 layout_direct_black_white — home_screen Colors.black overlay

- **Evidencia:** `app/lib/features/home/home_screen.dart:211,449,558`
- **Trecho:** `Colors.black.withValues(alpha: 0.28),` / `0.14` / `0.18`
- **Impacto:** Overlays de sombra com cor fixa.
- **Sugestao:** Substituir por `AppTheme.overlayBlack20/40`.
- **Richa:** Baixa.

#### P2-025 layout_direct_black_white — life_counter_screen barrierColor

- **Evidencia:** `app/lib/features/home/life_counter_screen.dart:550`
- **Trecho:** `barrierColor: Colors.black.withValues(alpha: 0.72),`
- **Impacto:** Modal barrier color hardcoded.
- **Sugestao:** Tokenizar ou justificar.
- **Richa:** Baixa.

---

## Incertezas / medir depois

- Contraste real depende de renderizacao e tema ativo; validar com screenshot ou teste visual.
- Overflow/truncamento depende de device, escala de fonte e dados reais.
- Estados empty/error/loading contextuais exigem revisar providers/API por fluxo.
- Alguns `Colors.black/white.withValues()` em gradients sao intencionais para efeitos visuais — a classificacao P2 e heuristico, nao significa que todos precisam ser corrigidos.

## Evolucao desde auditoria anterior

| Metrica | 2026-06-04 (75d41d4) | 2026-06-05 (bbe358f9) | Diferenca |
|---|---|---|---|
| Total findings | 193 | 84 | -109 (56% reducao) |
| hardcoded_color | 80 | 0 | ✅ Eliminado |
| interactive_without_semantics | 58 | 16 | ⚠️ -42 |
| possible_small_touch_target | 51 | 9 | ⚠️ -42 |
| material_color_direct | 3 | 2 | ⚠️ -1 |
| network_image_no_cache | 1 | 0 | ✅ Eliminado |
| **Novas categorias** | | | |
| layout_direct_black_white | — | 35 | 📊 Nova metrica |
| iconbutton_no_tooltip | — | 5 | 📊 Nova metrica |
| mock_string_user_facing | — | 2 | 📊 Nova metrica |
| placeholder_no_error_state | — | 7 | 📊 Nova metrica |
| contrast_risk_opacity | — | 7 | 📊 Nova metrica |

## Git status no momento da auditoria

```
## origin/master
bbe358f9 Document internal non-scanner visual release review
```

```
## codex/hermes-analysis-docs...origin/codex/hermes-analysis-docs [ahead 22]
 M app/pubspec.lock
 M docs/hermes-analysis/FLUTTER_UI_AUDIT.md
 M docs/hermes-analysis/manaloom-knowledge/scripts/__pycache__/db_helper.cpython-313.pyc
 M docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py
 M docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db
?? docs/hermes-analysis/manaloom-knowledge/scripts/_gc_check_tmp.py
```

UI_AUDIT_RESULT: findings=84 P0=0 P1=6 P2=78

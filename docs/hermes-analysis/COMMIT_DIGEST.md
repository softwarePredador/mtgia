# Hermes Analysis: Commit Digest

> Acompanhamento continuo dos commits do ManaLoom.
> Atualizado em 2026-05-26 (quarta rodada — commit 91885194).

## Estado atual

- Branch observada: `master`
- HEAD anterior: `ca0c8d52` (Polish Lotus life counter overlays)
- HEAD atual: **`91885194`** (Polish secondary shell headers)
- Branch de analise: `codex/hermes-analysis-docs`
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- SHA publicado confirmado em producao: **`918851942d59fd78e55d002924a6f0c71a31b209`** (`/health`, 2026-05-26)

## Novos commits nesta rodada

Um commit desde a ultima analise:

### `91885194` — Polish secondary shell headers (NOVO)
- **5 arquivos**, **+52/-54 linhas**
- Co-authored-by: Copilot
- Data: 2026-05-26 10:08 BRT
- Deployed SHA confirmado via `/health`: `918851942d59fd78e55d002924a6f0c71a31b209`

### `ca0c8d52` — Polish Lotus life counter overlays (rodada anterior)
- **4 arquivos**, **+531/-2 linhas**
- Co-authored-by: Copilot (mesmo autor de softwarePredador)
- Data: 2026-05-25 16:39 BRT

### `3eebd0f6` — Refresh ManaLoom visual system (rodada anterior)
- **63 arquivos**, **+3839/-2093 linhas** — commit massivo
- Co-authored-by: Copilot

## Analise detalhada do commit 3eebd0f6

### Tema e Design System
- `app/lib/core/theme/app_theme.dart` (+225 linhas)
- Novos tokens: `fontMicro` (8px) e `fontTiny` (9px) — escala vai de 8 a 32
- AppBar reformulado: fundo `backgroundAbyss` (antes surfaceSlate), iconTheme com `textSecondary`/22px, titleTextStyle Fraunces
- Novo `FilledButtonThemeData` com brass500 + padding padrao
- OutlinedButton agora usa `brass400` em vez de `frost400`
- Novos arquivos de teste do tema: `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Auth (novo shared widget)
- `AuthVisualShell` (225 linhas) — componente compartilhado para telas de auth
- Login screen: -373 linhas (refatorada para usar AuthVisualShell)
- Register screen: -527 linhas (mesma refatoracao)
- Splash screen: ajuste menor

### Home
- Home screen: 435 linhas alteradas
- Novo golden test para hero visual (`home_hero_sma135m.png` baseline)
- Home hero golden: 69KB PNG
- Hero art nova: `home_hero_banner.png` (252KB)
- Logo: `app_logo.png` (1.7MB)

### Community
- Community screen: 871 linhas alteradas (+504/-367) — grande refatoracao visual

### Profile
- Profile screen: 602 linhas alteradas (+388/-214)

### Card Search
- Card search: 240 linhas alteradas (+147/-93)

### Messages/Notifications
- Message inbox: 208 linhas alteradas
- Chat screen: 12 linhas
- Notification screen: 16 linhas

### Testes adicionados
- `home_screen_test.dart`: golden test para hero visual + asserts de novos CTAs
- `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Agente UX Design Auditor
- `manaloom-ux-design-auditor.agent.md`: reescrita completa (+767/-207)
- Agente agora tem modelo `gpt-5.5`
- Descricao expandida para "Elite UX/UI auditor for ManaLoom mobile"
- Diretrizes premium de produto: atmosferico, premium, cinematografico, game-native

### Documentacao
- `app/test/README.md`: instrucao para golden test do hero
- Runtime handoff: `manaloom_meus_decks_visual_system_iphone15_2026-05-22.md` (146 linhas)
- Layout uniformity audit: `manaloom_layout_uniformity_audit_iphone15_2026-05-22.md` (158 linhas)

### Assets novos
- `app/assets/branding/app_logo.png` (1.7MB)
- `app/assets/branding/home_hero_banner.png` (252KB)
- `nrelogo.png`, `nrelogos.png`, `slasharat.png` na raiz (arquivos fonte)

## Analise do commit 9a2bb38b — Lotus

- `lotus_visual_skin.dart`: skin CSS injetada no WebView do life counter
- Acabamento premium: cada um dos 4 jogadores agora tem cor de acento propria
  - J1: gold/warm (`#d89a2f`)
  - J2: blue (`#78a8ff`)
  - J3: purple (`#9a7cff`)
  - J4: green (`#4ed691`)
- Player cards com gradientes radiais + box-shadows + blend modes
- Saturação reduzida (0.62 vs 0.84) para aparencia mais cinematica e premium
- Cada player card tem glow, accent-soft e accent-faint como variaveis CSS
- Validacao adicional local em 2026-05-25 confirmou tela principal, radial menu,
  history, settings e card search em iPhone Simulator; ajustes de harness/skin
  posteriores a este HEAD ainda devem ser commitados antes de virarem baseline canonica.

## Analise do commit ca0c8d52 — Lotus Overlays Polish

Este commit expande `lotus_visual_skin.dart` (+423 linhas para 1333 total) com
CSS premium para tres overlays do Lotus WebView:

- **Settings overlay** (`Configurações`): posicionamento fixed full-viewport,
  safe-area-aware, fundo gradiente radial + linear, lista de itens com cards
  arredondados (20px), glassmorphism com `linear-gradient(180deg, rgba(13,22,42,0.8), rgba(6,11,24,0.72))`, bordoas sutis e sombra profunda.
- **Life history overlay**: timeline com tipografia `manaloom-display-font`,
  identidade visual consistente.
- **Card search overlay**: titulo `Buscar carta` posicionado, resultados com
  `card-name` estilizado, estrutura de pesquisa integrada ao tema premium.

Tres arquivos de smoke test foram atualizados/criados:
- `life_counter_lotus_card_search_visual_smoke_test.dart` (+59 linhas)
- `life_counter_lotus_settings_visual_smoke_test.dart` (+23 linhas)
- `life_counter_lotus_visual_overlays_smoke_test.dart` (+28 linhas, novo)

**Nao alterado**: backend, contratos API, core de decks, IA, ou outras
superficies do app. O arquivo `lotus_visual_skin.dart` continua sendo CSS
injetado no WebView, fora do sistema de tema Flutter.

**Status dos overlays**: settings, history e card search agora tem skin
premium, mas ainda precisam de prova viva lado a lado com `dddddd/` (baseline
pre-skin) para cada overlay antes de considerar a task de perfeicao fechada.

## Analise do commit 91885194 — Polish secondary shell headers

Este commit padroniza os AppBars de quatro telas secundarias, unificando
as seguintes propriedades em todas elas:

- **toolbarHeight: 54** (antes era 52 na Collection, inexistente nas demais)
- **centerTitle: true** (antes centralizacao era inconsistente)
- **titleTextStyle**: `titleMedium.w700` + `displayFontFamily` + `fontLg + 1`
- **surfaceTintColor: transparent**

### Impacto no design system

1. **Community screen** (`community_screen.dart`):
   - fontWeight: w800 → w700 (resolve o risco P1 documentado em OPEN_RISKS.md)
   - toolbarHeight adicionado (era ausente)
   - centerTitle adicionado

2. **Profile screen** (`profile_screen.dart`):
   - fontWeight: w800 → w700 (mesma correcao)
   - toolbarHeight e centerTitle adicionados

3. **Collection screen** (`collection_screen.dart`):
   - toolbarHeight: 52 → 54
   - **IconButton para `/collection/sets` removido** — o entry point direto para o catalogo de colecoes via AppBar foi eliminado. O acesso permanece via TabBar (aba "Colecoes"). Risco de usabilidade: usuarios que usavam o icone grid_view_rounded para navegacao rapida perdem esse atalho.
   - centerTitle adicionado
   - `go_router` import removido (redundante apos remocao do push)

4. **Market screen** (`market_screen.dart`):
   - **Tracker de cartas monitoradas removido do AppBar**: o badge com `provider.moversData!.totalTracked` nao aparece mais no header. O dado `moversData` continua disponivel no corpo da tela (loading/error states e listagem). Perda de visibilidade do total de cartas monitoradas sem navegacao extra.
   - Removeu padding, centralizou titulo e padronizou estilo

5. **Test file** (`collection_entrypoints_runtime_test.dart`):
   - Migrou de `find.widgetWithText(Tab, 'Marketplace')` para `find.byKey(Key('collection-tab-market'))`
   - Mesmo padrao para Trades, Colecoes e Fichario
   - Torna os testes mais resilientes a mudancas de texto e consistentes com UI_TEST_SURFACE_MAP.md

### Arquivos alterados

| Arquivo | Tipo | Mudanca |
|---------|------|---------|
| `app/lib/features/collection/screens/collection_screen.dart` | UI | AppBar padrao, remocao do atalho sets |
| `app/lib/features/community/screens/community_screen.dart` | UI | w800→w700, centerTitle |
| `app/lib/features/market/screens/market_screen.dart` | UI | AppBar padrao, remocao movers counter |
| `app/lib/features/profile/profile_screen.dart` | UI | w800→w700, centerTitle |
| `app/integration_test/collection_entrypoints_runtime_test.dart` | Test | Keys estaveis em vez de texto |

### Validacoes Linux (Hermes container)

- **dart test**: 599/599 passed (era 589 na rodada anterior)
- **flutter analyze**: No issues found

**Nao alterado**: backend (0 arquivos), contratos API, core de decks, IA, rotas.

## Impacto na direcao do projeto

### Projeto entrou oficialmente na Onda 6: Premium Visual System
O commit `3eebd0f6` estabelece um **design system premium completo**:
- Tema global refatorado (AppBar, buttons, font scale)
- Componentes visuais compartilhados (AuthVisualShell)
- Golden tests para hero
- Agente UX auditor dedicado com gpt-5.5
- Runtime proofs visuais

### Implicacoes
1. **Design system agora tem testes dedicados** — 3 novos arquivos de teste de tokens
2. **Home hero tem golden test** — baseline visual protegida contra regressao
3. **Auth screens refatoradas** — +225 linhas de componente compartilhado, ~900 linhas removidas das telas
4. **Life counter Lotus atingiu acabamento premium** — CSS skin com identidade por jogador + overlays settings/history/card search premium
5. **Projeto esta usando Copilot como co-author** — commits assinados por Copilot
6. **Agente UX auditor elevado para gpt-5.5** — ambicao de qualidade visual de produto premium

### O que NAO mudou
- Backend: nenhuma alteracao
- IA/Rotas: nenhuma alteracao
- Contratos app/backend: inalterados
- Core de decks: inalterado (nenhuma tela de decks foi tocada)
- Scrum/prioridades Sprint 1/2: mesmas pendencias abertas

## Ondas de commit atualizadas (HEAD~80)

| Onda | Periodo | Commits | Tema |
|------|---------|---------|------|
| 6 | 2026-05-25/26 | 4 | **Premium Visual System** — tema global, AuthVisualShell, golden tests, Lotus skin + overlays premium, secondary shell headers unificados, agente UX auditor |
| 1 | 2026-05-21/25 | 12 | UX Polishing — home, splash, icon, premium UX, card/deck screens |
| 2 | Abril-Maio | ~30 | Semantic Layer v2 |
| 3 | Maio | ~15 | Functional Tags + Localized Import |
| 4 | Abril-Maio | ~50 | Commander Reference |
| 5 | Marco | ~5 | Observabilidade + Infra |

## Direcao do projeto

1. **Premium Visual System (ATIVO)** — design system, golden tests, componentes compartilhados, audiencia UX
2. **Convergencia para o core** — decks, otimizacao, geracao, analise
3. **Qualidade de IA** — semantic tags, functional tags, Commander Reference
4. **Observabilidade** — Sentry, x-request-id
5. **Produto global** — icon, splash, onboarding

## O que esta fora dos commits recentes / nao consolidado neste digest

- Scanner/OCR — DEFERRED
- Community expansion — manutencao apenas
- Trades/Binder — manutencao apenas
- Carga/thresholds — nao iniciado
- Sentry mobile — pendente
- CHECKLIST_GO_LIVE — desatualizado
- Ajustes locais nao commitados no workspace principal nao contam como `master`
  ate virarem commit/push; este digest observa o `origin/master`.

## Como atualizar este digest

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
BASE_PREVIO=$(git rev-parse origin/codex/hermes-analysis-docs)
# Para ver o que mudou na master desde a ultima analise:
git log --oneline --decorate --stat $BASE_PREVIO..origin/master
```

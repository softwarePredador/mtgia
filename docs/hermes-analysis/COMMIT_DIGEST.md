# Hermes Analysis: Commit Digest

> Acompanhamento continuo dos commits do ManaLoom.
> Atualizado em 2026-05-25 (segunda rodada).

## Estado atual

- Branch observada: `master`
- HEAD anterior: `97195723` (Use new ManaLoom home hero art)
- HEAD atual: **`9a2bb38b`** (Improve Lotus life counter controls)
- Branch de analise: `codex/hermes-analysis-docs`
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- SHAs publicados: `97195723` (HEAD), `97195723` ainda rodando em producao (health confirmado)

## Novos commits nesta rodada

Dois commits desde a ultima analise:

### `3eebd0f6` — Refresh ManaLoom visual system
- **63 arquivos**, **+3839/-2093 linhas** — commit massivo
- Co-authored-by: Copilot
- Data: 2026-05-25 14:54 BRT

### `9a2bb38b` — Improve Lotus life counter controls (HEAD)
- **2 arquivos**, **+269/-13 linhas**
- Co-authored-by: Copilot
- Data: 2026-05-25 14:55 BRT

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
4. **Life counter Lotus atingiu acabamento premium** — CSS skin com identidade por jogador
5. **Projeto esta usando Copilot como co-author** — commits assinados por Copilot
6. **Agente UX auditor elevado para gpt-5.5** — ambicao de qualidade visual de produto premium

### O que NAO mudou
- Backend: nenhuma alteracao
- IA/Rotas: nenhuma alteracao
- Contratos app/backend: inalterados
- Scrum/prioridades Sprint 1/2: mesmas pendencias abertas

## Ondas de commit atualizadas (HEAD~80)

| Onda | Periodo | Commits | Tema |
|------|---------|---------|------|
| 6 | 2026-05-25 | 2 | **Premium Visual System** — tema global, AuthVisualShell, golden tests, Lotus skin, agente UX auditor |
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

## O que esta fora dos commits recentes

- Scanner/OCR — DEFERRED
- Community expansion — manutencao apenas
- Trades/Binder — manutencao apenas
- Carga/thresholds — nao iniciado
- Sentry mobile — pendente
- CHECKLIST_GO_LIVE — desatualizado

## Como atualizar este digest

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
BASE_PREVIO=$(git rev-parse origin/codex/hermes-analysis-docs)
# Para ver o que mudou na master desde a ultima analise:
git log --oneline --decorate --stat $BASE_PREVIO..origin/master
```
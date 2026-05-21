# ManaLoom UX/UI Global Premium Audit — 2026-05-21

## Status final

**PASS WITH RISKS** para o escopo non-scanner. Nao houve P0. Foram aplicados
patches P1 seguros e reversiveis em busca de cartas, estados de deck/fichario/
marketplace, dialogs de deck, mensagens e notificacoes usando tokens existentes
do `AppTheme`.

Fontes obrigatorias lidas: `app/lib/core/theme/app_theme.dart`,
`docs/qa/manaloom_ux_psychology_design_audit_2026-04-30.md`,
`app/doc/APP_AUDIT_2026-04-29.md` e
`app/doc/runtime_flow_handoffs/README.md`.

## Classificacao tela a tela

| Tela | Maturidade atual | Resultado |
| --- | --- | --- |
| Home | GOOD PRODUCT UI | Mantida; hierarquia ja orientada por intencao. |
| Busca/Cards/Colecoes | GOOD PRODUCT UI | Tiles de carta ficaram tocaveis por inteiro, com CTA brass e pips de identidade. |
| Detalhe da carta | GOOD PRODUCT UI | Provado no runtime de busca; sem patch estrutural. |
| Meus Decks | GOOD PRODUCT UI | Loading/error/filtro vazio e delete ficaram mais premium e confiaveis. |
| Novo Deck | GOOD PRODUCT UI | Dialog existente mantido; sem regressao. |
| Add Card Modal | GOOD PRODUCT UI | Mantido; tile de origem ficou mais acionavel. |
| Deck Detail — Visao Geral | GOOD PRODUCT UI | Estados loading/error/not-found migrados para `AppStatePanel`. |
| Deck Detail — Cartas | GOOD PRODUCT UI | Dialogs de carta/remocao/IA melhorados; lista preservada. |
| Deck Detail — Analise | GOOD PRODUCT UI | Sem patch direto nesta rodada; ja usa informacao estrategica. |
| Generate | GOOD PRODUCT UI | Mantido; coberto por auditoria historica. |
| Optimize | GOOD PRODUCT UI | Mantido; dialogs ja tinham preview/controle. |
| Import | FUNCTIONAL BUT FLAT | Sem patch nesta rodada; risco P2 de polish visual. |
| Binder/Colecao | GOOD PRODUCT UI | Empty/loading/error do fichario ficaram atmosfericos e mantiveram busca/scan. |
| Marketplace | GOOD PRODUCT UI | Estados vazios/erro/loading migrados para painel premium. |
| Trades | GOOD PRODUCT UI | Mantido; auditorias anteriores resolveram confianca/confirmacoes. |
| Messages | GOOD PRODUCT UI | Unread ganhou rail brass, avatar frost e semantica de envio mais consistente. |
| Notifications | GOOD PRODUCT UI | Unread ganhou rail brass; tipos usam frost/brass/semantic colors. |
| Profile | GOOD PRODUCT UI | Mantido; sem patch direto. |
| Community | GOOD PRODUCT UI | Mantido; sem patch direto. |
| Life Counter non-scanner | GOOD PRODUCT UI, PASS WITH RISKS | Fora dos patches por risco visual/runtime maior; sem regressao tocada. |

## Findings importantes e patch aplicado

| Prioridade | Surface | Current problem | Why it hurts UX | Ideal layout direction | Exact recommendation / patch | Status |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | Card Search | Result rows densas; thumbnail era o principal alvo de detalhe e add CTA pequeno. | Reduz scanabilidade e faz deck-building parecer utilitario. | Linha mais tatil, card identity evidente, CTA primario claro. | Tile inteiro abre detalhe; thumb 48x66; add CTA circular brass 40x40; pips WUBRG quando existe identidade. | PASS |
| P1 | Deck Details states | Spinner/erro/not-found simples. | Estados de espera/falha pareciam abandonados. | Painel obsidian com icone, microcopy e CTA contextual. | `AppStatePanel` para loading, erro 401/generico e not found. | PASS |
| P1 | Deck dialogs | Remocao e erros de IA/edicoes ainda tinham cara default/tecnica. | Acoes destrutivas e IA precisam transmitir controle e confianca. | Dialog com titulo iconografico, card de contexto, erro amigavel. | Remocao usa `DialogTitleBlock`/`DialogSectionCard`; erro IA/edicoes usa `FriendlyErrorMapper`; acoes viraram chips frost. | PASS |
| P1 | Deck List | Delete dialog default; loading/error/filtro vazio planos. | Colecao de decks perde percepcao premium e confianca em acao destrutiva. | Confirmacao com consequencia clara e estados curados. | Delete dialog custom; estados migrados para painel premium. | PASS |
| P1 | Binder/Marketplace | Empty/loading/error centrados e pouco atmosfericos. | Fichario e marketplace sao surfaces de valor/confianca; estados simples parecem inacabados. | Painel premium com simbolo, copy curta e CTA. | `AppStatePanel` onde seguro; empty do Binder preserva Buscar carta + Escanear existentes. | PASS |
| P1 | Messages/Notifications | Unread dependia de tint/violet legado. | Atenção e semantica visual ficavam inconsistentes com Brass/Frost. | Brass para atencao/acao, Frost para comunicacao/suporte. | Rail de unread brass, badges brass, avatares/send/loading frost/brass. | PASS |

## Prova runtime

Runtime executado no **iPhone 15 Pro Max Simulator**
`DABB9D79-2FDB-4585-94DB-E31F1288EE74` contra
`https://evolution-cartinhas.8ktevp.easypanel.host` com
`DISABLE_FIREBASE_STARTUP=true` e
`DISABLE_FIREBASE_PERFORMANCE_INIT=true`.

Comando provado:

```bash
cd app
DISABLE_FIREBASE_STARTUP=true DISABLE_FIREBASE_PERFORMANCE_INIT=true \
flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check
```

Resultado: **PASS**, `00:29 +1`.

Screenshots/proofs capturados no stdout do runtime:

| Proof | Bytes | Surface |
| --- | ---: | --- |
| `sets_search_01_cards_results` | 151494 | Busca de cartas com tile premium. |
| `sets_search_02_card_detail` | 6102265 | Detalhe da carta aberto pelo tile. |
| `sets_search_03_collections_results` | 441861 | Busca de colecoes. |
| `sets_search_04_set_detail` | 664150 | Detalhe da colecao. |

Os PNGs brutos nao foram commitados porque incluem screenshot de carta/conteudo
oficial como parte do app runtime; o proof tecnico fica registrado pelos nomes,
bytes, endpoints 200 e status PASS do harness.

## Validacao

| Comando | Resultado |
| --- | --- |
| `cd app && flutter analyze lib test --no-version-check` | PASS |
| `cd app && flutter test test --no-version-check` | PASS, `00:40 +589` |
| `cd app && flutter analyze integration_test/sets_search_catalog_runtime_test.dart --no-version-check` | PASS |
| Runtime iPhone 15 Pro Max publico acima | PASS |

## Riscos aceitos

- `Import` segue **FUNCTIONAL BUT FLAT** e merece polish P2 em outra rodada.
- A auditoria foi global, mas os patches foram cirurgicos; nem todas as telas
  tiveram runtime visual dedicado nesta sessao.
- Life Counter non-scanner foi classificado sem patch direto para evitar uma
  retematizacao ampla e arriscada.
- Scanner/camera/OCR/MLKit permaneceram fora do escopo.

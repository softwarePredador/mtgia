# ManaLoom App Logic, Buttons And Response Audit

Data: 2026-07-01
Backend alvo: `https://evolution-cartinhas.8ktevp.easypanel.host`
Status: `READY_FOR_INTERNAL_APP_QA_WITH_PUBLIC_RELEASE_BLOCKERS`

## Objetivo

Validar a logica atual do app antes de novas implementacoes: botoes, funcoes,
retornos, tempo de resposta, alinhamento com o backend publico e cobertura de
testes automatizados.

## Veredito

O app esta coerente para QA interna com o servidor publico como alvo padrao.

Nao deve ser tratado como release comercial completo porque a camada comercial
nova ainda e MVP local: plano, quota de IA e checkout usam estado local no
app, sem billing real e sem controle server-side. Tambem seguem pendentes os
bloqueios ja registrados de assinatura, Sentry mobile e aceite final em build
assinado.

## Evidencia executada nesta passada

### App e testes

Comandos executados:

```sh
git diff --check
flutter analyze --no-version-check
flutter test test/features/commercial test/features/growth test/features/retention test/features/decks/providers/deck_recommendation_context_payload_test.dart --no-version-check --reporter compact
flutter test test/features/home/home_screen_test.dart --no-version-check --reporter compact
flutter test test --no-version-check --reporter compact --concurrency=1
```

Resultados:

- `git diff --check`: PASS.
- `flutter analyze --no-version-check`: PASS, sem issues.
- Testes focados comercial/growth/retencao/payload: PASS, 8 testes.
- Teste focado Home: PASS, 3 testes.
- Suite completa `app/test`: PASS, 635 testes.

### Servidor publico

Probes via `/usr/bin/curl`:

| Endpoint | Status | Tempo total |
|---|---:|---:|
| `/health` | 200 | 0.996193s |
| `/ready` | 200 | 0.583192s |
| `/sets?limit=5` | 200 | 0.729427s |
| `/market/movers?limit=5` | 200 | 0.696632s |
| `/community/decks?limit=5` | 200 | 0.597465s |
| `/cards?name=Lightning%20Bolt&limit=5&page=1` | 200 | 0.605779s |
| `/cards/printings?name=Lightning%20Bolt&limit=5` | 200 | 0.603949s |
| `/auth/login` | 200 | 0.752112s |
| `/decks?limit=5` autenticado | 200 | 0.589417s |

Observacao: `/cards/search?q=...` retornou 404 porque nao e o endpoint usado
pelo app. O contrato atual do app usa `/cards?name=...`.

## Botões e fluxos revisados

| Area | Evidencia | Status |
|---|---|---|
| Login | Smoke autenticado no backend publico retornou 200 | PASS |
| Home | Widget test cobre layout SM A135M e scroll horizontal de acoes rapidas | PASS |
| Home quick actions | Corrigido teste para rolar a lista horizontal antes de exigir Colecao/Trocas | PASS |
| Deck details | Entradas de pos-jogo, explicacao e otimizacao preservadas em testes da suite completa | PASS_TESTED |
| Generate deck | Gate local de uso de IA e medidor de quota analisados/testados | PASS_MVP_LOCAL |
| Optimize deck | Payload inclui `recommendation_context` e preview segue coberto por testes | PASS_UI_CONTRACT |
| Comercial Free/Pro | Provider testa plano Free/Pro, quota e rollover mensal | PASS_MVP_LOCAL |
| Upgrade/checkout/legal | Rotas registradas e surfaces cobertas por analyze/testes | PASS_MVP_LOCAL |
| Perfil | Entrada para planos e medidor de uso preservados | PASS_TESTED |
| Comunidade/trade | Painel de crescimento tolera ausencia de `BinderProvider` e modelo tem teste | PASS_MVP |
| Retencao pos-jogo | Store local salva, carrega e tolera JSON corrompido | PASS_MVP_LOCAL |
| Scanner | Acao de scanner segue oculta por padrao no launch scope | PASS_SCOPE |

## Correção aplicada nesta passada

O teste de Home falhava em largura de `SM A135M` porque as acoes rapidas agora
ficam em uma lista horizontal e `Colecao`/`Trocas` nao aparecem sem scroll.

Alteracoes:

- `app/lib/features/home/home_screen.dart`: adicionada a key
  `home-quick-actions-list` na lista horizontal.
- `app/test/features/home/home_screen_test.dart`: teste agora rola a lista
  horizontal antes de validar `Colecao` e `Trocas`.

Validacao apos a correcao:

- `flutter test test/features/home/home_screen_test.dart --no-version-check --reporter compact`: 3 testes passaram.
- `flutter analyze lib/features/home/home_screen.dart test/features/home/home_screen_test.dart --no-version-check`: sem issues.
- Suite completa: 635 testes passaram.

## Alinhamento com servidor

O app esta apontando para o backend publico por padrao quando `API_BASE_URL`
nao e informado. A validacao de login, leitura de decks, cards, sets, market e
community retornou HTTP 200 com tempos abaixo de 1s na amostra desta passada.

O novo `recommendation_context` ja sai do app para otimizacao, mas ainda deve
ser tratado como contrato de UI/app ate o backend usar explicitamente colecao,
orcamento e intencao na selecao das recomendacoes.

## Riscos restantes

1. Plano, quota e checkout sao locais (`SharedPreferences`), nao controles de
   producao.
2. Historico pos-jogo e local por dispositivo, sem sincronizacao por conta.
3. `recommendation_context` ainda precisa aplicacao server-side para virar
   diferencial real de recomendacao.
4. Teste visual autenticado novo exige device/emulador e
   `MANALOOM_VISUAL_EMAIL`/`MANALOOM_VISUAL_PASSWORD`; ele nao foi executado
   nesta passada.
5. Nao foi executada geracao/otimizacao real com IA contra producao nesta
   passada para evitar custo e mutacoes desnecessarias.
6. Release publico ainda depende dos bloqueios ja documentados em
   `MANALOOM_RELEASE_READINESS_FINAL_PASS_2026-07-01.md`: Sentry mobile,
   signing Android/iOS e aceite final de build.

## Proxima etapa recomendada

Antes de implementar novas funcionalidades grandes, fechar nesta ordem:

1. Server-side para plano/quota/checkout.
2. Backend consumindo `recommendation_context`.
3. Sincronizacao server-side do pos-jogo.
4. Execucao do teste visual autenticado em device/emulador com credenciais de QA.
5. Repeticao do aceite final em build assinado.

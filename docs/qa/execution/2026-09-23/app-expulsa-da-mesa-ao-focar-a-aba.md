# O app expulsa o jogador da partida quando a aba recebe foco

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava.
> Depois dele, o defeito foi corrigido no master por `fba7c090e` (BT-NAV-02):
> `refresh()` mantém a matriz carregada durante o pedido, e qualquer falha e o
> `reset()` continuam negando na hora. Os dois testes citados abaixo não
> entraram com esses nomes; a cobertura equivalente está em
> `app/test/core/config/release_capabilities_test.dart`
> (`a refresh in flight keeps the loaded matrix for the route guard`, que
> passou a incluir `/decks/abc/play-vs-ai`, e
> `a refresh in flight that lands 200 with a smaller matrix revokes it`).
> Linhas de arquivo, digests e contagens de manifesto são os daquela árvore.

Data: 2026-09-23
Arquivo: `app/lib/core/config/release_capabilities.dart`

## Sintoma

Estando em `/decks/<id>/play-vs-ai` com a partida em curso, o app saía da tela
sozinho. A sessão continuava `waiting_for_action` no servidor — conferido pela
API no mesmo instante —, mas a tela ia para `/decks/<id>` e, num segundo salto,
para `/home`. Era isso que impedia a captura dos nove checkpoints.

## Causa

`ReleaseCapabilitiesProvider.refresh()` fazia, **antes** de perguntar ao
servidor:

```dart
_snapshot = ReleaseCapabilitiesSnapshot.denied();
_loadState = ReleaseCapabilitiesLoadState.loading;
_notifyIfMounted();
```

Durante toda a janela do fetch o app acreditava que **nenhuma** capability
existia. O `redirect` do GoRouter roda nessa notificação, e aí:

- `release_capabilities.dart:403` — `/play-vs-ai` sem `battleCoach` →
  `_deckDetailsFallback` → `/decks/<id>`;
- `release_capabilities.dart:519` — qualquer `/decks/...` sem `decksPrivate` →
  `/home`.

Daí os dois saltos observados.

O gatilho é `didChangeAppLifecycleState(resumed)` em `main.dart:1126`, que chama
`_refreshCapabilitiesAndWarmup`. Em Flutter Web, `resumed` dispara **a cada foco
da aba**. Ou seja: trocar de janela e voltar custava a partida em andamento. Não
era ferramenta de QA nem ambiente — qualquer jogador perderia a mesa assim.

## Prova ao vivo, antes da correção

Build servido pela fixture no digest `108f74a9`, um único evento de foco:

```
antes   : /decks/4a5ab8cd-.../play-vs-ai
1s depois: /decks/4a5ab8cd-...        <- saiu da mesa
...
10s depois: /decks/4a5ab8cd-...
```

## Correção

`refresh()` deixou de zerar a snapshot. A snapshot corrente sobrevive enquanto o
servidor não responde; `_loadState` vira `loading` e os listeners são avisados,
mas o acesso já concedido continua valendo.

Isto **não** afrouxa o fail-closed. Negar continua sendo a resposta a uma
*resposta* — 503, corpo inválido ou exceção levam a `_markUnavailable()` — e a
`reset()`, que é o caminho explícito de troca de conta. O que saiu foi só o
bloqueio preventivo, que negava sem ter perguntado.

## Testes

Em `app/test/core/config/release_capabilities_test.dart`:

- `um refresh em voo nao derruba o acesso ja concedido` — falha sem a correção
  (medido), e afirma as duas coisas: `isAllowed` continua verdadeiro durante o
  fetch, e `ReleaseCapabilityRouteGuard.redirectFor` devolve `null` para
  `/decks/abc/play-vs-ai` nessa janela.
- `reset() continua negando na hora, e uma resposta ruim tambem` — o
  contraponto, para que manter a snapshot não vire desculpa para acesso velho
  sobreviver a troca de conta ou a resposta inválida.

Os testes fail-closed que já existiam continuam verdes (503, corpo malformado,
exceção, resposta concorrente antiga): 19/19 em
`release_capabilities_test.dart`, 182/182 em `app/test/core/`.

## Custo

`app/lib` está no digest de UI, então o digest mudou: `108f74a9` → `ab2715e3`.
Os **34** manifestos de `docs/qa/ui-live/current/` ficaram defasados. Antes
desta correção eram 16 defasados de 34; recapturar tudo de uma vez, depois de
todas as correções de app, é mais barato que recapturar duas vezes.

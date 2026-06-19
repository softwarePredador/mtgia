# Battle / Generator / Lorehold Cycle - 2026-06-18

## Escopo fechado neste ciclo

Este ciclo tratou o primeiro slice fechavel do objetivo "battle + gerador de
deck + Lorehold": corrigir a camada de papeis funcionais usada pelo optimize e
quality gate. O foco foi reduzir candidatos ruins antes de eles entrarem em
scorecard, battle review ou sugestao do Lorehold.

Nao houve mudanca app-facing, API publica, PostgreSQL schema ou promocao
automatica de battle rules.

## Achados Hermes triados

Achados incorporados:

- `optimization_quality_gate.dart` usava `semanticOnly` para papéis de gate e
  podia mascarar `functional_tags` persistidos quando semantic v2 vinha parcial
  ou errado.
- Rituais de mana temporaria sem "ritual" no nome, como `Seething Song`, eram
  subdetectados pelo gate.
- `Smothering Tithe` podia ganhar papel `draw` por texto "opponent draws",
  contaminando o gate e sugestoes.
- Listas curadas de combo/protection estavam desalinhadas entre optimize e EDH
  bracket policy.

Achados rejeitados neste slice:

- Reescrever battle runtime ou promover novas regras `needs_review -> verified`.
  Isso segue exigindo evidencia focada, teste e replay/auditoria por carta.
- Usar `card_battle_rules` como fonte principal de papel de deckbuilding.
  Battle rules continuam regra executavel/auditavel; papeis de deckbuilding
  continuam vindo de `functional_tags`, `semantic_tags_v2` e heuristica.

## Alteracoes de codigo

- `server/lib/ai/optimization_quality_gate.dart`
  - O gate agora une roles de `functional_tags` persistidos e `semantic_tags_v2`
    em vez de deixar semantic v2 mascarar fonte persistida.
  - Tags persistidas como `board_wipe` continuam normalizadas para `wipe`.
  - Instant/sorcery que gera mana e tratado como burst temporario mesmo sem
    "ritual" no nome.

- `server/lib/ai/optimization_functional_roles.dart`
  - Corrigida heuristica de draw para nao contar `an opponent draws` como
    compra propria.
  - Land-search deixa de cair em draw por padrao "reveal/put into your hand".
  - Curadoria expandida de protection e combo pieces.

- `server/lib/edh_bracket_policy.dart`
  - A lista curada de infinite combo pieces foi alinhada com o optimizer para
    evitar drift entre recomendacao e bracket policy.

## Validacoes executadas

- `dart test test/optimization_quality_gate_test.dart -r expanded`
- `dart test test/optimization_quality_gate_test.dart test/edh_bracket_policy_test.dart -r expanded`
- `dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart lib/edh_bracket_policy.dart test/optimization_quality_gate_test.dart test/edh_bracket_policy_test.dart`
- `dart test test/functional_card_tags_test.dart test/optimization_validator_test.dart test/optimize_route_bracket_policy_filter_support_test.dart -r expanded`
- `git diff --check`

## Impacto esperado

- Menos falso positivo em candidatos de optimize.
- Menos perda silenciosa de papéis críticos quando semantic v2 diverge de
  `card_function_tags`.
- `Smothering Tithe` preserva `ramp/engine` sem virar `draw` por texto de
  compra do oponente.
- `Seething Song` e rituais similares deixam de entrar como swap seguro fora de
  combo apenas por não terem "ritual" no nome.
- Bracket policy e optimizer ficam mais coerentes para combo pieces comuns.

## Pendencias restantes

P1:

- Criar evidencia focada e replay audit para os proximos drafts relevantes:
  `Goblin Bombardment`, `Seize the Day`, `Iron Man, Titan of Innovation` e
  qualquer carta nova que entrar em `needs_rule_review`.
- Reduzir fallback do Lorehold com evidence por carta, nao por nome solto.
- Rodar scorecard Lorehold apos o deploy deste slice para medir se as sugestoes
  aprovadas mudaram e se nao houve regressao de singleton/color identity.

P2:

- Extrair listas curadas compartilhadas para um modulo unico se o drift voltar a
  aparecer em novas auditorias Hermes.
- Expandir testes de role detection para mais exemplos reais de "opponent
  draws", "each player draws" e draw simetrico/wheel.


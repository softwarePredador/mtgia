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
- Deploy EasyPanel de `manaloom-ops` e `hermes-lab` para
  `177544ca289e2c96048d59591c3b98d52708a4e7`
- `curl https://evolution-cartinhas.8ktevp.easypanel.host/health`
- `python3 server/bin/audit_easypanel_runtime_alignment.py --stdout-only`
- `python3 server/bin/audit_easypanel_cron_runtime.py`
- `dart run bin/lorehold_public_generator_parity_audit.dart --base-url=https://evolution-cartinhas.8ktevp.easypanel.host --artifact-dir=test/artifacts/lorehold_public_generator_parity_2026-06-18_role_gate`
- `API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host dart run bin/commander_generate_provenance_audit.dart --commander="Lorehold, the Historian" --artifact-dir=test/artifacts/goal_lorehold_generate_provenance_20260618_role_gate`

## Impacto esperado

- Menos falso positivo em candidatos de optimize.
- Menos perda silenciosa de papéis críticos quando semantic v2 diverge de
  `card_function_tags`.
- `Smothering Tithe` preserva `ramp/engine` sem virar `draw` por texto de
  compra do oponente.
- `Seething Song` e rituais similares deixam de entrar como swap seguro fora de
  combo apenas por não terem "ritual" no nome.
- Bracket policy e optimizer ficam mais coerentes para combo pieces comuns.

## Validacao Lorehold pos-deploy

Resultado publico:

- `health.git_sha=177544ca289e2c96048d59591c3b98d52708a4e7`
- `lorehold_public_generator_parity`: `PASS_WITH_RISKS`
- `/ai/generate`: `is_mock=false`, `generation_mode=reference_deterministic`,
  `reference_profile_used=true`, `reference_card_stats_used=true`
- `commander-learning`: `recommended_deck_source=promoted_learned_deck_pg`
- `commander_generate_provenance`: `PASS_WITH_RISKS`
- `profile_usable=true`
- `stats_count=34`
- `corpus_accepted_deck_count=3`
- `usage_hot_cards_count=50`
- `active_learned_deck_exists=true`
- `deterministic_main_count=99`
- `deterministic_distinct_card_count=99`

Riscos mantidos:

- `commander-learning` continua canal paralelo e nao substitui a ownership do
  backend.
- O auditor runtime ainda reporta P2 `split_operational_cache_paths` entre
  `manaloom-ops` e `hermes-lab`; aceitavel enquanto `hermes-lab` ficar
  report-only.

## Pendencias restantes

P1:

- Criar evidencia focada e replay audit para os proximos drafts relevantes:
  `Goblin Bombardment`, `Seize the Day`, `Iron Man, Titan of Innovation` e
  qualquer carta nova que entrar em `needs_rule_review`.
- Reduzir fallback do Lorehold com evidence por carta, nao por nome solto.
- Rodar scorecard Lorehold de optimize/battle em lote maior para medir se as
  sugestoes aprovadas mudaram; a validacao de generate/provenance deste slice
  ja confirmou main deck 99/99 distinto e profile ativo.

P2:

- Extrair listas curadas compartilhadas para um modulo unico se o drift voltar a
  aparecer em novas auditorias Hermes.
- Expandir testes de role detection para mais exemplos reais de "opponent
  draws", "each player draws" e draw simetrico/wheel.

---

## Atualizacao 2026-06-19 - Focused Evidence Para Iron Man E Massa Marvel

Este follow-up fechou o proximo slice testavel da fila `needs_rule_review`.
O foco foi reduzir o gargalo de cartas candidatas novas sem promover regra
automaticamente.

### Alteracoes

- `battle_analyst_v9.py`
  - adicionou `resolve_attack_artifact_tutor_trigger()`;
  - o trigger cria Treasure ao atacar;
  - sacrifica apenas artefato nao criatura quando houver alvo valido;
  - para o texto atual de `Iron Man, Titan of Innovation`, busca artefato com
    mana value exatamente `1 +` mana value do artefato sacrificado;
  - coloca o artefato no campo virado quando o oracle exigir;
  - emite `decision_trace` e `trigger_resolved` com `rule_status=needs_review`.

- `manaloom_battle_rule_focused_evidence.py`
  - adicionou template `attack_trigger_artifact_tutor`;
  - a evidência focada usa o oracle real de Iron Man: Treasure sacrificado busca
    `Sol Ring` CMC 1 e entra tapped;
  - continua report-only, sem write em PostgreSQL e sem auto-promotion.

- `manaloom_battle_rule_review_queue.py`
  - passou a classificar esse padrao como `attack_trigger_artifact_tutor`.

### Validacoes executadas

- `python3 -m py_compile server/bin/manaloom_battle_rule_review_queue.py server/bin/manaloom_battle_rule_focused_evidence.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `python3 server/test/manaloom_review_queue_consumers_test.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- Pipeline read-only em massa contra `msh,msc,mar`, 12 comandantes e 166 cartas:
  - `new_card_candidate_review`: `needs_rule_review=39`, `ignore=1950`,
    `backlog=3`;
  - `battle_rule_review_queue`: `12` drafts a partir de `39` rows;
  - `battle_rule_focused_evidence`: `12` avaliados, `4` com evidência;
  - `battle_rule_promotion_gate`: `4` elegíveis para promoção manual futura e
    `8` bloqueados.

### Resultado de cartas

Elegíveis para promoção manual futura, ainda sem auto-promotion:

- `Counterspell`
- `Goblin Bombardment`
- `Seize the Day`
- `Iron Man, Titan of Innovation`

Bloqueadas por falta de template focado:

- `Black Panther, Wakandan King`
- `Captain America, First Avenger`
- `Concerted Effort`
- `Final Showdown`
- `Ravenous Tyrannosaurus`
- `Storm, Force of Nature`
- `Warleader's Call`
- `Wolverine, Best There Is`

### Impacto para Lorehold

- `Goblin Bombardment` e `Seize the Day` continuam com evidência focada.
- `Iron Man, Titan of Innovation` deixou de ser bloqueio por falta de executor;
  agora tem evidência manual-gated e pode ser avaliado como candidato em
  Commander UR/RW-adjacent quando legal/identidade permitir.
- Nenhuma dessas regras foi promovida para `verified/active` em
  `card_battle_rules`; o backend/banco continuam donos da decisão.

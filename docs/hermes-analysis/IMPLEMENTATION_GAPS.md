# Implementation Gaps — PDF Spec vs Codebase

> Mapeamento da "Especificação técnica de regras faltantes para o ManaLoom Commander"
> para o código atual do battle_analyst_v9.py (engine ativo).
> Status: 2026-06-11
> Fonte oficial revalidada nesta rodada:
> `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`.
> Revisão estratégica complementar:
> `BATTLE_RULES_2026_STRATEGIC_REVIEW_2026-06-11.md`.
> Esta lista separa battle engine/regras de gaps de produto/UX. Itens visuais
> não devem entrar aqui.

## Resumo

| Categoria | Implementado | Parcial | Ausente/Tracked |
|---|---|---|---|
| Turno e Prioridade | 4/10 | 4/10 | 2/10 |
| SBAs e Triggers | 15/15 | 0/15 | 0/15 |
| Commander Rules | 5/8 | 2/8 | 1/8 |
| Mana e Custos | 2/6 | 4/6 | 0/6 |
| Targeting | 5/5 | 0/5 | 0/5 |
| Combate | 5/10 | 4/10 | 1/10 |
| Efeitos Contínuos | 4/5 | 1/5 | 0/5 |
| Tipos Complexos | 5/6 | 1/6 | 0/6 |
| Zonas e Objetos | 5/5 | 0/5 | 0/5 |
| Qualidade/QA | 7/7 | 0/7 | 0/7 |
| Regras oficiais 2026 | 10/12 | 2/12 | 0/12 tracked |

---

## 1. Turno e Prioridade (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Fases completas (untap,upkeep,draw,main1,combat,main2,end,cleanup) | ✅ Parcial | 4605-4828 | Upkeep só tem One Ring trigger. Falta janela de prioridade no upkeep |
| Passos de combate (beg.combat,decl.atk,decl.blk,damage,end.combat) | ⚠️ Parcial | 4773-5065 | Funções formais existem; faltam escolhas/restrições avançadas |
| Prioridade formal (APNAP pass sequence) | ✅ Básico | v9: `priority_order_from`, `emit_priority_pass_sequence`, `priority_round` | Passes APNAP são emitidos para pilha vazia e antes de resolver topo sem resposta; escolha humana/interativa e respostas card-specific seguem fora |
| Prioridade com pilha vazia | ✅ OK | 2563-2645 | `priority_round(..., phase=main)` permite ação sorcery-speed e o turno usa `run_priority_loop` |
| Sem prioridade em untap/resolução | ✅ OK | 4622-4633 | Untap não chama priority |
| Passos/fases extras (extra turn, extra combat) | ✅ Básico | v9: `extra_turns`, `extra_combats`, `play_turn_v8` | Extra turn e extra combat são suportados com cap anti-loop; fases extras arbitrárias seguem fora |
| Ações especiais (play land, morph) | ✅ OK | 4675-4700 | Land play tratado como ação especial |
| First draw em multiplayer | ✅ OK | 4642 | Ninguém pula draw no turno 1 |

**Ações imediatas**: 
- [ ] Adicionar `check_sbas_until_stable` nos pontos de prioridade ✅ FEITO
- [x] Adicionar janela de prioridade com pilha vazia nos main phases ✅
- [x] Separar passos de combate (beg.combat, decl.atk, decl.blk, damage, end) ✅

---

## 2. SBAs e Triggers (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Life <= 0 | ✅ OK | 2532-2535 | |
| Draw from empty library | ✅ OK | 2527-2531 | |
| Commander damage >= 21 | ✅ OK | 2538-2550 | |
| Deck out | ✅ Básico | v9: `Player.draw`, `check_sbas` | `failed_draw_from_empty_library` perde mesmo com cartas na mão |
| **Creature toughness <= 0 / lethal damage** | ✅ Básico | v9: `check_sbas` | Remove criatura por toughness/lethal damage |
| **Legend rule** | ✅ Básico | v9: `check_legend_rule` | Mantém a legenda mais recente por timestamp básico |
| Token fora do battlefield | ✅ Básico | v9: `check_token_lifecycle` | Token em graveyard/exile/hand deixa de existir no SBA loop |
| Aura/Equipment ilegal | ✅ Básico | v9: `check_illegal_attachments` | Aura ilegal vai ao graveyard; Equipment ilegal fica no battlefield e desanexa |
| +1/+1 e -1/-1 cancel | ✅ Básico | v9: `cancel_plus_minus_counters` | Cancela pares de marcadores via SBA e preserva aliases normalizados |
| Planeswalker 0 loyalty | ✅ Básico | v9: `check_sbas` | loyalty <= 0 move para graveyard |
| Saga capítulo final | ✅ Básico | v9: `check_saga_final_chapter` | Saga com capítulo final alcançado vai ao graveyard quando a habilidade de capítulo não está pendente |
| Battle defense 0 | ✅ Básico | v9: `check_sbas` | defense <= 0 move para exile |
| Commander em GY/exile → CZ (SBA) | ✅ Básico | v9: `ReplacementRegistry` | Zone change de commander para GY/exile/hand/library redireciona para command zone salvo escolha explícita |
| **Loop SBA até estabilizar** | ✅ Básico | v9: `check_sbas_until_stable` | Loop roda até estabilizar |
| **APNAP trigger ordering** | ✅ Básico | v9 | Triggers atuais entram como `triggered_ability`; falta player-choice avançado/aninhamento complexo |

**Ações imediatas**:
- [x] Creature SBA ✅
- [x] SBA loop ✅
- [x] Legend rule ✅
- [x] Adicionar deck out correto (trigger no draw, não check de biblioteca vazia)
- [x] APNAP ordering básico para triggers atuais

---

## 3. Commander Rules (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Commander tax (+2 por cast do CZ) | ✅ OK | 2253, 3532-3550 | |
| Commander damage tracking | ✅ Básico | v9: `commander_damage_by_source` | Ledger por `defender::commander_origin_id`; agregado legado por defensor preservado para compatibilidade |
| Commander replacement (GY/exile → CZ opcional) | ✅ Básico | v9: `ReplacementRegistry` | Redireciona para command zone salvo `commander_replacement_choice` |
| Commander replacement (hand/library → CZ opcional) | ✅ Básico | v9: `ReplacementRegistry` | Coberto no mesmo pipeline de zone change |
| Deck construction (100 cards, singleton, color ID) | ⚠️ Parcial | — | Feito no app, não no battle engine |
| Partner/Background/Friends Forever | ⚠️ Parcial | server: `commander_pairing.dart`; v9: damage ledger por origem | Servidor valida pares oficiais; battle engine ainda não modela UX/interação completa de dois commanders na command zone |
| Commander ninjutsu do CZ | ❌ Ausente | — | |
| Color identity de DFC/Adventure | ✅ Básico | v9: `compute_color_identity` | Agrega faces/partes/modos complexos |
| Legendary Vehicle/Spacecraft com P/T como commander | ✅ Básico | server + v9 | `commander_eligibility.dart`, `DeckRulesService`, `POST /decks/:id/cards` e `is_commander_eligible_card` cobrem regra 2026 |
| Hybrid mana em Commander | ✅ Guardado | server + v9 | Continua contando como todas as cores; sem regra "or" |

**Ações imediatas**:
- [x] Commander replacement opcional (GY/exile → CZ)
- [x] Commander damage keyed por origin ID, não nome

---

## 4. Mana e Custos (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Custo de mana básico | ✅ OK | 3532 | `cost = cmd["cmc"] + player.commander_tax` |
| Pipeline 601.2 (modes→targets→cost→lock→pay) | ⚠️ Parcial | v9: `CastingContext` | Contexto captura modes/targets/X/alt/additional costs; targeting legal formal fica separado |
| Custos alternativos (kicker, flashback, etc.) | ⚠️ Parcial | v9: `alternative_cost`, `additional_costs` | Suporte contextual/custo travado; falta semântica card-specific |
| X spells | ✅ Básico | v9: `x_value` | X entra no custo travado |
| Hybrid/Phyrexian mana | ✅ Básico | v9: `parse_mana_cost`, `Player._payment_plan` | Cobre híbrido colorido `{W/U}`, monocolored hybrid `{2/W}`, Phyrexian colorido `{W/P}` e hybrid Phyrexian `{W/U/P}`; restrições card-specific seguem pendentes |
| Mana pool com spend restrictions | ✅ Básico | v9: `restricted_mana`, `card_spend_tags` | Cobre restrições por categoria de spell (`creature_spell_only`, `artifact_spell_only`, `instant_or_sorcery_spell_only`, `noncreature_spell_only`); restrições arbitrárias por carta ainda exigem handler dedicado |

**Ações imediatas**:
- [x] Pipeline 601.2 mínimo: lock-in de custo antes de pagar
- [x] Expandir 601.2 para modes, X e alternative/additional costs
- [x] Levar targeting legal formal para o bloco Targeting
- [x] Adicionar pagamento básico de hybrid colorido e Phyrexian colorido

---

## 5. Targeting (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Seleção de alvos legais | ✅ Básico | v9: `target_matches_type`, `is_legal_target`, `removal_target_candidates` | Remoções filtram target type, hexproof, shroud, protection e proteção global |
| Alvos ilegais na resolução (partial resolution) | ✅ Básico | v9: `targeting_decision`, `resolve_multi_target_removal` | Single-target valida antes de resolver; multi-target declarado resolve alvos legais e ignora ilegais |
| Hexproof/Shroud | ✅ OK | — | Respeitado via `can_target` |
| Protection | ✅ Básico | v9: `is_legal_target` | `protection_from` por cor e `protection_from_everything` bloqueiam alvo |
| Ward | ✅ Básico | v9: `check_ward`, `apply_effect_immediate`, `resolve_multi_target_removal` | Remoção é anulada para o alvo com ward não pago; pagamento permite resolução. Abilities card-specific ainda ficam fora do modelo genérico |

---

## 6. Combate (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Declaração de atacantes | ⚠️ Parcial | v9: `declare_attackers_step`, `apply_basic_attack_requirements` | Função formal existe, com suporte básico a `must_attack*` e `cant_attack_alone`; escolha ainda é heurística/automática |
| Declaração de bloqueadores | ⚠️ Parcial | 4421-4462 | Bloqueadores calculados, não declarados |
| Blocked state persistente | ✅ OK | — | Bloqueado permanece mesmo se blocker morre |
| First/Double strike | ✅ OK | 4576-4580 | |
| Trample | ⚠️ Parcial | 4567-4568 | Funciona mas sem order formal |
| Deathtouch | ✅ OK | 4523-4528 | |
| Lifelink | ✅ OK | 4510-4511 | |
| Damage assignment multiplayer | ✅ Básico | v9: `assign_attackers_to_defenders`, `multi_defender_attack` | Atacantes podem ser distribuídos entre múltiplos defensores; requirements/restrictions por defensor ainda pendem |
| End of combat triggers | ✅ Básico | v9: `trigger_end_of_combat` | Permanentes com `trigger=end_of_combat` entram na stack por APNAP e resolvem efeitos genéricos seguros |
| Requirements/restrictions (must attack, can't attack alone) | ✅ Básico | v9: `must_attack_if_able`, `cant_attack_alone`, `apply_basic_attack_requirements` | Cobre flags explícitas `must_attack*` e `cant_attack_alone`; custos/requisitos por defensor, "attacks if able" condicionais e escolha interativa seguem fora |

---

## 7. Zonas, LKI e Instance ID (P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Zone change → novo objeto | ✅ Básico | v9: `_zone_id` | Mantém o dict Python, mas avança identidade lógica por `_zone_id` em zone changes modelados |
| LKI (last known information) | ✅ Básico | v9: `get_lki`, `_lki_snapshot` | Snapshot antes de mover criatura do battlefield |
| Command zone | ✅ OK | 2252, 2828 | |
| Exile (face up/down) | ✅ Básico | v9: `move_to_exile` | Registra metadados `_exile_face_down`, `_exile_public`, motivo e turno sem quebrar a lista `player.exile` existente |
| Token lifecycle | ✅ Básico | v9: `check_token_lifecycle` | Token em graveyard/exile/hand deixa de existir via SBA |

---

## 8. Efeitos Contínuos / Layers (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Layer 1 (copiable values) | ✅ Básico | v9: `apply_continuous_effects` | `copy` aplica snapshot |
| Layer 2-6 (control, text, type, color, abilities) | ✅ Básico | v9: `apply_continuous_effects` | set controller/text/type/color/abilities |
| Layer 7 (P/T com subcamadas) | ✅ Básico | v9: `apply_continuous_effects` | 7b/7c/7d/7e testados |
| Timestamps e dependencies | ✅ Básico | v9: `order_continuous_effects` | dependências declaradas; sem inferência automática |
| Replacement/prevention effects | ⚠️ Parcial | v9: `ReplacementRegistry` | Ordem determinística, prevention/life/shields/commander zone-change; faltam self-replacements card-specific |

---

## 9. IA e Métricas (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Loss tagging | ✅ OK | 4885-4920 | classify_loss implementado |
| WDWR/WPWR | ✅ OK | card_impact_analyzer.py | |
| Forensic audit | ✅ OK | battle_forensic_audit.py | |
| Quality gate | ✅ OK | master_optimizer_quality_gate.py | |
| Taxonomia canônica de derrota | ✅ Básico | `classify_loss` | Cobre `poison`, `effect_says_lose`, `concede` e tags heurísticas de screw/flood/mulligan/value |
| Telemetria de saúde do motor | ✅ Básico | v9: `EngineMetrics` | Contadores de stack, priority, SBA, replacements e replay events |
| Suite de conformidade | ✅ Básico | `test_battle_analyst_v10_3.py` | 15 cenários versionados em `CONFORMANCE_SCENARIOS` |
| Persistência operacional da telemetria | ✅ Operacional | v9: `write_engine_metrics_snapshot`, `MANALOOM_ENGINE_METRICS_DIR`, `master_optimizer_auto_cycle_cron.sh`, `engine_metrics_report.py` | Auto-cycle gera snapshots por rodada e publica `latest_engine_metrics_report.json` sanitizado |
| Diagnóstico de roles do optimize | ✅ OK | `optimization_functional_roles.dart`, `optimization_validator_test.dart` | `role_delta` usa `functional_tags` persistido antes de `semantic_tags_v2`, alinhando decisão de swap com a análise exibida ao usuário |
| Arquétipo efetivo do optimize/rebuild | ✅ OK | `optimize_archetype_support.dart`, `optimize_archetype_support_test.dart` | Política única para request genérico/específico e arquétipo detectado, removendo drift entre runtime e deck-state analysis |
| Roles estratégicos de cartas | ✅ OK | `functional_card_tags.dart`, `optimization_functional_roles.dart`, `functional_card_tags_test.dart` | `wincon`, `combo_piece`, `engine`, `payoff` e `enabler` passam pelo adapter único `resolveCardFunctionalRoles` |

### 9.1 Arquivos grandes / modularização (P1)

| Arquivo | Linhas em 2026-06-10 | Status | Próxima ação |
|---|---:|---|---|
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` | 7311 | ⚠️ Split iniciado | Seis cortes moveram helpers de mana/custo, características/identidade, lands/fontes, zone transitions, replacement/prevention e SBAs; próximo split seguro é novo domínio com conformance suite verde |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_cost_support.py` | 101 | ✅ Extraído | Centraliza parser/merge/snapshot de custo de mana sem dependência de fluxo de jogo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_characteristics_support.py` | 173 | ✅ Extraído | Centraliza faces/modos, identidade de cor e elegibilidade Commander sem dependência de fluxo de jogo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_land_support.py` | 110 | ✅ Extraído | Centraliza lands conhecidas, cores de fontes, normalização de nomes e `is_land` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py` | 118 | ✅ Extraído | Centraliza zone transitions parametrizadas, LKI, exile e resolution sem acoplar diretamente ao engine global |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py` | 231 | ✅ Extraído | Centraliza replacement/prevention, vida/dano e escudos; engine mantém wrappers locais para replay ativo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py` | 381 | ✅ Extraído | Centraliza SBAs, anexos ilegais, Saga final, token lifecycle e loop de estabilização com callbacks explícitos para replay/métricas/zone move |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` | 238 | ✅ Orquestrador fino | Todos os `def test_` foram extraídos para módulos por domínio; runner mantém imports, helpers, registry e lista agregada |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py` | 304 | ✅ Extraído | Mantém cenários e testes oficiais 2026 isolados |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py` | 330 | ✅ Extraído | Mantém regressões de combate isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py` | 151 | ✅ Extraído | Mantém regressões de replacement/prevention isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_commander_tests.py` | 145 | ✅ Extraído | Mantém regressões Commander isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py` | 112 | ✅ Extraído | Mantém regressões diretas de mana/custos isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` | 289 | ✅ Extraído | Mantém regressões de stack, priority e casting pipeline 601.2 isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py` | 328 | ✅ Extraído | Mantém regressões card-specific de Lorehold, Boros Charm, Akroma's Will e Silence isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py` | 241 | ✅ Extraído | Mantém regressões de targeting formal, hexproof/protection/ward, metadata e multi-target partial resolution isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_summoning_sickness_tests.py` | 362 | ✅ Extraído | Mantém regressões de summoning sickness, haste, vigilance, tokens, landfall token, mana source creature e Elvish Reclaimer isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py` | 229 | ✅ Extraído | Mantém regressões de zone transitions, lifecycle de tokens, remoção/tutor sem falsos positivos, land ramp/recursion e reanimation isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_import_tests.py` | 278 | ✅ Extraído | Mantém regressões de import/oracle, cache, rules table verificada, lands, artefatos curados e sync de regras normalizado |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py` | 147 | ✅ Extraído | Mantém regressões de turn flow, draw step, Approach win/turn stop, failed draw, extra turns e Unexpected Windfall isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py` | 171 | ✅ Extraído | Mantém regressões de SBA, cleanup, counters, anexos ilegais, Saga final, LKI/zone id e exile visibility isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py` | 246 | ✅ Extraído | Mantém regressões de planeswalker, battle/siege, DFC, adventure, prototype e split isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_continuous_effects_tests.py` | 155 | ✅ Extraído | Mantém regressões de continuous effects/layers, sublayers 7b-7e, timestamps e dependencies isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_engine_metrics_tests.py` | 133 | ✅ Extraído | Mantém regressões de EngineMetrics, snapshot JSON sanitizado e agregador de métricas isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_conformance_tests.py` | 201 | ✅ Extraído | Mantém registry base de conformidade e regressões transversais de blocked/APNAP/prevention isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py` | 228 | ✅ Extraído | Mantém regressões de replay events, fim de combate, APNAP/timestamp e spell-cast trigger isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_misc_regression_tests.py` | 198 | ✅ Extraído | Mantém regressões auxiliares de loss taxonomy, token/land recursion, proteção de jogador e auditoria isoladas |
| `server/routes/ai/optimize/index.dart` | 2321 | ⚠️ Split iniciado | Response/cache, envelope async, request parsing, payload final, warnings finais, diagnostics finais, fallback vazio, payloads de rejeição, validação pós-processamento, retry orchestration, filtro inicial de sugestões, filtro de identidade de cor, filtro de bracket, top-up deterministic/complete, proteção de remoção de lands, reequilíbrio pós-filtros, coleta EDHREC, query de dados completos das adições/quality gate, análise virtual pós-swap, execução do `OptimizationValidator`, decisão final pós-validator, outcome code e final response do modo complete foram movidos/reutilizados; manter rota como orquestração fina e só extrair novos blocos quando houver teste de support isolado |
| `server/lib/ai/optimize_runtime_support.dart` | 551 | ⚠️ Split iniciado | Cache, quality ranking, role/scoring funcional, utilitários de filler, seleção determinística de remoções, swap building, payload/response shaping e telemetry de fallback foram movidos para support dedicado; ainda falta extrair preferências de IA ou loaders de referência do comandante |
| `server/lib/ai/optimize_payload_support.dart` | 489 | ✅ Extraído | Normalização de payload, intensidade, parser de sugestões, response shaping, retry deterministic-first e recommendation detail |
| `server/lib/ai/optimize_fallback_telemetry_support.dart` | 148 | ✅ Extraído | Escrita e aggregate de telemetry do fallback vazio do optimize |
| `server/lib/ai/optimize_functional_role_support.dart` | 323 | ✅ Extraído | Centraliza inferência funcional, matching de necessidades e score de substituta; runtime mantém export compatível |
| `server/lib/ai/optimize_removal_candidate_support.dart` | 274 | ✅ Extraído | Centraliza seleção determinística de cartas a cortar, incluindo excesso de lands, proteção de core cards e escopo agressivo |
| `server/lib/ai/optimize_swap_candidate_support.dart` | 491 | ✅ Extraído | Centraliza `findSynergyReplacements`, ranking de pares de swap e montagem determinística de candidatos sem acoplar ao runtime monolítico; runtime mantém export compatível |
| `server/lib/ai/optimize_filler_loader_support.dart` | 1222 | ⚠️ Parcial | Centraliza loaders SQL de fillers, lands e structural recovery; helpers puros de dedupe/identity/quality foram extraídos para `optimize_filler_candidate_support.dart` |
| `server/lib/ai/optimize_filler_candidate_support.dart` | 203 | ✅ Modularizado | Dedupe por nome, filtro de identidade Commander, score de filler e helpers de land fixing com teste isolado |
| `server/lib/ai/optimize_cache_support.dart` | 119 | ✅ Extraído | Centraliza assinatura de deck, cache key estável e load/save de `ai_optimize_cache` com wrappers compatíveis no runtime |
| `server/lib/ai/optimize_candidate_quality_support.dart` | 327 | ✅ Extraído | Centraliza sinais de qualidade agressiva, ranking, buckets de rejeição e loader SQL com export compatível no runtime |
| `server/lib/ai/optimize_archetype_support.dart` | 29 | ✅ Extraído | Centraliza resolução de arquétipo efetivo para optimize, rebuild e deck-state analysis |
| `server/lib/ai/optimize_route_response_support.dart` | 136 | ✅ Extraído | Centraliza contagem de swaps, resposta cacheada, diagnostics agressivos e payload `rebuild_guided` |
| `server/lib/ai/optimize_route_async_support.dart` | 179 | ✅ Extraído | Centraliza criação de job, fire-and-forget e payloads `202 Accepted` de optimize/complete async |
| `server/lib/ai/optimize_route_request_support.dart` | 65 | ✅ Extraído | Centraliza parsing inicial de request, defaults, overrides e tri-state de async |
| `server/lib/ai/optimize_route_payload_support.dart` | 186 | ✅ Extraído | Centraliza balanceamento/filtro final de sugestões e mantém `recommendations` alinhado ao payload final |
| `server/lib/ai/optimize_route_warnings_support.dart` | 61 | ✅ Extraído | Centraliza montagem de warnings finais de optimize: cartas inválidas, identidade de cor, bracket, tema e fallback vazio |
| `server/lib/ai/optimize_route_diagnostics_support.dart` | 37 | ✅ Extraído | Centraliza `optimize_diagnostics` de fallback vazio e merge incremental de diagnostics sem sobrescrita |
| `server/lib/ai/optimize_route_empty_fallback_support.dart` | 103 | ✅ Extraído | Centraliza seleção de candidatas de remoção, aplicação de swaps e razões do fallback de sugestões vazias |
| `server/lib/ai/optimize_route_quality_rejection_support.dart` | 48 | ✅ Extraído | Centraliza payloads de rejeição `OPTIMIZE_NO_SAFE_SWAPS` e `OPTIMIZE_QUALITY_REJECTED` |
| `server/lib/ai/optimize_route_post_validation_support.dart` | 146 | ✅ Extraído | Centraliza warnings/improvements pós-processamento de identidade de cor, coleta EDHREC, tema e análise antes/depois |
| `server/lib/ai/optimize_route_retry_support.dart` | 64 | ✅ Extraído | Centraliza plano de retry deterministic-first → IA e metadata de respostas IA |
| `server/lib/ai/optimize_route_suggestion_filter_support.dart` | 76 | ✅ Extraído | Centraliza balanceamento/sanitização inicial de sugestões, proteção de comandante/core e filtro de no-op |
| `server/lib/ai/optimize_route_color_identity_filter_support.dart` | 38 | ✅ Extraído | Centraliza filtro puro de adições por identidade de cor do comandante |
| `server/lib/ai/optimize_route_bracket_policy_filter_support.dart` | 47 | ✅ Extraído | Centraliza filtro de adições por política de bracket preservando ordem/repetição da lista validada |
| `server/lib/ai/optimize_route_complete_top_up_support.dart` | 91 | ✅ Extraído | Centraliza top-up determinístico de básicos no modo complete sem acoplar SQL |
| `server/lib/ai/optimize_route_land_removal_protection_support.dart` | 62 | ✅ Extraído | Centraliza proteção contra remoção de terrenos quando a contagem de lands está baixa |
| `server/lib/ai/optimize_route_rebalance_support.dart` | 128 | ✅ Extraído | Centraliza plano de reequilíbrio pós-filtros, aplicação de substitutas e truncamento final |
| `server/lib/ai/optimize_route_final_gate_support.dart` | 156 | ✅ Extraído | Centraliza decisão final de quality gate, validação serializada e Semantic Layer v2 após o `OptimizationValidator` |
| `server/lib/ai/optimize_complete_support.dart` | 1450 | ⚠️ Split iniciado | Orquestra modo complete DB-backed; helpers puros de mana foram extraídos para suporte dedicado, mas o arquivo ainda concentra seed/filler/final response |
| `server/lib/ai/optimize_complete_mana_support.dart` | 118 | ✅ Extraído | Centraliza limite de básicos, demanda de cores e plano ponderado de terrenos básicos do modo complete com export compatível |
| `server/lib/commander_eligibility.dart` | 23 | ✅ Extraído | Centraliza elegibilidade Commander 2026 para DeckRulesService e rotas incrementais |
| `server/lib/commander_pairing.dart` | 105 | ✅ Extraído | Centraliza pares Partner, Partner with, Background, Friends Forever, Doctor's companion e normalização de nome físico |
| `server/lib/ai/optimization_validator.dart` | 904 | Aceitável por enquanto | Não splitar antes de isolar o optimize route/runtime |
| `server/lib/ai/optimization_functional_roles.dart` | 768 | Aceitável por enquanto | Manter coeso; split só se crescer com novas políticas |

---

## O Que Já Foi Implementado (2026-06-09)

| Fix | Status |
|---|---|
| SBA loop (check_sbas_until_stable) | ✅ |
| Creature toughness/damage SBA | ✅ |
| Legend rule SBA | ✅ |
| 2 call sites updated to until_stable | ✅ |
| APNAP trigger ordering básico | ✅ |

## Próximos Passos (Ordem de Impacto)

1. **Integração avançada de tipos complexos** — efeitos específicos de Omen/Prepare/Paradigm/Station por carta concreta
2. **Modularização segura** — continuar split do engine Hermes por domínio e depois route/runtime de optimize
3. **Targeting avançado** — seleção complexa/card-specific além de remoções declaradas; o bloco formal mínimo já está isolado em `battle_targeting_tests.py`
4. **Suite de conformidade expandida** — triggers aninhadas, escolha de ordenação e regressões v9
5. **Operacionalização Hermes** — plugar relatório agregado de telemetria nas crons se necessário

---

## 10. Regras oficiais 2026 / Mecânicas modernas (P1-P2)

Fonte consolidada: `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md` e
`BATTLE_RULES_2026_STRATEGIC_REVIEW_2026-06-11.md`.
Fonte primária para números novos de Edge of Eternities:
`https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin`.
Esta mesma fonte é também a âncora primária para Legendary Vehicle/Spacecraft
com P/T como commander em `903.3`/`903.12c`; o artigo de mecânicas fica apenas
como explicação operacional.
Fonte Commander/hybrid: `https://magic.wizards.com/en/formats/commander` e
`https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026`.

| Item | Status | Implementação | Limite restante |
|---|---|---|---|
| Omen cards | ✅ Parcial | `get_card_characteristics(..., cast_mode="omen")` e `compute_color_identity` | Efeitos card-specific por carta concreta |
| Station cards | ✅ Parcial | `activate_station_ability` | Escolha humana/interativa de criatura a stationar |
| Spacecraft | ✅ Parcial | `is_vehicle_or_spacecraft_card`, `activate_station_ability` | Efeitos específicos de cada Spacecraft |
| Warp | ✅ Parcial | `cast_warp_spell_from_hand`, `process_warp_end_step`, `cast_warp_card_from_exile` | Interações card-specific e permissões complexas |
| Prepare / Preparation cards | ✅ Parcial | `prepare_spell_copy`, `cleanup_prepared_copies` | Cast completo da cópia preparada por UI/interação |
| Paradigm | ✅ Parcial | `resolve_paradigm_spell` rastreia a fonte | Cópia automática na primeira main phase futura segue como tracked gap |
| Flashback | ✅ Básico | `cast_flashback_spell_from_graveyard`, exile replacement | Custos/restrições específicas por carta |
| Lander tokens | ✅ Básico | `create_lander_token` | Token variants por carta concreta |
| Void/Repartee/Opus/Increment/Infusion/Converge | ✅ Telemetria | `modern_ability_word_signals` | Sem enforcement porque ability words não têm efeito próprio |
| Multiplayer attack distribution | ✅ Básico | `assign_attackers_to_defenders` + `multi_defender_attack` | Requirements/restrictions por defensor e escolha interativa |
| Hybrid mana em Commander | ✅ Guardado | servidor + v9 preservam identidade combinada | Não flexibilizar; Wizards confirmou que a regra não mudou em 2026-02-09 |
| `is_commander` fora de Commander/Brawl | ✅ Guardado | `DeckRulesService.validateCommanderSlotAllowedForFormat` | Mantém todas as rotas que delegam ao serviço alinhadas com a regra de formato |
| No sideboard/outside-game em Commander | ⚠️ Tracked Gap | gap registrado nesta seção | Validar rotas/deck construction se o produto expuser sideboard/wishboard |

### 10.1 Decisão estratégica 2026-06-11

O suporte atual é intencionalmente mínimo e orientado a simulação Commander.
Não transformar `battle_analyst_v9.py` em judge engine completo neste ciclo.
As etapas do plano estratégico estão classificadas assim:

| Etapa | Classificação atual |
|---|---|
| Documentação/matriz oficial | Implemented |
| Commander legality 2026 e hybrid estrito | Implemented |
| Warp/Flashback/cast-from-exile | Partial mínimo testado |
| Station/Spacecraft | Partial mínimo testado |
| Prepare/Omen/Paradigm | Partial mínimo testado |
| Multiplayer Commander combat | Implemented básico |
| Ability words modernos | Telemetry, sem enforcement |

Ordem de implementação quando houver corpus concreto:

1. **Warp/Flashback/cast-from-exile card-specific** — validar custo, timing e
   exile replacement por carta real antes de promover efeito.
2. **Station/Spacecraft striations** — suportar múltiplos thresholds e efeitos
   impressos somente para Spacecraft que apareçam em deck real.
3. **Prepare/Omen/Paradigm** — adicionar resolução completa apenas por carta
   usada; manter características/cópia/exile tracking como base genérica.
4. **Multiplayer combat avançado** — requirements/restrictions por defensor,
   custos para atacar, blockers em APNAP e efeitos que referenciam
   "defending player". O suporte genérico a `must_attack*` e
   `cant_attack_alone` já existe como camada básica.
5. **Ability-word telemetry** — permanecer como sinal semântico; enforcement só
   se o texto da carta tiver regra executável própria.

Gate obrigatório: não criar regra genérica nova para Warp, Station, Prepare,
Omen, Paradigm ou ability words sem carta real no corpus, replay incorreto e
teste focado. Caso contrário, manter como tracked gap.

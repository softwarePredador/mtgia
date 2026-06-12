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

1. **Rollout controlado no Hermes runtime** — fazer backup do SQLite real, aplicar snapshot agregado e rodar report-only contra o DB real
2. **Identidade semântica de carta** — separar explicitamente printing id/oracle id/faces para DFC/MDFC, localized names, rulings e dedupe de regra
3. **Agregação segura de multi-função por carta** — manter o sync PG -> Hermes agregado por `card_id` e aplicar no SQLite runtime real somente após consumidores críticos compatíveis
4. **Learned decks Commander completo** — evoluir contrato de learned decks de 1 commander + 99 main para também aceitar pares oficiais quando houver corpus validado
5. **Integração avançada de tipos complexos** — efeitos específicos de Omen/Prepare/Paradigm/Station por carta concreta
6. **Modularização segura** — continuar split do engine Hermes por domínio e depois route/runtime de optimize
7. **Targeting avançado** — seleção complexa/card-specific além de remoções declaradas; o bloco formal mínimo já está isolado em `battle_targeting_tests.py`
8. **Suite de conformidade expandida** — triggers aninhadas, escolha de ordenação e regressões v9
9. **Operacionalização Hermes** — plugar relatório agregado de telemetria nas crons se necessário

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

---

## 11. Multi-função por carta e agregação segura PG -> Hermes (P1)

### Status

Partially implemented. O bug operacional de 2026-06-11 foi contido no sync do
target deck para Hermes sem usar `LEFT JOIN LATERAL (...) LIMIT 1` para
`card_battle_rules`. O sync agora agrega funções/regras por `card_id` e grava
`functional_tags_json`, `semantic_tags_v2_json`, `battle_rules_json`,
`deck_hash`, `semantics_hash`, `ruleset_hash` e `sync_run_id`. A aplicação no
SQLite runtime real do Hermes foi executada em 2026-06-11 com backup e
validação. O gap permanece aberto por política e cobertura: scripts
históricos/manuais ainda podem assumir `functional_tag` único, e a derivação de
`card_battle_rules` para `card_function_tags` ainda precisa de taxonomia, gate
de confiança/revisão e limpeza de stale tags. O dedupe lógico por
`logical_rule_key` foi implementado e aplicado no Hermes AWS, mas ainda não
autoriza derivação automática de tags funcionais.

### Evidência

- PostgreSQL `deck_cards` é a fonte canônica de cardinalidade do deck:
  `server/database_setup.sql` define `UNIQUE(deck_id, card_id)` e `quantity`.
- PostgreSQL `card_battle_rules` permite múltiplas regras por carta:
  `card_id` é indexado, mas não único; a chave primária é `normalized_name`.
- `card_function_tags` é multi-tag por desenho:
  a chave efetiva usada pela camada de IA é `(card_id, tag, source)`.
- O sync Hermes corrigido tem guard de soma de quantidade e agregação semântica
  por `card_id`; a evidência está em
  `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`.

### Invariante obrigatório

Todo consumidor em contexto de deck deve preservar:

```text
SUM(deck_cards.quantity) antes do enriquecimento
==
SUM(deck_cards.quantity) depois do enriquecimento
```

Uma carta pode ter múltiplas funções e múltiplas regras executáveis, mas isso
não pode criar múltiplas cartas no deck. Contadores de papel podem somar mais
que 100 porque uma carta pode contar como `ramp` e `engine`, por exemplo; o
total legal do deck continua vindo somente de `deck_cards.quantity`.

### Modelo correto

Separar três contratos:

| Contrato | Fonte | Uso |
|---|---|---|
| Cardinalidade do deck | `deck_cards.quantity` | total 100, main 99, hash de deck, validação Commander |
| Função de deckbuilding | `card_function_tags`, `card_semantic_tags_v2` | ramp/draw/removal/wipe/protection/engine/payoff/wincon |
| Regra executável | `card_battle_rules` | battle engine, replay, forensic audit, simulação |

Nenhum consumidor deve fazer join bruto de `deck_cards` com tabelas que possam
ter múltiplas linhas por `card_id`. Antes de tocar `deck_cards`, essas tabelas
devem ser reduzidas para uma linha por carta.

### Fechamentos obrigatórios do contrato

- **Taxonomia canônica**: normalizar categorias antes de escolher
  `functional_tag`. Exemplo: `board_wipe` deve virar `wipe`; `unknown` não
  deve ser promovido; tipos estruturais (`artifact`, `creature`, `land`) só
  devem ser fallback quando não houver papel funcional real.
- **Buckets sobrepostos**: `functional_tags_json` é membership overlay, não
  partição. Uma carta pode contar em `ramp` e `engine`; por isso
  `SUM(role_qty.values())` pode ser maior que `SUM(deck_cards.quantity)` sem
  indicar deck overfull.
- **Dedupe lógico de regras**: agregar por `card_id` evita duplicar cartas,
  mas não impede duas regras equivalentes no mesmo `battle_rules_json`.
  Definir `logical_rule_key` por carta/face/efeito/papel antes de agregar e
  manter somente o melhor exemplar por chave lógica.
- **Promoção confiável para `card_function_tags`**: tags derivadas de
  `card_battle_rules` só podem virar fonte canônica quando passarem por gate.
  No schema atual, `curated` é `source`, não `review_status`. Portanto, o gate
  deve considerar algo como `review_status IN ('verified', 'active')`,
  `source IN ('manual', 'curated')` quando aplicável e piso mínimo de
  `confidence`.
- **Limpeza de stale tags derivadas**: se a futura derivação usar
  `source='card_battle_rules_v1'`, cada rodada deve remover desse source as
  tags que não aparecem mais no conjunto derivado atual para os `card_id`
  tocados.
- **Hashes separados**: `deck_hash` deve representar somente estrutura do deck
  (`card_id`, `quantity`, `is_commander`). Mudanças em tags/regras devem gerar
  `semantics_hash` separado, para não quebrar baseline/quality gate quando só a
  camada semântica mudou.
- **Autoridade SQLite vs PostgreSQL**: `functional_tags_json` e
  `battle_rules_json` no SQLite Hermes são cache/snapshot operacional. A fonte
  de verdade continua sendo PostgreSQL (`card_function_tags`,
  `card_semantic_tags_v2`, `card_battle_rules`). A tabela SQLite normalizada de
  battle rules continua sendo a fonte para executor/auditor; o JSON agregado é
  para consumidores em contexto de deck.

### Próxima implementação recomendada

Concluído no Slice 1:

1. Criar uma query/helper compartilhado para agregação por `card_id`:
   - `functional_tags_json`: array ordenado de tags funcionais distintas;
   - `semantic_tags_v2_json`: JSON/array agregado quando aplicável;
   - `battle_rules_json`: array ordenado de regras com `effect_json`,
     `deck_role_json`, `source`, `confidence`, `review_status`,
     `rule_version` e `normalized_name`.
2. Usar `jsonb_agg(... ORDER BY ...)` no PostgreSQL e
   `COALESCE(..., '[]'::jsonb)` para saída determinística.
3. Atualizar `sync_pg_target_deck_to_hermes.py` para persistir esses campos no
   SQLite Hermes como JSON text, mantendo campos legados somente como projeção:
   - `functional_tag` pode continuar como primary/legacy role;
   - `functional_tags_json` deve preservar o conjunto completo;
   - `battle_rules_json` deve preservar todas as regras da carta.
4. Adicionar migração idempotente no SQLite Hermes para novas colunas JSON.
5. Validar suporte JSON do SQLite em runtime; se `json_each/json_extract` não
   estiverem disponíveis, os scripts devem fazer parse em Python.

Concluído no bridge de consumidores ativos:

6. Atualizar `master_optimizer_common.py` e `slot_optimizer.py` para consumir
   `functional_tags_json` com fallback para `functional_tag`.
7. Separar `deck_hash` estrutural de `semantics_hash`.
8. Atualizar `_mana_validator.py`, `_run_validation.py` e
   `_update_cron_status.py` para usar membership de `functional_tags_json`,
   mantendo `SUM(deck_cards.quantity)` como cardinalidade.

Ainda pendente:

9. Manter `card_battle_rules` fora da contagem de deckbuilding quando o objetivo
   for função de deck; usar essa tabela apenas como regra executável/revisável.
10. Revisar manualmente os candidatos positivos do slot scan Lorehold
   `semantic_snapshot_smoke` antes de qualquer apply:
   `Loran's Escape`, `Chain Lightning`, `Erode`, `Steelshaper's Gift`,
   `Furygale Flocking` e `The Battle of Bywater`.
11. Adicionar derivação controlada de `card_battle_rules` para
   `card_function_tags` somente depois de definir taxonomia canônica,
   gate de `source/review_status/confidence` e limpeza de stale tags.

Concluído no Slice 2:

12. Aplicar no Hermes AWS a implementação local de `semantics_hash`/`ruleset_hash`
   em baseline, quality gate, slot scan e apply; validado com backup,
   apply controlado e slot smoke. Evidência: backup
   `knowledge.db.pre-ruleset-76d828d2.20260611T194820Z`, baseline `id=2` com
   `60` jogos, `7` linhas de `slot_benchmarks` na phase `ruleset_hash_smoke`
   contendo `baseline_semantics_hash` e `baseline_ruleset_hash`, deck restaurado
   com `100` rows, `100` quantity e `1` commander.

Concluído no Slice 3:

13. Implementar `logical_rule_key` no snapshot Hermes, deduplicar regras
    equivalentes por face/variante/efeito/papel e manter o melhor exemplar por
    prioridade de `review_status`, `source`, `confidence` e `rule_version`.
    Smoke PG -> SQLite temporário e Hermes AWS real de Lorehold: `100` cards,
    `100` quantity, `1` commander, `100` regras vistas, `98` regras escritas,
    `2` deduped e `0` regras sem `logical_rule_key`.
14. Aplicar Slice 3 no Hermes AWS com backup
    `knowledge.db.pre-logical-rule-55af86c4.20260611T201027Z`; smoke remoto:
    baseline `id=3`, `36` jogos, phase `logical_rule_smoke`, `8` slot rows
    com `baseline_semantics_hash` e `baseline_ruleset_hash`, deck restaurado
    com `100` rows, `100` quantity, `1` commander e sem Mox premium.

Concluído no Slice 4 report-only:

15. Criar `derive_functional_tags_from_battle_rules.py` para propor, sem
    aplicar, candidatos `card_function_tags` derivados de regras confiáveis.
    Gate atual: `card_id` obrigatório, `review_status` `verified/active`,
    `source` `manual/curated`, confidence >= `0.75` e tag derivável.
    Smoke PG report-only revisado: `3156` regras vistas, `89` novos
    candidatos, `261` já presentes, `2806` rejeitados por gate, `30`
    candidatos low-risk review e `59` manual-review; `apply=false`.

### Testes obrigatórios antes de merge

- Unit test do helper SQL: uma carta com duas `card_battle_rules` e duas
  `card_function_tags` continua retornando uma linha de deck.
- Regressão PG -> Hermes: `cards_seen`, `quantity_seen`, `quantity_written` e
  `SUM(deck_cards.quantity)` permanecem 100 em Commander.
- Teste de determinismo: duas execuções sem mudança geram JSON byte-identical.
- Teste de idempotência: rerodar derivação/sync não duplica tags nem regras.
- Teste de stale cleanup: uma tag derivada com
  `source='card_battle_rules_v1'` some quando a regra que a originou deixa de
  derivar essa tag.
- Teste de gate de revisão: regra `needs_review` ou com baixa confiança aparece
  em `battle_rules_json`, mas não é promovida para `card_function_tags`.
- Teste de dedupe lógico: duas linhas equivalentes de regra geram uma entrada
  canônica em `battle_rules_json`, preservando metadados suficientes para
  auditoria.
- Teste de preservação: `battle_rules_json` contém todas as regras esperadas da
  carta; `functional_tags_json` contém todas as tags esperadas.
- Teste de hash: mudar somente tags/regras altera `semantics_hash`, mas não
  altera `deck_hash`.
- Teste de overlay: carta multi-role conta em todos os papéis aplicáveis, mas
  validadores não tratam `SUM(role_qty.values()) > total_cards` como overfull.
- Teste de separação semântica: land-back MDFC pode entrar como heurística
  `land_like`, mas não vira land real para tutor, legalidade ou castabilidade
  zone-sensitive.

### Fora de escopo desta correção

- Trocar todo o battle engine para judge engine completo.
- Achatar carta para uma única função definitiva.
- Usar `card_battle_rules` como tabela principal de papéis de deckbuilding.
- Criar enforcement novo de IA baseado em tags sem scorecard e replay real.

### Critério de conclusão

Este gap só deve ser fechado quando o sync PG -> Hermes, os scorecards e os
consumidores de deck enriquecido estiverem usando agregados por `card_id`, sem
`LIMIT 1` como mecanismo de preservação de cardinalidade, e com validação
automática impedindo que qualquer enriquecimento altere o total de cartas.

---

## 12. Battle/AI/Hermes/Lorehold - mapa para próximas tratativas (P1)

### Documento base

O detalhamento atual da lógica foi consolidado em:

- `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`

Usar este documento antes de aceitar qualquer plano novo sobre:

- battle simulator;
- geração de decks com IA;
- optimize/rebuild;
- Hermes crons;
- learned decks;
- Lorehold best-of learned;
- migração de conhecimento Hermes para backend.

O deep dive descreve o estado atual. O plano de implementação define a ordem
segura para codar. O documento de decisões separa dúvidas de produto/logística
que precisam de validação antes de virarem comportamento de produção.
O handoff `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md` lista as
perguntas que o owner deve responder quando uma fase sair dos defaults já
aprovados.

Decisão do owner em 2026-06-11: seguir com estabilidade de release primeiro,
sem ban global de Mox, learned decks apenas single-commander por enquanto,
duplicidade singleton Commander bloqueando save/import, metadados Hermes
ocultos para usuários normais, Hermes propondo e backend mandando,
`needs_review` fora de execução dura, `card_battle_rules` derivando tags só
quando confiável/rastreável, e primeiro slice limitado a agregação + snapshot
Hermes + testes.

### Gaps adicionais derivados do deep dive

| Prioridade | Gap | Evidência | Ação esperada |
|---|---|---|---|
| P1 | Identidade semântica de carta ainda em transição | Slice 2026-06-12 adicionou contrato/migration aditiva para `cards.oracle_id`, `cards.layout` e `cards.card_faces_json`; `scryfall_id` passa a ser tratado como printing id nas rotas/sync alterados; `DeckRulesService` agora usa `oracle_id` quando presente para bloquear singleton Commander e comandante duplicado no main deck em save/import/validate final, com fallback por nome físico normalizado; `/import/validate` chama a regra central em modo aviso | Rodar migration/backfill controlado, confirmar cobertura em produção e só depois usar `oracle_id` completo em learned-opponent sync e políticas de canonical printing |
| P1 | Learned deck ainda é single-commander | `validateCommanderLearnedDeckInput` exige `commanderQuantity == 1` e `mainQuantity == 99` | Evoluir contrato para pares oficiais somente quando houver corpus partner/background validado |
| P1 | Derivação de regra executável para função de deck ainda não tem política de apply | `derive_functional_tags_from_battle_rules.py` agora propõe candidatos report-only; após correção de taxonomia são `89` novos candidatos: `30` low-risk review e `59` manual-review; modo allowlist dry-run bloqueia manual-review por padrão | Revisar os 30 low-risk; próximo passo seguro é allowlist dry-run versionada, não apply; manter os 59 como manual-only até existir taxonomia/faces/stale cleanup |
| P1 | Consumidores Hermes históricos ainda podem assumir papel único | Consumidores ativos (`master_optimizer_common.py`, `slot_optimizer.py`, `_mana_validator.py`, `_run_validation.py`, `_update_cron_status.py`, `battle_analyst_v9.py`, `master_optimizer_apply.py`) já leem arrays; scripts manuais/importers antigos ainda consultam `functional_tag` direto | Classificação criada em `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`; migrar só scripts que virarem ativos |
| P2 | Backend tem simulador leve e Hermes tem simulador rico | `/decks/:id/simulate` mede abertura/curva; `battle_analyst_v9.py` roda Commander 4-player | Documentar contrato e não substituir um pelo outro sem API nova e testes de performance |
| P2 | `ml_prompt_feedback` coleta, mas ainda não decide política | `/ai/optimize` registra feedback automático | Usar feedback em ranking/prompt policy somente após scorecard e teste de regressão |
| P2 | Replay sem snapshot semântico completo | Hermes replays e forensic ainda dependem de nomes/effects legados em partes do pipeline; Slice 5 adicionou `logical_rule_key`, `oracle_hash`, `card_id`, `semantic_hash` e contagem de cobertura no forensic quando esses campos já existem no snapshot, sem mudar execução; Slice 6 report-only atualizou `audit_learned_opponent_card_identity.py` para separar `card_id` resolvido de `oracle_id` resolvido por múltiplas printings do mesmo oracle, sem escolher printing arbitrária; Hermes AWS em `9c6f44c9` confirmou `oracle_id_column_present=false`, `1200` instâncias, `1150` resolvidas por `card_id`, `50` ambíguas e `0` não resolvidas | Próximo passo: aplicar migration/backfill `cards.oracle_id` no banco controlado, rerodar o audit e só então decidir persistência de identidade para learned opponents; manter `needs_review` sem comportamento hard |
| P2 | Lorehold no-mox é política manual, não heurística universal | Learned deck 82 remove `Chrome Mox`, `Mox Diamond`, `Mox Opal` por decisão do produto | Não generalizar bloqueio de Mox para todos os comandantes/brackets sem regra explícita |
| P2 | Decisões de produto base aprovadas; exceções ainda precisam validação | `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md` registra os defaults aprovados em 2026-06-11 | Seguir Slice 1; qualquer mudança fora dos defaults exige nova validação |

Atualização 2026-06-11: Slice 1 foi implementado localmente em
`sync_pg_target_deck_to_hermes.py`. O sync agora exige `card_id`, agrega
`functional_tags_json`, `semantic_tags_v2_json` e `battle_rules_json`, grava
`deck_hash`, `semantics_hash` e `sync_run_id`, rejeita duplicatas antes de
escrever SQLite e não usa mais `LEFT JOIN LATERAL (...) LIMIT 1` para
`card_battle_rules`. Evidência em
`BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`. Slice 2 foi implementado
em `76d828d2` e aplicado no Hermes AWS real: `ruleset_hash` agora é persistido
em `deck_cards`, baseline/quality/slot/apply carregam hashes separados e o
smoke remoto confirmou `100` rows, `100` quantity, `1` commander, um
`deck_hash`, um `semantics_hash`, um `ruleset_hash` e `7` benchmarks
`ruleset_hash_smoke` com ambos hashes. Pendente real: revisar candidatos
Lorehold, ampliar amostra e definir política de derivação de
`card_battle_rules`. Slice 3 adicionou `logical_rule_key` e dedupe lógico ao
sync, com smoke PG -> SQLite temporário e Hermes AWS real mantendo 100/1,
deduplicando 2 regras equivalentes e gravando 98 regras com chave lógica.
Slice 4 adicionou derivação report-only de `card_battle_rules_v1` para
`card_function_tags`, sem escrita em PG. A revisão
`BATTLE_RULE_DERIVED_TAG_REVIEW_2026-06-11.md` corrigiu o mapeamento de
efeitos concretos de recursão para `recursion` em vez de `engine`; o relatório
atual propõe `89` candidatos, sendo `30` low-risk review e `59` manual-review.
Slice 5 adicionou proveniência semântica de replay sem alterar comportamento:
`battle_rule_registry.py` agora calcula `logical_rule_key` e carrega
`oracle_hash`; `battle_analyst_v9.py` carrega `card_id`/`semantics_hash` do
SQLite Hermes quando existem e propaga `card_id`, `semantic_hash`,
`logical_rule_key` e `oracle_hash` para eventos via `replay_rule_fields`;
`battle_forensic_audit.py` mede cobertura desses campos. Evidência em
`BATTLE_REPLAY_SEMANTIC_PROVENANCE_SLICE_2026-06-12.md`. Validação no Hermes
AWS em `74850947` mostrou `45/45` eventos com `logical_rule_key` e `24/45` com
`card_id`/`semantic_hash`; inspeção posterior mostrou que os `21` ausentes
vieram de decks reais aprendidos de oponentes, não do deck Lorehold
sincronizado. Ainda pende resolver IDs estáveis para learned-opponent cardlists
via PG/resolver confiável e definir se o `semantic_hash` deck-level atual deve
virar hash semântico por carta.

### Ordem recomendada de implementação

1. Revisar manualmente os candidatos positivos do slot scan Lorehold antes de
   qualquer apply.
2. Rodar nova amostra maior report-only para confirmar que `ruleset_hash` não
   mascara alteração semântica/regra como alteração estrutural.
3. Revisar os 30 candidatos low-risk de `card_battle_rules_v1`; usar o modo
   `--allowlist` apenas para dry-run versionado; manter os 59 candidatos
   scope-sensitive como manual-only até existir taxonomia/faces suficiente.
4. Adicionar IDs estáveis a learned-opponent cardlists via PG-backed resolver
   ou sync dedicado; não sintetizar IDs dentro do replay. O primeiro passo
   report-only é `audit_learned_opponent_card_identity.py`. Validação Hermes
   AWS em `191ead51`: `12` decks, `1200` instâncias, `1149` resolvidas,
   `1` não resolvida, `50` ambíguas, cobertura `0.9575`; antes de apply,
   resolver as ambiguidades explicitamente. Slice 6 atualiza o auditor para
   separar resolução concreta por `card_id` de resolução semântica por
   `oracle_id`; múltiplas printings do mesmo oracle passam a contar como
   cobertura semântica quando a coluna existe, mas continuam não persistindo
   `card_id` até existir política de printing canônica. Validação Hermes AWS
   em `9c6f44c9`: `oracle_id_column_present=false`, `1200` instâncias, `1150`
   resolvidas por `card_id`, `50` ambíguas, `0` não resolvidas e cobertura
   `0.958333`; portanto o próximo bloqueio real é migration/backfill do banco,
   não o parser do auditor. Amostra `dbbf4ab1`: ambiguidades principais são
   múltiplas printings (`Sol Ring`, `Ancient Tomb`, `Command Tower`,
   `Birds of Paradise`, `Phyrexian Metamorph`, `Cyclonic Rift`), então a
   correção deve definir política de
   oracle/canonical-printing identity; não usar `LIMIT 1`. Verificação em
   produção/Hermes em 2026-06-12 confirmou que `cards` ainda não possui coluna
   `oracle_id` dedicada e que `unaccent` não está disponível no PostgreSQL.
   Portanto, o auditor deve separar `card_id` exato, match diagnóstico por
   acento e ambiguidade por múltiplas printings, mas qualquer persistência
   continua bloqueada até existir uma identidade canônica explícita. Validação
   Hermes AWS em `91fd125f` zerou não resolvidas (`0`) e classificou `1150/1200`
   instâncias como resolvidas para diagnóstico (`1117` exact, `32` front,
   `1` accent-normalized); as `50` restantes são `multiple_printings_exact`.
5. Decidir se o `semantic_hash` deck-level atual é suficiente para auditoria de
   replay ou se o produto precisa de hash semântico por carta.
6. Criar helper/query de agregação por `card_id` em PG/backend se o contrato
   precisar ser consumido fora do sync Hermes.
7. Completar a formalização de identidade semântica de carta e faces antes de
   expandir regras DFC/MDFC: colunas `oracle_id`, `layout` e
   `card_faces_json` já foram introduzidas no backend/sync; ainda falta
   aplicar migration/backfill, medir cobertura e ligar consumidores críticos a
   essa identidade canônica.
8. Só depois evoluir learned decks para dois comandantes.
9. Só depois usar feedback ML como input de política.

### Critério de bloqueio

Qualquer plano futuro deve ser rejeitado ou reescrito se:

- tratar `card_battle_rules` como fonte principal de papel de deckbuilding;
- achatar toda carta para uma única função definitiva;
- usar `LIMIT 1` como solução final;
- alterar total de cartas por enriquecimento semântico;
- confundir `source='curated'` com `review_status`;
- tratar `rule_version` como string;
- transformar Hermes SQLite em fonte final do produto;
- aplicar swap Lorehold direto no produto sem handoff.

### Proximo handoff para validacao do owner

Quando uma decisão sair dos defaults aprovados, usar:

- `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`

Esse documento pergunta explicitamente sobre apply no Hermes real, migracao de
identidade semantica, singleton por identidade, visibilidade de metadados Hermes
no app, excecao no-mox, explicacao "por que esta carta", execucao de
`needs_review`, automacao futura de crons e prioridade do contrato
`deck_card_semantics_v1`.

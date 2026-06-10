# Implementation Gaps — PDF Spec vs Codebase

> Mapeamento da "Especificação técnica de regras faltantes para o ManaLoom Commander"
> para o código atual do battle_analyst_v9.py (engine ativo).
> Status: 2026-06-10

## Resumo

| Categoria | Implementado | Parcial | Ausente |
|---|---|---|---|
| Turno e Prioridade | 4/10 | 4/10 | 2/10 |
| SBAs e Triggers | 15/15 | 0/15 | 0/15 |
| Commander Rules | 5/8 | 1/8 | 2/8 |
| Mana e Custos | 2/6 | 4/6 | 0/6 |
| Targeting | 5/5 | 0/5 | 0/5 |
| Combate | 5/10 | 4/10 | 1/10 |
| Efeitos Contínuos | 4/5 | 1/5 | 0/5 |
| Tipos Complexos | 5/6 | 1/6 | 0/6 |
| Zonas e Objetos | 5/5 | 0/5 | 0/5 |
| Qualidade/QA | 7/7 | 0/7 | 0/7 |
| Regras oficiais 2026 | 9/11 | 2/11 | 0/11 |

---

## 1. Turno e Prioridade (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Fases completas (untap,upkeep,draw,main1,combat,main2,end,cleanup) | ✅ Parcial | 4605-4828 | Upkeep só tem One Ring trigger. Falta janela de prioridade no upkeep |
| Passos de combate (beg.combat,decl.atk,decl.blk,damage,end.combat) | ⚠️ Parcial | 4773-5065 | Funções formais existem; faltam escolhas/restrições avançadas |
| Prioridade formal (APNAP pass sequence) | ⚠️ Parcial | 2563-2620 | `run_priority_loop` cobre ações vazias do active player; falta pass sequence completa para todos |
| Prioridade com pilha vazia | ✅ OK | 2563-2645 | `priority_round(..., phase=main)` permite ação sorcery-speed e o turno usa `run_priority_loop` |
| Sem prioridade em untap/resolução | ✅ OK | 4622-4633 | Untap não chama priority |
| Passos/fases extras (extra turn, extra combat) | ⚠️ Parcial | 4789-4828 | `play_turn_sequence_v8` suporta extra turn, mas não extra combat/phase |
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
| Partner/Background/Friends Forever | ❌ Ausente | — | |
| Commander ninjutsu do CZ | ❌ Ausente | — | |
| Color identity de DFC/Adventure | ✅ Básico | v9: `compute_color_identity` | Agrega faces/partes/modos complexos |
| Legendary Vehicle/Spacecraft com P/T como commander | ✅ Básico | server + v9 | `DeckRulesService` e `is_commander_eligible_card` cobrem regra 2026 |
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
| Hybrid/Phyrexian mana | ⚠️ Parcial | v9: `parse_mana_cost`, `Player._payment_plan` | Cobre híbrido colorido `{W/U}` e Phyrexian colorido `{W/P}`; `{2/W}`, `{2/P}` e restrições card-specific seguem pendentes |
| Mana pool com spend restrictions | ⚠️ Parcial | 2288, 2311 | ManaPool existe mas sem restrictions |

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
| Declaração de atacantes | ⚠️ Parcial | v9: `declare_attackers_step` | Função formal existe, mas escolha ainda é heurística/automática |
| Declaração de bloqueadores | ⚠️ Parcial | 4421-4462 | Bloqueadores calculados, não declarados |
| Blocked state persistente | ✅ OK | — | Bloqueado permanece mesmo se blocker morre |
| First/Double strike | ✅ OK | 4576-4580 | |
| Trample | ⚠️ Parcial | 4567-4568 | Funciona mas sem order formal |
| Deathtouch | ✅ OK | 4523-4528 | |
| Lifelink | ✅ OK | 4510-4511 | |
| Damage assignment multiplayer | ⚠️ Parcial | 4372-4418 | Só ataca 1 oponente por vez |
| End of combat triggers | ✅ Básico | v9: `trigger_end_of_combat` | Permanentes com `trigger=end_of_combat` entram na stack por APNAP e resolvem efeitos genéricos seguros |
| Requirements/restrictions (must attack, can't attack alone) | ❌ Ausente | — | |

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
| Persistência operacional da telemetria | ✅ Básico | v9: `write_engine_metrics_snapshot`, `MANALOOM_ENGINE_METRICS_DIR` | Snapshots JSON sanitizados por run do optimizer quando env var é definida |

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
2. **Targeting avançado** — seleção complexa/card-specific além de remoções declaradas
3. **Suite de conformidade expandida** — triggers aninhadas, escolha de ordenação e regressões v9
4. **Operacionalização Hermes** — plugar relatório agregado de telemetria nas crons se necessário

---

## 10. Regras oficiais 2026 / Mecânicas modernas (P1-P2)

Fonte consolidada: `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`.

| Item | Status | Implementação | Limite restante |
|---|---|---|---|
| Omen cards | ✅ Básico | `get_card_characteristics(..., cast_mode="omen")` e `compute_color_identity` | Efeitos card-specific por carta concreta |
| Station cards | ✅ Básico | `activate_station_ability` | Escolha humana/interativa de criatura a stationar |
| Spacecraft | ✅ Básico | `is_vehicle_or_spacecraft_card`, `activate_station_ability` | Efeitos específicos de cada Spacecraft |
| Warp | ✅ Básico | `cast_warp_spell_from_hand`, `process_warp_end_step`, `cast_warp_card_from_exile` | Interações card-specific e permissões complexas |
| Prepare / Preparation cards | ✅ Básico | `prepare_spell_copy`, `cleanup_prepared_copies` | Cast completo da cópia preparada por UI/interação |
| Paradigm | ✅ Telemetria básica | `resolve_paradigm_spell` | Cópia automática na primeira main phase futura |
| Flashback | ✅ Básico | `cast_flashback_spell_from_graveyard`, exile replacement | Custos/restrições específicas por carta |
| Lander tokens | ✅ Básico | `create_lander_token` | Token variants por carta concreta |
| Void/Repartee/Opus/Increment/Infusion/Converge | ✅ Telemetria | `modern_ability_word_signals` | Sem enforcement porque ability words não têm efeito próprio |
| Multiplayer attack distribution | ✅ Básico | `assign_attackers_to_defenders` + `multi_defender_attack` | Requirements/restrictions avançadas |
| No sideboard/outside-game em Commander | ⚠️ Documentado | gap registrado nesta seção | Validar rotas/deck construction se o produto expuser sideboard/wishboard |

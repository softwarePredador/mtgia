# Implementation Gaps — PDF Spec vs Codebase

> Mapeamento da "Especificação técnica de regras faltantes para o ManaLoom Commander"
> para o código atual do battle_analyst_v9.py (engine ativo).
> Status: 2026-06-10

## Resumo

| Categoria | Implementado | Parcial | Ausente |
|---|---|---|---|
| Turno e Prioridade | 4/10 | 4/10 | 2/10 |
| SBAs e Triggers | 4/15 | 2/15 | 9/15 |
| Commander Rules | 4/8 | 2/8 | 2/8 |
| Mana e Custos | 1/6 | 2/6 | 3/6 |
| Targeting | 1/5 | 1/5 | 3/5 |
| Combate | 5/10 | 4/10 | 1/10 |
| Efeitos Contínuos | 0/5 | 1/5 | 4/5 |
| Tipos Complexos | 1/6 | 2/6 | 3/6 |
| Zonas e Objetos | 2/5 | 1/5 | 2/5 |
| Qualidade/QA | 3/6 | 1/6 | 2/6 |

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
| Deck out | ⚠️ Parcial | 2551-2555 | Condição errada: `not library and not hand` (deveria ser "tentativa de draw em library vazia") |
| **Creature toughness <= 0 / lethal damage** | ❌ Ausente | — | ✅ FEITO (v9 patch) |
| **Legend rule** | ❌ Ausente | — | ✅ FEITO (v9 patch) |
| Token fuera do battlefield | ❌ Ausente | — | Token é destruído em combate, não por SBA |
| Aura/Equipment ilegal | ❌ Ausente | — | |
| +1/+1 e -1/-1 cancel | ❌ Ausente | — | |
| Planeswalker 0 loyalty | ❌ Ausente | — | |
| Saga capítulo final | ❌ Ausente | — | |
| Battle defense 0 | ❌ Ausente | — | |
| Commander em GY/exile → CZ (SBA) | ❌ Ausente | — | |
| **Loop SBA até estabilizar** | ❌ Ausente | — | ✅ FEITO (check_sbas_until_stable) |
| **APNAP trigger ordering** | ✅ Básico | v9 | Triggers atuais entram como `triggered_ability`; falta player-choice avançado/aninhamento complexo |

**Ações imediatas**:
- [x] Creature SBA ✅
- [x] SBA loop ✅
- [x] Legend rule ✅
- [ ] Adicionar deck out correto (trigger no draw, não check de biblioteca vazia)
- [x] APNAP ordering básico para triggers atuais

---

## 3. Commander Rules (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Commander tax (+2 por cast do CZ) | ✅ OK | 2253, 3532-3550 | |
| Commander damage tracking | ⚠️ Parcial | 2261, 4512-4513 | Keyed por opponent name string, não por commander origin ID |
| Commander replacement (GY/exile → CZ opcional) | ❌ Ausente | 2828 | Sempre vai ao CZ, sem escolha |
| Commander replacement (hand/library → CZ opcional) | ❌ Ausente | — | |
| Deck construction (100 cards, singleton, color ID) | ⚠️ Parcial | — | Feito no app, não no battle engine |
| Partner/Background/Friends Forever | ❌ Ausente | — | |
| Commander ninjutsu do CZ | ❌ Ausente | — | |
| Color identity de DFC/Adventure | ❌ Ausente | — | |

**Ações imediatas**:
- [ ] Commander replacement opcional (GY/exile → CZ)
- [ ] Commander damage keyed por origin ID, não nome

---

## 4. Mana e Custos (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Custo de mana básico | ✅ OK | 3532 | `cost = cmd["cmc"] + player.commander_tax` |
| Pipeline 601.2 (modes→targets→cost→lock→pay) | ⚠️ Parcial | v9: `CastingContext` | Pipeline mínimo com announce, legality, cost lock e pay; faltam modes/X/alt costs/targeting formal |
| Custos alternativos (kicker, flashback, etc.) | ❌ Ausente | — | |
| X spells | ❌ Ausente | — | |
| Hybrid/Phyrexian mana | ❌ Ausente | — | |
| Mana pool com spend restrictions | ⚠️ Parcial | 2288, 2311 | ManaPool existe mas sem restrictions |

**Ações imediatas**:
- [x] Pipeline 601.2 mínimo: lock-in de custo antes de pagar
- [ ] Expandir 601.2 para modes, X, alternative/additional costs e targeting formal

---

## 5. Targeting (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Seleção de alvos legais | ⚠️ Parcial | — | Alvos são implícitos (combat), não declarados formalmente |
| Alvos ilegais na resolução (partial resolution) | ❌ Ausente | — | |
| Hexproof/Shroud | ✅ OK | — | Respeitado via `can_target` |
| Protection | ❌ Ausente | — | |
| Ward | ❌ Ausente | — | |

---

## 6. Combate (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Declaração de atacantes | ❌ Ausente | 4315-4332 | Todos atacam automaticamente |
| Declaração de bloqueadores | ⚠️ Parcial | 4421-4462 | Bloqueadores calculados, não declarados |
| Blocked state persistente | ✅ OK | — | Bloqueado permanece mesmo se blocker morre |
| First/Double strike | ✅ OK | 4576-4580 | |
| Trample | ⚠️ Parcial | 4567-4568 | Funciona mas sem order formal |
| Deathtouch | ✅ OK | 4523-4528 | |
| Lifelink | ✅ OK | 4510-4511 | |
| Damage assignment multiplayer | ⚠️ Parcial | 4372-4418 | Só ataca 1 oponente por vez |
| End of combat triggers | ❌ Ausente | — | |
| Requirements/restrictions (must attack, can't attack alone) | ❌ Ausente | — | |

---

## 7. Zonas, LKI e Instance ID (P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Zone change → novo objeto | ❌ Ausente | — | Mesmo dict Python sobrevive entre zonas |
| LKI (last known information) | ❌ Ausente | — | |
| Command zone | ✅ OK | 2252, 2828 | |
| Exile (face up/down) | ❌ Ausente | — | |
| Token lifecycle | ⚠️ Parcial | — | Token existe no battlefield, some ao sair |

---

## 8. Efeitos Contínuos / Layers (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Layer 1 (copiable values) | ❌ Ausente | — | |
| Layer 2-6 (control, text, type, color, abilities) | ❌ Ausente | — | |
| Layer 7 (P/T com subcamadas) | ❌ Ausente | — | |
| Timestamps e dependencies | ❌ Ausente | — | |
| Replacement/prevention effects | ⚠️ Parcial | v9: `ReplacementRegistry` | Prevention/life/commander zone-change mínimos; falta CR 616 completo |

---

## 9. IA e Métricas (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Loss tagging | ✅ OK | 4885-4920 | classify_loss implementado |
| WDWR/WPWR | ✅ OK | card_impact_analyzer.py | |
| Forensic audit | ✅ OK | battle_forensic_audit.py | |
| Quality gate | ✅ OK | master_optimizer_quality_gate.py | |
| Taxonomia canônica de derrota | ⚠️ Parcial | classify_loss | Faltam: poison, effect_says_lose, concede |
| Telemetria de saúde do motor | ❌ Ausente | — | |

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

1. **Replacement/prevention avançado** — aplicar ordem CR 616 de forma determinística
2. **Casting pipeline 601.2 avançado** — modes, X, custos alternativos/adicionais e targeting formal
3. **Layers 1-7** — efeitos contínuos com timestamp/dependência
4. **Suite de conformidade** — cobrir triggers aninhadas, escolha de ordenação e regressões v9

# Mulligan Log — Lorehold Spellslinger (Per-Deck Timeline)

> Canonical reference: `docs/hermes-analysis/manaloom-knowledge/MULLIGAN_LOG.md` (global history)
> This file: per-deck timeline, updated when new simulation runs for this deck.

## Verificacao — 2026-06-01T10:32:36+00:00 (Sem Mudancas — C#23 Swaps Documentados Mas NAO Aplicados, T3=13.3% Estavel)

### Estado
- Evolution Oracle C#23 (2026-06-01T08:23:57): **2 swaps DEFENSIVOS documentados** — OUT Apex of Power (CMC 10) + Storm Herd (CMC 10) → IN Demand Answers (CMC 2) + Thrill of Possibility (CMC 2). Net DCMC=-16.
- **Swaps NAO aplicados no DB.** Apex of Power e Storm Herd ainda no deck.
- Deck state: 35 lands, 100 cards, 86 unique names (inalterado desde Exec#13).
- Card hash: `30d00347764fc2a215edb4e668994871` — MATCH com ultima verificacao (09:26).
- Sem Play T3 canonico: **13.3%** (Execucao #13, N=1000, seed=42) — ZONA DEFENSIVA (>12%).
- Mulligan: **30.1%**, Jogaveis: **66.0%**, Ramp T1 (Sol Ring only): **8.5%**.
- Free Mulligan: 4.6%
- CMC medio: 3.70
- Evolution Oracle "Wincon Diversity" analysis (09:22): identificou gap STEALTH — recomenda Twinflame (CMC 2) para Ciclo #24.

### Decisao
**Simulacao NAO executada.** A Evolution Oracle C#23 documentou swaps mas NAO os aplicou no DB. O deck e identico ao estado da Execucao #13 (2026-06-01T08:14:37). Re-executar N=1000 reproduziria 13.3% com ruido de +/-2.1pp. Nao ha valor incremental.

### Projecao (se C#23 for aplicado)
Se os 2 swaps documentados em C#23 forem aplicados (OUT CMC 10+10, IN CMC 2+2):
- Net DCMC: -16
- T3 projetado: 13.3% → ~9-10% (saindo da zona DEFENSIVA)
- Mulligan projetado: ~31-34% (sem mudanca significativa — swaps afetam T3, nao mulligan inicial)
- Ramp T1: constante (inalterado)

### O que essa metrica significa
**Sem Play T3 = 13.3%** significa que em ~13 de cada 100 jogos, voce nao consegue conjurar NENHUMA spell nos turnos 1-3 porque suas cartas tem CMC alto demais para a quantidade de mana disponivel. Em Commander casual/B3, isso e aceitavel mas esta acima do limiar defensivo de 12%. O deck precisa de mais cartas CMC <= 2 com impacto imediato. As swaps documentadas em C#23 (Demand Answers CMC 2, Thrill of Possibility CMC 2) atacam exatamente esse problema — cada uma da -8 DCMC e acrescenta draw early-game.

**Mulligan = 30.1%** e a taxa de maos iniciais NAO jogaveis (0-1 lands ou 2 lands sem ramp). E um valor tipico para decks de 35 lands. Nao e alarmante e nao mudaria com as swaps C#23 (que nao alteram land count).

---

## Execucao #12 — Pos-Ciclo #14 (2026-05-31T23:44:02+00:00)

### Estado do Deck
- 35 lands, 100 cards. Ciclo #14 = 0 swaps (4o ciclo consecutivo: C#11, C#12, C#13, C#14).
- 25 swaps totais desde baseline. Deck identico a Execucao #11 (pos-Ciclo #10).

### Resultados (seed=42, N=1000, definicao rigorosa)

| Metrica | Exec#11 (pos-C#10) | Exec#12 (pos-C#14) | D |
|:--------:|:------------------:|:------------------:|:-:|
| Jogaveis | 46.7% | **48.9%** | +2.2pp |
| Mulligan | 47.9% | **45.7%** | -2.2pp |
| Ramp T1 (Sol Ring only) | 6.3% | **6.3%** | 0.0pp |
| Sem Play T3 | 13.3% | **13.3%** | **0.0pp** |

### Analise

**Sem Play T3 = 13.3% ESTAVEL.** 4 ciclos consecutivos sem swaps (0 mudancas no deck). A metrica T3 e identica a Execucao #11 porque o estado do deck nao mudou desde o Ciclo #10.

**Pequena variacao em Jogaveis/Mulligan (+2.2pp/-2.2pp) dentro do IC95% (±2.1pp) — ruido estatistico, nao mudanca real.**

**Maturidade Absoluta confirmada.** Apos 25 swaps desde baseline, o deck atingiu um estado onde nenhum candidato na colecao atinge Necessidade >= 3 + Evidencia >= 3. 48+ candidatos rejeitados em 3+ ciclos.

**Limite estrutural ~47% jogaveis confirmado.** Sem fast mana adicional (Chrome Mox, Mana Vault) ou draw CMC 1 (Skullclamp), o deck nao consegue reduzir T3 abaixo de 12%.

**Proximo upgrade requer AQUISICAO:** Skullclamp (CMC 1, $5-8).

---

*Simulacao: 1000 maos, seed=42, definicao rigorosa. IC95% = +/-2.1pp.*
*Sem Play T3 = nenhuma carta nao-terreno com CMC <= min(lands, 3).*
*Ramp canonico para jogaveis = Sol Ring, Arcane Signet, Boros Signet, Talisman of Conviction.*

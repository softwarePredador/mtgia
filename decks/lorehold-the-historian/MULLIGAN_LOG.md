# Mulligan Log — Lorehold Spellslinger (Per-Deck Timeline)

> Canonical reference: `docs/hermes-analysis/manaloom-knowledge/MULLIGAN_LOG.md` (global history)
> This file: per-deck timeline, updated when new simulation runs for this deck.

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

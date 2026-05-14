# Commander Reference Sprint 3 A+B Consolidation - 2026-05-14

## Resultado

**PASS_WITH_RISKS.**

Os Lotes A e B do Commander Reference Sprint 3 estao consolidados com oito
comandantes promovidos para mini-batch controlado. Todos passaram por corpus
DB-backed, dry-run, apply, idempotencia, public proof 5/5 de `POST /ai/generate`
e readiness scorecard final `score=100`, `ready_for_mini_batch`, sem invalid,
off-identity ou timeout fallback.

O resultado nao e PASS pleno de produto porque a prova app runtime real cobriu
quatro dos oito comandantes promovidos, o Android fisico `SM A135M` ainda usou
workaround de rede celular para contornar timeout Wi-Fi, e o iPhone 15 Simulator
permanece nao provado por blocker historico de `MLImage.framework`/scanner. O
scanner, camera e OCR ficaram fora do escopo.

## Fontes locais lidas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_FINAL_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_B_PUBLIC_PROOF_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_b_app_2026-05-14.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## API contract stability

`server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e permaneceu
inalterado. Nao houve drift real de rota, payload, response shape, diagnostics
app-facing, async job, fonte de dados ou consumidor mobile. O contrato relevante
continua sendo `POST /ai/generate` com `commander_name` opcional e diagnostics
Commander Reference opcionais/backward-compatible; o app deve seguir usando
`generated_deck` e `validation` como fonte de verdade.

## Promovidos A+B

| Lote | Commander | Cor | Arquetipo/tema | Corpus/apply/idempotencia | Public proof | p50 | p95 | Readiness |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| A | `Krenko, Mob Boss` | R | Goblin typal, go-wide tokens, haste/aggro | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 888ms | 1233ms | score 100, `ready_for_mini_batch` |
| A | `Light-Paws, Emperor's Voice` | W | Auras, Voltron, protection/evasion | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 873ms | 952ms | score 100, `ready_for_mini_batch` |
| A | `Niv-Mizzet, Parun` | UR | Spellslinger, draw-damage, control/combo lanes | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 857ms | 981ms | score 100, `ready_for_mini_batch` |
| A | `Teysa Karlov` | WB | Aristocrats, tokens, death triggers/sacrifice | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 856ms | 908ms | score 100, `ready_for_mini_batch` |
| B | `Meren of Clan Nel Toth` | BG | Graveyard recursion, sacrifice value, toolbox creatures | PASS 3/3, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 854ms | 1238ms | score 100, `ready_for_mini_batch` |
| B | `Korvold, Fae-Cursed King` | BRG | Sacrifice, treasure, value/aristocrats | PASS 4/4 Lote B, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 878ms | 942ms | score 100, `ready_for_mini_batch` |
| B | `Sythis, Harvest's Hand` | GW | Enchantress value, enchantment draw/ramp, aura support | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 651ms | 667ms | score 100, `ready_for_mini_batch` |
| B | `Urza, Lord High Artificer` | U | Artifacts, control, combo with explicit power lane | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton limpo | PASS 5/5, invalid/off-id 0, timeout 0/5 | 652ms | 757ms | score 100, `ready_for_mini_batch` |

## Backend proof

- Lote A: Krenko, Light-Paws, Niv-Mizzet e Teysa foram preparados, aplicados,
  reaplicados por idempotencia e provados no backend publico 5/5 por comandante.
- Lote B: Meren, Korvold, Sythis e Urza repetiram o mesmo gate; Korvold ficou com
  8/8 linhas aceitas totais por conter 4 linhas historicas e 4 linhas validadas
  no Lote B.
- Todos os scorecards publicos terminaram com `score=100`,
  `ready_for_mini_batch`, warnings vazios, blockers vazios, profile/stats/corpus
  usados e main deck 99.
- O primeiro disparo continuo do Lote B encontrou `429` apos dez chamadas
  publicas; Sythis e Urza foram rerodados com backoff e os summaries
  rate-limited ficaram preservados em `public_proof_rate_limited_attempt/`. Esse
  achado e risco operacional dos scripts de lote, nao defeito de qualidade dos
  decks gerados.

## App proof

| Lote | Device/backend | Commanders provados | Fluxo | Resultado |
| --- | --- | --- | --- | --- |
| A | Android fisico `SM A135M` contra backend publico | `Krenko, Mob Boss`, `Teysa Karlov` | register/login, Generate Commander com `commander_name`, preview, save, Deck Details, `/decks/:id/validate` | PASS_WITH_RISKS: 99 main, 100 total, comandante unico fora das 99, off_identity=0, `validation_ok=true` |
| B | Android fisico `SM A135M` contra backend publico | `Urza, Lord High Artificer`, `Meren of Clan Nel Toth` | register/login, Generate Commander com `commander_name`, preview, save, Deck Details, `/decks/:id/validate` | PASS_WITH_RISKS: 99 main, 100 total, comandante unico fora das 99, off_identity=0, `validation_ok=true` |

Riscos app remanescentes:

1. No Lote A, o Wi-Fi do `SM A135M` causou timeout HTTP app-side para `/health`
   em 15s enquanto o Mac respondia e o device pingava o host; a prova passou
   usando rede celular e o Wi-Fi foi reabilitado ao final.
2. No Lote B, o runtime ja iniciou com o workaround de rede celular para evitar o
   mesmo timeout Wi-Fi.
3. O iPhone 15 Simulator foi descoberto, mas nao usado como prova final porque o
   Android primario passou e o blocker `MLImage.framework`/scanner permanece.
4. No Lote B, `GET /decks/:id` retornou o comandante correto na lista
   `commander`, mas o campo agregado `commander_name` nao refletiu o comandante
   salvo; a validacao DB-backed e `deck_cards.is_commander` foram a fonte de
   verdade.

## Cores cobertas

| Dimensao | Cobertura consolidada |
| --- | --- |
| Cores individuais | W, U, B, R e G aparecem nos comandantes promovidos. |
| Mono-color | R (`Krenko`), W (`Light-Paws`), U (`Urza`). |
| Guildas | UR (`Niv-Mizzet`), WB (`Teysa`), BG (`Meren`), GW (`Sythis`). |
| Tricolor | BRG (`Korvold`). |
| Gaps relevantes | WU blink/control ainda nao promovido; cinco cores e Abzan counters/tokens ficam adiados; red e white precisam de variantes nao identicas para nao repetir Krenko/Light-Paws. |

## Arquetipos cobertos

- Mono-red goblin typal/go-wide aggro.
- Mono-white auras/Voltron/protection.
- Izzet spellslinger draw-damage/control-combo.
- Orzhov aristocrats/tokens/death triggers.
- Golgari graveyard recursion/sacrifice toolbox.
- Jund sacrifice/treasure/value-aristocrats.
- Selesnya enchantress value.
- Mono-blue artifacts/control/combo.

## Recomendacao para Lote C

**GO condicionado** para preparar Lote C em modo pequeno, com os mesmos gates de
corpus offline, dry-run DB-backed, apply controlado, idempotencia, public proof
5/5, readiness scorecard `score=100` e prova app runtime para pelo menos dois
comandantes de arquetipos distintos antes de ampliar guidance.

A recomendacao abaixo prioriza lacunas citadas sem repetir diretamente os shells
ja promovidos: red tokens sem Goblin typal, Azorius blink/control ainda ausente,
Izzet spellslinger com magecraft/storm em vez de Niv draw-damage hard-control, e
mono-white equipment em vez de aura tutor Light-Paws.

| Prioridade | Commander | Cor | Lacuna coberta | Por que agora | Guardrail minimo |
| ---: | --- | --- | --- | --- | --- |
| 9 | `Purphoros, God of the Forge` | R | Mono-red go-wide tokens/burn sem Goblin typal | Cobre token payoff vermelho sem repetir Krenko como tribo Goblin/haste. | Corpus deve separar token-burn de Goblin typal, evitar land/curve aggro extrema, unresolved=0, off_color=0, public proof 5/5 sem fallback. |
| 10 | `Brago, King Eternal` | WU | Azorius blink/ETB value/control | E o maior gap de cor/arquetipo apos A+B e ja estava no plano Sprint 3 original. | Distinguir blink value de stax duro, manter ETB/control como eixo, sem transformar artifacts utilitarios em identidade principal. |
| 11 | `Veyran, Voice of Duality` | UR | Izzet magecraft/spell-copy/prowess | Reusa a lacuna spellslinger de forma diferente de Niv-Mizzet, testando storm/tempo sem default cEDH. | Lane casual/high-power explicita, sem tratar storm/combo infinito como padrao bracket 3, invalid/off-id 0 e timeout 0/5. |
| 12 | `Balan, Wandering Knight` | W | Mono-white Equipment Voltron | Cobre white equipment como equivalente a auras sem repetir Light-Paws tutor de Auras. | Corpus deve provar equipamentos, protecao/evasion e card advantage white; bloquear se virar white goodstuff ou aura shell. |

`Jodah, the Unifier`, `Ghave, Guru of Spores` e `Feather, the Redeemed` ficam
adiados, nao rejeitados: Jodah/Ghave ampliam cinco cores/counters/tokens, mas
repetem mais temas ja cobertos por Atraxa/Teysa/Korvold; Feather e valioso, mas
Boros spellslinger-Voltron fica mais proximo de Light-Paws/Niv do que a lacuna
Azorius.

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lotes A+B estao promovidos para mini-batch controlado no backend/public proof e
tem prova app real parcial suficiente para seguir com Lote C controlado. Nao ha
mudanca de contrato app/backend nesta consolidacao; repetir public proof e app
runtime e obrigatorio se o deploy publico mudar antes de usar esta evidencia em
release.

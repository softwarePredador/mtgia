# Commander Reference Sprint 4 Track A Coverage - 2026-05-14

## Verdict

**PASS_WITH_RISKS.**

Track A propos uma fila Sprint 4 por lacunas de cores/arquetipos sem alterar
runtime, API map, manual, tracker ou contratos app-facing.

O risco principal e que a expansao ainda nao deve virar promocao automatica:
cada candidato precisa repetir corpus offline, dry-run DB-backed, apply,
idempotencia, public proof 5/5 sanitizado de `/ai/generate` e readiness
scorecard `score=100`.

## Fontes locais lidas

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_AB_CONSOLIDATION_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DATA_QUALITY_AUDIT_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PIPELINE_GAP_AUDIT_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_MINI_BATCH_COVERAGE_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_A_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_B_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_C_2026-05-12.md`

## Fontes web consultadas

Consulta somente de contexto/legality, sem copiar decklists completas:

- Scryfall API `cards/named`: confirmou que Feather, Chulane, Miirym,
  K'rrik, Giada, Lathril e Isshin sao criaturas lendarias legais em Commander
  e retornou suas identidades de cor.
- EDHREC commander pages: URLs de Commander existentes e HTTP 200 para os sete
  candidatos acima, usadas apenas como sinal de contexto Commander, nao como
  decklist.

## Fatos locais provados

### Estado promovido atual

Total promovido auditado: **20 comandantes**.

| Grupo | Promovidos |
| --- | --- |
| Mini-batch inicial | Lorehold, Prosper, Aesi, Edgar, Dina, Zimone |
| Sprint 2 | Kinnan, Muldrotha, Yuriko, Winota, Atraxa |
| Sprint 3 A+B | Krenko, Light-Paws, Niv-Mizzet, Teysa, Meren, Korvold, Sythis, Urza |
| Sprint 3 C | Brago |

### Bloqueados/adjuntos recentes

| Commander | Estado local |
| --- | --- |
| Purphoros, God of the Forge | Corpus limpo 5/5, mas sem profile/card_stats/deterministic; public proof nao usou reference |
| Veyran, Voice of Duality | Corpus limpo 4/4, mas sem profile/card_stats/deterministic |
| Balan, Wandering Knight | Corpus limpo 4/4, mas sem profile/card_stats/deterministic |
| Feather, the Redeemed | Tem profile/card_stats locais, mas sem corpus/public proof |
| Jodah, the Unifier | Profile legado nao utilizavel como Commander Reference forte |
| Ghave, Guru of Spores | Sem dados locais provados |

## Matriz de cobertura atual

| Dimensao | Coberto | Lacunas relevantes |
| --- | --- | --- |
| Mono-color | W, U, R | Mono-B e mono-G ainda nao promovidos |
| Guildas | RW, BR, GU, BG, UB, UR, WB, GW, WU | RG ainda ausente |
| Tricolor | WBR, BRG, BGU | Bant GWU, Temur GUR, Abzan WBG, Jeskai URW ainda ausentes |
| 4 cores | WUBG Atraxa | Demais combinacoes 4c ausentes |
| 5 cores | Nenhum promovido utilizavel | Jodah legado nao serve como guidance forte |
| Typal | Vampires, Goblins, Ninjas parcial | Angels, Elves, Dragons ainda nao promovidos |
| Voltron | Auras/Light-Paws | Equipment bloqueado em Balan; Heroic/target-spells ainda ausente |
| Combo/high power | Kinnan, Urza, Niv, Korvold com lanes | Mono-B combo/life-as-mana ausente |
| Creature value/ETB | Brago blink; Aesi lands | Bant creature-cast/bounce ainda ausente |
| Combat triggers | Winota aggro | Attack-trigger doubling Isshin ainda ausente |

## 4 candidatos prioritarios para Sprint 4

| Ordem | Commander | Cores | Lacuna coberta | Fato local | Justificativa |
| ---: | --- | --- | --- | --- | --- |
| 1 | Feather, the Redeemed | RW | Boros heroic/protection spells, target-spell Voltron | Profile/card_stats existentes; corpus ausente | Menor delta tecnico entre candidatos nao promovidos: falta corpus e public proof. Apesar de RW ja existir, o padrao e diferente de Lorehold/Winota. |
| 2 | Chulane, Teller of Tales | GWU | Bant creature-cast value, land drops, bounce/ETB | Profile high, 35 resolved, 0 unresolved/off-color | Abre Bant e testa value engine de criatura sem confundir com Brago blink ou Aesi lands. |
| 3 | Miirym, Sentinel Wyrm | GUR | Temur dragons, clone/copy, ramp, ETB damage | Profile high, 33 resolved, 0 unresolved/off-color | Cobre Temur e aproxima lacuna RG por identidade GUR, alem de typal Dragon ainda ausente. |
| 4 | K'rrik, Son of Yawgmoth | B | Mono-black life-as-mana/combo | Profile/card_stats existentes; 28 resolved, 0 unresolved/off-color | Preenche mono-B, mas exige guardrails fortes para nao transformar bracket 3 casual em shell cEDH. |

## 3 backups

| Backup | Commander | Cores | Por que fica no banco |
| ---: | --- | --- | --- |
| 1 | Giada, Font of Hope | W | Angels/counters typal; localmente resolvida, mas mono-W ja tem Light-Paws e Balan adjunto |
| 2 | Lathril, Blade of the Elves | BG | Elf typal/tokens/drain; boa cobertura typal, mas BG ja tem Dina/Meren |
| 3 | Isshin, Two Heavens as One | WBR | Attack triggers/combat; profile pronto, mas Mardu ja tem Edgar e RW/Winota cobre parte do eixo agressivo |

## Guardrails por candidato

### Feather, the Redeemed

- Separar heroic/protection/cantrip recursion de aura Voltron Light-Paws.
- Nao copiar lista pronta; usar apenas agregados, roles e pacotes recorrentes.
- Corpus deve passar com commander 1/99, main 99, unresolved 0, off-color 0 e
  singleton limpo.
- Bloquear se virar Boros goodstuff ou pseudo-Light-Paws.

### Chulane, Teller of Tales

- Separar Bant creature-cast/bounce de Brago blink puro.
- Explicitar lane casual vs combo; nao promover loops deterministicos como
  default bracket 3.
- Garantir pacote de criaturas, ramp/land drops, interacao e payoff sem
  superconcentrar em combo.

### Miirym, Sentinel Wyrm

- Validar Dragon typal/ramp/copy sem virar Temur goodstuff generico.
- Controlar curva alta e numero de ramp pieces para evitar deck injogavel no
  bracket alvo.
- Bloquear se corpus depender demais de staples caros ou linhas combo high-power
  como default.

### K'rrik, Son of Yawgmoth

- Separar mono-black value/combo casual de cEDH.
- Nao usar tutor/fast-mana/storm como padrao casual.
- Exigir linguagem de power lane explicita e public proof sem invalid/off-identity.
- Monitorar risco de listas homogeneas por combo core.

## Riscos

| Risco | Impacto | Mitigacao |
| --- | --- | --- |
| Expandir antes de corrigir Purphoros/Veyran/Balan | Repetir bloqueio de profile/card_stats/deterministic | Tratar P/V/B como lane de remediacao, nao promocao automatica |
| Corpus bruto em artifacts | Risco compliance/copyright | Persistir apenas summaries/agregados quando possivel |
| K'rrik puxar logica cEDH | Casual recebe shell competitivo indevido | Power lane obrigatoria e bracket-aware |
| Chulane/Miirym sem corpus provado | Pode falhar por unresolved/off-color | Fazer dry-run antes de qualquer apply |
| 429 em provas publicas | Batch pode falhar por rate limit | Backoff e execucao em baixo volume |
| iPhone 15 ainda nao provado | Risco runtime mobile posterior | Nao bloquear Track A documental, mas exigir runtime antes de release amplo |

## Recomendacao de ordem

1. **Feather, the Redeemed** - maior prontidao local: profile/card_stats existem;
   falta corpus.
2. **Chulane, Teller of Tales** - maior ganho de cobertura de cor: Bant ausente.
3. **Miirym, Sentinel Wyrm** - cobre Temur/Dragon typal e aproxima lacuna RG.
4. **K'rrik, Son of Yawgmoth** - cobre mono-B, mas so depois de guardrails de
   power lane.

Backups em ordem: **Giada**, **Lathril**, **Isshin**.

## Menores proximas acoes tecnicas

1. Para Feather: preparar corpus offline, dry-run DB-backed e bloquear se qualquer
   gate falhar.
2. Para Chulane/Miirym/K'rrik: confirmar corpus disponivel antes de apply.
3. Manter Purphoros/Veyran/Balan em trilha separada de reparo profile/card_stats.
4. Repetir public proof 5/5 sanitizado e readiness scorecard antes de qualquer
   promocao.
5. Nao atualizar API map/manual/tracker ate haver mudanca real de contrato ou
   decisao de sprint operacional.

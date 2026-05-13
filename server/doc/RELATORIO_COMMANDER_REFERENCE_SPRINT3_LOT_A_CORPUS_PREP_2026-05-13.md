# Commander Reference Sprint 3 Lote A Corpus Prep - 2026-05-13

## Verdict

**PASS** para corpus prep/dry-run inicial.

Atualizacao pos-apply controlado: **PASS WITH RISKS**. Os quatro corpora
continuaram PASS no dry-run pre-apply, foram aplicados com sucesso, passaram no
apply de idempotencia e o scorecard pos-apply sem runtime summary ficou em
`profile_ready_needs_proof` para todos os comandantes por
`public_runtime_proof_missing`.

Foram preparados corpora offline para `Krenko, Mob Boss`,
`Light-Paws, Emperor's Voice`, `Niv-Mizzet, Parun` e `Teysa Karlov` em
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json`.

Na preparacao inicial, nenhum corpus foi aplicado no banco. O unico gate
executado naquela etapa foi `--dry-run`, com `db_mutations=false` para todos os
comandantes. A secao de atualizacao pos-apply abaixo registra a aplicacao
controlada posterior.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing, public proof e promocao
ficaram fora do escopo. A preparacao inicial cobriu pesquisa publica de baixo
volume, montagem offline do JSON, dry-run DB-backed e documentacao; a atualizacao
posterior cobriu `--apply`, idempotencia e readiness scorecard sem runtime
summary.

## Fontes web consultadas

As fontes abaixo sao paginas publicas EDHREC Average Deck. Elas provam contexto
Commander por rotulo explicito da pagina, comandante no slot de comando e
`total_card_count=100` no payload publico usado para montar o artifact offline.

| Commander | Fontes incluidas |
| --- | --- |
| `Krenko, Mob Boss` | `https://edhrec.com/average-decks/krenko-mob-boss`; `https://edhrec.com/average-decks/krenko-mob-boss/goblins`; `https://edhrec.com/average-decks/krenko-mob-boss/tokens`; `https://edhrec.com/average-decks/krenko-mob-boss/haste` |
| `Light-Paws, Emperor's Voice` | `https://edhrec.com/average-decks/light-paws-emperors-voice`; `https://edhrec.com/average-decks/light-paws-emperors-voice/auras`; `https://edhrec.com/average-decks/light-paws-emperors-voice/voltron`; `https://edhrec.com/average-decks/light-paws-emperors-voice/budget` |
| `Niv-Mizzet, Parun` | `https://edhrec.com/average-decks/niv-mizzet-parun`; `https://edhrec.com/average-decks/niv-mizzet-parun/spellslinger`; `https://edhrec.com/average-decks/niv-mizzet-parun/combo`; `https://edhrec.com/average-decks/niv-mizzet-parun/control`; `https://edhrec.com/average-decks/niv-mizzet-parun/budget` |
| `Teysa Karlov` | `https://edhrec.com/average-decks/teysa-karlov`; `https://edhrec.com/average-decks/teysa-karlov/aristocrats`; `https://edhrec.com/average-decks/teysa-karlov/tokens`; `https://edhrec.com/average-decks/teysa-karlov/sacrifice`; `https://edhrec.com/average-decks/teysa-karlov/budget` |

Paginas sondadas e deixadas fora do artifact final por redundancia, risco de
misturar lane ou para manter baixo volume: Krenko `combo` e `budget`;
Light-Paws `enchantments` e `equipment`; Niv-Mizzet `wheels` e `wheel` (404);
Teysa `lifegain`.

## Fatos locais comprovados

Comando executado para cada comandante:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/dry_run
```

Resultado consolidado:

| Commander | Decks | Status | db_mutations | Commander/main | unresolved | off_color | singleton_violations | Artifact |
| --- | ---: | --- | --- | --- | ---: | ---: | --- | --- |
| `Krenko, Mob Boss` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/dry_run/krenko_mob_boss_dry_run_summary.json` |
| `Light-Paws, Emperor's Voice` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/light_paws_emperor_s_voice/dry_run/light_paws_emperor_s_voice_dry_run_summary.json` |
| `Niv-Mizzet, Parun` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/dry_run/niv_mizzet_parun_dry_run_summary.json` |
| `Teysa Karlov` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/dry_run/teysa_karlov_dry_run_summary.json` |

O dry-run tambem provou que nenhum deck foi rejeitado e que `--apply` nao foi
executado.

## Achados derivados da web

Os sinais abaixo vem das fontes EDHREC Average Deck incluidas; eles ainda nao
sao regras de runtime porque nao houve `--apply`, public proof ou scorecard de
promocao.

| Commander | Padrao publico observado |
| --- | --- |
| `Krenko, Mob Boss` | Goblin typal mono-red com curva baixa, rituais de mana por criaturas, payoffs de go-wide, haste/untap para ativar o comandante antes da mesa responder e poucos slots de remocao. |
| `Light-Paws, Emperor's Voice` | Voltron de auras mono-white: auras baratas viram chain de tutor, protecao/evasion mantem o comandante vivo e draw enchantress evita ficar sem gas. |
| `Niv-Mizzet, Parun` | Izzet draw-damage: cantrips, counters, wheels/loot e Curiosity-like effects aparecem, mas combo/control/budget precisam ficar em lanes explicitas. |
| `Teysa Karlov` | Orzhov aristocrats: criaturas que morrem em dobro, sac outlets, token makers e drain payoffs convertem permanentes pequenos em dano, vida e valor. |

## Interpretacao estrategica

Krenko premia velocidade de setup e multiplicacao de goblins. A malicia e fazer
Krenko gerar varios tokens no turno em que entra, usando haste/untap e rituais
que escalam com a mesa, em vez de virar apenas mono-red goblins generico.

Light-Paws quer proteger uma engine fragil: cada aura deve funcionar como buff,
evasion, protecao ou compra indireta. Equipamentos e enchantress generico foram
deixados fora do corpus para preservar o plano de aura-Voltron.

Niv-Mizzet tem incentivo natural para combo por draw-damage, especialmente com
efeitos tipo Curiosity. Essa informacao e util, mas arriscada: casual Commander
nao deve receber combo infinito como default; o corpus preserva lanes
`spellslinger`, `combo`, `control` e `budget` separadas.

Teysa dobra gatilhos de morte e recompensa sacrificio planejado. O pacote util
precisa equilibrar fodder, outlets e payoffs; so empilhar drain effects sem
geradores de token/sacrifice deixa o deck generico.

## Padroes uteis para absorver futuramente

- Krenko: Goblin Matron/tutors goblin, rituais que escalam com criaturas,
  haste/untap e anthems/go-wide payoffs como pacote de identidade.
- Light-Paws: auras baratas, protecao, evasion, double strike e draw enchantress
  como suporte; evitar equipment como padrao.
- Niv-Mizzet: cantrips/draw, counters, spell-copy ou wheels apenas quando a lane
  pedir, e Curiosity-like package marcado como combo/power lane.
- Teysa: sac outlets, token makers, Blood Artist/Cruel Celebrant-style drain,
  Skullclamp/draw e recursion como pacote aristocrats coerente.

## Padroes arriscados ou nao transferiveis

- Nao colapsar `combo` de Niv-Mizzet em casual Commander; tratar como lane
  explicita antes de qualquer guidance forte.
- Nao transformar Light-Paws em white goodstuff/enchantress/equipment generico.
- Nao transformar Krenko em goblins sem aceleracao/haste, pois perde a janela de
  explosao do comandante.
- Nao copiar decklists EDHREC em prompt/runtime; usar somente sinais agregados
  apos etapa futura de apply e scorecard.
- Nao assumir que popularidade publica e criterio de produto: budget, theme,
  control e combo precisam respeitar bracket/intencao do usuario.

## Recomendacao por comandante

| Commander | Recomendacao |
| --- | --- |
| `Krenko, Mob Boss` | Apply/idempotencia PASS; exigir public proof de haste/tokens/goblins antes de promocao. |
| `Light-Paws, Emperor's Voice` | Apply/idempotencia PASS; exigir public proof de aura/protection/evasion e monitorar goodstuff antes de promocao. |
| `Niv-Mizzet, Parun` | Apply/idempotencia PASS, mas manter **PASS WITH RISKS** ate public proof provar separacao casual vs combo/control. |
| `Teysa Karlov` | Apply/idempotencia PASS; exigir public proof com densidade equilibrada de fodder, sac outlets e drain payoffs. |

## Atualizacao pos-apply controlado - 2026-05-13

Comandos executados a partir de `server/`:

```bash
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/dry_run_pre_apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/apply_idempotency

dart run bin/commander_reference_readiness_scorecard.dart \
  --commanders="Krenko, Mob Boss;Light-Paws, Emperor's Voice;Niv-Mizzet, Parun;Teysa Karlov" \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/readiness_after_corpus
```

O scorecard foi executado **sem** `--runtime-summary`, por isso public proof
permanece explicitamente nao provado.

### Dry-run pre-apply

| Commander | Decks | Status | db_mutations | accepted/deck | unresolved | off_color | commander/main | singleton |
| --- | ---: | --- | --- | --- | ---: | ---: | --- | --- |
| `Krenko, Mob Boss` | 4 | PASS | false | 4/4 | 0 | 0 | 1/99 em 4/4 | `{}` em 4/4 |
| `Light-Paws, Emperor's Voice` | 4 | PASS | false | 4/4 | 0 | 0 | 1/99 em 4/4 | `{}` em 4/4 |
| `Niv-Mizzet, Parun` | 5 | PASS | false | 5/5 | 0 | 0 | 1/99 em 5/5 | `{}` em 5/5 |
| `Teysa Karlov` | 5 | PASS | false | 5/5 | 0 | 0 | 1/99 em 5/5 | `{}` em 5/5 |

### Apply e idempotencia

| Commander | Apply | Apply artifact | Idempotency | Idempotency artifact |
| --- | --- | --- | --- | --- |
| `Krenko, Mob Boss` | PASS, 4/4 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/apply/krenko_mob_boss_apply_summary.json` | PASS, 4/4 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/apply_idempotency/krenko_mob_boss_apply_summary.json` |
| `Light-Paws, Emperor's Voice` | PASS, 4/4 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/light_paws_emperor_s_voice/apply/light_paws_emperor_s_voice_apply_summary.json` | PASS, 4/4 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/light_paws_emperor_s_voice/apply_idempotency/light_paws_emperor_s_voice_apply_summary.json` |
| `Niv-Mizzet, Parun` | PASS, 5/5 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/apply/niv_mizzet_parun_apply_summary.json` | PASS, 5/5 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/apply_idempotency/niv_mizzet_parun_apply_summary.json` |
| `Teysa Karlov` | PASS, 5/5 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/apply/teysa_karlov_apply_summary.json` | PASS, 5/5 aceitos | `server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/apply_idempotency/teysa_karlov_apply_summary.json` |

As mutacoes foram restritas aos upserts idempotentes de
`commander_reference_decks`, `commander_reference_deck_cards` e
`commander_reference_deck_analysis`. O rollback pratico e remover os
`source_deck_key` do Lote A dessas tabelas; reaplicar os mesmos corpora e seguro
porque o runner usa `ON CONFLICT` por chave estavel e recria as linhas de cards
do deck antes de inserir a versao atual.

### Contagens DB-backed pos-apply

Consulta direta nas tabelas de corpus apos o apply de idempotencia:

| Commander | commander_reference_decks | commander_reference_deck_analysis | unresolved | off_color | commander_qty | main_qty | singleton_rows |
| --- | --- | --- | ---: | ---: | --- | --- | ---: |
| `Krenko, Mob Boss` | 4 decks / 4 aceitos | 4/4 | 0 | 0 | 1-1 | 99-99 | 0 |
| `Light-Paws, Emperor's Voice` | 4 decks / 4 aceitos | 4/4 | 0 | 0 | 1-1 | 99-99 | 0 |
| `Niv-Mizzet, Parun` | 5 decks / 5 aceitos | 5/5 | 0 | 0 | 1-1 | 99-99 | 0 |
| `Teysa Karlov` | 5 decks / 5 aceitos | 5/5 | 0 | 0 | 1-1 | 99-99 | 0 |

### Readiness scorecard pos-apply

Artifact:
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/readiness_after_corpus/readiness_scorecard_summary.json`.

| Commander | Score | Status | Blockers | Warnings | Expansion ready |
| --- | ---: | --- | --- | --- | --- |
| `Krenko, Mob Boss` | 98 | `profile_ready_needs_proof` | `[]` | `public_runtime_proof_missing` | false |
| `Light-Paws, Emperor's Voice` | 98 | `profile_ready_needs_proof` | `[]` | `public_runtime_proof_missing` | false |
| `Niv-Mizzet, Parun` | 98 | `profile_ready_needs_proof` | `[]` | `public_runtime_proof_missing` | false |
| `Teysa Karlov` | 98 | `profile_ready_needs_proof` | `[]` | `public_runtime_proof_missing` | false |

Resultado consolidado: `PASS_WITH_RISKS`, `commander_count=4`, `ready_count=0`.
Nenhum comandante foi promovido, pois public runtime proof permanece `NOT_RUN`.

## Proximas acoes tecnicas minimas

1. Executar public proof sanitizado 5/5 por comandante com runtime summary.
2. Reexecutar readiness scorecard com runtime summary.
3. Bloquear promocao de qualquer alvo com timeout fallback, blocker, warning
   relevante, `score<100`, off-identity, invalid cards ou core package fraco.
4. Atualizar `server/doc/API_CONTRACTS_AND_DATA_MAP.md` somente se houver
   mudanca real de rota, payload, diagnostics app-facing ou consumidor mobile.

# Commander Reference Profiles — Anchor 30 Batch A — 2026-05-12

## Resultado

**PASS.** Os 8 Commander Reference Profiles do Batch A da base Anchor 30 foram
curados como sinais agregados, validados em dry-run, aplicados e reaplicados com
idempotencia positiva. Todos resolveram o commander card localmente, todos os
cards representativos dos packages resolveram, e nenhum card ficou fora da
identidade de cor do comandante.

Escopo fora deste relatorio: tokens, JWT, `DATABASE_URL`, Sentry DSN,
`OPENAI_API_KEY`, prompts completos, payloads sensiveis e decklists completas de
terceiros. As referencias persistidas usam apenas temas, roles, packages e
cartas representativas.

## Fontes consultadas

### Fatos locais / banco / codigo

- `server/doc/COMMANDER_REFERENCE_PROFILE_ANCHOR_30_PLAN_2026-05-12.md`
- `server/test/artifacts/commander_reference_profile_anchor30_2026-05-12/anchor_30_queue.json`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_2026-05-11.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_STRIXHAVEN_LOT2_2026-05-11.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_STRIXHAVEN_LOT2_RUNTIME_2026-05-11.md`
- `server/bin/commander_reference_profile.dart`
- `server/lib/ai/commander_reference_profile_support.dart`
- `server/lib/ai/commander_reference_card_stats_support.dart`
- Tabelas `commander_reference_profiles` e
  `commander_reference_card_stats`, via runner DB-backed.

### Evidencia web derivada

As fontes publicas abaixo foram usadas apenas para contexto Commander/cEDH
agregado. Nao houve copia de decklist completa.

- EDHREC commander/cEDH pages para Atraxa, Korvold, Muldrotha, Chulane, Yuriko,
  Kinnan, Winota e Prosper.
- EDH Wiki commander pages para Atraxa, Korvold, Muldrotha, Chulane e Prosper.
- Learn cEDH decklist/primer pages para Korvold, Yuriko e Kinnan.
- EDHTop16 commander pages para Korvold, Chulane, Yuriko e Kinnan.
- MTGTop8 commander/cEDH archetype pages para Atraxa, Yuriko e Kinnan.
- Draftsim commander guides para Atraxa, Muldrotha, Chulane, Yuriko, Kinnan e
  Prosper.
- cEDH Decklist Database / Moxfield / Archidekt / MTGDecks public pages como
  fontes de contexto competitivo ou high-power, sem copiar listas.
- `https://mtgcommander.net/index.php/banned-list/`
- Wizards Commander banned/restricted announcement de 2024-09-23, usado para
  evitar absorver sinais historicos com `Dockside Extortionist`, `Mana Crypt`,
  `Jeweled Lotus` e `Nadu, Winged Wisdom`.

## O que foi provado localmente

- Os 8 comandantes do Batch A resolveram como cards reais no banco local/remoto
  configurado pelo runner.
- Os 8 profiles passaram em `--dry-run` com `unresolved_count=0` e
  `off_color_count=0`.
- Os 8 profiles foram aplicados com `profile_usable_after_run=true`.
- A segunda execucao `--apply` manteve os mesmos hashes e voltou a passar com
  `unresolved_count=0` e `off_color_count=0`.
- O apply nao mudou contrato app-facing; ele popula guidance backend-owned usado
  por `/ai/generate` quando `commander_name` tem profile exato persistido.

## O que foi inferido da pesquisa web

- Todos os 8 comandantes tem contexto Commander publico suficiente para profile
  exato.
- Yuriko, Kinnan e Winota tem sinal cEDH/high-power forte; esse sinal deve ser
  mantido separado de Commander casual.
- Korvold e Prosper tem historico high-power/cEDH, mas listas antigas podem
  conter cartas agora banidas. Os profiles evitam essas cartas como package ativo.
- Atraxa tem multiplas leituras populares: proliferate/counters/superfriends e
  poison. Poison foi tratado como package opcional/bracket-aware.
- Muldrotha e Chulane tem alto reaproveitamento como arquétipos de valor, mas
  combos deterministas devem depender de intencao/power lane.

## Profiles aplicados

| Commander | Identidade | Confidence | Source count | Resolved | Unresolved | Off-color | Pattern absorvido |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Atraxa, Praetors' Voice | WUBG | high | 5 | 36 | 0 | 0 | Proliferate, counters, superfriends e poison opcional. |
| Chulane, Teller of Tales | GWU | high | 5 | 35 | 0 | 0 | Creature-cast value, land drops e bounce/ETB loops. |
| Kinnan, Bonder Prodigy | GU | high | 6 | 35 | 0 | 0 | Nonland mana amplification, infinite mana e big-mana payoffs. |
| Korvold, Fae-Cursed King | BRG | high | 5 | 35 | 0 | 0 | Sacrifice, treasure, aristocrats e combo Jund bracket-aware. |
| Muldrotha, the Gravetide | BGU | high | 5 | 34 | 0 | 0 | Self-mill e recursion de permanentes com interacao reaproveitavel. |
| Prosper, Tome-Bound | BR | high | 6 | 35 | 0 | 0 | Exile value, treasure, artifact-drain e storm opt-in. |
| Winota, Joiner of Forces | RW | high | 3 | 36 | 0 | 0 | Split non-Human enablers / Human hits e aggro-stax. |
| Yuriko, the Tiger's Shadow | UB | high | 6 | 42 | 0 | 0 | Evasive tempo, ninjas, topdeck damage e combo opt-in. |

## Patterns uteis para absorver

- **Atraxa:** separar counters/superfriends de poison; poison deve ser
  power-lane/social-contract aware.
- **Korvold:** exigir equilibrio entre fodder, sacrifice outlets, payoffs e
  protecao; treasure sozinho nao basta.
- **Muldrotha:** favorecer permanentes replayable e respostas a graveyard hate,
  nao pilhas Sultai cheias de instant/sorcery.
- **Chulane:** cheap creature density e bounce loops sao mais importantes que
  Bant goodstuff generico.
- **Yuriko:** manter o triangulo evasive enablers + ninjas + topdeck setup;
  high-MV reveals nao podem virar cartas mortas demais.
- **Kinnan:** priorizar mana nao-terreno porque o comandante dobra essa fonte;
  land-ramp generico e mais casual.
- **Winota:** modelar a proporcao non-Human enablers / Human hits; hard stax
  precisa ser bracket-aware.
- **Prosper:** impulse draw precisa de curva jogavel; treasure payoffs e storm
  devem respeitar intencao do usuario.

## Patterns arriscados ou nao transferiveis

- Cartas banidas em Commander que ainda aparecem em listas antigas: `Dockside
  Extortionist`, `Mana Crypt`, `Jeweled Lotus` e `Nadu, Winged Wisdom`.
- Oracle/Consult, Doomsday, Ad Nauseam, hard stax e Breach storm nao devem
  entrar automaticamente em Commander casual.
- Infect Atraxa e Winota stax sao sensiveis para produto e mesa; usar apenas
  quando power lane/tema pedir.
- Muldrotha combo cEDH e Chulane loops deterministas sao validos como sinal, mas
  nao substituem o plano default de valor.
- Nao copiar EDHREC, Moxfield, Archidekt, MTGTop8, MTGDecks ou primers como
  decklist; os packages sao sinais funcionais agregados.

## Artifacts sanitizados

- `server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/*.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/dry_run/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/apply/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/apply_idempotency/*_summary.json`

Os artifacts registram nomes publicos de comandantes/cartas representativas,
contagens, hashes e status de resolucao; nao registram segredo, JWT, prompt
completo ou decklist completa.

## Comandos executados

```bash
git fetch origin master --quiet
git pull --ff-only --quiet
git status --short --branch
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/dry_run
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/apply
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/apply_idempotency
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
git diff --check
git diff/added-content secret scan over changed and untracked files
```

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| Batch A 8 profiles | PASS, 8/8. |
| Commander relevance provada | PASS para Commander; cEDH separado onde aplicavel. |
| Commander card resolution | PASS, 8/8. |
| Dry-run `unresolved=0` | PASS, 8/8. |
| Dry-run `off_color=0` | PASS, 8/8. |
| Apply seguro | PASS, 8/8 com profile utilizavel apos escrita. |
| Idempotencia | PASS, 8/8 com hashes estaveis. |
| `dart analyze bin lib routes test` | PASS, sem issues. |
| Testes focados de Commander Reference | PASS, 18/18. |
| `git diff --check` | PASS. |
| Scan simples de segredos em conteudo novo | PASS, sem chave/JWT/DSN/URL de banco real. |
| Segredos/decklists completas em artifacts | PASS por desenho dos artifacts sanitizados. |

## Menores proximas acoes tecnicas

1. Rodar probes sanitizados de `/ai/generate` para pelo menos Kinnan, Yuriko,
   Winota e Atraxa antes de promover copy de UX para esses anchors.
2. Preparar Batch B somente depois de confirmar que o runtime publico atual
   tambem resolve os commanders Anchor 30 como cards.
3. Se algum probe mostrar baixa densidade tematica, ajustar apenas packages
   representativos mantendo `unresolved=0` e `off_color=0`.

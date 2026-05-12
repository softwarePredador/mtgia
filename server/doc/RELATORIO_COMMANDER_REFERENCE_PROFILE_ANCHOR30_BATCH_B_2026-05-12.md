# Commander Reference Profiles — Anchor 30 Batch B — 2026-05-12

## Resultado

**PASS.** Os 8 Commander Reference Profiles do Batch B da base Anchor 30 foram
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
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_A_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_A_RUNTIME_2026-05-12.md`
- Follow-up Chulane documentado no commit `8f92742`
- `server/bin/commander_reference_profile.dart`
- `server/lib/ai/commander_reference_profile_support.dart`
- `server/lib/ai/commander_reference_card_stats_support.dart`
- Tabelas `commander_reference_profiles` e
  `commander_reference_card_stats`, via runner DB-backed.

### Evidencia web derivada

As fontes publicas abaixo foram usadas apenas para contexto Commander/cEDH
agregado. Nao houve copia de decklist completa.

- EDHREC commander, average, optimized, landfall, elves e cEDH pages para Edgar
  Markov, Miirym, Isshin, Teysa, Lathril, Aesi, Sythis e Urza.
- Moxfield e Archidekt public Commander/cEDH pages como prova de contexto e
  leitura de pacotes, sem copiar listas.
- MTGGoldfish pages para Teysa Karlov e Urza como contexto Commander publico.
- Draftsim guides para Miirym e Sythis como leitura agregada de Commander.
- Commander's Herald para contexto cEDH de Urza.
- TCGPlayer Commander guide para Sythis.

## O que foi provado localmente

- Os 8 comandantes do Batch B resolveram como cards reais no banco local/remoto
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
- Edgar e Urza tem sinais high-power/cEDH fortes, mas esses sinais devem ficar
  separados de Commander casual.
- Miirym, Isshin, Teysa, Lathril, Aesi e Sythis tem padroes Commander muito
  claros que sao mais uteis para ManaLoom quando modelados por densidade de
  package do que por staples genericas de cor.
- Urza e Sythis exigem cuidado de produto: stax e hard locks sao padroes reais,
  mas nao devem ser recomendacao casual default.
- Lathril e Edgar se beneficiam de typal density; reduzir esses perfis a
  Golgari/Mardu goodstuff destruiria a intencao do usuario.

## Profiles aplicados

| Commander | Identidade | Confidence | Source count | Resolved | Unresolved | Off-color | Hash | Pattern absorvido |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| Aesi, Tyrant of Gyre Strait | GU | high | 5 | 30 | 0 | 0 | `1d9d3d01f609` | Lands/ramp/draw, extra land drops, landfall e recursion. |
| Edgar Markov | WBR | high | 5 | 33 | 0 | 0 | `726cb5c21483` | Vampire low curve, lords, tokens e aristocrats Mardu. |
| Isshin, Two Heavens as One | WBR | high | 4 | 27 | 0 | 0 | `aa2147c5dc17` | Attack triggers, go-wide combat e attacker safety. |
| Lathril, Blade of the Elves | BG | high | 5 | 32 | 0 | 0 | `da5f3076153c` | Elf density, mana-Elves, tokens, drain e untap. |
| Miirym, Sentinel Wyrm | GUR | high | 4 | 33 | 0 | 0 | `bbb3c148e89a` | Dragon typal, clone/copy, ETB damage e Temur ramp. |
| Sythis, Harvest's Hand | GW | high | 5 | 31 | 0 | 0 | `3bde6c175c92` | Enchantress density, aura ramp, pillow/protection e payoffs. |
| Teysa Karlov | WB | high | 5 | 32 | 0 | 0 | `597df6873d0e` | Fodder + sac outlet + death payoff aristocrats. |
| Urza, Lord High Artificer | U | high | 6 | 37 | 0 | 0 | `e6b5cf7805ed` | Artifact density, control, combo, stax parity and tutors. |

## Patterns uteis para absorver

- **Edgar Markov:** manter densidade de Vampires baratos, lords, protecao contra
  wipe e fallback aristocrats; cEDH tutor/fast-mana so com power lane explicita.
- **Miirym:** exigir ramp alto antes de top-end Dragon; pontuar clone/ETB damage
  como pacote especifico, nao como Dragon pile generico.
- **Isshin:** modelar a proporcao entre attack triggers, payoff de combate,
  geradores de token e seguranca para atacar.
- **Teysa:** usar o triangulo aristocrats: fodder + sacrifice outlet + death
  payoff, com draw/recursion suficiente.
- **Lathril:** contar mana-Elves como ramp e typal density; untap e drain sao
  payoffs de engine, nao staples genericas.
- **Aesi:** recomendar land count acima do normal, extra land drops e landfall
  payoffs; Simic goodstuff sem lands deve perder prioridade.
- **Sythis:** priorizar enchantment density, aura ramp, enchantress redundancy e
  removal em forma de enchantment quando possivel.
- **Urza:** separar plano casual artifact value de cEDH stax/combo; usar artifact
  density, tutors e countermagic como sinais de perfil.

## Patterns arriscados ou nao transferiveis

- cEDH fast mana, hard stax, Ad Nauseam/turbo, lock pieces e reserved-list
  expensive staples nao devem entrar automaticamente em Commander casual.
- Cartas off-color que parecem sinergicas por texto, como exemplos verdes de
  attack trigger para Isshin, devem ficar apenas em `avoid_patterns`.
- Miirym sem ramp/copy vira battlecruiser lento; Aesi com land count normal perde
  o motor; Sythis com poucos enchantments perde o motivo do commander.
- Nao copiar EDHREC, Moxfield, Archidekt, MTGGoldfish, Draftsim, TCGPlayer ou
  Commander's Herald como decklist; os packages sao sinais funcionais agregados.

## Artifacts sanitizados

- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/*.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/dry_run/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/apply/*_summary.json`
- `server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/apply_idempotency/*_summary.json`

Os artifacts registram nomes publicos de comandantes/cartas representativas,
contagens, hashes e status de resolucao; nao registram segredo, JWT, prompt
completo ou decklist completa.

## Comandos executados

```bash
git fetch origin master --prune --quiet
git pull --ff-only origin master --quiet
git status --short --branch
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/dry_run
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/apply
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/apply_idempotency
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
git diff --check
git diff/added-content secret scan over changed and untracked files
```

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| Batch B 8 profiles | PASS, 8/8. |
| Commander relevance provada | PASS para Commander; cEDH separado onde aplicavel. |
| Commander card resolution | PASS, 8/8. |
| Dry-run `unresolved=0` | PASS, 8/8. |
| Dry-run `off_color=0` | PASS, 8/8. |
| Apply seguro | PASS, 8/8 com profile utilizavel apos escrita. |
| Idempotencia | PASS, 8/8 com hashes estaveis. |
| Segredos/decklists completas em artifacts | PASS por desenho dos artifacts sanitizados. |

## Menores proximas acoes tecnicas

1. Rodar runtime publico Batch B via `/ai/generate` com `commander_name` para os
   8 commanders apos deploy do commit deste lote.
2. Amostrar pelo menos Urza e Sythis com cuidado de diagnostics para confirmar
   que cEDH/stax nao vaza como default casual sem power lane.
3. Preparar Batch C somente depois de confirmar que o runtime publico atual
   ativa `reference_profile_used=true` e `reference_card_stats_used=true` para
   Batch B.

# Commander Reference Profiles — Strixhaven Lot 2 — 2026-05-11

## Resultado

**PASS.** O lote 2 aplicou 8 Commander Reference Profiles de Secrets of
Strixhaven com `unresolved=0`, `off_color=0`, idempotencia positiva e prova de
presenca no banco.

Escopo fora deste relatorio: tokens, JWT, `DATABASE_URL`, Sentry DSN,
`OPENAI_API_KEY`, prompts completos e decklists completas copiadas de terceiros.

## Pre-condicoes

| Criterio | Resultado |
| --- | --- |
| Branch alvo | `master`, sincronizada com `origin/master` antes da aplicacao. |
| Deploy publico do tuning `76a8ddc` | PASS documentado em `RELATORIO_AI_GENERATE_REFERENCE_TIMEOUT_TUNING_2026-05-11.md` e `RELATORIO_COMMANDER_ARCHETYPE_REFERENCE_QUALITY_PROOF_2026-05-11.md`. |
| Relatorio de timeout com `BLOCKED` | Nao observado nos documentos consultados. |
| Profiles Strixhaven ja aplicados | Lote 1: Dina, Killian, Lorehold, Prismari, Quandrix, Quintorius, Rootha, Silverquill, Witherbloom e Zimone. |

## Fontes consultadas

### Fatos locais / banco / codigo

- `server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11/secrets_of_strixhaven_new_commanders_seed.json`
- `server/doc/COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_PLAN_2026-05-11.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_2026-05-11.md`
- `server/doc/RELATORIO_COMMANDER_ARCHETYPE_REFERENCE_QUALITY_PROOF_2026-05-11.md`
- `server/doc/RELATORIO_AI_GENERATE_REFERENCE_TIMEOUT_TUNING_2026-05-11.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/bin/commander_reference_profile.dart`
- Tabelas `commander_reference_profiles` e `commander_reference_card_stats`

### Evidencia web derivada

As fontes publicas abaixo foram usadas apenas como contexto manual/agregado; nao
houve copia de decklist completa nem dependencia runtime.

- Scryfall card pages para os 8 comandantes do lote.
- EDHREC Commander pages para os 8 comandantes do lote, como contexto Commander
  agregado.
- Wizards, `Secrets of Strixhaven Commander Decklists`, como contexto publico do
  produto SOC.
- Scryfall set pages `sos` e `soc`, como contexto publico de set.
- Draftsim, `All Secrets of Strixhaven Secondary Precon Commanders Ranked`, como
  sinal estrategico agregado para comandantes secundarios.
- EDHREC, `Silverquill Influence - Secrets of Strixhaven Precon Guide`, como
  contexto agregado para Scriv/Silverquill.

## O que foi provado localmente

- O seed local contem os nomes exatos, sets, type lines, textos oracle e
  identidades de cor dos comandantes escolhidos.
- Antes do lote 2, nenhum dos 8 comandantes selecionados tinha profile exato
  persistido em `commander_reference_profiles`.
- O runner generico resolveu todos os cards representativos dos packages com
  `unresolved=0` e `off_color=0`.
- `--apply` carregou profile utilizavel apos escrita para os 8 comandantes.
- A segunda execucao de `--apply`, em artifact separado, manteve os mesmos
  hashes de profile e voltou a passar com `unresolved=0` e `off_color=0`.
- Prova DB final: os 8 profiles existem e possuem card stats resolvidos.

## O que foi inferido da pesquisa web

- Todos os 8 comandantes tem contexto Commander publico suficiente para profile
  casual/funcional.
- Relevancia cEDH nao foi provada para nenhum comandante deste lote.
- Berta, Aziza e Zaffai tiveram evidencia estrategica publica mais fina; por
  isso ficaram com `confidence=medium` e dependem principalmente de oracle text,
  identidade de cor e suporte local de cards.
- Excava, Gorma, Muddle, Primo e Scriv tiveram sinais agregados mais claros em
  paginas Commander, set/precon context e comentario estrategico externo; por
  isso ficaram em `medium_high`.

## Profiles aplicados

| Commander | Identidade | Confidence | Source count | Resolved | Unresolved | Off-color | Pattern absorvido |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Aziza, Mage Tower Captain | RW | medium | 3 | 46 | 0 | 0 | Go-wide Boros que copia instants/sorceries ao tapar criaturas. |
| Berta, Wise Extrapolator | GU | medium | 3 | 44 | 0 | 0 | Increment/+1/+1 counters gerando mana, Fractals e X-spells. |
| Excava, the Risen Past | RW | medium_high | 4 | 44 | 0 | 0 | Recursao Boros de permanentes pequenos com finality counter. |
| Gorma, the Gullet | BG | medium_high | 4 | 44 | 0 | 0 | Aristocrats/counters com sacrifice, death payoffs e persist/undying. |
| Muddle, the Ever-Changing | UR | medium_high | 4 | 45 | 0 | 0 | Spellslinger que vira copia nonlegendary com myriad. |
| Primo, the Unbounded | GU | medium_high | 4 | 43 | 0 | 0 | Base-power-0/Hydra/Fractal counters com evasao. |
| Scriv, the Obligator | BW | medium_high | 4 | 39 | 0 | 0 | Contract Auras, politica/goad e enchantment payoffs. |
| Zaffai and the Tempests | UR | medium | 3 | 52 | 0 | 0 | Free big spells Izzet, setup de mao/topo, copy/recursion. |

## Patterns uteis para absorver

- **Aziza:** separar spellslinger Boros de decks sem criaturas; o custo de tapar
  tres criaturas exige token density e vigilance/untap.
- **Berta:** tratar counters como fonte de mana e nao apenas plano de combate;
  X-spells e Fractals sao payoffs naturais.
- **Excava:** preferir permanentes de mana value 3 ou menos com ETB/death value;
  evitar reanimator de haymakers.
- **Gorma:** equilibrar sacrifice outlets, fodder/recursion e death payoffs;
  persist/undying entra como pacote bracket-aware.
- **Muddle:** exigir alvos nonlegendary bons para copia; pure storm sem
  criaturas e sinal ruim.
- **Primo:** distinguir base-power-0/Hydra counters de Simic goodstuff generico.
- **Scriv:** Contract Auras e ataque politizado importam mais que Voltron puro.
- **Zaffai:** free-cast de big spells precisa selection/setup; nao fundir com
  `Zaffai, Thunder Conductor` sem checar o nome exato.

## Patterns arriscados ou nao transferiveis

- cEDH nao provado: nenhum profile deve virar shell competitivo obrigatorio.
- Nao importar off-color de arquétipos populares: white big spells em UR,
  black aristocrats em RW, white persist em BG, ou cards UR/BW fora da identidade.
- Nao copiar EDHREC, Moxfield, Archidekt, WotC ou artigos externos como decklist.
  Os `expected_packages` sao sinais funcionais agregados e cartas representativas.
- Nao aplicar profile com `confidence<medium`, `unresolved>0` ou `off_color>0`.
- Berta/Aziza/Zaffai ficam com risco de produto maior por evidencia externa fina;
  devem ser validados por probes de `/ai/generate` antes de promover copy de UX.

## Artifacts sanitizados

- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/profiles/*.json`
- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/dry_run/*_summary.json`
- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/apply/*_summary.json`
- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/apply_idempotency/*_summary.json`

Os artifacts registram nomes de comandantes/cartas representativas, contagens,
hashes e status de resolucao; nao registram segredo, JWT, prompt completo ou
decklist completa.

## Comandos executados

```bash
git fetch origin master
git pull --ff-only origin master
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/dry_run
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/apply
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/apply_idempotency
cd server && dart analyze bin lib routes test
cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
git diff --check
git grep -nE "(sk-[A-Za-z0-9_-]{20,}|DATABASE_URL=|SENTRY_DSN=<SENTRY_DSN_REDACTED> Bearer|eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+)" -- <changed files>
```

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| 5-8 profiles selecionados | PASS, 8 profiles. |
| Commander relevance provada | PASS para Commander casual/funcional; cEDH not proven. |
| Dry-run `unresolved=0` | PASS, 8/8. |
| Dry-run `off_color=0` | PASS, 8/8. |
| Apply seguro | PASS, 8/8 com profile utilizavel apos escrita. |
| Idempotencia | PASS, 8/8 em artifact separado. |
| DB proof | PASS, 8/8 `present`, 39-52 card stats resolvidos por commander. |
| `dart analyze bin lib routes test` | PASS, sem issues. |
| Testes focados de Commander Reference | PASS, 17/17. |
| `git diff --check` | PASS. |
| Scan simples de secrets reais em linhas adicionadas/untracked | PASS, sem chave/JWT/DSN/URL de banco real. |

## Menores proximas acoes tecnicas

1. Rodar probes sanitizados de `/ai/generate` para pelo menos Berta, Aziza e
   Zaffai, porque a evidencia externa deles e mais fina.
2. Preparar lote 3 com monocoloridos claros e casos BG/BW restantes; deixar
   colorless e MDFC ambigua para uma triagem separada.
3. Se algum probe gerar baixa densidade tematica, ajustar packages sem mudar
   contrato app-facing e mantendo `unresolved=0`/`off_color=0`.

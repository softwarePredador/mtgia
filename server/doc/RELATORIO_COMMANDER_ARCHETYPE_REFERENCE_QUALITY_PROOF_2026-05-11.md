# Commander Archetype Reference Quality Proof — 2026-05-11

## Objetivo

Provar a qualidade real de `/ai/generate` com reutilizacao de referencia de
arquetipo para um comandante sem profile exato, usando `Velomachus Lorehold`
como piloto parecido com `Lorehold, the Historian`.

Escopo fora deste relatorio: scanner, camera, OCR, prompts completos,
decklists completas, tokens, JWT, Sentry DSN, `DATABASE_URL`,
`OPENAI_API_KEY` e qualquer segredo operacional.

## Commits inspecionados

| Commit | Leitura |
| --- | --- |
| `f3bac2bb2fa8de53430acd940732a77e1cd2e133` | Backend publico em `/health`; documenta prova publica anterior. |
| `637054b9a706b0a232bab7fab72cc21c0db6ecd7` | Preserva `commander_name` no fallback deterministico. |
| `e5d8d8a26d6692f0d038bdf05d1778ade2b43759` | Adiciona Commander Archetype Reference Reuse. |

Backend publico validado:
`https://evolution-cartinhas.8ktevp.easypanel.host/health` retornou `200`,
`status=healthy`, `environment=production` e
`git_sha=f3bac2bb2fa8de53430acd940732a77e1cd2e133`.

## Metodo

- Branch local `master` sincronizado com `origin/master`.
- Usuario QA descartavel criado via `/auth/register`; credenciais e JWT nao
  foram persistidos nem documentados.
- Executadas 5 amostras sync de `POST /ai/generate` para Commander:
  - 4 com `commander_name=Velomachus Lorehold` e prompt Boros de big spells,
    topdeck/miracle, spellslinger, ramp, draw, removal e protection;
  - 1 baseline sem `commander_name`, mantendo o texto com o nome do comandante
    no prompt.
- O resumo abaixo registra apenas campos contratuais e metricas agregadas.
- Para comparar qualidade percebida sem expor decklist, as respostas
  representativas foram reabertas por cache e cada carta das 99 foi classificada
  por metadata publica de `/cards`, em buckets aproximados:
  `on_theme`, `generic`, `questionable`, `off_theme`.

## Comandos executados

| Comando | Resultado |
| --- | --- |
| `git status --short --branch && git fetch origin master && git checkout master && git pull --ff-only origin master` | PASS, branch atualizado em `f3bac2b`. |
| `curl https://evolution-cartinhas.8ktevp.easypanel.host/health` | PASS, `200`, `git_sha=f3bac2bb2fa8de53430acd940732a77e1cd2e133`. |
| Probe sanitizado Python: register QA + 5x `POST /ai/generate` | PASS, 5/5 `status=200`. |
| Probe sanitizado Python: reabrir amostras por cache + classificar por `/cards` | PASS, sem decklist em output. |
| `git diff --check` | PASS. |
| Scan simples de secrets no diff | PASS, sem JWT/token/API key/DSN/DB URL no diff. |
| `cd server && dart analyze lib routes test` | PASS. |
| `cd server && dart test test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_support_test.dart test/ai_generate_performance_support_test.dart -r expanded` | PASS. |

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| Backend publico no commit esperado | PASS |
| Autenticacao QA descartavel | PASS |
| 3 a 5 probes sanitizados | PASS, 5 probes |
| Pelo menos 1 OpenAI real valido | PASS |
| Baseline sem `commander_name` | PASS |
| Sem 5xx/timeout cru/4xx inesperado | PASS |
| Comandante preservado quando solicitado | PASS |
| 99 cartas no main | PASS |
| Validacao final positiva | PASS |
| Sem Lorehold nas 99 | PASS |
| Sem off-identity observado | PASS |
| Worktree limpo ao final | PASS apos commit/push desta evidencia |

## Resultado dos probes

| Amostra | Status | Elapsed | Cache | Fallback/OpenAI | Commander | Main | Validacao | Archetype reuse |
| --- | ---: | ---: | --- | --- | --- | ---: | --- | --- |
| `archetype_velomachus_1` | 200 | 13157 ms | miss | fallback timeout (`warnings.code=openai_timeout_deterministic_fallback`) | Velomachus Lorehold | 99 | valid | true, 48 candidatos |
| `archetype_velomachus_2` | 200 | 12860 ms | miss | fallback timeout (`warnings.code=openai_timeout_deterministic_fallback`) | Velomachus Lorehold | 99 | valid | true, 48 candidatos |
| `archetype_velomachus_3` | 200 | 12773 ms | miss | fallback timeout (`warnings.code=openai_timeout_deterministic_fallback`) | Velomachus Lorehold | 99 | valid | true, 48 candidatos |
| `archetype_velomachus_4` | 200 | 9965 ms | miss | OpenAI real, sem timeout | Velomachus Lorehold | 99 | valid | true, 48 candidatos |
| `baseline_no_commander_name` | 200 | 12178 ms | miss | OpenAI real, sem timeout | Velomachus Lorehold | 99 | valid | ausente |

`reference_profile_used=false` e `reference_card_stats_used=false` em todas as
amostras com Velomachus, confirmando que nao havia profile exato sendo usado.
`archetype_reference_used=true` apareceu somente nas amostras com
`commander_name`, como esperado.

## Matriz de caminho selecionado

| Caminho | Evidencia |
| --- | --- |
| Exact Commander Reference Profile | Nao selecionado para Velomachus: `reference_profile_used=false`. |
| Reference Card Stats exato | Nao selecionado: `reference_card_stats_used=false`. |
| Archetype Reference Reuse | Selecionado nas 4 amostras com `commander_name`: 48 candidatos, packages de topdeck/miracle, big spells/copy, interaction/resets e graveyard leave. |
| OpenAI completo | Selecionado e concluido em `archetype_velomachus_4` e no baseline, ambos sem `ai_generation_timed_out`. |
| Deterministic fallback | Selecionado nas 3 primeiras amostras por timeout; manteve comandante correto, diagnostics e validacao. |
| Cache | Miss nas 5 amostras iniciais; reaberturas por cache retornaram em 582-731 ms. |
| 5xx/4xx inesperado | Nao observado. |

## Qualidade percebida: archetype vs baseline

Comparacao agregada em respostas reais, sem timeout e sem expor decklist:

| Amostra real | On-theme | Generic | Questionable | Off-theme | Leitura |
| --- | ---: | ---: | ---: | ---: | --- |
| Archetype reuse + `commander_name` | 18 | 71 | 10 | 0 | Melhor densidade de cartas ligadas a spellslinger/topdeck/miracle/big spells; manteve suporte generico alto e zero off-theme/off-identity. |
| Baseline sem `commander_name` | 4 | 83 | 12 | 0 | Gerou deck valido e com comandante correto inferido do prompt, mas com menos sinais tematicos especificos. |

Leitura: a amostra OpenAI real com archetype reuse foi **melhor que o baseline
em qualidade percebida** para o pedido Boros big spells/topdeck/spellslinger,
sem relaxar legalidade, identidade de cor ou tamanho final.

## Contrato e seguranca do output

- `generated_deck.commander.name=Velomachus Lorehold` nas 5 amostras.
- `commander_preserved=true` nas 4 amostras com `commander_name`.
- `main_quantity=99` nas 5 amostras.
- `validation.is_valid=true` nas 5 amostras.
- `Lorehold, the Historian` nao apareceu nas 99.
- Nenhuma violacao off-identity/off-color/illegal foi exposta pela validacao.
- `cache.cache_key` retornou apenas hash/metadados; nenhum prompt ou payload
  sensivel foi documentado.
- `diagnostics.archetype_source_commanders` nas amostras com reuse:
  `Lorehold, the Historian` e `Quintorius, History Chaser`.
- `diagnostics.archetype_package_keys` incluiu:
  `topdeck_and_miracle_setup`, `miracle_payoffs_expensive_spells`,
  `spell_payoff_copy_package`, `interaction_and_resets`, `interaction`,
  `graveyard_leave_enablers`.

## App/backend contract findings

- O backend entrega os campos que o app deve tratar como opcionais:
  `cache`, `timings`, `diagnostics`, `warnings`, `ai_generation_timed_out`.
- `generated_deck` continuou sendo a fonte de verdade para preview/save.
- A resposta sem `commander_name` permaneceu backward-compatible e nao recebeu
  diagnostics de archetype reuse.
- O fallback timeout manteve o mesmo contrato JSON e expôs
  `warnings.code=openai_timeout_deterministic_fallback`.
- Nenhuma alteracao app-side foi necessaria.

## Timing summary

| Tipo | Tempo observado |
| --- | ---: |
| Registro QA | 886 ms |
| Amostras sync iniciais | 9965-13157 ms |
| OpenAI real archetype | 9965 ms |
| OpenAI real baseline | 12178 ms |
| Timeout fallback valido | 12773-13157 ms |
| Reabertura por cache | 582-731 ms |

Latencia se concentrou na etapa OpenAI/timeout. O cache ficou coerente para
releitura de evidencia, retornando rapido e preservando o mesmo shape do
payload.

## Sentry/logging

Nao foi necessario acessar Sentry. A validacao foi feita por contrato publico,
sem coletar logs com prompt completo, decklist completa, token, JWT ou secrets.
O endpoint expôs contexto suficiente no payload (`cache`, `timings`,
`diagnostics`, `warnings.code` para fallback) para diagnosticar timeout vs
OpenAI real sem depender de dados sensiveis.

## Resultado

**PASS.** Houve pelo menos 1 geracao OpenAI real valida com archetype reference
reuse, comandante correto, 99 cartas no main, validacao positiva, zero
off-theme/off-identity observado e qualidade percebida melhor que o baseline sem
`commander_name`.

## Blockers

Nenhum blocker para aceitar a prova. Nao houve 5xx persistente, falha de auth,
backend em commit divergente ou indisponibilidade total da OpenAI.

## Riscos e menores proximos ajustes

- A classificacao tematica e aproximada porque o contrato de archetype reuse nao
  expõe `reference_deck_evaluation`; ela foi calculada por metadata publica de
  cartas, sem decklist em documento.
- A taxa de timeout ainda apareceu em 3/4 amostras com reuse. O fallback e
  valido, mas a experiencia depende de cache/modelo/timeout para obter OpenAI
  real com maior frequencia.
- Ajuste recomendado em sprint separada: medir `OPENAI_TIMEOUT_GENERATE_SECONDS`
  e `OPENAI_MODEL_GENERATE` com amostra maior antes de alterar defaults de
  producao.

## Addendum 2026-05-11 — Timeout reference-guided

O ajuste recomendado foi medido e aplicado de forma incremental em
`server/doc/RELATORIO_AI_GENERATE_REFERENCE_TIMEOUT_TUNING_2026-05-11.md`.

- Publico atual em `a199569`: 5 amostras Velomachus com
  `commander_name` tiveram `fallback_rate=40%`, 5/5 `status=200`, 5/5
  comandante preservado, 5/5 `main_quantity=99` e 5/5 validacao OK.
- Local staging atual com budget 8s: 5/5 Velomachus cairam em fallback por
  timeout.
- Local com patch e `OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` default 20s
  para Commander/Brawl reference-guided: 0/5 fallbacks, 5/5 OpenAI real,
  5/5 comandante preservado, 5/5 `main_quantity=99`, 5/5 validacao OK e
  `on_theme` aproximado 10-13.
- Baseline sem `commander_name` permaneceu no budget legacy de 8s, preservando
  compatibilidade para clientes antigos.

Leitura: o resultado e **PASS WITH RISKS**. A taxa de fallback caiu de forma
clara no caso-alvo sem piorar contrato/validacao, mas o N ainda e pequeno para
afirmar ganho estatistico definitivo de qualidade tematica contra a melhor
amostra publica anterior.

## Addendum 2026-05-11 17:29 BRT — Deploy do timeout reference-guided

O commit `76a8ddc561f686318a6cf0dc4cecefc79de024e1` foi observado no backend
publico por `/health` e validado com 5 probes sanitizados de `POST /ai/generate`
para `commander_name=Velomachus Lorehold`.

| Criterio | Resultado |
| --- | --- |
| Backend publico no commit esperado | PASS, `git_sha` inicia com `76a8ddc`. |
| Usuario QA descartavel | PASS, sem documentar credenciais/JWT. |
| Status HTTP | PASS, 5/5 `200`. |
| Cache | 5/5 miss nos probes iniciais. |
| Commander | 5/5 retornaram e preservaram `Velomachus Lorehold`. |
| Main deck | 5/5 com `main_quantity=99`. |
| Validacao | 5/5 `validation.is_valid=true`. |
| Archetype Reference Reuse | 5/5 `archetype_reference_used=true`, 48 candidatos. |
| Source commanders | `Lorehold, the Historian` e `Quintorius, History Chaser`. |
| Fallback timeout | 0/5, sem `openai_timeout_deterministic_fallback`. |
| Timeout selecionado | 5/5 `timings.openai_timeout_ms=20000`. |
| Timings | p50 `12155 ms`; p95 aproximado `13604 ms`. |
| On-theme aproximado | 5-6 por heuristica agregada conservadora. |

Comparado ao publico pre-deploy (`a199569`, `fallback_rate=40%`) e ao local
staging 8s (`fallback_rate=100%`), o deploy reduziu fallback para 0% sem quebrar
comandante, tamanho do main ou validacao. Resultado atualizado:
**PASS** para o tuning de timeout em producao; a leitura de qualidade tematica
permanece limitada por N=5 e por classificacao aproximada sem decklist completa.

## Addendum 2026-05-12 08:31 BRT — Revalidacao no deploy `9989605`

O backend publico foi revalidado depois de novos commits em `master`. `/health`
retornou `git_sha=998960529660...`, portanto o deploy atual nao inicia mais com
`76a8ddc`, mas `76a8ddc561f686318a6cf0dc4cecefc79de024e1` e ancestral do
`master` implantado.

| Criterio | Resultado |
| --- | --- |
| Backend publico contem o tuning | PASS, `76a8ddc` e ancestral de `9989605`. |
| Usuario QA descartavel | PASS, sem documentar credenciais/JWT. |
| Status HTTP | PASS, 5/5 `200`. |
| Cache | PASS, 5/5 cache miss na rodada final. |
| Commander | PASS, 5/5 retornaram e preservaram `Velomachus Lorehold`. |
| Main deck | PASS, 5/5 com `main_quantity=99`. |
| Validacao | PASS, 5/5 `validation.is_valid=true`. |
| Archetype Reference Reuse | PASS, 5/5 `archetype_reference_used=true`, 48 candidatos. |
| Source commanders | `Excava, the Risen Past` e `Lorehold, the Historian`. |
| Fallback timeout | PASS, 0/5 com `openai_timeout_deterministic_fallback`. |
| Timeout selecionado | PASS, 5/5 `timings.openai_timeout_ms=20000`. |
| Timings | p50 `13739 ms`; p95 aproximado `18071 ms`. |

Resultado atualizado: **PASS WITH RISKS** para a revalidacao de 2026-05-12.
O comportamento de Archetype Reference Reuse e do timeout reference-guided segue
correto e app-consumable, mas o criterio estrito de SHA exato deve ser lido como
risco de rastreabilidade porque o backend publico ja esta em commit posterior.

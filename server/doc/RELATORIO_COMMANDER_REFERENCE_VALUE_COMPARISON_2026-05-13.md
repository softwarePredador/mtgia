# Commander Reference Value Comparison - 2026-05-13

## Resultado

**PASS.**

O usuario deve perceber melhora clara quando o app envia `commander_name` para
`POST /ai/generate`: os 18 probes com `commander_name` preservaram o comandante,
usaram profile/card-stats/corpus, retornaram main deck com 99 cartas, nao
colocaram o comandante nas 99, nao tiveram cartas invalidas/off-identity e
responderam em p50 `946ms` / p95 `1084ms`.

O baseline sem `commander_name`, usando prompts equivalentes com o nome do
comandante em texto livre, continuou compativel e retornou `HTTP 200`/validacao
OK em 18/18, mas preservou o comandante esperado em apenas 1/18, nao ativou
profile/stats/corpus em nenhum probe, teve 17/18 timeout fallbacks e respondeu em
p50 `12648ms` / p95 `12714ms`.

## Escopo e seguranca

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Branch/local commit inspecionado: `ff2adcfabb44e1ebedbe63dfe59eddffe77703bf`
  (`master`, fast-forward ja atualizado).
- Backend publico no `/health`: `git_sha=ff2adcfabb44e1ebedbe63dfe59eddffe77703bf`.
- Usuario QA descartavel criado via `/auth/register`; credenciais, token e
  e-mail completo nao foram registrados.
- Scanner, camera e OCR ficaram fora do escopo.
- Artifact sanitizado:
  `server/test/artifacts/commander_reference_value_comparison_2026-05-13/summary.json`.
- Nao foram salvas respostas brutas, decklists geradas nem prompts completos.

## Matriz agregada

| Modo | Probes | HTTP 200 | Validation OK | Commander preserved | Main 99 | Profile/stats/corpus | Fallback | Timeout fallback | Invalid/off-identity | Commander in 99 | p50 | p95 | Approx theme hits avg |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `with_commander_name` | 18 | 18 | 18 | 18 | 18 | 18/18/18 | 18 | 0 | 0/0 | 0 | 946ms | 1084ms | 35.17 |
| `baseline_without_commander_name` | 18 | 18 | 18 | 1 | 18 | 0/0/0 | 17 | 17 | 1/0 | 0 | 12648ms | 12714ms | 0.28 |

Observacao: no modo `with_commander_name`, `fallback_count=18` reflete o flag
legado `is_mock`/fallback deterministico usado pelo caminho reference-guided
promovido; nao houve `ai_generation_timed_out`. O sinal operacional que
importa para risco de UX aqui e `timeout_fallback_count=0`.

## Matriz por comandante

| Commander | With preserved | Baseline preserved | With profile/stats/corpus | With p50/p95 | Baseline p50/p95 | Delta theme avg |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Prosper, Tome-Bound | 3/3 | 0/3 | 3/3/3 | 1048/1261ms | 12706/12751ms | +34.00 |
| Edgar Markov | 3/3 | 1/3 | 3/3/3 | 972/985ms | 12639/12640ms | +31.33 |
| Aesi, Tyrant of Gyre Strait | 3/3 | 0/3 | 3/3/3 | 959/992ms | 12662/12678ms | +30.00 |
| Dina, Essence Brewer | 3/3 | 0/3 | 3/3/3 | 933/938ms | 12647/12648ms | +38.00 |
| Zimone, Infinite Analyst | 3/3 | 0/3 | 3/3/3 | 940/941ms | 12646/12660ms | +42.00 |
| Lorehold, the Historian | 3/3 | 0/3 | 3/3/3 | 889/895ms | 12650/12662ms | +34.00 |

## Caminho selecionado

| Modo | Caminho observado | Evidencia |
| --- | --- | --- |
| `with_commander_name` | Commander Reference deterministic fast path | `reference_deterministic_count=18`, `openai_count=0`, `profile_used=18`, `stats_used=18`, `corpus_used=18`, `cache_hit_count=0`. |
| `baseline_without_commander_name` | Caminho legado prompt-only com OpenAI e fallback deterministico por timeout na maior parte dos probes | `openai_count=18`, `timeout_fallback_count=17`, `profile_used=0`, `stats_used=0`, `corpus_used=0`, `cache_hit_count=0`. |

## Contrato app/backend

O contrato documentado em `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi lido e
continua coerente: `commander_name` e opcional/backward-compatible, mas e o campo
que ativa guidance exata de Commander Reference. `generated_deck` e `validation`
continuam sendo a fonte app-facing de verdade. Nao houve alteracao de metodo,
request body obrigatorio, response shape ou consumidor mobile; por isso o API map
nao precisou ser alterado.

Conclusao para consumo mobile: quando o usuario escolhe um comandante em
Commander/Brawl, o app deve continuar enviando `commander_name`. O prompt em
texto livre sozinho nao e suficiente para garantir preservacao do comandante,
uso de corpus/profile ou latencia aceitavel.

## Legalidade, identidade de cor e qualidade

- Com `commander_name`: 18/18 `validation_ok`, 18/18 `main_quantity=99`,
  0 invalid cards, 0 off-identity, 0 comandante nas 99.
- Baseline: 18/18 `validation_ok` e 18/18 `main_quantity=99`, mas 1 carta
  invalida foi removida/reparada em um probe de Edgar; ainda assim nao houve
  erro off-identity nem comandante nas 99.
- Os hits tematicos aproximados vieram de diagnostics
  `reference_deck_evaluation`/`core_package_matched` quando disponiveis; no
  baseline, onde nao ha diagnostics de profile/corpus, a contagem e apenas uma
  aproximacao in-memory por keywords de nomes de cartas. Nenhum nome de carta foi
  persistido.

## Sentry/logging

Nao houve acesso a Sentry nem exposicao de `SENTRY_DSN`. Do lado do contrato
fonte, `server/routes/ai/generate/index.dart` captura excecoes nao tratadas com
`captureRouteException(..., tags: {'route': 'ai_generate'})`. Nos probes
publicos, a evidencia disponivel pelo cliente ficou limitada a status/timings
sanitizados; todas as chamadas retornaram `HTTP 200`.

## Comandos executados

```bash
git --no-pager status --short --branch
git pull --ff-only origin master
curl -fsS --max-time 10 https://evolution-cartinhas.8ktevp.easypanel.host/health
python3 <harness temporario de probes sanitizados>
```

Validacoes finais registradas no fechamento:

```bash
git diff --check
<secret scan documental/artifact com Python>
```

## Blockers e menores proximos ajustes

Blockers: nenhum.

Menor ajuste recomendado, nao bloqueante: separar no futuro os sinais
`deterministic_reference_guided` e `fallback` nos summaries para evitar confusao,
porque o caminho promovido com `commander_name` usa fallback/mock deterministico
valido sem timeout, enquanto o baseline teve fallback de timeout real em 17/18.

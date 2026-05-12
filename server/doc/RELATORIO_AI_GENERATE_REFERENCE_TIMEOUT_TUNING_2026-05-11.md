# AI Generate Reference Timeout Tuning — 2026-05-11

## Objetivo

Reduzir fallback/timeout de `POST /ai/generate` para Commander quando
`commander_name` ativa Commander Reference Profile ou Archetype Reference Reuse,
preservando contrato, comandante, tamanho final, validacao e qualidade tematica.

Fora de escopo: scanner, camera, OCR, prompts completos, decklists completas,
tokens, JWT, Sentry DSN, `DATABASE_URL`, `OPENAI_API_KEY` e qualquer segredo.

## Commits inspecionados

| Commit | Leitura |
| --- | --- |
| `a1995694b7e94ab76a44079b5915d7b23cac825d` | `master`/`origin/master` antes do ajuste; backend publico em producao. |
| `f3bac2bb2fa8de53430acd940732a77e1cd2e133` | Prova publica anterior de archetype reference. |
| `637054b9a706b0a232bab7fab72cc21c0db6ecd7` | Fallback preserva `commander_name`. |
| `e5d8d8a26d6692f0d038bdf05d1778ade2b43759` | Commander Archetype Reference Reuse. |

Backend publico validado:
`https://evolution-cartinhas.8ktevp.easypanel.host/health` retornou `200`,
`environment=production` e `git_sha=a1995694b7e94ab76a44079b5915d7b23cac825d`.

## Experimento

- Usuario QA descartavel por rodada; credenciais/JWT nao documentados.
- Amostras sync de `POST /ai/generate`, sem cache hit, com payloads sanitizados.
- Variante principal: 5 amostras com `commander_name=Velomachus Lorehold`.
- Baseline: 1 amostra sem `commander_name`.
- Metricas coletadas: status, elapsed, fallback warning, validacao, comandante,
  quantidade main, diagnostics de reference/archetype, timings agregados e
  `on_theme` aproximado. Nenhuma decklist foi persistida neste relatorio.

## Resultado dos probes

| Variante | Velomachus N | Fallback rate | Status | Commander | Main | Validacao | Archetype reuse | p50 | p95 | On-theme aprox. |
| --- | ---: | ---: | --- | --- | --- | --- | --- | ---: | ---: | --- |
| Publico atual `a199569` | 5 | 40% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 13318 ms | 17359 ms | 0-12 |
| Local atual staging 8s | 5 | 100% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 13980 ms | 14067 ms | 0 |
| Local env 20s global | 5 | 0% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 17662 ms | 19290 ms | 10-11 |
| Local patch reference 20s | 5 | 0% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 20074 ms | 24496 ms | 10-13 |

Baseline sem `commander_name` no patch permaneceu no budget legacy:
`fallback_rate=100%`, `timings.openai_timeout_ms=8000`, `status=200`,
`main_quantity=99`, `validation.is_valid=true`. Isso confirma compatibilidade:
o ajuste nao aumenta latencia do caminho legacy sem reference guidance.

## Patch aplicado

- `server/lib/ai_generate_performance_support.dart`
  - adiciona `selectAiGenerateOpenAiTimeout`, funcao pura testada.
  - usa `OPENAI_TIMEOUT_GENERATE_SECONDS` para legacy.
  - usa `OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` somente quando ha reference
    guidance em Commander/Brawl.
  - default reference-guided: 20s, clamp 3-90s.
  - override explicito por env e honrado apos clamp; nao ha `max()` que esconda
    uma reducao operacional intencional.
- `server/routes/ai/generate/index.dart`
  - passa a selecionar o timeout pelo helper.
  - adiciona `timings.openai_timeout_ms` ao payload.
  - log de timeout inclui apenas `format`, `timeout_ms`, env key e flag
    `reference_guidance`, sem prompt, decklist, token ou segredo.
- `server/test/ai_generate_performance_support_test.dart`
  - cobre legacy sem guidance, Commander guidance default 20s, formatos fora de
    Commander/Brawl e overrides bounded.

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| Fallback rate caiu para Commander reference-guided | PASS, local 8s 100% -> patch 0% em 5 amostras. |
| Pelo menos 1 OpenAI real valido manteve comandante/99/validation | PASS, 5/5 no patch. |
| Qualidade tematica nao piorou contra fallback | PASS WITH RISKS, amostras reais ficaram `on_theme` aprox. 10-13; N=5 ainda pequeno contra a prova publica anterior `on_theme=18`. |
| Contrato atual preservado | PASS, campos sao aditivos e legacy sem guidance manteve timeout 8s. |
| Sem 5xx/422 inesperado | PASS nas amostras. |
| Sem exposicao de secrets/decklists | PASS. |

## Timing summary

| Caminho | OpenAI budget | Observacao |
| --- | ---: | --- |
| Legacy sem `commander_name` | 8s staging/dev, 12s prod | Inalterado; fallback valido continua rapido quando OpenAI passa do budget. |
| Commander/Brawl com reference guidance | 20s default | Reduziu timeout/fallback e deixa OpenAI real concluir com mais frequencia. |
| Override operacional | `OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` | Configuravel por env, clamp 3-90s, sem hardcode irreversivel de modelo. |

## App/backend contract findings

- O app continua usando `generated_deck` como fonte de verdade.
- `timings.openai_timeout_ms` e diagnosticos continuam opcionais/aditivos.
- `warnings.code=openai_timeout_deterministic_fallback` segue sendo o indicador
  de fallback por timeout.
- O caminho async chama o mesmo executor sync, portanto herda o novo budget
  apenas quando o payload ativa reference guidance.

## Sentry/logging

Nao foi necessario acessar Sentry. O patch melhora observabilidade pelo payload
sanitizado (`timings.openai_timeout_ms`) e log sem prompt/decklist/JWT/secrets.

## Resultado

**PASS WITH RISKS.** O patch reduziu fallback/timeout no caso-alvo sem degradar
validacao, preservacao do comandante ou tamanho final nas amostras coletadas.
O risco remanescente e estatistico: N=5 e `on_theme` aproximado menor que a
melhor amostra publica anterior, embora ainda acima do baseline historico.

## Menores proximos ajustes

- Repetir com N>=20 por comandante depois de deploy para medir p95 real em
  producao e confirmar headroom contra proxy/client timeout.
- Se p95 continuar proximo de 20s, avaliar `OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS=25`
  por env antes de mudar default em codigo.

## Addendum 2026-05-11 17:29 BRT — Prova publica do deploy `76a8ddc`

### Objetivo

Validar no backend publico o deploy do commit
`76a8ddc561f686318a6cf0dc4cecefc79de024e1` ("Tune AI generate reference
timeout") para `POST /ai/generate` com `commander_name=Velomachus Lorehold` e
Commander Archetype Reference Guidance.

### Comandos executados

| Comando | Resultado |
| --- | --- |
| `git fetch origin master && git pull --ff-only origin master` | PASS, branch local `master` em `76a8ddc`. |
| Poll sanitizado de `GET /health` no backend publico | PASS, `200`, `environment=production`, `git_sha=76a8ddc561f686318a6cf0dc4cecefc79de024e1`. |
| Probe sanitizado Python: register QA descartavel + 5x `POST /ai/generate` | PASS, 5/5 `status=200`. |
| `git diff --check` | PASS. |
| Scan simples de secrets no diff | PASS, sem JWT/token/API key/DSN/DB URL no diff. |

Credenciais, JWT, prompt completo, decklists completas, tokens, DSN, URL de
banco e chaves OpenAI nao foram persistidos nem documentados.

### Resultado publico pos-deploy

| Variante | Velomachus N | Fallback rate | Status | Commander | Main | Validacao | Archetype reuse | OpenAI budget | p50 | p95 aprox. | On-theme aprox. |
| --- | ---: | ---: | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| Publico deploy `76a8ddc` | 5 | 0% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 20000 ms | 12155 ms | 13604 ms | 5-6 |

Detalhe sanitizado por amostra:

| Amostra | Status | Elapsed | Cache | Warning | Commander | Main | Validacao | Archetype reuse | Candidatos | Timeout |
| --- | ---: | ---: | --- | --- | --- | ---: | --- | --- | ---: | ---: |
| `public_76a8ddc_1` | 200 | 11111 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_76a8ddc_2` | 200 | 12867 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_76a8ddc_3` | 200 | 13604 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_76a8ddc_4` | 200 | 11427 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_76a8ddc_5` | 200 | 12155 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |

`diagnostics.reference_profile_used=false` e
`diagnostics.reference_card_stats_used=false` em todas as amostras, confirmando
que o caminho selecionado foi Archetype Reference Reuse, nao profile exato. As
fontes observadas foram `Lorehold, the Historian` e
`Quintorius, History Chaser`.

### Comparacao com evidencia pre-deploy

| Evidencia | Fallback rate | Leitura |
| --- | ---: | --- |
| Publico pre-deploy `a199569` | 40% | 2/5 fallbacks em amostra Velomachus reference-guided. |
| Local staging 8s | 100% | 5/5 fallbacks no budget antigo. |
| Local patch reference 20s | 0% | 5/5 OpenAI real no budget novo. |
| Publico pos-deploy `76a8ddc` | 0% | 5/5 OpenAI real, `timings.openai_timeout_ms=20000`. |

### Resultado

**PASS.** O backend publico esta no commit esperado e a taxa de fallback do
caso-alvo caiu para 0% em 5 amostras, mantendo comandante correto, 99 cartas no
main, `validation.is_valid=true`, cache miss nos probes, diagnostics coerentes e
contrato app-facing estavel. A metrica `on_theme` segue aproximada e
conservadora porque foi calculada apenas por heuristica agregada, sem persistir
decklist completa.

## Addendum 2026-05-12 08:31 BRT — Revalidacao publica no `master` atual

### Objetivo

Revalidar o backend publico depois dos commits posteriores ao tuning, garantindo
que o comportamento introduzido por
`76a8ddc561f686318a6cf0dc4cecefc79de024e1` continua ativo em
`POST /ai/generate` com `commander_name=Velomachus Lorehold`.

### Comandos executados

| Comando | Resultado |
| --- | --- |
| `git fetch origin master --prune` | PASS, `master` local sincronizado com `origin/master` em `998960529660...`; `76a8ddc` permanece ancestral. |
| Poll sanitizado de `GET /health` no backend publico | PASS WITH RISKS, 12 polls retornaram `200`, `environment=production`, `git_sha=998960529660...`; o SHA nao inicia com `76a8ddc` porque o deploy avancou, mas contem o commit esperado. |
| Probe sanitizado Python: register QA descartavel + 5x `POST /ai/generate` | PASS, 5/5 `status=200`, 5/5 cache miss. |

Credenciais, JWT, prompt completo, decklists completas, tokens, DSN, URL de
banco e chaves OpenAI nao foram persistidos nem documentados.

### Resultado publico no deploy atual

| Variante | Velomachus N | Fallback rate | Status | Commander | Main | Validacao | Archetype reuse | OpenAI budget | p50 | p95 aprox. | On-theme aprox. |
| --- | ---: | ---: | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| Publico deploy `9989605` contendo `76a8ddc` | 5 | 0% | 5x 200 | 5/5 preservado | 5/5 = 99 | 5/5 valid | 5/5 | 20000 ms | 13739 ms | 18071 ms | 6 |

Detalhe sanitizado por amostra:

| Amostra | Status | Elapsed | Cache | Warning | Commander | Main | Validacao | Archetype reuse | Candidatos | Timeout |
| --- | ---: | ---: | --- | --- | --- | ---: | --- | --- | ---: | ---: |
| `public_9989605_1` | 200 | 18071 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_9989605_2` | 200 | 13739 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_9989605_3` | 200 | 13107 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_9989605_4` | 200 | 12935 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |
| `public_9989605_5` | 200 | 13883 ms | miss | nenhum | Velomachus Lorehold | 99 | valid | true | 48 | 20000 ms |

`diagnostics.reference_profile_used=false` e
`diagnostics.reference_card_stats_used=false` continuaram indicando Archetype
Reference Reuse, nao profile exato. As fontes observadas no deploy atual foram
`Excava, the Risen Past` e `Lorehold, the Historian`, refletindo os profiles
adicionados depois do tuning.

### Comparacao com evidencia local/pre-deploy

| Evidencia | Fallback rate | Leitura |
| --- | ---: | --- |
| Publico pre-deploy `a199569` | 40% | 2/5 fallbacks em amostra Velomachus reference-guided. |
| Local staging 8s | 100% | 5/5 fallbacks no budget antigo. |
| Local patch reference 20s | 0% | 5/5 OpenAI real no budget novo. |
| Publico deploy `76a8ddc` | 0% | 5/5 OpenAI real, `timings.openai_timeout_ms=20000`. |
| Publico deploy atual `9989605` | 0% | 5/5 OpenAI real, `timings.openai_timeout_ms=20000`, commit esperado ancestral. |

### Resultado

**PASS WITH RISKS.** O comportamento do tuning esta ativo no backend publico
atual: fallback publico segue em 0% no caso-alvo, com comandante correto,
`main_quantity=99`, `validation.is_valid=true`, diagnostics coerentes e budget
OpenAI de 20s. O risco e somente de rastreabilidade do criterio de deploy: o
`git_sha` publico ja nao inicia com `76a8ddc`, pois `master` foi implantado em
um commit posterior (`9989605`) que contem o tuning como ancestral.

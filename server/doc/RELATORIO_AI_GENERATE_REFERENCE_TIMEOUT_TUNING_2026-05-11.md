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

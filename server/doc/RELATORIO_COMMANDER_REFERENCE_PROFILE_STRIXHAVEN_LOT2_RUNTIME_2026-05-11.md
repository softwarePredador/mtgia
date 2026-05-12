# Commander Reference Profiles Strixhaven Lot 2 - Public Runtime - 2026-05-11

## Resultado final em 2026-05-12 10h15

**PASS.** O runtime publico completo dos 8 Commander Reference Profiles
Strixhaven lot2 foi fechado no backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host` apos a correcao de card
resolution do commit `1dcf7ff31832d5fa9a6e53009a9e8caaf92d4701`.

Todos os 8 probes sanitizados de `POST /ai/generate` retornaram `200`,
preservaram o comandante exato, entregaram `main_quantity=99`,
`validation.is_valid=true`, `reference_profile_used=true` e
`reference_card_stats_used=true`. Nenhum token, JWT, senha, DSN, URL de banco,
chave OpenAI, prompt completo ou decklist completa foi registrado.

## Escopo e deploy final

| Item | Resultado |
| --- | --- |
| Branch alvo | `master` |
| Commit local/remoto | `1dcf7ff31832d5fa9a6e53009a9e8caaf92d4701` |
| `/health` publico | PASS, `git_sha=1dcf7ff31832d5fa9a6e53009a9e8caaf92d4701`, `environment=production` |
| `/health/ready` publico | PASS, DB healthy, `cards_data.card_count=33791` |
| Usuario QA descartavel | Criado com prefixo sanitizado `qa_strix_lot2` e dominio `example.invalid`; token usado apenas em memoria |
| Scanner/camera/OCR | Fora do escopo |

## Comandos executados na rodada final

```bash
git fetch origin master --quiet
git pull --ff-only --quiet
git status --short --branch
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health/ready
python3 <sanitized public /cards availability + auth + ai/generate lot2 probe runner>
```

Validacoes finais de fechamento foram executadas apos a atualizacao deste
relatorio: `git diff --check` e scan simples de segredos nos arquivos alterados.

## Disponibilidade publica dos comandantes

| Commander | `/cards` status | `total_returned` | Exact matches |
| --- | ---: | ---: | ---: |
| Aziza, Mage Tower Captain | 200 | 2 | 2 |
| Berta, Wise Extrapolator | 200 | 2 | 2 |
| Excava, the Risen Past | 200 | 1 | 1 |
| Gorma, the Gullet | 200 | 1 | 1 |
| Muddle, the Ever-Changing | 200 | 1 | 1 |
| Primo, the Unbounded | 200 | 1 | 1 |
| Scriv, the Obligator | 200 | 1 | 1 |
| Zaffai and the Tempests | 200 | 2 | 2 |

## Probe matrix final de `/ai/generate`

| Commander | HTTP | Elapsed ms | Fallback/warning | Cache | Commander returned | Preservado | Main qty | Validation | Invalid count | Profile/stats | On-theme | Off-identity aprox. |
| --- | ---: | ---: | --- | --- | --- | --- | ---: | --- | ---: | --- | ---: | --- |
| Aziza, Mage Tower Captain | 200 | 17,459 | `validation_warnings` | miss | Aziza, Mage Tower Captain | true | 99 | true | 2 | true / true | 46 | 0 por validacao backend |
| Berta, Wise Extrapolator | 200 | 13,439 | `validation_warnings` | miss | Berta, Wise Extrapolator | true | 99 | true | 0 | true / true | 44 | 0 por validacao backend |
| Excava, the Risen Past | 200 | 20,792 | `openai_timeout_deterministic_fallback` | miss | Excava, the Risen Past | true | 99 | true | 0 | true / true | 44 | 0 por validacao backend |
| Gorma, the Gullet | 200 | 13,689 | `validation_warnings` | miss | Gorma, the Gullet | true | 99 | true | 1 | true / true | 44 | 0 por validacao backend |
| Muddle, the Ever-Changing | 200 | 20,710 | `openai_timeout_deterministic_fallback` | miss | Muddle, the Ever-Changing | true | 99 | true | 0 | true / true | 45 | 0 por validacao backend |
| Primo, the Unbounded | 200 | 10,348 | `validation_warnings` | miss | Primo, the Unbounded | true | 99 | true | 1 | true / true | 43 | 0 por validacao backend |
| Scriv, the Obligator | 200 | 15,276 | `validation_warnings` | miss | Scriv, the Obligator | true | 99 | true | 0 | true / true | 39 | 0 por validacao backend |
| Zaffai and the Tempests | 200 | 12,246 | `validation_warnings` | miss | Zaffai and the Tempests | true | 99 | true | 0 | true / true | 52 | 0 por validacao backend |

Repeticao obrigatoria para timeout/fallback: Excava e Muddle foram repetidos
uma vez cada. As repeticoes tambem retornaram `200`, comandante preservado,
`main_quantity=99` e `validation.is_valid=true`; a repeticao de Excava teve
1 invalid card removido com seguranca e a de Muddle teve 1 invalid card removido
com seguranca. Nao houve 422 na matriz final.

## Package keys finais observadas

| Commander | Package keys |
| --- | --- |
| Aziza, Mage Tower Captain | `copy_worthy_spells`, `interaction_and_protection`, `spell_payoffs_and_copy`, `token_creature_sources`, `untap_vigilance_support` |
| Berta, Wise Extrapolator | `counter_engine`, `interaction_and_protection`, `ramp`, `untap_support`, `x_spells_and_fractals` |
| Excava, the Risen Past | `artifact_enchantment_engine`, `cheap_permanent_value_targets`, `graveyard_setup`, `interaction_and_protection`, `spirit_and_token_payoffs` |
| Gorma, the Gullet | `counter_persist_support`, `death_payoffs_and_draw`, `fodder_and_recursion`, `interaction`, `sacrifice_outlets` |
| Muddle, the Ever-Changing | `interaction_and_protection`, `nonlegendary_copy_targets`, `spell_velocity`, `spellslinger_payoffs`, `token_and_combat_payoffs` |
| Primo, the Unbounded | `base_power_zero_threats`, `counter_engine`, `evasion_and_finish`, `interaction_and_protection`, `ramp` |
| Scriv, the Obligator | `aura_enchantment_engine`, `draw_and_value`, `interaction_and_protection`, `politics_and_deterrents` |
| Zaffai and the Tempests | `big_spell_payoffs`, `copy_recursion_payoffs`, `interaction_and_protection`, `ramp_and_cost_support`, `selection_and_setup` |

## Timing summary final

| Grupo | Min | p50 | Max |
| --- | ---: | ---: | ---: |
| 8 probes primarios | 10,348 ms | 14,482 ms | 20,792 ms |
| 2 repeticoes de fallback/timeout | 16,237 ms | 18,524 ms | 20,811 ms |

Latencia concentrada em OpenAI/fallback: `openai_ms` variou de 9,414 ms a
20,002 ms nos probes primarios. `reference_profile_ms` ficou baixo
(13-61 ms), `validation_ms` ficou em 172-406 ms quando exposto, e
`meta_context_ms` ficou entre 0-2 ms.

## Path matrix e contrato app/backend

| Pergunta | Evidencia final |
| --- | --- |
| Path selecionado | Profile-guided `/ai/generate`; 6/8 passaram pela geracao principal com warnings de saneamento e 2/8 usaram `openai_timeout_deterministic_fallback` valido. |
| Cache | 8/8 `cache.hit=false` na matriz primaria, evitando dependencia de resultados antigos. |
| Job polling | Nao aplicavel; probes foram sync, sem `async=true`. |
| Profile/card stats | 8/8 com `reference_profile_used=true` e `reference_card_stats_used=true`. |
| App preview/apply | Resposta manteve o contrato `generated_deck.commander.name` + `generated_deck.cards[] {name, quantity}` consumido pelo app; nenhuma mudanca de contrato foi feita. |
| Legalidade/identidade | `validation.is_valid=true` em 8/8; off-identity aproximado 0 por validacao backend strict. |
| Complete/filler | Fora do escopo desta rodada; os probes foram de generate profile-guided, nao `/ai/optimize` complete. |
| Meta deck references | Nao foram usados como fonte principal; a evidencia final veio de reference profiles/card stats do lote. |
| Sentry/logging | Nao houve 5xx nem crash. O handler segue capturando excecoes inesperadas com tag `route=ai_generate`; 422 nao ocorreu na matriz final. |

## Invalid cards e riscos

- Invalid cards apareceram apenas como saneamento seguro em respostas `200`.
  Buckets sanitizados: `unresolved_or_not_in_public_db`.
- Contagens primarias: Aziza 2, Gorma 1, Primo 1; os demais 0. O deck final
  permaneceu valido porque o backend removeu os nomes nao resolvidos antes da
  validacao final.
- Risco operacional restante: o refresh publico oficial de sets novos continua
  recomendado para reduzir dependencias de self-healing pontual via
  `/cards/resolve` e reduzir invalid cards gerados por cartas ainda ausentes no
  DB publico.

## Bloqueadores e menores proximos ajustes

- **Bloqueadores:** nenhum para fechar o runtime publico lot2.
- **Menor proximo ajuste:** acompanhar os warnings de invalid card por carta
  ausente no DB publico e rodar refresh de sets novos no ambiente publico.

## Resultado atualizado em 2026-05-12 10h

**PASS na amostra de unblock.** Os 8 comandantes que retornavam
`GET /cards?name=<commander>` com `total_returned=0` foram populados no backend
publico pela rota existente `POST /cards/resolve`, com match exato Scryfall e
sem aliases manuais. Depois disso, 3 probes publicos sanitizados de
`/ai/generate` para Aziza, Excava e Zaffai retornaram `200`,
`validation.is_valid=true`, comandante preservado e `main_quantity=99`.

Resumo do reparo de dados publico:

| Commander | Antes `/cards` | Resolve source | Match exato | Depois `/cards` |
| --- | ---: | --- | --- | ---: |
| Aziza, Mage Tower Captain | 0 | scryfall | true | 2 |
| Berta, Wise Extrapolator | 0 | scryfall | true | 2 |
| Excava, the Risen Past | 0 | scryfall | true | 1 |
| Gorma, the Gullet | 0 | scryfall | true | 1 |
| Muddle, the Ever-Changing | 0 | scryfall | true | 1 |
| Primo, the Unbounded | 0 | scryfall | true | 1 |
| Scriv, the Obligator | 0 | scryfall | true | 1 |
| Zaffai and the Tempests | 0 | scryfall | true | 2 |

Probes publicos apos reparo:

| Commander | HTTP | Commander preservado | Main qty | Validation | Profile/stats |
| --- | ---: | --- | ---: | --- | --- |
| Aziza, Mage Tower Captain | 200 | true | 99 | true | true / true |
| Excava, the Risen Past | 200 | true | 99 | true | true / true |
| Zaffai and the Tempests | 200 | true | 99 | true | true / true |

Fix preventivo implementado: `server/bin/commander_reference_profile.dart` agora
inclui `commander_card_resolution` no summary e bloqueia `--apply` quando o
comandante do profile nao resolve em `cards`, exceto com override explicito
`--allow-unresolved-commander` para curadoria pre-release nao runtime-ready.
Detalhes em
`server/doc/RELATORIO_AI_GENERATE_CARD_RESOLUTION_FIX_2026-05-12.md`.

Nota: a matriz publica completa 12/12 deste relatorio nao foi reexecutada nesta
rodada; a amostra solicitada foi desbloqueada e o blocker raiz dos 8
comandantes (`total_returned=0`) foi removido.

## Resultado atualizado em 2026-05-12

**BLOCKED.** O backend publico ja serve o commit novo de `master`
(`git_sha=e0266cc33ed3902c5b6595272dd9ceb0a2624ecb`) e continua ativando
`reference_profile_used=true` / `reference_card_stats_used=true` para todos os
8 comandantes do lote, mas nenhum probe profile-guided retornou deck Commander
valido.

A causa raiz continua sendo de dados publicos: os 8 comandantes existem em
`commander_reference_profiles`, mas nao existem como cards resolviveis no
backend publico (`GET /cards?name=<commander>&limit=5` retornou
`total_returned=0` e `exact_matches=0` para todos). Sem `card_id` real do
comandante, o backend nao consegue validar legalidade nem entregar payload que o
app consiga salvar com seguranca.

## Escopo e sanitizacao

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Branch alvo: `master`, sincronizada com `origin/master`.
- Branch/commit local inspecionado: `master` em
  `e0266cc33ed3902c5b6595272dd9ceb0a2624ecb`
  (`docs: revalidate ai generate timeout deploy`).
- Commits relevantes inspecionados:
  - `e0266cc` - deploy publico atual observado em `/health`.
  - `9989605` - runtime audit anterior do lote 2.
  - `a137dd5` - aplicacao/documentacao do lote Strixhaven lot 2.
- Nenhum token, JWT, senha, DSN, URL de banco, chave OpenAI, prompt completo ou
  decklist completa foi registrado.
- Usuario QA descartavel criado apenas para chamadas autenticadas; somente
  prefixo/dominio sanitizados foram persistidos no artifact.

## Comandos executados

```bash
git fetch origin master --quiet
git pull --ff-only --quiet
git status --short --branch
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health/ready
python3 <sanitized public ai/generate probe runner>
python3 <sanitized public /cards availability checker>
git diff --check
git grep <secret-patterns> -- <changed files>
```

## Deploy observado

| Etapa | Resultado |
| --- | --- |
| `git status` inicial | `master...origin/master`, sem arquivos modificados. |
| Commit local apos sync | `e0266cc33ed3902c5b6595272dd9ceb0a2624ecb`. |
| `/health` | PASS, `git_sha=e0266cc33ed3902c5b6595272dd9ceb0a2624ecb`, `environment=production`. |
| `/health/ready` | PASS, database healthy, `cards_data.card_count=33777`. |
| Usuario QA descartavel | `POST /auth/register` retornou 201 e token recebido; token nao foi persistido. |

## Probe matrix

Foram executados 14 probes publicos sanitizados:

- 1 probe com `commander_name` exato para cada um dos 8 comandantes.
- 3 amostras para Aziza e 3 para Zaffai como comandantes prioritarios.
- 2 baselines sem `commander_name` para Aziza e Zaffai.

| Grupo | Probes | 200 | 422 | Commander preservado | Main 99 | `validation.is_valid` | Profile/stats diagnostics |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Com `commander_name` | 12 | 0 | 12 | 0 | 2 | 0 | 12/12 com profile e card stats ativos |
| Baseline sem `commander_name` | 2 | 2 | 0 | 0 | 2 | 2 | Sem profile/stats, esperado |

### Resultado por comandante com `commander_name`

| Commander | Status | Main qty | Validacao | Profile | Stats | On-theme candidates | Unresolved refs | Off-identity aprox. | Fallback/timeout |
| --- | ---: | ---: | --- | --- | --- | ---: | ---: | ---: | --- |
| Aziza, Mage Tower Captain | 422 | 79 / 89 / 82 | invalid | true | true | 46 | 0 | 0 | nao |
| Berta, Wise Extrapolator | 422 | 37 | invalid | true | true | 44 | 0 | 0 | nao |
| Excava, the Risen Past | 422 | 72 | invalid | true | true | 44 | 0 | 0 | nao |
| Gorma, the Gullet | 422 | 99 | invalid | true | true | 44 | 0 | 0 | timeout fallback tambem invalido |
| Muddle, the Ever-Changing | 422 | 82 | invalid | true | true | 45 | 0 | 0 | nao |
| Primo, the Unbounded | 422 | 78 | invalid | true | true | 43 | 0 | 0 | nao |
| Scriv, the Obligator | 422 | 76 | invalid | true | true | 39 | 0 | 0 | nao |
| Zaffai and the Tempests | 422 | 99 / 42 / 41 | invalid | true | true | 52 | 0 | 0 | 1/3 timeout fallback tambem invalido |

`off_identity` e aproximado porque a falha principal ocorre antes de existir
um deck Commander valido. Nas cartas resolvidas retornadas, nenhuma entrada com
`color_identity` presente excedeu a identidade esperada.

### Baselines sem `commander_name`

| Baseline | Status | Commander retornado | Main qty | `validation.is_valid` | Profile | Stats | Fallback/timeout |
| --- | ---: | --- | ---: | --- | --- | --- | --- |
| Aziza theme, sem commander_name | 200 | Isamaru, Hound of Konda | 99 | true | null | null | timeout fallback |
| Zaffai theme, sem commander_name | 200 | Isamaru, Hound of Konda | 99 | true | null | null | timeout fallback |

Os baselines provam que o endpoint publico consegue devolver um Commander
valido sem profile exato, mas por fallback deterministico apos timeout. A
comparacao mostra queda forte de qualidade/intencao: o comandante retornado e
generico e nao preserva o tema Strixhaven solicitado quando `commander_name` e
omitido.

## Timing summary

| Grupo | p50 | p95 aprox. | Min | Max |
| --- | ---: | ---: | ---: | ---: |
| Com `commander_name` | 17,454 ms | 20,813 ms | 12,194 ms | 20,832 ms |
| Baseline sem `commander_name` | 13,095 ms | 13,546 ms | 12,645 ms | 13,546 ms |

Observacoes de timing:

- 10/12 respostas 422 profile-guided de validacao principal nao expuseram
  `timings` no corpo final.
- 2/12 respostas 422 passaram por `openai_timeout_deterministic_fallback`;
  ambas expuseram `openai_timeout_ms=20000`, `openai_ms` aproximado de 20s e
  `total_ms` aproximado de 20.2s, mas o fallback tambem falhou porque o
  comandante nao resolve em `/cards`.
- A latencia se concentra no caminho OpenAI/fallback; `reference_profile_ms`
  observado nos timeouts ficou em 13-14 ms.

## Package keys observadas

| Commander | Package keys |
| --- | --- |
| Aziza, Mage Tower Captain | `copy_worthy_spells`, `interaction_and_protection`, `spell_payoffs_and_copy`, `token_creature_sources`, `untap_vigilance_support` |
| Berta, Wise Extrapolator | `counter_engine`, `interaction_and_protection`, `ramp`, `untap_support`, `x_spells_and_fractals` |
| Excava, the Risen Past | `artifact_enchantment_engine`, `cheap_permanent_value_targets`, `graveyard_setup`, `interaction_and_protection`, `spirit_and_token_payoffs` |
| Gorma, the Gullet | `counter_persist_support`, `death_payoffs_and_draw`, `fodder_and_recursion`, `interaction`, `sacrifice_outlets` |
| Muddle, the Ever-Changing | `interaction_and_protection`, `nonlegendary_copy_targets`, `spell_velocity`, `spellslinger_payoffs`, `token_and_combat_payoffs` |
| Primo, the Unbounded | `base_power_zero_threats`, `counter_engine`, `evasion_and_finish`, `interaction_and_protection`, `ramp` |
| Scriv, the Obligator | `aura_enchantment_engine`, `draw_and_value`, `interaction_and_protection`, `politics_and_deterrents` |
| Zaffai and the Tempests | `big_spell_payoffs`, `copy_recursion_payoffs`, `interaction_and_protection`, `ramp_and_cost_support`, `selection_and_setup` |

## Evidencia de causa raiz

Checagem publica de cards apos o deploy `e0266cc`:

| Commander | `/cards` status | `total_returned` | `exact_matches` |
| --- | ---: | ---: | ---: |
| Aziza, Mage Tower Captain | 200 | 0 | 0 |
| Berta, Wise Extrapolator | 200 | 0 | 0 |
| Excava, the Risen Past | 200 | 0 | 0 |
| Gorma, the Gullet | 200 | 0 | 0 |
| Muddle, the Ever-Changing | 200 | 0 | 0 |
| Primo, the Unbounded | 200 | 0 | 0 |
| Scriv, the Obligator | 200 | 0 | 0 |
| Zaffai and the Tempests | 200 | 0 | 0 |

O corpo de erro dos probes profile-guided ficou em `Generated deck failed
validation` ou `Generated fallback deck failed validation`. Como o comandante
retornado fica vazio apos validacao, `commander_preserved=false` para todos.

## App/backend contract findings

- O app usa `generated_deck` como fonte de verdade para preview/salvamento.
- Salvar um Commander gerado exige que o comandante seja resolvido para
  `card_id` por rotas de cards/resolucao.
- Como os 8 comandantes nao existem em `/cards`, nao e seguro mascarar a falha
  com stub em `/ai/generate`: isso produziria preview nao persistivel e
  enfraqueceria legalidade/identidade de cor.
- Nao houve drift de contrato app-facing nesta rodada; `API_CONTRACTS_AND_DATA_MAP.md`
  nao precisou de alteracao.

## Legalidade e identidade de cor

- O lote local provou `unresolved_reference_cards=0` e `off_color=0` para cards
  representativos dos packages.
- O runtime publico nao consegue validar legalidade final do deck porque o
  comandante em si nao resolve.
- A regra correta e bloquear/422, nao fabricar comandante sem `card_id`.

## Sentry/logging

- O handler de `/ai/generate` tem captura de excecoes inesperadas com tag de
  rota `ai_generate`.
- Esta rodada retornou 422 de validacao, nao 5xx; nao houve evidencia de queda
  sistemica do processo.
- Ainda ha lacuna operacional: 422 por deck invalido nao expuseram `timings` na
  maior parte dos casos, o que dificulta diagnostico de latencia quando a
  validacao falha antes do fallback.

## Blockers

1. Os 8 comandantes do lote Strixhaven lot 2 nao existem como cards resolviveis
   no backend publico.
2. O deploy novo (`e0266cc`) nao corrigiu o blocker observado em `a137dd5`.
3. Enquanto os cards/legalidades dos comandantes nao forem populados no backend
   publico, `/ai/generate` com `commander_name` exato ativa profile/stats mas
   retorna 422 para todos os comandantes do lote.

## Menores proximos fixes

1. Popular/sincronizar no backend publico os registros de `cards` e legalidade
   Commander dos 8 comandantes do lote, usando fonte oficial/agregada ja usada
   no seed, sem registrar prompts ou decklists completas.
2. Endurecer `server/bin/commander_reference_profile.dart`: `--apply` deve
   validar que o comandante do profile resolve em `cards` no mesmo banco antes
   de considerar o profile runtime-ready.
3. Adicionar teste focado para impedir promocao runtime-ready de profile cujo
   proprio comandante nao resolve.
4. Reexecutar os 14 probes sanitizados apos corrigir dados; criterio de PASS:
   8/8 comandantes com status 200, comandante preservado, `main_quantity=99`,
   `validation.is_valid=true`, profile/stats diagnostics presentes e
   `unresolved_reference_cards=[]`.

## Artifacts sanitizados

- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_runtime_2026-05-11/summary.json`
- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_runtime_2026-05-11/public_card_availability.json`

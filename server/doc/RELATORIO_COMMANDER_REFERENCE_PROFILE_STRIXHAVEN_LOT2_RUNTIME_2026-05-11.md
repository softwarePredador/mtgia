# Commander Reference Profiles Strixhaven Lot 2 — Public Runtime — 2026-05-11

## Resultado

**BLOCKED.** O backend publico recebeu o deploy do lote 2 (`git_sha`
`a137dd5039884dabdb92862ee807322073d1ec40`) e ativou
`reference_profile_used=true` / `reference_card_stats_used=true` para todos os
8 comandantes, mas nenhum probe profile-guided retornou deck Commander valido.

A causa provada e de dados: os 8 comandantes do lote existem em
`commander_reference_profiles`, mas nao existem como cards resolviveis no
backend publico (`GET /cards?name=<commander>&limit=3` retornou
`total_returned=0` e `exact_matches=0` para todos). Sem `card_id` real do
comandante, o backend nao consegue validar legalidade nem entregar payload que o
app consiga salvar com seguranca.

## Escopo e sanitizacao

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Branch/commit local inspecionado: `master` em
  `a137dd5039884dabdb92862ee807322073d1ec40`
  (`docs: add strixhaven commander profile lot2`).
- Nenhum token, JWT, senha, DSN, `DATABASE_URL`, `OPENAI_API_KEY`, prompt
  completo ou decklist completa foi registrado.
- Usuario QA descartavel criado apenas para chamadas autenticadas; somente
  prefixo/dominio sanitizados foram persistidos no artifact.

## Comandos executados

```bash
git fetch origin master --quiet
git pull --ff-only --quiet
git status --short --branch
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
python3 <sanitized public ai/generate probe runner>
python3 <sanitized public /cards availability checker>
git diff --check
git grep -nE "(sk-[A-Za-z0-9_-]{20,}|DATABASE_URL=|SENTRY_DSN=|OPENAI_API_KEY=|Authorization: Bearer|eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+)" -- <changed files>
```

## Deploy observado

| Etapa | Resultado |
| --- | --- |
| `git status` inicial | `master...origin/master`, sem arquivos modificados. |
| Commit local apos sync | `a137dd5039884dabdb92862ee807322073d1ec40`. |
| `/health` inicial | Ainda servia `da2ab3a2aed414b06f1ef57b8f91c5f2c9d96d28`. |
| `/health` final | PASS, `git_sha=a137dd5039884dabdb92862ee807322073d1ec40`, `environment=production`. |

## Probe matrix

Foram executados 14 probes publicos sanitizados:

- 1 probe com `commander_name` exato para cada um dos 8 comandantes.
- 3 amostras para Aziza e 3 para Zaffai como comandantes prioritarios.
- 2 baselines sem `commander_name` para Aziza e Zaffai.

| Grupo | Probes | 200 | 422 | Commander preservado | Main 99 | `validation.is_valid` | Profile/stats diagnostics |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Com `commander_name` | 12 | 0 | 12 | 0 | 0 | 0 | 12/12 com profile e card stats ativos |
| Baseline sem `commander_name` | 2 | 2 | 0 | 0 | 2 | 2 | Sem profile/stats, esperado |

### Resultado por comandante com `commander_name`

| Commander | Status | Main qty | Validacao | Profile | Stats | On-theme candidates | Unresolved refs |
| --- | ---: | ---: | --- | --- | --- | ---: | ---: |
| Aziza, Mage Tower Captain | 422 | 84 / 82 / 78 | invalid | true | true | 46 | 0 |
| Berta, Wise Extrapolator | 422 | 36 | invalid | true | true | 44 | 0 |
| Excava, the Risen Past | 422 | 75 | invalid | true | true | 44 | 0 |
| Gorma, the Gullet | 422 | 72 | invalid | true | true | 44 | 0 |
| Muddle, the Ever-Changing | 422 | 76 | invalid | true | true | 45 | 0 |
| Primo, the Unbounded | 422 | 37 | invalid | true | true | 43 | 0 |
| Scriv, the Obligator | 422 | 75 | invalid | true | true | 39 | 0 |
| Zaffai and the Tempests | 422 | 39 / 40 / 90 | invalid | true | true | 52 | 0 |

## Timing summary

| Grupo | p50 | p95 aprox. | Min | Max |
| --- | ---: | ---: | ---: | ---: |
| Com `commander_name` | 10,215 ms | 15,094 ms | 7,611 ms | 15,916 ms |
| Baseline sem `commander_name` | 11,968 ms | 12,224 ms | 11,712 ms | 12,224 ms |

Os 422 profile-guided nao expuseram `timings` no corpo final porque a resposta
e o caminho de erro `Generated deck failed validation`.

## Evidencia de causa raiz

Um probe debug sanitizado para Aziza retornou:

- `error="Generated deck failed validation"`;
- `validation.errors` incluiu comandante obrigatorio ausente;
- `invalid_cards` incluiu `Aziza, Mage Tower Captain`;
- `reference_profile_used=true`;
- `reference_card_stats_used=true`;
- `on_theme_candidate_count=46`;
- `unresolved_reference_cards=[]`.

Em seguida, a checagem publica de cards confirmou:

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

## App/backend contract findings

- O app envia `commander_name` apenas quando o campo opcional e preenchido e
  usa `generated_deck` como fonte de verdade para salvar.
- Salvar um Commander gerado exige que o comandante seja resolvido para
  `card_id` por `/cards/resolve/batch`.
- Como os 8 comandantes nao existem em `/cards`, nao e seguro mascarar a falha
  com um stub em `/ai/generate`: isso produziria preview nao persistivel e
  enfraqueceria legalidade/identidade de cor.

## Legalidade e identidade de cor

- O runner do lote provou `unresolved_reference_cards=0` e `off_color=0` para
  cards representativos dos packages.
- O runtime publico nao conseguiu chegar a validacao de legalidade do deck final
  porque o comandante em si nao resolve.
- `off_identity` aproximado para os probes profile-guided fica **not proven**:
  a falha ocorre antes de um deck Commander valido existir.

## Sentry/logging

- O handler de `/ai/generate` tem captura de excecoes com tag
  `route=ai_generate` para erros inesperados.
- Esta rodada retornou 422 de validacao, nao 5xx; nao houve evidencia de queda
  sistemica do processo.
- O corpo de erro e seguro do ponto de vista de segredo, mas a ausencia de
  `timings` no 422 dificulta diagnostico operacional de latencia em falhas de
  validacao.

## Blockers

1. Os 8 comandantes do lote Strixhaven lot 2 nao existem como cards resolviveis
   no backend publico.
2. O apply dos profiles provou packages/stats, mas nao bloqueou a promocao
   quando o proprio comandante nao estava resolvivel em `cards`.
3. Enquanto isso nao for corrigido, `/ai/generate` com `commander_name` exato
   ativa profile/stats mas retorna 422 para todos os comandantes do lote.

## Menores proximos fixes

1. Popular/sincronizar no backend publico os registros de `cards` e legalidade
   Commander dos 8 comandantes do lote, usando a fonte oficial/agregada ja
   usada no seed, sem registrar prompts ou decklists completas.
2. Endurecer `server/bin/commander_reference_profile.dart`: `--apply` deve
   validar que o comandante do profile resolve em `cards` no mesmo banco antes
   de considerar o profile runtime-ready.
3. Adicionar teste focado para impedir `reference_profile_used=true` com
   comandante irresolvivel quando o contrato esperado e preview/app save-ready.
4. Reexecutar os 14 probes sanitizados apos corrigir dados; criterio de PASS:
   8/8 comandantes com status 200, comandante preservado, `main_quantity=99`,
   `validation.is_valid=true`, profile/stats diagnostics presentes e
   `unresolved_reference_cards=[]`.

## Artifacts sanitizados

- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_runtime_2026-05-11/summary.json`
- `server/test/artifacts/commander_reference_profile_strixhaven_lot2_runtime_2026-05-11/public_card_availability.json`

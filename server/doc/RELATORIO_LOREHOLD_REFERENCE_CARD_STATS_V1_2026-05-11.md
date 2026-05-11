# Lorehold Reference Card Stats v1

Data: 2026-05-11

Resultado: **PASS WITH RISKS**

## Escopo

- Evoluir o piloto `Lorehold, the Historian` de Reference Profile v1 para
  Reference Card Stats v1.
- Transformar `expected_packages` em dados normalizados, pontuaveis,
  persistidos e verificaveis por `/ai/generate`.
- Manter compatibilidade para requests sem `commander_name` e para outros
  comandantes.
- Fora de escopo: Scanner/camera/OCR/MLKit, scraping pesado e exposicao de
  secrets/JWT/tokens/DSN/DATABASE_URL/emails reais/payload sensivel.

## Commits inspecionados

| Item | Commit |
| --- | --- |
| Base sincronizada em `master` | `04c4fbd Wire Lorehold commander generate profile in app` |
| Backend publico sanity `/health` | `87d9b7c3814ea07c3e89d718976fb694efd57d1d` |

## Antes / depois

| Area | Antes | Depois Reference Card Stats v1 |
| --- | --- | --- |
| Packages Lorehold | Listas textuais em `profile_json.expected_packages` | Linhas em `commander_reference_card_stats` por carta/pacote |
| Resolucao de cartas | Nao verificavel por carta no runner | Resolucao contra `cards`, incluindo aliases split/DFC |
| Pontuacao | Nao havia score por carta | `score`, `role`, `confidence`, `confidence_rank`, `source`, `evidence_count` |
| Unresolved | Nao persistido separadamente | Mesmo registro com `unresolved=true` e `card_id=NULL`, sem quebrar apply |
| `/ai/generate` | Prompt com profile agregado | Profile + candidate pool estruturado quando stats existem |
| Diagnostics | `reference_profile_used`, `profile_confidence`, `themes`, `source_count` | Campos anteriores + `reference_card_stats_used`, `on_theme_candidate_count`, `unresolved_reference_cards`, `package_keys`, `reference_deck_evaluation` |
| Fallback | Profile-only/legacy | Mantido se stats estiver vazio/ausente |

## Persistencia

Tabela nova/adaptada:

`commander_reference_card_stats`

Campos principais:

| Campo | Uso |
| --- | --- |
| `commander_name`, `commander_name_normalized` | Escopo Lorehold e chave normalizada |
| `card_name`, `card_name_normalized` | Nome exibivel e chave de dedupe |
| `card_id` | UUID resolvido em `cards`, nullable para unresolved |
| `package_key` | Origem dentro de `expected_packages` |
| `role` | Role normalizada para guidance/evaluation |
| `score` | Prioridade relativa do pacote/carta |
| `confidence`, `confidence_rank` | Filtro seguro sem ordenar strings lexicograficamente |
| `source`, `evidence_count` | Fonte agregada e quantidade de evidencias do profile |
| `unresolved`, `updated_at` | Re-resolucao idempotente e auditoria |

Chave primaria:

`(commander_name_normalized, card_name_normalized, package_key)`

## Cobertura por pacote

Evidencia do apply local sanitizado:

| Pacote | Resolvidas | Unresolved |
| --- | ---: | ---: |
| `topdeck_and_miracle_setup` | 7 | 0 |
| `miracle_payoffs_expensive_spells` | 12 | 0 |
| `interaction_and_resets` | 6 | 0 |
| `spell_payoff_copy_package` | 9 | 0 |
| **Total** | **34** | **0** |

`commander_reference_card_stats` ficou com `loaded_usable_after_run=34` e cache
version `reference_card_stats_v1:8bbfb843a0b4`. Reexecutar `--apply` manteve os
mesmos totais, provando idempotencia.

## Contrato `/ai/generate`

Ativacao:

```json
{
  "prompt": "Boros miracle big spells with topdeck setup and interaction",
  "format": "Commander",
  "commander_name": "Lorehold, the Historian"
}
```

Regras:

- `commander_name` ausente: caminho legado preservado.
- Outro comandante: caminho legado preservado.
- Lorehold com profile `confidence >= medium`: profile ativo.
- Lorehold com card stats `confidence_rank >= medium` e `unresolved=false`:
  candidate pool estruturado ativo.
- Tabela stats ausente/vazia: fallback profile-only/legacy, sem enfraquecer
  legalidade, identidade de cor, tamanho final ou validacao.

Diagnostics opcionais quando Lorehold ativa:

```json
{
  "diagnostics": {
    "reference_profile_used": true,
    "reference_card_stats_used": true,
    "on_theme_candidate_count": 34,
    "unresolved_reference_cards": [],
    "package_keys": [
      "interaction_and_resets",
      "miracle_payoffs_expensive_spells",
      "spell_payoff_copy_package",
      "topdeck_and_miracle_setup"
    ],
    "reference_deck_evaluation": {
      "classification": "on_theme",
      "counts": {
        "on_theme": 0,
        "generic": 0,
        "questionable": 0,
        "off_theme": 0
      }
    }
  }
}
```

Os numeros em `reference_deck_evaluation.counts` variam conforme o deck gerado.
O app deve tratar todos os campos de diagnostics como opcionais e continuar
usando `generated_deck`/`validation` como fonte de verdade.

## Avaliador tematico

Foi adicionado avaliador backend para classificar cartas geradas como:

| Classe | Regra v1 |
| --- | --- |
| `on_theme` | Carta aparece em `commander_reference_card_stats` resolvido |
| `generic` | Terreno R/W/colorless, ramp/rock, draw/rummage, remocao ou suporte generico Lorehold |
| `questionable` | Carta legal/sem cor fora do pool e sem role generica detectada |
| `off_theme` | Exemplos de `avoid_patterns`, basics U/B/G ou identidade fora de R/W |

O avaliador e explicativo. A legalidade real continua em
`GeneratedDeckValidationService` e `DeckRulesService`.

## Comandos executados

| Comando | Resultado |
| --- | --- |
| `git status --short`, `git branch --show-current`, `git log -1 --oneline` | PASS, `master`, worktree inicial limpo |
| `git fetch origin master && git pull --ff-only origin master` | PASS, ja atualizado |
| `dart analyze lib/ai routes/ai bin test` | PASS |
| `dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart` | PASS |
| `dart run bin/commander_reference_profile_lorehold.dart --dry-run` | PASS WITH RISKS, sem mutacao |
| `dart run bin/commander_reference_profile_lorehold.dart --apply` | PASS, stats persistidos |
| `dart run bin/commander_reference_profile_lorehold.dart --apply` repetido | PASS, idempotente |
| `RUN_LOREHOLD_REFERENCE_PROFILE_LIVE=1 LIVE_REFERENCE_CARD_STATS=1 TEST_API_BASE_URL=http://127.0.0.1:18086 dart test test/commander_reference_profile_generate_live_test.dart --reporter expanded` | PASS |
| `dart test test/ai_optimize_flow_test.dart ...` sem backend local | FAIL ambiental: `127.0.0.1:8082` recusou conexao |
| Backend local `PORT=8082` + `dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart` | PASS |
| `flutter analyze lib/features/decks test/features/decks --no-version-check` | PASS |
| `flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check` | PASS |
| Backend local `PORT=8080` + `dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS, 19 candidatos seriam validados; sem auth/deck/optimize/bulk save/validate |
| `curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health` | PASS, sanity publico |

## Limites e riscos

- **PASS WITH RISKS** porque o backend publico ainda reporta commit anterior a
  esta entrega; a prova publica de `reference_card_stats_used=true` depende de
  deploy.
- Reference Card Stats v1 e Lorehold-only. Outros comandantes continuam sem
  stats dedicados por design.
- `interaction_and_resets` permanece role agregada v1; uma futura v2 pode dividir
  carta a carta entre spot interaction e wipes usando oracle text.
- O avaliador e tematico/explicativo, nao substitui validacao de legalidade.
- OpenAI pode nao escolher todos os candidatos; o prompt orienta "nao forcar
  todas as cartas" para preservar qualidade, curva, budget/bracket e legalidade.

## Menores proximos ajustes

1. Publicar o backend e repetir a prova publica de `/ai/generate` com
   `LIVE_REFERENCE_CARD_STATS=1`.
2. Adicionar profiles/card stats para outros comandantes apenas com evidencia
   agregada e sem copiar decklists publicas.
3. Refinar roles por oracle text para separar `interaction_and_resets` em spot
   removal e board wipes quando isso trouxer ganho de geracao/diagnostico.

# Commander Reference Pipeline Generalization - 2026-05-11

## Resultado

**PASS WITH RISKS**

O piloto Lorehold deixou de ser o unico caminho possivel do pipeline. O backend
agora tem uma camada generica para receber perfis de outros comandantes por JSON,
persistir `commander_reference_profiles`, resolver e salvar
`commander_reference_card_stats`, e permitir que `/ai/generate` use qualquer
perfil persistido com `confidence >= medium`.

Lorehold segue como fixture/regressao principal e continua protegido por testes.

## O que mudou

- Novo runner generico:
  - `server/bin/commander_reference_profile.dart`
  - aceita `--profile-json=<path>`
  - roda `--dry-run` por padrao ou `--apply`
  - gera artifact sanitizado com cobertura, resolucao de cartas e status de
    mutacao.
- `commander_reference_profile_support.dart`
  - adicionou builder generico de profile;
  - `loadUsableCommanderReferenceProfile` deixou de ser hardcoded em Lorehold;
  - prompt de profile usa comandante e identidade de cor do profile persistido.
- `commander_reference_card_stats_support.dart`
  - adicionou flatten/resolution generico de card stats;
  - `loadUsableCommanderReferenceCardStats` deixou de ser hardcoded em Lorehold;
  - evaluator passa a respeitar identidade de cor do profile em vez de assumir
    sempre `R/W`.
- `/ai/generate`
  - carrega qualquer commander profile persistido para o `commander_name`
    recebido;
  - preserva fallback legado quando nao ha profile, stats ou confidence
    suficiente;
  - mantem Lorehold como regressao e fallback deterministico enriquecido.

## Formato de entrada para proximos comandantes

O proximo comandante deve chegar como JSON neste formato minimo:

```json
{
  "commander": "Nome do Comandante",
  "version": "nome_do_comandante_reference_profile_v1_2026-05-11",
  "source": "aggregate_reference_profile_v1",
  "confidence": "medium",
  "source_count": 1,
  "color_identity": ["G"],
  "themes": [
    {
      "name": "theme_key",
      "confidence": "medium",
      "notes": "Resumo curto da estrategia."
    }
  ],
  "role_targets": {
    "lands": {"min": 36, "max": 38}
  },
  "expected_packages": {
    "package_key": ["Card Name"]
  },
  "avoid_patterns": [
    {
      "pattern": "off_color",
      "examples": ["Card Name"],
      "reason": "Motivo."
    }
  ],
  "source_limit_notes": [
    "Aggregate/manual reference only; no copied public decklist."
  ]
}
```

## Comando para dry-run

```bash
cd server
dart run bin/commander_reference_profile.dart --profile-json=/absolute/path/profile.json --dry-run
```

## Comando para apply

```bash
cd server
dart run bin/commander_reference_profile.dart --profile-json=/absolute/path/profile.json --apply
```

## Validacao executada

| Comando | Resultado |
|---|---|
| `dart analyze lib/ai/commander_reference_profile_support.dart lib/ai/commander_reference_card_stats_support.dart routes/ai/generate/index.dart bin/commander_reference_profile.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart` | PASS |
| `dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded` | PASS, `+20` |
| `dart run bin/commander_reference_profile.dart --profile-json=<tmp> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_generalized_2026-05-11` | PASS WITH RISKS, sem mutacao |

Dry-run sintetico:

- comandante: `Test Commander`
- cartas resolvidas: `2/2`
- unresolved: `0`
- `db_mutations=false`
- artifact:
  `server/test/artifacts/commander_reference_profile_generalized_2026-05-11/test_commander_dry_run_summary.json`

## Riscos

- O piloto real de qualidade continua sendo Lorehold. O runner generico foi
  validado com profile sintetico para provar formato e resolucao, nao qualidade
  estrategica.
- Cada novo comandante ainda precisa de curadoria de profile antes do apply.
- O app so aproveita o profile quando enviar `commander_name` preenchido.
- Scanner/camera/OCR/MLKit seguem fora do escopo.

## Quando passar a lista

Pode passar a lista depois desta entrega quando cada item tiver pelo menos:

- nome exato do comandante;
- identidade de cor;
- 3 a 6 temas principais;
- pacotes esperados com cartas;
- cartas/padroes a evitar;
- fonte ou observacao de origem.

Se voce passar so nomes de comandantes, a proxima sprint deve primeiro criar os
profiles via pesquisa/curadoria antes de rodar `--apply`.

# Hermes Docs Triage — 2026-06-11

> Status: triagem curada dos commits de docs em
> `origin/codex/hermes-analysis-docs`.
> Base revalidada: `master@792007e7`.
> Objetivo: separar achados reais de claims stale antes de abrir tarefa ou
> alterar código.

## Commits triados

| Commit | Título | Branch | Arquivos |
|---|---|---|---|
| `13a10128` | `docs: audit card semantics 2026-06-11` | `codex/hermes-analysis-docs` | `PLANO_CORRECAO.md`, `STRUCTURE_AUDIT.md`, `TECHNICAL_MAP.md` |
| `372cdfca` | `docs: audit estrutura functions-not-called 2026-06-11` | `codex/hermes-analysis-docs` | `PLANO_CORRECAO.md`, `STRUCTURE_AUDIT.md`, `TECHNICAL_MAP.md` |
| `76ec897f` | `docs: audit estrutura broken-imports-and-circular-dependencies 2026-06-11` | `codex/hermes-analysis-docs` | `PLANO_CORRECAO.md`, `STRUCTURE_AUDIT.md`, `TECHNICAL_MAP.md` |

## Decisão de merge

Não fazer merge bruto desses três docs na `master`.

Motivo: os relatórios foram gerados em checkouts anteriores ao estado atual da
`master` e carregam números/claims já parcialmente superados. Eles são úteis
como entrada de triagem, não como fonte canônica sem revalidação.

## Achados revalidados como reais

### P1 — `swap_integrity` é emitido, mas `verifySwapIntegrity` não é chamado

Evidência atual:

- `server/routes/ai/optimize/index.dart` anexa `swap_integrity`.
- `server/lib/ai/optimize_swap_integrity.dart` define `verifySwapIntegrity`.
- Busca em `server`/`app` encontrou somente a definição de
  `verifySwapIntegrity`, sem chamada runtime.

Impacto:

- O backend calcula assinatura de swaps, mas ainda não prova rejeição de apply
  contra deck antigo ou payload adulterado.

Próxima ação:

- Identificar o caminho real de aplicação de sugestões e chamar
  `verifySwapIntegrity` antes de mutar cartas, ou remover o verificador se o
  campo for apenas diagnóstico.

Validação mínima:

- Teste com hash errado.
- Teste com `deck_signature` antigo.
- Teste com assinatura correta preservando fluxo atual.

### P1/P2 — ciclo real no Life Counter tabletop/turn tracker

Evidência atual:

- `app/lib/features/home/life_counter/life_counter_tabletop_engine.dart`
  importa `life_counter_turn_tracker_engine.dart`.
- `app/lib/features/home/life_counter/life_counter_turn_tracker_engine.dart`
  importa `life_counter_tabletop_engine.dart`.

Impacto:

- Regra de mesa e regra de turno ficam acopladas em ciclo, dificultando teste
  isolado e evolução de overlays/settings.

Próxima ação:

- Extrair helper neutro para detecção de jogadores ativos/sanitização de ponteiros
  ou inverter uma das dependências.

Validação mínima:

- Analyzer app.
- Testes de engines do Life Counter, se existentes.
- Prova viva visual apenas se houver mudança de UI.

### P2 — `optimize_response_support.dart` tem builders sem chamada runtime clara

Evidência atual:

- `server/lib/ai/optimize_response_support.dart` define
  `buildOptimizeResponse` e top-level `respondWithOptimizeTelemetry`.
- `server/routes/ai/optimize/index.dart` define função local com o mesmo nome
  `respondWithOptimizeTelemetry` e as chamadas resolvem localmente.

Impacto:

- A extração existe parcialmente, mas a rota ainda carrega builder local; isso
  confunde próximos splits e documentação.

Próxima ação:

- Substituir a função local pela versão do support, ou remover os builders mortos
  se a versão local for a fonte correta.

Validação mínima:

- `dart analyze` em rota/support/testes de optimize.
- Testes de contrato do optimize que cubram telemetry/timings/diagnostics.

## Achados parcialmente stale

### `sync_cards_utils.dart`

Status atual:

- Não é mais totalmente test-only.
- `server/bin/sync_cards.dart` importa `sync_cards_utils.dart`.
- `parseSinceDays` e `getNewSetCodesSinceFromData` já são usados pelo CLI.

Ainda vale revisar:

- `extractCardRow`, `extractSetCardRow`, `extractOracleIds` e
  `extractLegalities` continuam sem chamada runtime confirmada na busca atual,
  apesar de terem testes.

Próxima ação:

- Rodada separada do pipeline MTGJSON: decidir se o CLI deve usar esses helpers
  restantes ou se os testes/harnesses devem ser marcados como legado.

## Achados stale ou já mitigados

| Claim do relatório Hermes | Status em `master@792007e7` |
|---|---|
| `sync_cards_utils.dart` totalmente test-only | Stale: CLI importa e usa parte do utilitário |
| ciclo `optimize_runtime_support.dart` ↔ `optimize_filler_loader_support.dart` | Stale na busca atual: filler loader não importa mais runtime |
| `optimize_runtime_support.dart` com ~4197 linhas | Stale: arquivo atual tem 551 linhas |
| `server/routes/ai/optimize/index.dart` com ~3497 linhas | Stale: arquivo atual tem 2321 linhas |
| imports quebrados massivos | Stale/mitigado: auditor atual reportou `Imports quebrados: 0` |

## Ferramenta Hermes corrigida nesta triagem

`docs/hermes-analysis/scripts/structure_auditor.py` ainda escrevia em
`STRUCTURE_AUDIT.md` por padrão. Quando o arquivo não tinha o marcador esperado,
o script substituía o histórico manual inteiro pelo relatório gerado.

Correção aplicada:

- `merge_generated_report_with_manual_history(...)` agora preserva o histórico
  manual sob `## Historico manual preservado` quando o marcador antigo não
  existir.

Validação:

- `python3 -m py_compile docs/hermes-analysis/scripts/structure_auditor.py`.

## Ordem recomendada

1. Tratar `swap_integrity` porque é segurança/consistência de apply.
2. Resolver ou documentar o ciclo do Life Counter antes de novos overlays.
3. Limpar `optimize_response_support.dart` para manter rota de optimize como
   orquestração fina.
4. Fazer rodada separada de `sync_cards_utils.dart` no pipeline MTGJSON.
5. Não migrar os docs brutos de `codex/hermes-analysis-docs` para `master` sem
   revalidação por arquivo/linha.

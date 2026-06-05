# Hermes Cron Findings Triage - 2026-06-05

## Contexto

Entrada analisada: retorno das crons Hermes com quatro blocos principais:

- Flutter UI Audit: 193 findings P2 cosmeticos/acessibilidade.
- Commander Deep Report - Lorehold: tendencias de cartas e crises de pipeline.
- Mana Base Validation: decks completos e seeds parciais misturados na leitura.
- Gamechanger Research: lacunas de classificacao EDH bracket/gamechanger.

## Decisao de prioridade

1. Gamechanger/bracket data bugs: acao imediata, pois afetam IA, filtros e scorecards.
2. Seeds parciais como decks: acao imediata no export/sync Hermes para evitar payload final invalido.
3. Flutter UI Audit P2: backlog real, nao bloqueante, deve ser tratado em lotes por tela com prova viva.
4. Commander Deep Report Lorehold: manter como sinal de aprendizado, sem corte automatico sem validacao de deck completo.

## Correcoes aplicadas

- `server/lib/edh_bracket_policy.dart`
  - Land-search/ramp nao consome mais categoria `tutor`.
  - `Fierce Guardianship` e demais free interaction curadas sao detectadas por nome mesmo com `oracle_text` ausente/desatualizado.
  - `Gaea's Cradle`, `Serra's Sanctum` e `Mishra's Workshop` foram adicionadas como fast mana lands.
  - Casos `Field of the Dead` e `Underworld Breach` ficam protegidos contra falso positivo de bracket por padrao.
  - `Tergrid, God of Fright` segue detectada por lista curada mesmo sem oracle text.

- `server/bin/export_hermes_learned_deck.py`
  - Export Hermes agora falha cedo quando o learned deck nao e Commander 100 cartas, 1 comandante e 99 main.
  - Override so por `HERMES_EXPORT_ALLOW_INCOMPLETE=1`, para analise manual fora do sync normal.

- `server/test/edh_bracket_policy_test.dart`
  - Nova cobertura para os casos de regressao citados pelo Hermes.

## Pendencias mantidas

- Flutter UI Audit P2:
  - 80 cores hardcoded.
  - 58 widgets interativos sem `Semantics`.
  - 51 touch targets menores que 48px.
  - 1 `NetworkImage` sem cache.
  - Tratar em lote separado por tela, com screenshots antes/depois no iPhone Simulator.

- Mana base / seeds:
  - O auto-promote ja exige Commander 100/99+1.
  - Se o validator continuar reportando seeds parciais como decks, ajustar o prompt/script da cron para classificar `card_count < 90` como seed/incomplete, nao como deck real.

- Lorehold trends:
  - `Esper Sentinel`, `Grand Abolisher` e `Call Forth the Tempest` devem virar candidatos de revisao, nao corte automatico.
  - Cortes precisam passar por scorecard de deck completo e validacao commander_legal.

## Validacoes executadas

```bash
cd server
dart format lib/edh_bracket_policy.dart test/edh_bracket_policy_test.dart
python3 -m py_compile bin/export_hermes_learned_deck.py
dart analyze lib/edh_bracket_policy.dart test/edh_bracket_policy_test.dart
dart test test/edh_bracket_policy_test.dart test/optimize_runtime_support_test.dart -r expanded
dart test test/commander_learned_deck_support_test.dart -r expanded
dart analyze lib bin test
```

Resultado: PASS.

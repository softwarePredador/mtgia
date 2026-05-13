# Commander Reference Readiness Scorecard — 2026-05-13

## Verdict

**PASS** para a Sprint 1 do plano Commander AI Optimization Strategy.

Foi criado um scorecard read-only para decidir se um comandante pode entrar em
mini-batch de expansão do fluxo Commander Reference. O objetivo é impedir
rollout por tentativa e erro.

## O que foi entregue

- Novo suporte: `server/lib/ai/commander_reference_readiness_support.dart`.
- Novo runner read-only:
  `server/bin/commander_reference_readiness_scorecard.dart`.
- Novo teste:
  `server/test/commander_reference_readiness_support_test.dart`.
- Artifact sanitizado:
  `server/test/artifacts/commander_reference_readiness_2026-05-13/readiness_scorecard_summary.json`.

Nenhuma rota app-facing mudou e nenhuma mutação de banco foi feita pelo runner.

## Scorecard

O score considera:

- resolução da carta do comandante;
- profile disponível e confidence utilizável;
- source/theme/package coverage do profile;
- card stats resolvidos e sem unresolved;
- corpus disponível;
- quantidade de decks aceitos no corpus;
- força do `core_package`;
- fallback determinístico válido;
- main com 99 cartas;
- prova pública sanitizada quando fornecida.

Status possíveis:

- `ready_for_mini_batch`;
- `profile_ready_needs_proof`;
- `needs_data`;
- `blocked`.

## Resultado Lorehold

Com artifact público v5:

- commander: `Lorehold, the Historian`;
- score: `100`;
- status: `ready_for_mini_batch`;
- blockers: `[]`;
- warnings: `[]`;
- commander card resolved: `true`;
- profile confidence: `high`;
- card stats: `34`;
- unresolved stats: `0`;
- corpus accepted decks: `3`;
- core package: `26`;
- deterministic fallback valid: `true`;
- deterministic main quantity: `99`;
- public runtime gate: `true`.

## Comandos executados

```bash
cd server && dart format lib/ai/commander_reference_readiness_support.dart bin/commander_reference_readiness_scorecard.dart test/commander_reference_readiness_support_test.dart
cd server && dart analyze lib/ai/commander_reference_readiness_support.dart bin/commander_reference_readiness_scorecard.dart test/commander_reference_readiness_support_test.dart
cd server && dart test test/commander_reference_readiness_support_test.dart -r expanded
cd server && dart run bin/commander_reference_readiness_scorecard.dart --commander="Lorehold, the Historian" --runtime-summary=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json --artifact-dir=test/artifacts/commander_reference_readiness_2026-05-13
```

## Como usar daqui em diante

Antes de aplicar corpus/profile determinístico para um novo comandante:

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commander="Nome do Comandante" \
  --runtime-summary=test/artifacts/<artifact-publico>/summary.json \
  --artifact-dir=test/artifacts/commander_reference_readiness_<data>
```

Se o status não for `ready_for_mini_batch`, a expansão fica bloqueada ou
limitada a profile/card-stats sem caminho determinístico forte.

## Próximo passo recomendado

Rodar o scorecard para o próximo mini-batch candidato antes de implementar
qualquer expansão:

- `Dina, Soul Steeper`;
- `Zimone, Quandrix Prodigy`;
- `Prosper, Tome-Bound`;
- `Aesi, Tyrant of Gyre Strait`;
- `Edgar Markov`.

O batch só deve avançar para execução pública depois que cada comandante tiver
scorecard sem blockers e plano claro para o que falta.

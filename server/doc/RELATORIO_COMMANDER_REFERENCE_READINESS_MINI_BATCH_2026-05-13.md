# Commander Reference Readiness Mini-Batch - 2026-05-13

## Verdict

**PASS WITH RISKS / NO PROMOTION.**

O scorecard foi executado para o primeiro mini-batch candidato depois do
fechamento de Lorehold. Nenhum comandante foi promovido para expansao forte ou
caminho deterministico forte nesta rodada.

## Command

```bash
cd server
dart run bin/commander_reference_readiness_scorecard.dart \
  --commanders="Dina, Essence Brewer;Zimone, Infinite Analyst;Prosper, Tome-Bound;Aesi, Tyrant of Gyre Strait;Edgar Markov" \
  --artifact-dir=test/artifacts/commander_reference_readiness_mini_batch_corrected_2026-05-13
```

## Result

| Commander | Score | Status | Expansion ready | Blockers | Warnings |
| --- | ---: | --- | --- | --- | --- |
| Aesi, Tyrant of Gyre Strait | 78 | `profile_ready_needs_proof` | false | none | `core_package_weak`, `corpus_missing`, `public_runtime_proof_missing` |
| Dina, Essence Brewer | 78 | `profile_ready_needs_proof` | false | none | `core_package_weak`, `corpus_missing`, `public_runtime_proof_missing` |
| Edgar Markov | 78 | `profile_ready_needs_proof` | false | none | `core_package_weak`, `corpus_missing`, `public_runtime_proof_missing` |
| Prosper, Tome-Bound | 78 | `profile_ready_needs_proof` | false | none | `core_package_weak`, `corpus_missing`, `public_runtime_proof_missing` |
| Zimone, Infinite Analyst | 78 | `profile_ready_needs_proof` | false | none | `core_package_weak`, `corpus_missing`, `public_runtime_proof_missing` |

Artifact:
`server/test/artifacts/commander_reference_readiness_mini_batch_corrected_2026-05-13/readiness_scorecard_summary.json`

## Interpretation

Os cinco candidatos possuem base suficiente para trabalho de preparacao
controlada: comandante resolvido, profile/card stats utilizaveis e deck
deterministico validavel. Ainda nao possuem os tres requisitos que liberaram
Lorehold:

- corpus aceito com evidencia suficiente;
- pacote core forte;
- prova publica repetida sem fallback/timeout/off-color.

Isso confirma que o scorecard esta cumprindo a funcao esperada: ele nao deixa a
expansao virar rollout amplo antes de corpus e prova publica.

## Correction During Execution

A primeira tentativa usou nomes antigos para Dina/Zimone:

- `Dina, Soul Steeper`
- `Zimone, Quandrix Prodigy`

Esses nomes nao correspondem aos profiles Secrets of Strixhaven aplicados. A
rodada corrigida usou:

- `Dina, Essence Brewer`
- `Zimone, Infinite Analyst`

Os artifacts da tentativa incorreta nao foram versionados.

## Next Step

Escolher um unico comandante do mini-batch para repetir o fluxo Lorehold em
menor escala:

1. montar corpus aceito com 3 a 5 decks;
2. extrair roles/core/theme/support;
3. rodar scorecard;
4. se `ready_for_mini_batch`, executar prova publica 5/5;
5. so entao liberar deterministic/reference-guided path para esse comandante.

Recomendacao pragmatica: comecar por `Prosper, Tome-Bound` ou `Aesi, Tyrant of
Gyre Strait`, porque ambos tendem a ter packages mais claros e corpus publico
mais abundante que alguns comandantes Strixhaven custom.

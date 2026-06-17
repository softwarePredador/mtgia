# Lorehold Generator Source Mix Audit — 2026-06-17

## Objetivo

Transformar o diagnóstico manual do `commander_generate_provenance_live5` em
um relatório canônico e repetível, para responder:

- quais cartas ainda tocam `deterministic_fallback`;
- quais delas continuam pouco corroboradas;
- quais buckets são realmente prioridade de melhoria do generator;
- quais números antigos (`fallback_only=2`, `Mind Stone`, etc.) já ficaram
  obsoletos.

## Fonte usada

- Artefato de entrada:
  [commander_generate_provenance_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/commander_generate_provenance_2026-06-17_live5/commander_generate_provenance_summary.json)
- Auditor novo:
  [audit_commander_generator_source_mix.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/audit_commander_generator_source_mix.py)
- Artefato de saída:
  [lorehold_generator_source_mix_2026-06-17.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generator_source_mix_2026-06-17.json)

## Comandos executados

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/audit_commander_generator_source_mix.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_commander_generator_source_mix.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_commander_generator_source_mix.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/audit_commander_generator_source_mix.py \
  --summary server/test/artifacts/commander_generate_provenance_2026-06-17_live5/commander_generate_provenance_summary.json \
  --output docs/hermes-analysis/master_optimizer_reports/lorehold_generator_source_mix_2026-06-17.json
```

## Resultado factual

- `fallback_touched_count = 42`
- `fallback_only_count = 0`
- `all_fallback_have_non_fallback_source = true`
- `learned_plus_fallback_only_count = 2`
- `fallback_without_profile_or_stats_count = 9`
- `fallback_profile_stats_only_count = 18`
- `fallback_profile_stats_no_empirical_support_count = 18`

Leitura correta:

- o problema atual do Lorehold **não** é mais "cartas que só existem por
  fallback puro";
- o problema real virou "cartas ainda tocadas por fallback, mas com níveis
  muito diferentes de corroboracão";
- isso é melhor que antes, mas ainda impede chamar o deck de
  `fully source-backed`.

## Buckets úteis

### P1 — learned + fallback only

Cartas:

- `Fellwar Stone`
- `Lightning Greaves`

Leitura:

- essas cartas aparecem com suporte de `active_learned_deck`, mas ainda sem
  `reference_corpus_packages`, `usage_hot_cards`, `profile_expected_packages`
  ou `reference_card_stats`;
- não são bug por si só, mas ainda não têm triangulação suficiente.

Ação correta:

- verificar se devem entrar por `usage_hot_cards`, `reference_corpus_packages`
  ou profile/stats;
- se não houver evidência real, manter como fallback explícito e documentado.

### P1 — fallback sem profile/stats

Cartas:

- `Arcane Signet`
- `Boros Charm`
- `Boros Signet`
- `Esper Sentinel`
- `Faithless Looting`
- `Fellwar Stone`
- `Generous Gift`
- `Lightning Greaves`
- `Sol Ring`

Leitura:

- essas cartas ainda tocam `deterministic_fallback`, mas o profile canônico e o
  bloco de `reference_card_stats` não explicam sua presença;
- algumas têm learned/usage, outras não.

Ação correta:

- revisar por que profile/stats ainda não absorveram staples e interaction
  óbvias do pacote Lorehold;
- priorizar backfill de profile/stats antes de mexer no fallback em si.

### P2 — fallback + profile/stats, mas sem learned/corpus/usage

Cartas:

- `Apex of Power`
- `Arcane Bombardment`
- `Austere Command`
- `Bonfire of the Damned`
- `Brainstone`
- `Brass's Bounty`
- `Chandra, Hope's Beacon`
- `Creative Technique`
- `Double Vision`
- `Monastery Mentor`
- `Primal Amulet // Primal Wellspring`
- `Pyromancer's Goggles`
- `Soulfire Eruption`
- `Sunbird's Invocation`
- `Temple Bell`
- `Terminus`
- `Volcanic Vision`
- `Young Pyromancer`

Leitura:

- aqui o profile/stats já justificam parcialmente a carta;
- o que falta é suporte empírico via corpus, usage ou learned deck;
- isso é um risco menor do que staples básicos sem profile/stats, mas ainda é
  dependência auxiliar de fallback.

Ação correta:

- revisar esse bloco por pacote temático:
  - big-spell payoff
  - spell-copy engine
  - draw/filter artifacts
  - wipe/closers
- promover só quando corpus/usage realmente sustentarem o slot.

## O que ficou obsoleto

Esta rodada invalida leituras antigas como:

- `fallback_only residual = 2`
- `Mind Stone` ainda como fallback-only
- "resta só curar o bucket `fallback_only`"

Estado correto agora:

- `fallback_only = 0`
- `Mind Stone` não está mais no bucket residual crítico
- o problema passou a ser **fallback auxiliar por bucket de evidência**, não
  fallback puro.

## Conclusão operacional

O próximo slice do generator não deve tentar "remover o fallback do Lorehold"
de uma vez.

Ele deve atacar, nesta ordem:

1. staples/interaction tocadas por fallback sem profile/stats;
2. slots `learned + fallback` ainda sem corroboracão adicional;
3. pacotes temáticos que seguem em `fallback + profile/stats` sem evidência
   empírica.

Pergunta certa daqui para frente:

- "por que esta carta ainda precisa tocar fallback se já temos profile/stats,
  learned, corpus e usage?"

Pergunta errada:

- "como zerar `deterministic_fallback` imediatamente?"

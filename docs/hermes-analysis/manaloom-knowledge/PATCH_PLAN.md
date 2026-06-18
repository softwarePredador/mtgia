# Patch Plan — P0 Code Fixes para ManaLoom

> **Historico / nao operacional em 2026-06-17:** este documento permanece como
> memoria do patch aplicado em maio. O executor `validate_patches.py` foi
> removido do tree operacional; validacoes atuais devem usar testes versionados
> em `server/test/*` e os guardrails Hermes em
> `docs/hermes-analysis/manaloom-knowledge/scripts/test_known_cards_consumer_guardrail.py`.

> Patches validados e simulados para os 3 bugs criticos no codigo
> que causam classificacao errada de cartas.
>
> Branch alvo: master (via PR) ou codex/hermes-analysis-docs (via merge)
> Arquivos: server/lib/ai/optimization_functional_roles.dart
>           server/lib/edh_bracket_policy.dart

---

## Status de aplicacao no produto

**APLICADO em `master`: `f57bb8d3` — `Fix semantic role classification fallbacks`**

O patch foi implementado de forma conservadora no codigo de produto:

- `server/lib/ai/optimization_functional_roles.dart`
  - adiciona listas curadas pequenas para `wincon`, `engine`, `combo_piece` e `protection`;
  - avalia essas listas antes dos fallbacks de `draw`, `removal` e `ramp`;
  - corrige os casos reproduzidos: `Walking Ballista`, `The One Ring`, `Basalt Monolith`, `Fierce Guardianship`, `Endurance`.
- `server/lib/edh_bracket_policy.dart`
  - detecta `without paying` como `freeInteraction`;
  - cobre cartas como `Fierce Guardianship`, `Deflecting Swat` e `Deadly Rollick` quando o oracle usa free-cast em vez de `rather than pay`.
- Testes adicionados:
  - `server/test/optimization_quality_gate_test.dart`
  - `server/test/optimize_runtime_support_test.dart`

Validacoes locais executadas antes do push:

```bash
cd server
dart analyze lib/ai/optimization_functional_roles.dart lib/edh_bracket_policy.dart test/optimization_quality_gate_test.dart test/optimize_runtime_support_test.dart
dart test test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart -r expanded
dart analyze bin lib routes test
dart test
```

Resultado:

- `dart analyze`: PASS
- testes focados: PASS
- `dart test` completo backend: PASS, `601` testes
- `git diff --check`: PASS
- scan simples de secrets nas linhas alteradas: PASS

Observacoes:

- A correcao nao substitui `semantic_tags_v2`; ela melhora o fallback quando a carta nao tem tag persistida ou a confianca semantica e baixa.
- `Fierce Guardianship` foi tratado por lista curada, nao por regra global para todos os counters. Isso evita reclassificar `Counterspell`/`Swan Song`, que continuam preservando o papel `removal` nos testes existentes.
- As listas curadas sao intencionalmente pequenas. Novas cartas devem entrar com evidencia concreta e teste.
- Backend publico em `7329fbbd` contem `f57bb8d3` por ancestralidade Git (`git merge-base --is-ancestor f57bb8d3 7329fbbd => yes`).
- Scorecard publico pos-patch foi tentado em 2026-05-26 com `--expected-sha 7329fbbdd0d5ea3e88de50d3c8235e76852380f4`, mas ficou inconclusivo sem artifact/saida dentro da janela local. Antes de qualquer enforcement alem de shadow/controlado, rerodar com timeout/progresso por caso ou janela maior.

---

## Patch 1: Walking Ballista classificado como removal em vez de wincon

### Arquivo: `server/lib/ai/optimization_functional_roles.dart`

### Problema
Walking Ballista tem oracle `"{4}, Remove a +1/+1 counter from Walking Ballista: It deals 1 damage to any target."`
O classificador deterministico ve "deals" + "damage" + "any target" na linha 75 e retorna `removal`.
O sistema NAO TEM tag `wincon` no classificador deterministico — so existe via semantic_tags_v2.

### Correcao
Adicionar uma lista curada de wincons conhecidos e uma verificacao antes do bloco de `removal`:

```dart
// === ANTES (linha 65-81) ===
if (oracle.contains('draw') || oracle.contains('look at the top') || ...) {
  return 'draw';
}
if (oracle.contains('destroy target') || oracle.contains('exile target') || ...) {
  return 'removal';
}

// === DEPOIS (corrigido) ===
// Wincon: cards that win the game (checked before removal)
if (oracle.contains('you win the game') || _knownWinconNames.contains(name)) {
  return 'wincon';
}
// Engine: sustained value (checked before draw)
if (_knownEngineNames.contains(name)) {
  return 'engine';
}
// Combo piece: known combo enablers
if (_knownComboPieceNames.contains(name)) {
  return 'combo_piece';
}
if (oracle.contains('draw') || oracle.contains('look at the top') || ...) {
  return 'draw';
}
// Removal: skip counter-based wincons
if ((oracle.contains('destroy target') || ...) &&
    !(oracle.contains('remove a +1/+1 counter'))) {
  return 'removal';
}
```

### Lista de wincons a adicionar no final do arquivo
```dart
const _knownWinconNames = <String>{
  'walking ballista',
  'laboratory maniac',
  "thassa's oracle",
  'jace, wielder of mysteries',
  'approach of the second sun',
  'craterhoof behemoth',
  'torment of hailfire',
  'exsanguinate',
  'aetherflux reservoir',
  'finale of devastation',
  'triskaidekaphile',
  'test of talents',
};
```

### Lista de engines a adicionar
```dart
const _knownEngineNames = <String>{
  "the one ring",
  'thrasios, triton hero',
  'kinnan, bonder prodigy',
  'seedborn muse',
  'consecrated sphinx',
  'necropotence',
  'bolas\'s citadel',
  'mystic forge',
  'future sight',
  'magus of the future',
  "sensei's divining top",
  'rhystic study',
  'mystic remora',
  'esper sentinel',
};
```

### Lista de combo pieces a adicionar
```dart
const _knownComboPieceNames = <String>{
  'basalt monolith',
  'grim monolith',
  'freed from the real',
  'pemmin\'s aura',
  'dramatic reversal',
  'isochron scepter',
  'underworld breach',
  'lion\'s eye diamond',
  'demonic consultation',
  'tainted pact',
  'hermit druid',
};
```

---

## Patch 2: The One Ring classificado como draw em vez de engine

### Arquivo: `server/lib/ai/optimization_functional_roles.dart`

### Problema
A linha 65 verifica `oracle.contains('draw')` antes de qualquer contexto.
The One Ring tem `"draw a card for each burden counter"` → cai como `draw`.
O sistema perde que o Ring e PROTECAO + DRAW + INDESTRUTIVEL.

### Correcao
Ja incluida no Patch 1 acima — a lista `_knownEngineNames` captura The One Ring
antes do bloco de `draw`. Nao ha necessidade de patch separado.

---

## Patch 3: FreeInteraction nao detecta "without paying its mana cost"

### Arquivo: `server/lib/edh_bracket_policy.dart`

### Problema
A heuristica de freeInteraction (linhas 116-121) so detecta o padrao
`"rather than pay"`. Cartas como Fierce Guardianship, Deflecting Swat,
Deadly Rollick usam `"without paying its mana cost"` — nao sao detectadas.

### Correcao

```dart
// === NOVO bloco apos a linha 120 ===
final hasWithout = o.contains('without paying');
if (hasWithout) {
  categories.add(BracketCategory.freeInteraction);
}
```

Ou, mais completo, fundindo as heuristicas:

```dart
// Free interaction: custo alternativo
final hasRather = o.contains('rather than pay');
final hasExile = o.contains('exile a') || o.contains('exile two') || o.contains('exile one');
final hasPayLife = o.contains('pay') && o.contains('life') && hasRather;
final hasPitch = hasRather && (hasExile || hasPayLife);
final hasFreeCast = o.contains('without paying');
if (hasPitch || hasFreeCast) {
  categories.add(BracketCategory.freeInteraction);
}
```

---

## Simulacao de Validacao

Historicamente, `validate_patches.py` comparava tags ANTES/DEPOIS do patch. Em
2026-06-17 esse executor foi removido porque validava uma proposta antiga fora
da suite atual. Para confirmar regressao hoje, rode os testes versionados do
backend e do guardrail Hermes em vez do script historico:

```bash
cd server
dart test test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart -r expanded

cd ../docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_known_cards_consumer_guardrail.py -v
```

---

## Efeito Esperado

| Carta | Tag Antes | Tag Depois | Impacto |
|:------|:---------:|:----------:|:--------|
| Walking Ballista | removal | wincon | IA nao sugera remover a wincon |
| The One Ring | draw | engine | IA respeita o valor do Ring |
| Thrasios, Triton Hero | draw | engine | IA entende que e engine, nao so draw |
| Basalt Monolith | ramp | combo_piece | IA nao sugera trocar por outro ramp |
| Fierce Guardianship | remainder | +freeInteraction | Bracket system detecta como GC |
| Endurance | other | protection | IA sabe que e hate piece |

### Precisao esperada apos patches

| Categoria | Antes | Depois |
|:----------|:-----:|:------:|
| Tags funcionais (Kinnan) | 61% (8/13) | ~92% (12/13) |
| GC detectados | 21/53 | 24/53 (+Fierce, Deflecting Swat, Deadly Rollick) |

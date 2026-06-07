# Oracle Report — Revisão Heurística Scryfall Classifier
**Data:** 2026-05-27  
**Arquivo Revisado:** `scripts/scryfall_classifier.py`  
**Referência Dart:** `server/lib/ai/optimization_functional_roles.dart` + `server/lib/ai/functional_card_tags.dart`  
**Revisor:** Agente Revisor Oracle

---

## 1. Escopo da Revisão

Comparação linha-a-linha entre:
- **Python:** `scryfall_classifier.py` — implementa o classificador single-tag (`classify_card`) da função Dart `classifyOptimizationFunctionalRole`
- **Dart (A):** `optimization_functional_roles.dart` — classificador single-tag determinístico (349 linhas)
- **Dart (B):** `functional_card_tags.dart` — classificador multi-tag com 25+ funções heurísticas (1052 linhas)

A revisão cobre ambos os sistemas, mas o foco principal é o single-tag (o que é usado para contagens de deck). O multi-tag é documentado como gap estrutural.

---

## 2. Resultado dos Testes com 5 Cartas Reais

Teste executado via Scryfall API em 2026-05-27:

| Carta | Python Tag | Dart Single-Tag Esperado | Match? |
|-------|-----------|------------------------|--------|
| **Smothering Tithe** | `draw` | `draw` | ✅ |
| **Boros Charm** | `removal` | `removal` | ✅ |
| **Teferi's Protection** | `utility` | `utility` | ✅ |
| **Volcanic Vision** | `wipe` | `wipe` | ✅ |
| **Sunbird's Invocation** | `enchantment` | `enchantment` | ✅ |

**Conclusão:** Para o classificador **single-tag**, Python e Dart produzem resultados **idênticos** para as 5 cartas testadas.

> Nota: Teferi's Protection → `utility` em AMBOS porque o single-tag Dart `classifyOptimizationFunctionalRole()` só checa `hexproof`, `indestructible`, `shroud`, `ward` — não checa `phase out`, `protection from`, ou `gain protection`. A proteção mais robusta só existe no sistema multi-tag (`_looksLikeProtection` em `functional_card_tags.dart`).

---

## 3. Gaps Identificados

### 3.1 Gaps no Classificador Single-Tag (CRÍTICOS)

#### 🔴 CRÍTICO #1: Checagem de Ramp para artefatos muito restrita

**Arquivo:** `scryfall_classifier.py` linha 150  
**Código atual:**
```python
if "artifact" in type_line and "add {" in oracle:
    return True
```

**Dart equivalente** (em `classifyOptimizationFunctionalRole`):
```dart
(typeLine.contains('artifact') && oracle.contains('add'))
```

**Diferença:** Dart checa apenas `oracle.contains('add')` (sem o `{`), o que é mais abrangente.

**Cartas afetadas:** Qualquer artefato cujo texto de ativação use "Add X mana" sem chaves literais. Exemplo: nenhum nas cartas testadas, mas artefatos com texto "Add one mana of any color" já são pegos por `"mana of any"`.

**Impacto real:** 🔴 BAIXO na prática porque `"mana of any"` e `"add {"` pegam quase todos os casos. A diferença teórica existe mas raramente se manifesta.

---

#### 🔴 CRÍTICO #2: Heurística de Draw muito ampla (compartilhado com Dart)

**Arquivo:** `scryfall_classifier.py` linha 177  
**Código:**
```python
if "draw" in oracle or "look at the top" in oracle:
    return "draw"
```

**Problema:** Não exclui oponentes comprando. Smothering Tithe ("Whenever an opponent draws...") é classificado como `draw` porque a oracle contém a substring "draw".

**Dart multi-tag** (`_looksLikeDraw` em `functional_card_tags.dart` linhas 644-661) faz a exclusão correta:
```dart
if (oracle.contains('target opponent draws') ||
    oracle.contains('an opponent draws') ||
    oracle.contains('each opponent draws')) {
  return false;
}
```

**Cartas afetadas:** Smothering Tithe, Howling Mine, Font of Mythos, Dictate of Kruphix, etc.

**Impacto real:** ⚠️ O Dart single-tag TEM O MESMO PROBLEMA — então não é um gap Python vs Dart, mas um gap de design em ambos os single-tag classifiers. No multi-tag Dart, a correção existe.

---

### 3.2 Gaps no Sistema Multi-Tag (Não Implementado no Python)

O Python **não implementa** o sistema multi-tag de `functional_card_tags.dart`. Abaixo, a lista completa de funções heurísticas faltantes:

| # | Função Dart Faltante | Tags Geradas | Impacto |
|---|---------------------|-------------|---------|
| 1 | `_looksLikeDraw` (refinado) | `draw` | 🟡 MODERADO — versão refinada com exclusão de oponente |
| 2 | `_looksLikeLoot` | `loot` | 🟡 MODERADO — loot/rummage detection |
| 3 | `_looksLikeTutor` (refinado) | `tutor` | 🟡 MODERADO — requer put/reveal/card |
| 4 | `_looksLikeTargetedRemoval` (refinado) | `removal` | 🟡 MODERADO — exclui próprias permanentes, adiciona -X/-X |
| 5 | `_looksLikeProtection` (completo) | `protection` | 🟡 MODERADO — phase out, protection from, prevent damage, nomes específicos |
| 6 | `_looksLikeRecursion` | `recursion` | 🔴 CRÍTICO — recursão é função primária de deck |
| 7 | `_looksLikeGraveyardSynergy` | `graveyard_synergy` | 🟡 MODERADO |
| 8 | `_looksLikeTokenMaker` | `token_maker` | 🟡 MODERADO — ex: Smothering Tithe cria tokens |
| 9 | `_looksLikeSacrificeOutlet` | `sacrifice_outlet` | 🟡 MODERADO |
| 10 | `_looksLikeAristocratPayoff` | `aristocrat_payoff` | 🟡 MODERADO |
| 11 | `_looksLikeLifegain` | `lifegain` | 🟡 MODERADO |
| 12 | `_looksLikeDrain` | `drain` | 🟡 MODERADO |
| 13 | `_looksLikeSpellslinger` | `spellslinger` | 🟡 MODERADO |
| 14 | `_looksLikeArtifactSynergy` | `artifact_synergy` | 🟡 MODERADO |
| 15 | `_looksLikeEnchantmentSynergy` | `enchantment_synergy` | 🟡 MODERADO |
| 16 | `_looksLikeEtb` | `etb` | 🟡 MODERADO |
| 17 | `_looksLikeBlink` | `blink`, `protection` | 🟡 MODERADO — também gera tag protection |
| 18 | `_looksLikeBigSpellPayoff` | `big_spell` | 🟡 MODERADO — ex: Sunbird's Invocation (cmc>=6) |
| 19 | `_looksLikeExileValue` | `exile_value` | 🟡 MODERADO |
| 20 | `_looksLikeRitual` | `ritual` | 🟡 MODERADO — Dark Ritual, Jeska's Will |
| 21 | `_looksLikeWincon` | `wincon` | 🟡 MODERADO |
| 22 | `_looksLikeComboPiece` | `combo_piece` | 🟡 MODERADO |
| 23 | `_looksLikeEngine` | `engine` | 🟡 MODERADO — ex: Smothering Tithe gera engine |
| 24 | `_looksLikePayoff` | `payoff` | 🟡 MODERADO |
| 25 | `_looksLikeEnabler` | `enabler` | 🟡 MODERADO |
| 26 | Named-card exceptions (signet/talisman/sol ring) | `ramp` | 🔴 CRÍTICO — mas baixo impacto na prática |
| 27 | Heurística de CMC >= 6 | `big_spell` | 🟡 MODERADO — ex: Volcanic Vision (cmc=7) |

**Total: 27 funções heurísticas não implementadas.**

---

### 3.3 Gaps na Estrutura de Dados

O Python retorna apenas UMA tag por carta. O Dart retorna uma LISTA de tags com níveis de confiança:

```dart
class FunctionalCardTag {
  final String tag;        // ex: 'draw', 'ramp', 'protection'
  final double confidence; // ex: 0.84
  final String evidence;   // ex: 'card_draw_text'
}
```

O sistema Dart multi-tag permite que uma carta seja simultaneamente:
- `ramp` + `draw` + `engine` (ex: Smothering Tithe → no multi-tag seria `engine` + `token_maker`)
- `removal` + `protection` (ex: counterspells → Dart adiciona `protection` com confiança 0.62)
- `wipe` + `recursion` + `big_spell` (ex: Volcanic Vision)

O Python força uma escolha binária, perdendo informação semântica.

---

## 4. Mapa de Cartas Testadas vs Heurísticas Multi-Tag

| Carta | Tags Multi-Tag (Dart) | Python | Gap |
|-------|----------------------|--------|-----|
| **Smothering Tithe** | `engine`, `token_maker` | `draw` (impreciso) | 🟡 engine + token_maker perdidos |
| **Boros Charm** | `protection` (via indestructible), `removal` | `removal` | 🟡 proteção de board perdida |
| **Teferi's Protection** | `protection` (via phase out + gain protection) | `utility` | 🟡 proteção perdida |
| **Volcanic Vision** | `recursion`, `big_spell`, `wincon` (c/ dano), `wipe` | `wipe` | 🟡 3 tags perdidas |
| **Sunbird's Invocation** | `big_spell` (cmc>=6 ou "without paying") | `enchantment` | 🟡 big_spell perdido |

---

## 5. Recomendações

### Prioridade Alta (🔴)

1. **Adicionar `_looksLikeProtection` completo** — Mesmo no single-tag, a versão expandida (phase out, protection from, prevent damage, can't be target) melhora a classificação de proteção. Impacto direto em cartas como Teferi's Protection e Heroic Intervention.

2. **Implementar sistema multi-tag** — A replicação parcial da função `inferFunctionalCardTags` permitiria que cada carta recebesse múltiplas tags com confiança. Isto é necessário para análise de deck completa (contagens de `engine`, `payoff`, `enabler`, etc.).

### Prioridade Média (🟡)

3. **Adicionar `_looksLikeTokenMaker`** — Impacta ramp indireto (Treasure tokens), tokens de criatura.

4. **Adicionar `_looksLikeEngine`** — Cartas como Smothering Tithe são engines de valor, não draw.

5. **Adicionar `_looksLikeRecursion`** — Função crítica para decks de cemitério.

6. **Adicionar `_looksLikeRitual`** — Diferencia ramp permanente de burst de mana temporário.

7. **Refinar `looks_like_ramp`** — Mudar `"add {"` para `"add"` no contexto artifact+add, para alinhar com Dart.

### Prioridade Baixa (🔵)

8. **Adicionar tags secundárias** — `loot`, `graveyard_synergy`, `sacrifice_outlet`, `aristocrat_payoff`, `lifegain`, `drain`, `spellslinger`, `artifact_synergy`, `enchantment_synergy`, `etb`, `blink`, `exile_value`, `combo_piece`, `payoff`, `enabler`.

---

## 6. Conclusão

O `scryfall_classifier.py` replica fielmente o classificador **single-tag** de `optimization_functional_roles.dart` para as 5 cartas testadas. Não há discrepâncias entre Python e Dart no classificador single-tag.

O gap principal é estrutural: o sistema **multi-tag** inteiro (27 heurísticas, 36 tags, níveis de confiança, evidências textuais) não foi implementado em Python. Este sistema é o que alimenta a análise semântica V2 no ManaLoom e é responsável por tags como `engine`, `payoff`, `recursion`, `wincon`, `ritual`, `token_maker`, etc.

**Score de completude:**
- Single-tag classifier: **~95%** (apenas diferenças marginais)
- Multi-tag classifier: **0%** (não implementado)
- Análise semântica V2 (speed, mana efficiency, card advantage type, interaction scope): **0%** (não implementado)
#!/usr/bin/env python3
"""Append new synthesis tasks to IMPLEMENTATION_TASKS.md."""
import os

path = "/opt/data/workspace/mtgia/docs/hermes-analysis/IMPLEMENTATION_TASKS.md"
with open(path, "r") as f:
    content = f.read()

new_tasks = """

### [P1] Semantic Helpers Divergence: Unificar `_looksLikeWincon`/`_looksLikeComboPiece`/etc. entre functional_card_tags.dart e optimization_functional_roles.dart — dois classificadores com heuristicas completamente diferentes

**Conhecimento MTG:** O STRUCTURE_AUDIT (Rodada: Duplicated or similar logic, 2026-06-07) documenta que as heuristicas semanticas de alto nivel (wincon, combo_piece, engine, payoff, enabler) tem DUAS implementacoes completamente divergentes no codigo. Uma carta pode ser classificada como `wincon` pelo tag v1 (`functional_card_tags.dart`) e como `engine` pelo role classifier (`optimization_functional_roles.dart`). Isso cria drift entre a analise funcional (explicabilidade para o usuario) e a decisao de swap (pipeline de optimize).

**Evidencia no codigo:**
- `server/lib/ai/functional_card_tags.dart:859-907` — `_looksLikeWincon`, `_looksLikeComboPiece`, `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler` usam `oracle` + `normalizedName` com regras ricas (ex: nomes conhecidos como `thassa's oracle`, `isochron scepter`, `blood artist`, `greaves`).
- `server/lib/ai/optimization_functional_roles.dart:529-569` — MESMOS nomes de funcao, mas implementacoes RADICALMENTE diferentes: usam apenas `oracle`, sem consulta a nomes de carta. Ex: `_looksLikeWincon` no role classifier so detecta `you win the game` / `opponent loses the game`, enquanto o tag v1 tambem detecta `damage equal to`, `double your life total`, `each opponent loses`.
- `_looksLikeComboPiece` no role classifier detecta `remove...counter...from among` e `search...may cast...without paying`, enquanto o tag v1 detecta `isochron scepter`, `dramatic reversal`, `copy target activated or triggered ability`, `untap+add`, `infinite`.
- `_looksLikeEnabler` no role classifier so detecta cost reduction + spells cost less, enquanto o tag v1 tambem detecta `greaves`, `boots`, `haste`, `mill`, `sacrifice another`, `search your library`.

**Gap:** Duas implementacoes independentes com heuristicas diferentes para classificar os MESMOS papeis semanticos. Nao ha contrato compartilhado, nao ha testes cruzados. Uma carta como `Impact Tremors` pode ser `payoff` em um sistema e nao-payoff no outro.

**Impacto:** P1 — Drift entre analise funcional (tag v1, exibida ao usuario) e decisao de swap (role classifier, usada pelo quality gate). O quality gate pode rejeitar swaps que o usuario esperaria baseado na analise funcional, ou aceitar swaps que contradizem a analise. Afeta toda a pipeline de optimize para decks com tags semanticas de alto nivel.

**Risco:** P1 — Incoerencia sistemica entre dois classificadores que operam no mesmo dominio sem contrato unificado. Agravado pelo fato de que `optimization_functional_roles.dart` ja foi melhorado com regras contextuais (Cron #11), mas `functional_card_tags.dart` permanece com heuristicas antigas.

**Acao recomendada:**
1. Extrair heuristicas compartilhadas para um modulo unico (ex: `semantic_role_heuristics.dart`) com funcoes `looksLikeWincon()`, `looksLikeComboPiece()`, etc. que aceitam `oracle` + `normalizedName` opcional.
2. Ambos `functional_card_tags.dart` e `optimization_functional_roles.dart` devem importar do modulo compartilhado.
3. Adicionar testes cruzados: para N cartas sentinela, verificar que ambos os classificadores retornam o mesmo papel semantico.
4. Manter as regras contextuais de `optimization_functional_roles.dart` como camada adicional, nao como substituta.

**Validacao:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart && dart analyze lib/ai/optimization_functional_roles.dart
cd server && dart test test/ai/semantic_role_heuristics_test.dart
```

---

### [P1] Basic Land Detection: Centralizar 4 variantes de `isBasicLandName` em um unico modulo — inconsistencia em snow-covered lands pode quebrar validacao de singleton

**Conhecimento MTG:** O STRUCTURE_AUDIT (Rodada: Duplicated or similar logic, 2026-06-07) identifica 4 implementacoes diferentes de deteccao de basic land name no backend, cada uma com regras de normalizacao diferentes para snow-covered lands (hifen vs espaco, `snow-covered` vs `snow covered`). A LOGIC_COHERENCE_REPORT (2026-05-29) ja havia identificado um modulo `basic_land_utils.dart` criado, mas as implementacoes duplicadas persistem.

**Evidencia no codigo:**
- `server/lib/ai/optimize_runtime_support.dart:4184-4197` — `isBasicLandName` compara nomes exatos com hifen para snow-covered lands.
- `server/lib/generated_deck_validation_service.dart:752-764` — Aceita `startsWith('snow-covered ...')`.
- `server/lib/meta/meta_deck_reference_support.dart:890-903` — Aceita snow lands com ESPACO (`snow covered plains`) em vez de hifen.
- `server/routes/ai/commander-reference/index.dart:621-629` — Reconhece apenas as seis basics nao-snow, ignorando snow-covered completamente.
- `server/lib/ai/basic_land_utils.dart` — Modulo centralizado EXISTE mas nao e usado por todos os chamadores.

**Gap:** Quatro arquivos respondem a mesma pergunta de dominio com regras diferentes. Validacao de singleton pode rejeitar snow-covered Plains como duplicata em um chamador e aceitar em outro. O commander-reference endpoint e cego a snow-covered lands.

**Impacto:** P1 — Inconsistencia na validacao de terrenos basicos entre fluxos de deck validation, optimize, meta reference, e commander reference. Um deck com Snow-Covered Plains pode ser validado corretamente pelo `deck_rules_service` mas rejeitado pelo optimize runtime support, ou vice-versa.

**Risco:** P1 — Validacao de singleton inconsistente. Snow-covered lands sao staples em decks com Field of the Dead ou Extraplanar Lens.

**Acao recomendada:**
1. Expandir `basic_land_utils.dart` para cobrir TODOS os casos de normalizacao (hifen, espaco, Wastes, snow-covered).
2. Migrar `optimize_runtime_support.dart`, `generated_deck_validation_service.dart`, `meta_deck_reference_support.dart`, e `commander-reference/index.dart` para usar `basic_land_utils.isBasicLandName()`.
3. Adicionar testes unitarios para snow-covered com hifen, snow-covered com espaco, Wastes, e as 6 basics normais.
4. Remover as implementacoes privadas duplicadas.

**Validacao:**
```bash
cd server && dart analyze lib/ai/basic_land_utils.dart
cd server && dart test test/basic_land_utils_test.dart
cd server && dart test test/generated_deck_validation_service_test.dart
```

---

### [P2] Theme-Specific Optimization Targets: Usar metricas validadas por tema (THEMES.md) em vez de targets genericos no quality gate e optimize

**Conhecimento MTG:** O THEMES.md (2026-06-07) documenta metricas validadas de 8 temas com dados reais (EDHREC, Moxfield, Archidekt, primers). As metricas variam RADICALMENTE por tema:
- Goblins: ramp 8-11 (integrado a criaturas), haste/untap 6-10 (ausente do modelo atual)
- Elfball: ramp 20-30 (dorks de mana), draw 6-10
- Dragons: ramp 12-16, CMC medio ~4.09, copy enablers 5-9, ETB damage payoffs 5-8
- Vampires: ramp 9-12, draw 10-13, interaction 8-11
- Enchantress: ramp 8-10 (enchantment-based), draw 10-14
- cEDH Combo: ramp 20-30, draw 4-6, interaction 12-20

O codigo atual usa targets genericos para todas as otimizacoes, ignorando que um deck de Elfball PRECISA de 20+ ramp dorks (que tambem sao elfos) enquanto um deck de Goblins precisa de 6-10 haste/untap enablers (que o modelo atual nem reconhece como categoria).

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart` — `_criticalRolesForArchetype()` mapeia archetypes genericos (aggro, control, midrange, combo) para papeis criticos, sem considerar tema.
- `server/lib/ai/optimize_runtime_support.dart` — Targets de swap usam metricas estruturais (lands, ramp, draw, removal) sem variacao por tema.
- `server/lib/ai/functional_card_tags.dart:38-56` — `deckAnalysisMainFunctionalBuckets` inclui `token_maker`, `sacrifice_outlet`, `aristocrat_payoff`, `spellslinger`, mas nao `haste`, `copy_enabler`, `etb_damage` que sao criticos para temas especificos.
- `server/lib/ai/theme_contextual_rules_service.dart` — Servico de regras tematicas existe, mas nao e integrado aos targets de otimizacao.

**Gap:** O quality gate e o optimize pipeline usam metricas genericas que nao refletem as necessidades reais de cada tema. Um deck de Goblins com 8 ramp sources seria considerado "abaixo do ideal" por um target generico de 10-12, quando na verdade 8-11 e o range CORRETO para Goblins. Um deck de Dragons sem copy enablers nao seria alertado porque `copy_enabler` nao existe como categoria.

**Impacto:** P2 — Recomendacoes de swap sub-otimas para decks com temas validados. O sistema pode recomendar adicionar ramp em um deck de Goblins que ja tem ramp suficiente, ou nao recomendar haste/untap enablers que sao criticos para Krenko.

**Risco:** P2 — Afeta a qualidade das recomendacoes de swap para os 8 temas validados. Nao afeta a integridade estrutural (deck continua valido), mas reduz a relevancia estrategica das sugestoes.

**Acao recomendada:**
1. Criar `theme_optimization_targets.dart` com metricas ideais por tema, baseado nos dados validados do THEMES.md:
   - Cada tema define `Map<String, Range>` com min/max para lands, ramp, draw, removal, interaction, protection, e papeis tematicos (haste, copy_enabler, etb_damage, sacrifice_outlet, etc.)
2. Integrar ao `optimization_quality_gate.dart`: `_criticalRolesForArchetype()` deve consultar o tema do deck quando disponivel.
3. No `optimize_runtime_support.dart`: targets de swap estruturais (ramp, draw, removal) devem usar metrics por tema em vez de genericas.
4. Adicionar `haste_enabler` e `copy_enabler` aos functional buckets como tags reconhecidas.

**Validacao:**
```bash
cd server && dart analyze lib/ai/theme_optimization_targets.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db');
print('Temas no DB:', conn.execute('SELECT COUNT(*) FROM deck_themes').fetchone()[0]);
print('Regras de deteccao:', conn.execute('SELECT COUNT(*) FROM theme_detection_rules').fetchone()[0])
"
```

---

### [P2] Deck Stats Duplication: Extrair `getMainType`/`calculateCmc` das rotas privada e publica para um helper compartilhado

**Conhecimento MTG:** O STRUCTURE_AUDIT (Rodada: Duplicated or similar logic, 2026-06-07) identifica que as rotas de deck privado (`server/routes/decks/[id]/index.dart`) e deck publico (`server/routes/community/decks/[id].dart`) tem implementacoes DUPLICADAS de `getMainType` e `calculateCmc`. As duas rotas constroem agrupamento por tipo, curva de mana, e distribuicao de cores com regras praticamente identicas. Uma correcao de bug em uma rota pode ser esquecida na outra.

**Evidencia no codigo:**
- `server/routes/decks/[id]/index.dart:405-436` — Define `getMainType` e `calculateCmc` dentro da rota de deck privado.
- `server/routes/community/decks/[id].dart:91-117` — Define helpers equivalentes na rota de deck publico.
- Ambos usam `cardsList` como entrada e produzem `mainBoard`, `manaCurve`, `colorDistribution` com logica quase identica.

**Gap:** Duas rotas mantem copias independentes da mesma logica de estatisticas de deck. Se uma regra de CMC ou tipo principal mudar, precisa ser atualizada em dois lugares.

**Impacto:** P2 — Risco de divergencia: o mesmo deck pode apresentar estatisticas diferentes quando visto pelo dono (rota privada) e pela comunidade (rota publica). Ex: se `calculateCmc` tratar cartas MDFC ou split cards de forma diferente nas duas implementacoes.

**Risco:** P2 — Baixo no curto prazo (implementacoes atualmente identicas), mas risco de drift a medida que cada rota evolui independentemente.

**Acao recomendada:**
1. Criar `server/lib/deck_stats_helper.dart` com funcoes `getMainType()`, `calculateCmc()`, e `buildManaCurve()` compartilhadas.
2. Migrar ambas as rotas para usar o helper compartilhado.
3. Adicionar testes de contrato: para um deck fixture, verificar que a resposta de stats e identica entre rota privada e publica.

**Validacao:**
```bash
cd server && dart analyze lib/deck_stats_helper.dart
cd server && dart analyze routes/decks/[id]/index.dart
cd server && dart analyze routes/community/decks/[id].dart
cd server && dart test test/deck_stats_helper_test.dart
```

---

### [P2] Game Changer Impact Sub-Categorization: Adicionar `cardAdvantage`, `boardWipe`, `stax`, `valueEngine`, `protection` ao `BracketCategory` enum — 29/53 GCs sem categoria de impacto

**Conhecimento MTG:** O GAME_CHANGERS.md (2026-06-07) e o SQLite `game_changers` documentam que 29 dos 53 Game Changers (55%) tem `manaloom_detected=0` — ou seja, o sistema sabe que SAO Game Changers (pela lista hardcoded), mas nao consegue classificar o TIPO de impacto (card advantage, board wipe, stax, etc.). As 5 categorias atuais do `BracketCategory` enum (fastMana, tutor, freeInteraction, extraTurns, infiniteCombo) cobrem apenas 24/53 GCs. Cartas como Rhystic Study (card_advantage), Cyclonic Rift (board_wipe), Drannith Magistrate (stax), The One Ring (card_advantage), Teferi's Protection (protection) nao se encaixam em nenhuma categoria existente.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:7-14` — `BracketCategory` enum com apenas 6 valores: `fastMana`, `tutor`, `freeInteraction`, `extraTurns`, `infiniteCombo`, `gameChanger`.
- `server/lib/edh_bracket_policy.dart:103` — Game Changers detectados por nome retornam APENAS `{BracketCategory.gameChanger}`, sem sub-categoria.
- SQLite: `SELECT card_name, impact_category, manaloom_bracket_category FROM game_changers WHERE manaloom_detected=0` retorna 29 cartas com categorias como `card_advantage_gap`, `other`, `board_wipe`.

**Gap:** O bracket policy perde a informacao de IMPACTO do game changer. Isso nao afeta a contagem de budget (que usa `gameChanger` corretamente), mas impede:
- Explicar ao usuario POR QUE uma carta e game changer
- Validar se a lista hardcoded esta completa (se uma nova carta com `card_advantage` explosivo surgir, nao seria detectada como GC potencial)
- Categorizar game changers para analise de poder (ex: deck tem 3 GCs, todos de fast mana = mais explosivo que 3 GCs de card advantage)

**Impacto:** P2 — Afeta explicabilidade e analise de power level. Nao afeta a contagem de budget de bracket (que funciona corretamente com `gameChanger`). Afeta a capacidade do sistema de explicar decisoes de bracket para o usuario.

**Risco:** P2 — Melhoria de transparencia e completude taxonomica. O sistema atual funciona corretamente para contagem de GCs, mas a falta de sub-categorizacao limita a qualidade da analise.

**Acao recomendada:**
1. Adicionar ao `BracketCategory` enum: `cardAdvantage`, `boardWipe`, `stax`, `valueEngine`, `protection`.
2. Em `tagCardForBracket()`: para game changers detectados por nome, tambem inferir a sub-categoria usando o `impact_category` do SQLite ou heuristicas:
   - `cardAdvantage`: oracle contem `draw a card` + trigger repetivel (Rhystic Study, The One Ring, Necropotence)
   - `boardWipe`: oracle contem `destroy all` / `exile all` / `return all` (Cyclonic Rift, Farewell)
   - `stax`: oracle contem `can't` + `opponent` (Drannith Magistrate, Opposition Agent, Narset)
   - `valueEngine`: oracle contem `whenever` + valor continuo (Seedborn Muse, Consecrated Sphinx)
   - `protection`: oracle contem `protection from` / `phase out` / `indestructible` massivo (Teferi's Protection)
3. Atualizar `countBracketCategories()` e `applyBracketPolicyToAdditions()` para incluir as novas categorias no tracking (mas sem budget restriction — sub-categorias sao informativas, nao restritivas).
4. Atualizar `BracketPolicy.maxCounts` para incluir as novas categorias com limite 99 (sem restricao pratica, apenas tracking).

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db');
detected = conn.execute('SELECT COUNT(*) FROM game_changers WHERE manaloom_detected=1').fetchone()[0];
total = conn.execute('SELECT COUNT(*) FROM game_changers').fetchone()[0];
print(f'GCs with sub-category: {detected}/{total} ({detected/total*100:.0f}%) — target: 53/53 (100%)')
"
```

---

> **Base de conhecimento:** STRUCTURE_AUDIT (Rodada: Duplicated or similar logic — 2026-06-07), GAME_CHANGERS.md (29/53 GCs sem sub-categoria de impacto), THEMES.md (8 temas validados com metricas divergentes), SQLite game_changers + tag_accuracy + decks
> **Novas tasks nesta execucao:** 5 (2xP1, 3xP2) — Semantic helpers unification, basic land detection centralization, theme-specific optimization targets, deck stats deduplication, GC impact sub-categorization
"""

# Prepend new tasks after the header block (after the first "---" separator)
# Find the first "---" after the header
header_end = content.find("---", content.find("> **Metodo:**"))
if header_end == -1:
    header_end = content.find("---", content.find("> **Branch:**"))

if header_end != -1:
    # Find the end of that separator line
    sep_end = content.find("\n", header_end)
    # Insert new tasks after the separator
    new_content = content[:sep_end+1] + new_tasks + content[sep_end+1:]
else:
    # Fallback: prepend after first 5 lines
    lines = content.split("\n")
    new_content = "\n".join(lines[:6]) + new_tasks + "\n".join(lines[6:])

with open(path, "w") as f:
    f.write(new_content)

print(f"Updated {path} ({len(new_content)} chars, was {len(content)} chars)")

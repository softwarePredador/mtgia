# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference
> **Gerado:** 2026-06-05T06:00Z por ManaLoom Knowledge Synthesis (Cron #8)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 94b620a6
> **Metodo:** Cruzamento do conhecimento MTG (Commander Knowledge Deep S42-43, Gamechanger Research Exec #7-#9, MANA_BASE_VALIDATION_REPORT 2026-06-05, THEMES.md, STRUCTURE_AUDIT card-semantics) com codigo Dart (edh_bracket_policy, card_validation_service, deck_rules_service, functional_card_tags, optimization_quality_gate, commander_fallback_policy, optimize_runtime_support)
> **Base de conhecimento:** Commander Knowledge Deep S42-43 (Multi-Commander Evolution 4 promotions, Korvold incomplete import, Krenko AI stub) + Gamechanger Research #7-#9 (Tergrid oracle_text resolved, 8 NULL prices persistent, structural hash unchanged) + MANA_BASE_VALIDATION_REPORT (Yuriko 21/84 untagged, CRITs potentialmente inflados) + THEMES.md (42 temas com metricas per-tema nao integradas ao codigo)
> **Novas tasks nesta execucao:** 5 (2xP1, 3xP2) — Deck import completeness, Commander eligibility filter, GC oracle_text auto-heal, GC price_usd RL distinction, Mana base NULL tag reporting

### [P1] Deck Import: Adicionar validacao de completude — verificar que o numero de cartas importadas corresponde ao total esperado (previne pipeline operando sobre decks fantasmas)

**Conhecimento MTG:** O Commander Knowledge Deep S42-43 (2026-06-05) documenta que 3 dos 8 decks no SQLite estao gravemente incompletos:
- Korvold, Fae-Cursed King: 11/100 cartas importadas (89 cartas faltando)
- Kinnan, Bonder Prodigy: 13/100 cartas importadas (87 cartas faltando)
- Teysa Karlov: 80/100 cartas (20 faltando, EDHREC aggregate parcial)

Os decks Korvold e Kinnan sao funcionalmente INUTEIS para qualquer analise — tem apenas 11-13 cartas seed de um deck de 100. No entanto, o sistema os trata como decks validos: aparecem no MANA_BASE_VALIDATION_REPORT como "INCOMPLETE", sao consultados por crons, e o Multi-Commander Evolution precisou aprender a filtra-los manualmente. O Mana Base Validator reporta "INCOMPLETE (<50 cards)" mas isso e um diagnostico pos-falha — o sistema nao impede a importacao parcial e nao alerta no momento da importacao.

**Evidencia no codigo:**
- `server/lib/deck_rules_service.dart:412-447` — `_loadCardsData()` consulta cartas do PG mas **nao valida** se o numero de cartas retornadas corresponde ao `total_cards` esperado.
- `server/lib/card_validation_service.dart:67-80` — `_findCard()` consulta apenas `id, name`. Sem validacao de completude.
- `rg "total_cards|card_count|completeness|missing.*cards" server/lib/` — ZERO resultados para validacao de completude.
- A importacao e feita via scripts Python (`auto_sync_learned_decks.py`) que inserem `deck_cards` mas nao verificam se `COUNT(*)` de cartas inseridas == `total_cards` do deck.

**Gap:** Quando um deck e importado (via script Python ou API), nao ha verificacao de que TODAS as cartas foram inseridas com sucesso. Falhas parciais (ex: 11/100 cartas) sao aceitas silenciosamente. O sistema downstream (Mana Base Validator, Commander Knowledge Deep, Multi-Commander Evolution) herda dados incompletos e produz analises enganosas ou quebra.

**Impacto:** `P1` — Decks fantasmas (Korvold 11/100, Kinnan 13/100) consomem recursos de todos os crons, produzem relatorios enganosos (MANA_BASE_VALIDATION_REPORT mostra "INCOMPLETE" sem explicar que e 89% vazio), e exigem workarounds manuais em cada cron (Multi-Commander Evolution precisou aprender a filtrar `total_cards < 90`).

**Risco:** P1 — Dados incompletos se propagam para toda a pipeline de analise. Decks com 11% das cartas sao tratados como decks reais, desperdicando ciclos de cron e produzindo recomendacoes baseadas em dados fantasmas.

**Acao recomendada:**
1. No script de importacao Python (`auto_sync_learned_decks.py` ou equivalente): apos inserir `deck_cards`, executar `SELECT COUNT(*) FROM deck_cards WHERE deck_id = ?` e comparar com `total_cards` do deck. Se `COUNT(*) < total_cards * 0.9`, marcar o deck como `import_status='partial'` e logar warning.
2. Em `card_validation_service.dart`: Adicionar metodo `validateDeckCompleteness(int deckId, int expectedCardCount)` que retorna `DeckCompletenessResult` com `importedCount`, `expectedCount`, `missingCards`.
3. No `deck_rules_service.dart`: apos `_loadCardsData()`, verificar se `cards.length >= expectedTotal * 0.9`. Se nao, retornar erro ou warning.
4. No endpoint de analise de deck (`server/routes/decks/[id]/analysis/`), verificar completude antes de executar Monte Carlo/analise funcional.
5. Adicionar coluna `import_completeness` (0.0-1.0) a tabela `decks` para tracking.

**Validacao:**
```bash
cd server && dart analyze lib/card_validation_service.dart
cd server && dart analyze lib/deck_rules_service.dart
cd server && dart test test/deck_rules_service_test.dart
```

---

### [P1] Commander Selection: Query both `decks` AND `learned_decks` tables — verificar `total_cards >= 90` em pelo menos uma tabela antes de selecionar comandante para otimizacao

**Conhecimento MTG:** O Multi-Commander Evolution Pipeline (Execucao #1, 2026-06-04, documentado no Commander Knowledge Deep S42-43) descobriu empiricamente que comandantes podem ter dados parciais:
- Korvold: 11/100 cards em `decks` (89% vazio)
- Kinnan: 13/100 cards em `decks` (87% vazio)
- Aesi, Teysa, Yuriko: tem decks parciais em `decks` mas NAO tem `learned_decks` completos (card_count < 90)

Se o otimizador selecionar Korvold (11 cartas) para evolucao, o pipeline inteiro quebra: analise de wincon sobre 11 cartas, swap em deck fantasma, validacao contra dados incompletos. O Multi-Commander Evolution precisou aprender manualmente a filtrar `total_cards >= 90`. Mas esse filtro deveria estar no codigo, nao no prompt do cron.

**Evidencia no codigo:**
- `rg "total_cards|card_count|learned_deck" server/lib/ai/optimize_runtime_support.dart` — Referencias a `learned_deck` existem para `loadCommanderReferenceProfileFromCache()` (linha 3820), mas nao para filtrar comandantes elegiveis.
- `rg "WHERE.*total_cards|WHERE.*card_count" server/lib/` — ZERO resultados com threshold de completude.
- `server/lib/ai/commander_fallback_policy.dart` — Politica de fallback para comandantes desconhecidos, mas nao verifica se os dados do comandante sao completos.
- O endpoint de optimize (`server/routes/ai/optimize/index.dart`) seleciona comandante baseado no deck do usuario, sem verificar se o deck esta completo.

**Gap:** Quando o otimizador ou o pipeline de evolucao seleciona um comandante para analise, nao verifica se os dados disponiveis sao suficientes (>=90 cartas). Decks com 11-13 cartas passam pela selecao e produzem analises invalidas. O filtro `total_cards >= 90` existe apenas no prompt do cron (documentado no skill), nao no codigo.

**Impacto:** `P1` — O optimize pipeline pode operar sobre dados incompletos, produzindo recomendacoes de swap baseadas em 11% do deck real. O Multi-Commander Evolution gastou uma execucao inteira aprendendo isso (e documentando o workaround). Sem o fix no codigo, qualquer novo cron ou endpoint que selecione comandantes repetira o mesmo erro.

**Risco:** P1 — Recomendacoes de swap baseadas em decks fantasmas (Korvold 11 cartas, Kinnan 13 cartas). Afeta diretamente a confiabilidade do optimize pipeline para esses comandantes.

**Acao recomendada:**
1. Criar funcao `isCommanderEligibleForOptimization(String commanderName)` que:
   - Consulta `decks` WHERE `total_cards >= 90`
   - Consulta `learned_decks` WHERE `card_count >= 90`
   - Retorna `true` se PELO MENOS UMA das duas tabelas tem dados completos
2. Integrar ao `commander_fallback_policy.dart`: antes de aplicar fallback, verificar se os dados do comandante sao completos.
3. No endpoint de optimize: antes de iniciar analise, verificar `isCommanderEligibleForOptimization()` e retornar erro 422 se nao for elegivel.
4. Adicionar mensagem de erro informativa: "Commander X has insufficient data (Y/100 cards). Please import a complete decklist first."

**Validacao:**
```bash
cd server && dart analyze lib/ai/commander_fallback_policy.dart
cd server && dart test test/ai/commander_fallback_policy_test.dart
```

---

### [P2] Game Changer Import: Auto-detectar `oracle_text=NULL` e disparar reimportacao via Scryfall fuzzy search com fallback para nomes MDFC sem `//`

**Conhecimento MTG:** O Gamechanger Research Report (Exec #7-#9, 2026-06-04/05) documenta que Tergrid, God of Fright // Tergrid's Lantern ficou com `oracle_text=NULL` por multiplas execucoes consecutivas. A causa: o nome MDFC contem `//`, e o Scryfall fuzzy search (`/cards/named?fuzzy=...`) falha quando o nome inclui `//`. A solucao manual (reimportar via `fuzzy=Tergrid, God of Fright` sem `//`) funcionou, mas o sistema deveria auto-curar. As heuristicas de deteccao de GC (`tagCardForBracket()`) dependem de `oracle_text` para detectar tutores, free interaction, e infinite combos — com `oracle_text=NULL`, TODAS as heuristicas ficam cegas para a carta.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:91-145` — `tagCardForBracket()` usa `oracleText` para detectar `tutor` (linha 111: `o.contains('search your library')`), `extraTurns` (116), `freeInteraction` (121-132). Com `oracle_text=NULL`, `o` e string vazia -> nenhuma categoria detectada.
- `server/lib/edh_bracket_policy.dart:140-143` — A deteccao por nome (`_gameChangerNames`) ainda funciona, mas a carta e marcada apenas como `gameChanger`, sem a categoria de impacto correta (ex: Tergrid deveria ser `stax`/`value_engine`).
- O script `gc_hash_check.py` (linhas 82-90) detecta `oracle_text IS NULL` mas apenas reporta — nao corrige.
- O script de importacao inicial (que popula `game_changers` no SQLite) deve lidar com falhas de fuzzy search para nomes MDFC.

**Gap:** Cartas MDFC com `//` no nome falham na importacao do Scryfall (oracle_text=NULL) e permanecem nesse estado por multiplas execucoes. O `tagCardForBracket()` perde TODAS as heuristicas de deteccao para essas cartas. O sistema detecta o problema (`gc_hash_check.py` reporta NULLs) mas nao auto-corrige.

**Impacto:** `P2` — 1 carta (Tergrid) foi afetada e ja corrigida manualmente. Mas o padrao pode se repetir para qualquer MDFC futuro adicionado a lista de Game Changers. A deteccao por nome ainda funciona, mas a categorizacao de impacto fica incompleta.

**Risco:** P2 — Baixa frequencia (1/53 GCs afetado), mas alta severidade quando ocorre (todas as heuristicas cegas). A correcao e preventiva para futuras adicoes de MDFCs.

**Acao recomendada:**
1. No script de importacao de Game Changers (Python): ao detectar `oracle_text IS NULL` apos importacao, tentar fallback com fuzzy search sem `//`:
   ```python
   if '//' in card_name:
       fallback_name = card_name.split('//')[0].strip()
       # Refazer Scryfall fuzzy search com fallback_name
   ```
2. Adicionar ao `gc_hash_check.py`: ao detectar `oracle_text IS NULL`, imprimir instrucao de correcao (nao apenas reportar).
3. No `tagCardForBracket()` Dart: adicionar warning via `developer.log` quando `oracleText` e vazio para uma carta que esta na lista de GCs (`_gameChangerNames`).

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
```

---

### [P2] Game Changer: Marcar `price_usd=NULL` de Reserved List explicitamente como `RESERVED_LIST` em vez de `NULL` — distingue "dado ausente" de "RL nao precifica"

**Conhecimento MTG:** O Gamechanger Research Report (Exec #7-#9, 2026-06-04/05) documenta que 8 cartas Reserved List tem `price_usd=NULL` no SQLite: Glacial Chasm, Humility, Intuition, Lion's Eye Diamond, Mishra's Workshop, Mox Diamond, Survival of the Fittest, The Tabernacle at Pendrell Vale. A Scryfall API retorna `null` para precos de cartas Reserved List intencionalmente (politica da plataforma). Tratar esse NULL como "dado faltante" e enganoso — o dado NAO esta faltando, a fonte deliberadamente nao o fornece. O sistema atual nao distingue "importacao falhou" de "RL sem preco".

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart` — A lista `_gameChangerNames` nao tem campo de preco. O preco e consumido apenas para exibicao (nao afeta logica de bracket).
- `scripts/gc_hash_check.py:93-97` — Detecta `price_usd IS NULL` mas nao distingue RL de falha de importacao.
- `rg "price_usd|reserved_list|RESERVED_LIST" server/lib/` — ZERO resultados. O backend nao le `price_usd` da tabela `game_changers`.

**Gap:** As 8 cartas RL com `price_usd=NULL` sao indistinguiveis de cartas onde a importacao de preco realmente falhou. Se uma carta nao-RL tiver `price_usd=NULL` por erro de rede/API, o sistema nao consegue diferenciar. O `gc_hash_check.py` reporta "NULL price_usd: 8" sem contexto, fazendo parecer que ha 8 falhas de importacao quando na verdade sao 0 falhas + 8 RL.

**Impacto:** `P2` — Baixo impacto funcional (preco nao afeta logica de bracket). Mas alto impacto na confiabilidade dos relatorios: operadores veem "8 NULL prices" e assumem falha de importacao. A distincao RL vs erro real e importante para diagnosticar problemas de integridade de dados.

**Risco:** P2 — Cosmetico/falso alarme. Nao afeta decisoes de swap ou bracket. Mas mascara falhas reais de importacao de preco para cartas nao-RL.

**Acao recomendada:**
1. Adicionar flag `is_reserved_list BOOLEAN DEFAULT 0` a tabela `game_changers` no SQLite.
2. No script de importacao, verificar se a carta esta na Reserved List (via Scryfall `reserved=true` ou lista estatica) e setar `is_reserved_list=1`.
3. No `gc_hash_check.py`, reportar `price_usd=NULL` separadamente para RL vs nao-RL.
4. Opcional: preencher `price_usd` com valor `-1` para RL (sentinel value) em vez de NULL, para queries nao precisarem de `IS NULL OR is_reserved_list=1`.

**Validacao:**
```bash
python3 -c "
import sqlite3
conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
rl = conn.execute('SELECT card_name FROM game_changers WHERE price_usd IS NULL AND is_reserved_list=1').fetchall()
non_rl = conn.execute('SELECT card_name FROM game_changers WHERE price_usd IS NULL AND is_reserved_list=0').fetchall()
print(f'RL sem preco: {len(rl)} (esperado: 8)')
print(f'Nao-RL sem preco: {len(non_rl)} (esperado: 0)')
"
```

---

### [P2] Mana Base Validator: Reportar contagem de `functional_tag=NULL` separadamente nos relatorios para evitar CRITs inflados por cartas nao classificadas

**Conhecimento MTG:** O MANA_BASE_VALIDATION_REPORT (2026-06-05) mostra que Yuriko tem `interaction=6 vs [10-16]` — CRIT d=4. Mas 21 das 84 cartas de Yuriko (25%) tem `functional_tag=NULL`. Cartas como Misdirection, Lim-Dul's Vault, e Commit // Memory podem ter funcao de interacao mas nao foram classificadas. O CRIT de interacao pode ser PARCIALMENTE INFLADO — parte do deficit de 4-10 cartas de interacao pode ser porque 21 cartas simplesmente nao tem tag, nao porque o deck realmente tem pouca interacao. O validador atual (MANA_BASE_VALIDATION_REPORT.md nota #4) reconhece isso em texto, mas a tabela de metricas mostra o CRIT sem contexto de untagged cards.

**Evidencia no codigo:**
- O script `_run_validation.py` executa `SUM(dc.quantity)` agrupado por `functional_tag`, mas **nao separa** a contagem de `functional_tag IS NULL`.
- `MANA_BASE_VALIDATION_REPORT.md` linha 15-19 — A tabela mostra metricas (lands, ramp, draw, interaction, etc.) sem coluna "untagged". O campo "untagged" so aparece em notas de rodape textuais.
- `server/lib/ai/functional_card_tags.dart:432-465` — `summarizeFunctionalTagsForDeck()` classifica cartas, mas cartas que caem no bucket `other` (sem tag) sao contadas como `otherRows`/`otherCopies` sem indicacao de que NAO foram classificadas.
- `server/lib/ai/optimization_validator.dart:28-86` — O validator usa `FunctionalDeckSummary` que tem `otherRows` mas nao distingue "classificado como utility" de "nao classificado".

**Gap:** Cartas sem `functional_tag` (NULL no SQLite) sao invisiveis nas metricas de role. O deficit aparente de uma role (ex: interaction=6 vs [10-16]) pode ser artificialmente inflado porque 25% das cartas nao tem tag. O operador ve "CRIT" e assume que o deck precisa de mais interacao, quando na verdade o problema pode ser que o classificador nao processou 21 cartas que SAO interacao.

**Impacto:** `P2` — CRITs podem ser falsos positivos (deficit inflado por untagged cards). O operador toma decisoes baseadas em metricas incompletas. Yuriko e o pior caso (25% untagged), mas Lorehold tambem tem 3/100 untagged.

**Risco:** P2 — Afeta a confiabilidade das metricas exibidas. Nao causa falhas funcionais (swaps nao sao bloqueados por isso), mas reduz a utilidade do relatorio para diagnostico humano.

**Acao recomendada:**
1. No script `_run_validation.py`: adicionar query separada para `SUM(dc.quantity) WHERE functional_tag IS NULL` por deck e incluir como coluna "untagged" na tabela de relatorio.
2. No `MANA_BASE_VALIDATION_REPORT.md`: adicionar coluna "Untagged" a tabela de Resumo Geral.
3. No status do deck: se `untagged >= 10% do total`, mostrar aviso de que metricas podem estar subestimadas.
4. No `FunctionalDeckSummary` (Dart): distinguir `untaggedRows`/`untaggedCopies` de cartas classificadas como `utility`/`other`.

**Validacao:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart
```

---

## Resumo de Tasks Novas (2026-06-05 @ 94b620a6 — Cron #8)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Deck Import: Validar completude (imported vs expected card count) | Commander Knowledge Deep S42-43 (Korvold 11/100, Kinnan 13/100) |
| 2 | P1 | Commander Selection: Query both `decks` AND `learned_decks` for `total_cards >= 90` | Multi-Commander Evolution aprendizado empirico |
| 3 | P2 | Game Changer Import: Auto-heal `oracle_text=NULL` via MDFC name fallback | Gamechanger Research #7-#9 (Tergrid resolvido, padrao preventivo) |
| 4 | P2 | Game Changer: Marcar `price_usd=NULL` de Reserved List como `RESERVED_LIST` | Gamechanger Research #7-#9 (8 cartas RL) |
| 5 | P2 | Mana Base Validator: Reportar `functional_tag=NULL` separadamente | MANA_BASE_VALIDATION_REPORT (Yuriko 25% untagged) |

> **Nota:** Tasks #1 e #2 sao complementares — ambas abordam a protecao do pipeline contra dados incompletos (import completeness + commander eligibility).
> **Nota:** Tasks #3 e #4 sao complementares — ambas melhoram a integridade dos dados de Game Changers (oracle_text MDFC + price_usd RL).
> **Nota:** Task #5 complementa a task pendente P2 "Tag Accuracy Auto-Healing" — enquanto aquela foca em melhorar a precisao das tags, esta foca em reportar a AUSENCIA de tags.


### [P1] Deck Import: Validar CMC das cartas importadas contra a tabela `cards` do PostgreSQL — previne corrupção de dados que afeta toda a pipeline de análise

**Conhecimento MTG:** O VALIDATOR_LOG v3.23 (2026-06-02) documenta corrupção massiva de CMC na importação do deck Lorehold: 14+ cartas com `CMC=0.0` (Sol Ring, Mana Vault, Boros Signet, Orim's Chant, etc.) e 6 cartas com `CMC=NULL` (Aetherflux Reservoir, Past in Flames, Electroduplicate, etc.). A CMC média reportada de 2.15 é subestimada — a CMC real do deck está ~2.8-3.0. Todos os cálculos downstream (curva de mana, Mulligan Simulation T3, GoldfishSimulator keepable, quality gate ΔCMC) são afetados.

**Evidencia no código:**
- `server/lib/deck_rules_service.dart:412-447` — `_loadCardsData()` consulta `id, name, type_line, oracle_text, colors, color_identity, mana_cost` da tabela `cards` do PG, mas **não consulta `cmc`**. A classe `_CardData` (linhas 484-502) não tem campo `cmc`.
- `server/lib/card_validation_service.dart:67-80` — `_findCard()` consulta apenas `id, name`. Sem validação de CMC.
- `server/lib/ai/optimization_quality_gate.dart:459-465` — `_getCmc()` retorna `0` silenciosamente quando `cmc` é `null` ou inválido, propagando dados corrompidos para o quality gate.
- `rg "cmc" server/lib/deck_rules_service.dart server/lib/card_validation_service.dart` → **ZERO resultados**. Nenhum serviço de validação verifica CMC.

**Gap:** Quando um deck é importado (via script Python ou API), os valores de CMC nas cartas não são validados contra a tabela `cards` do PostgreSQL (fonte autoritativa com 33.795 cartas). Cartas com CMC=0.0 ou CMC=NULL são aceitas sem warning, corrompendo todos os cálculos downstream: GoldfishSimulator (keepable/T3 rate inflado), quality gate (ΔCMC errado), filler loader (curva de mana errada), e mana base validator.

**Impacto:** `P1` — Dados corrompidos em cadeia. Swaps podem ser aprovados/rejeitados baseados em ΔCMC errado. O Mulligan Simulation reporta T3 inflado (mascara color screw). A análise de curva de mana mostra valores incorretos para o usuário. O problema é silencioso — não há logs, warnings, ou alertas.

**Risco:** P1 — Corrupção de dados se propaga para todas as camadas de análise sem detecção. Afeta diretamente a confiabilidade do optimize pipeline e da exibição de métricas para o usuário.

**Ação recomendada:**
1. Adicionar campo `final double? cmc` à classe `_CardData` em `deck_rules_service.dart:484-502`
2. Adicionar `cmc` ao SELECT em `_loadCardsData()` (linha 415): `SELECT id::text, name, type_line, oracle_text, colors, color_identity, mana_cost, cmc`
3. Em `_getCmc()` (optimization_quality_gate.dart:459-465), adicionar `developer.log` warning quando CMC é null/zero para cartas não-land:
   ```dart
   if (cmc == null || (cmc is num && cmc == 0)) {
     developer.log('WARNING: card has null/zero CMC', name: card['name']);
   }
   ```
4. Criar `validateCardCmc()` em `card_validation_service.dart` que compara o CMC importado contra o CMC do PG e retorna warning se diferir
5. No script Python de importação (`auto_sync_learned_decks.py`), sempre consultar `cards.cmc` do PG e usar esse valor como autoritativo

**Validação:**
```bash
cd server && dart analyze lib/deck_rules_service.dart
cd server && dart analyze lib/card_validation_service.dart
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/deck_rules_service_test.dart
```

---

### [P1] Quality Gate: Adicionar regras específicas para o arquétipo 'combo' em `_criticalRolesForArchetype` e `_looksLikeOffThemeRoleSwap`

**Conhecimento MTG:** O deck Lorehold sofreu pivot de spellslinger para cEDH stax-combo (documentado em VALIDATOR_LOG v3.23 e Commander Knowledge Deep #34-38). Decks combo têm papéis críticos diferentes de aggro/midrange/control: tutores, engines, wincons e proteção são essenciais; remoção e ramp são secundários. O Domain Skill documenta que decks combo priorizam velocidade e consistência do combo sobre interação com o board.

**Evidencia no código:**
- `server/lib/ai/optimization_quality_gate.dart:346-353` — `_criticalRolesForArchetype()` tem casos para 'aggro', 'control', 'midrange', e default `{'removal', 'ramp'}`. **Não há caso para 'combo'**. Quando o deck é classificado como combo, cai no default que trata remoção e ramp como críticos — errado para combo.
- `server/lib/ai/optimization_quality_gate.dart:355-382` — `_looksLikeOffThemeRoleSwap()` tem casos para 'aggro', 'control', 'midrange', e **sem default explícito** (retorna `false`). Swaps off-theme em decks combo nunca são detectados.
- `server/lib/ai/optimization_quality_gate.dart:170-176` — `_recommendedLandCountForArchetype()` retorna 33 lands para combo (correto para cEDH combo).
- `server/lib/ai/optimization_quality_gate.dart:232-244` — `_isStructuralRecoveryUpgrade()` tem casos para 'control', 'midrange', 'aggro', e default. 'combo' cai no default que é razoável, mas não otimizado.

**Gap:** Decks combo (incluindo cEDH stax-combo, turbo-naus, etc.) são avaliados contra papéis críticos genéricos (`removal`, `ramp`). Na realidade, decks combo precisam de: `tutor` (encontrar peças), `engine` (gerar valor), `wincon` (finalizar), `protection` (proteger o combo). O quality gate atual bloquearia um swap que troca remoção por tutor em deck combo (porque perde `removal` que é marcado como crítico), quando na verdade esse swap MELHORA o deck combo.

**Impacto:** `P1` — Swaps corretos para decks combo são bloqueados; swaps incorretos podem ser aprovados. Com o pivot do deck Lorehold para cEDH combo, este gap é empiricamente relevante AGORA (não é teórico). O optimize pipeline pode recomendar cortar tutores/engines por achar que remoção é mais importante.

**Risco:** P1 — Decisões incorretas do quality gate para um arquétipo inteiro (combo). Afeta todos os decks classificados como combo, não apenas Lorehold.

**Ação recomendada:**
1. Adicionar caso 'combo' em `_criticalRolesForArchetype`:
   ```dart
   'combo' => {'tutor', 'engine', 'wincon', 'protection'},
   ```
2. Adicionar caso 'combo' em `_looksLikeOffThemeRoleSwap`:
   ```dart
   if (normalized == 'combo' &&
       {'tutor', 'engine', 'wincon', 'protection'}.contains(removedRole) &&
       !{'tutor', 'engine', 'wincon', 'protection', 'ramp', 'draw'}.contains(addedRole)) {
     return true;
   }
   ```
3. Adicionar caso 'combo' em `_isStructuralRecoveryUpgrade` para permitir swaps land→tutor/engine/wincon em recuperação estrutural
4. Atualizar `_recommendedLandCountForArchetype` para diferenciar 'combo' (33 lands, ok) de 'cEDH' (27-30 lands) — manter 33 como fallback seguro

**Validação:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P2] Tag Accuracy Auto-Healing: Backend deve ler `tag_accuracy` do SQLite e disparar reavaliação de tags com baixa precisão

**Conhecimento MTG:** A tabela `tag_accuracy` no SQLite (`knowledge.db`) coleta métricas de qualidade da classificação funcional de cartas desde 2026-05-26. Dados atuais (2026-06-04):
- `last_updated` máximo = `2026-05-27T17:44:36Z` — **8+ dias sem atualizações**
- `payoff`: 11/31 corretos = **35.5% precisão** (worse tag)
- `enabler`: 21/42 corretos = **50% precisão**
- `wincon`: 6/8 corretos = 75%
- `protection`: 9/13 corretos = 69%
- `false_positive` e `false_negative` = **ZERO para TODAS as 22 linhas** (nunca foram preenchidos)
- **18 tags distintas** sem entrada em `tag_accuracy` (45% da taxonomia de 40 tags efetivas não monitorada)

O Commander Knowledge Skill documenta este congelamento desde 2026-06-04 como "8-Day Stagnation".

**Evidencia no código:**
- `rg "tag_accuracy" server/lib/ server/routes/` → **ZERO resultados**. Nenhum arquivo Dart lê ou escreve na tabela `tag_accuracy`.
- `server/lib/ai/functional_card_tags.dart:432-465` — `summarizeFunctionalTagsForDeck()` classifica cartas mas nunca verifica `tag_accuracy` para saber se a tag aplicada tem baixa precisão histórica.
- `server/lib/ai/optimization_functional_roles.dart:55-124` — `classifyOptimizationFunctionalRole()` aplica tags sem consultar qualidade histórica.
- `server/lib/ai/optimize_runtime_support.dart:2133-2200` — `inferFunctionalRole()` idem.

**Gap:** O sistema coleta dados de qualidade de classificação (`tag_accuracy`) mas nunca age sobre eles. Tags com 35.5% de precisão continuam sendo aplicadas sem warning. O pipeline de classificação não tem ciclo de feedback: classifica → mede qualidade → reavalia tags ruins → melhora. A qualidade da classificação está efetivamente congelada desde 27 de Maio.

**Impacto:** `P2` — Classificação de cartas não melhora com o tempo. Cartas mal classificadas (35.5% de precisão em `payoff`) geram recomendações de swap incorretas, análises de deck imprecisas, e métricas de role (ramp/draw/removal) erradas para o usuário.

**Risco:** P2 — Melhoria de qualidade. O sistema funciona sem isso, mas a precisão da classificação estagna. Afeta indiretamente a confiabilidade das recomendações de swap.

**Ação recomendada:**
1. Criar `tag_accuracy_service.dart` que:
   - Lê `tag_accuracy` do SQLite (`knowledge.db`) para encontrar tags com `correct_count/total_count < 0.70`
   - Para cada tag de baixa precisão, identifica cartas no PG `card_function_tags` ou SQLite `deck_cards` que têm essa tag
   - Dispara re-classificação dessas cartas usando `inferFunctionalCardTags()` com heurísticas atualizadas
   - Atualiza `tag_accuracy` com novos `correct_count`, `total_count`, `false_positive`, `false_negative`
   - Atualiza `last_updated` timestamp
2. Integrar ao cron `manaloom-tag-accuracy-reporter` ou criar endpoint `POST /api/tag-accuracy/re-evaluate`
3. (Futuro P3) Adicionar coluna `auto_re_evaluated_at` para tracking

**Validação:**
```bash
cd server && dart analyze lib/ai/tag_accuracy_service.dart
# Verificar que tag_accuracy.last_updated avançou após execução
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
rows = conn.execute('SELECT tag_name, correct_count, total_count, last_updated FROM tag_accuracy WHERE total_count > 0 ORDER BY CAST(correct_count AS REAL)/total_count ASC LIMIT 5').fetchall()
for r in rows: print(r)
"
```

---

### [P2] Quality Gate: Substituir `_recommendedLandCountForArchetype` hardcoded por consulta ao PG `commander_reference_profiles`

**Conhecimento MTG:** O MANA_BASE_VALIDATION_REPORT (2026-06-04) compara decks contra perfis EDHREC com ranges de lands por comandante:
- Aesi, Tyrant of Gyre Strait: lands **39-43** (landfall commander)
- Korvold, Fae-Cursed King: lands **34-37**
- Winota, Joiner of Forces: lands **31-35** (aggro)
- Atraxa, Praetors' Voice: lands **35-38**

O THEMES.md documenta que landfall precisa de 15-20 ramp + 39-43 lands, enquanto cEDH combo precisa de 27-33. O valor genérico de 35 lands mascara necessidades reais de decks específicos.

**Evidencia no código:**
- `server/lib/ai/optimization_quality_gate.dart:170-176` — `_recommendedLandCountForArchetype()` retorna valores hardcoded: aggro=34, combo=33, control=37, default=35.
- `server/lib/ai/optimization_quality_gate.dart:178-200` — `_computeLandTrimContext()` usa `_recommendedLandCountForArchetype` para calcular `excessLands`. Se o valor recomendado está errado, o `landTrimUpgrade` (linha 84-88) aprova/rejeita swaps incorretamente.
- `server/lib/ai/optimize_runtime_support.dart:3820-3846` — `loadCommanderReferenceProfileFromCache()` **já existe** e carrega `profile_json` com `role_targets` incluindo `lands: {min, max}`. Mas `_recommendedLandCountForArchetype()` **não a chama**.

**Gap:** Um deck Aesi com 40 lands (dentro do range ideal de 39-43) seria tratado pelo quality gate como tendo `excessLands = 40 - 35 = 5` (usando o default 35). O gate poderia aprovar swaps que removem lands de um deck que PRECISA de mais lands. Similarmente, um deck Winota com 31 lands (dentro do range 31-35) seria tratado como `excessLands = 31 - 35 = -4` (déficit), potencialmente bloqueando swaps spell→land que o deck precisa.

**Impacto:** `P2` — O quality gate toma decisões de land trim baseadas em valores genéricos que não refletem o comandante específico. Decks landfall são penalizados; decks aggro são tratados como se precisassem de mais lands. O `landTrimUpgrade` (uma das poucas exceções que permitem land→spell swaps) é aplicado incorretamente.

**Risco:** P2 — Melhoria de precisão. O sistema funciona com os valores genéricos, mas produz falsos positivos/negativos para comandantes com necessidades de land atípicas.

**Ação recomendada:**
1. `_computeLandTrimContext()` deve aceitar parâmetro opcional `String? commanderName`
2. Se `commanderName` for fornecido, chamar `loadCommanderReferenceProfileFromCache()` para obter `role_targets.lands` (min/max)
3. Usar `(min + max) ~/ 2` como `recommendedLandCount` quando disponível
4. Fallback para `_recommendedLandCountForArchetype()` hardcoded quando perfil não existir
5. Atualizar callers: `filterUnsafeOptimizeSwapsByCardData` precisa receber `commanderName` (ou extraí-lo dos commanders do deck)

**Validação:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

## Resumo de Tasks Novas (2026-06-04 @ 54480471 — Cron #7)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Deck Import: Validar CMC contra PG `cards` e adicionar warning em `_getCmc()` | VALIDATOR_LOG v3.23 (CMC corruption) |
| 2 | P1 | Quality Gate: Adicionar regras para arquétipo 'combo' em `_criticalRolesForArchetype` | Lorehold cEDH pivot + Commander Knowledge |
| 3 | P2 | Tag Accuracy Auto-Healing: Backend lê `tag_accuracy` do SQLite e dispara reavaliação | tag_accuracy frozen 8+ days (SQLite data) |
| 4 | P2 | Quality Gate: Usar PG `commander_reference_profiles` para land ranges em vez de hardcoded | MANA_BASE_VALIDATION_REPORT (per-commander lands) |

> **Nota:** Tasks #1 e #4 são complementares — ambas abordam a qualidade dos dados (CMC integrity na importação, land ranges no quality gate).
> **Nota:** Task #2 é empiricamente validada pelo pivot do Lorehold para cEDH combo (não é teórico).
> **Nota:** Task #3 aborda o congelamento do pipeline de qualidade de classificação (8+ dias sem atualizações em `tag_accuracy`).

---

### [P1] Optimize Pipeline: Adicionar verificacao de `discrepancies_found` no `run_log` antes de reutilizar analise em cache (Short-Circuit Staleness Detection)

**Conhecimento MTG:** O Domain Skill Gap 17 documenta que o mecanismo de short-circuit dos crons (responder [SILENT] quando o deck nao mudou) PERPETUA erros da ultima analise. Exemplo concreto: Validator v3.24 afirmou que Worldfire estava banida no Commander (FALSO — Scryfall confirma `commander=legal`). Como o deck nao mudou, o Validator retorna SILENT em TODAS as execucoes subsequentes (confirmado #64, 04/Jun). O erro de banlist fica permanentemente nos logs. NENHUM agente verifica "minha ultima analise estava correta?" antes do short-circuit. O Domain Skill recomenda: "Todo short-circuit deve incluir verificacao de `discrepancies_found > 0` no `run_log` da ultima execucao."

**Evidencia no codigo:**
- `server/lib/ai/optimization_validator.dart:28-86` — `OptimizationValidator.validate()` executa Monte Carlo + analise funcional + critic IA, mas NAO verifica se a ultima analise para este deck teve `discrepancies_found > 0`. Se o deck nao mudou e a analise anterior foi chamada externamente, o validator pode reutilizar resultados cacheados sem checar se havia erros.
- `rg "run_log" server/lib` → **ZERO resultados**. A tabela `run_log` existe no SQLite (`docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`) com campos `discrepancies_found`, `known_issues`, `execution_time`, `agent_name` — mas NENHUM arquivo Dart le essa tabela.
- `server/lib/ai/optimize_runtime_support.dart` — O pipeline de optimize (buildRoleTargetProfile, loadOptimizeFillerCandidateStubs) opera com dados cacheados do PG e nao verifica se a ultima analise do deck tinha discrepancias.

**Gap:** Quando o classificador foi corrigido (ramp tags 6→19) ou dados externos mudaram (banlist, EDHREC trends), o optimize pipeline continua usando analises antigas que podem conter erros factuais. O sistema nao tem codigo que diga: "a ultima analise deste deck tinha discrepancias — re-executar antes de recomendar swaps."

**Impacto:** `P1` — Swaps podem ser recomendados (ou bloqueados) baseados em analises com erros factuais. Exemplo: se a ultima analise dizia que uma carta estava banida (quando nao esta), o optimize pode evitar recomenda-la por meses, mesmo apos a correcao do banlist. O operador nao tem como saber que a analise esta stale.

**Risco:** P1 — Decisoes de swap baseadas em dados incorretos. Afeta diretamente a confiabilidade do pipeline de otimizacao.

**Acao recomendada:**
1. Criar `run_log_service.dart` com query que le o `run_log` do SQLite para um `deck_id` especifico
2. No `OptimizationValidator.validate()`, antes de executar Monte Carlo, consultar `run_log` para o deck:
   - Se `discrepancies_found > 0` na ultima execucao → pular short-circuit, forcar re-analise completa
   - Se `known_issues` contem erros nao resolvidos → flag como `stale_analysis: true`
3. Adicionar campo `staleAnalysis` ao `ValidationReport` para que o optimize pipeline possa decidir se confia ou nao nos resultados cacheados
4. No `buildRoleTargetProfile()`, verificar se os targets cacheados vieram de uma analise com discrepancias

**Validacao:**
```bash
cd server && dart analyze lib/ai/run_log_service.dart
cd server && dart analyze lib/ai/optimization_validator.dart
cd server && dart test test/ai/optimization_validator_test.dart
```

---

### [P1] `classifyOptimizationFunctionalRole`: Adicionar `functional_tags` persistidas como fonte primaria (unificar cadeia de prioridade com `FunctionalDeckSummary`)

**Conhecimento MTG:** O ManaLoom tem 3 classificadores diferentes no mesmo codebase: `inferFunctionalCardTags()` (multi-tag, 29 heuristicas, `functional_card_tags.dart:432-465`), `classifyOptimizationFunctionalRole()` (single-tag, quality gate, `optimization_functional_roles.dart:55-124`), e `inferFunctionalRole()` (single-tag, filler loader, `optimize_runtime_support.dart:2133-2179`). O Domain Skill Gap 6 documenta "duplo nulo" — 10%+ de cartas sao invisiveis a TODOS os classificadores simultaneamente. O Logic Coherence Audit (2026-05-29) identificou drift entre `functional_card_tags.dart` (que usa cadeia correta: `persisted functional_tags → semanticV2 → heuristic`) e `optimization_functional_roles.dart` (que usa apenas `semantic_tags_v2 → heuristic`, IGNORANDO `functional_tags` persistidas). A resolucao do classificador Python (v3.25) melhorou tags no SQLite (ramp 6→19), mas o codigo Dart ainda nao consulta esses dados persistidos.

**Evidencia no codigo:**
- `server/lib/ai/optimization_functional_roles.dart:55-58` — `classifyOptimizationFunctionalRole()` consulta APENAS `semantic_tags_v2` via `_classifySemanticV2FunctionalRole()`. Se `semantic_tags_v2` for null ou low-confidence, cai DIRETO para heuristicas de oracle text (linhas 63-124). NUNCA consulta `card['functional_tag']` (do SQLite `deck_cards`) nem `card['functional_tags']` (do PG `card_function_tags`).
- `server/lib/ai/functional_card_tags.dart:455-465` — `summarizeFunctionalTagsForDeck()` implementa a cadeia CORRETA: `persistedTags` (PG `card_function_tags`) → `semanticV2` → `inferredTags` (heuristicas). Esta cadeia produz resultados mais precisos porque `persistedTags` sao curadas/validadas.
- `server/lib/ai/optimize_runtime_support.dart:2133-2179` — `inferFunctionalRole()` (TERCEIRO classificador) usa APENAS heuristicas de oracle text. Cartas como Smothering Tithe (treasure ramp, classificada como `utility`), Aetherflux Reservoir (wincon via "pay 50 life", classificada como `engine`), e Sol Ring (classificado como `ramp` via `signet`/`talisman` substring check — na verdade e `sol ring`) sao mal classificadas.

**Gap:** `classifyOptimizationFunctionalRole` e usado pelo quality gate (`optimization_quality_gate.dart:52-53`) para decidir se um swap preserva o papel funcional. Se a carta removida e classificada como `utility` quando na verdade e `ramp`, o quality gate pode aprovar um swap que remove ramp — mesmo que `functional_tags` persistidas digam corretamente que a carta e `ramp`. O `FunctionalDeckSummary` (usado para analise/display) CLASSIFICA CORRETAMENTE a mesma carta, mas o quality gate usa um classificador DIFERENTE que erra.

**Impacto:** `P1` — O quality gate toma decisoes de swap baseadas em classificacao incorreta. Cartas essenciais podem ser marcadas como `utility` e sugeridas para remocao. O `FunctionalDeckSummary` mostra a classificacao correta (via cadeia de prioridade adequada), mas o gate usa outra — gerando inconsistencia visivel para o usuario ("deck summary diz ramp, mas optimize sugeriu cortar como filler").

**Risco:** P1 — Inconsistencia entre o que o sistema mostra ao usuario e o que o sistema usa para decidir. Swaps incorretos aprovados ou corretos bloqueados.

**Acao recomendada:**
1. `classifyOptimizationFunctionalRole()` deve aceitar parametro opcional `Map<String, dynamic>? cardData` com dados completos da carta (incluindo `functional_tag` e `functional_tags`)
2. Implementar cadeia de prioridade identica a `summarizeFunctionalTagsForDeck`:
   - 1º: `cardData['functional_tag']` (SQLite, single-tag) ou `cardData['functional_tags']` (PG, multi-tag)
   - 2º: `cardData['semantic_tags_v2']` (via `_classifySemanticV2FunctionalRole`)
   - 3º: Heuristicas de oracle text (fallback atual)
3. Atualizar callers (`optimization_quality_gate.dart:52-53`, `optimization_validator.dart`) para passar `cardData` completo
4. (Opcional, P2 futuro) Unificar `inferFunctionalRole()` com a mesma cadeia de prioridade

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_functional_roles.dart
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P2] `deck_learning_events`: Fechar o loop de aprendizado — Backend nunca le os eventos de aprendizado do PG

**Conhecimento MTG:** Os commits do master (70e170f0 "Harden Hermes learned deck sync" e anteriores) implementaram um pipeline de aprendizado: o App Flutter salva decks jogados → eventos sao escritos na tabela PG `deck_learning_events` → scripts Python (`auto_sync_learned_decks.py`, `auto_promote_learned_decks.py`) processam esses eventos e geram `learned_decks`. O modulo `deck_learning_event_support.dart` (novo no master) fornece `loadUsageHotCards()` e `buildUsageHotCardsPrompt()`. Porem, o backend Dart **nunca le `deck_learning_events` diretamente** — 0 referencias em `server/lib/`. O optimize pipeline nao sabe quais cartas o usuario realmente joga, quais tiveram bom desempenho, ou quais foram cortadas apos teste real.

**Evidencia no codigo:**
- `rg "deck_learning_event" server/lib` → **ZERO resultados**. A tabela `deck_learning_events` existe no PG (criada pelos scripts Python) mas nenhum arquivo Dart faz query nela.
- `server/lib/ai/deck_learning_event_support.dart` — Existe no master (commit 70e170f0) com funcoes `loadUsageHotCards()` e `buildUsageHotCardsPrompt()`, mas estas funcoes sao usadas apenas pelos scripts Python, nao pelo backend Dart.
- `server/lib/ai/optimize_runtime_support.dart` — O pipeline de optimize (`_scoreAggressiveCandidateQualityPair`, `loadOptimizeFillerCandidateStubs`) pontua candidatos baseado em `commander_card_synergy`, `card_role_scores`, e `meta_deck_count`. NENHUM uso de dados de aprendizado real do usuario.

**Gap:** O usuario joga com o deck, o App registra eventos de aprendizado, mas o optimize pipeline nunca usa esses dados para melhorar recomendacoes. Exemplo: se o usuario consistentemente corta uma carta que o optimize recomendou adicionar, o sistema nao aprende com isso — continua recomendando a mesma carta nos proximos ciclos. O loop de feedback usuario → sistema esta QUEBRADO no backend.

**Impacto:** `P2` — O optimize pipeline nao aprende com o uso real. Recomendacoes de swap nao melhoram com o tempo porque o sistema ignora o feedback do usuario. A funcionalidade de "learned decks" existe no master mas o backend nao a utiliza para otimizacao.

**Risco:** P2 — Melhoria de qualidade. O sistema funciona sem isso, mas perde a capacidade de aprender e se adaptar ao estilo do usuario.

**Acao recomendada:**
1. Criar `deck_learning_service.dart` que le `deck_learning_events` do PG para um `deck_id`
2. Extrair metricas: `cards_kept_after_test` (cartas que sobreviveram a testes reais), `cards_cut_after_test` (cartas removidas apos uso), `most_played_cards` (cartas mais usadas em partidas)
3. Integrar ao `AggressiveCandidateQualitySignal`:
   - Cartas `kept_after_test` → +10 bonus (validacao real)
   - Cartas `cut_after_test` → -20 penalty (feedback negativo real)
4. No optimize prompt, incluir secao "Your Recent Gameplay History" com dados de aprendizado

**Validacao:**
```bash
cd server && dart analyze lib/ai/deck_learning_service.dart
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P2] `card_deck_analysis`: Integrar scores de wincon (speed/resilience/stealth) do pipeline Python ao optimize quality gate

**Conhecimento MTG:** O pipeline Python (`scripts/analyze_deck_wincons.py` e relacionados) popuula a tabela PG `card_deck_analysis` com scores de wincon por carta: `speed_score` (quao rapida a wincon e), `resilience_score` (quao dificil de interromper), `stealth_score` (quao "invisivel" — nao obvia para oponentes). O Scout (Exec #38) usa esses scores para priorizar wincons: RAPIDAS (S>=6), IMBATIVEIS (R>=7), INVISIVEIS (ST>=7). O Domain Skill documenta que `card_deck_analysis` e "NOT yet read by backend". Isso e complementar a tarefa pendente sobre `card_deck_profiles` (que tem perfis por carta) — `card_deck_analysis` tem scores DE NIVEL ESTRATEGICO para o deck como um todo.

**Evidencia no codigo:**
- `rg "card_deck_analysis" server/lib` → **ZERO resultados**. A tabela existe no PG mas nenhum arquivo Dart faz query nela.
- `server/lib/ai/optimization_quality_gate.dart:34-101` — O quality gate filtra swaps baseado em role preservation, CMC delta, e structural recovery. NAO considera se a carta removida e uma wincon INVISIVEL (stealth alto) ou se a carta adicionada e uma wincon FRAGIL (resilience baixa).
- `server/lib/ai/optimization_validator.dart:28-86` — O validator executa Monte Carlo e analise funcional, mas nao avalia a QUALIDADE das wincons (speed/resilience/stealth).

**Gap:** O optimize pode recomendar cortar uma wincon com stealth_score=8 (INVISIVEL, como Guttersnipe — stealth_score=8 no DB) e substituir por uma wincon com resilience_score=2 (FRAGIL). O quality gate nao tem regras para prevenir isso porque nao le `card_deck_analysis`. Similarmente, o sistema nao prioriza adicionar wincons com resilience alta (IMBATIVEIS) quando o deck precisa de resiliencia.

**Impacto:** `P2` — Qualidade dos swaps reduzida. Wincons "invisiveis" (dificeis de prever) podem ser cortadas em favor de wincons "obvias" (faceis de interromper). O optimize perde a capacidade de balancear speed vs resilience vs stealth.

**Risco:** P2 — Melhoria de qualidade. O sistema funciona, mas as recomendacoes de swap sao menos informadas estrategicamente.

**Acao recomendada:**
1. Criar `card_deck_analysis_service.dart` com query que carrega `wincon_total_score`, `speed_score`, `resilience_score`, `stealth_score` para cada carta no deck
2. Integrar ao quality gate (`optimization_quality_gate.dart`):
   - Regra: nao cortar wincons com `stealth_score >= 7` (INVISIVEIS)
   - Regra: nao cortar wincons com `resilience_score >= 7` (IMBATIVEIS) a menos que substituida por wincon de resilience similar
   - Regra: priorizar adicoes com `speed_score >= 6` em decks aggro/combo
3. Adicionar campos `winconSpeed`, `winconResilience`, `winconStealth` ao `AggressiveCandidateQualitySignal` (ja existente em `optimize_runtime_support.dart:2433-2479`)

**Validacao:**
```bash
cd server && dart analyze lib/ai/card_deck_analysis_service.dart
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P2] `GoldfishSimulator`: Adicionar validacao de requisitos de cor (color requirements) na definicao de mao keepable

**Conhecimento MTG:** O Domain Skill Gap 9 documenta que o Mulligan Simulation NAO verifica requisitos de cor: "Mao com 3 Mountains + spells brancos e considerada 'jogavel' → ~3-8pp de superestimacao." O pipeline de mulligan (Execucoes #4-#15) define mao "jogavel" como "2-4 lands AND (ramp >= 1 OR lands >= 3)" mas essa definicao (usada pelos crons Python) tambem ignora cor. A tarefa pendente #8 (GoldfishSimulator: Tapped lands) e a tarefa #5 da sintese anterior (GoldfishSimulator: ramp em keepable) abordam keepable — mas NENHUMA tarefa cobre requisitos de cor. Este e o terceiro e ultimo componente para tornar o keepable realistico.

**Evidencia no codigo:**
- `server/lib/ai/goldfish_simulator.dart:131,156` — A definicao atual de keepable: `if (landsInHand >= 2 && landsInHand <= 5) keepableHands++`. Nao ha NENHUMA verificacao de se as lands na mao conseguem produzir as cores necessarias para conjurar as spells na mao.
- `server/lib/ai/goldfish_simulator.dart` — O simulador tem acesso ao `type_line` e `oracle_text` de cada carta (via `cardData`), mas nao extrai `color_identity` nem `mana_cost` para verificar viabilidade de cor.
- `server/lib/ai/optimization_validator.dart:37-40` — `_runMonteCarloComparison()` chama `GoldfishSimulator` e usa `consistencyScore` (que pesa `keepableRate` como 40%). Keepable inflado = consistencyScore inflado = quality gate aprova swaps que pioram a consistencia real.

**Gap:** O `GoldfishSimulator` superestima a taxa de keepable porque ignora color screw. Uma mao com 3 Mountains, 1 Path to Exile (W), 1 Swords to Plowshares (W), 1 Boros Charm (RW), e 1 Lorehold (RW) e considerada "keepable" (3 lands, 2-5 range) — mas na pratica e injogavel porque nenhuma land produz White. Isso infla o `consistencyScore` e mascara problemas de mana base nos swaps.

**Impacto:** `P2` — Swaps que pioram a mana base (ex: trocar 1 Plateau por 1 Mountain) nao sao detectados porque o keepable rate nao muda. O validator aprova swaps que criam color screw porque o `GoldfishSimulator` e cego a cores.

**Risco:** P2 — Melhoria de precisao. Complementar as tarefas pendentes #5 (ramp em keepable) e #8 (tapped lands). Juntas, as 3 correcoes transformam o keepable de "simplista" para "realista".

**Acao recomendada:**
1. Adicionar `_extractManaCost(card)` helper que extrai o custo de mana como lista de simbolos
2. Adicionar `_extractLandColors(card)` helper que extrai as cores produzidas por uma land (do `oracle_text`: "{T}: Add {R}" → produz Red)
3. Na funcao `_isKeepable()`, apos verificar lands e ramp, adicionar:
   - Extrair todas as spells nao-land da mao
   - Extrair todas as cores que as lands na mao podem produzir
   - Verificar se TODAS as spells tem pelo menos 1 fonte de cada cor necessaria
   - Se nao → nao e keepable (color screw)
4. Implementar como metodo separado `_hasColorScrew(hand)` para facilidade de teste

**Validacao:**
```bash
cd server && dart analyze lib/ai/goldfish_simulator.dart
cd server && dart test test/ai/goldfish_simulator_test.dart
```

---

## Resumo de Tasks Novas (2026-06-04 @ 03e09d30)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Short-Circuit Staleness Detection — `run_log.discrepancies_found` check no validator | Domain Skill Gap 17 (NOVO) |
| 2 | P1 | `classifyOptimizationFunctionalRole` — Unificar com `functional_tags` persistidas | Domain Skill Gap 6 + Logic Coherence Audit (generalizacao pendente #2) |
| 3 | P2 | `deck_learning_events` — Fechar loop de aprendizado no backend | Master commits 70e170f0 + 0 refs em server/lib (NOVO) |
| 4 | P2 | `card_deck_analysis` — Integrar wincon speed/resilience/stealth ao quality gate | Scout #38 + 0 refs em server/lib (NOVO) |
| 5 | P2 | `GoldfishSimulator` — Adicionar validacao de color requirements ao keepable | Domain Skill Gap 9 (NOVO, complementar a pendentes #5 e #8) |

## Tasks Anteriores (ainda pendentes das execucoes 2026-06-04 @ 22787279, @ d2ca5234, @ 498eb1a8)

| # | Prioridade | Task |
|:-:|:----------|:-----|
| 1 | P1 | Bracket Policy: Adicionar 7 categorias ao `BracketCategory` enum (29/53 GCs nao detectados) |
| 2 | P1 | `buildRoleTargetProfile`: Usar PG `commander_reference_profiles` + `theme_contextual_rules` |
| 3 | P1 | `ThemeContextualRulesService.validateDeck()`: Detectar archetype mismatch |
| 4 | P1 | Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap |
| 5 | P1 | Battle Simulator: Implementar regras Commander (stack, multiplayer, etc.) |
| 6 | P1 | Goldfish Simulator: Tapped lands (complementa Task #5 nova) |
| 7 | P1 | Optimize/Archetypes: Owner-scoped deck queries |
| 8 | P2 | `inferFunctionalRole()`: Consultar `card_function_tags` persistidas antes de heuristicas |
| 9 | P2 | `card_deck_profiles` (1299 perfis PG): Integrar ao backend — tabela nunca lida |
| 10 | P2 | `GoldfishSimulator`: Adicionar ramp/mana rocks na definicao de keepable |
| 11 | P2 | Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica |
| 12 | P2 | Candidate Quality: Adicionar `edhrec_trend_zscore` como fator de scoring |
| 13 | P2 | Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'` |
| 14 | P2 | Activation Funnel: Sync `_allowedEvents` app-backend |

> **Nota:** Tasks #5 nova (color requirements), #6 pendente (tapped lands) e #10 pendente (ramp keepable) sao complementares — todas melhoram o `GoldfishSimulator`. Implementar juntas.
> **Nota:** Task #2 nova (classifier unification) generaliza a pendente #8 (`inferFunctionalRole`) e a pendente antiga sobre `classifyOptimizationFunctionalRole` — unificar os 3 classificadores em uma cadeia de prioridade unica.


### [P1] `buildRoleTargetProfile`: Substituir hardcoded archetype targets por PG `commander_reference_profiles` + `theme_contextual_rules`

**Conhecimento MTG:** O pipeline Hermes (Purpose Analyzer v3.25) documenta que decks podem mudar de arquetipo (ex: spellslinger -> cEDH fast-mana-combo). O PG tem 48+ `commander_reference_profiles` com `role_targets` (min/max por role como lands 33-35, ramp 8-12, draw 6-10, etc.) e 27 `theme_contextual_rules` com faixas por funcao por tema. O Domain Skill (Gap 4) documenta que o validator deve usar ranges especificos por tema, nao genericos.

**Evidencia no codigo:** `server/lib/ai/optimize_runtime_support.dart:763-793` — `buildRoleTargetProfile(String targetArchetype)` usa apenas 3 arquetipos hardcoded (aggro, control, combo) com valores estaticos (`ramp: 10, draw: 10, removal: 8, interaction: 6, engine: 8, wincon: 4, utility: 8`). A funcao nunca consulta PG `commander_reference_profiles` nem `theme_contextual_rules`. O `optimize_runtime_support.dart:3820-3846` ja tem `loadCommanderReferenceProfileFromCache()` que carrega `profile_json` do PG — mas `buildRoleTargetProfile()` NAO a chama.

**Gap:** O optimize pipeline usa targets genericos que nao refletem o comandante especifico nem o tema do deck. Um deck cEDH Lorehold (ramp=19, draw=9, wincon=10) e avaliado contra targets de "combo generico" (ramp=11, draw=12, wincon=5) em vez dos ranges do perfil PG especifico. O filler loader (`loadOptimizeFillerCandidateStubs`, linha 2775-2848) usa `buildRoleTargetProfile` para calcular `surplus` (line 2831) — targets errados produzem recomendacoes de corte erradas.

**Impacto:** `P1` — O optimize recomenda cortes baseados em targets incorretos. No caso Lorehold cEDH, targets genericos de "combo" dizem ramp=11 (deck tem 19 surplus=8), sugerindo cortar 8 fontes de ramp que sao ESSENCIAIS para o funcionamento cEDH. Os targets do perfil PG especifico evitariam esse falso positivo.

**Acao recomendada:**
1. `buildRoleTargetProfile()` deve aceitar `commanderName` como parametro
2. Chamar `loadCommanderReferenceProfileFromCache()` para carregar `role_targets` do perfil PG
3. Fallback para `theme_contextual_rules` (ja carregadas via `ThemeContextualRulesService`) se perfil nao existir
4. Manter os valores hardcoded APENAS como ultimo fallback
5. Atualizar `buildSlotNeedsForDeck()` (line 795) para passar `commanderName`

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P1] `ThemeContextualRulesService.validateDeck()`: Adicionar deteccao de archetype mismatch antes da validacao

**Conhecimento MTG:** O Purpose Analyzer v3.25 documenta que quando um deck e reconstruido para um arquetipo diferente (spellslinger -> cEDH fast-mana-combo), TODAS as metricas ficam fora do range do perfil PG original. Reportar 10/10 CRITs e enganoso — o problema nao e o deck, e o mismatch de arquetipo. O Domain Skill (Gap 4) recomenda: "Validator deve detectar mudanca de arquetipo (comparar `decks.archetype` contra os temas do perfil PG) e reportar como `ARCHETYPE MISMATCH` ao inves de CRITs individuais."

**Evidencia no codigo:** `server/lib/ai/optimization_validator.dart:52-64` — `ThemeContextualRulesService.validateDeck()` e chamado sem verificacao previa de compatibilidade de arquetipo. `server/lib/ai/theme_contextual_rules_service.dart:50-108` — O servico carrega regras por `theme` mas nao compara o `theme` do deck contra o `theme` esperado pelo perfil PG. O `loadCommanderReferenceProfileFromCache()` em `optimize_runtime_support.dart:3820` carrega `profile_json` que contem `themes` — mas ninguem compara esses temas com o `archetype` atual do deck.

**Gap:** Quando o deck Lorehold foi reconstruido de spellslinger para cEDH combo, `themeService?.validateDeck(archetype: archetype, ...)` recebeu `archetype='fast-mana-copy-combo-big-spells-no-premium-mox'` mas validou contra regras do tema `spellslinger` (porque o perfil PG e spellslinger). O sistema nao tem codigo que diga: "este deck nao e mais spellslinger, o perfil nao se aplica."

**Impacto:** `P1` — O validator produz CRITs em massa que enterram problemas reais. No caso v3.25, 10/10 metricas mostraram CRIT. O operador nao consegue distinguir "deck quebrado" de "deck de arquetipo diferente". Isso desperdica atencao e reduz confianca no validator.

**Acao recomendada:**
1. `ThemeContextualRulesService.validateDeck()` deve aceitar `profileThemes` como parametro opcional
2. Antes de validar, comparar `deckArchetype` contra `profileThemes`: se overlap < 50%, retornar `ThemeValidationResult(theme: 'mismatch', hasCriticalViolation: false)` com flag `archetypeMismatch: true`
3. No `optimization_validator.dart`, se `themeValidation.archetypeMismatch == true`, reportar como `ARCHETYPE MISMATCH` em vez de CRITs individuais
4. Adicionar campo `archetypeMismatch` ao `ThemeValidationResult`

**Validacao:**
```bash
cd server && dart analyze lib/ai/theme_contextual_rules_service.dart
cd server && dart analyze lib/ai/optimization_validator.dart
cd server && dart test test/ai/optimization_validator_test.dart
```

---

### [P2] `inferFunctionalRole()` (3o classificador): Consultar `card_function_tags` persistidas antes de heuristicas

**Conhecimento MTG:** O ManaLoom tem 3 classificadores diferentes no mesmo codebase: `inferFunctionalCardTags()` (multi-tag, 29 heuristicas), `classifyOptimizationFunctionalRole()` (single-tag, quality gate), e `inferFunctionalRole()` (single-tag, filler loader). O Domain Skill (Gap 6) documenta que o classificador tem "duplo nulo" — 10%+ de cartas invisiveis a ambos os classificadores. A resolucao do classificador (v3.25) melhorou tags no DB (ramp 6->19), mas o codigo Dart ainda nao consulta esses dados persistidos. O Logic Coherence Audit (2026-05-29) identificou drift entre `functional_card_tags.dart` e `optimization_functional_roles.dart` (P1 pendente).

**Evidencia no codigo:** `server/lib/ai/optimize_runtime_support.dart:2133-2200` — `inferFunctionalRole()` e um TERCEIRO classificador, separado dos outros dois. Ele usa APENAS heuristicas de oracle text (ramp via `add {`, draw via `draw a card`, removal via `destroy target`, interaction via `counter target`, wincon via `you win the game`). NENHUMA consulta a `card_function_tags` (PG) ou `card_tags` (SQLite). NENHUM uso de `semantic_tags_v2`.

**Gap:** `inferFunctionalRole()` e chamado pelo filler loader (`loadOptimizeFillerCandidateStubs`, linha 2802-2807) para classificar TODAS as cartas do deck durante a deteccao de fillers. Cards como Smothering Tithe (treasure ramp) sao classificados como `utility` porque nao contem `add {` nem `draw a card` — caem no fallback da linha 2199. Cards como Aetherflux Reservoir (wincon, "pay 50 life") nao sao detectados como wincon porque nao contem "you win the game".

**Impacto:** `P2` — O filler loader identifica cards para remocao baseado em classificacao incorreta. Cards classificados como `utility` quando sao na verdade `ramp` ou `wincon` podem ser erroneamente sugeridos para corte pelo optimize.

**Acao recomendada:**
1. `inferFunctionalRole()` deve aceitar parametro opcional `Map<String, dynamic>? cardData` com dados completos da carta
2. Primeiro verificar `cardData['functional_tag']` (do SQLite `deck_cards`) — se disponivel, usar como fonte primaria
3. Segundo, verificar `cardData['semantic_tags_v2']` (como `classifyOptimizationFunctionalRole` ja faz)
4. Terceiro, cair para heuristicas de oracle text (fallback atual)
5. Alternativa: unificar os 3 classificadores em uma unica funcao `classifyCardRole()` com prioridade explicita

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
```

---

### [P2] `card_deck_profiles` (PG, 1299 perfis): Integrar ao backend — tabela nunca lida

**Conhecimento MTG:** O pipeline Python importa analises de deck para a tabela PG `card_deck_profiles` (1299 perfis de carta por deck, com campos: `card_name`, `role_in_deck`, `importance_level`, `wincon_total_score`, `speed_score`, `resilience_score`, `stealth_score`). O Scout (#38) usa esses scores para priorizar wincons (RAPIDAS S>=6, IMBATIVEIS R>=7, INVISIVEIS ST>=7). O Domain Skill documenta que `card_deck_profiles` "NOT yet read by backend".

**Evidencia no codigo:** `rg "card_deck_profile" server/lib` -> **ZERO resultados**. A tabela existe no PG com 1299 linhas, e populada pelo script Python `scripts/import_card_profiles.py`, mas NENHUM arquivo Dart faz query nela. O `AggressiveCandidateQualitySignal` (optimize_runtime_support.dart:2433-2479) tem campos `roleScore`, `synergyScore`, `functionConfidence` — mas todos sao populados de outras fontes (card_role_scores, commander_card_synergy), nao de `card_deck_profiles`.

**Gap:** 1299 perfis de carta analisados pelo pipeline Python (com scores de wincon, engine, importancia estrategica) estao disponiveis no PG mas sao completamente ignorados pelo backend Dart. O optimize pipeline nao sabe, por exemplo, que Guttersnipe tem `wincon_total_score=19, stealth_score=8` (INVISIVEL) ou que Mizzix's Mastery tem `resilience_score=7` (IMBATIVEL).

**Impacto:** `P2` — O optimize pipeline perde a capacidade de distinguir wincons "invisiveis" (stealth alto) de wincons "frageis" (resilience baixa). O quality gate nao pode aplicar regras como "nao cortar INVISIVEIS (ST>=7)" ou "priorizar IMBATIVEIS (R>=7)".

**Acao recomendada:**
1. Criar `card_deck_profiles_service.dart` com query que carrega perfis por `deck_id`
2. Integrar ao `AggressiveCandidateQualitySignal` como campos opcionais: `winconSpeed`, `winconResilience`, `winconStealth`
3. No `_scoreAggressiveCandidateQualityPair()` (line 2501), adicionar bonus: `stealth >= 7` -> +15, `resilience >= 7` -> +15
4. No quality gate, adicionar regra: nao cortar cartas com `importance_level >= 4`

**Validacao:**
```bash
cd server && dart analyze lib/ai/card_deck_profiles_service.dart
cd server && dart test test/ai/candidate_quality_test.dart
```

---

### [P2] `GoldfishSimulator`: Adicionar verificacao de ramp/mana rocks na definicao de keepable

**Conhecimento MTG:** O pipeline de simulacao de mulligan (Execucoes #4-#15) define mao "jogavel" como: **"2-4 lands AND (ramp >= 1 OR lands >= 3)"**. Esta definicao rigorosa reconhece que maos com 2 lands e SEM ramp sao efetivamente nao-jogaveis (~22% das maos em um deck de 35 lands). A diferenca entre a definicao permissiva (2-5 lands, sem ramp) e a rigorosa e de ~20pp na taxa de keepable, afetando diretamente as recomendacoes de swap. O Domain Skill documenta a metodologia completa.

**Evidencia no codigo:** `server/lib/ai/goldfish_simulator.dart:131,156` — A definicao atual e puramente baseada em lands: `if (landsInHand >= 2 && landsInHand <= 5) keepableHands++`. Nao ha NENHUMA verificacao de ramp, mana rocks, ou aceleracao. `server/lib/ai/goldfish_simulator.dart:340-354` — `_playLandIfPossible()` nao rastreia se a terra entra tapped.

**Gap:** O `GoldfishSimulator` superestima a taxa de keepable em ~20pp (2-5 lands = ~71% vs rigoroso = ~50%). O `consistencyScore` (line 32-39) pesa `keepableRate` como 40% do score total — keepable errado produz consistencyScore errado. O quality gate (`optimization_quality_gate.dart:412-415`) usa `monteCarlo.consistencyScore` para aprovar/rejeitar swaps.

**Impacto:** `P2` — Swaps que pioram a consistencia real podem ser aprovados porque o consistencyScore esta inflado. Exemplo: trocar um mana rock CMC 2 por uma carta CMC 4 sem ramp. O GoldfishSimulator atual diria que a mao ainda e "keepable" (2-5 lands), mas na definicao rigorosa a mao com 2 lands e sem ramp NAO e keepable — e remover o mana rock torna essa situacao mais provavel.

**Acao recomendada:**
1. Adicionar `_isManaSource()` helper que verifica se uma carta produz mana (ramp, rock, ritual)
2. Alterar keepable para: `landsInHand >= 2 && landsInHand <= 4 && (rampCount >= 1 || landsInHand >= 3)`
3. `rampCount` = contar cartas na mao que sao fontes de mana (via `_isManaSource()`)
4. Manter flood em `landsInHand >= 6` e screw em `landsInHand <= 1`

**Validacao:**
```bash
cd server && dart analyze lib/ai/goldfish_simulator.dart
cd server && dart test test/ai/goldfish_simulator_test.dart
```

---

## Resumo de Tasks Novas (2026-06-04 @ 22787279)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | `buildRoleTargetProfile`: Usar PG `commander_reference_profiles` + `theme_contextual_rules` em vez de hardcoded | Validator v3.25 (archetype mismatch) |
| 2 | P1 | `ThemeContextualRulesService.validateDeck()`: Detectar archetype mismatch antes da validacao | Validator v3.25 + Domain Skill Gap 4 |
| 3 | P2 | `inferFunctionalRole()`: Consultar `card_function_tags` persistidas antes de heuristicas | Domain Skill Gap 6 + Logic Coherence Audit |
| 4 | P2 | `card_deck_profiles` (1299 perfis PG): Integrar ao backend (tabela nunca lida) | Scout #38 + Domain Skill |
| 5 | P2 | `GoldfishSimulator`: Adicionar ramp/mana rocks na definicao de keepable | Pipeline Mulligan (Execucoes #4-#15) + Domain Skill Gap 9 |

## Tasks Anteriores (ainda pendentes das execucoes 2026-06-04 @ d2ca5234 e @ 498eb1a8)

| # | Prioridade | Task |
|:-:|:----------|:-----|
| 1 | P1 | Bracket Policy: Adicionar 7 categorias ao `BracketCategory` enum (29/53 GCs nao detectados) |
| 2 | P1 | `classifyOptimizationFunctionalRole`: Usar `functional_tags` persistidas como fonte primaria |
| 3 | P1 | Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap |
| 4 | P2 | Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica |
| 5 | P2 | Candidate Quality: Adicionar `edhrec_trend_zscore` como fator de scoring |
| 6 | P2 | Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'` |
| 7 | P1 | Battle Simulator: Implementar regras Commander (stack, multiplayer, etc.) |
| 8 | P1 | Goldfish Simulator: Tapped lands (complementa Task #5 nova) |
| 9 | P1 | Optimize/Archetypes: Owner-scoped deck queries |
| 10 | P2 | Activation Funnel: Sync `_allowedEvents` app-backend |

> **Nota:** Tasks #5 nova (keepable com ramp) e #8 pendente (tapped lands) sao complementares — ambas melhoram o `GoldfishSimulator`. Implementar juntas.
> **Nota:** Tasks #4 nova (card_deck_profiles) e #4/#5 pendentes (edhrec_inclusion_pct + trend_zscore) sao complementares — todas populam e leem `card_deck_profiles` com dados do EDHREC.

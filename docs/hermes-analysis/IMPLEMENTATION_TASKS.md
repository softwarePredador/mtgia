# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> Status atual: backlog grande de implementacao.
> Use como fila de ideias/tarefas, nao como prova de estado atual. Revalide
> contra codigo vivo antes de executar.

> **Gerado:** 2026-06-06 por ManaLoom Knowledge Synthesis (Cron #11)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 565b73af
> **Metodo:** Cruzamento do conhecimento MTG (VALIDATOR_LOG 2026-06-02 — pipeline integrity crisis + CMC corruption, GAME_CHANGERS.md — 53 GCs com double-counting detectado, SCOUT_LOG — Lorehold maturity, TAG_ACCURACY — payoff 35% accuracy) com codigo Dart (edh_bracket_policy, optimization_quality_gate, optimization_functional_roles, goldfish_simulator)
> **Base de conhecimento:** VALIDATOR_LOG (deck rebuild + 37 CMCs corrompidos + 20 unknown tags + only 3 removals), GAME_CHANGERS (53 GCs com 23 double-tagged), tag_accuracy (payoff 35%, enabler 50%), SCOUT_LOG (deck em maturidade persistente)
> **Novas tasks nesta execucao:** 5 (1xP1, 4xP2) — Game Changer double-counting fix, payoff tag accuracy improvement, contextual enabler/payoff heuristics, goldfish CMC validation hardening, GC list sync mechanism
> **Atualizacao Codex 2026-06-06:** P1 Game Changer double-counting foi reavaliado contra o codigo vivo. A politica atual preserva `gameChanger` + papeis secundarios (`fastMana`, `tutor`, `freeInteraction`, `infiniteCombo`) para diagnostico e budgets multi-tag; testes em `server/test/optimize_runtime_support_test.dart` e `server/test/edh_bracket_policy_test.dart` cobrem Mana Vault, Demonic Tutor, Force of Will e Thassa's Oracle.
> **Atualizacao Codex 2026-06-06:** P2 payoff/enabler contextual resolvido em `server/lib/ai/optimization_functional_roles.dart`; testes em `server/test/optimization_quality_gate_test.dart` cobrem spellslinger, aristocrats e tokens.
> **Atualizacao Codex 2026-06-06:** P2 goldfish CMC hardening resolvido em `server/lib/ai/cmc_safety.dart`; `GoldfishSimulator`, `OptimizationValidator` e `OptimizationSwapGate` agora recuperam CMC pelo `mana_cost` quando o CMC bruto esta corrompido e tratam CMC desconhecido non-land como custo alto, nunca como carta gratis.
> **Atualizacao Codex 2026-06-06:** P2 Game Changer drift guard resolvido com bloco Dart gerado a partir do SQLite, script `docs/hermes-analysis/manaloom-knowledge/scripts/sync_game_changers_to_dart.py --check` e teste cobrindo lista com 53 entradas + nome MDFC de Tergrid.
> **Atualizacao Codex 2026-06-09:** P1 Job Polling NULL `user_id` resolvido no backend. `OptimizeJob` e `AiGenerateJob` agora usam `userId` non-nullable no modelo, rows legadas com `user_id=NULL` viram owner vazio e os pollers `/ai/optimize/jobs/:id` e `/ai/generate/jobs/:id` retornam 404 para jobs sem dono ou de outro usuario. `AiGenerateJobStore.create` exige `required String userId`, e a rota async de generate retorna `Authentication required` antes de criar job sem usuario. Testes: `ai_optimize_authorization_source_test.dart`, `ai_generate_job_authorization_source_test.dart`, `ai_generate_performance_support_test.dart`.

### [P1][OBSOLETO/RESOLVIDO COMO MULTI-TAG] Bracket Policy: double-counting de Game Changers

**Status em 2026-06-11:** OBSOLETO como tarefa de implementacao. A premissa "somente `gameChanger`" foi substituida pela estrategia multi-tag: cartas oficiais Game Changer preservam `gameChanger` e tambem papeis mecanicos secundarios. Isso e usado como diagnostico/budget de risco, nao como erro de regra. Nao alterar o codigo para early-return exclusivo sem nova decisao de produto.

**Evidencia viva:**
- `server/test/optimize_runtime_support_test.dart` — `preserves secondary tags for official Game Changers` espera `gameChanger` + papel secundario.
- `server/test/optimize_runtime_support_test.dart` — `game changer budget also consumes secondary role budgets` valida budget multi-tag.
- `server/test/edh_bracket_policy_test.dart` — `keeps official gamechanger names tagged without suppressing roles`.

**Conclusao operacional:** manter esta secao apenas como historico do problema original. A acao recomendada antiga abaixo nao deve ser executada.

**Conhecimento historico original:** esta tarefa nasceu de uma leitura inicial de que Game Changers deveriam consumir apenas budget de GC. A politica atual do ManaLoom divergiu disso de proposito: `gameChanger` e uma tag oficial, mas papeis secundarios continuam preservados para explicar risco funcional e limitar concentracao de fast mana/tutor/free interaction quando a decisao de produto assim exigir.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:101-103` — `_fastManaNames` check adiciona `fastMana`.
- `server/lib/edh_bracket_policy.dart:111-113` — Oracle 'search your library' adiciona `tutor`.
- `server/lib/edh_bracket_policy.dart:140-143` — `_gameChangerNames` check adiciona `gameChanger`.
- O codigo nao tem EARLY RETURN apos detectar `gameChanger`. Os checks sao sequenciais e acumulativos — uma carta recebe TODAS as categorias que derem match.

**Simulacao confirmada:** 23 das 53 cartas GCs (43%) sao double-tagged:
- 6 fast mana GCs (Ancient Tomb, Chrome Mox, Grim Monolith, Lion's Eye Diamond, Mana Vault, Mox Diamond) → `fastMana` + `gameChanger`
- 12 tutor GCs (Demonic Tutor, Vampiric, Mystical, Enlightened, Worldly, Gamble, Gifts Ungiven, Intuition, Imperial Seal, Crop Rotation, Natural Order, Survival) → `tutor` + `gameChanger`
- 4 free interaction GCs (Force of Will, Fierce Guardianship, Bolas's Citadel, Panoptic Mirror) → `freeInteraction` + `gameChanger`
- 1 infinite combo GC (Thassa's Oracle) → `infiniteCombo` + `gameChanger`

**Impacto em bracket 3 (max 3 GCs):**
- Um deck com 6 fast mana GCs seria BLOQUEADO (excede limite de 3 GCs), mesmo tendo budget de 6 fastMana.
- Um deck com 3 tutor GCs (ex: Demonic + Vampiric + Mystical) consome TODOS os 3 slots de GC, deixando 0 slots para Rhystic Study, The One Ring, etc.
- O budget de `tutor` (max 6) fica parcialmente consumido por cartas que NAO deveriam contar contra ele.

**Gap historico:** `tagCardForBracket()` acumula categorias. Isso era tratado como bug, mas agora e comportamento esperado e coberto por teste.

**Impacto atual:** Nenhuma acao de codigo pendente neste item. Qualquer alteracao para `gameChanger` exclusivo deve passar por nova decisao de produto e nova matriz de testes.

**Risco atual:** Reabrir esta tarefa automaticamente criaria regressao contra os testes multi-tag atuais.

**Acao recomendada antiga (NAO EXECUTAR sem nova decisao):**
1. Em `tagCardForBracket()`: se a carta esta em `_gameChangerNames`, retornar somente `{BracketCategory.gameChanger}`.
2. OU: apos todos os checks, se `categories.contains(BracketCategory.gameChanger)`, remover as outras categorias.
3. Atualizar `applyBracketPolicyToAdditions()` para tratar GCs como categoria exclusiva.
4. Adicionar teste unitario confirmando que Mana Vault retorna somente `gameChanger`.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart
```

---

### [P2] Payoff Tag Accuracy: Melhorar heuristica de classificacao — 35% de precisao (11/31) compromete quality gate

**Status em 2026-06-06:** RESOLVIDO para o quality gate deterministico. `classifyOptimizationFunctionalRole()` agora aceita `theme` opcional e tambem le `theme`, `deck_theme` ou `archetype` no mapa da carta, aplicando regras contextuais antes do fallback generico de payoff/enabler.

**Conhecimento MTG:** Uma carta "payoff" e aquela que RECOMPENSA por seguir o tema do deck. Ex: em spellslinger, Guttersnipe e um payoff (causa dano por spell). Em aristocrats, Blood Artist e payoff (drena vida por sacrificio). Em tokens, Anointed Procession e payoff (dobra tokens). O conceito de payoff e ALTAMENTE contextual — depende do tema do deck, nao apenas do oracle text da carta. Classificar payoff corretamente requer entender o contexto do deck, nao apenas regex no oracle.

**Evidencia no codigo:**
- `server/lib/ai/functional_card_tags.dart:16-36` — `functionalCardTagsV1` inclui 'payoff' como tag valida.
- `server/lib/ai/optimization_functional_roles.dart:55-124` — `classifyOptimizationFunctionalRole()` usa heuristica regex (oracle text + type line). Nao tem CONHECIMENTO DO TEMA do deck.
- `tag_accuracy`: payoff = 11/31 correto (35%), fp=0, fn=0. Muito abaixo das outras tags (ramp=100%, draw=100%, removal=100%).

**Gap:** O classificador regex atual acerta payoff apenas 35% das vezes. Isso significa que ~20 cartas classificadas como payoff estao ERRADAS. O quality gate (`filterUnsafeOptimizeSwapsByCardData`) usa `classifyOptimizationFunctionalRole` para decidir se swaps preservam papeis funcionais. Swaps envolvendo payoffs mal-classificados podem ser incorretamente bloqueados ou permitidos.

**Impacto:** P2 — Quality gate toma decisoes baseadas em classificacao de payoff com 65% de erro. Swaps legitimas podem ser bloqueadas, swaps ruins podem passar.

**Risco:** P2 — Afeta otimizacao de decks com muitos payoffs (spellslinger, aristocrats, tokens).

**Acao recomendada:**
1. Adicionar contexto de tema a `classifyOptimizationFunctionalRole()`: se o deck e 'spellslinger', cartas com "whenever you cast" sao payoff; se e 'aristocrats', cartas com "whenever a creature dies" sao payoff.
2. Criar tabela `payoff_heuristics` mapeando tema → padroes de oracle text para payoff.
3. Usar `theme_contextual_rules_service.dart` para informar a classificacao de payoff.
4. Revalidar as 31 cartas classificadas como payoff contra o contexto tematico.

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_functional_roles.dart
cd server && dart test test/ai/functional_card_tags_test.dart
```

---

### [P2] Classificador: Tags de baixa precisao `enabler` (50%) e `payoff` (35%) precisam de heuristica contextual — 63 tags incorretas

**Status em 2026-06-06:** RESOLVIDO para os temas principais do classificador usado pelo optimize/quality gate. Foram adicionadas regras contextuais para `spellslinger`, `aristocrats`, `tokens`, `tribal`, `graveyard`, `artifacts` e `enchantments`, preservando fallback quando nao ha tema.

**Conhecimento MTG:** `enabler` e `payoff` sao tags DEPENDENTES DE CONTEXTO. Nao podem ser classificadas por regex simples no oracle text. Exemplos:
- Em tribal Elves, Llanowar Elves e um enabler (ramp) E payoff (elfo). A tag 'ramp' e correta, 'enabler' e contextual.
- Em spellslinger, Past in Flames e enabler (recursao de spells). Mas em graveyard, e payoff.
- Em artifacts, Krark-Clan Ironworks e enabler (sacrifice). Em aristocrats, e payoff.

A tag_accuracy mostra `enabler` com 50% (21/42) e `payoff` com 35% (11/31). Juntas sao 73 cartas, das quais apenas ~32 estao corretas. 63 cartas estao potencialmente mal-classificadas.

**Evidencia no codigo:**
- `server/lib/ai/functional_card_tags.dart:7-36` — Define `functionalCardTagsV1` com 'enabler' e 'payoff'.
- `server/lib/ai/optimization_functional_roles.dart:55-124` — Classificador regex sem contexto tematico.
- `server/lib/ai/theme_contextual_rules_service.dart` — Servico de regras tematicas existe mas nao e integrado ao classificador de papeis funcionais.

**Gap:** O classificador de papeis funcionais opera isoladamente, sem acesso ao tema do deck. Tags contextuais (enabler, payoff) requerem informacao do tema para precisao aceitavel.

**Impacto:** P2 — 63 cartas mal-classificadas afetam quality gate, validacao funcional, e recomendacoes de swap.

**Risco:** P2 — Afeta toda a pipeline de otimizacao para tags contextuais.

**Acao recomendada:**
1. `classifyOptimizationFunctionalRole()` deve receber parametro opcional `String? theme`.
2. Criar `_classifyContextualRole()` que usa `theme` + oracle text para classificar enabler/payoff.
3. Heuristicas por tema:
   - spellslinger → payoff: "whenever you cast", "whenever you copy"; enabler: "flashback", "without paying"
   - aristocrats → payoff: "whenever a creature dies"; enabler: "sacrifice"
   - tokens → payoff: "create.*token.*instead", "whenever.*create.*token"; enabler: "populate"
   - tribal → payoff: "other.*get +1/+1"; enabler: "{T}: add.*mana"
4. Fallback: se tema nao definido, usar heuristica generica com confianca reduzida (confidence <= 0.5).

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_functional_roles.dart
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db');
counts = conn.execute("SELECT functional_tag, COUNT(*) FROM deck_cards WHERE functional_tag IN ('enabler','payoff') AND deck_id=6 GROUP BY functional_tag").fetchall();
print('Current enabler/payoff counts:', counts)
"
```

---

### [P2] Goldfish Simulator: Validar CMC antes de usar — `_getCmc()` retorna 0 para dados corrompidos sem distinguir lands de non-lands

**Status em 2026-06-06:** RESOLVIDO para a camada de simulacao/validacao. A logica compartilhada `safeCmcForOptimization()` preserva lands e cartas reais de custo 0, corrige casos como `cmc=0` + `mana_cost={1}` para CMC 1, recalcula `cmc=null` ou invalido quando `mana_cost` existe, e usa fallback conservador alto para non-lands sem dado suficiente. Testes adicionados em `server/test/cmc_safety_test.dart` e `server/test/goldfish_simulator_test.dart`.

**Conhecimento MTG:** O VALIDATOR_LOG (2026-06-02) documenta que 37 cartas no deck_id=6 tem CMC=0.0 no DB, incluindo fast mana REAL (Chrome Mox real CMC=0, Mox Diamond real CMC=0, Lotus Petal real CMC=0) e cartas com CMC ERRADO (Mana Vault real CMC=1, Boros Signet real CMC=2, Mana Confluence real CMC=0 como land). O goldfish simulator usa CMC para calcular playabilidade de maos e curva de mana. Com CMC=0.0 para cartas que custam 1-2 mana, a simulacao subestima a dificuldade de jogar o deck.

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart:459-465` — `_getCmc()` retorna 0 para null/0 sem distinguir land de non-land.
- `server/lib/ai/goldfish_simulator.dart` — Usa `_getCmc()` para cada carta; CMC=0.0 significa "jogavel T1 sem custo".
- `server/lib/ai/optimization_validator.dart:97-101` — Monte Carlo comparison usa goldfish com os mesmos dados corrompidos.

**Gap:** Mesmo apos a correcao batch de CMC (task P1 do Cron #10), o `_getCmc()` nao valida se o valor e plausivel. Se o CMC batch falhar ou for parcial, o goldfish continua usando dados corrompidos silenciosamente. Nao ha distincao entre "CMC=0 porque e land" e "CMC=0 porque o dado esta corrompido".

**Impacto:** P2 — Goldfish simulator produz metricas enganosas ("keepable T3" artificialmente alto, "mana screw" artificialmente baixo) para decks com CMCs corrompidos. A comparacao Monte Carlo "antes vs depois" do validator pode achar que um swap PIOROU o deck quando na verdade so mudou o CMC medio.

**Risco:** P2 — Depende do sucesso da task P1 (CMC batch correction). Se a correcao for completa, este hardening e preventivo. Se for parcial, e necessario.

**Acao recomendada:**
1. `_getCmc()`: adicionar parametro `String typeLine` para distinguir lands.
2. Para non-lands com CMC=0: logar warning `developer.log('Suspicious CMC=0 for non-land card: \$name')`.
3. No goldfish simulator: se CMC=0 para non-land, usar CMC=3 como fallback conservador (nao subestimar custo real).
4. Adicionar validacao `_validateDeckCmc()` que verifica se >5% das non-lands tem CMC=0 (indicando corrupcao).

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart analyze lib/ai/goldfish_simulator.dart
```

---

### [P2] Game Changer List: Dart hardcoded `_gameChangerNames` vs SQLite autoritativo — risco de drift com futuras atualizacoes da lista oficial

**Status em 2026-06-06:** RESOLVIDO como guardrail local. A lista Dart agora e exposta como `officialGameChangerNamesForBracketPolicy`, fica dentro de um bloco gerado, e o script `sync_game_changers_to_dart.py` sincroniza/valida contra `scripts/knowledge.db`. A deteccao tambem normaliza MDFC para aceitar tanto o nome completo quanto a face principal, cobrindo `Tergrid, God of Fright // Tergrid's Lantern`.

**Conhecimento MTG:** A lista de 53 Game Changers e mantida oficialmente pelo Commander Rules Committee (mtgcommander.net) e pela Wizards. O banco SQLite (`game_changers` table) tem a lista importada do Scryfall com campos `why_game_changer`, `impact_category`, `impact_level` — dados ricos que a pesquisa autonoma produziu. O Dart `_gameChangerNames` e uma lista hardcoded de 53 nomes. Se a lista oficial mudar (cartas adicionadas/removidas), o Dart fica desatualizado enquanto o SQLite pode ser re-importado.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:280-334` — `_gameChangerNames` e uma `const` Set de 53 strings.
- `docs/hermes-analysis/manaloom-knowledge/GAME_CHANGERS.md:46-50` — SQLite tem 53 cartas com 14 colunas de metadados.
- Diferenca detectada: Dart usa `'tergrid, god of fright'`, DB usa `'Tergrid, God of Fright // Tergrid\'s Lantern'`. Normalizacao de nome MDFC nao e consistente.

**Gap:** Duas fontes de verdade (Dart hardcoded + SQLite importado). Se a lista oficial adicionar/remover cartas, apenas o SQLite seria atualizado (via re-importacao Scryfall). O Dart permaneceria stale ate re-compilacao. Alem disso, os metadados ricos do SQLite (why_game_changer, impact_category) nao sao usados pelo Dart.

**Impacto:** P2 — Atualmente a lista esta sincronizada (53/53, apenas diferenca de nomenclatura MDFC). Mas nao ha mecanismo de sincronizacao automatica. Se o RC adicionar 5 novos GCs amanha, o SQLite pode ser atualizado mas o Dart continua com 53.

**Risco:** P2 — Baixo no curto prazo (lista oficial e estavel), mas risco de drift a medio/longo prazo.

**Acao recomendada:**
1. Criar script `sync_game_changers_to_dart.py` que le o SQLite e gera o Set Dart como codigo.
2. OU: mudar `tagCardForBracket()` para consultar o PG/SQLite em vez de usar lista hardcoded (requer acesso a DB em runtime).
3. Documentar no `COMMIT_DIGEST.md` quando a lista oficial mudar.
4. Health check no cron watchdog: comparar `COUNT(*)` de `game_changers` do SQLite com `_gameChangerNames.length` do Dart.

**Validacao:**
```bash
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db');
db_count = conn.execute('SELECT COUNT(*) FROM game_changers').fetchone()[0];
print(f'SQLite GC count: {db_count} (Dart: 53)')
"
```

---

> **Base de conhecimento:** Commander Deep Report S44 (promotion migration failure — 4/4 decks incomplete), TAG_ACCURACY_REPORT (tag system fork — 5 orphaned tags + 12 new fine tags + CMC=0.0 spread to 142 cards), Commander Deep Report S44.3 (Atraxa split archetype), S44.4 (Winota stax density 14/100)
> **Novas tasks nesta execucao:** 5 (2xP1, 3xP2) — Deck promotion card migration verification, CMC batch correction + prevention hardening, tag accuracy fine-tag tracking, stax archetype detection in quality gate, split archetype detection heuristic

### [P1] Deck Promotion: Adicionar verificacao de migracao de cartas pos-promocao — `deck_promotions` registra sucesso mas `deck_cards` fica vazio (4/4 decks promovidos quebrados)

**Conhecimento MTG:** O Commander Knowledge Deep Report S44 (2026-06-05) documenta uma crise de integridade de dados: o Multi-Commander Evolution promoveu 4 decks em 24 minutos (2026-06-04), mas NENHUM teve as cartas migradas completamente:
- Winota: claim=100, actual=85 (-15)
- Atraxa: claim=100, actual=91 (-9)  
- Kinnan: claim=100, actual=13 (-87)
- Korvold: claim=90, actual=11 (-79)

O processo de promocao criou registros em `deck_promotions` com `new_card_count` correto, mas a migracao de `learned_decks.card_list` para `deck_cards` falhou SILENCIOSAMENTE. O Multi-Commander Evolution acredita que os decks estao completos (le `deck_promotions`), mas a pipeline de analise trabalha com `deck_cards` — que estao quase vazios.

**Evidencia no codigo:**
- `rg "deck_promotion|auto_promote" server/lib/` → ZERO resultados. Promocao e inteiramente Python.
- `server/lib/ai/commander_fallback_policy.dart` — Nao verifica se deck promovido tem cartas.
- O validator e quality gate consultam `deck_cards` sem verificar `deck_promotions.migration_verified`.

**Gap:** Promocao em 2 etapas (criar registro + migrar cartas). Etapa 2 falha sem que etapa 1 saiba.
**Impacto:** P1 — 4/8 decks inuteis. Pipeline opera sobre dados fantasmas.
**Risco:** P1 — Dados fantasmas se propagam para toda a pipeline.

**Acao recomendada:**
1. Adicionar `migration_verified BOOLEAN DEFAULT 0` a `deck_promotions`
2. No `auto_promote_learned_decks.py`: verificar `COUNT(*)` pos-migracao vs `new_card_count`
3. `commander_fallback_policy.dart`: verificar `migration_verified=1` antes de usar dados
4. Health check no cron watchdog para promotions nao verificadas

**Validacao:**
```bash
python3 -c "import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'); [print(f'promo_id={r[0]}: claimed={r[1]}, actual={r[2]}') for r in conn.execute('SELECT dp.id, dp.new_card_count, (SELECT COUNT(*) FROM deck_cards dc WHERE dc.deck_id = dp.target_deck_id) as actual FROM deck_promotions dp').fetchall()]"
```

---

### [P1] CMC Correction: Script de correcao em lote para 142 cartas com CMC=0.0 + hardening do `_getCmc()` com warning ativo

**Status em 2026-06-11:** RESOLVIDO no código backend/app-facing e no código
operacional Hermes; PENDENTE apenas a execução do sync no AWS com `knowledge.db`
populado.
`resolveImportCardNames(...)` agora carrega `cards.cmc`; `GeneratedDeckValidationService`
propaga esse campo internamente e emite warning para CMC não-terreno
ausente/zerado suspeito; `CardValidationService.validateDeckCards(...)`
compara CMC informado contra `cards.cmc`; `DeckRulesService._loadCardsData(...)`
passou a consultar `cmc`. `sync_pg_card_metadata_to_hermes.py` agora faz
backfill de `deck_cards.cmc/type_line/oracle_text` a partir de
`card_oracle_cache`, `import_lorehold_decks.py` prefere esse cache autoritativo
e as crons `known_cards_*` executam o sync antes de operar.

**Conhecimento MTG:** O TAG_ACCURACY_REPORT (2026-06-05) documenta que 142 cartas (26.2%) tem CMC=0.0. A corrupcao se espalhou de 1 deck para TODOS os 7. Cartas como Sol Ring (CMC=1), Mana Vault (1), Boros Signet (2), Aetherflux Reservoir (4) estao com CMC=0.0. Atraxa (deck 9, 100 cartas) importada com 29 CMCs invalidos.

**Evidencia no codigo:**
- `server/lib/ai/cmc_safety.dart` — fallback conservador já recupera CMC por `mana_cost` e evita tratar non-land desconhecido como grátis.
- `server/lib/generated_deck_validation_service.dart` — emite warning de CMC suspeito no fluxo de validação de decks gerados/importados.
- `server/lib/card_validation_service.dart` — compara CMC informado contra `cards.cmc` no validador genérico.
- `server/lib/deck_rules_service.dart` — `_loadCardsData()` agora consulta `cmc`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py` — backfill idempotente de `deck_cards` a partir do cache PG.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_card_metadata_to_hermes.py` — prova backfill e dry-run em SQLite in-memory.

**Gap remanescente:** Executar a rotina no Hermes/AWS após popular `knowledge.db`
com decks reais; o report precisa mostrar `deck_cards_table_present=true` e
`suspicious_nonland_zero_cmc_after=0` para o corpus alvo.
**Impacto:** P1 — GoldfishSimulator, quality gate, e mulligan usam CMC corrompido.
**Risco:** P1 — Se o SQLite Hermes ficar desatualizado, crons de mulligan/optimizer podem continuar usando CMC local corrompido.

**Acao recomendada:**
1. ~~Adicionar `cmc` ao SELECT em `_loadCardsData()`~~
2. ~~Carregar `cmc` no resolver de nomes usado por import/deck generation~~
3. ~~Emitir warning app-facing quando CMC resolvido for suspeito~~
4. ~~Criar rotina Hermes para corrigir SQLite local e scripts Python de importação aprendida~~
5. Rodar a rotina no Hermes/AWS com DB populado e anexar o report operacional

**Validacao:**
```bash
cd server && dart test test/generated_deck_validation_service_test.dart test/cmc_safety_test.dart
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_sync_pg_card_metadata_to_hermes.py
```

---

### [P2] Tag Accuracy: Adicionar tracking de precisao para as 12 novas tags finas — 45% da taxonomia sem cobertura

**Conhecimento MTG:** TAG_ACCURACY_REPORT documenta fork no sistema de tags: 12 novas tags finas (token_maker, big_spell, aristocrat_payoff, etc.) sem entrada em `tag_accuracy`. 5 tags legadas orfas (0 cartas). `tag_accuracy` congelado desde 2026-05-27 (9 dias).

**Evidencia no codigo:**
- `functional_card_tags.dart:38-54` — `deckAnalysisMainFunctionalBuckets` INCLUI tags finas.
- `candidate_quality_data_support.dart:343-365` — Mapeia fine→legacy via switch-case.
- MAS: `rg "tag_accuracy" server/lib/` → ZERO resultados.

**Gap:** 12 tags operam sem metricas de qualidade. Sistema de auto-healing nao pode funcionar sem saber quais tags monitorar.
**Impacto:** P2 — Precisao das novas tags e desconhecida.
**Risco:** P2 — Fork de tags pode crescer descontroladamente.

**Acao recomendada:**
1. Atualizar `tag_accuracy_reporter.py` para detectar novas tags e criar entradas em `tag_accuracy`
2. Validacao cruzada com PG `card_function_tags` como fonte de verdade

**Validacao:**
```bash
python3 -c "import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'); new = conn.execute('SELECT DISTINCT dc.functional_tag FROM deck_cards dc WHERE dc.functional_tag NOT IN (SELECT tag_name FROM tag_accuracy) AND dc.functional_tag IS NOT NULL AND dc.functional_tag != \"unknown\"').fetchall(); print(f'Untracked tags: {len(new)} (target: 0)')"
```

---

### [P2] Quality Gate: Adicionar deteccao de densidade de stax como atributo estrutural — Winota 14 stax pieces

**Conhecimento MTG:** Commander Deep Report S44.4: Winota tem 14 stax pieces (~16.5% das nao-lands). Domain Skill Gap 3: stax e uma das 7 categorias GC faltando. Quality gate trata Winota como "aggro" generico.

**Evidencia no codigo:**
- `optimization_quality_gate.dart:346-353` — `_criticalRolesForArchetype()` sem case 'stax'.
- `functional_card_tags.dart:16-36` — `_taggableRoleNames` NAO inclui 'stax'.
- `theme_contextual_rules_service.dart` — NAO tem tema 'stax' ou 'hatebears'.

**Gap:** Quality gate cego a stax. Swaps que removem stax pieces nao sao bloqueados.
**Impacto:** P2 — Pipeline pode cortar stax pieces de Winota.
**Risco:** P2 — Afeta decks com stax density > 10%.

**Acao recomendada:**
1. Adicionar 'stax' ao `_taggableRoleNames`
2. Heuristica de deteccao: oracle text com "can't" + "opponent"
3. `_criticalRolesForArchetype`: case 'stax' → {'stax', 'creature', 'protection', 'ramp'}
4. Metrica `staxDensity` e flag `heavyStax` quando > 0.15

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart && dart analyze lib/ai/functional_card_tags.dart
```

---

### [P2] Optimization Validator: Adicionar deteccao de split archetype — Atraxa 3 sub-arquetipos (infect + superfriends + counters)

**Conhecimento MTG:** Commander Deep Report S44.3: Atraxa tem 3 sub-arquetipos competindo: infect (~8), superfriends (~6), counters (~10). 0 board wipes, 3 protection em bracket 4.

**Evidencia no codigo:**
- `optimization_validator.dart:28-86` — Sem deteccao de split archetype.
- `optimization_functional_roles.dart:55-124` — Classifica cartas individualmente, sem visao de cluster.
- `theme_contextual_rules_service.dart` — Nao detecta multiplos sub-temas.

**Gap:** Validator avalia metricas mas nao a coerencia estrategica. Deck pode ter metricas perfeitas mas ser injogavel por split archetype.
**Impacto:** P2 — Falso positivo "deck saudavel". Swaps podem piorar o split.
**Risco:** P2 — Afeta qualquer deck goodstuff com multiplos mini-temas.

**Acao recomendada:**
1. `_detectArchetypeFocus()` no validator: agrupar por functional_tag fino, detectar clusters >=5 cartas
2. `ValidationReport.archetypeFocus` com `isSplitArchetype` flag
3. Quality gate: se split, priorizar swaps que consolidam
4. Alerta "Deck has N competing sub-archetypes"

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_validator.dart && dart test test/ai/optimization_validator_test.dart
```

## Resumo de Tasks Novas (2026-06-05 @ 3f7266d6 — Cron #10)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Deck Promotion: Adicionar verificacao de migracao de cartas pos-promocao | Commander Deep Report S44 (4/4 promotions failed) |
| 2 | P1 | CMC Batch Correction: Script para corrigir 142 cartas + hardening `_getCmc()` | TAG_ACCURACY_REPORT (CMC=0.0 spread to 26.2%) |
| 3 | P2 | Tag Accuracy: Adicionar tracking para 12 novas tags finas (45% sem cobertura) | TAG_ACCURACY_REPORT (tag system fork) |
| 4 | P2 | Quality Gate: Adicionar deteccao de densidade de stax como atributo estrutural | Commander Deep Report S44.4 (Winota 14 stax) |
| 5 | P2 | Optimization Validator: Adicionar deteccao de split archetype (Atraxa 3 sub-arquetipos) | Commander Deep Report S44.3 (Atraxa infect+superfriends+counters) |

> **Nota:** Tasks #1 e #2 sao correcoes de integridade de dados — a base de conhecimento esta corrompida (promotions sem cartas, CMCs zerados). Estas tasks DESBLOQUEIAM as tasks de analise (Atraxa, Winota) que dependem de dados completos.
> **Nota:** Task #3 complementa a task P2 pendente "Tag Accuracy Auto-Healing" (Cron #7) — enquanto aquela foca em melhorar precisao de tags existentes, esta garante que as NOVAS tags tambem sejam monitoradas.
> **Nota:** Tasks #4 e #5 abordam gaps de classificacao de arquetipo — o quality gate atual so reconhece aggro/control/midrange/combo. Stax e split archetype sao dimensoes novas que o sistema precisa entender.

---


### [P1] Deck Import: Adicionar validacao de completude — verificar que o numero de cartas importadas corresponde ao total esperado (previne pipeline operando sobre decks fantasmas)

**Atualizacao Codex 2026-06-11:** PARCIALMENTE RESOLVIDO na camada Hermes/local. Foi adicionado guard compartilhado em `docs/hermes-analysis/manaloom-knowledge/scripts/learned_deck_completeness.py`; `generate_known_cards.py` ignora learned decks com menos de 90 cartas; `materialize_learned_deck_to_deck_cards.py` deixa de preencher decks parciais com terrenos basicos por padrao; `export_hermes_learned_deck.py` bloqueia export parcial e normaliza lista main-99 + comandante; `import_lorehold_decks.py` so aceita deck Commander completo. O backend PG de learned decks ja possui gate forte em `server/lib/ai/commander_learned_deck_support.dart` (100 total, 1 comandante, 99 main). Ainda nao foi adicionada coluna `import_completeness` em `decks`, pois isso exigiria migracao/schema separado.

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

**Atualizacao Codex 2026-06-11:** PARCIALMENTE RESOLVIDO no pipeline Hermes. `sync_pg_meta_decks_to_hermes.py` agora usa `--min-cards=90` por padrao e `sync_pg_target_deck_to_hermes.py` recusa deck PG alvo com `total_qty < 90` ou sem comandante. Isso reduz o risco de crons/battle tooling selecionarem seeds parciais. A validacao do endpoint de optimize do app permanece baseada no deck do usuario e nas regras atuais do backend; nao foi introduzido bloqueio global por comandante desconhecido para evitar falsos negativos em decks reais recem-criados.

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


### [P1] ✅ Resolvido em 2026-06-11 — Unificar roles estratégicos entre `functional_card_tags.dart` e `optimization_functional_roles.dart`

**Conhecimento MTG:** Cartas como Thassa's Oracle (wincon/combo), Blood Artist (aristocrat payoff), Isochron Scepter (combo piece), e Lightning Greaves (protection/enabler) têm papéis funcionais bem definidos no Commander. A classificação correta desses papéis é essencial para que o quality gate tome decisões corretas de swap — trocar um "wincon" por "engine" requer regras diferentes de trocar "utility" por "utility".

**Status:** resolvido sem criar módulo extra: o módulo canônico já existente
`server/lib/ai/optimization_functional_roles.dart` expõe o adapter
`resolveCardFunctionalRoles`. `server/lib/ai/functional_card_tags.dart` removeu
as cópias privadas de `_looksLikeWincon`, `_looksLikeComboPiece`,
`_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler` e passou a
consultar esse adapter para `wincon`, `combo_piece`, `engine`, `payoff` e
`enabler`.

**Evidência atual:**
- `functional_card_tags.dart`: `inferFunctionalCardTags` chama
  `resolveCardFunctionalRoles(...)` e usa `strategicRoles` para os cinco roles.
- `optimization_functional_roles.dart`: continua sendo a fonte única para
  classificação multi-role e `primary_role`.
- `functional_card_tags_test.dart`: adiciona teste cruzado com `Impact Tremors`,
  `Isochron Scepter`, `The One Ring`, `Aetherflux Reservoir` e `Demonic Tutor`,
  além de impedir que `Nature's Lore` vire `enabler`.

**Impacto:** o tagger exibido na análise e o classificador usado por
optimize/validator/quality gate deixam de discordar nesses roles estratégicos.

**Próxima pendência relacionada:** centralizar basic/snow lands, descrita na
task P2 seguinte.

**Validação:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart lib/ai/optimization_functional_roles.dart test/functional_card_tags_test.dart
cd server && dart test test/functional_card_tags_test.dart test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart --reporter compact
```

---

### [P2] Centralizar `_isBasicLandName` em utilitário único de domínio — 4 implementações com normalização diferente causam validação inconsistente de terrenos básicos

**Conhecimento MTG:** Terrenos básicos (Plains, Island, Swamp, Mountain, Forest, Wastes, e suas variantes Snow-Covered) são fundamentais para as regras de deckbuilding do Commander: singleton não se aplica a eles, e a contagem correta afeta validação de legalidade, análise de mana base, e simulação de mulligan. Diferentes partes do sistema precisam concordar sobre o que constitui um "basic land" — especialmente as variantes Snow-Covered e Wastes.

**Evidencia no código:** 4 implementações diferentes da mesma pergunta de domínio, com normalização divergente:

1. `server/lib/ai/optimize_runtime_support.dart:4184-4197` — `isBasicLandName` público: compara nomes exatos com hífen para snow-covered lands (`snow-covered plains`). Expõe `isBasicLandName` como API pública (linha 285).

2. `server/lib/generated_deck_validation_service.dart:752-764` — `_isBasicLandName` privado: usa `startsWith('snow-covered ')` com espaço, sem hífen. Aceita prefixo parcial — "snow covered plains" (com espaço duplo ou sem hífen) seria tratado como basic.

3. `server/lib/meta/meta_deck_reference_support.dart:890-903` — `_isBasicLandName` privado: aceita snow lands com espaço normal (`snow covered plains`) em vez de hífen. Comportamento intermediário entre #1 e #2.

4. `server/routes/ai/commander-reference/index.dart:621-629` — `_isBasicLandName` privado: reconhece APENAS as 6 basics não-snow (Plains, Island, Swamp, Mountain, Forest, Wastes). Snow-Covered lands NÃO são reconhecidas como básicas nesta rota.

**Gap:** Um deck com Snow-Covered Plains pode ser validado como legal (singleton bypass) por `generated_deck_validation_service.dart` mas tratado como não-básico por `commander-reference/index.dart`. A análise de mana base em `optimize_runtime_support.dart` conta Snow-Covered Plains como básica, mas `meta_deck_reference_support.dart` pode normalizar o nome de forma diferente, causando mismatch em referências.

**Impacto:** `P2` — Inconsistência entre validadores pode causar falsos positivos/negativos na validação de singleton (deck rejeitado como tendo 2 Snow-Covered Plains quando na verdade são 2 terrenos básicos permitidos), ou falso positivo de legalidade (deck aprovado com "duplicata" de Wastes que um validador conta como básica e outro não). 

**Risco:** P2 — Afeta edge cases com Snow-Covered lands e Wastes. A maioria dos decks usa basics normais (não afetados pela divergência). Mas quando ocorre, o comportamento é inconsistente entre rotas.

**Ação recomendada:**
1. Criar `server/lib/domain/basic_land_utils.dart` com função canônica `bool isBasicLandName(String name)` que:
   - Normaliza o nome (trim, lowercase)
   - Verifica as 5 basic land types + Wastes
   - Trata Snow-Covered variants com ambos os formatos (hífen e espaço)
2. Atualizar os 4 call sites para importar e usar a função canônica
3. Adicionar testes unitários cobrindo: nomes normais, Snow-Covered (com e sem hífen), Wastes, e casos negativos (non-basic lands com "forest" no nome como "Tropical Forest")

**Validação:**
```bash
cd server && dart analyze lib/domain/basic_land_utils.dart
cd server && dart test test/domain/basic_land_utils_test.dart
cd server && dart test test/generated_deck_validation_service_test.dart
```

---

### [P2] Conectar `MLKnowledgeService.recordFeedback` a um fluxo runtime — tabela `ml_prompt_feedback` existe mas nunca é alimentada, impedindo ciclo de aprendizado com qualidade de prompts

**Conhecimento MTG:** O optimize pipeline gera prompts para IA que sugerem swaps de cartas. A qualidade desses prompts afeta diretamente a qualidade das recomendações. Sem um ciclo de feedback, o sistema não sabe se prompts anteriores produziram boas ou más recomendações — e não pode melhorar. O Domain Skill documenta que "o optimize pipeline não aprende com o uso real" (Gap 8).

**Evidencia no código:**
- `server/lib/ml_knowledge_service.dart:251-264` — `recordFeedback()` método que insere em `ml_prompt_feedback` com campos: `prompt_id`, `rating`, `comment`, `user_id`. Totalmente implementado mas sem caller.
- `rg "recordFeedback\(" server/lib/ server/routes/ server/bin/` → **ZERO chamadas** fora da definição.
- `rg "ml_prompt_feedback" server/lib/ server/routes/` → Apenas a definição da tabela (schema SQL) e o INSERT dentro de `recordFeedback`. Nenhum SELECT.
- `server/routes/ai/optimize/index.dart` — A rota de optimize chama `MLKnowledgeService` para contexto (`getMLContext`) mas NUNCA chama `recordFeedback` após receber a resposta da IA.

**Gap:** O feedback loop de qualidade de prompts está completamente quebrado. A tabela `ml_prompt_feedback` tem schema, tem método de escrita, mas não tem caller. Nenhum fluxo (app, rota, cron) registra se um prompt de optimize produziu boas recomendações. O sistema não pode aprender quais tipos de prompt funcionam melhor para diferentes comandantes/arquetipos.

**Impacto:** `P2` — O optimize pipeline nunca melhora a qualidade dos prompts porque não coleta feedback. Sem dados em `ml_prompt_feedback`, qualquer futuro sistema de "prompt quality scoring" ou "prompt selection" não tem dados para treinar. A funcionalidade de `MLKnowledgeService.getPromptQualityMetrics` (se existir) operaria sobre tabela vazia.

**Risco:** P2 — Sem feedback, o sistema não aprende. As mesmas estratégias de prompt (boas ou ruins) são repetidas indefinidamente. Afeta a qualidade de longo prazo das recomendações de swap.

**Ação recomendada:**
1. Adicionar chamada a `recordFeedback` no endpoint de optimize após processar a resposta da IA:
   - Capturar o `prompt_id` usado (ou gerar um hash do prompt)
   - Se a IA retornou swaps válidos → `rating >= 3`
   - Se a IA retornou erro/alucinação → `rating <= 2`
2. Adicionar endpoint `POST /api/optimize/feedback` para o app Flutter reportar feedback do usuário sobre recomendações (rating manual)
3. Criar `getPromptQualityMetrics()` em `MLKnowledgeService` que agrega ratings por tipo de prompt/comandante para uso futuro
4. (Futuro) Usar métricas de qualidade para selecionar templates de prompt que historicamente produziram melhores resultados

**Validação:**
```bash
cd server && dart analyze lib/ml_knowledge_service.dart
cd server && dart test test/ml_knowledge_service_test.dart
# Verificar que ml_prompt_feedback tem rows após optimize:
psql -h 143.198.230.247 -p 5433 -U postgres -d halder -c "SELECT COUNT(*) FROM ml_prompt_feedback"
```

---

### [P2] Expandir `_run_validation.py` para buscar profiles batch_c — 8 comandantes sem cobertura de validação de mana base

**Conhecimento MTG:** O Mana Base Validator compara decks contra perfis EDHREC com ranges ideais de lands, ramp, draw, etc. por comandante. O projeto tem 24 profiles JSON (8 batch_a + 8 batch_b + 8 batch_c), mas o script de validação só consulta 16 deles (batch_a + batch_b). Comandantes dos profiles batch_c — incluindo potenciais comandantes futuros no `knowledge.db` — ficam sem validação de mana base.

**Evidencia no código:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/_run_validation.py` — O script (criado 2026-06-04) carrega profiles de `batch_a` e `batch_b` apenas. A lógica de busca de profiles (aproximadamente linhas 30-60) percorre apenas estes dois diretórios.
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles/` — 8 profiles JSON existem mas não são lidos.
- O Commander Knowledge Skill (2026-06-05, Mana Base Validator Exec #2) documenta: "Só busca profiles em batch_a e batch_b (não batch_c)" e "Seção de notas (L258-272) é hardcoded — pode divergir dos dados reais".

**Gap:** Se um deck para um comandante do batch_c for adicionado ao `knowledge.db` (ex: Krenko, Mob Boss; Muldrotha, the Gravetide; ou outro dos 8 profiles batch_c), o Mana Base Validator reportará "NO PROFILE" em vez de validar contra os ranges ideais. A seção de notas do relatório também é hardcoded — se novos decks forem adicionados, as notas não refletirão a realidade.

**Impacto:** `P2` — Atualmente nenhum deck no `knowledge.db` corresponde a comandantes do batch_c (são Kinnan, Yuriko, Korvold, Teysa, Aesi, Winota, Atraxa, Lorehold — batch_a/batch_b). Mas o sistema não escala: qualquer novo deck de batch_c ficará sem validação. A seção de notas hardcoded também falseará o relatório quando novos decks aparecerem.

**Risco:** P2 — Baixo impacto imediato (0 decks batch_c no DB), mas impede expansão futura. A nota hardcoded é um risk de integridade de relatório.

**Ação recomendada:**
1. Adicionar `batch_c` ao loop de busca de profiles em `_run_validation.py`:
   ```python
   profile_dirs = [
       "server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/",
       "server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/",
       "server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles/",
   ]
   ```
2. Substituir seção de notas hardcoded (L258-272) por geração dinâmica baseada nos dados reais de cada deck
3. Adicionar contagem de "profiles available vs profiles used" no output do script para transparência

**Validação:**
```bash
cd /opt/data/workspace/mtgia && /opt/hermes/.venv/bin/python3 docs/hermes-analysis/manaloom-knowledge/scripts/_run_validation.py
# Verificar que o relatório gerado referencia 24 profiles (não 16)
grep -c "profile" docs/hermes-analysis/manaloom-knowledge/MANA_BASE_VALIDATION_REPORT.md
```

---

### [P3] Adicionar consumidor de leitura para `deck_weakness_reports` — dados persistidos nunca são lidos, anula benefício da persistência

**Conhecimento MTG:** A análise de fraquezas de deck identifica gaps estruturais (falta de ramp, draw insuficiente, remoção escassa) que afetam a performance. Persistir essas análises permite tracking histórico: "esta fraqueza foi corrigida?" "o deck melhorou após swaps?" Sem leitura, a tabela é um write-only log sem valor.

**Evidencia no código:**
- `server/routes/ai/weakness-analysis/index.dart:374` — `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING` — única referência à tabela.
- `rg "FROM deck_weakness_reports" server/lib/ server/routes/ server/bin/ app/` → **ZERO resultados**. Nenhum SELECT consulta a tabela.
- O campo `addressed` existe no schema (`server/database_setup.sql:363`) para marcar fraquezas como resolvidas, mas não há fluxo de UPDATE porque ninguém lê a tabela para identificar o que precisa ser atualizado.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md:286` — marca o endpoint como "experimental/not proven".

**Gap:** A rota `POST /ai/weakness-analysis` gasta recursos computacionais (análise de IA) para gerar um relatório de fraquezas, persiste o resultado... e nunca mais o consulta. O dado é efetivamente descartado após a resposta HTTP. O campo `addressed` (booleano) nunca é atualizado porque nenhum fluxo lê a tabela para verificar se fraquezas antigas foram corrigidas.

**Impacto:** `P3` — Desperdício de armazenamento e processamento. As fraquezas identificadas não retroalimentam otimizações futuras (ex: "este deck já teve warning de ramp baixo 3 vezes — priorize adicionar ramp"). O optimize pipeline não sabe que o deck tem fraquezas históricas não resolvidas.

**Risco:** P3 — Baixo impacto funcional (a análise é retornada na resposta HTTP em tempo real). Mas representa custo de armazenamento sem benefício e uma oportunidade perdida de melhorar recomendações com histórico.

**Ação recomendada:**
1. Criar endpoint `GET /api/decks/:id/weakness-history` que retorna fraquezas históricas com status `addressed`
2. No optimize pipeline (`optimize_runtime_support.dart`), consultar fraquezas não-resolvidas para priorizar categorias de swap (ex: se `addressed=false` para "falta ramp", dar +5 bonus a candidatos de ramp)
3. Após aplicar swaps, marcar fraquezas relacionadas como `addressed=true` se as métricas melhoraram
4. (Opcional) Adicionar dashboard no app Flutter mostrando "fraquezas resolvidas vs pendentes"

**Validação:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart
cd server && dart test test/ai/optimize_runtime_support_test.dart
# Verificar que deck_weakness_reports é consultado:
rg "deck_weakness_reports" server/lib/ server/routes/ --count
```

---

## Resumo de Tasks Novas (2026-06-05 — Cron #9)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Unificar heurísticas `_looksLike{Wincon,Engine,ComboPiece,Payoff,Enabler}` entre `functional_card_tags.dart` e `optimization_functional_roles.dart` | STRUCTURE_AUDIT 2026-06-05 (divergent heuristic implementations) |
| 2 | P2 | Centralizar `_isBasicLandName` em utilitário único com normalização canônica | STRUCTURE_AUDIT 2026-06-05 (4 conflicting implementations) |
| 3 | P2 | Conectar `MLKnowledgeService.recordFeedback` a fluxo runtime — tabela `ml_prompt_feedback` nunca alimentada | STRUCTURE_AUDIT 2026-06-05 (functions not called: recordFeedback) |
| 4 | P2 | Expandir `_run_validation.py` para buscar profiles batch_c | Commander Knowledge Skill (Mana Base Validator Exec #2 limitations) |
| 5 | P3 | Adicionar consumidor de leitura para `deck_weakness_reports` — tabela write-only | STRUCTURE_AUDIT 2026-05-28 (postgresql-tables-not-used) |

> **Nota:** Task #1 complementa a tarefa pendente P1 "classifyOptimizationFunctionalRole: Usar functional_tags persistidas como fonte primária" (Cron #7) — enquanto aquela aborda a CADEIA DE PRIORIDADE de fontes, esta aborda a DIVERGÊNCIA NAS IMPLEMENTAÇÕES das heurísticas de fallback.
> **Nota:** Task #3 complementa a tarefa pendente P2 "deck_learning_events: Fechar o loop de aprendizado" (Cron #7) — enquanto aquela foca em eventos de gameplay, esta foca em feedback de qualidade de prompts.
> **Nota:** Task #2 resolve um problema de integridade de dados que afeta múltiplos validadores — centralizar evita que correções futuras sejam aplicadas em apenas um local.

### [P1] Deck Import: Validar CMC das cartas importadas contra a tabela `cards` do PostgreSQL — previne corrupção de dados que afeta toda a pipeline de análise

**Status em 2026-06-11:** RESOLVIDO no código. O caminho de resolução/import
app-facing passa a carregar `cards.cmc` e gerar warnings de integridade; o
payload público foi preservado. A rotina Hermes de backfill/sync de
`deck_cards.cmc` existe e está testada; falta apenas execução operacional no
AWS com `knowledge.db` populado.

**Conhecimento MTG:** O VALIDATOR_LOG v3.23 (2026-06-02) documenta corrupção massiva de CMC na importação do deck Lorehold: 14+ cartas com `CMC=0.0` (Sol Ring, Mana Vault, Boros Signet, Orim's Chant, etc.) e 6 cartas com `CMC=NULL` (Aetherflux Reservoir, Past in Flames, Electroduplicate, etc.). A CMC média reportada de 2.15 é subestimada — a CMC real do deck está ~2.8-3.0. Todos os cálculos downstream (curva de mana, Mulligan Simulation T3, GoldfishSimulator keepable, quality gate ΔCMC) são afetados.

**Evidencia no código:**
- `server/lib/import_card_lookup_service.dart` — queries de exact/localized/split agora retornam `c.cmc`.
- `server/lib/generated_deck_validation_service.dart` — cards resolvidos carregam `cmc` internamente e geram warning de integridade.
- `server/lib/card_validation_service.dart` — `_getCardInfo()` retorna `mana_cost`/`cmc` e `validateDeckCards()` compara contra o valor informado.
- `server/lib/deck_rules_service.dart` — `_loadCardsData()` consulta e armazena `cmc` em `_CardData`.
- `server/lib/ai/cmc_safety.dart` — funções compartilhadas identificam CMC suspeito e recuperam fallback por `mana_cost`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py` — corrige `deck_cards.cmc/type_line/oracle_text` a partir de `card_oracle_cache`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/import_lorehold_decks.py` — usa `card_oracle_cache` antes de `card_oracle_data`.

**Gap remanescente:** Operacional: rodar o sync no Hermes/AWS depois de popular
`knowledge.db` com decks reais. Se o banco continuar vazio, o relatório expõe
`deck_cards_table_present=false`.

**Impacto:** `P1` — Dados corrompidos em cadeia. Swaps podem ser aprovados/rejeitados baseados em ΔCMC errado. O Mulligan Simulation reporta T3 inflado (mascara color screw). A análise de curva de mana mostra valores incorretos para o usuário. O problema é silencioso — não há logs, warnings, ou alertas.

**Risco:** P1 — Corrupção de dados se propaga para todas as camadas de análise sem detecção. Afeta diretamente a confiabilidade do optimize pipeline e da exibição de métricas para o usuário.

**Ação recomendada:**
1. ~~Adicionar campo `cmc` à `_CardData` e ao SELECT de `DeckRulesService`~~
2. ~~Carregar `cmc` no resolver de import/localized/split~~
3. ~~Emitir warning em validação app-facing para CMC suspeito/divergente~~
4. ~~Criar rotina Hermes para corrigir SQLite local e scripts Python de importação aprendida~~
5. Rodar rotina no AWS e anexar relatório `deck_cards_backfill`

**Validação:**
```bash
cd server && dart analyze lib/deck_rules_service.dart lib/card_validation_service.dart lib/generated_deck_validation_service.dart lib/import_card_lookup_service.dart
cd server && dart test test/generated_deck_validation_service_test.dart test/cmc_safety_test.dart
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_sync_pg_card_metadata_to_hermes.py
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

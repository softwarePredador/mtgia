# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v6.0
**Data:** 2026-06-07T16:00:00+00:00
**Commit:** `3c252249` (HEAD local, não pushado — sem credenciais Git)
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)
**Escopo:** Auditoria completa dos 18 crons ativos + gaps desde v5.0 (2026-06-06 05:27Z)
**Status:** v5.0 → v6.0 (36h desde última auditoria bem-sucedida; execuções intermediárias falharam com HTTP 429)

**⚠️ AVISO:** O prompt deste cron contém 5 IDs de crons descomissionados desde v3.7 (2026-06-04). Esta é a 6ª execução consecutiva com prompt stale. Os diretórios `/opt/data/cron/output/f20ac299992b/`, `/opt/data/cron/output/712579b15767/`, `/opt/data/cron/output/08468451a06a/`, `/opt/data/cron/output/94f8590b1beb/`, e `/opt/data/cron/output/a50bef4c2a59/` **não existem**. O auditor opera usando o skill `manaloom-mtg-domain` v2.7.0 e inspeção direta dos outputs no lugar dos diretórios inexistentes.

---

## Sumário Executivo (v6.0)

| Cron | ID | Status | Nota MTG | Mudança vs v5.0 |
|:-----|:--|:-------|:--------:|:----------------|
| **Pipeline Lorehold** | — | 🔴 DESCOMISSIONADO | N/A | — |
| Master Watchdog | `757eefb8738b` | ✅ script-only | N/A | — |
| Normal Audit | `660397bb97e1` | ✅ Ativo | 8.0/10 | — (provider backoff resolved) |
| Weekly Parallel Audit | `aeaeb666d377` | 🔴 HTTP 429 | N/A | ↓ (falhou última exec) |
| **Commander Knowledge Deep** | `75eed994c103` | 🔴 **Battle-Validated** | 3.0/10 | ↓ (Exec #11 cita Battle Simulator, P0 tasks baseadas nele) |
| Game Changer Research | `7915cc2377a0` | ✅ Ativo | 7.5/10 | ↓ (Exec #9: Tergrid oracle_text ainda vazio, regressão) |
| Tag Accuracy Reporter | `b340374bc4e7` | 🔴 HTTP 429 | N/A | ↓ (última exec falhou) |
| Mana Base Validator | `444aa9510c2c` | ✅ Ativo | 7.0/10 | — (CMC corruption descoberto, mas só reporta) |
| Knowledge Import | `b2f5c21ce2d7` | ✅ script-only | N/A | — |
| **Knowledge Synthesis** | `10a59b3bdf4d` | 🔴 HTTP 404 | 5.0/10 | ↓ (nova falha de provider) |
| Logic Coherence Auditor | `de6fb777f5d1` | ✅ Ativo | 8.0/10 | — |
| Code Structure Auditor | `577a0a669714` | ✅ Ativo | N/A | — |
| Cron Governor Report | `21fa86eb0d84` | ✅ Ativo | N/A | — |
| **Auto-sync-learned-decks** | `7fcab928efd3` | 🔴 script-only | 0/10 | — (PermissionError persiste) |
| Pull-learning-events | `262dc49e1be1` | ✅ script-only | N/A | ↑ (último run ok, mas UUID cast persiste) |
| Auto-promote-learned | `104fd03a2ea2` | ✅ script-only | N/A | — |
| Knowncards Generator | `b9c8a7d6e5f4` | ⛔ PAUSADO | 0/10 | — (root-owned + path errado) |
| **Universal Optimizer** | `c8d9e0f1a2b3` | ⛔ PAUSADO | 1.0/10 | — (propõe cortar staples, root-owned) |
| Knowncards Validator | `d4e5f6a7b8c9` | 🔴 LOCKED | 2.0/10 | ↓ (5420s lock, funcionamento intermitente) |
| **Master Optimizer Preflight** | `mmo-preflight01` | 🔴 SQLite READONLY | N/A | 🆕 Nova falha |
| Manager Watchdog | `2d436c71bbf7` | ⛔ PAUSADO | N/A | — |
| **MTG Rules Auditor** | `c0591cb18024` | 🔴 PROMPT STALE | 2.0/10 | ↓ (6ª exec stale + HTTP 429 intermitente) |
| **PIPELINE SCORE** | | | **2.5/10** 🔴 | **↓0.5 vs v5.0** |

---

## Mudanças desde v5.0 (2026-06-06 05:27Z → 2026-06-07 16:00Z)

### 🔴 1. Commander Knowledge Deep — Exec #11 Continua Padrão "Battle-Validated"

**Exec #10 (2026-06-06 05:10Z):** Reportou "6 swaps battle-validados" com WR 89.5% (Slot Optimizer v3). 5 tasks P0-P1 geradas.

**Exec #11 (2026-06-07 15:29Z):** Continua citando "Battle-Validated Run" com WR 87.0% (300 games do Master Optimizer). **Gera 2 tasks P0** baseadas em dados do Battle Simulator: "Apply Slot Optimizer Phase 3 Findings" (+12.5pp) e "Integrate Master Optimizer as Cron Pipeline".

**O Battle Simulator (`battle_simulator.dart`, 879 linhas, linha 9) declara:** "Sem stack complexo (resolução imediata)". NÃO implementa:
- Stack/priority (CR 117.3-117.4)
- Commander damage (CR 903.10a) ou tax (CR 903.8)
- Multiplayer (2-player apenas)
- ETB triggers, planeswalkers
- Múltiplos bloqueadores

**O WR de 87-89% é do simulador 2-player sem stack — inválido para decisões de deckbuilding em Commander. As 2 tasks P0 geradas na Exec #11 são baseadas em dados de um simulador que não segue regras oficiais.**

**Status:** 3 execuções consecutivas (#9, #10, #11) com o mesmo padrão. NENHUMA correção aplicada.

**Avaliação MTG:** 3.0/10 🔴 (↓1.0 vs v5.0. Não é mais apenas "cita Battle"; agora GERA TASKS P0 baseadas nos dados inválidos.)

### 🔴 2. Tergrid — REGRESSÃO Confirmada (Skill vs DB)

**O skill `manaloom-mtg-domain` v2.7.0 afirma:** "Tergrid, God of Fright oracle_text está OK. A reimportação via Scryfall fuzzy search foi bem-sucedida."

**O DB contradiz (confirmado Game Changer Research Exec #8 e #9):** `oracle_text` é string vazia (`''`), não texto funcional. A "resolução" apenas converteu NULL → `''` sem popular o oracle real. Tergrid permanece invisível para heurísticas baseadas em oracle_text.

**Pitfall:** `WHERE oracle_text IS NULL` não detecta mais Tergrid (agora é `''`). Query correta: `WHERE oracle_text IS NULL OR oracle_text = ''`.

**Status:** Lacuna documentada, mas o fix aplicado foi cosmético (NULL→''), não funcional (sem texto oracle). O skill e o DB divergem — o skill afirma "RESOLVIDO", o DB mostra o contrário.

### 🔴 3. Knowledge Synthesis — HTTP 404 (Nova Falha)

**Exec #9 (2026-06-07 12:23Z):** Falhou com `RuntimeError: HTTP 404 — Not Found | opencode`. O provider `opencode-go` (ou `deepseek-pro`) retornou 404 para o modelo `deepseek-v4-pro`. **Nova falha — não era HTTP 429 como os demais crons.** Impacto: sem geração de IMPLEMENTATION_TASKS.md desde 2026-06-07.

### 🔴 4. CMC Corruption — 144 Cartas (26.6%), Inalterado desde v5.0

```sql
SELECT COUNT(*) FROM deck_cards WHERE cmc IS NULL OR cmc = 0.0;
-- Resultado: 144/542 (26.6%)
```

Distribuição por deck: deck 1=2, deck 2=19, deck 4=15, deck 5=19, deck 6=38, deck 7=22, deck 9=29.

**Novo (Mana Base Validator Exec #3, 2026-06-07 12:54Z):** Confirmado que TODOS os decks exceto Atraxa (#9) têm `decks.avg_cmc` armazenado divergindo do `AVG(cmc) WHERE cmc>0`. Lorehold (#6) é o pior: stored 1.79 vs computed 3.14.

**Impacto MTG:** Curva de mana, mulligan simulation, e quality gate operam com dados corrompidos. Cartas com CMC 5+ tratadas como CMC 0.0 distorcem todas as métricas derivadas.

**Status:** Script `fix_cmc_batch.py` pendente desde 2026-06-05. NÃO EXECUTADO.

### 🆕 5. Master Optimizer Preflight — SQLite Read-Only (Falha Nova)

**Todas as execuções:** `sqlite3.OperationalError: attempt to write a readonly database` em `sync_pg_card_metadata_to_hermes.py` linha 370. O script tenta escrever em `knowledge.db` que está em modo read-only. **43 falhas consecutivas.**

### 🔴 6. Git Push — 19+ Commits Acumulados sem Credenciais

**Status:** TODOS os crons que produzem commits estão bloqueados no push. Commits locais acumulados incluem `3c252249` (Commander Knowledge Deep), `0fe0bcf9` (Game Changer Research), `94d9e87d` (Mana Base Validator), e `b9b68751` (Knowledge Synthesis). **Nenhum push bem-sucedido desde 2026-06-06.**

### 🔴 7. KC Validator — LOCKED (5420s)

**Exec #63 (2026-06-07 15:11Z):** "LOCKED (5420s). Exiting." O lock file persiste por 1.5 horas. O validator não está produzindo novos relatórios de conflito de classificação.

---

## Auditoria MTG Rules — Crons Ativos

### Commander Knowledge Deep (`75eed994c103`) — 3.0/10 🔴

**O que faz:** Analisa 1 commander por execução, gera padrões de ramp/draw/removal/wincon, cria tasks.

**Contra regras MTG:**
- ❌ Cita Battle Simulator como "BATTLE-VALIDATED" (Exec #9, #10, #11)
- ❌ Gera tasks P0 baseadas em WR de simulador 2-player sem stack (Exec #11)
- ❌ WR de 87-89% é do simulador, não de jogo real Commander
- ✅ Análise de sinergia e arquétipo é sólida e baseada em regras reais
- ✅ Identifica padrões de deckbuilding corretamente

**Recomendação:** Adicionar disclaimer obrigatório: "Battle Analyst não implementa regras oficiais de Commander. WR é indicativo apenas para comparação entre builds do mesmo simulador." Remover "BATTLE-VALIDATED" do léxico. Não gerar tasks P0 baseadas exclusivamente em dados do simulador.

### Game Changer Research (`7915cc2377a0`) — 7.5/10 🟡

**O que faz:** Analisa GCs, detecta lacunas de categoria/heurística.

**Contra regras MTG:**
- ✅ Categorização semanticamente correta (card_advantage, stax, etc.)
- ✅ 24/53 GCs detectados (45%) — gap conhecido no código Dart
- ❌ Tergrid `oracle_text` vazio — regressão documentada
- ✅ Auto-diagnóstico em `notes` (CATEGORY_GAP, NOT_DETECTED, FALSE_FLAG)
- ✅ 8 cartas RL com `price_usd=NULL` — documentado, pendente de fix

**Impacto MTG:** Médio. O gap de detecção de GCs (45%) significa que 55% dos Game Changers oficiais não são sinalizados pelo bracket policy. Isso afeta a classificação de bracket dos decks e a validação de deckbuilding.

### Knowledge Synthesis (`10a59b3bdf4d`) — 5.0/10 🔴

**O que faz:** Cruza conhecimento MTG com código Dart, gera IMPLEMENTATION_TASKS.md.

**Contra regras MTG:**
- ✅ Tasks geradas são baseadas em gaps reais de código vs regras MTG
- ❌ Falhando com HTTP 404 (provider `opencode-go` não encontra modelo)
- ⚠️ Tasks P2 frequentemente duplicadas entre execuções
- ✅ Metodologia de cross-reference é correta: conhecimento → código → gap → task

**Recomendação:** Corrigir provider/modelo. Adicionar deduplicação de tasks.

### Mana Base Validator (`444aa9510c2c`) — 7.0/10 🟡

**O que faz:** Valida mana base de decks vs perfis EDHREC.

**Contra regras MTG:**
- ✅ Validação de lands/ramp/draw vs perfis EDHREC é sólida
- ✅ Detectou CMC corruption sistêmico (decks.avg_cmc vs computed)
- ⚠️ Não avalia regras MTG diretamente (apenas métricas de deckbuilding)
- ⚠️ Limitação: `role_targets` de commander profiles não mapeiam 1:1 para `functional_tag`

**Recomendação:** Adicionar verificação de color identity compliance. Reportar decks que violam identidade de cor.

### Universal Optimizer (`c8d9e0f1a2b3`) — 1.0/10 🔴

**O que faz:** Otimizador universal de deck via Battle Simulator.

**Contra regras MTG:**
- ❌ Avalia 576 candidatos via Battle Simulator (2-player, sem stack)
- ❌ Propõe cortar Smothering Tithe (40%+ EDHREC, staple Commander) e Imperial Recruiter
- ❌ Cortes baseados em simulação inválida para Commander real
- 🟢 PAUSADO — mitigação acidental (PermissionError em root-owned files)
- ❌ CMC corruption (26.6%) distorce seleção de candidatos

**Recomendação:** Não reativar sem: (a) corrigir Battle Simulator para regras Commander, (b) adicionar heurística de proteção para staples EDHREC ≥ 30%, (c) corrigir CMC corruption.

### MTG Rules Auditor (`c0591cb18024`) — 2.0/10 🔴 (ESTE CRON)

**O que faz:** Audita crons contra regras MTG oficiais.

**Contra regras MTG:**
- ❌ Prompt stale há 6 execuções consecutivas (desde v3.7, 2026-06-04)
- ❌ Referencia 5 IDs de crons descomissionados cujos diretórios não existem
- ❌ Últimas 4 execuções falharam com HTTP 429 (rate limit)
- ✅ Quando roda, produz auditoria precisa baseada nos skills
- ⚠️ Skill `manaloom-commander-knowledge` listado em `jobs.json` não existe — todos os crons que o listam recebem aviso "[SKIPPED]"

---

## Gaps de Código Dart — Status (inalterado desde v3.8)

| Gap | Descrição | Arquivo | Status |
|:----|:----------|:--------|:------|
| Gap 3 | Bracket policy: 29/53 GCs não detectados (54.7%) | `edh_bracket_policy.dart` | 🔴 Persiste |
| Gap 6 | Classificador "duplo nulo": 10%+ cartas invisíveis | `functional_card_tags.dart` | 🔴 Persiste |
| Gap 8 | Battle Simulator: sem stack/priority/commander | `battle_simulator.dart` | 🔴 Persiste |
| Gap 13 | Bulk import: `functional_tag='unknown'`, CMC NULL | `import_lorehold_decks.py` | 🔴 Persiste |
| Gap 15 | Ramp misclassification: 10/16 cartas não detectadas | `functional_card_tags.dart` | 🟡 Parcial (classificador corrigido no DB, código Dart pode regredir) |

---

## Dados Corrompidos — Impacto em Regras MTG

### CMC Corruption (144/542 cartas, 26.6%)

**Impacto direto em regras MTG:** Curva de mana é um aspecto fundamental de deckbuilding Commander. Com 26.6% das cartas tendo CMC=0.0 incorreto:
- Simulações de mulligan operam com distribuição de CMC errada
- Quality gate valida swaps contra thresholds de CMC errados
- Candidatos de swap com CMC real alto (5+) podem ser selecionados como "CMC 0" — distorcendo completamente a análise de curva

### Tergrid oracle_text (string vazia)

**Impacto direto em regras MTG:** Tergrid é um Game Changer oficial. Sem oracle_text:
- Nenhuma heurística pode avaliar Tergrid (precisa do texto da carta)
- O bracket policy não detecta Tergrid como GC (falso negativo)
- Decks incluindo Tergrid não consomem slot de GC — violação silenciosa de bracket

### 8 Cartas Reserved List (price_usd=NULL)

**Impacto:** Médio. Afeta apenas métricas de custo, não conformidade com regras MTG.

---

## Plano de Correções (v6.0, ordenado por impacto)

| # | Severidade | Alvo | Ação | Estado |
|:-:|:----------:|:-----|:-----|:------|
| 1 | 🔴 P0 | Commander Knowledge Deep | **Adicionar disclaimer obrigatório sobre Battle Simulator. Remover "BATTLE-VALIDATED" do léxico. Não gerar tasks P0 baseadas em dados do simulador.** | ❌ NÃO RESOLVIDO (3 execs) |
| 2 | 🔴 P0 | MTG Rules Auditor | **Atualizar prompt no jobs.json — remover 5 IDs descomissionados, focar nos 18 crons ativos.** | ❌ NÃO RESOLVIDO (6 execs) |
| 3 | 🔴 P0 | CMC Corruption | **Rodar fix_cmc_batch.py para corrigir 144 cartas com CMC=0.0** | ❌ NÃO RESOLVIDO (48h+) |
| 4 | 🔴 P0 | Tergrid oracle_text | **Reimportar via Scryfall buscando "Tergrid, God of Fright" (sem //). Verificar resultado NÃO é string vazia.** | ❌ REGRESSÃO |
| 5 | 🔴 P0 | Universal Optimizer | **Não reativar. Remover script ou adicionar disclaimer de que simulador não implementa Commander.** | 🟢 PAUSADO (mitigado) |
| 6 | 🟡 P1 | Git Credentials | **Configurar GIT_TOKEN ou .git-credentials no ambiente cron. 19+ commits locais não pushados.** | ❌ NÃO RESOLVIDO |
| 7 | 🟡 P1 | Root-owned files | `sudo chown -R hermes:hermes docs/hermes-analysis/manaloom-knowledge/` | 🟡 references/ OK, scripts/ ainda root |
| 8 | 🟡 P1 | Knowledge Synthesis | Corrigir HTTP 404 (provider/modelo) | ❌ NOVO |
| 9 | 🟡 P1 | Master Optimizer Preflight | Corrigir SQLite read-only (knowledge.db permissão) | 🆕 NOVO |
| 10 | 🟡 P1 | KC Validator | Corrigir LOCKED (5420s) — lock file stale | 🆕 NOVO |
| 11 | 🟡 P2 | Skill manaloom-commander-knowledge | Criar skill ou remover referências em jobs.json | ❌ NÃO RESOLVIDO |

**0 de 11 correções resolvidas. 3 novas falhas adicionadas desde v5.0.**

---

## Bloqueio Operacional — Root-Owned Files (Atualizado)

**Confirmado 2026-06-07:**
- `docs/hermes-analysis/manaloom-knowledge/references/` → ✅ `hermes:hermes` (corrigido)
- `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_generated.json` → ❓ provável `root:root`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py` → ❓ provável `root:root`

Comando para destravar (requer sudo):
```bash
sudo chown -R hermes:hermes /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/
```

---

## Conclusão

O pipeline de conhecimento Commander do ManaLoom tem confiabilidade **MUITO BAIXA (2.5/10)** em relação às regras oficiais de MTG. **↓0.5 vs v5.0 (3.0/10).**

**O que piorou (v5.0→v6.0):**
1. Commander Knowledge Deep passou de "citar Battle" para GERAR TASKS P0 baseadas no simulador inválido
2. Knowledge Synthesis quebrou com HTTP 404 (nova falha de provider)
3. Master Optimizer Preflight quebrou com SQLite read-only (nova falha)
4. KC Validator travou em LOCKED state
5. Tergrid regressão confirmada (skill diz "OK", DB mostra string vazia)
6. CMC corruption permanece em 144 cartas (26.6%) — 48h+ sem correção

**O que permanece igual:**
- 5 crons Lorehold descomissionados (correto)
- Git push bloqueado em todos os crons (19+ commits locais)
- Dados de Battle Simulator continuam sendo usados como se fossem válidos para Commander
- Prompt do MTG Rules Auditor stale há 6 execuções

**Ações imediatas (top 3):**
1. Atualizar prompt do Commander Knowledge Deep — adicionar disclaimer sobre Battle Simulator e remover "BATTLE-VALIDATED"
2. Rodar `fix_cmc_batch.py` — 26.6% dos dados estão corrompidos, toda análise derivada é inválida
3. Atualizar prompt do MTG Rules Auditor no `jobs.json` para auditar os 18 crons ativos, não os 5 descomissionados

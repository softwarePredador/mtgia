# MTG Rules Compliance Audit — Full Pipeline v3.3 (2026-06-02, Quarta Auditoria)

**Commit:** Pré-commit
**Auditor:** MTG Rules Auditor v3 (cron job `c0591cb18024`)
**Data da inspeção:** 2026-06-02T19:00Z
**Contexto:** Deck Lorehold totalmente reconstruído entre 18:00-18:52. Todos os logs C#1-C#23 stale.

---

## 🚨 Sumário Executivo

O deck Lorehold spellslinger (25 swaps, motor 4/4, T3 13.3%) foi **completamente reconstruído** durante a janela de 18:00-18:52 UTC em uma build cEDH turbo-combo. Esta auditoria avalia o comportamento de CADA cron do pipeline diante desta transformação radical — um teste de estresse involuntário do pipeline.

| Cron | Score v3.2 | Score v3.3 | Δ | Verdict |
|:-----|:----------:|:----------:|:--:|:--------|
| Scout | 3.5/10 | **4.0/10** | +0.5 | 🔴 BAIXA — Detectou crise mas recomenda carta banida |
| Validator | 7.0/10 | **8.0/10** | +1.0 | ⚠️ MÉDIA-ALTA — Detectou crise + corrupção de dados |
| Mulligan | 6.5/10 | **7.5/10** | +1.0 | ⚠️ MÉDIA-ALTA — Simulou build nova, identificou gap de classificador |
| Battle | N/A | **N/A** | = | 🔴 NÃO É CRON — Confirmado, sem diretório de output |
| Oracle | 3.5/10 | **1.0/10** | -2.5 | 🔴 QUEBRADO — Script determinístico lista wincons de build QUE NÃO EXISTE MAIS |
| **PIPELINE** | **5.1/10** | **4.0/10** | **-1.1** | 🔴 **BAIXA — Pipeline OVERWHELMED por reconstrução externa** |

---

## 🔴 CRITICAL FINDING #1: BANNED CARD IN DECK

A build cEDH atual contém **Mana Crypt**, que está na Commander banlist desde Setembro 2024 (confirmado via mtgcommander.net).

```
Mana Crypt — BANNED in Commander (September 2024 Quarterly Update)
```

**NENHUM dos 5 agentes detecta que o deck contém uma carta banida.** O Scout #36 inclusive recomenda adicionar **Worldfire** (CMC 9) sem verificar que Mana Crypt — a fast mana que viabiliza conjurá-lo — é banida.

Este é o **primeiro caso confirmado de carta banida no deck Lorehold** desde o início do pipeline. A vulnerabilidade documentada nos audits v1-v3.2 materializou-se.

**Impacto:** Se o Evolution Oracle estivesse ativo como LLM agent, poderia recomendar swaps baseados em uma build ilegal — comprometendo a integridade de todas as análises downstream (mulligan, matchup, collection recommendations).

---

## 🔴 CRITICAL FINDING #2: Bulk Import Data Corruption

A importação em massa (`import_lorehold_decks.py`) inseriu cartas com dados corrompidos:

| Problema | Qtd | Impacto |
|:---------|:---:|:--------|
| `functional_tag='unknown'` (não NULL) | 20 | Classificador cego para 20% do deck |
| `CMC=NULL` | 6 | Cálculos de curva quebrados |
| `CMC=0.0` incorreto (Sol Ring, Mana Vault) | 14+ | DB reporta avg CMC 2.15 vs real ~2.9 |
| `type_line=NULL` | 5 | Keyword detection falha |
| `card_tags` vazio para estas cartas | 20 | Multi-tag classifier também falhou |

O Validator v3.23 detectou isso corretamente e alertou. Mas a raiz do problema (script de importação que pula o classificador) persiste.

---

## Auditoria por Cron (v3.3)

### Scout (f20ac299992b) — 4.0/10 (+0.5)

**O que mudou desde v3.2:**
- ✅ **NÃO foi [SILENT] desta vez.** Scout #36 (18:34) produziu output real — o primeiro não-SILENT em muitas execuções.
- ✅ **Detectou pipeline integrity crisis.** Hash `0b4913e7` divergente de `30d00347`.
- ✅ **Reconheceu que o deck foi reconstruído.** Notou faltam 2 cartas (98/100).

**O que continua errado:**
1. 🔴 **Recomenda cartas sem verificar banlist.** Worldfire (CMC 9) é legal, mas o Scout lista "Fast mana (Crypt...)" sem notar que Mana Crypt é BANIDA.
2. 🔴 **Prompt ainda é "Wincon Hunter".** Busca apenas `card_deck_analysis` — não usa EDHREC JSON API, não faz A+B+C synergy scoring.
3. 🔴 **Não verifica color identity.** Filtra cards da coleção sem checar se são Boros-legais.
4. 🟡 **Wincon list ainda referencia cartas que não estão mais no deck.** O prompt fixo lista "Rise of the Eldrazi, Mizzix's Mastery, Approach..." como wincons do deck — mas a build atual tem wincons diferentes (Twinflame+Dualcaster, Aetherflux, Storm Herd+Akroma's Will).
5. 🟡 **Não detecta double-null cards** — mas desta vez 20 cartas são `'unknown'`, pior que double-null.

**Veredict:** O Scout fez o MÍNIMO necessário (detectou crise de integridade), mas seu prompt fundamentalmente errado (Wincon Hunter em vez de sinergia A+B+C) + falta de verificação de banlist mantém o score baixo. O +0.5 é por ter quebrado o ciclo [SILENT].

---

### Validator (712579b15767) — 8.0/10 (+1.0)

**O que mudou desde v3.2:**
- ✅ **Pipeline integrity crisis detectado com precisão.** Hash divergente em 3 estágios (`30d00347` → `0b4913e7` → `f2241d99`).
- ✅ **Corrupção de dados identificada.** 20 cartas `'unknown'`, 6 `NULL`, 14+ CMC=0.0, 5 type_line=NULL.
- ✅ **Recomendações acionáveis.** TOP 5: corrigir DB, adicionar remoção, re-adicionar Akroma's Will, aumentar basics, executar mulligan.
- ✅ **SYNERGY_MAP recalculado para a NOVA build.** Combo Pieces 9/10, Explosive Mana 8/10, Recursion 8/10 — escores refletem o novo arquétipo cEDH.
- ✅ **Alertou que a build é RECONSTRUÇÃO TOTAL.** Instruiu o Oracle a resetar contador de ciclos e reconstruir logs do zero.
- ✅ **Métricas realistas.** Reportou avg CMC ~2.9 (corrigido do DB 2.15), lands 33, ramp ~12, removal APENAS 3.

**O que continua errado:**
1. 🔴 **Não detecta que Mana Crypt é banida.** A análise de métricas (ramp ~12, fast mana) lista as cartas mas não cruza com banlist.
2. 🟡 **Prompt ainda referencia `card_oracle_data`** (tabela inexistente) em vez de `card_rulings`.
3. 🟡 **PG comparison usa perfil spellslinger** (lands=32, ramp=3.67) contra uma build cEDH (ramp=12). O desvio é reportado como 🔴 mas não é um erro — é um arquétipo diferente.
4. 🔵 **Não detecta que a build tem apenas 2 basic lands.** "33 (2 basic!)" é reportado no output mas sem severidade de CRIT.

**Veredict:** O Validator é o agente MAIS RESILIENTE do pipeline. Detectou a crise, documentou corrupção, recalculou SYNERGY_MAP, e deu recomendações acionáveis. O +1.0 reflete performance superior sob estresse. A falta de verificação de banlist é o gap remanescente mais crítico.

**Melhoria chave vs v3.23:** O Validator deveria adicionar um `## 🚨 BANLIST CHECK` automático em toda execução — query `format_staples` ou Scryfall API para cartas banidas no deck.

---

### Mulligan (08468451a06a) — 7.5/10 (+1.0)

**O que mudou desde v3.2:**
- ✅ **NÃO foi [SILENT].** Executou simulação completa (N=1000, seed=42) na nova build.
- ✅ **Resultados precisos e acionáveis.** T3 = 8.9% (vs 13.3% pré-rebuild), Mulligan = 16.0%, Jogavel = 84.0%.
- ✅ **Detectou DB classifier gap.** Apenas 6 cartas com `functional_tag='ramp'` vs 16 reais. Alertou que se usasse só tags do DB, T3 seria 17.7% (falso).
- ✅ **Cruzou abaixo do limiar DEFENSIVO.** T3 < 12% pela primeira vez em meses.
- ✅ **Identificou manualmente as 16 cartas de ramp reais.** Tabela detalhada no output.
- ✅ **London Mulligan free first mantido.** `bottom_count = max(0, mulligan_count - 1)`.

**O que continua errado:**
1. 🔴 **Não detecta que Mana Crypt (uma das 16 ramp cards) é BANIDA.** O Mulligan simulou mãos contendo uma carta ilegal.
2. 🟡 **Não simula tapped lands.** Ancient Tomb, City of Brass, Gemstone Caverns — algumas dessas entram tapped ou causam dano.
3. 🟡 **Não verifica color requirements.** Com apenas 2 basic lands e muitas lands que produzem colorless (Ancient Tomb, City of Brass), pode haver color screw não detectado.
4. 🟡 **Prompt não especifica seed.** Apesar da skill documentar seed=42 como canônico, o prompt não inclui. O agente usou seed=42 por iniciativa própria.
5. 🔵 **Só avalia mão inicial.** Não simula draws T1-T3.

**Veredict:** O Mulligan provou ser o segundo agente mais resiliente. Executou sob estresse, produziu métricas corretas, e identificou um gap SISTÊMICO (classificador de ramp do DB falha em detectar 10/16 cartas óbvias). O +1.0 reflete a qualidade da Exec#14. A falta de verificação de banlist persiste.

**Melhoria crítica:** Antes de simular, verificar se alguma carta no deck está na banlist. Se sim, flaggear como 🔴 BANLIST VIOLATION e pular a simulação até corrigir.

---

### Battle (94f8590b1beb) — N/A (confirmado: não é cron)

**Status inalterado desde v3.2:**
- Sem entrada em `jobs.json`
- Sem diretório `/opt/data/cron/output/94f8590b1beb/`
- Código `battle_simulator.dart` (879 linhas) existe como protótipo 2-player

**Re-inspeção do código (confirmado):**
- Keywords: ✅ flying, trample, lifelink, deathtouch, first strike, vigilance, haste
- Lifelink: ✅ SEM cap (`active.life += lifeGained`, linha 517)
- Trample: ✅ implementado (linha 497-499)
- First Strike: ✅ timing correto (linha 474-483)
- Stack/Priority: 🔴 NÃO implementado (linha 9: "Sem stack complexo")
- Commander damage: 🔴 NÃO implementado
- Commander tax: 🔴 NÃO implementado
- Multiplayer: 🔴 2-player apenas
- Múltiplos bloqueadores: 🔴 1 blocker/attacker apenas

**Veredict:** Continua NÃO sendo cron. O código é um protótipo de combate que não reflete Commander real (sem stack, sem commander damage/tax, 2-player). NÃO usar para decisões de swap.

---

### Evolution Oracle (a50bef4c2a59) — 1.0/10 (-2.5)

**O que NÃO mudou desde v3.2:**
- 🔴 **Ainda é `no_agent: true`** — script determinístico.
- 🔴 **Output IDÊNTICO** ao de 2026-06-01: "keep current decklist", mesmas 3 prioridades de wincon.
- 🔴 **Lista wincons de uma build que NÃO EXISTE MAIS.** O output diz "fastest: Approach + Topdeck" — mas a build atual não tem Scroll Rack nem Penance. "most_resilient: Rise of the Eldrazi" — não está mais no deck. "stealthiest: Fiery Emancipation + Guttersnipe" — Guttersnipe NÃO está no deck.

**Agravamento crítico (v3.3):**
- 🔴 **O Oracle é completamente cego à reconstrução do deck.** Continua produzindo o mesmo output determinístico independente de qualquer mudança. Scout #36, Validator v3.23, e Mulligan Exec#14 todos detectaram a crise. O Oracle — o agente que DEVERIA sintetizar todos os outros — é o único que não sabe que algo mudou.
- 🔴 **Pipeline Death Loop confirmado e AGRAVADO.** O ciclo: Oracle (0 swaps) → Mulligan ([SILENT] se não houvesse rebuild) → Scout ([SILENT] se não houvesse rebuild) → Oracle (mesmo output). A reconstrução externa do deck quebrou o loop mas o Oracle permanece no estado pré-rebuild.
- 🔴 **Se o deck não tivesse sido reconstruído externamente, o pipeline estaria 100% parado.** O Oracle (script) não aplica swaps → Mulligan não simula → Scout não busca → Validator roda sozinho.

**Veredict:** O Oracle está fundamentalmente quebrado e é o GARGALO do pipeline inteiro. Não é um LLM agent — é um script determinístico que produz o mesmo output há semanas. A reconstrução externa do deck expôs que o Oracle não tem capacidade de detectar mudanças, ler logs de outros agentes, ou tomar decisões. Score caiu de 3.5 → 1.0 porque a reconstrução do deck provou que o Oracle é um NO-OP completo — não apenas ineficaz, mas produzindo recomendações para um deck que não existe mais.

---

## 🚨 BANLIST VERIFICATION — First Confirmed Violation

| Card | Status | Source | In Deck? |
|:-----|:-------|:-------|:--------:|
| **Mana Crypt** | 🔴 BANNED (Sept 2024) | mtgcommander.net | ✅ YES |
| Mox Diamond | ✅ Legal | mtgcommander.net | ✅ YES |
| Chrome Mox | ✅ Legal | mtgcommander.net | ✅ YES |
| Lotus Petal | ✅ Legal | mtgcommander.net | ✅ YES |
| Mana Vault | ✅ Legal | mtgcommander.net | ✅ YES |
| Simian Spirit Guide | ✅ Legal | mtgcommander.net | ✅ YES |

**NENHUM agente detecta esta violação.** Se o Oracle estivesse ativo como LLM agent, poderia recomendar swaps baseados em uma build contendo carta banida.

---

## Mapa de Gaps por Comprehensive Rule (CR) — ATUALIZADO v3.3

| CR | Regra | Scout | Validator | Mulligan | Battle | Oracle |
|:---|:------|:-----:|:---------:|:--------:|:------:|:------:|
| 103.4c | London Mulligan (free first) | N/A | N/A | ✅ | N/A | N/A |
| 117.3-117.4 | Priority/Stack | N/A | N/A | N/A | 🔴 | N/A |
| 405.4 | Stack LIFO | N/A | N/A | N/A | 🔴 | N/A |
| 702.94 | Miracle timing | N/A | N/A | 🔵 | N/A | N/A |
| 704 | State-Based Actions | N/A | N/A | N/A | 🔴 | N/A |
| 903.5 | Color Identity | 🔴 | ✅ | 🟡 | N/A | 🔴 |
| 903.8 | Commander Tax | N/A | N/A | N/A | 🔴 | N/A |
| 903.10a | Commander Damage | N/A | N/A | N/A | 🔴 | N/A |
| 903.13a | **Commander Banlist** | 🔴 | 🔴 | 🔴 | N/A | 🔴 |
| 903.13b | Deck size (100 cards) | 🟡 | 🟡 | N/A | N/A | N/A |

**Legenda:** ✅ Correto | 🟡 Parcial/implícito | 🔴 Não implementado | 🔵 Não verificado | N/A Não aplicável

---

## Novo Mapa: Resiliência a Reconstrução Externa do Deck

A reconstrução total do deck em ~1h expôs a resiliência de cada agente:

| Agente | Detectou rebuild? | Recalculou métricas? | Produziu output útil? | Tempo de reação |
|:-------|:-----------------:|:--------------------:|:---------------------:|:---------------|
| Scout | ✅ Sim (hash divergente) | ✅ Sim (wincon query) | 🟡 Parcial (recomenda Worldfire s/ checar banlist) | ~34 min |
| Validator | ✅ Sim (3 hashes) | ✅ Sim (SYNERGY_MAP refeito) | ✅ Sim (TOP 5 recomendações) | ~44 min |
| Mulligan | ✅ Sim (hash divergente) | ✅ Sim (N=1000) | ✅ Sim (T3=8.9%, gap de classificador) | ~52 min |
| Oracle | 🔴 NÃO | 🔴 NÃO | 🔴 NÃO (output da build antiga) | 🔴 NUNCA |
| Battle | N/A | N/A | N/A | N/A |

---

## Plano de Correções (Ordenado por Impacto) — ATUALIZADO v3.3

| # | Prioridade | Cron | Ação | Impacto | Novo? |
|:--|:----------|:-----|:-----|:--------|:------|
| 1 | 🔴🔴 CRÍTICO | **ALL** | **Adicionar BANLIST CHECK em todos os agentes.** Query `format_staples WHERE is_banned=true` antes de qualquer análise. Se detectar carta banida, ABORTAR e reportar. | Mana Crypt no deck torna TODAS as análises inválidas | 🆕 |
| 2 | 🔴🔴 CRÍTICO | Oracle | **Restaurar como LLM agent URGENTE.** Remover `no_agent: true`. Reescrever prompt para: (a) ler 4 logs de agentes, (b) verificar banlist, (c) sintetizar recomendações. | Pipeline inteiro PARADO. Oracle atual é NO-OP. | = |
| 3 | 🔴 CRÍTICO | Oracle | **Resetar pipeline para nova build.** Contador C#24 → Ciclo #1 da nova build. Reconstruir EVOLUTION_LOG do zero. | Build atual é deck NOVO, não evolução do spellslinger. | 🆕 |
| 4 | 🔴 CRÍTICO | Scout | Restaurar prompt original A+B+C (EDHREC JSON API + coleção + sinergia). Wincon Hunter é seção, não prompt. | 94% [SILENT] histórico. Precisa detectar cartas novas. | = |
| 5 | 🔴 CRÍTICO | — | **Corrigir `import_lorehold_decks.py`** para rodar classificador após inserção em massa. Re-classificar 20 cartas com `functional_tag='unknown'`. | Dados corrompidos invalidam todas as métricas. | 🆕 |
| 6 | 🔴 CRÍTICO | — | **Remover Mana Crypt do deck.** Carta BANIDA desde Set 2024. | Deck atual é ILEGAL para Commander. | 🆕 |
| 7 | 🟡 ALTO | Mulligan | Adicionar seed fixo (`random.seed(42)`) no prompt. Simular tapped lands + color requirements. | T3 real é 3-8pp pior que reportado. | = |
| 8 | 🟡 ALTO | Mulligan | Rodar simulação a cada 3-4 ciclos mesmo sem mudanças. | Confirma estabilidade. | = |
| 9 | 🟡 ALTO | Mulligan | Verificar `functional_tag='ramp'` count antes de simular. Se < 8 em deck com fast mana óbvio, usar classificação manual. | Gap de classificador infla T3 em 8.8pp. | 🆕 |
| 10 | 🔵 MÉDIO | Validator | Corrigir prompt: `card_oracle_data` → `card_rulings` | Evita confusão. | = |
| 11 | 🔵 MÉDIO | Validator | Adicionar tema-awareness: detectar arquétipo (spellslinger vs cEDH combo) e ajustar PG comparison. | Ranges atuais são para spellslinger, não cEDH. | 🆕 |
| 12 | 🔵 MÉDIO | Scout | Adicionar filtro de color identity explícito. | Previne recomendar cartas off-color. | = |

---

## Conclusão

A pipeline Lorehold tem confiabilidade **BAIXA (4.0/10, -1.1 vs v3.2)** em relação às regras oficiais de MTG Commander.

**A reconstrução externa do deck foi um teste de estresse que expôs 3 falhas fundamentais:**

1. **Oracle é um NO-OP.** Script determinístico que produz o mesmo output há semanas, completamente cego à reconstrução do deck. É o agente mais crítico do pipeline (deveria sintetizar todos os outros) e está 100% quebrado.

2. **NENHUM agente verifica a banlist.** Pela primeira vez, uma carta banida (Mana Crypt) entrou no deck. Nenhum dos 4 agentes detectou. Se o Oracle estivesse ativo, poderia recomendar swaps baseados em deck ilegal.

3. **Importação em massa corrompe dados.** 20 cartas com `functional_tag='unknown'`, CMCs errados, type_line=NULL. O classificador nunca rodou. Isso afeta todas as métricas downstream.

**Pontos fortes (confirmados sob estresse):**
- Validator (8.0/10): Detectou crise, corrupção, refez SYNERGY_MAP, deu TOP 5 recomendações.
- Mulligan (7.5/10): Simulou build nova com métricas corretas, identificou gap sistêmico do classificador.
- Scout (4.0/10): Pelo menos quebrou o ciclo [SILENT] e detectou a crise.

**Para restaurar o pipeline à funcionalidade:**
1. **Imediato:** Remover Mana Crypt do deck (ilegal).
2. **Imediato:** Corrigir `import_lorehold_decks.py` + re-classificar 20 cartas.
3. **Curto prazo:** Transformar Oracle de script-only → LLM agent (remover `no_agent: true`).
4. **Curto prazo:** Adicionar BANLIST CHECK em todos os 4 agentes.
5. **Médio prazo:** Restaurar Scout para A+B+C synergy scoring.
6. **Médio prazo:** Corrigir Mulligan (seed fixo, tapped lands, color requirements).

**Status atual do deck (2026-06-02T19:00Z):** cEDH turbo-combo, 100 cards, T3 8.9%, ⚠️ CONTÉM CARTA BANIDA (Mana Crypt), ⚠️ dados corrompidos no DB.

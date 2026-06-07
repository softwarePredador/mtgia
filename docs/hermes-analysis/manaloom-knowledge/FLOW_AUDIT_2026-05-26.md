# Auditoria de Fluxo — ManaLoom Hermes

> Auditoria completa do ecossistema de crons, dados, e fluxo do projeto.
> Data: 2026-05-26

---

## 1. Status dos 12 Crons

| # | Cron | Schedule | Status | Ultima exec | Observacao |
|:-:|:-----|:--------:|:------:|:-----------:|:-----------|
| 1 | master-watchdog | 30min | **OK** | 19:49 | Script shell, sem agente |
| 2 | hermes-normal-audit | 16h,21h | **OK** | 16:18 | Auditoria normal |
| 3 | hermes-daily-deep-audit | 11:30 | **NUNCA RODOU** | - | Agenda amanha |
| 4 | hermes-weekly-memory-cleanup | Dom 12h | **NUNCA RODOU** | - | Agenda domingo |
| 5 | hermes-weekly-parallel-audit | Dom 12:30 | **NUNCA RODOU** | - | Agenda domingo |
| 6 | commander-knowledge-deep | 20min | **REATIVADO** | 18:19 (erro) | Estava travado (next_run_at=null). Re-triggered |
| 7 | gamechanger-research | 20min | **REATIVADO** | 17:22 (ok) | Estava travado. Re-triggered |
| 8 | themes-research | 20min | **REATIVADO** | 17:51 (erro) | Estava travado. Re-triggered |
| 9 | missing-gc-filler | 20min | **AGENDADO** | - | Primeira exec pendente |
| 10 | manager-watchdog | 30min | **AGENDADO** | - | Primeira exec pendente |
| 11 | tag-accuracy-reporter | 6h | **AGENDADO** | - | Primeira exec 01:55 |
| 12 | mana-base-validator | 60min | **AGENDADO** | - | Primeira exec 20:55 |

### Problemas Encontrados e Corrigidos

- **3 crons travados** com `next_run_at=null` apos troca de branch — re-triggered manualmente
- **Cron gerencial** (`manager-watchdog`) ainda nao rodou — vai detectar automaticamente futuras paradas
- **5 crons nunca rodaram** — diario e semanais so executam em seus horarios agendados

---

## 2. Dados no SQLite

| Tabela | Linhas | Observacao |
|:-------|:-----:|:-----------|
| commanders | 3 | Faltam: Atraxa (tem .md mas nao foi inserida no DB) |
| decks | 3 | 3 decks inseridos: Kinnan, Yuriko, Korvold |
| deck_cards | 108 | 108 cartas analisadas (media 36/deck) |
| card_analyses | 108 | 108 analises psicologicas |
| game_changers | 53 | 53 GCs inseridos |
| discrepancies | 15 | 15 discrepancias com ManaLoom |
| insights | 15 | 15 insights documentados |
| tag_accuracy | 20 | 20 combinacoes de tag |
| deck_themes | 5 | 5 temas registrados |
| theme_detection_rules | 10 | 10 regras de deteccao |
| patterns | 0 | **VAZIO** — precisa de cron para preencher |
| psychology_profiles | 0 | **VAZIO** — precisa de cron para preencher |
| synergies | 0 | **VAZIO** — precisa de cron para preencher |
| vocabulary | 0 | **VAZIO** — precisa de cron para preencher |
| run_log | 3 | 3 execucoes registradas |

### Problemas Encontrados

- **Atraxa nao esta no SQLite** — o deck foi analisado (501 linhas de markdown) mas nunca inserido no banco
- **4 tabelas vazias** — patterns, psychology_profiles, synergies, vocabulary — NENHUM cron preenche elas
- **53 GCs inseridos mas so 2 com analise** — why_game_changer preenchido para apenas 2/53
- **Tag 'ninja' com 0% precisao** — 17 cartas classificadas como 'ninja', 0 corretas (bug na classificacao do Yuriko)

---

## 3. Pesquisas Web — Coerencia

| Deck | Fonte | Coerente? |
|:-----|:------|:----------|
| Kinnan | Artefato EDHTop16 + meu conhecimento | **PARCIAL** — usei conhecimento interno para 80% da analise |
| Atraxa | EDHREC avg (41.130 decks) + meu conhecimento | **PARCIAL** — dados EDHREC reais, mas analise minha |
| Yuriko | EDHREC avg (30.9k decks) | **OK** — fonte web real, cron com fontes |
| Korvold | EDHREC avg (19.646 decks) | **OK** — fonte web real |
| Ancient Tomb | Scryfall + EDHREC | **OK** — fonte web real |
| Ad Nauseam | Scryfall + EDHREC | **OK** — fonte web real |

### Conclusao:
- **Deck #1 (Kinnan):** conhecimento interno — PRECISA SER REEXECUTADO com fontes web
- **Deck #2 (Atraxa):** parcialmente web + conhecimento interno
- **Decks #3-4 (Yuriko, Korvold):** web real — corretos
- **GCs #1-2 (Ancient Tomb, Ad Nauseam):** web real — corretos

---

## 4. Fluxo do Projeto — Analise de Coerencia

### Fluxo Atual

```
Cron de conhecimento (20min)
  ├── Busca dados de fonte (web / artefatos / EDHREC)
  ├── Analisa em 3 camadas (estrutura, psicologia, mental model)
  ├── Salva markdown em docs/hermes-analysis/manaloom-knowledge/decks/
  └── (DEVERIA salvar no SQLite mas nem sempre faz)

Cron de GCs (20min)
  ├── Busca 1 GC sem analise no SQLite
  ├── Pesquisa na web (Scryfall + EDHREC)
  ├── Atualiza why_game_changer no SQLite
  └── Commit

Cron de temas (20min)
  ├── Pesquisa 1 tema
  ├── Atualiza deck_themes no SQLite
  └── Commit

Cron gerencial (30min)
  ├── Lista todos os crons
  ├── Reativa os que estao travados
  └── Atualiza CRON_STATUS.md
```

### Gargalos Identificados

| Gargalo | Impacto | Solucao |
|:--------|:--------|:--------|
| 4 tabelas vazias (patterns, profiles, synergies, vocabulary) | Conhecimento nao estruturado | Criar cron para preencher |
| SQLite nao tem todos os decks (Atraxa faltando) | Dados inconsistentes | O cron precisa SEMPRE inserir no DB |
| 51/53 GCs sem analise | Base incompleta | Os 3 crons de 20min vao preencher em ~17h |
| Tag 'ninja' com 0% | Classificacao errada | Validar functional_tags para "ninja" |
| Scorecard nunca completou | Sem validacao pos-patch | Rodar com --limit 1 para testar |
| .git/objects com 9 dirs root | Git commit falha | Limpeza eventual necessaria |

### O Que Esta Funcionando Bem

- **599/599 testes offline** PASS
- **173/177 testes live** PASS (4 skip)
- **Patches P0 aplicados** em master (f57bb8d3) e codex/hermes-dev
- **4 decks analisados** com ~200 cartas revisadas
- **15 insights e 15 discrepancias** documentadas
- **Tag accuracy:** ramp/draw/removal/tutor/land = 100% (excelente)

---

## 5. Recomendacoes

### Critico (imediato)
1. Inserir Atraxa no SQLite (deck analisado mas nao registrado)
2. Criar cron `manaloom-knowledge-patterns` para preencher patterns + synergies + vocabulary
3. Validar tag 'ninja' — 0% precisao, possivel bug no classificador

### Importante (curto prazo)
4. Rodar scorecard com `--limit 1` contra servidor local
5. Re-analisar Kinnan deck com fontes web reais (EDHREC)
6. Limpar .git/objects root-owned dirs

### Melhoria Continua
7. Aumentar cobertura de tag_accuracy para todas as 29 functional tags
8. Adicionar psicologia de deckbuilding ao fluxo (perfis de jogador)
9. Conectar patterns + synergies ao fluxo de otimizacao

---

## 6. Metricas de Saude do Projeto

| Metrica | Valor | Alvo | Status |
|:--------|:-----:|:----:|:------|
| Testes offline | 599/599 | 600+ | **OK** |
| Testes live | 173/177 | 190+ | OK (+4 skip) |
| Comandantes analisados | 4 | 50+ | Em progresso |
| GCs analisados | 2/53 | 53/53 | 20h restantes |
| Precisao tags (boas) | 100% | 95%+ | **OK** |
| Precisao tags (ruins) | 0-50% | 80%+ | **PRECISA ATENCAO** |
| Crons ativos | 12/12 | 12 | **OK** (3 reativados) |
| Tabelas DB com dados | 11/15 | 15/15 | Faltam 4 |
| Documentos criados | 14 | 20+ | Em progresso |
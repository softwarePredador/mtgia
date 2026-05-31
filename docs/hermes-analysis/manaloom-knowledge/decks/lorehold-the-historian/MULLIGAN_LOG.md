## Verificacao -- 2026-05-31T20:59:07+00:00 (Sem Mudancas -- Ciclo #13 = 0 Swaps, 3o ciclo consecutivo)

### Estado
- Evolution Oracle Ciclo #13 (2026-05-31T20:59:07+00:00): **0 SWAPS** -- 3o ciclo consecutivo sem swaps (C#11, C#12, C#13)
- Deck state: 35 lands, 100 cards, identico a Execucao #11
- Sem Play T3 canonico: **13.3%** (Execucao #11, N=1000, seed=42)
- Mulligan: **47.9%**, Jogaveis: **46.7%**, Ramp T1 (Sol Ring only): **6.3%**
- SCOUT #22 (20:51) propos 7 novos candidatos -- todos rejeitados pelo framework Necessidade/Evidencia

### Decisao
**Simulacao NAO executada.** O Evolution aplicou ZERO swaps pelo 3o ciclo consecutivo.
O deck e identico ao estado pos-Ciclo #10.
Re-executar N=1000 reproduziria 13.3% com ruido de +-2.1pp.

### Estrategia para Proximo Ciclo
- **T3 = 13.3% > 12% → DEFENSIVO obrigatorio.**
- Colecao ESGOTADA de cartas CMC <= 2 com sinergia. 38 cartas, 0 com Necessidade >= 3.
- Proximo upgrade requer AQUISICAO: Skullclamp (CMC 1, draw engine).
- Estado do deck: MATURIDADE ATINGIDA -- 25 swaps desde baseline, motor 4/4, copy 6, SYNERGY_MAP 7 eixos 6-9/10, Nivel 1 VAZIO.

---

## Verificacao — 2026-05-31T20:14:29+00:00 (Sem Mudancas — Ciclo #11 = 0 Swaps)

### Estado
- Evolution Oracle Ciclo #11 (2026-05-31T19:10): **0 SWAPS** — colecao esgotada, deck saudavel
- Deck state: 35 lands, 100 cards, identico a Execucao #11
- Sem Play T3 canonico: **13.3%** (Execucao #11, N=1000, seed=42)
- Mulligan: **47.9%**, Jogaveis: **46.7%**, Ramp T1 (Sol Ring only): **6.3%**

### Decisao
**Simulacao NAO executada.** O Evolution rodou (19:10) apos a ultima execucao de mulligan (19:03),
mas aplicou ZERO swaps. O deck e identico — re-executar N=1000 reproduziria 13.3% com ruido de +-2.1pp.

### Estrategia para Proximo Ciclo
- **T3 = 13.3% > 12% → DEFENSIVO obrigatorio.**
- Porem, colecao ESGOTADA de cartas CMC <= 2 com sinergia. 38 candidatos avaliados no Ciclo #11, nenhum atinge Necessidade >= 3.
- **Proximo upgrade requer AQUISICAO:** Skullclamp (CMC 1, draw engine).
- Estado do deck: MATURIDADE ATINGIDA — 25 swaps desde baseline, motor 4/4, copy 6, SYNERGY_MAP 7 eixos 6-9/10, Nivel 1 VAZIO.

---

## Execucao #11 -- Pos-Ciclo #10 (2026-05-31T19:02:35+00:00)

### Deck state: 35 lands, 64 nonlands. Ciclo #10 swaps: Ruby Medallion -> Twinflame, Galvanoth -> Flare of Duplication. Net DCMC = -2.
25 swaps totais desde baseline (C#1:3, C#2:3, C#3:5, C#4:3, C#5:3, C#6:2, C#7:1, C#8:0, C#9:1, C#10:2).

### Resultados (seed=42, N=1000, definicao rigorosa)

| Metrica | Pos-C#9 (Exec#10) | Pos-C#10 (Exec#11) | D |
|:--------:|:----------------:|:------------------:|:-:|
| Jogaveis | 46.3% | **46.7%** | +0.4pp |
| Mulligan | 49.3% | **47.9%** | -1.4pp |
| Ramp T1 (3 cartas) | 20.1% | **18.7%** | -1.4pp |
| Ramp T1 (Sol Ring only) | ~7% | **6.3%** | -0.7pp |
| Sem Play T3 | 16.9% | **13.3%** | **-3.6pp** |

### Distribuicao de Lands na Mao Inicial

| Lands | Maos | % |
|:-----:|:----:|:-:|
| 0 | 50 | 5.0% |
| 1 | 186 | 18.6% |
| 2 | 306 | 30.6% |
| 3 | 289 | 28.9% |
| 4 | 111 | 11.1% |
| 5 | 54 | 5.4% |
| 6 | 4 | 0.4% |
| 7 | 0 | 0.0% |

### Analise do Delta

**Sem Play T3 -3.6pp (16.9% -> 13.3%):** O net DCMC=-2 produziu uma melhoria MAIOR que a projetada (-1.9pp vs -3.6pp real). O swap Galvanoth (CMC 5, nao-castavel com <=3 lands) -> Flare of Duplication (CMC 3, castavel com 3 lands) foi o responsavel. Em maos com 3 lands (28.9%), ter Flare em vez de Galvanoth transforma uma mao "sem play T3" em jogavel. A melhoria observada esta no limite superior do IC95% (13.3% +- 2.1pp).

**Comparacao com projecao do Evolution Oracle (Ciclo #10):** O Evolution Oracle projetou T3 ~15% (-1.9pp). O resultado real foi 13.3% (-3.6pp). O impacto foi quase o DOBRO do projetado. Motivo: Flare de Duplication nao apenas reduz CMC — ele E um instant que pode ser jogado FREE (sacrificando criatura vermelha), criando linhas de jogo em T1-T3 que Galvanoth nunca oferecia.

**Jogaveis +0.4pp (46.3% -> 46.7%):** Estatisticamente neutro (IC95% = +-2.8pp). O limite estrutural de ~47% com 35 lands e apenas 3 fontes de T1 ramp permanece.

**Mulligan -1.4pp (49.3% -> 47.9%):** Dentro do ruido (IC95% = +-2.8pp). A reducao e consistente com DCMC=-2, mas nao significativa.

**Ramp T1 (3 cartas) -1.4pp (20.1% -> 18.7%):** Ruido estatistico. Nenhuma das cartas de T1 ramp foi alterada no Ciclo #10. Este valor oscila naturalmente +-4pp entre execucoes.

**Ramp T1 (Sol Ring only) 6.3%:** Valor canonico estrito — apenas Sol Ring gera mana T1. Este e o numero que importa para comparacao cross-execution. 6.3% e consistente com a taxa teorica (1/99 * 7 * 1000 = ~7.0%).

### Impacto dos Swaps do Ciclo #10

**Swap 1: Ruby Medallion (CMC 2) -> Twinflame (CMC 2) — DCMC=0, sem impacto no T3.**
Medallion era cost reduction redundante em deck com 14 fontes de ramp. Twinflame expande copy layer + interage com Surge/Akroma's Will. Mesmo CMC — nao afeta T3.

**Swap 2: Galvanoth (CMC 5) -> Flare of Duplication (CMC 3) — DCMC=-2, responsavel pela melhoria no T3.**
Galvanoth era uma criatura 3/3 que precisava sobreviver 1 turno para ativar — raramente acontecia em Commander. Flare de Duplication e um instant CMC 3 (ou FREE sacrificando criatura) que copia spells. Impacto no T3:
- Com 3 lands: Flare e castavel (CMC 3 <= 3), Galvanoth nao era (CMC 5 > 3)
- P(3 lands) = 28.9%, P(Flare em opening 7) = 7.1% -> ~2.0pp de melhoria direta
- Efeito adicional: Flare FREE com sacrificio permite jogadas T1-T3 com mana livre para outros spells

### T3 por Ciclo (linha do tempo completa)

| Ciclo | Swaps | Net DCMC | Estrategia | T3 medido | Fonte |
|:-----:|:------|:--------:|:----------|:---------:|:------|
| C#0 | -- | -- | -- | 3.3% | Exec#1 |
| C#1 | 3 | +3 | AGGRESSIVE | 12.4% | Exec#3 |
| C#2 | 3 | +7 | AGGRESSIVE | 16.5% | Exec#5 |
| C#3 | 5 | -4 | DEFENSIVO | 16.4% | Exec#7 |
| C#4 | 3 | -15 | DEFENSIVO | 12.0% | Exec#8 |
| C#5 | 3 | +1 | BALANCED | 15.3% | Exec#9 |
| C#6 | 2 | -2 | DEFENSIVO | ~13-14% | Estimado |
| C#7 | 1 | +2 | AGGRESSIVE* | ~14-15% | Estimado |
| C#8 | 0 | 0 | -- | ~14-15% | Estimado |
| C#9 | 1 | +2 | AGGRESSIVE* | 16.9% | Exec#10 |
| C#10 | 2 | -2 | DEFENSIVO | **13.3%** | **Exec#11** |

*Ciclos #7/#8/#9 usaram T3=3.7% (free mulligan rate) em vez do Sem Play T3 correto — ver Pitfall #19.

### Estrategia para Ciclo #11

**Sem Play T3 = 13.3% > 12% -> DEFENSIVO obrigatorio.** Net DCMC necessario: -5 a -15.

Porem, colecao esgotada de cartas CMC <= 2 com alta sinergia para Lorehold.
Apos 25 swaps, as opcoes restantes sao:
- CMC 3-4 com sinergia media (pioram T3 se substituirem CMC 1-2)
- Cartas CMC 1-2 sem sinergia (filler — pior que manter cartas declining)
- **Aquisicao de Skullclamp (CMC 1, draw engine) e a unica saida real para reduzir T3 abaixo de 12%.**

**Recomendacao para C#11:** 0 swaps se colecao ainda esgotada. Priorizar AQUISICAO de:
1. Skullclamp (CMC 1) — draw engine com tokens, maior impacto por dolar
2. Chrome Mox (CMC 0) — fast mana T0, reduz T3 em ~2pp sozinho
3. Mana Vault (CMC 1) — fast mana T1, reduz T3 em ~1.5pp

### O Que Essa Metrica Significa

**Sem Play T3 = 13.3%** significa que ~1 em cada 7.5 partidas abre sem nenhuma carta nao-terreno jogavel nos 3 primeiros turnos. Melhorou de ~1 em 6 (16.9%). O Ciclo #10 foi o primeiro ciclo com T3 correto e a estrategia DEFENSIVA funcionou — -3.6pp com apenas -2CMC net. O deck esta na direcao certa, mas ainda na zona DEFENSIVE (>12%). Sem aquisicoes, o T3 provavelmente estabilizara em 12-15% — o limite estrutural de um deck Boros big-spells com 35 lands.

**Mulligan de 47.9%** e um artefato da definicao estrita (2 lands sem ramp = mulligan). Na pratica, maos com 2 lands + Top/Scroll Rack/Esper Sentinel sao keepable. O jogador real provavelmente sente ~35-40% de mulligan, nao 48%.

**Jogaveis de 46.7%** e o complemento: ~47% das maos sao claramente boas. As restantes (~5-6%) sao maos borderline (5 lands com T1 ramp) que nem sao jogaveis nem mulligan — decisao situacional.

---

*Simulacao: 1000 maos de 7 cartas do deck de 99 com random.shuffle(), seed=42.*
*Definicao rigorosa: Jogavel = 2-4 lands + (ramp T1 OU 3+ lands). Mulligan = 0-1 lands OU 2 lands sem ramp OU 6+ lands.*
*Ramp T1 (para jogavel/mulligan) = Sol Ring, Land Tax, Weathered Wayfarer.*
*Ramp T1 estrito (para metrica cross-execution) = Sol Ring only.*
*Sem Play T3 = nenhuma carta nao-terreno com CMC <= min(lands, 3). IC95% = +-2.1pp.*
*London Mulligan: primeiro mulligan gratis (0 cartas no fundo).*

--------|:-----:|
| Jogaveis | 46.3% |
| Mulligan | 49.3% |
| Ramp T1 (estrito) | 20.1% |
| Sem Play T3 | 16.9% |

**Acao requerida:** Executar Mulligan Tester (lorehold-mulligan-analyst) com N=1000, seed=42,
definicao rigorosa, para medir impacto do DCMC=-2 no Sem Play T3.

---

## Execucao #11 -- Sem Mudancas (pos-Ciclo #9) (2026-05-31T17:42:47+00:00)

### Status: Deck nao mudou desde a ultima simulacao

Nenhum novo ciclo de evolution aplicado desde Execucao #10 (2026-05-31T14:41:24+00:00).
O deck permanece no estado pos-Ciclo #9 (Pearl Medallion -> Akroma's Will).

**Metricas estaveis (Execucao #10, N=1000, seed=42):**

| Metrica | Valor |
|:--------|:-----:|
| Jogaveis | 46.3% |
| Mulligan | 49.3% |
| Ramp T1 (estrito) | 20.1% |
| **Sem Play T3** | **16.9%** |

**Estrategia ativa para Ciclo #10:** DEFENSIVO (T3 16.9% > 12%). Net DCMC necessario: -5 a -15.
Alerta: colecao esgotada de cartas CMC <= 2 com EDHREC alto para Lorehold.

**O que essa metrica significa:** Sem mudancas no deck, a consistencia early-game permanece identica.
O Mulligan Tester so executa simulacao completa quando o deck muda. Execucoes "no-change"
economizam recursos computacionais e evitam ruido estatistico desnecessario.

---

# Mulligan Log — Lorehold Spellslinger

## Execucao #10 -- Pos-Ciclo #9 (2026-05-31T14:41:24+00:00)

### Deck state: 35 lands, 64 nonlands. 23 swaps desde baseline.
4 ciclos aplicados desde ultima simulacao (Exec#9 pos-C#5):
- C#6 (DEFENSIVO): Goldspan Dragon -> Wedding Ring, Seething Song -> Abrade. Net DCMC = -2.
- C#7 (AGGRESSIVE): Galadriel's Dismissal -> Victory Chimes. Net DCMC = +2.
- C#8: 0 swaps (deck saudavel, colecao esgotada de upgrades CMC 1-2).
- C#9 (AGGRESSIVE): Pearl Medallion -> Akroma's Will. Net DCMC = +2.
Total net DCMC desde Exec#9: +2.

### Resultados (seed=42, N=1000, definicao rigorosa)

| Metrica | Pos-C#5 (Exec#9) | Pos-C#9 (Exec#10) | D |
|:--------:|:----------------:|:-----------------:|:-:|
| Jogaveis | 48.0% | **46.3%** | -1.7pp |
| Mulligan | 52.0% | **49.3%** | -2.7pp |
| Ramp T1 (estrito) | 21.2% | **20.1%** | -1.1pp |
| Sem Play T3 | 15.3% | **16.9%** | **+1.6pp** |

### Distribuicao de Lands na Mao Inicial

| Lands | Maos | % |
|:-----:|:----:|:-:|
| 0 | 37 | 3.7% |
| 1 | 208 | 20.8% |
| 2 | 302 | 30.2% |
| 3 | 284 | 28.4% |
| 4 | 116 | 11.6% |
| 5 | 44 | 4.4% |
| 6 | 9 | 0.9% |

### Analise do Delta

**Sem Play T3 +1.6pp (15.3% -> 16.9%):** O net DCMC +2 desde o Ciclo #5 produziu o efeito esperado de ~0.8pp por +1 CMC liquido. Projecao era +2-4pp; real foi +1.6pp, dentro do esperado. T3 agora esta 4.9pp acima do limite de 12%.

**Jogaveis -1.7pp (48.0% -> 46.3%):** Dentro do ruido estatistico (IC95% = +/-2.8pp). A metrica ~47% e um limite estrutural: com 35 lands e apenas 3 fontes de T1 ramp estrito, P(2 lands sem ramp) = ~24% de todas as maos.

**Mulligan -2.7pp (52.0% -> 49.3%):** Dentro do ruido. Melhora aparente mas nao significativa estatisticamente. A taxa de ~50% e estrutural para 35 lands em Boros.

### Impacto dos Swaps por Ciclo (pos-C#5)

| Ciclo | Swaps | Net DCMC | Estrategia | T3 medido/estimado |
|:-----:|:------|:--------:|:----------|:-------------------|
| C#5 | 3 | +1 | BALANCED | 15.3% (Exec#9 medido) |
| C#6 | 2 | -2 | DEFENSIVO | ~13-14% (estimado) |
| C#7 | 1 | +2 | AGGRESSIVE | ~14-15% (estimado) |
| C#8 | 0 | 0 | -- | ~14-15% (sem mudanca) |
| C#9 | 1 | +2 | AGGRESSIVE | 16.9% (Exec#10 medido) |

**Nota sobre T3=3.7% do Evolution Oracle:** O Evolution Oracle Ciclo #8 referenciava 'Sem Play T3 = 3.7% (pos-C#6)'. Esta medicao NAO foi reproduzida com N=1000, seed=42, mesma definicao rigorosa. O valor 3.7% coincide EXATAMENTE com a taxa de free mulligan (0 ou 7 lands na mao inicial). O Evolution Oracle provavelmente usou uma definicao incorreta de 'Sem Play T3'. O valor correto para pos-C#6, consistente com a trajetoria 15.3% -> +1.6pp (net +2 CMC) = 16.9%, seria ~13-14% (15.3% - ~2pp do C#6 DEFENSIVO).

### Estrategia para Ciclo #10

**Sem Play T3 = 16.9% > 12% -> DEFENSIVO obrigatorio.** Net DCMC necessario: -5 a -15.

**Alerta de colecao esgotada:** Apos 23 swaps, a colecao tem poucas cartas CMC <= 2 com EDHREC alto para Lorehold. Candidatos defensivos viaveis (se na colecao):
- Fated Clash (CMC 5, 15.6%, trend -0.19) e o unico corte claro de CMC alto com baixo impacto
- Se Skullclamp (CMC 1) ou Mana Vault (CMC 1) entrarem na colecao, seriam upgrades defensivos ideais

**Recomendacao:** Se nao houver candidatos CMC <= 2 na colecao, documentar esgotamento e recomendar aquisicoes. Forcar swaps de baixa qualidade pior que 0 swaps.

### O Que Essa Metrica Significa

**Sem Play T3 = 16.9%** significa que ~1 em cada 6 partidas abre sem nenhuma carta jogavel nos 3 primeiros turnos. E o valor mais alto registrado desde o inicio do pipeline (pico anterior: 16.5% na Exec#5 pos-Ciclo #2). O deck acumulou poder no mid-late game (motor 4/4, copy 3/3, 8+ wincon paths) as custas de consistencia early-game.

**Mulligan de 49.3%** nao significa que metade das partidas comeca mal -- significa que, pela definicao ESTRITA (2 lands SEM ramp = mulligan), ~49% das maos iniciais tem risco. Na pratica, muitos jogadores mantem maos com 2 lands e sem ramp se tiverem Top, Scroll Rack, ou Esper Sentinel -- cartas que 'corrigem' a mao. A taxa real de mulligan 'sentida' e provavelmente 35-40%, nao 49%.

**Ramp T1 de 20.1%** e estavel. Com apenas 3 cartas no deck de 99 que geram mana T1, a taxa teorica e ~19.7%. Este e o limite do formato Boros sem fast mana adicional (Mana Vault, Chrome Mox).

---

*Simulacao: 1000 maos de 7 cartas do deck de 99 com random.shuffle(), seed=42.*
*Definicao rigorosa: Jogavel = 2-4 lands + (ramp T1 OU 3+ lands). Mulligan = 0-1 lands OU 2 lands sem ramp OU 6+ lands.*
*Ramp T1 estrito = Sol Ring, Land Tax, Weathered Wayfarer.*
*Sem Play T3 = nenhuma carta nao-terreno com CMC <= min(lands, 3). IC95% = +/-2.8pp.*

---

## [2026-05-27 03:01:58 UTC] Execução #1 — Baseline (34 lands)

### Resultados

| Métrica | Valor | Status |
|---------|-------|--------|
| Mãos jogáveis (2-4 lands + play early) | 70.1% | ✅ |
| Precisam de mulligan (0-1 lands ou 2 sem ramp) | 23.9% | 🟡 |
| Ramp turno 1 (Sol Ring ou similar) | 13.6% | ✅ |
| Sem play até turno 3 | 3.3% | ✅ |

## [2026-05-27T13:14:33+00:00] Execução #2 — Pós-Evolution (35 lands)

| Métrica | Resultado | Leitura |
|:--------|:---------|:--------|
| Mãos jogáveis | 70.6% | 2-4 lands + pelo menos 1 spell CMC≤3 |
| Mulligan | 23.0% | 0-1 lands ou 6-7 lands |
| Ramp turno 1 | 18.4% | inclui ramp/ritual não-land CMC≤1 |
| Ramp turno 1-2 | 35.1% | ramp/ritual não-land CMC≤2 |
| Removal até turno 3 | 18.5% | removal/board_wipe CMC≤3 na mão |
| Sem play até T3 | 8.8% | sem spell castável CMC≤3 ou sem land |
| Lands médias na mão | 2.38 | distribuição normal para 35 lands |
| CMC médio das spells na mão | 3.80 | só não-terrenos |

## [2026-05-27T19:50:00+00:00] Execução #3 — Pós-Evolution confirmado

### Deck state: 35 lands, 64 nonlands, swaps aplicados (Furygale→Esper Sentinel, Jokulhaups→Gamble, Karoo→Plains)

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis | 73.2% | ✅ |
| Mulligan | 26.8% | 🔴 |
| Ramp turno 1 | 25.4% | ✅ |
| Sem play até T3 | 12.4% | 🟡 |

### Delta vs Execução #2

| Métrica | Antes | Agora | Δ |
|:--------|:-----|:-----|:-:|
| Jogáveis | 70.6% | 73.2% | +2.6pp |
| Mulligan | 23.0% | 26.8% | +3.8pp |
| Ramp T1 | 18.4% | 25.4% | +7.0pp |
| Sem play T3 | 8.8% | 12.4% | +3.6pp |

| ### Conclusão
|
|As trocas foram estatisticamente neutras para mulligan. Variação dentro do ruído (±3pp para N=1000). O ponto crítico real é "sem play T3" em 12.4% — deck precisa de mais spells baratas.|
|
|## [2026-05-27T21:54:00+00:00] Execução #4 — Pós-Evolution Ciclo #2
|
|### Deck state: 35 lands, 65 nonlands. Swaps: Deflecting Palm→Big Score, Hellkite Tyrant→Dance with Calamity, Mother of Runes→The One Ring
|
|| Métrica | Valor | Status |
||:--------|:-----|:-------|
|| Mãos jogáveis | 71.1% | ✅ |
|| Mulligan | 29.9% | 🔴 |
|| Ramp turno 1 | 24.8% | ✅ |
|| Sem play até T3 | 15.8% | 🔴 |
|
|### Delta vs Ciclo #1
|
|| Métrica | Pós-Evo #1 | Agora (Ciclo #2) | Δ |
||:--------|:---------:|:----------------:|:-:|
|| Jogáveis | 73.2% | 71.1% | -2.1pp |
|| Mulligan | 26.8% | 29.9% | +3.1pp |
|| Ramp T1 | 25.4% | 24.8% | -0.6pp (ruído) |
|| Sem play T3 | 12.4% | 15.8% | +3.4pp |
|
|### Conclusão
|
|Os swaps do Ciclo #2 tiveram um custo mensurável na consistência early-game. A troca de 3 cartas CMC 1-2 (Deflecting Palm, Mother of Runes) e CMC 6 (Hellkite) por 3 cartas CMC 4-4-8 (Big Score, TOR, Dance) elevou o perfil de CMC da mão inicial. O deck está mais forte no mid-late game (Dance com Miracle + Lorehold copy é devastador) mas mais vulnerável nos turnos 1-3. A tendência de piora em "sem play T3" (3.3% → 12.4% → 15.8%) precisa ser corrigida com interação CMC≤2 no próximo ciclo.|
||
|**Recomendação:** Adicionar Chaos Warp e/ou Generous Gift no Ciclo #3 para reduzir "sem play T3" de volta para <12%. Manter 35 lands.

## [2026-05-28T07:00:00+00:00] Execução #5 — Estabilidade Pós-Ciclo #2

### Status: Sem mudanças no deck desde Ciclo #2
Nenhuma evoluçōes nova aplicada. Evolution Oracle ainda não executou o Ciclo #3.
Simulação de confirmação: 1000 mãos, seed=42.

### Resultados

| Métrica | Valor | Status |
|:--------|:-----|:-------|
| Mãos jogáveis | 71.1% | ✅ |
| Mulligan | 29.8% | 🔴 |
| Ramp T1 | 27.2% | ✅ |
| Sem play T3 | 16.5% | 🔴 |

### Delta vs Execução #4

| Métrica | Exec#4 | Exec#5 | Δ |
|:--------|:------:|:------:|:-:|
| Jogáveis | 71.1% | 71.1% | +0.0pp |
| Mulligan | 29.9% | 29.8% | -0.1pp |
| Ramp T1 | 24.8% | 27.2% | +2.4pp |
| Sem play T3 | 15.8% | 16.5% | +0.7pp |

### Conclusão
Deck está ESTÁVEL. Todas as métricas dentro do ruído estatístico (±2.8pp). Nenhum swap novo para testar. Aguardando Evolution Oracle Ciclo #3 para aplicar interação CMC≤2 (Chaos Warp, Generous Gift) e reduzir "sem play T3" do nível crítico atual (~16%).

### O Que Essa Métrica Significa
**"Sem play T3" em 16.5%** significa que ~1 em cada 6 partidas abre sem nenhuma carta jogável nos 3 primeiros turnos. Para um deck Boros que depende de ativar triggers de legends/instants/sorceries, cada turno "morto" é um turno onde o comandante não gera valor. O deck precisa de mais cartas CMC≤2 que geram valor imediato (remoção, ramp, draw). O Ciclo #3 precisa resolver isso.|

---

## [2026-05-31T06:00:00+00:00] Execução #8 — Pós-Ciclo #4 (DEFENSIVO confirmado)

### Deck state: 35 lands, 64 nonlands. Ciclo #4 swaps: Rise of the Eldrazi→Faithless Looting, Season of the Bold→Dragon's Rage Channeler, Goblin Engineer→Thrill of Possibility. Net ΔCMC = -15.

### Resultados

| Métrica | Valor | Status |
|:--------|:-----:|:-------|
| Mãos jogáveis (2-4 lands + ramp/3+ lands) | 49.5% | 🔴 |
| Mulligan obrigatório (0-1 lands ou 2 lands sem ramp) | 46.4% | 🔴 |
| Ramp turno 1 (Sol Ring, Land Tax, Wayfarer) | 21.2% | ✅ |
| Sem play até turno 3 (nada castável com lands disponíveis) | 12.0% | 🟡 |

### Comparação com Histórico (definição rigorosa)

| Métrica | Exec#6 (pós-C#2) | Exec#8 (pós-C#4) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis (rigoroso) | 49.8% | 49.5% | -0.3pp |
| Mulligan | 45.4% | 46.4% | +1.0pp |
| Ramp T1 estrito | 27.2% | 21.2% | -6.0pp |
| Sem play T3 | 16.5% | 12.0% | **-4.4pp ✅** |

### Análise

**O Ciclo #4 atingiu seu objetivo primário:** reduzir Sem Play T3 de 16.5% para 12.0% (-4.4pp). A estratégia DEFENSIVA com net ΔCMC = -15 funcionou.

A métrica de "jogáveis rigorosos" permanece ~49.5% — este é um **limite estrutural** de um deck com 35 lands e apenas 3 fontes de T1 ramp. P(2 lands) = 31%, dos quais ~79% não têm ramp T1 → ~24.5% de todas as mãos são "2 lands sem ramp" (mulligan pela definição rigorosa). Para melhorar: ramp T2 (Signets) ou +1-2 lands.

**Com T3 = 12.0%, o Ciclo #5 pode usar estratégia BALANCED** (net ΔCMC 0 a -2).

### O Que Essa Métrica Significa

**Sem Play T3 = 12.0%** significa que ~1 em cada 8 partidas abre sem nenhuma carta jogável nos 3 primeiros turnos. Melhorou de ~1 em 6 (pré-Ciclo #4). Para um deck Boros big-spells em bracket 3, 12% é aceitável — o deck compensa com poder explosivo no mid-late game (motor 4/4 completo).

**Jogáveis "rigorosos" = 49.5%** significa que cerca de metade das mãos iniciais precisam de mulligan pela definição estrita. Parece alto, mas lembrando: a definição rigorosa exige OU ramp T1 (só 3 cartas no deck) OU 3+ lands, para mãos com 2-4 lands. Mãos com 2 lands sem ramp (~24.5%) são marcadas como mulligan. Isso é intencional — sem ramp adicional, 2 lands em Boros é lento demais para competir.

**Próximo teste:** Após Ciclo #5 (BALANCED, com Dawning Archaic + Chaos Warp + Arcane Bombardment).

---

*Simulação: 1000 maos, seed=42, definicao rigorosa. IC95% = ±2.8pp.*

---
## Execução #9 — Pós-Ciclo #5 (2026-05-31T04:43:48Z)

### Resultados (seed=42, N=1000, definição rigorosa)

| Métrica | Pos-C#4 (Exec#8) | Pos-C#5 (Exec#9) | Δ |
|:--------:|:----------------:|:----------------:|:-:|
| Jogáveis | 47.9% | 48.0% | +0.1pp |
| Mulligan | 52.1% | 52.0% | -0.1pp |
| Ramp T1 | 20.9% | 21.2% | +0.3pp |
| Sem Play T3 | 13.0% | **15.3%** | **+2.3pp** |

Sem Play T3 ultrapassou 12% → Estratégia Ciclo #6: DEFENSIVA (net ΔCMC -5 a -10).

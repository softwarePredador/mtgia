# Knowledge Log — ManaLoom Deck Analysis

## Aesi, Tyrant of Gyre Strait — 2026-05-30
Aesi é o único comandante UG que dá extra land drop + card draw simultaneamente, funcionando como motor completo de draw/ramp em um slot. Com 40 terrenos e 23 fontes de ramp, cada land drop cascateia em valor (carta + token + contador). Vulnerabilidade central: apenas 2 proteções — a estratégia é recastar Aesi rapidamente via ramp massiva em vez de protegê-la.

## Dina, Essence Brewer — 2026-05-28
Dina é um aristocrats híbrido Soul Sisters único: converte lifegain em dano + scry, diferente de Teysa (dobra death triggers) ou Korvold (recompensa sac de permanente). O deck opera com triângulo aristocrats clássico (fodder + outlet + payoff) mas com 4 Blood Artist effects + Dina = 12 dano total por morte de criatura. Resiliência via recursão verde compensa a falta de proteção branca.

Insight central: o "quadrado de drain" (Blood Artist + Zulaport Cutthroat + Bastion + Enduring Tenacity) é o coração — sem ele, Dina perde 75% do dano. Skullclamp transforma tokens 1/1 em card advantage. Gap crítico: 1 proteção, 0 tutores, ramp abaixo do ideal — deck confia em consistência natural para funcionar.

## Aesi, Tyrant of Gyre Strait — 2026-05-28
Aesi é o único comandante que dá draw E extra land drop simultaneamente, transformando cada terreno em card advantage. O deck default EDHREC opera com 40 terrenos e 23 fontes de ramp — acima do range ideal do perfil — sacrificando slots de proteção pela consistência do motor. Problema ManaLoom: Aesi é classificada apenas como "draw", perdendo metade da função (ramp embutido via extra land drops).

**Insight principal:** Deck vence por valor exponencial (Avenger of Zendikar + land drops geram exército impossível de bloquear), não por combo. Cyclonic Rift é a remoção perfeita porque preserva os próprios terrenos. Apenas 2 cartas de proteção — a resiliência vem da ramp massiva que permite recastar Aesi imediatamente após remoção.

## Aesi, Tyrant of Gyre Strait (Analysis v2) — 2026-05-28
Versão estruturada criada: analyses/aesi-tyrant-of-gyre-strait.md. Destaques: Exploration (1 mana, dobra land drops), Avenger (payoff landfall mais explosivo), Cyclonic Rift (wipe que poupa terrenos). Vulnerabilidade principal: Mass Land Destruction é quase irreversível para este arquétipo.

## Aesi, Tyrant of Gyre Strait - 2026-05-28
Aesi é o único comandante que une extra land drop + card draw num único slot, tornando cada terreno uma "tripla ameaça" (mana, draw, landfall trigger). O deck prioriza consistência (40 terrenos, 23 ramp) sobre interação, confiando que valor incremental massivo supera oponentes. Janela crítica: precisa de Aesi ativa até o turno 5 ou perde competitividade.

## Atraxa, Praetors' Voice — 2026-05-28
Atraxa prolifera todo end step gratuitamente, e o deck acumula 12+ fontes adicionais de multiplicar/forçar counters para vencer por veneno. Insight principal: o deck é 40% infect theme + 60% "melhores cartas genéricas do Commander" (Rhystic Study, Smothering Tithe, Doubling Season, Oko). A vitoria segue uma fórmula previsível — Prologue to Phyresis "inicia" o veneno nos 3 oponentes, depois cada Atraxa end step adiciona +3 veneno até o lethal. Problema ManaLoom: cartas como Blighted Agent e Skithiryx precisam de tags `enabler`/`wincon` simultâneas — atualmente o sistema trata apenas 1 função por carta.

## Aesi, Tyrant of Gyre Strait - 2026-05-28 (Structured Analysis)
Análise estruturada salva em analyses/aesi-tyrant-of-gyre-strait.md. Três cartas-chave identificadas: Exploration (extra land drop mais barato, habilita o motor turn 1), Avenger of Zendikar (wincon mais explosivo — 40 plantas + counters por land drop), Cyclonic Rift (mass removal que preserva terrenos do Aesi). Insight central: o deck acumula vantagem por "inércia de valor" — cada terreno é mana+draw+payoff simultâneo. Vulnerabilidade fatal: apenas 2 fontes de proteção, confiando em recastar Aesi rapidamente com ramp massivo.

## Aesi, Tyrant of Gyre Strait - 2026-05-28 (Bounce Lands & ManaLoom Gaps)
Bounce lands (Simic Growth Chamber, Coral Atoll) são peças-chave silenciosas: re-triggar landfall e Aesi a cada ciclo, criando loops com Kodama of the East Tree. O deck inclui 2 bounce lands + 2 fetch lands + Evolving Wilds/Terramorphic Expanse — totalizando ~8 terrenos que "entram e saem" para maximizar triggers. Gap ManaLoom: 4 cartas com tags incorretas — Aesi (draw→engine), Tatyova (draw→engine), Avenger (other→wincon), Cyclonic Rift (removal→board_wipe). Recomendação: sistema precisa de tag composta "engine" para comandantes que geram valor em múltiplas dimensões.

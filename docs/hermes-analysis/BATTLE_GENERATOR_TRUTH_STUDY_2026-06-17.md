# Battle + Generator + Lorehold Truth Study - 2026-06-17

> Status 2026-06-19: documento historico. As conclusoes devem ser cruzadas
> com o register vivo e com os artefatos latest antes de qualquer decisao de
> pronto. Fonte viva:
> [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md).
> Indice: [BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md](BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md).

## Objetivo

Consolidar, com evidência atual de código, artefatos e fontes externas, o que é
verdade hoje sobre:

- battle simulator Hermes;
- geração de decks no backend;
- caso de controle `Lorehold, the Historian`;
- backlog real para transformar battle/generator em fontes mais confiáveis de
  melhoria de deck.

Este documento separa:

1. o que já é verdade operacional;
2. o que ainda é heurística útil, mas não verdade final;
3. o que está stale nos relatórios Hermes remotos;
4. o que precisa virar task de implementação.

Matriz de execução derivada desta consolidação:

- [BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md)

## Fontes usadas

### Código e artefatos locais

- [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- [commander_reference_generate_fallback_support.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_generate_fallback_support.dart)
- [commander_generate_provenance_audit.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/bin/commander_generate_provenance_audit.dart)
- [generate/index.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/generate/index.dart)
- [IMPLEMENTATION_GAPS.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/IMPLEMENTATION_GAPS.md)
- [BATTLE_SYSTEM_LOGIC.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md)
- [BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md)
- [LOREHOLD_GENERATOR_SOURCE_MIX_AUDIT_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_GENERATOR_SOURCE_MIX_AUDIT_2026-06-17.md)
- [BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md)
- [commander_generate_provenance_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/commander_generate_provenance_2026-06-17_live5/commander_generate_provenance_summary.json)
- [lorehold_generator_source_mix_2026-06-17.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generator_source_mix_2026-06-17.json)

### Branch remota Hermes docs

- `origin/codex/hermes-analysis-docs`
- [manaloom-knowledge/COMMANDER_DEEP_REPORT.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/COMMANDER_DEEP_REPORT.md)
- [manaloom-knowledge/TAG_ACCURACY_REPORT.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/TAG_ACCURACY_REPORT.md)
- [manaloom-knowledge/MANA_BASE_VALIDATION_REPORT.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/MANA_BASE_VALIDATION_REPORT.md)
- [manaloom-knowledge/decks/lorehold-the-historian/BATTLE_LOG.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/BATTLE_LOG.md)

Importante: esses relatórios remotos foram lidos como insumo, não como verdade
ativa automática. Parte deles está ancorada em hashes, benchmarks e battle logs
anteriores ao `master` atual.

### Fontes externas rechecadas

- [Magic Rules](https://magic.wizards.com/en/rules)
- [Commander oficial](https://magic.wizards.com/en/formats/commander)
- [The London Mulligan](https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03)
- [Edge of Eternities Update Bulletin](https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin)
- [Secrets of Strixhaven Mechanics](https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-mechanics)
- [Lorehold, the Historian (Commander) - EDHREC](https://edhrec.com/commanders/lorehold-the-historian)
- [How to Build a Commander Deck - EDHREC](https://edhrec.com/articles/how-to-build-a-commander-deck)
- [Foundations: How to Build Mana Bases - EDHREC](https://edhrec.com/articles/foundations-how-to-build-mana-bases)
- [Ramp in Commander - EDHREC](https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander)
- [Miracles Every Turn With Lorehold, the Historian in Commander - EDHREC](https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander)
- [Using Win Rate Data - 17Lands](https://blog.17lands.com/posts/using-win-rate-data/)
- [17Lands Metrics Definitions](https://www.17lands.com/metrics_definitions)
- [Mox Diamond - Scryfall](https://scryfall.com/card/sth/138/mox-diamond)
- [Lotus Petal - Scryfall](https://scryfall.com/card/tmp/294/lotus-petal)
- [Crop Rotation - Scryfall](https://scryfall.com/card/ulg/98/crop-rotation)
- [Harrow - Scryfall](https://scryfall.com/card/cma/115/harrow)

## Verdade atual do battle simulator

## O que já está provado

### 1. O battle já saiu do estado "quebrado" para as decisões principais modeladas

O runtime ativo não é mais uma pilha de overrides soltos. A precedência real
está documentada em [BATTLE_SYSTEM_LOGIC.md:670](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md#L670) e hoje é:

1. `card_battle_rules` / cache Hermes;
2. snapshot canônico de fallback;
3. heurística/`unknown` auditável.

O inventário manual ativo foi zerado no fluxo normal. Isso significa que o
simulador já serve para:

- detectar regressão;
- validar se uma jogada foi legal e coerente dentro do que está modelado;
- impedir aprendizado cego a partir de efeitos sabidamente errados.

### 2. Mulligan já usa política mínima melhor do que "só contar terrenos"

Hoje `mulligan_evaluation()` não decide apenas por quantidade de lands. O código
real em [battle_analyst_v9.py:3225](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py#L3225) mostra:

- mulligan automático se `< 2` lands;
- mulligan automático se `> 5` lands;
- avaliação de plano inicial por curva/janela;
- flag de `expensive_dead_hand` quando a mão é pesada e sem plano.

O trace emitido em [battle_analyst_v9.py:3276](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py#L3276) já registra:

- `lands`, `colors`, `early_play`, `early_ramp`, `high_cost_cards`;
- `risk_flags`;
- `alternatives_considered`;
- `reason`.

Isso está alinhado com:

- regra oficial do London Mulligan: comprar 7 e bottomar após cada mulligan;
- heurística estratégica atual de Commander: 2-4 lands, cores corretas e plano
  inicial jogável são a base da mão funcional.

### 3. Multi-rule runtime está correto na arquitetura, mas não no corpus

O ponto mais importante da rodada de 2026-06-17 é este:

- armazenar múltiplas regras por carta já está suportado;
- executar múltiplas regras automaticamente por nome não está aberto;
- o PostgreSQL canônico ainda não materializa casos reais multi-row.

O estado real está em [BATTLE_SYSTEM_LOGIC.md:684](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md#L684) e [BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md:46](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md#L46):

- `3158` nomes ativos;
- `multi_rule_card_count = 0`;
- `any_multi = 0`.

O runtime já faz três coisas certas:

1. compõe apenas o subconjunto seguro de múltiplas resoluções;
2. funde apenas metadata segura de custo adicional;
3. bloqueia alternativas que exigem executor de activated/trigger/static.

Isso evita o erro de "executar tudo pelo nome".

## O que ainda não está provado

### 1. O battle ainda não prova que a melhor jogada foi escolhida

O trace atual registra bastante coisa, mas ainda não fecha a pergunta:

- por que A foi melhor que B;
- qual payoff esperado existia para cada alternativa rejeitada;
- quando o pass/no-action foi politicamente bom, e não só legal.

Na prática, o battle hoje prova:

- legalidade;
- coerência dentro do que está modelado;
- ausência de alguns erros fortes.

Ele ainda não prova:

- EV ótimo por jogada;
- threat assessment ótimo em todos os pods;
- valor estatístico real de cada cast/hold/pass.

### 2. A cobertura dos oponentes continua parcial

O ruído residual deixou de ser "Lorehold está quebrando". Agora ele é:

- `review_rule_used`;
- `needs_review`;
- activated abilities com executor incompleto;
- cartas do oponente ainda não promovidas para regra estável.

O próximo outlier operacional relevante segue sendo `Ashnod's Altar`: a
metadata já existe, mas ainda não há executor genérico de activated ability
`sacrifice_creature`.

### 3. O scorecard estatístico ainda é fraco

O produto ainda não mede, de forma canônica:

- WR com carta vista;
- WR sem carta vista;
- WR com carta castada;
- WR sem carta castada;
- delta contra baseline fresco por hash;
- impacto por arquétipo e por turno médio.

Isso é precisamente o ponto em que a metodologia do 17Lands agrega:
interpretar WR bruto sem segmentação é enganoso.

## Verdade atual do deck generator

## O que já está provado

### 1. O generator não é prompt-only

O fluxo real de `/ai/generate` continua:

1. tenta geração AI;
2. força o comandante do profile quando necessário;
3. filtra identidade de cor;
4. valida no backend;
5. cai para fallback determinístico somente se a saída vier inválida ou
   irresolvida.

Isso está explícito em [generate/index.dart:642](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/generate/index.dart#L642) e no bloco de fallback em [generate/index.dart:775](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/routes/ai/generate/index.dart#L775).

Logo, a verdade correta é:

- AI é primeira tentativa;
- backend é dono da validação;
- fallback determinístico existe para manter o fluxo create/validate/optimize;
- o app não é a fonte de verdade.

### 2. O caminho determinístico já tem explainability útil

O builder determinístico agrega estas fontes em ordem real de inclusão, como
mostra [commander_reference_generate_fallback_support.dart:195](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_generate_fallback_support.dart#L195):

1. `reference_card_stats`
2. `reference_corpus_packages`
3. `profile_expected_packages`
4. `active_learned_deck`
5. `usage_hot_cards`
6. `deterministic_fallback`

Consequência importante:

- no caminho determinístico, `active_learned_deck` não é precedência máxima;
- ele adiciona nomes e proveniência, mas não substitui automaticamente o que
  já entrou antes por `stats/corpus/profile`.

Essa ordem é verdade de código hoje. Não é interpretação.

### 3. O Lorehold já tem profile persistido canônico e utilizável

A prova real do `live5` é:

- `row_source = aggregate_reference_profile_v1`
- `usable = true`
- `usable_confidence = high`
- `usable_source_count = 4`
- `usable_runtime_origin = null`

Isso significa que o problema antigo de "profile existe, mas o runtime cai no
fallback built-in por shape legado" foi fechado.

Além disso, o provenance summary atual mostra:

- `reference_card_stats usable_count = 34`
- `reference_corpus accepted_deck_count = 3`
- `usage_hot_cards count = 50`

Logo, o Lorehold já não depende de um perfil fake ou invisível. O que ainda
existe é dependência auxiliar de fallback no builder determinístico.

## O que ainda não está provado

### 1. Learned deck continua canal paralelo no generate

O auditor atual já aponta o gap real:

- existe deck aprendido ativo;
- ele aparece como fonte;
- mas não é a política dominante de ranking do `/ai/generate`.

O próprio summary atual marca:

- `learned_deck_parallel_not_ranked_in_generate`

Então a pergunta correta não é "o learned existe?". Existe.

A pergunta correta é:

- em quais caminhos ele domina a geração?
- em quais caminhos ele só contribui como proveniência/candidate pool?

### 2. O builder determinístico ainda usa fallback demais para o Lorehold

O problema mudou de forma.

Não existe mais `fallback_only` puro no Lorehold:

- `fallback_only_count = 0`

Mas ainda existe dependência relevante:

- `fallback_touched_count = 42`
- `learned_plus_fallback_only_count = 2`
- `fallback_without_profile_or_stats_count = 9`
- `fallback_profile_stats_no_empirical_support_count = 18`

Logo, a leitura correta hoje é:

- o generator não está mais "cego em fallback";
- ele ainda está "apoiado em fallback" em muitos slots.

## Verdade atual do Lorehold como deck de controle

## O que ele já serve para medir

Lorehold hoje já serve como caso de controle real para:

- profile/corpus/stats/usage;
- geração AI com validação backend;
- fallback determinístico com proveniência;
- optimize com quality gate mais coerente;
- battle replay e decisão estratégica em partidas auditadas.

Além disso, fontes externas atuais convergem para uma direção temática clara:

- Lorehold está sendo tratado em EDHREC como `Topdeck`, `Spellslinger`,
  `Discard`;
- as listas e artigos mais atuais continuam puxando:
  - milagre/topdeck;
  - spellslinger Boros;
  - value e payoff por instants/sorceries;
  - necessidade real de draw/ramp e mana base consistente.

## O que ele ainda não serve para provar

Lorehold ainda não pode ser usado como prova universal de que:

- o battle decide melhor que humanos;
- a geração AI já está ideal;
- swaps sugeridos por WR são verdade final.

Motivos:

1. o scorecard estatístico ainda é limitado;
2. a cobertura dos oponentes ainda é parcial;
3. o builder determinístico ainda carrega 42 cartas tocadas por fallback;
4. o learned deck ainda é parcialmente canal paralelo.

## Triagem da branch Hermes docs

## Achados que continuam úteis

Os relatórios remotos ainda ajudam a apontar classes de problema:

- risco de benchmark em hash stale;
- role mismatch em revisão de qualidade;
- necessidade de lineage melhor entre profile/stats/corpus/usage;
- risco de usar WR bruto como verdade.

Esses sinais continuam válidos como categoria.

## Achados que não podem mais ser copiados como verdade ativa

Há pelo menos quatro blocos que já estão stale sem rerun:

1. `COMMANDER_DEEP_REPORT.md`
   - está ancorado em hash e battle logs anteriores;
   - não reflete os slices atuais de `Mox Amber`, `Dismember`, multi-rule,
     snapshot canônico e normalização do profile Lorehold.
2. `TAG_ACCURACY_REPORT.md`
   - é de 2026-06-07;
   - ainda é útil como sinal de dívida no pipeline Hermes local, mas não deve
     abrir task de produto sem reexecução.
3. `MANA_BASE_VALIDATION_REPORT.md`
   - mistura seeds incompletos e decks battle-simulator placeholder;
   - útil para mostrar que o corpus Hermes é heterogêneo, mas não como
     veredito final de produto.
4. `BATTLE_LOG.md`
   - carrega fases históricas de engines anteriores;
   - ainda é útil para evolução de baseline, mas não como prova isolada do
     runtime atual.

Conclusão:

- `origin/codex/hermes-analysis-docs` continua útil como staging de pesquisa;
- não deve ser tratado como fonte primária de estado do produto quando o
  `master` atual já avançou além daqueles hashes.

## Gaps reais consolidados

## P1 - battle

### 1. Evoluir `decision_trace_v1` para decisão comparativa

Falta registrar, por decisão relevante:

- opções jogáveis completas;
- alternativa rejeitada;
- motivo de rejeição;
- payoff esperado;
- risco assumido.

Sem isso, o battle ainda audita legalidade/coerência melhor do que qualidade de
escolha.

### 2. Criar scorecard Commander-safe de impacto

Necessário medir:

- seen vs unseen;
- cast vs not cast;
- delta vs baseline hash fresco;
- sample floor;
- split por arquétipo;
- split por turno médio.

Sem isso, qualquer WR alto ou baixo continua sendo suspeito.

### 3. Fechar outliers recorrentes de oponentes

Prioridade atual:

- `Ashnod's Altar`
- activated abilities recorrentes com custo de sacrifício
- outras cartas que continuam aparecendo como `review_rule_used`

### 4. Materializar casos reais multi-row de `card_battle_rules`

Antes de qualquer executor mais forte, o PG precisa conter casos reais de:

- `spell_resolution`
- `activated_ability`
- `trigger_resolution`
- `static_layer`
- `cost_annotation`

Sem isso, o suporte multi-rule continua exercitado só por fixture.

## P1 - generator / Lorehold

### 5. Decidir explicitamente a precedência do deterministic builder

Hoje a ordem é:

- stats
- corpus
- profile
- learned
- usage
- fallback

Isso é coerente se a intenção for "referência canônica primeiro".

Não é coerente se a intenção for "deck aprendido manda".

Esse ponto precisa de decisão de produto e depois virar regra explícita.

### 6. Curar os 9 slots `fallback_without_profile_or_stats`

Cards atuais:

- Arcane Signet
- Boros Charm
- Boros Signet
- Esper Sentinel
- Faithless Looting
- Fellwar Stone
- Generous Gift
- Lightning Greaves
- Sol Ring

Isso é o próximo slice de maior retorno para reduzir fallback auxiliar sem
desmontar o builder.

### 7. Curar os 2 slots `learned_plus_fallback_only`

Cards atuais:

- Fellwar Stone
- Lightning Greaves

Esses são os melhores candidatos para decidir se:

- ganham corpus/usage/profile formal;
- ou permanecem explicitamente apoiados em fallback.

### 8. Revisar os 18 slots `fallback + profile/stats` sem suporte empírico

Esses não são o primeiro bloco a atacar, mas continuam importantes para não
deixar o generator parecer mais comprovado do que realmente está.

### 9. Decidir promoção controlada de `card_role_scores` com EDHREC bounded

O slice de candidate quality com EDHREC bounded já existe.

O que falta não é ideia. É decisão operacional:

- revisar stale prune;
- aplicar em janela controlada;
- rerodar scorecards de generate/optimize depois do apply.

## O que não deve ser feito

- não usar WR bruto como verdade final;
- não usar `deck_cards -> card_battle_rules` join cru;
- não usar SQLite Hermes como fonte final do produto;
- não abrir executor multi-rule por nome sem escopo;
- não promover relatório Hermes remoto como verdade atual sem rerun;
- não assumir que learned deck direto e deterministic builder são o mesmo canal;
- não tratar fallback residual do Lorehold como simples "lista ruim" sem olhar
  bucket de evidência.

## Próxima ordem de trabalho recomendada

1. Rerodar os relatórios Hermes operacionais em cima do `master` atual antes de
   reaproveitar qualquer finding antigo como task de produto.
2. Implementar `decision_trace` comparativo e scorecard Commander-safe.
3. Curar o bucket P1 do Lorehold:
   - 9 `fallback_without_profile_or_stats`
   - 2 `learned_plus_fallback_only`
4. Tomar decisão explícita de precedência do builder determinístico.
5. Materializar 3-5 casos multi-row reais no PG e só então reabrir execução
   multi-rule mais forte.

## Veredito

O battle simulator e o generator já têm dados úteis de verdade, mas em camadas
diferentes:

- battle já é útil para validar coerência e evitar aprendizado ruim do que está
  modelado;
- generator já é útil para produzir decks válidos com explainability parcial e
  múltiplas fontes;
- Lorehold já é um deck de controle válido para evolução.

O que ainda falta não é "fazer o sistema funcionar". O que falta é:

- tornar a decisão do battle mais comparável e mensurável;
- reduzir a dependência auxiliar de fallback do generator;
- impedir que relatórios stale do Hermes voltem a contaminar a priorização.

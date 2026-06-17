# Battle + Generator + Lorehold Truth Study - 2026-06-16

## Summary

Este documento consolida o estado real do battle simulator Hermes, da geracao
de decks no backend e do caso de controle `Lorehold, the Historian`.

Objetivo:

- separar o que ja esta suficientemente validado;
- separar o que ainda e heuristica operacional;
- identificar quais dados ja sao uteis para criacao de deck;
- registrar o que ainda precisa ser implementado para o sistema produzir
  recomendacoes mais confiaveis e menos dependentes de fallback manual.

Veredito curto:

1. O battle simulator nao esta mais em estado "quebrado" para as decisoes
   principais ja auditadas. Ele esta adequado para servir como laboratorio
   auditavel, mas ainda nao como verdade final de qualidade de jogada.
2. O generator nao e prompt-only. Ele ja usa referencia estruturada, corpus,
   hot cards de uso real e validacao backend-owned. Mesmo assim, ainda ha
   fallback curado literal, especialmente para Lorehold.
3. Lorehold ja serve como deck de controle real para medir geracao, validacao,
   optimize e battle, mas o valor de aprendizado continua bloqueado por lacunas
   de cobertura em utility lands, cartas de oponentes e metricas de decisao.
4. O optimize de Lorehold nao cai mais em um quality gate generico de
   `removal/ramp`: o arquétipo `combo` agora protege explicitamente
   `tutor`, `engine`, `wincon`, `protection` e `combo_piece`.
5. A branch `origin/codex/hermes-analysis-docs` segue util apenas como staging
   Hermes. Para battle/generator/Lorehold, ela esta atrasada frente ao
   `master` local e nao deve ser tratada como fonte primaria.

## Fontes canonicas usadas

### Codigo e docs do projeto

- `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/IMPLEMENTATION_GAPS.md`
- `docs/hermes-analysis/DECK_GENERATION_FOCUS_READINESS_2026-06-16.md`
- `docs/hermes-analysis/BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
- `docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md`
- `docs/hermes-analysis/LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md`
- `server/routes/ai/generate/index.dart`
- `server/routes/ai/optimize/index.dart`
- `server/lib/generated_deck_validation_service.dart`
- `server/lib/ai/deck_learning_event_support.dart`
- `server/lib/ai/commander_reference_generate_fallback_support.dart`
- `server/lib/ai/candidate_quality_data_support.dart`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`

### Regras oficiais e referencias externas

- [Magic Comprehensive Rules](https://magic.wizards.com/en/rules)
- [Commander oficial](https://magic.wizards.com/en/formats/commander)
- [London Mulligan](https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03)
- [Edge of Eternities update bulletin](https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin)
- [EDHREC - Lorehold, the Historian](https://edhrec.com/commanders/lorehold-the-historian)
- [EDHREC - How to Build a Commander Deck](https://edhrec.com/articles/how-to-build-a-commander-deck)
- [EDHREC - Ramp in Commander](https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander)
- [EDHREC - Foundations: Mana Bases](https://edhrec.com/articles/foundations-how-to-build-mana-bases)
- [17Lands metrics definitions](https://www.17lands.com/metrics_definitions)
- [17Lands - Using Win Rate Data](https://blog.17lands.com/posts/using-win-rate-data/)

Regra de leitura:

- regra oficial e oracle/rulings definem legalidade e comportamento duro;
- EDHREC/comunidade calibram heuristica de deckbuilding;
- 17Lands entra so como metodologia estatistica, nao como fonte Commander.

## Estado real do battle simulator

## O que ja esta suficientemente validado

O engine ativo e `battle_analyst_v9.py`. O estado atual do runtime mostra:

- inventario manual ativo zerado (`HANDCRAFTED_KNOWN_CARDS == set()`);
- waivers manuais desativados por padrao;
- resolucao principal em ordem:
  1. waiver manual explicito;
  2. `card_battle_rules` via registry/cache;
  3. `known_cards_canonical_snapshot.json`;
  4. `known_cards_generated.json` apenas como ultimo fallback historico;
  5. tags/heuristicas.

As suites focadas recentes cobrem:

- turn flow e APNAP;
- stack LIFO;
- state-based actions;
- commander damage e command zone;
- hybrid/phyrexian/restricted mana;
- targeting formal minimo;
- combat, trample, deathtouch, blockers, first/double strike;
- zone changes, tokens, exile visibility, reanimation, recursion;
- mulligan keep/mull decision minima;
- fast mana e one-shot resource guardrails;
- Mox Diamond, Chrome Mox, Everflowing Chalice, Lotus Petal;
- board wipe / wheel multiplayer v1;
- tutoring contextual;
- pass / no-action decision trace;
- mecanicas modernas ja adicionadas no backlog 2026 minimo
  (`Warp`, `Station`, `Prepare`, `Omen`, `Paradigm`, etc.) em cobertura
  limitada de conformance.

Tambem ha validacao operacional recente em
`BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`:

- 16 seeds;
- mais de 17k eventos;
- mais de 2300 decision traces;
- 0 blockers estrategicos na amostra reproduzida;
- apenas findings low de `review_rule_used`.

Conclusao:

- para as decisoes implementadas e observadas, o battle esta
  `coherent_in_sample`;
- ele ja e bom o bastante para detectar regressao e para impedir que Lorehold
  aprenda de uma jogada claramente ruim que hoje ja esta modelada;
- ele ainda nao prova que a melhor jogada foi sempre escolhida.

## O que ainda nao e verdade final

O battle ainda nao tem cobertura suficiente para ser tratado como juiz
estrategico completo.

Lacunas reais:

1. `Urza's Saga` nao esta mais em baseline puro. O battle agora:
   - inicializa estado de capitulo/lore ao entrar;
   - avanca capitulo no upkeep;
   - cria Construct com guardrail no capitulo II;
   - tutorar um artefato seguro de mana value `<= 1` no capitulo III;
   - deixa o SBA sacrificar a Saga depois da habilidade final.
   O gap restante deixou de ser "sem comportamento" e virou refinamento:
   sizing dinamico do Construct e generalizacao prudente para outros Sagas.
2. `Ancient Tomb`, `War Room`, `Sunbaked Canyon`, `Inventors' Fair` e `Hall of
   Heliod's Generosity` ja sairam do estado puramente
   metadata-only. O battle agora executa uma linha minima e segura:
   - `Ancient Tomb`: so converte vida em mana extra quando o bonus realmente
     destrava comandante ou spell contextual relevante no precombat, em vez de
     conceder `{C}{C}` gratis em todo turno;
   - `War Room`: ativa no postcombat quando a mao esta curta, a vida esta
     segura e a troca mana/vida por carta faz sentido;
   - `Sunbaked Canyon`: so converte o land em compra quando a mao esta curta e
     o controlador ainda fica com base de mana aceitavel.
   - `Inventors' Fair`: ja resolve o trigger de ganho de vida no upkeep e a
     linha minima de tutor de artefato quando o threshold de artefatos e o
     custo de oportunidade justificam o uso.
   - `Hall of Heliod's Generosity`: ja consegue reciclar o melhor encantamento
     do cimiterio para o topo quando a mao esta curta e a cor/custo estao
     disponiveis.
   Isso reduz ambiguidade no caso Lorehold; `Urza's Saga` agora entrou nesse
   mesmo grupo de linha minima auditavel, ainda que com refinamentos pendentes.
3. A cobertura de cartas dos oponentes ainda mistura:
   - regra PG confiavel;
   - gerado `needs_review`;
   - heuristica;
   - `unknown`.
4. O replay ja documenta muita coisa, mas ainda nao explica todas as decisoes
   rejeitadas com nivel "por que A foi melhor que B".
5. O sistema ainda nao mede decisao por impacto estatistico forte:
   - com carta vista;
   - sem carta vista;
   - com carta castada;
   - sem carta castada;
   - delta contra baseline congelado;
   - impacto por oponente/arquetipo.

## Known cards / battle rules — estado real apos revalidacao

Nesta continuidade foi revalidado o risco de conflito entre:

- `card_battle_rules` / registry canônico;
- `known_cards_canonical_snapshot.json`;
- `known_cards_generated.json`;
- overrides manuais historicos do runtime.

Veredito tecnico:

1. nao existe conflito estrutural ativo no runtime atual;
2. o inventario manual legado continua desativado por padrao;
3. o snapshot canonico continua sendo o fallback degradado preferencial;
4. o JSON legado continua apenas como ultimo fallback historico;
5. o risco residual agora e cobertura incompleta de cartas, nao colisao de
   precedencia.

Evidencias objetivas desta rodada:

- `HANDCRAFTED_KNOWN_CARDS == set()`;
- `MANUAL_RULE_RUNTIME_WAIVERS == set()`;
- auditoria de ambiente do runtime: `PASS`;
- recheck do fallback canonico: snapshot canonico com `3159` linhas, sem
  nomes exclusivos no `known_cards_generated.json`;
- suite de regressao de battle/hotfix fallback permanecendo verde;
- suite focada de `known_cards`/snapshot/reviewed layer fechou com `29` testes
  Python `OK`, sem `ResourceWarning` residual de SQLite depois da troca para
  fechamento explicito de conexoes no harness e nos auditores/sync helpers.

Casos de amostra validados no runtime atual:

- `Mox Amber` resolve hoje como `manual/verified` a partir da regra canonica,
  sem waiver runtime;
- `Lotus Petal` resolve como `manual/verified`;
- `Angel's Grace` resolve como `curated/verified` com
  `effect=cannot_lose_turn`;
- `Chromatic Star` resolve como `curated/active` com
  `effect=cantrip_mana_filter_artifact`,
  `battle_model_scope=sacrifice_mana_filter_cantrip_v2`,
  `activation_cost_generic=1` e `draw_on_self_sacrifice=1`.
- `Natural Order` resolve agora como `curated/verified` com
  `effect=tutor`,
  `target=green_creature_to_battlefield`,
  `requires_sacrifice_green_creature=true` e
  `battle_model_scope=green_creature_pod_tutor_v1`; o runtime local tambem
  passou a pagar o custo adicional no cast e a bloquear o cast quando nao
  houver criatura verde sacrificavel.

Implicacao correta:

- o battle nao esta mais aprendendo de uma fonte manual escondida ou
  conflitante;
- o proximo trabalho certo e promover cartas ainda `generated/needs_review`,
  `heuristic` ou `active` simplificado para regras trusted/traceable quando forem
  relevantes ao corpus;
- findings como `Chromatic Star` agora sao gaps de fidelidade/completude de
  modelagem, nao regressao de precedence.

Risco operacional adicional encontrado:

- `battle_analyst_v9.py --help` estava executando simulacao em vez de apenas
  imprimir uso. Isso nao alterava resultado de battle, mas atrapalhava
  auditoria e automacao. O ajuste correto e manter parse de CLI antes do load
  do deck e da simulacao.

Implicacao pratica:

- WR bruto de Lorehold nao pode ser tratado como verdade.
- Replay limpo significa "nao encontramos erro grande naquilo que sabemos
  verificar", nao "o deck esta objetivamente perfeito".

## Estado real da geracao de decks

## Verdades externas que o generator precisa respeitar

As fontes externas consultadas nesta rodada reforcam tres verdades que precisam
continuar backend-owned:

1. Regras oficiais de Commander
   - deck `99 + 1 comandante`;
   - singleton exceto basics;
   - identidade de cor inclui custo e simbolos no texto;
   - comandante nasce na command zone, paga tax e causa commander damage;
   - em multiplayer Commander o atacante pode distribuir ataques entre multiplos
     defensores no mesmo combate.
   Implicacao: isso precisa continuar sendo fechado por
   `GeneratedDeckValidationService` / `DeckRulesService`, nunca por prompt.

2. Heuristica estrutural de deckbuilding Commander
   - EDHREC reforca `mana curve` e `turn mapping`: nao basta listar cartas boas;
     o deck precisa realmente jogar T2/T3/T4 e nao encher a mao de spells 6+.
   - Ramp e mana base nao podem ser tratadas como "resto da lista". Elas
     definem se o plano de jogo funciona.
   Implicacao: o ranking do generator precisa valorizar estrutura de curva,
   densidade de plays iniciais, ramp funcional e estabilidade de cores, e nao
   apenas afinidade tematica/bruta por carta.

3. Metodologia estatistica tipo 17Lands
   - win rate bruto isolado induz erro;
   - e preciso olhar amostra, carta vista, carta nao vista, contexto e vies de
     jogos longos/curtos.
   Implicacao: scorecards de Lorehold e de futuras promocoes nao devem aceitar
   "WR alto" como verdade sem baseline congelado e sem sinal por carta/decisao.

## O que o generator ja usa de dado real

`server/routes/ai/generate/index.dart` ja nao depende apenas de prompt livre.
Hoje ele combina:

1. `prompt` do usuario + `format`;
2. `requestedCommanderName`;
3. `commander_reference_profiles`;
4. `commander_reference_card_stats`;
5. `commander_reference_deck_corpus`;
6. `commander_card_usage` via `loadUsageHotCards`;
7. validacao backend-owned com `GeneratedDeckValidationService`;
8. `DeckRulesService` como gate final de legalidade;
9. fallback deterministico quando OpenAI falha, demora demais ou devolve deck
   invalido.

Isso significa:

- o backend ja controla legalidade, singleton e identidade de cor;
- o backend ja acumula sinais reais de uso por comandante;
- o generator ja consegue criar decks validos mesmo sem depender do app ou de
  API externa no cliente.

## Matriz real de ownership do generator

O comportamento correto do `/ai/generate` hoje nao e "OpenAI gera um deck do
zero". O pipeline real e este:

1. resolve `commander_name`/`format` e tenta carregar
   `commander_reference_profiles`;
2. se existir profile usavel, carrega `commander_reference_card_stats`;
3. se existir profile usavel, carrega tambem
   `commander_reference_deck_corpus`;
4. se nao existir profile exato, tenta `archetype_reference_reuse_v1` com
   comandantes compativeis por identidade e prompt;
5. sempre que houver comandante informado, carrega `commander_card_usage` e
   converte isso em texto de guidance (`Real-player usage data...`);
6. se o profile + stats + corpus atingem threshold minimo, entra no fast path
   deterministico (`buildDeterministicReferenceDeck`) sem depender da resposta
   do modelo;
7. se usar OpenAI, a saida continua passando por:
   - filtro de identidade de cor;
   - refill deterministico;
   - `GeneratedDeckValidationService`;
   - `DeckRulesService` como gate final.

Em termos de ownership:

- legalidade e reparo continuam backend-owned;
- profile/stats/corpus ja sao sinais estruturados reais;
- `commander_card_usage` ainda e guidance textual, nao ranking deterministico;
- semantic v2 continua apenas `shadow/additive`;
- o modelo de IA participa, mas nao e o dono final da lista.

## Learned decks: produto real, mas fluxo paralelo ao `/ai/generate`

`commander_learned_decks` e `commander_learning_snapshot` ja existem no
backend. Eles sao reais, versionados e validados para Commander. Mas isso nao
significa que o `/ai/generate` atual seja "movido por learned decks".

Hoje o estado correto e:

- o app usa `GET /ai/commander-learning` para descobrir decks promovidos por
  comandante;
- o app pode abrir um preview de `recommended_deck` e salvar esse deck
  aprendido diretamente;
- `server/routes/ai/commander-learning/index.dart` valida e monta esse
  `recommended_deck` como fluxo proprio de produto;
- `server/routes/ai/generate/index.dart` nao chama
  `commander_learned_decks`/`commander_learning_snapshot` como fonte primaria de
  construcao do deck gerado.

Conclusao arquitetural:

- learned deck hoje e um **canal paralelo e explicito** de geracao assistida;
- `/ai/generate` continua sendo um pipeline hibrido
  profile/stats/corpus/usage/openai/validation;
- isso e coerente com a policy atual:
  - learned decks continuam single commander;
  - metadata Hermes fica escondida do usuario comum;
  - Hermes propoe; backend decide.

Consequencia pratica:

- quando o usuario usa o botao "Usar deck aprendido do comandante", ele nao
  esta exercitando o mesmo pipeline do `/ai/generate`;
- portanto scorecards e auditorias precisam separar claramente:
  - deck gerado por `ai/generate`;
  - deck carregado de `commander-learning`;
  - deck reconstruido por fallback deterministico.
- nesta continuidade, os `diagnostics` opcionais de `/ai/generate` passaram a
  poder expor `runtime_profile_origin` e `runtime_profile_reason` quando o
  profile utilizavel vier do fallback runtime em vez de uma row persistida
  usavel. Isso nao muda decklist nem contrato obrigatorio, mas melhora a
  rastreabilidade do caso Lorehold.

## Auditoria medida de provenance do Lorehold

Foi criado e executado o auditor read-only:

- `server/bin/commander_generate_provenance_audit.dart`
- artefato:
  `server/test/artifacts/commander_generate_provenance_2026-06-16_current/commander_generate_provenance_summary.json`

Resultado medido no banco real:

- `profile.row_exists = true`
- `profile.row_source = edhrec`
- `profile.row_confidence = null`
- `profile.row_source_count = null`
- `profile.usable = true`
- `profile.usable_runtime_origin = built_in_fallback`
- `profile.usable_runtime_reason = persisted_profile_missing_or_not_usable`
- `reference_card_stats.usable_count = 34`
- `reference_corpus.accepted_deck_count = 3`
- `usage_hot_cards.count = 50`
- `active_learned_deck.exists = true`
- `deterministic_deck.built = true`
- `deterministic_deck.main_count = 99`
- `deterministic_deck.runtime_build_diagnostics.built_in_fallback_used_count = 62`
- `deterministic_deck.runtime_build_diagnostics.built_in_fallback_only_count = 25`

Leitura correta:

1. Lorehold **nao esta sem dados**.
   Ele tem stats, corpus, usage e learned deck ativo.
2. O problema atual e mais especifico:
   o row persistido atual ainda nao carrega sozinho a forma estruturada esperada
   pelo runtime (`confidence/source_count`), entao o profile utilizavel local
   continua sendo reconstruido via `built_in_fallback`.
3. Como consequencia direta, o fast-path deterministico do generator **ja liga**
   na pilha local revalidada, montando `99` cartas no main deck com `34`
   reference stats resolvidos, `3` decks aceitos no corpus e forte mistura de
   profile/stats/corpus/fallback.
4. O canal de produto `commander-learning` continua separado por arquitetura,
   mas agora ele concorre com um `/ai/generate` estruturalmente muito mais forte
   para Lorehold do que no snapshot inicial desta auditoria.
5. O problema aberto deixou de ser so "falta profile". A verdade atual e mais
   dura: o builder deterministico ainda usa `62` cartas tocadas pelo
   `built_in_fallback`, sendo `25` delas fallback puro. Ou seja, o Lorehold
   local ainda nao esta pronto para ser tratado como deck gerado apenas por
   sinais aprendidos/estruturados.

## Revalidacao publica do `/ai/generate` e `commander-learning`

Em 2026-06-16 foi executada nova prova contra o backend publico em:

- `https://evolution-cartinhas.8ktevp.easypanel.host/health`
- SHA exposto: `9c1ca349634de7d1321b448af22767e19bd64496`
- auditor read-only criado para repeticao:
  - `server/bin/lorehold_public_generator_parity_audit.dart`
  - artefato:
    `server/test/artifacts/lorehold_public_generator_parity_2026-06-16_recheck/summary.json`

Resultado observado em chamada real de `POST /ai/generate` com:

- `format=Commander`
- `commander_name=Lorehold, the Historian`
- prompt: `Boros miracle big spells with topdeck setup and interaction`

Resposta recebida:

- `status=200`
- `cache.hit=true`
- `is_mock=true`
- `diagnostics.reference_profile_used=false`
- `diagnostics.reference_card_stats_used=false`
- `diagnostics.archetype_reference_used=true`
- `diagnostics.archetype_source_commanders=["Aziza, Mage Tower Captain", "Excava, the Risen Past", "Feather, the Redeemed", "Winota, Joiner of Forces"]`
- deck fallback mock: `50x Mountain // Mountain`, `49x Plains // Plains`

Leitura correta:

1. O deploy publico esta no SHA certo do codigo.
2. Mesmo assim, o runtime publico **nao** enxergou um profile persistido
   utilizavel para Lorehold nesta chamada.
3. Como o `cache_key` de `/ai/generate` inclui `reference_profile_version`
   quando `referenceProfile != null`, esse `cache.hit=true` com
   `reference_profile_used=false` indica que o problema nao e so "cache velho";
   o caminho publico realmente continuou resolvendo Lorehold via archetype
   fallback no momento do request.

Provas auxiliares no backend publico:

- `GET /ai/commander-learning?commander=Lorehold,%20the%20Historian`
  retornou:
  - `source=pg_commander_learned_decks`
  - `profile=null`
  - `card_stats=null`
  - `deck_corpus=null`
  - mas `promoted_deck` presente (`learned_deck:82`)
- `GET /ai/commander-reference?commander=Lorehold,%20the%20Historian&learning=1&include_deck=1`
  retornou modelo `commander_reference_profile` com `source=edhrec`,
  `meta_decks_found=0` e sem evidenciar o profile PG estruturado usado nos
  audits locais.

Conclusao operacional:

- o banco acessado pelos audits locais/read-only ja mostra Lorehold com
  `profile_usable=true`;
- o backend publico ainda nao expoe esse mesmo estado no caminho live do
  generator;
- portanto, o proximo gap real nao e mais "construir o profile", e sim fechar a
  paridade entre:
  - banco auditado localmente;
  - banco/config usado pelo deploy publico;
  - respostas live de `/ai/generate`, `/ai/commander-learning` e
    `/ai/commander-reference`.

Dry-run complementar sem mutacao no banco real:

- `dart run bin/commander_reference_profile_lorehold.dart --dry-run`
- artefato:
  `server/test/artifacts/commander_reference_profile_lorehold_2026-06-16_dry_run/summary_dry_run.json`

Resultado:

- o payload canonico esperado existe e continua consistente:
  - `profile.confidence = high`;
  - `profile.source_count = 4`;
  - `profile.hash = 8d00b81c4b4e`;
- `reference_card_stats.stats_total = 34`;
- `reference_card_stats.resolved_count = 34`;
- `reference_card_stats.unresolved_count = 0`;
- `profile.usable_after_run = true` no recheck real mais recente.

Leitura correta deste segundo artefato:

- o problema nao esta mais na modelagem do profile do Lorehold nem no row
  persistido atual do banco;
- o gap aberto agora e de **prova operacional do consumo live**:
  confirmar em respostas reais do `/ai/generate` quando o caminho persistido foi
  usado e reduzir a dependencia residual do
  `loreholdDeterministicReferenceFallbackCards`;
- portanto, o proximo slice certo para `/ai/generate` e de telemetry,
  explainability e reducao de fallback literal, nao de upsert do profile.

Os maiores buckets de overlap medidos foram:

- `active_learned_deck`: `32`
- `active_learned_deck + usage_hot_cards`: `24`
- `deterministic_fallback + reference_card_stats`: `18`
- `deterministic_fallback`: `17`
- `active_learned_deck + reference_corpus_packages`: `13`
- `reference_corpus_packages`: `9`

Interpretacao:

- o learned deck promovido ja tem massa propria relevante;
- o usage real esta convergindo para esse learned deck em varias cartas;
- stats + fallback ainda carregam uma parte importante do pacote estrutural;
- corpus ja aparece, mas nao domina sozinho a identidade da lista.

Recheck de explainability instrumentado nesta continuidade:

- `source_usage_counts.reference_card_stats = 34`
- `source_usage_counts.reference_corpus_packages = 36`
- `source_usage_counts.profile_expected_packages = 34`
- `source_usage_counts.usage_hot_cards = 24`
- `source_usage_counts.deterministic_fallback = 59`
- `built_in_fallback_only_count` caiu de `25` para `16`
- `built_in_fallback_only_sample` inclui:
  `Boros Signet`, `Talisman of Conviction`, `Mind Stone`, `Fellwar Stone`,
  `Wayfarer's Bauble`, `Thought Vessel`, `Commander's Sphere`,
  `Marble Diamond`, `Fire Diamond`, `Thrill of Possibility`, `Big Score`

Leitura correta desse recheck:

- o generator local agora expõe proveniência do deck determinístico por carta e
  por bucket;
- `usage_hot_cards` agora entra no builder determinístico antes do
  `loreholdDeterministicReferenceFallbackCards`, sem ler `learned_deck`
  diretamente;
- a hipótese "fallback quase não entra mais" continua errada, mas ela ficou
  menos ruim: o fallback puro residual caiu para `16` cartas;
- o próximo slice seguro para Lorehold continua não sendo remover fallback às
  cegas, e sim atacar primeiro esse bucket residual `fallback_only`.

Recheck 2026-06-17 após ampliar o limite de hot cards aprendidos para 50 no
generator:

- `source_usage_counts.reference_card_stats = 34`
- `source_usage_counts.reference_corpus_packages = 36`
- `source_usage_counts.profile_expected_packages = 34`
- `source_usage_counts.usage_hot_cards = 50`
- `source_usage_counts.deterministic_fallback = 45`
- `built_in_fallback_only_count` caiu de `16` para `2`
- `built_in_fallback_only_sample = [Mind Stone, Fellwar Stone]`

Leitura correta desse recheck:

- o PostgreSQL ja tinha 50 sinais de uso real para Lorehold, mas o caminho live
  de `/ai/generate` cortava a amostra em 24 antes de montar o deck
  determinístico;
- ampliar o consumo para 50 não muda contrato publico, não lê SQLite Hermes como
  fonte final e não copia o learned deck diretamente;
- a dependência residual de fallback literal ficou pequena e explícita, mas ela
  ainda existe e não deve ser apagada sem cobertura por stats/corpus/uso;
- o próximo ajuste de código deve mirar `Mind Stone`/`Fellwar Stone` ou o
  consumo direto controlado do learned deck, não uma remoção ampla do fallback.

### Bug real encontrado e corrigido nesta rodada

`loadUsageHotCards()` estava multiplicando cartas por printings ao fazer join
direto com `cards`. Isso poluia o sinal de uso real de Lorehold.

Correcao aplicada:

- `server/lib/ai/deck_learning_event_support.dart`
  agora usa `LEFT JOIN LATERAL ... LIMIT 1` para escolher um nome canonico sem
  fanout de printings.
- teste guard novo:
  `server/test/deck_learning_event_support_test.dart`

Depois da correcao, o sample de usage deixou de repetir nomes canonicos.

## O que ainda esta forte demais em fallback curado

Ainda existe curadoria literal relevante no caminho de fallback/reference:

- `buildDeterministicReferenceDeck()` usa:
  - stats de referencia;
  - corpus packages;
  - expected packages;
  - e, no caso de Lorehold, um bloco literal
    `loreholdDeterministicReferenceFallbackCards`.

Esse bloco literal nao e errado. Ele e util como fallback seguro para manter o
fluxo create/validate/optimize. O problema e epistemico:

- ele nao representa aprendizado aberto do sistema;
- ele nao cresce sozinho com corpus real;
- ele ancora a geracao em uma lista curada historica.

Portanto, o estado correto e:

- o generator ja e data-backed;
- mas ainda nao e data-owned o bastante para dispensar fallback curado em
  comandantes-chave como Lorehold.

## Onde exatamente Lorehold ainda depende de curadoria

Hoje Lorehold tem tres camadas diferentes, e misturar isso gera leitura errada:

1. `commander_reference_profiles` / `commander_reference_card_stats` /
   `commander_reference_deck_corpus`
   - sinais estruturados reais;
2. `commander_card_usage`
   - sinal real de uso, mas ainda consumido como texto de prompt;
3. `loreholdDeterministicReferenceFallbackCards`
   - lista literal de seguranca para manter deck valido e tematico quando o
     pipeline acima nao basta sozinho.

Logo, o problema real nao e "Lorehold esta totalmente hardcoded". Tambem nao e
"Lorehold ja aprendeu sozinho". O estado verdadeiro e intermediario:

- Lorehold ja esta fortemente ancorado em dados reais;
- mas o ultimo fechamento de composicao ainda aceita uma lista curada historica;
- esse fallback curado ainda mascara o quanto o pipeline profile/stats/corpus
  realmente conseguiria andar sozinho.

## Estado real do fallback `known_cards_generated`

Foi adicionada uma auditoria dedicada em:

- `docs/hermes-analysis/manaloom-knowledge/scripts/audit_known_cards_runtime_fallback.py`

Resultado local em 2026-06-16:

- `1970` nomes existem tanto no fallback gerado quanto no cache canonico
  `battle_card_rules`;
- `1385` ja batem exatamente em bruto;
- `1456` batem exatamente depois da normalizacao real de runtime;
- `297` ainda diferem apenas estruturalmente apos a normalizacao;
- `217` continuam com `effect` realmente diferente mesmo apos a mesma
  normalizacao de runtime aplicada nos dois lados;
- `1189` cartas existem no cache canonico SQLite e nem sequer aparecem no
  `known_cards_generated.json`.

Interpretacao correta:

- o risco residual do fallback legado existe, mas ele e menor do que a leitura
  bruta sugeria;
- a diferenca real que ainda pode alterar comportamento em queda de SQLite/PG e
  de `216` cartas, nao de `431`;
- o cache canonico hoje cobre muito mais cartas do que o snapshot gerado, entao
  o fallback legado e semanticamente mais pobre e menos abrangente do que o
  runtime normal;
- isso nao gera conflito ativo enquanto SQLite/PG estiverem saudaveis, mas
  ainda e um risco operacional relevante para auditoria, reproducoes locais e
  cenarios degradados.

Consequencia pratica:

- nao faz sentido trocar o runtime agora;
- agora o runtime ja aceita um snapshot fallback canonico exportavel a partir
  de `battle_card_rules`, reduzindo a distancia entre o estado normal e o modo
  degradado sem reintroduzir inventario manual no codigo.
- o risco principal nao e mais "conflito silencioso no battle runtime", e sim
  "modo degradado semanticamente mais pobre caso SQLite/PG falhe ou algum
  consumidor paralelo leia o JSON legado sem sobrepor o cache canonico".

### Validacao operacional complementar - 2026-06-16

Revalidacao focada desta rodada:

- `battle_analyst_v9.py` continua resolvendo a regra pela ordem correta:
  `battle_card_rules`/SQLite primeiro, fallback legado depois;
- `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` passou e confirmou
  que os hotfixes promovidos resolvem do registry canonico, nao de inventario
  manual/runtime waiver;
- `test_battle_card_rules_table_overrides_fallbacks` passou dentro da suite
  `battle_card_specific_tests`;
- `test_sync_battle_card_rules_manual_preserve.py` passou e confirmou que a
  sincronizacao atual nao tenta repovoar "manual rows" legadas depois da
  canonicalizacao.

Achado tecnico importante:

- o runtime principal do battle estava coerente;
- a rota secundaria ainda insegura era `universal_optimizer.py`, que lia
  `known_cards_generated.json` cru;
- ela foi alinhada para o mesmo padrao de `slot_optimizer.py`: JSON legado como
  base, `battle_card_rules` por cima como fonte canonica.
- o `battle_analyst_v9.py` agora tenta primeiro
  `known_cards_canonical_snapshot.json` e so depois cai no
  `known_cards_generated.json`;
- `sync_battle_card_rules_pg.py --apply-sqlite-from-pg` passou a exportar esse
  snapshot canonico junto com o refresh do cache SQLite, mantendo o modo
  degradado mais proximo da fonte de verdade.
- `test_known_cards_consumer_guardrail.py` agora protege a fronteira de
  consumidores ativos e falha se algum script novo voltar a tratar o fallback
  legado como fonte primaria sem passar pela camada canonica.

Estado correto apos a validacao:

- sem conflito ativo de precedencia no battle runtime;
- sem conflito ativo na rota secundaria mais obvia do optimizer Hermes;
- snapshot canonico agora esta implementado como fallback suportado;
- o snapshot canonico tambem foi materializado localmente em
  `known_cards_canonical_snapshot.json` e a auditoria
  `audit_known_cards_runtime_environment.py` fechou com `status=PASS`
  (`canonical_fallback_count=3159`, `handcrafted_count=0`,
  `manual_waiver_count=0`);
- o pendente restante virou rollout operacional:
  garantir que os jobs Hermes efetivamente refresquem esse snapshot no ambiente
  AWS e apos isso reduzir ainda mais a dependencia do `known_cards_generated`
  como ultimo recurso historico.

Drift operacional observado no Hermes AWS:

- o `master` local resolveu com:
  - `HANDCRAFTED_KNOWN_CARDS=[]`;
  - `MANUAL_RULE_RUNTIME_WAIVERS=[]`;
  - ordem `battle_card_rules -> known_cards_canonical_snapshot -> known_cards_generated`.
- apos export local do snapshot canonico:
  - `known_cards_canonical_snapshot.json` presente;
  - `canonical_fallback_count=3159`;
  - `known_cards_count=3159`;
  - auditoria de ambiente local em `PASS`.
- a primeira leitura remota induzia que o problema principal era branch errada,
  porque o workspace `/opt/data/workspace/mtgia` estava parado em
  `codex/hermes-analysis-docs` (`HEAD 2edcc757`) e sem snapshot canonico.
- a revalidacao operacional refinou a conclusao:
  - o script remoto `/opt/data/scripts/known_cards_validator_cron.sh` faz
    `git checkout master` corretamente e executa no SHA `9c1ca349`;
  - o primeiro replay operacional mostrou que o cron ainda nao exportava o
    snapshot canonico;
  - apos hotfix compatível no cron remoto + `sync_battle_card_rules_pg.py`, o
    arquivo `known_cards_canonical_snapshot.json` passou a ser materializado
    com `canonical_snapshot_rows_exported=3158`;
  - o passo seguinte foi roll-outar tambem no Hermes AWS o trio local ja
    validado (`battle_analyst_v9.py`, `known_cards_fallback_snapshot.py`,
    `sync_battle_card_rules_pg.py`);
  - apos essa rodada completa, o auditor remoto
    `audit_known_cards_runtime_environment.py` fechou com:
    - `git_branch=master`;
    - `git_sha=9c1ca349`;
    - `known_cards_count=3158`;
    - `canonical_fallback_count=3158`;
    - `handcrafted_count=0`;
    - `manual_waiver_count=0`;
    - `status=PASS`.

Leitura correta:

- a logica do `master` ficou coerente;
- o risco restante nao e conflito de precedencia no repo principal;
- o risco restante tambem nao e simplesmente "Hermes numa branch antiga";
- o runtime Hermes AWS agora tambem ficou coerente depois do hotfix operacional;
- o gap que sobra deixou de ser logico/runtime e virou gap de rollout
  versionado/deploy: o estado remoto passou a ficar correto, mas ainda precisa
  ser preservado por commit/push/deploy formal para nao regredir no proximo
  rebuild do container.

## Onde `card_role_scores` entra hoje

`card_role_scores` e o slice mais promissor para melhorar criacao e optimize,
mas o uso ainda esta em transicao.

O que ja existe:

- tabela `card_role_scores`;
- builder `buildCandidateRoleScores`;
- bonus bounded por `edhrec_inclusion_rate` e `edhrec_sample_decks`;
- suporte interno para foundation/apply controlado;
- consumo evidente no optimize candidate quality;
- uso indireto em commander reference/profile pipelines.

O que ainda nao esta plenamente provado:

- geracao final data-driven usando `card_role_scores` como motor principal de
  selecao de cartas, acima do fallback curado;
- apply amplo sem stale prune controlado e sem scorecards novos de regressao.

Conclusao:

- `card_role_scores` e caminho de evolucao correto;
- ainda nao e verdade operacional suficiente para substituir sozinho a
  referencia/corpus/fallback atual.

## Estado real do Lorehold como caso de controle

## O que Lorehold ja prova

O deck canonicamente recomendado em
`LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md` ja estabelece uma base de
controle util:

- 1 comandante;
- 99 cartas no main deck;
- identidade RW consistente;
- sem `Chrome Mox`, `Mox Diamond` e `Mox Opal`;
- sem ban global de Mox no produto;
- `Mox Amber` mantido por decisao contextual;
- plano de jogo claro:
  Boros spellslinger / topdeck / miracle / wheels / big-spell finishers.

`LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` mostra:

- `0` nonlands unmodelled;
- `0` high-risk cards;
- utility lands ainda como principal risco medio, mas agora com `Urza's Saga`
  fora do estado puramente baseline;
- cobertura suficiente para tratar o deck como caso de controle valido.

Em termos praticos, Lorehold hoje ja permite validar:

- save/import/validate;
- explainability de lista;
- optimize;
- replay;
- battle decision trace;
- learned deck gating.

## O que Lorehold ainda nao prova

Lorehold ainda nao prova sozinho:

- que o battle sabe jogar bem contra cobertura ampla de oponentes;
- que o deck aprendido 82 e ideal no sentido absoluto;
- que o conjunto atual de fallback/reference e o melhor possivel;
- que swaps futuros promovidos por learning sao confiaveis sem scorecard maior.

Lorehold hoje deve ser tratado como:

- caso de controle;
- pacote de regressao;
- deck para medir melhora real;
- nao como prova final de qualidade universal do sistema.

## O que realmente falta implementar

## P0

Nenhum blocker novo de arquitetura foi confirmado neste estudo.

O sistema nao precisa parar tudo para "consertar battle do zero". Esse seria o
movimento errado neste momento.

## P1 - battle que melhora o valor do dado

0. Promover a semantica canônica de fast mana condicional antes de aprender com
   ela.
   - Caso concreto ja observado: `Mox Amber` tinha regra promovida sem a flag
     de mana condicional no snapshot/SQLite, o que inicialmente exigiu waiver
     explicito para bloquear keep falso de opening hand.
   - Proximo passo correto:
     - corrigir a linha canônica em PG/SQLite/snapshot;
     - rerodar auditor de ambiente e replay seed de controle;
     - manter o runtime sem waiver local e fechar a mesma paridade no rollout
       PG/Hermes remoto.
   - Ganho: mulligan, mana refresh e ranking de fast mana param de depender de
     hotfix local.

1. Hard-model das utility lands mais relevantes do Lorehold.
   - Motivo: hoje elas ainda contam mais como mana/metadata do que como
     decisoes de valor/ativacao.
   - Ganho: replay mais fiel, melhor aprendizado de timing e menos falso
     positivo no scorecard.

2. Fechar cartas recorrentes de oponente com `review_rule_used`.
   - Prioridade atual observada:
     `Ashnod's Altar`, `Incubation Druid` e qualquer outra que voltar a aparecer
     no audit low recorrente.
   - Ganho: reduzir ruido de battle coverage.

3. Evoluir `decision_trace_v1` para decisao comparativa.
   - Adicionar de forma sistematica:
     - opcoes rejeitadas relevantes;
     - motivo de rejeicao;
     - beneficio esperado;
     - custo de recurso;
     - risco.
   - Ganho: sair de "evento correto" para "decisao auditavel".

4. Criar scorecard estatistico no estilo 17Lands, mas Commander-safe.
   - Minimos:
     - WR com carta vista;
     - WR sem carta vista;
     - WR com carta castada;
     - delta contra baseline congelado;
     - amostra minima;
     - impacto por arquetipo/oponente.
   - Ganho: parar de confiar em WR bruto.

4.1. Formalizar o mulligan Commander como heuristica auditavel e nao apenas
     regra de legalidade.
   - Fonte-base validada nesta rodada:
     - London Mulligan oficial;
     - Commander oficial;
     - EDHREC para `curve`, `color`, `plan`, `sequencing` e necessidade
       eventual de `interaction`.
   - Status 2026-06-17:
     - `choose_mulligan_bottom_cards()` substituiu o bottom aleatorio;
     - bombas 7+/8+ sem curva/ramp/selecao passam a ir para o fundo antes de
       lands necessarias e jogadas iniciais;
     - excesso de land so vai para o fundo quando nao ha spell morta melhor;
     - fast mana morta continua fora do plano inicial.
   - Proximo passo correto:
     - manter trace com `why keep`, `why mull`, `why bottom` e alternativas
       rejeitadas;
     - medir a politica em corpus maior contra baseline fixo.
   - Ganho: Lorehold para de inflar dados por maos "legais" mas
     estrategicamente ruins.

## P1 - generator que melhora o valor do dado

5. Reduzir dependencia do fallback literal de Lorehold.
   - Nao removendo o fallback agora.
   - Primeiro passo correto:
     usar mais ranking estruturado de profile/stats/corpus/usage para decidir a
     ordem e a composicao antes de cair na lista fixa.
   - Ganho: deck mais explicavel e menos "preset curado".

6. Definir se `/ai/generate` deve ter modo opcional de ownership por learned
   deck promovido.
   - Nao por default.
   - Nao para partner/background ainda.
   - Nao expondo metadata Hermes ao usuario comum.
   - Mas com policy clara:
     - quando usar `commander-learning` como canal separado;
     - quando usar learned deck apenas como source de ranking interno;
     - quando nao usar learned deck nenhum.
   - Ganho: parar a ambiguidade entre "gerado com IA" e "carregado do learned
     deck".

7. Provar o consumo live do profile persistido do Lorehold antes de exigir mais IA.
   - O recheck real mais recente mostrou `profile.usable = true`,
     `profile.confidence = high`, `profile.source_count = 4` e
     `deterministic_main_count = 99`.
   - Ajuste correto:
     - rastrear em resposta real do `/ai/generate` quando o persisted profile foi
       usado;
     - alinhar o banco/config do deploy publico ate que
       `diagnostics.reference_profile_used=true` e
       `runtime_profile_origin` fique ausente para Lorehold;
     - rerodar o provenance audit e o readiness scorecard quando houver mudança
       no generator;
     - reduzir a dependencia do fallback literal quando o persisted profile ja
       estiver provado em runtime.
   - Ganho: o generator passa a usar sua propria pilha estruturada com prova
     operacional, nao apenas por inferencia de banco.

8. Promover usage real de guidance textual para ranking deterministico auditavel.
   - O bug de fanout por printings foi corrigido nesta rodada, entao o proximo
     passo agora pode ser estatistico/ranking, nao mais higienizacao basica do
     dado.
   - Ajuste correto:
     - usar usage como peso adicional por carta;
     - com limite por pacote/role;
     - sem quebrar legalidade, curva e estrutura.
   - Ganho: generator mais conectado ao comportamento real de usuarios.

8.1. Sair do bucket hardcoded de arquétipo no quality gate e passar a usar
     `role_targets`/assinatura do profile quando disponivel.
   - O fix de `combo` resolveu o erro mais gritante de Lorehold:
     `tutor/engine/wincon/protection` nao caem mais no fallback de
     `removal/ramp`.
   - O gap remanescente agora e mais fino:
     - contagem de lands ainda sai de bucket fixo;
     - ranges por papel ainda nao leem o profile persistido;
     - `combo`/`control`/`midrange` ainda resumem estrategias diferentes demais.
   - Ganho: quality gate mais aderente ao profile real do comandante sem
     reintroduzir prompt-ownership no backend.

9. Promover `card_role_scores` com janela controlada.
   - Revisar stale prune;
   - executar apply controlado;
   - rodar scorecards generate/optimize;
   - comparar Lorehold e comandantes de controle.
   - Ganho: candidatas mais fortes e menos dependentes de heuristica textual.

10. Adicionar explainability backend-owned por carta gerada.
   - Exemplo por carta:
     - `source_profile`
     - `source_corpus`
     - `source_usage`
     - `source_learned_deck` ou `source_learned_rank`
     - `source_fallback`
     - papel funcional
     - por que entrou
   - Ganho: resposta melhor para o produto e para QA ("por que ele considerou
     essa carta?").

11. Separar claramente no payload interno:
   - deck gerado por referencia/corpus;
   - deck gerado por fallback deterministico;
   - deck gerado com suporte de learned ranking;
   - deck corrigido por validacao/repair.
   - Ganho: auditoria e scorecard mais honestos.

## P1 - governanca de verdade

12. Higienizar proveniencia de regras promovidas.
    - Hoje o runtime manual esta zerado, mas PG/SQLite ainda preservam `486`
      regras com `source='manual'`.
    - Isso nao e conflito funcional, mas e ruido conceitual.
    - Ganho: menos confusao em futuras auditorias.

13. Manter `card_battle_rules` fora de joins diretos de deckbuilding.
    - Isso continua sendo regra estrutural.
    - Sempre agregar por `card_id` ou usar snapshot one-row-per-card.

12. Manter SQLite Hermes como cache/lab.
    - Nenhum passo deste estudo autoriza mover ownership de decisao para
      SQLite Hermes.

## P2 - backlog correto, nao blocker do ciclo atual

13. Support partner/background em learned decks.
14. Expandir corpus para outros comandantes alem de Lorehold.
15. Adotar `commander_learning_snapshot` como loader diagnostico/analitico
    unico, evitando consumidores paralelos montando agregados diferentes sobre
    learned decks, usage e synergy.
16. Concluído em 2026-06-16: o snapshot legado embutido em
    `battle_analyst_v9.py` foi removido do código ativo. O runtime mantém
    apenas `KNOWN_CARDS = {}` para carregamento posterior de registry/snapshot
    canonico/fallback gerado e para waivers explícitos de teste/incidente. O
    guardrail `test_known_cards_consumer_guardrail.py` falha se o dicionário
    manual ou engines antigos forem restaurados.
17. Formalizar em backend mais sinais de `why this card` para app/admin/debug.

## O que nao deve ser feito agora

1. Nao reescrever o battle simulator do zero.
2. Nao tratar WR bruto de Lorehold como verdade.
3. Nao globalizar politicas locais do Lorehold, como "banir todos os Mox".
4. Nao usar branch docs Hermes como fonte principal se ela estiver atrasada do
   `master`.
5. Nao substituir corpus/reference/validation por prompt puro.
6. Nao promover `needs_review` para comportamento duro sem replay e teste.
7. Nao usar `card_battle_rules` como tabela principal de papel de deckbuilding
   via join cru.

## Ordem recomendada de execucao

1. Hard-model das utility lands mais impactantes do Lorehold.
2. Limpeza das regras recorrentes `review_rule_used` de oponentes.
3. Expandir `decision_trace_v1` para comparacao de opcoes.
4. Construir scorecard estatistico Commander-safe sobre replays.
5. Executar apply controlado de `card_role_scores` com stale prune revisado.
6. Definir explicitamente a fronteira entre `/ai/generate` e
   `/ai/commander-learning`, para learned deck nao contaminar scorecards errados.
7. Reordenar/parametrizar o builder de deck para depender mais de
   stats/corpus/usage antes do fallback literal Lorehold. O slice 2026-06-17 ja
   ampliou `usage_hot_cards` para 50 e reduziu `fallback_only` para 2 cartas.
8. Adicionar explainability backend-owned por carta gerada.
9. So depois considerar nova rodada forte de learned deck promotion.

## Truth status final

### Battle

- **Status**: usable laboratory, not strategic truth engine.

### Generator

- **Status**: hybrid and useful, but still partially fallback-curated.

### Lorehold

- **Status**: valid control deck, not universal proof of correctness.

### Next best move

- **Status**: focar agora em melhorar a qualidade do dado que alimenta
  geracao/optimize, nao em abrir novos modulos ou fazer redesign estrutural.

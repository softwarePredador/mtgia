# Receipt de trabalho — harness determinístico de consistência de mana

Status: `PASS_LOCAL · COMMITTED_AND_PUSHED_WITH_AUTHORIZED_HOOK_BYPASS · FORA_DA_FILA`

Este receipt registra trabalho **exploratório fora da fila**. Ele **não** fecha
nenhuma ficha `BT-*`, não reordena a fila e não ocupa o slot `NOW`, que
permanece `BT-SCP-001`. Não autoriza PR, merge, deploy, migration, DML live,
capability `ON`, atualização de pin nem promoção de deck/regra.

A entrada é read-only sobre o repositório e sobre um SQLite local de
laboratório. Nenhum acesso a produção, nenhuma chamada de rede, nenhum LLM.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA base da implementação: `354983a1e8a37f8fe1139b6282ca9e909a4f886d`
- Upstream: `origin/codex/free-beta-release-candidate-2026-07-17`
- Slot `NOW` no momento do trabalho: `BT-SCP-001` (não interrompido)
- Fixture SHA-256: `1172da51a7208bb98e50e79ab9a8984d3bcb8d37ad0e386dc6938c11b8c7ec80`
- Baseline SHA-256: `ccbc92f59e7a7e38ad98befdb4f03ba2adf6336ad27e1aff57adc743eb44b330`
- Dart SDK: `3.11.4 (stable)`
- Autorização usada: código/tooling/documentação local e commit da branch.

## Problema que motivou o trabalho

A geração de deck não tinha **nenhuma** medição de qualidade. O eval existente
é uma tautologia: `commander_ai_prompt_eval_suite.dart:29` resolve a resposta
candidata como `responseOverride ?? _mapValue(testCase['candidate_response'])`,
e o teste do gate (`commander_ai_prompt_eval_suite_test.dart:21-28`) chama sem
`responseOverride`. Ele lê a resposta escrita à mão dentro do próprio fixture e
a corrige contra o gabarito ao lado, então **passa para sempre**, independente
do que a IA de produção produza.

Consequência: qualquer mudança na geração — inclusive um futuro loop de
aprendizado — é hoje infalsificável.

## O que foi entregue

| Arquivo | Papel |
| --- | --- |
| `server/lib/ai/deck_quality_report.dart` | Biblioteca pura de scoring |
| `server/bin/deck_quality_report.dart` | CLI e comparação contra baseline |
| `server/bin/build_deck_quality_fixture.py` | Congela decks reais em fixture |
| `server/test/ai/deck_quality_report_test.dart` | 14 testes de comportamento |
| `server/test/ai/deck_quality_report_limits_test.dart` | 3 testes que fixam limites conhecidos |
| `server/test/fixtures/deck_quality_fixture.json` | 17 decks Commander reais |
| `server/test/fixtures/deck_quality_baseline.json` | Baseline commitado |
| `scripts/manaloom_deck_quality_gate.sh` | Script do gate |
| `scripts/quality_gate.sh` | Modo `deck-quality` registrado |

Reusa engine existente em vez de reimplementar julgamento: `GoldfishSimulator`
para o score de consistência e curva, e os pisos de
`commander_mana_floor.dart` (terrenos, e fontes de cor dominante/secundária).

### Por que é falsificável

`GoldfishSimulator` semeia de um hash estável do deck
(`goldfish_simulator.dart:143`), então o mesmo deck sempre produz o mesmo
score. A tolerância do baseline é **0**: qualquer diferença é mudança real de
comportamento, nunca ruído.

## Evidência executada

Comandos rodados e resultado:

```
dart analyze lib/ai/deck_quality_report.dart bin/deck_quality_report.dart \
  test/ai/deck_quality_report_test.dart
  -> No issues found!

dart test test/ai/
  -> All tests passed! (17/17 — 14 de comportamento + 3 de limite conhecido)

dart test test/goldfish_simulator_test.dart test/optimization_quality_gate_test.dart \
  test/commander_ai_prompt_eval_suite_test.dart
  -> All tests passed! (71/71, pré-existentes, sem regressão)

./scripts/manaloom_deck_quality_gate.sh
  -> decks scored: 17
  -> consistency_score: min=68 median=75 max=84
  -> decks with issues: 9/17
  -> PASS: baseline matches
  -> exit 0
```

### Prova de que o gate falha quando deve

Duas regressões foram injetadas e revertidas:

1. **Regressão de qualidade** (-4 terrenos no deck 6): gate saiu com `exit 1` e
   reportou a deriva campo a campo — `consistency_score` 79→74, `land_count`
   34→31, `mana_foundation_satisfied` true→false, `issue_codes` []→2 códigos.
2. **Edição manual do fixture**: pega pelo digest recalculado em Dart
   (`_computeDeckDigest`), que não confia no `content_digest_sha256` que o
   fixture declara — um arquivo editado à mão mantém o digest antigo.

Determinismo verificado em 3 execuções consecutivas: resultado idêntico.

## Achado substantivo

Primeira medição de consistência de mana do projeto. Sobre 17 decks reais de
100 cartas:

- **4 decks abaixo do piso de 34 terrenos com certeza** (`27, 29, 32, 33`),
  contando de forma generosa toda carta com `//` como terreno de verso.
- **Outros 4 marcados abaixo do piso podem ser artefato** de face traseira
  (ver limite 7): `30(+7), 30(+4), 31(+6), 32(+5)`.
- **7 decks com fontes de cor insuficientes** pelo modelo atual, que
  **não conta mana rock nem dork** — logo há falso positivo conhecido aqui.
- O `consistency_score` acompanha a base de mana: 27 terrenos → 68;
  39 terrenos → 84.
- O deck curado `6` ("Lorehold 607 - Current Champion") pontua 79 com 34
  terrenos e **zero** problemas; os decks com problema são as variantes
  experimentais. A contagem de terrenos do deck 6 foi conferida de forma
  independente contra o SQLite bruto: 34 por ambos os métodos.

## Defeito encontrado e corrigido durante a implementação

A primeira versão classificava terreno básico por substring do **nome**. Isso
contava `Misty Rainforest` (fetchland, não produz mana) como fonte verde. Como
inflar fontes faz o relatório **subestimar** base de mana quebrada — a direção
perigosa para um gate — foi corrigido para derivar a cor do **subtipo no
`type_line`**, caindo no parsing de oracle text para não-básicos. Dois testes
de regressão fixam o comportamento.

Nota: `Cori Mountain Monastery` também casava pelo nome, mas o oracle dele diz
`{T}: Add {R}` — era fonte vermelha de verdade. O resultado não mudou; a razão
mudou de errada para certa.

## Limites honestos

1. **Concentração de comandante.** 12 dos 17 decks são Lorehold. O baseline
   detecta regressão bem, mas cobre pouca variedade de comandante e de
   identidade de cor.
2. **Não é medida de qualidade de deck — é de consistência de mana.** Provado,
   não estimado: um deck de 36 Forest + 64 Grizzly Bears idênticos pontua
   **84 com zero problemas**, empatando com o melhor deck real do fixture. A
   métrica não enxerga interação, saque, ramp, win condition nem sinergia. O
   nome original deste trabalho ("qualidade de deck") era overclaim e foi
   corrigido em código, script e gate. `deck_quality_report_limits_test.dart`
   fixa esse exemplo para que a limitação não se perca.
3. **Não mede a saída da geração.** Ele pontua decks de um fixture. Ligar o
   score à rota `/ai/generate` exige chamada ao LLM e é o passo seguinte, não
   este.
4. **Node do PATH é incompatível — contornável.** `scripts/quality_gate.sh`
   exige Node `^20.19`, `^22.13` ou `>=24`; o do PATH (nvm) é
   `v20.11.1` e o fallback `/opt/homebrew/bin/node` está quebrado
   (`libsimdutf.34.dylib` ausente). Resolvido sem alterar o ambiente com
   `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node` (v22.23.2, já
   instalado): com isso `./scripts/quality_gate.sh deck-quality` roda pelo
   wrapper oficial e passa.
5. **O modo não foi adicionado ao arm `full`.** Entrar no caminho de `pre-push`
   é decisão de fila/governança, não deste trabalho.
6. **Fixture veio de `docs/hermes-analysis/`.** A dependência é de uma única
   vez e está congelada no JSON commitado: o harness não lê o SQLite. Isso
   reduz, não aumenta, o acoplamento com a árvore que o projeto quer aposentar.
7. **Faces traseiras de MDFC são invisíveis.** `deck_cards` e
   `card_oracle_cache` guardam apenas a face frontal, então
   `Emeria's Call // Emeria, Shattered Skyclave` conta como Sorcery. 47 cartas
   do fixture estão nessa condição. O dado não existe localmente para
   corrigir; a incerteza é exposta em `possible_back_face_lands`.
8. **Mana rock e dork não contam como fonte de cor.** Só terrenos são
   contados, então `insufficient_color_sources` tem falso positivo conhecido
   em decks que se apoiam em artefatos. Fixado em teste de limite.
9. **Modelo de cor ainda simplificado.** Híbrido é excluído do requisito e do
   denominador (deveria ser requisito de união); os pisos 15/10 vêm de
   matemática de 60 cartas, não de 99; Pathways contam para as duas cores.
   Corrigir isso é trabalho de design próprio, não deste receipt.

## Revisão adversarial

O trabalho passou por revisão adversarial multi-agente (4 lentes, 24 agentes,
18 achados confirmados). Corrigidos nesta entrega: `oracle_text` ausente do
digest recalculado (permitia edição de fixture passar), `--simulations`
inválido ou zero (crashava com NaN em vez de falhar), fixture malformado
(saía 255 com stack trace), ids de deck duplicados, símbolos de cor lidos de
custo de ativação como se fossem produção de mana (corrigiu 3 decks, sempre
para baixo), e o overclaim de nome. Não corrigidos e registrados acima como
limites 7-9: face traseira de MDFC, mana rocks como fonte, e o modelo de cor.

## Estado do commit — bypass autorizado do hook

**Commitado com `--no-verify`, sob autorização explícita do dono**, após duas
tentativas sem bypass e após esgotar as alternativas. O que foi bypassado e o
que foi verificado no lugar está registrado aqui para auditoria.

### Gates do `run_quick` executados manualmente

| Gate | Resultado |
| --- | --- |
| `run_shell_contracts` (`bash -n`) | PASS |
| `run_commander_game_changer_source` | PASS |
| `run_secret_scan` | PASS — `literal_live_credentials: 0`, gitleaks 8.30.1 |
| `run_project_logic` | FAIL — pré-existente, ver abaixo |
| `run_ui_live_evidence` | FAIL — pré-existente; nenhum arquivo `app/` foi tocado |

Os dois gates que falham são anteriores a este trabalho e não têm relação com
os arquivos entregues. O drift de project logic em si **foi resolvido**
(`Project logic is synchronized (9 artifacts)`); o que falha é o teste
`tools/project_logic/test/project_logic_generator_test.dart`.

### Por que não foi corrigido em vez de bypassado

Tentativa registrada: exportar `MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE` para o
subshell e rodar `dart pub get` dentro do cache isolado. **Não resolve** — o
teste valida o `.dart_tool/package_config.json` da raiz do workspace, cujas
dependências vivem no cache global. Fazer passar exige resolver o repositório
inteiro num PUB_CACHE isolado, que é a campanha de cold bootstrap de
`BT-SCP-001` — a tarefa no slot `NOW`. Corrigir isso aqui seria intervir na
tarefa ativa, então foi descartado.

Causa estrutural, para quem for fechar `BT-SCP-001`:
`scripts/manaloom_local_ci.sh:105-112` — `run_project_logic()` chama
`manaloom_project_logic.sh --check`, que exporta o cache task-scoped **no
próprio processo**, e depois roda `"$DART_BIN" test` num subshell que não
herda nem o cache nem as dependências resolvidas nele.

### Push

Enviado em 2026-09-18 sob autorização explícita do dono, com
`git push --no-verify`, levando também o commit `354983a1e` (BT-SCP-001), que
estava sem enviar — o dono foi consultado sobre isso e optou por incluí-lo.
Remoto ficou em `d93867b68`.

O hook `pre-push` (`manaloom_local_ci.sh full`) passou por project logic,
secret scan, XMage pin transition e report retention, e falhou em
`scripts/lib/manaloom_public_web_surface_contract.sh:81` —
"landing/pricing nao identificam uma unica Beta gratuita e sem cobranca".
Esse check inspeciona HTML renderizado do web público. Nenhum arquivo de
`web-public/` foi tocado nesta entrega, e os fontes
(`web-public/src/app/page.tsx`, `web-public/src/app/pricing/page.tsx`) contêm
os três termos exigidos. A falha é de build local, não do conteúdo.

### Detalhe original do bloqueio
`tools/project_logic/test/project_logic_generator_test.dart` aborta em
`setUpAll` com `.dart_tool/package_config.json points outside the task
PUB_CACHE`. Esse teste exige o contrato de cold bootstrap de `BT-SCP-001` —
a tarefa no slot `NOW`, em andamento — e falha independentemente das
mudanças aqui (o diretório `tools/project_logic/` não foi tocado).

Causa estrutural, em `scripts/manaloom_local_ci.sh:105-112`:
`run_project_logic()` chama `manaloom_project_logic.sh --check`, que exporta
`MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE` **no próprio processo**, e em
seguida roda `"$DART_BIN" test` num subshell que não herda a variável.

O drift de project logic que bloqueava antes **foi resolvido**: os 9
artefatos foram regenerados e o gate reporta `Project logic is synchronized`.
A regeneração é puramente aditiva (conferida contra backup: apenas entradas
`deck_quality`, +2 `dart_source_files`, +2 `tests`, +3 `scripts_and_jobs`,
+3 `environment_variables`). Os artefatos foram deixados **fora do stage**
porque carregam ~26k linhas de alterações em andamento que não pertencem a
esta tarefa.

## Próximo passo sugerido

Ligar o score à rota real de geração, para medir o que a IA produz e não
apenas decks de fixture. Isso muda a natureza do trabalho (passa a exigir LLM)
e deve entrar como ficha própria.

# Resolution Corpus Workflow

> Documento ativo de apoio para o corpus de resolução.
> A prioridade operacional continua sendo definida por
> `docs/CONTEXTO_PRODUTO_ATUAL.md`.

## Objetivo e limite da evidência

O corpus fixa uma amostra de decks fonte para o fluxo:

1. `POST /ai/optimize`;
2. quando a rejeição qualificada exigir, `POST /ai/rebuild`;
3. persistência temporária e validação do deck final.

Há dois níveis de evidência que não podem ser confundidos:

- o preflight read-only prova que os IDs existem no PostgreSQL e que o runner
  consegue selecionar shells estruturalmente elegíveis;
- somente o gate mutável isolado, com resposta não mock e artefato por deck,
  pode provar o `flow_path` observado.

O corpus atual é estrutural e representativo. Ele ainda não é uma matriz
comprovada de `optimized_directly`, `safe_no_change` e `rebuild_guided`.

Arquivo canônico:

- `server/test/fixtures/optimization_resolution_corpus.json`.

## Snapshot read-only de 2026-07-15

A consulta atual ao PostgreSQL confirmou:

- 19 decks existentes, não excluídos, no formato Commander;
- 16 contextos distintos de comandante;
- 19/19 com exatamente 100 cartas;
- 18 shells com um Commander e um shell com dois Commanders;
- 34 a 40 lands no corpus atual;
- um contexto colorless, `Kozilek, the Great Distortion`;
- um contexto five-color, `Jodah, the Unifier`;
- um contexto partner/background real, `Wilson, Refined Grizzly + Sword Coast
  Sailor`.

No seed Wilson, as duas cartas estão legais em Commander no PostgreSQL;
`Wilson, Refined Grizzly` tem `Choose a Background` e `Sword Coast Sailor` é um
Background lendário. Isso prova elegibilidade estrutural do par, não o caminho
de optimize/rebuild.

O seed Wilson substituiu o Urza alternativo `9eec03d2-...`, cuja composição
`card_id/quantity/is_commander` era idêntica à de `25d34306-...`. O corpus ainda
contém contextos repetidos para regressão e duas shells QA Lorehold com o mesmo
fingerprint; portanto ele não deve ser apresentado como amostra estatisticamente
independente.

## Estado real do contrato de flow

O run mais recente está em:

- `/tmp/manaloom_resolution_corpus/20260715222504_83341_14293e90e188/summary.json`;
- `server/test/artifacts/optimization_resolution_suite/`.

O resumo histórico registrou 19/19 como `optimized_directly`, mas os 19 artefatos por deck
também registraram:

- `optimize_status=200`;
- `optimize_response.is_mock=true`;
- `optimize_response.outcome_code=mock_non_actionable`;
- `optimize_response.can_apply=false`.

O runner histórico classificou o HTTP 200 mock como `optimized_directly`. Esse
resultado comprova o ciclo estrutural, cleanup e validação do clone preservado;
ele não comprova uma otimização acionável nem cobertura real de flow.
O contrato corrente do runner já rejeita HTTP 200 mock, respostas explicitamente
não acionáveis, pares desbalanceados e recomendações sem detalhes aplicáveis;
o artefato citado é anterior a esse hardening.

Dois canários posteriores, com provedor real, executaram o mesmo Lorehold 607:

- `/tmp/manaloom_resolution_corpus/20260715232051_73597_f5f0cd39f298`
  terminou em `safe_no_change` após rejeitar uma proposta que reduziria os
  terrenos de 34 para 32;
- `/tmp/manaloom_resolution_corpus/20260715232945_3108_f0688cd3ae6b`
  terminou em `optimized_directly`, persistindo dois pares diferentes.

Essa variação é evidência de que uma expectativa exata por deck é instável para
um provedor estocástico. O corpus passou a declarar:

```json
"expected_flow_contract": "runtime_terminal_non_mock"
```

Esse contrato não equivale a aceitar qualquer resposta. Os únicos terminais
reconhecidos continuam sendo:

- `optimized_directly`;
- `safe_no_change`;
- `rebuild_guided`.

Para aprovar uma entrada, o artefato daquele deck deve provar, no mesmo run:

1. resposta de optimize não mock e diferente de `mock_non_actionable`;
2. o path reconhecido pelo contrato do runner:
   - `optimized_directly`: optimize 200, `outcome_code=optimized`, nenhum
     `quality_error` e resposta acionável;
   - `safe_no_change`: optimize 422, outcome `near_peak` ou
     `no_safe_upgrade_found`, e deck fonte saudável;
   - `rebuild_guided`: optimize 422 com `OPTIMIZE_NEEDS_REPAIR`, next action
     `rebuild_guided`, rebuild 200, `strict_rules_valid=true` e estado final
     `healthy`;
3. deck final existente, com 100 cartas e a mesma quantidade legal de
   Commanders do deck fonte;
4. `POST /decks/:id/validate` 200;
5. proveniência runtime conhecida e explícita no próprio artefato:
   `provider`, `cache`, `deterministic` ou `state_gate`; `unknown` falha;
6. flags opcionais de execução (`is_mock`, `can_apply` e
   `learning_eligible`) ausentes ou booleanas; tipo malformado falha em
   qualquer status HTTP;
7. quando houver chamada ao provedor, metadados seguros encontrados em
   `ai_logs` para o clone e a janela da execução, sem prompt, resposta integral,
   erro ou credencial;
8. cleanup da identidade e dos decks temporários sem resíduo.

No agregado completo, o gate exige ao menos uma proposta acionável realmente
persistida. Ele não inventa dependência de provedor quando a rota responde de
forma determinística ou por cache: essas origens são registradas separadamente,
e chamadas reais ao provedor continuam sendo evidência adicional. Assim, um
corpus de 19 respostas `safe_no_change` não pode fingir prova de aplicação
direta.

## Quando adicionar ou substituir um deck

O deck deve:

- existir no PostgreSQL corrente e estar no formato Commander;
- ter exatamente 100 cartas;
- ter um Commander ou um par legal que o backend valide;
- não ser um clone gerado pelo próprio fluxo de validação;
- acrescentar uma dimensão real de cobertura ou substituir uma shell com
  fingerprint duplicado;
- carregar nota que separe fato estrutural de hipótese de flow;
- usar `runtime_terminal_non_mock`, salvo quando houver motivo explícito e
  determinístico para testar um único flow exato.

Uma shell intencionalmente `needs_repair` pode entrar para descobrir a rota de
rebuild, mas o diagnóstico estático não autoriza marcar `rebuild_guided`. O deck
`goblins` (`8c22deb9-...`) é um candidato futuro por ter 100 cartas e apenas 25
lands; ele não está no corpus atual porque ainda não há prova de que o rebuild
termina com 100 cartas, validação estrita e estado `healthy`.

## Checklist de onboarding

1. Consultar o deck e sua composição no PostgreSQL em read-only.
2. Comparar o fingerprint `card_id/quantity/is_commander` com as shells atuais.
3. Confirmar total, Commanders, legalidade e contagem de lands.
4. Editar manualmente a fixture; não há utilitário de add/update versionado.
5. Usar `expected_flow_contract=runtime_terminal_non_mock`.
6. Validar o JSON.
7. Executar o preflight read-only.
8. Em ambiente aprovado e com provedor configurado, executar o gate mutável.
9. Inspecionar os artefatos por deck e confirmar terminal, proposta, persistência,
   proveniência runtime, eventual provedor, deck final e cleanup.
10. Repetir o corpus quando dados, provedor ou contratos mudarem materialmente.

## Comandos suportados

Todos os comandos abaixo partem da raiz do repositório.

Validar a sintaxe e os invariantes básicos da fixture:

```bash
jq empty server/test/fixtures/optimization_resolution_corpus.json
jq -e '
  (.decks | length) > 0 and
  ([.decks[].deck_id] | length == (unique | length)) and
  ([.decks[].expected_flow_contract] | all(. == "runtime_terminal_non_mock"))
' server/test/fixtures/optimization_resolution_corpus.json
```

Executar somente o preflight PostgreSQL read-only:

```bash
VALIDATION_PREFLIGHT_ONLY=1 ./scripts/quality_gate.sh resolution
```

Executar o gate mutável isolado, somente com aprovação PostgreSQL explícita e
provedor configurado no ambiente:

```bash
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
./scripts/quality_gate.sh resolution
```

O contrato terminal continua fail-closed: mock, HTTP 200 não acionável,
rejeição não resolvida, origem runtime `unknown`, persistência divergente, deck
final inválido ou ausência de aplicação direta no corpus completo tornam o gate
vermelho. Falhas de execução/validação do optimize não são reclassificadas como
`safe_no_change`; somente rejeições de qualidade explicitamente reconhecidas
podem usar esse terminal.

Os antigos comandos `audit_resolution_corpus.dart`,
`add_resolution_corpus_entry.dart` e `bootstrap_resolution_corpus_decks.dart`
não existem no repositório corrente e não fazem parte deste workflow.

## Contrato do E2E mutável isolado

O gate recorrente sempre executa primeiro o preflight read-only. A etapa mutável
continua bloqueada sem aprovação PostgreSQL explícita e, quando aprovada:

- inicia uma API própria em loopback e em uma porta livre; `API_BASE_URL`
  externo ou reutilizado não é aceito;
- usa identidade, senha, JWT e diretório de artefatos exclusivos por execução;
- grava os artefatos em `/tmp/manaloom_resolution_corpus/<run-token>` por
  padrão;
- encerra a API e remove somente a identidade descartável exata; decks e
  preferências vinculados devem desaparecer no mesmo ciclo de cleanup;
- falha se encontrar resíduo da identidade ou dos decks temporários.

O artefato `mutation_audit.json` mede o delta de contagem e linhas com
`created_at` dentro da janela. Ele não detecta todo `UPDATE`/`ON CONFLICT` em
linha preexistente sem sinal `updated_at`, nem atribui escritores concorrentes
em banco compartilhado. Portanto essa auditoria prova ausência de inserções e
variação visíveis no escopo medido, não ausência absoluta de toda atualização.

Para escolher outra porta inicial, use `PORT`. Não configure `API_BASE_URL` no
gate mutável, pois o processo deve possuir e validar a instância local usada.

## Critério de fechamento

O corpus só pode ser apresentado como cobertura de resolução quando:

- cada entrada tiver artefato não mock do contrato corrente;
- cada entrada tiver origem runtime conhecida, sem atribuir execução
  determinística ou cache ao provedor;
- houver ao menos uma otimização direta com pares acionáveis, PUT 200 e
  assinatura persistida confirmada;
- o run completo passar sem `failed`, `unresolved` ou resíduo mutável;
- mudanças posteriores de dados, provedor ou contrato causarem nova execução,
  sem congelar como verdade um flow estocástico observado no passado.

Até lá, o resultado correto é: corpus estrutural/representativo verde no
preflight e cobertura real de flow pendente.

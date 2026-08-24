# BrewTact — contrato de execução task a task

Status: `CURRENT_CONTRACT · WIP_LIMIT_1 · NO_LIVE_MUTATION_AUTHORITY`

Este contrato transforma o backlog mestre em trabalho executável sem criar uma
segunda fonte de verdade. Uma task é um ID já existente no backlog; a fila e a
ficha apenas coordenam e registram sua execução.

## 1. Autoridade e precedência

1. `docs/status/CURRENT_PRODUCT_DECISION.md` decide produto, oferta e escopo de
   release.
2. `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` é a única autoridade
   manual de ID, prioridade, estado, dependências, entrega e aceite.
3. `docs/generated/TASK_REGISTRY.json` é a projeção machine-readable gerada do
   backlog. Nunca deve ser editada manualmente.
4. `docs/execution/CURRENT_QUEUE.md` coordena a ordem de trabalho com WIP 1. Não
   pode mudar prioridade, estado, dependência ou aceite.
5. `docs/execution/tasks/*.md` registra uma execução concreta. A ficha é um
   ledger manual, não um receipt machine-validated.
6. Receipts revisados e duráveis ficam em `docs/qa/execution/`; evidência
   transitória permanece em `/tmp` e não recebe crédito de release.

Nenhum documento, fila, ficha ou receipt autoriza deploy, migration live,
escrita em PostgreSQL live, chamada mutante a API live ou promoção de learning.

## 2. Estrutura

```text
docs/execution/
├── README.md
├── CURRENT_QUEUE.md
├── TASK_PACKET_TEMPLATE.md
├── waves/
│   ├── 00-truth-and-evidence.md
│   ├── 01-platform-safety.md
│   ├── 02-deck-foundation.md
│   ├── 03-analyze-optimize.md
│   ├── 04-generate-rebuild.md
│   ├── 05-learning.md
│   ├── 06-battle-independent.md
│   └── 07-beta-release.md
└── tasks/
    └── <TASK-ID>.md
```

Os pacotes de onda explicam o resultado e o fechamento específico de cada ID
da sequência aprovada. A ficha individual só é criada quando o ID vai entrar no
slot `NOW`; assim, não surgem 217 cópias que envelhecem fora do backlog.

## 3. Regra de WIP 1

- Há exatamente uma task `NOW` no programa principal.
- Battle é independente em arquitetura, capacidade e release, mas não cria uma
  segunda task `NOW` no mesmo checkout.
- Agentes podem auditar ou testar partes independentes da mesma task em
  paralelo; não podem implementar IDs diferentes ao mesmo tempo.
- O limite operacional desta rodada é de no máximo 15 subagentes.
- Um ID só entra em `NOW` depois de todas as dependências canônicas estarem
  fechadas ou de o trabalho ser explicitamente apenas contenção fail-closed.
- A fila declara `Exceção de contenção fail-closed do NOW: none` quando todas
  as dependências estão `PASS`. Uma exceção usa o próprio Task ID, exige motivo
  explícito e só é válida para estado canônico `IN_PROGRESS_CONTAINED`.
- Se a task bloquear, sua ficha registra o bloqueio e a prova. Ela sai de
  `NOW`; a próxima task elegível só entra depois de a fila ser atualizada.
- `SKIP`, `PARTIAL`, teste focal, checkout sujo ou capability `OFF` nunca são
  convertidos em `PASS`.

Os rótulos `NOW`, `NEXT`, `PARKED`, `WAITING_EXTERNAL` e
`WAITING_AUTHORIZATION` são somente coordenação. Eles não substituem os estados
canônicos do backlog.

## 4. Ciclo obrigatório de uma task

### 4.1 Selecionar

1. Resolver o ID em `docs/generated/TASK_REGISTRY.json`.
2. Confirmar que ele aparece uma única vez, que suas dependências resolvem e
   que o estado permite a ação pretendida.
3. Ler a decisão corrente, o contrato da área e
   `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.
4. Para UI, ler também `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`.
5. Para Deck/IA/Learning, ler o fluxo corrente e o contrato Commander.

### 4.2 Abrir a ficha

Copiar `TASK_PACKET_TEMPLATE.md` para `docs/execution/tasks/<TASK-ID>.md` e
preencher:

- SHA inicial, branch, hash do backlog/registry e digest de project logic;
- resultado desta execução e limites explícitos;
- contratos, superfícies, dados, riscos e capabilities afetadas;
- baseline reproduzível;
- plano de testes, observabilidade, rollback e receipts;
- autorização máxima permitida para a execução.

Prioridade, estado, dependências, entrega e aceite não são reescritos na ficha.
Eles são resolvidos pelo ID; uma eventual visualização é rotulada como snapshot
não autoritativo.

### 4.3 Baseline antes de editar

- confirmar `git status`, HEAD, upstream e alterações preexistentes;
- executar o menor teste capaz de reproduzir o gap;
- registrar tabelas, rotas, consumers e receipts aplicáveis;
- verificar `semantic_analysis` e `lineage` antes de alterar fonte;
- classificar dado live, fixture, cache ou laboratório;
- definir rollback antes da primeira alteração.

### 4.4 Implementar atomicamente

- alterar somente fontes; gerados são produzidos por suas ferramentas;
- DDL de produto existe somente em migration versionada;
- preservar alterações alheias do worktree;
- manter capabilities default-deny durante todo o trabalho;
- não misturar refactor sem relação, limpeza oportunista ou outra task;
- preferir um commit por task; acoplamentos inseparáveis devem ser justificados
  na ficha e auditados como uma unidade.

### 4.5 Provar por camadas

1. testes focais positivos e negativos;
2. concorrência, retry, idempotência e failure injection quando aplicáveis;
3. análise e contratos da superfície;
4. PostgreSQL loopback descartável quando houver persistência ou schema;
5. integração producer → storage → API → consumer;
6. app/runtime/UI quando houver superfície humana;
7. gates agregados aplicáveis;
8. receipts ligados à mesma SHA e ao mesmo digest;
9. auditoria independente do diff/índice para mudanças P0 ou de release.

### 4.6 Fechar

Uma task só fecha quando:

1. cada cláusula do aceite canônico aponta para evidência específica;
2. código, contrato, API map, migration e consumer concordam;
3. fonte inicial/final é estável e os receipts usam a mesma revisão;
4. nenhum gate aplicável terminou `SKIP`, `PARTIAL`, `BLOCKED` ou `FAIL`;
5. UI aplicável possui os três níveis de prova no mesmo digest;
6. rollback, cleanup, observabilidade e riscos residuais foram verificados;
7. `project_logic --write` e `--check` passaram quando o lineage mudou;
8. secret scan e `diff --check` passaram;
9. um revisor independente deu `GO` para o escopo de alto risco;
10. o backlog mestre foi atualizado com o link do receipt/commit e o registry
    foi regenerado.

Depois disso, a ficha recebe o veredito da execução, sai da fila e pode ser
arquivada. Somente a linha do backlog recebe o estado canônico `PASS`.

## 5. Fronteiras de dados e IA

- PostgreSQL/backend é a verdade de produto.
- Hermes/SQLite é cache, laboratório ou evidência; nunca encerra uma task de
  produto sozinho.
- Identidade jogável usa `oracle_id`; identidade física usa printing/card ID.
- Consultas de carta devem preferir `card_intelligence_snapshot` ou serviço
  canônico equivalente e evitar fan-out cru de efeitos, roles e rulings.
- Optimize é advisory até apply explícito, revalidado e receipt atômico.
- Generate/Rebuild não materializa lista injetada pelo cliente.
- Telemetria, contribuição, candidato e promoção de learned deck são estados
  separados. Nenhum deles implica o seguinte.
- Preview, cache, fallback ou mock não é receipt de aplicação nem autorização
  de learning.

## 6. Classes de fechamento ponta a ponta

Toda ficha declara as classes aplicáveis.

| Classe | Prova mínima |
| --- | --- |
| `LOCAL_CODE` | foco positivo/negativo, analyzer, contratos, full aplicável, diff e secrets |
| `DISPOSABLE_PG` | cluster loopback novo, migrations, DDL/FK/views, integração e cleanup |
| `DECK_MUTATION` | owner, expected revision, atomicidade, ledger, retry, conflito, undo e receipt |
| `AI_ADVISORY` | provenance, input/fingerprint, policy, timeout, fallback rotulado, cache e ausência de apply implícito |
| `LEARNING` | consentimento/finalidade, state machine, idempotência, revoke/delete, promoção humana e receipt |
| `UI_RUNTIME` | `PASS_AUTOMATED`, `PASS_RUNTIME`, todas as capturas abertas e `PASS_VISUAL_REVIEWED` no mesmo digest |
| `RELEASE_READ_ONLY` | branch remota, SHA, policy digest, `/health`, `/ready`, `/capabilities` e schema coerentes |
| `LIVE_MUTATING` | autorização textual separada, preflight, backup/rollback, janela, cleanup e receipt pós-mudança |

Uma task local pode terminar `PASS` sem deploy quando o aceite não exige live.
Uma task de release não pode. “Código concluído; release pendente” é um estado
honesto e diferente de produção concluída.

## 7. Matriz mínima de gates

Base para qualquer alteração de fonte:

```bash
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
./scripts/manaloom_secret_scan.sh --worktree
git diff --check
```

Fechamento local amplo, quando aplicável:

```bash
MANALOOM_NODE_BIN=/opt/homebrew/bin/node ./scripts/manaloom_local_ci.sh full
./scripts/manaloom_local_ci.sh schema
./scripts/manaloom_local_ci.sh e2e
```

Gates especializados ainda explicitamente separados:

```bash
./scripts/quality_gate.sh deck-ai-learning local
./scripts/quality_gate.sh engine-capabilities
(cd web-public && npm run test:contract)
PYTHONDONTWRITEBYTECODE=1 python3 server/test/manaloom_ops_daemon_test.py
./scripts/manaloom_release_ops_contract_test.sh
```

Selecionar apenas o conjunto aplicável e registrar qualquer sobreposição. O
aggregate estrito tem precedência sobre execuções diagnósticas. Para release de
Deck/IA/Learning, `PASS_CODE_ONLY` precisa do receipt PostgreSQL read-only
durável; ele não é `PASS` de release.

## 8. UI e evidência física

Mudança app-facing invalida evidência do digest anterior. Captura só ocorre
quando a superfície da onda estiver estável, para evitar promover uma matriz
que a próxima task invalidará. Android físico não pode ser substituído por
emulador.

TalkBack humano e teclado Web real são verificações separadas mesmo com o gate
visual verde. Captura sem abertura e revisão de todos os PNGs não recebe
`PASS_VISUAL_REVIEWED`.

## 9. Git, auditoria e publicação

Antes de commit:

1. worktree e índice representam somente a task e seus gerados legítimos;
2. `git diff --cached --check` passa;
3. scan de segredos passa no conteúdo a publicar;
4. auditor independente revisa atomicidade, removidos, binários e receipts;
5. o commit inclui o ID da task no corpo ou no receipt associado.

Push publica a branch; não autoriza deploy. A validação pública pós-push é
read-only. Se o servidor estiver em SHA anterior, registrar os dois SHAs e
`SERVER_BEHIND`; publicar a nova SHA exige autorização separada.

## 10. Handoff obrigatório

O fechamento entregue ao usuário deve conter:

- resultado primeiro;
- ID e commit/digest;
- mudanças por superfície;
- gates e receipts com status real;
- UI/runtime/live executados ou explicitamente pendentes;
- riscos residuais e rollback;
- estado canônico atualizado ou motivo de não atualização;
- próximo ID elegível da fila.

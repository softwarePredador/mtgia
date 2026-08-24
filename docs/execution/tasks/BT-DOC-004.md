# Ficha de execução — `BT-DOC-004`

> Ledger de execução não autoritativo. ID, prioridade, estado, dependências,
> entrega e aceite continuam resolvidos no backlog mestre/registry.

## Autoridade

- Task ID: `BT-DOC-004`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `2`
- Registry `generated_from.sha256`:
  `5109f0e0e5585c2c6ce3655514d2f8a5f38331105f6a6471ee9069e520d25864`
- Project logic source digest inicial:
  `c1ddf67874b4861c9736cd64c5519887a3e59106e9658f12276a6905d9387a96`
- Linha canônica: `227`
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`

## Identidade da execução

- Owner: `/root`
- Início UTC: `2026-08-24T19:43:25Z`
- Fim UTC: `pending`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA inicial: `c1bd186633a479f62eae0ba4db6eb29463e94419`
- Git SHA anterior ao commit de abertura:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Git SHA final: `pending`
- Worktree digest inicial:
  `ee254fdbc66babfe86ddd041b8a28e3c458e5c13a536e0599d88d55b2b4f08a7`
  (`manaloom-worktree-v2`, checkout limpo)
- Worktree digest final: `pending`
- Fonte estável: `true` na abertura; verificação final pendente
- Classe de fechamento: `LOCAL_CODE`
- Autorização máxima: código/documentação local, commits e push da branch;
  nenhum PR/merge, deploy, migration live, escrita live, capability, pin, regra
  ou deck

## Resultado desta execução

### Dentro do escopo

- Fortalecer o parser backlog → registry e seus negativos determinísticos.
- Tornar WIP 1 e o vínculo `NOW → task packet` verificáveis por máquina.
- Explicitar lifecycle não autoritativo da fila e das fichas.
- Tornar honesta a granularidade de rotas, producers e consumers.
- Vincular especificamente o receipt do manifesto ao source digest.
- Regenerar os nove artefatos e emitir receipt durável da task.

### Fora do escopo

- Inferir o call graph completo por entrypoint; isso permanece em
  `BT-GATE-005`/`BT-AI-029`.
- Exigir receipt forte de todos os fluxos; isso permanece em `BT-GATE-002`.
- Alterar feature, PostgreSQL, Hermes/SQLite, runtime, capability, XMage/Forge,
  pin, deck, regra, PR, merge ou deploy.

### Capabilities

- Antes: matriz server-authoritative permanece no estado atual, sem promoção.
- Depois pretendido: nenhuma capability muda.
- Evidência default-deny: diff restrito a documentação/tooling/testes/gerados;
  nenhum código de produto ou persistência no escopo.

## Critérios de entrada

- Dependência: `BT-DOC-001=PASS`, receipt
  `docs/qa/execution/2026-08-24/BT-DOC-001.md`.
- Baseline reproduzível: project logic `1.4.0`, 23/23 testes, nove gerados sem
  drift, 217 tasks e 393 arestas.
- Contratos: `AGENTS.md`, `docs/execution/README.md`,
  `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` e
  `docs/project_logic_contracts.json`.
- Superfícies: backlog, fila/ficha, lifecycle, route registry, receipt registry,
  generator e testes; zero tabela/rota/runtime alterado.
- Riscos: falso positivo de placeholder; ficha virar segunda autoridade;
  consumer por fluxo ser apresentado como consumer por rota; autorreferência
  entre ficha e digest.
- Rollback planejado: reverter o commit focal, regenerar os nove artefatos e
  repetir o gate `project-logic`; não existe estado live para restaurar.

## Plano de implementação

1. Rejeitar placeholders e definições inequívocas fora da tabela.
2. Validar WIP 1, ID canônico, caminho e identidade/autorização da ficha `NOW`.
3. Explicitar fichas como supporting ledger sem autoridade.
4. Renomear os campos compartilhados por fluxo para
   `flow_producers`/`flow_consumers` e publicar sua granularidade.
5. Exigir `source_digest_sha256` em `project_logic_manifest_v1`.
6. Cobrir positivos, negativos, ordenação determinística e digest.

### Fontes previstas

- `tools/project_logic/lib/project_logic_generator.dart`
- `tools/project_logic/test/project_logic_generator_test.dart`
- `docs/project_logic_contracts.json`
- `docs/execution/CURRENT_QUEUE.md`
- `docs/execution/README.md`
- `tools/project_logic/README.md`
- esta ficha e o receipt final

### Gerados derivados esperados

- os nove caminhos declarados em `ProjectLogicGenerator.outputPaths`

### Migration/DDL

- Não aplicável; zero DDL e zero conexão PostgreSQL.

## Plano de prova

### Funcional

- Positivo: registry atual, WIP 1, ficha correspondente, lifecycle, rotas,
  consumers, receipts e source digest.
- Negativo: ID duplicado/inválido; dependência ausente/duplicada/própria;
  ciclo; placeholder; definição fora da tabela; zero/dois `NOW`; WIP diferente
  de 1; packet ausente/divergente; histórico ativo; rota ausente; receipt sem
  binding e receipt do manifesto sem source digest.
- Concorrência: não aplicável; parser/generator local determinístico.
- Retry/idempotência: duas projeções da mesma fixture devem ser idênticas.
- Failure injection: fixtures inválidas acima devem falhar fechado.

### Integração ponta a ponta

- Producer → storage → API → consumer: não aplicável; nenhuma jornada de
  produto foi alterada. A prova é backlog → parser → registry → gerados.
- Isolamento A/B: não aplicável; nenhum dado de usuário.
- Cleanup/rollback: somente arquivos versionados e artefatos temporários dos
  gates.

### UI/runtime

- `PASS_AUTOMATED`: não aplicável a UI; testes do generator são obrigatórios.
- `PASS_RUNTIME`: não aplicável; nenhum app-facing change.
- `PASS_VISUAL_REVIEWED`: não aplicável; nenhuma captura nova recebe crédito.
- TalkBack/teclado/permissões: não aplicável.

### Observabilidade

- Eventos/métricas/logs: não aplicável a runtime.
- SLO/alerta/runbook: não aplicável.
- Redação/PII: manifesto não captura valor de ambiente, credencial ou DSN.

## Gates executados

| Gate | Comando | Esperado | Real | Exit | SHA | Artefato/hash |
| --- | --- | --- | --- | ---: | --- | --- |
| Focal inicial | `dart test test/project_logic_generator_test.dart` | negativos verdes; drift antes de regenerar | 26 testes funcionais verdes; único erro foi drift esperado de quatro gerados | `1` | worktree | saída local |
| Project logic intermediário | `./scripts/quality_gate.sh project-logic` | negativos verdes | `???`/`...` expuseram regressão na normalização; 26/27 | `1` | worktree | corrigido antes do commit |
| Project logic final | `./scripts/quality_gate.sh project-logic` | `PASS` | 27/27 testes, 9 artefatos sincronizados e `dart doc` limpo em 4 módulos | `0` | worktree | source digest `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0` |
| Secret scan | `./scripts/manaloom_secret_scan.sh --worktree` | `PASS` | zero credencial live literal; gitleaks `8.30.1` | `0` | worktree | saída local |
| Estrutura | `git diff --check` | `PASS` | sem erro | `0` | worktree | saída local |
| Retenção | `./scripts/manaloom_report_retention_audit.sh` | `PASS` | 17/17 testes | `0` | worktree | JSON `3bd0d2be6e731560bb63463bdcfd0477b8c40dc03b5e2bb658d7358b9d92edf6`; Markdown `ea9ba8570182d45e7224924989cdf68a4f265b2b40ab479eaa8b0a66eccc05b4` |

## Receipts

| Contrato | Producer | Status | Path/hash | Durável | Bindings revisados |
| --- | --- | --- | --- | --- | --- |
| `project_logic_manifest_v1` | `scripts/manaloom_project_logic.sh` | pass | `project_logic_manifest.json`; SHA-256 `624610e83e30d2011e20311fccc32dfee95be981a376874d8f14899a12668f9b` | yes | `source_digest_sha256=bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0` |
| `BT-DOC-004` | `/root` | pending | `docs/qa/execution/2026-08-24/BT-DOC-004.md` | yes | pending |

## Aceite canônico

| Cláusula resolvida do registry | Evidência |
| --- | --- |
| IDs únicos e dependências resolvidas | parser, DAG, negativos focais e gate `PASS`/contenção estruturada do `NOW` |
| Nenhum placeholder | detector em delivery/acceptance e corpus negativo |
| Ciclo detectado | ordenação topológica e fixture cíclica |
| Histórico não entra como fonte ativa | lifecycle, banners e negativo de autoridade histórica |
| Receipt vinculado ao digest | `project_logic_manifest_v1.source_digest_sha256` e receipt final |

## Fechamento

- Resultado E2E estrito: `n/a` para mudança local de tooling documental
- Gate-eligible: `false` até gates, commit e auditoria finais
- Release identity: `n/a`; nenhuma release executada
- Bloqueios: nenhum conhecido; fechamento pendente
- Riscos residuais: traceability completa e receipts fortes dos demais fluxos
  permanecem em suas tasks canônicas
- Rollback verificado: `pending`
- Auditor independente: `GO` final após resolver os quatro gaps e os achados
  adicionais de schema, scripts e normalização
- Veredito da execução: `pending`
- Commit que atualiza o estado canônico: `pending`
- Próximo ID elegível: `BT-SCP-001`, condicionado ao fechamento desta task

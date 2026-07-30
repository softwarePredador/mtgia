# Evidência de resiliência S8/BL10 — complemento de 2026-07-29

**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**Base observada:** `58c161bc4`
**Classificação:** `PASS_LOCAL_PRE_HOMOLOGATION / RELEASE_NO_GO`

## Resultado

Este complemento fecha duas lacunas locais sem atribuir crédito de ambiente
publicado:

1. S8-04 agora possui uma matriz controlada de falhas do provedor para 429,
   5xx, queda de conexão, timeout e cancelamento. Todos os retornos públicos
   impedem salvar/aprender, não entram em cache e não expõem o detalhe privado
   da dependência.
2. BL10-03 agora possui carga integrada sobre rota, PostgreSQL descartável e
   lane batch: 24 jobs concorrentes, consultas sob carga, execução batch e
   cancelamento/limpeza com budgets explícitos.

O estado de release permanece `NO_GO`: as duas provas são locais e não
substituem carga, telemetria nem smoke da mesma SHA no ambiente alvo.

## Contrato de falha S8-04

Arquivos exercitados:

- `server/lib/ai_provider_runtime_support.dart`;
- `server/routes/ai/generate/index.dart`;
- `server/test/ai_provider_runtime_support_test.dart`;
- `server/test/ai_generate_provider_failure_matrix_e2e_test.dart`;
- `scripts/quality_gate.sh`.

Contrato público uniforme:

- `Cache-Control: no-store`;
- `generated_deck: null`;
- `can_save: false`;
- `learning_eligible: false`;
- erro sanitizado, sem corpo, host, trace ou identificador privado do provedor;
- timeout, 429, 5xx e transporte comunicam possibilidade de nova tentativa;
- rejeição não transitória não é marcada como repetível;
- cancelamento continua distinguível de indisponibilidade.

A matriz usa um servidor HTTP exclusivamente loopback e prova o transporte
real do cliente, inclusive fechamento físico do peer em timeout/cancelamento.
Ela também prova os builders públicos e verifica estaticamente os pontos de
ligação usados pela rota. Ela **não** invoca o `onRequest` publicado, não chama
um provedor externo e não atravessa auth/middleware/PostgreSQL.

Medição observada no gate `performance`:

| Cenário | Tempo |
|---|---:|
| HTTP 429 | 42 ms |
| HTTP 5xx | 1 ms |
| queda de conexão | 4 ms |
| timeout com abort físico | 153 ms |
| cancelamento com abort físico | 2 ms |

Todos ficaram abaixo do limite local de 2.000 ms.

## Carga integrada BL10-03

Arquivos exercitados:

- `server/test/battle_job_integrated_load_live_test.dart`;
- `scripts/manaloom_tbls_local_gate.sh`;
- `server/test/battle_lab_gate_contract_test.dart`.

O gate cria um PostgreSQL descartável em `/tmp`, aplica as 56 migrations e
executa 24 jobs concorrentes distribuídos por oito owners. O teste combina
criação/listagem/cancelamento pelas funções reais das rotas, consultas reais no
PostgreSQL e execução da lane batch através do runtime, com adapter nativo
determinístico.

Medição observada:

| Medida carregada | Resultado | Budget |
|---|---:|---:|
| criação p95 | 188 ms | 5.000 ms |
| listagem p95 | 34 ms | 1.000 ms |
| PostgreSQL p95 | 35 ms | 500 ms |
| batch p95 | 9 ms | 500 ms |
| cancelamento p95 | 47 ms | 1.000 ms |
| agregado | 196 ms | 15.000 ms |
| delta RSS | 10.928.128 bytes | 134.217.728 bytes |
| jobs ativos após limpeza | 0 | 0 |

O schema também permaneceu alinhado ao manifesto: 79 tabelas, 6 views, 98
foreign keys e 56 migrations.

Esta prova é pré-homologação: não inclui socket HTTP/middleware real, sidecars
publicados, perfil de CPU/RSS do alvo ou deployment da mesma SHA.

## Execuções

| Execução | Resultado |
|---|---|
| análise Dart completa do servidor | `PASS`, sem issues |
| contrato/provider/timeout/abort/Battle gate | `PASS`, 16 testes |
| família completa `ai_generate*` + runtime provider | `PASS`, 51 testes |
| `./scripts/quality_gate.sh performance` | `PASS` |
| harness Python de performance | `PASS`, 17 testes |
| carga sintética server + homologação Flutter | `PASS`, 2 + 3 testes |
| `./scripts/manaloom_tbls_local_gate.sh` | `PASS` |
| sintaxe dos dois scripts alterados | `PASS` |
| teste de carga fora do gate | `SKIP_EXPECTED`, exige DB descartável |

## Pendências que continuam abertas

- repetir desempenho inicial Web e Android no artefato final da mesma SHA;
- repetir memória/imagens Web no artefato final;
- executar fault matrix contra o serviço externo de homologação, com
  observabilidade e alertas verificados;
- comprovar carga integrada em infraestrutura alvo, incluindo HTTP,
  PostgreSQL e sidecars publicados;
- correlacionar resultados com Sentry/alertas e smoke pós-deploy da mesma SHA;
- concluir as provas físicas ainda abertas de FCM, backup/restore, TalkBack e
  ciclo background/foreground.

Nenhuma migration, deploy, escrita live ou promoção de release foi realizada
por esta evidência.

# Homologação local Battle BL4/BL6 — 2026-07-26

- Resultado: `PASS_LOCAL_PREFLIGHT_BLOCKED_PHYSICAL_AND_LIVE`
- SHA no início da rodada:
  `e64800eab41c3e87ee20a2a2377fa5e519d63fab`
- Árvore: worktree compartilhado com alterações não commitadas de outras
  frentes; os números abaixo provam a árvore local executada, não o SHA
  isoladamente.
- Escritas live: nenhuma.
- Android físico/TalkBack: não executados e permanecem `BLOCKED`.

## Ambiente observado

| Campo | Fato desta rodada |
|---|---|
| Host | macOS 26.2 `25C56`, arm64 |
| Flutter | 3.44.6, framework `ee80f08bbf` |
| Dart | 3.12.2 |
| Chrome | 150.0.7871.184 |
| `adb devices -l` | lista vazia |
| Flutter devices usados | host VM e Chrome |
| Dispositivo pessoal detectado | iPad iOS 18.4.1, `NOT_USED` |
| DTD/runtime ativo na inspeção MCP | nenhum |

O inventário Flutter também listou macOS. Não havia Android físico nem
emulador Android; dispositivos iOS pessoais não foram usados como substituto.

## Resultado BL4-03

O arquivo
`app/test/features/battle/battle_local_homologation_test.dart` executa sete
amostras após aquecimento e falha se p95 exceder o orçamento.

### Flutter test host VM

| Operação | p50 | p95 | Orçamento p95 | Estado |
|---|---:|---:|---:|---|
| histórico, 100 itens | 1.593 µs | 3.841 µs | 250 ms | `PASS_LOCAL_PREFLIGHT` |
| detalhe, 20.000 eventos | 20.117 µs | 31.250 µs | 2.500 ms | `PASS_LOCAL_PREFLIGHT` |
| scrub scan, 20.000 | 40 µs | 1.251 µs | 100 ms | `PASS_LOCAL_PREFLIGHT` |
| filtro, 20.000 | 260 µs | 710 µs | 400 ms | `PASS_LOCAL_PREFLIGHT` |
| série, 10 reports | 0 µs | 2 µs | 100 ms | `PASS_LOCAL_PREFLIGHT` |

### Chrome Web test host

| Operação | p50 | p95 | Orçamento p95 | Estado |
|---|---:|---:|---:|---|
| histórico, 100 itens | 500 µs | 4.000 µs | 500 ms | `PASS_LOCAL_PREFLIGHT` |
| detalhe, 20.000 eventos | 38.299 µs | 60.101 µs | 5.000 ms | `PASS_LOCAL_PREFLIGHT` |
| scrub scan, 20.000 | 99 µs | 401 µs | 250 ms | `PASS_LOCAL_PREFLIGHT` |
| filtro, 20.000 | 901 µs | 1.300 µs | 800 ms | `PASS_LOCAL_PREFLIGHT` |
| série, 10 reports | 0 µs | 101 µs | 250 ms | `PASS_LOCAL_PREFLIGHT` |

Esses números são do test host, não frame timing de Android. A prova Android
continua bloqueada.

## Resultado BL4-05 e BL6-07

Três widget tests passaram em VM e Chrome:

- atraso determinístico de 300 ms e poll interval de 100 ms;
- no máximo um poll em voo;
- erro offline preserva registro e cursor;
- retry retoma do cursor anterior e deduplica o registro repetido;
- foco é movido para `Reconectar`;
- progress semantics expõe nome e valor;
- ação principal tem label semântico;
- ação de reconexão mantém tooltip e alvo mínimo de 48 px;
- teclado `Space` pausa a visualização;
- texto em 200%, viewport 390 × 844 e reduced motion não geram exceção.

Isso valida a árvore Semantics automatizada. Não valida a experiência real do
TalkBack.

## Resultado BL6-06

O arquivo
`server/test/battle_live_local_load_homologation_test.dart` exercitou um
histórico de 20.000 eventos e fanout sintético de 64 streams, com 200
eventos-fonte por stream e páginas públicas de até 100 itens.

| Medida | Resultado | Orçamento | Estado |
|---|---:|---:|---|
| deep p50 | 46.150 µs | informativo | `PASS_LOCAL_PREFLIGHT` |
| deep p95 | 92.654 µs | <= 5.000 ms | `PASS_LOCAL_PREFLIGHT` |
| stream p50 | 1.382 µs | informativo | `PASS_LOCAL_PREFLIGHT` |
| stream p95 | 2.185 µs | <= 750 ms | `PASS_LOCAL_PREFLIGHT` |
| fanout no host | 125 ms | <= 15.000 ms | `PASS_LOCAL_PREFLIGHT` |
| maior página | 51.085 bytes | <= 131.072 bytes | `PASS_LOCAL_PREFLIGHT` |
| payload agregado | 3.267.510 bytes | <= 8.388.608 bytes | `PASS_LOCAL_PREFLIGHT` |
| delta RSS | 55.377.920 bytes | <= 268.435.456 bytes | `PASS_LOCAL_PREFLIGHT` |

O teste é intencionalmente de um processo Dart. Sockets concorrentes reais,
CPU/RSS alvo e sidecar em produção permanecem `BLOCKED`.

## Segurança, reconexão e contratos

O conjunto focado do servidor passou 31 testes, cobrindo:

- allowlist pública e hidden zones;
- cursor HMAC adulterado/cross-stream;
- limites de página e payload;
- retomada após reinício e deduplicação;
- mudança de processo com uma reread limitada;
- 404 recuperável e 5xx sem terminal fabricado;
- auth/owner scope, IDOR e engine não suportado fail-closed;
- contrato da migration 055 e rota protegida/rate-limited.

## Comandos executados

| Comando resumido | Exit | Prova |
|---|---:|---|
| Flutter 3.44.6 `test ...battle_local_homologation_test.dart` | 0 | 3/3 |
| Flutter 3.44.6 `test --platform chrome ...` | 0 | 3/3 |
| Dart 3.12.2 `test` nos sete arquivos Battle Live focados | 0 | 31/31 |
| `./scripts/quality_gate.sh performance` | 0 | 17 Python + 1 servidor + 3 Flutter |
| `manaloom_tbls_local_gate.sh` em PostgreSQL loopback | 0 | 77 tabelas, 6 views, 91 FKs, 55 migrations e Battle jobs/Live |
| Dart MCP `analyze_files` nos novos testes/contrato do gate | 0 | sem erros |

O modo `performance` agora inclui os dois preflights Battle, além dos harnesses
runtime existentes.

## Provas ainda não concluídas nesta rodada

| Prova | Estado | Motivo/condição |
|---|---|---|
| PostgreSQL loopback owner/checkpoint/dedupe/cascade | `PASS_LOCAL` | cluster descartável criado, testado e removido nesta rodada |
| project logic `--write` e `--check` | `PASS_LOCAL` | 8 artefatos regenerados e sincronizados na árvore final |
| Android físico | `BLOCKED` | nenhum Android em `adb`/Flutter |
| TalkBack | `BLOCKED` | exige Android físico e roteiro manual |
| carga com sockets reais | `BLOCKED` | exige ambiente isolado |
| CPU/RSS do alvo | `BLOCKED` | exige profiler no alvo |
| migration/deploy/smoke live | `BLOCKED` | fora do escopo autorizado |
| release same-SHA | `BLOCKED` | sem build/deploy/health do mesmo SHA |

## Decisão por item

| Item | Estado desta rodada |
|---|---|
| BL4-03 | `PASS_LOCAL_PREFLIGHT`; Android target `BLOCKED` |
| BL4-05 | `PASS_LOCAL_AUTOMATED`; TalkBack/Android `BLOCKED` |
| BL4-06 | `PASS_LOCAL_AUTOMATED`, com Android/live/same-SHA ainda bloqueados |
| BL4-07 | `PASS_LOCAL_EVIDENCE`, sem evidência de release |
| BL6-06 | `PASS_LOCAL_PREFLIGHT`; carga/CPU/RSS alvo `BLOCKED` |
| BL6-07 | `PASS_LOCAL_AUTOMATED`; Android/live `BLOCKED` |

Decisão de release: `NO_GO` até fechar os bloqueios físicos, de alvo e
same-SHA. O preflight local pode ser usado como gate de regressão, não como
autorização de rollout.

# Template de homologação local — Battle BL4/BL6

Este registro serve para uma única árvore de código e uma única rodada. Ele
não transforma cobertura de host em prova de Android físico, TalkBack, carga
do alvo ou release live.

## 1. Identidade imutável da rodada

- data/hora e timezone:
- SHA auditado antes da rodada:
- branch:
- estado do worktree (`clean` ou lista de arquivos):
- SHA final, se existir:
- executor:

Se o worktree não estiver limpo, o resultado é evidência da árvore local
descrita, e não do SHA isolado.

## 2. Ambiente

| Campo | Valor |
|---|---|
| Host/arquitetura | |
| Flutter/Dart exatos | |
| Chrome | |
| Dispositivos Flutter | |
| `adb devices -l` | |
| PostgreSQL | |
| Espaço livre antes/depois | |

Dispositivos pessoais detectados, mas fora do escopo, devem ser registrados
como `NOT_USED`, nunca como evidência executada.

## 3. Vocabulário de estado

| Estado | Significado |
|---|---|
| `PASS_LOCAL` | comando executado nesta árvore, exit 0 e assertivas verdes |
| `PASS_LOCAL_PREFLIGHT` | limite sintético/host atendido; não prova o alvo |
| `PARTIAL` | parte executada, com lacuna nomeada |
| `BLOCKED` | prova obrigatória não executável nesta rodada |
| `FAIL` | comando ou orçamento falhou |
| `NOT_RUN` | não executado; não equivale a PASS |

## 4. Orçamentos locais obrigatórios

### BL4-03 — replay

Cada operação usa sete amostras após um aquecimento e publica p50/p95:

| Operação | Fixture | VM p95 | Chrome p95 |
|---|---:|---:|---:|
| parse do histórico | 100 itens | <= 250 ms | <= 500 ms |
| parse do detalhe | 20.000 eventos | <= 2.500 ms | <= 5.000 ms |
| scan de scrub | 20.000 eventos | <= 100 ms | <= 250 ms |
| filtro | 20.000 eventos | <= 400 ms | <= 800 ms |
| resumo de série | 10 reports | <= 100 ms | <= 250 ms |

Esses limites são preflight de regressão do modelo/test host. Latência de
renderização em Android físico continua sendo uma prova separada.

### BL6-06 — Live sintético

| Dimensão | Limite |
|---|---:|
| histórico profundo | 20.000 eventos |
| streams sintéticos | 64 |
| eventos-fonte por stream | 200 |
| eventos por página pública | <= 100 |
| payload por página | <= 131.072 bytes |
| payload agregado do fanout | <= 8.388.608 bytes |
| preparação profunda p95 | <= 5.000 ms |
| página por stream p95 | <= 750 ms |
| fanout total no host | <= 15.000 ms |
| delta de RSS do processo de teste | <= 268.435.456 bytes |

O fanout roda em um único processo Dart e mede tempo de parede/RSS do host.
Não é prova de sockets reais, CPU/RSS do alvo nem sidecar em produção.

### BL6-07 — rede e retomada

- atraso sintético por resposta: 300 ms;
- polling: 100 ms;
- concorrência máxima de polls em voo: 1;
- cursor anterior preservado no erro;
- retry sem duplicação;
- estado recebido permanece visível;
- foco vai para a ação de reconexão.

## 5. Matriz de comandos

Registrar comando literal, exit code, contagem e linha JSON emitida:

| Escopo | Comando | Exit | Resultado |
|---|---|---:|---|
| VM Flutter | | | |
| Chrome Flutter | | | |
| servidor sintético | | | |
| segurança/reconexão | | | |
| gate performance | | | |
| PostgreSQL descartável | | | |
| project logic `--write` | | | |
| project logic `--check` | | | |

`SKIP`, ausência de dispositivo ou comando não iniciado devem aparecer como
tal, sem reutilizar contagens de outra rodada.

## 6. Acessibilidade BL4-05

Separar as evidências:

- automatizado: semantics labels/values, alvos, teclado, texto 200%,
  reduced motion e ausência de overflow;
- manual Web: navegação e leitura em Chrome;
- Android físico: viewport, teclado se aplicável e performance;
- TalkBack: ordem de foco, nomes, estados e ações anunciadas.

Teste de árvore Semantics não substitui TalkBack.

## 7. Segurança, persistência e limpeza

Registrar separadamente:

- auth e owner scope;
- IDOR;
- cursor adulterado/cross-stream;
- allowlist e hidden zones;
- retry/restart/dedupe;
- PostgreSQL loopback descartável;
- cascade/cleanup;
- confirmação de nenhum processo/cluster temporário restante.

## 8. Bloqueios obrigatórios

| Prova | Estado | Condição de desbloqueio |
|---|---|---|
| Android físico | `BLOCKED` até executar | aparelho Android compatível |
| TalkBack | `BLOCKED` até executar | aparelho + roteiro manual |
| carga real/sockets | `BLOCKED` até executar | ambiente isolado e observável |
| CPU/RSS alvo | `BLOCKED` até executar | profiler no alvo |
| migration/deploy live | `BLOCKED` sem autorização | autorização e alvo explícitos |
| same-SHA release | `BLOCKED` até publicar | build/deploy/health do mesmo SHA |

## 9. Decisão

- BL4-03:
- BL4-05:
- BL4-06:
- BL4-07:
- BL6-06:
- BL6-07:
- release: `GO` ou `NO_GO`, com motivo:

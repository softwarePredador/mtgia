# Evidências da Sprint 9 — Consolidação e retenção

Data: 2026-07-23
Branch: `codex/free-beta-release-candidate-2026-07-17`
Commit de implementação validado/publicado:
`2139ec9f6f902a8b266fbb852db6e834b25bceff`
Base limpa da disposição residual:
`9deb607e4c09f8d8e6cd94241a61f2960262c6fe`

Esta evidência identifica o commit atômico de implementação e retenção
publicado na branch. Ela não autoriza remoção remota de histórico, promoção,
deploy, migration ou escrita live.

## Resultado atual

Resultado da sprint: `IMPLEMENTED_UNPROVEN`

O auditor de retenção foi ampliado de 5 para 12 checks e agora valida
inventário, hashes, recuperação, referências, índices, conteúdo canônico e
arquivos locais pendentes. A suíte possui 17 testes e passou integralmente.

```text
./scripts/quality_gate.sh report-retention
  testes                         17/17 PASS
  checks do auditor              12/12 PASS
  fontes brutas rastreadas       942
  active_consumer                657
  manifest_only                  285
  não governadas                 0
  grupos/arquivos canônicos      23/23
  originais removidos/reponíveis 473/473
  bytes recuperados              3.474.857
  grandes arquivados/reponíveis  6/6
  bytes arquivados               223.542.888
  referências verificadas        7.378
  referências inválidas          0
  duplicatas exatas residuais    0
  resíduos ignorados             0
```

Também passaram:

```text
./scripts/quality_gate.sh deps          4 pacotes, PASS
./scripts/quality_gate.sh server-target PASS
./scripts/manaloom_secret_scan.sh --worktree
                                         0 credenciais live literais, PASS
./scripts/manaloom_project_logic.sh --check
                                         8 artefatos sincronizados, PASS
./scripts/manaloom_local_ci.sh full       PASS
./scripts/quality_gate.sh e2e             PARTIAL esperado: 10 PASS,
                                         9 skips guardados, 0 FAIL/BLOCKED
```

O `pre-push` repetiu `manaloom_local_ci.sh full` sobre `2139ec9f6`, incluindo
backend 1736/1736, Flutter 1157 + 1 skip Web-only conhecido, Web pública,
UI audit, custom lint, Patrol 9/9, dependências e schema PostgreSQL loopback
com 73 tabelas, 6 views, 76 FKs e 51 migrations. Ao fim, local e remoto
apontavam para o mesmo SHA e o checkout estava limpo.

Foram corrigidos o link PG848, referências residuais PG499/PG578, repetição no
índice de reports e a distinção entre o contrato XMage histórico de junho e o
contrato corrente.

## Disposição S9-03 dos contratos gigantes

Os três entrypoints que ainda misturavam norma corrente e diário histórico
receberam disposição explícita. Os bytes anteriores foram preservados sem
alteração em `docs/hermes-analysis/archive/`, com tamanho e SHA-256 selados no
índice desse diretório:

```text
entrypoints antes             26.263 linhas / 1.584.706 bytes
entrypoints compactos            496 linhas /    19.840 bytes
snapshots históricos          26.263 linhas / 1.584.706 bytes
```

- `README.md`: 1.640 → 134 linhas;
- `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`: 3.904 → 283 linhas;
- `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`: 20.719 → 79 linhas.

Os entrypoints compactos retêm somente regra vigente, limites de autoridade,
handoff e links para evidência. Os snapshots são `historical_evidence_archive`
e não viram input de runtime, fonte de produto, autorização de PostgreSQL,
promoção ou deploy. O auditor de retenção inclui os três snapshots no conjunto
de referências ativas para preservar a recuperação dos links históricos.

Passaram as regressões de superfície Commander, ponte app/IA, alinhamento
operacional, estratégia XMage, retenção e seus testes. Os demais Markdown
acima de 100 KiB foram classificados como registros correntes, checkpoints
históricos ou background técnico; nenhum deles continua sendo um entrypoint
canônico que acumula diário e norma. S9-03 está concluída localmente, sem
deleção de evidência.

## Atomicidade e recuperação

- recovery commit registrado:
  `4700fc38317aae0d3c1955176b32c18ac3b34339`;
- commit atômico de implementação:
  `2139ec9f6f902a8b266fbb852db6e834b25bceff`;
- manifesto:
  `docs/hermes-analysis/DEDUPLICATED_REPORTS_2026-07-23.json`;
- índice de grandes artefatos:
  `docs/hermes-analysis/ARCHIVED_LARGE_ARTIFACTS.md`;
- conteúdos preservados:
  `docs/hermes-analysis/deduplicated-report-content/`.

Os dois índices, os 23 conteúdos canônicos, as referências corrigidas e as
deleções foram incorporados no mesmo commit. O diff registrou 630 paths
(`54` adicionados, `117` modificados e `482` removidos); o auditor confirmou
os hashes, a recuperação de 473/473 originais e 6/6 artefatos grandes, além de
7.378 referências válidas e zero referência inválida.

## Pendências por task

- S9-01: inventário, owner/retenção, recuperação e commit atômico estão
  comprovados; o estado permanece `IMPLEMENTED_UNPROVEN` porque S8 continua
  aberta;
- S9-02: contexto corrente, project logic e auditoria final de 7.378 links
  estão sincronizados; permanece dependente de S9-01;
- S9-03: os três contratos gigantes receberam entrypoints compactos e
  snapshots byte-identical selados; regressões canônicas e retenção estão
  verdes; permanece `IMPLEMENTED_UNPROVEN` apenas pela dependência S9-01;
- S9-04: consumidores de rota/import, gates focados e agregados locais passaram
  depois da regeneração e foram repetidos na identidade limpa; permanece
  dependente de S9-01;
- S9-05: duplicatas, artefatos governados e atomicidade estão verdes e
  rastreados; permanece dependente de S9-01;
- S9-06: secret scan, project logic, links, diff congelado e gate local
  completo passaram; o fechamento aguarda somente a cadeia de dependências.

# Evidências da Sprint 9 — Consolidação e retenção

Data: 2026-07-23
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD observado: `4700fc38317aae0d3c1955176b32c18ac3b34339`

Esta é evidência de trabalho local em checkout dirty. Não identifica um commit
final e não autoriza remoção remota, promoção ou escrita live.

## Resultado atual

Resultado da sprint: `IN_PROGRESS`

O auditor de retenção foi ampliado de 5 para 12 checks e agora valida inventário,
hashes, recuperação, referências, índices, conteúdo canônico e arquivos locais
pendentes. A suíte possui 16 testes e passou integralmente.

```text
./scripts/quality_gate.sh report-retention
  testes                         16/16 PASS
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

Foram corrigidos o link PG848, referências residuais PG499/PG578, repetição no
índice de reports e a distinção entre o contrato XMage histórico de junho e o
contrato corrente.

## Atomicidade e recuperação

- recovery commit registrado:
  `4700fc38317aae0d3c1955176b32c18ac3b34339`;
- manifesto:
  `docs/hermes-analysis/DEDUPLICATED_REPORTS_2026-07-23.json`;
- índice de grandes artefatos:
  `docs/hermes-analysis/ARCHIVED_LARGE_ARTIFACTS.md`;
- conteúdos preservados:
  `docs/hermes-analysis/deduplicated-report-content/`.

Os dois índices e os 23 conteúdos canônicos ainda estão untracked. O auditor
confirma seus hashes no worktree, mas o fechamento exige que índices,
canônicos, referências corrigidas e deleções sejam revisados e incorporados
atomicamente ao mesmo commit. Fazer somente as deleções destruiria a
governança comprovada.

## Pendências por task

- S9-01: revisar owner/retenção de cada decisão antes do commit atômico;
- S9-02: contexto corrente e project logic foram sincronizados; resta a
  auditoria final de links depois que o diff for congelado;
- S9-03: índices e auditor estão verdes; contratos gigantes restantes ainda
  precisam de disposição explícita, sem apagar norma canônica;
- S9-04: consumidores de rota/import, gates focados e agregados locais passaram
  depois da regeneração; resta repetir a prova na identidade limpa congelada;
- S9-05: duplicatas e artefatos governados estão verdes no gate, porém só
  fecham quando a mudança estiver atômica e rastreada;
- S9-06: secret scan, project logic e gate local completo passaram; faltam a
  auditoria final de links e o diff do checkout congelado.

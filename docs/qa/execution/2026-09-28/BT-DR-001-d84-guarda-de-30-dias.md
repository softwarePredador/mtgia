# Receipt — BT-DR-001: guarda de 30 dias e cadência decidida (D-83 e D-84) — 2026-09-28

- **Tarefa:** `BT-DR-001`, depois das decisões do dono de 2026-09-28, que já estão no registro
  oficial:
  - **D-83:** aceitou o ensaio semanal e o ensaio antes de toda migration na produção.
  - **D-84:** o backup local fica 30 dias, com cifra em repouso pelo FileVault; o dump mais novo
    com ensaio aprovado fica sempre; apagar dump continua pedindo o sim do dono na hora, até a
    rotação ser automatizada.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, junto com a `BT-DB-005`, no mesmo commit, como a coordenação pediu.
- **Limites:** nada tocou a produção nem o diretório real de backups. O check só lê metadados dos
  arquivos, e nenhum dump foi apagado.

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `server/config/backup_policy.json` | versão `2026-09-28.1`; decisões D-83 e D-84; `encryption` passa a ser o FileVault do disco; `retention_days` 30, com a nota da D-84; a cadência passa a `decidida_D-12_e_D-83` |
| `scripts/manaloom_backup_cadence.py` | o `check` devolve `retention`, só com a lista: `expired` para os dumps com mais de 30 dias e `keep` para o mais novo com ensaio aprovado e o mais novo de todos. Não apaga nada. A política passa a exigir a nota do prazo sempre |
| `docs/runbooks/BACKUP_E_RESTAURACAO.md` | cifra e guarda da D-84, a cadência da D-83 e a seção "Guarda de 30 dias", com o passo do sim do dono |
| `server/test/backup_cadence_test.py` | a política confere a D-83 e a D-84; teste novo da lista de vencidos |

O roteiro do lote, fora do repositório (`~/.manaloom/coordenacao/banco/ROTEIRO_LOTE_DEPLOY_BACKUP.md`),
ganhou a mesma guarda: depois do ciclo, mostrar `retention.expired` ao dono e apagar só com o
sim dele.

## Provas

| Prova | Resultado |
| --- | --- |
| `server/test/backup_cadence_test.py` | 16 verdes |
| O teste novo | com dumps de 45, 35, 31 e 10 dias e de 3 h, e ensaio aprovado no de 35 dias: `keep` é o de 35 dias e o de 3 h; `expired`, o de 45 e o de 31 dias (o ensaio deste falhou); todos os arquivos continuam lá |
| `python3 scripts/manaloom_backup_cadence.py validate-policy` | `valid`, versão `2026-09-28.1` |
| Mutações (`mutacoes_d84.json`, na cópia de trabalho da frente): guarda sem o dump ensaiado, check que apaga os vencidos, política com 14 dias, guarda sem a nota, guarda contada em horas e cadência sem a D-83 | 6 de 6 derrubadas |
| Gates | os do commit da `BT-DB-005` (receipt `BT-DB-005-tabelas-e-formas-da-producao.md`) |

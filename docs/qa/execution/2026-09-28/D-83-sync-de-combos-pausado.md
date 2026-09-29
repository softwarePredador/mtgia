# Receipt — o job de sync de combos está pausado (D-83) — 2026-09-28

- **Decisão:** D-83. O dono aceitou em bloco as recomendações do `BT-AI-029`. O item 4 manda
  pausar o job de sync de combos (`server/bin/cron_sync_combos.sh`) onde ele estiver agendado.
- **Motivo:** o job alimenta `card_combos` e `combo_cards`, que só o
  `POST /ai/weakness-analysis` lia. Essa rota saiu na D-31.
- **Dono no backlog:** `BT-AI-029`, cujo registry registrou o achado.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. As tabelas e as linhas ficam; sem migration.

## Onde o job estava agendado

Em lugar nenhum do código. Procurei nos três lugares que agendam jobs:

- **Daemon de ops** (`server/bin/manaloom_ops_daemon.py`). O `JOBS` não tem o job, e o
  manifesto de jobs (`jobs.json`), que o daemon escreve a partir do `JOBS`, também não.
- **Bootstrap do laboratório Hermes** (`server/bin/hermes_lab_cron_bootstrap.py`). Nem o
  `DESIRED_JOBS`, nem o `PAUSE_JOBS`, nem o `REMOVE_JOBS` citam o job.
- **Imagens e entrypoints.**
  - O `server/Dockerfile.manaloom-ops` copia o repositório inteiro, mas não dá permissão de
    execução a este script.
  - O `server/Dockerfile` da API leva só o binário compilado e o
    `api_with_battle_worker.sh`.

O único agendamento era a linha de crontab que a documentação antiga sugeria:

- `30 3 * * 1 /app/bin/cron_sync_combos.sh`, no próprio script e em
  `server/doc/MANALOOM_CRONS_E_PENDENCIAS.md`. O cabeçalho desse documento já dizia que o crontab
  não descreve o runtime.
- Se alguém instalou a linha num host, ela está fora do código. Esta frente não tem acesso à
  produção para conferir.

## O que mudou

- **A pausa fica no próprio script.** O `cron_sync_combos.sh` só roda com
  `MANALOOM_COMBO_SYNC_AUTHORIZED=1`, exatamente `1`.
  - Sem ela, sai 0 com um recibo de uma linha:
    `{"job":"cron_sync_combos","status":"paused","decision":"D-83",...}`.
  - Não baixa o bulk (~500 MB) e não toca o banco.
  - Assim, um agendamento de fora do código vira recibo de pausa, e não falha que alarma.
- **O cabeçalho do script** explica a pausa e marca a linha de crontab como histórica.
- **O documento de crons** marca a linha do job como pausada (D-83) e comenta a linha no crontab
  consolidado.
- **Guarda:** `server/test/combo_sync_pause_contract_test.dart` roda o script de verdade, com um
  `dart` falso no PATH que registra se foi chamado. Ele prova:
  - sem a autorização, o recibo de pausa e nenhum sync;
  - com `0`, `true`, `yes`, ` 1` ou `11`, ainda pausado;
  - com `1`, o sync de sempre (`dart run bin/sync_combos.dart`);
  - que nenhum agendador do código chama o job: o daemon de ops, o bootstrap do Hermes, o
    entrypoint de ops, o entrypoint da API e as duas imagens.

## Efeito na produção

O efeito na produção só vem no deploy do ops, que é a imagem que leva o script e o `dart`. A
imagem da API não leva o script.

- **Com crontab instalado num host.** Depois desse deploy, a linha passa a produzir o recibo de
  pausa, em vez de baixar o bulk e gravar as tabelas.
- **Sem crontab.** Nada muda na produção, porque nenhum agendador do código chamava o job.
- **Recomendação para o deploy do ops.** Conferir com o `server/bin/audit_easypanel_cron_runtime.py`
  que nenhum cron do EasyPanel chama o script. Se chamar, remover a linha, ou deixá-la e
  confirmar o recibo de pausa no log.

## Evidência

- **Contrato:** `server/test/combo_sync_pause_contract_test.dart`, 4/4.
- **Foco:** 3 arquivos e 28 testes (o contrato novo, o suporte do sync do Commander Spellbook e a fronteira
  operacional).
- **Sem E2E por HTTP:** a mudança não toca rota; o script roda de verdade no teste de contrato.

## Mutações

Cada mutação foi aplicada no worktree. Rodou então o teste de contrato e, por fim, o arquivo foi
restaurado e conferido byte a byte. As 3 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M150 | o job roda sem a autorização | contrato: pausa e valor exato (2/4) |
| M151 | qualquer valor autoriza | contrato: valor exato (1/4) |
| M152 | o daemon de ops volta a agendar o job | contrato: nenhum agendador (1/4) |

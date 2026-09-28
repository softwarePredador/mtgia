# Runbook — SLOs e alertas (`BT-OBS-001`)

- **Política:** `server/config/slo_alert_policy.json` (D-47 e D-51).
- **Avaliador:** `server/bin/manaloom_slo_alerts.py`, job `manaloom_slo_alerts` do daemon
  de ops, a cada 5 minutos.
- **Quem recebe:** o dono do projeto, por e-mail (Resend) ou Telegram.
- **Fora daqui:** o alerta de release é o `BT-OBS-003` (D-51); a queda vista de fora
  (DNS, TLS, domínio) é o `BT-OBS-002`. Se o host inteiro cair, este avaliador cai junto.

## SLOs

- **Disponibilidade da API: 99,5% em 30 dias (D-47).** A unidade é a janela de 5 minutos
  avaliada. A janela é boa quando `/health/live` e `/health/ready` respondem 200 e a taxa de
  5xx do tráfego de produto fica abaixo de 5%. Janela com menos de 20 requisições conta só
  pela sondagem. O orçamento de erro é 0,5% das janelas, cerca de 3 h 36 min em 30 dias.
- **Latência de leitura: p95 abaixo de 800 ms (D-47).** Vale para GET e HEAD de produto em
  cada janela de 5 minutos com pelo menos 20 leituras.
- **Tráfego de produto:** as sondagens `/health*`, `/ready` e `/capabilities` ficam fora das
  janelas.
- **Relatório:** `python3 server/bin/manaloom_slo_alerts.py report` no contêiner de ops. Lê
  `$MANALOOM_OPS_DATA_DIR/slo/observations.jsonl`, que guarda 35 dias. A saída traz
  disponibilidade, orçamento restante, conformidade de latência e cobertura (fração das
  janelas avaliadas).

## Ativação

O avaliador só lê e só avisa quem estiver configurado. Configurar o serviço de ops
(`evolution_manaloom-ops`) é configuração persistente e fica com o dono. As variáveis são
estas:

- `MANALOOM_SLO_API_BASE_URL`: endereço interno da API na rede do Swarm, por exemplo
  `http://evolution_cartinhas:8080`;
- `MANALOOM_OPS_API_KEY`: a mesma chave de ops do backend, para ler `/health/metrics`;
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` e `DB_PASS`: já usados pelos outros jobs. A
  leitura roda em transação READ ONLY;
- o receptor, uma das duas opções:
  - `MANALOOM_ALERT_CHANNEL=email`, com `MANALOOM_ALERT_EMAIL_TO`, `RESEND_API_KEY` e
    `RESEND_FROM_EMAIL` (o domínio verificado do Resend);
  - `MANALOOM_ALERT_CHANNEL=telegram`, com `MANALOOM_ALERT_TELEGRAM_BOT_TOKEN` e
    `MANALOOM_ALERT_TELEGRAM_CHAT_ID`.

Sem receptor, o job grava a observação e termina com erro `BLOCKED: receptor de alerta não
configurado`. Alerta sem receptor não é alerta.

## Teste de alerta

1. No contêiner de ops, rode `python3 server/bin/manaloom_slo_alerts.py test-alert`. A saída
   traz `test_id`, canal e horário.
2. O dono confirma à coordenação que a mensagem `Teste de alerta <test_id>` chegou.
3. A coordenação grava o receipt em `docs/qa/execution/<data>/`, com o `test_id`, o canal e
   a confirmação. Nenhum endereço ou token vai no receipt.

## Como os avisos chegam

- Uma mensagem por avaliação, com os alertas novos, os que seguem abertos há mais de 60
  minutos e os resolvidos.
- O estado fica em `$MANALOOM_OPS_DATA_DIR/slo/state.json`. Se o envio falhar, o estado não
  avança e a próxima avaliação tenta de novo.
- A mensagem leva o código, a severidade, o valor observado, o limite e a seção deste
  runbook. Não leva e-mail, UUID, token nem caminho cru: as rotas saem como template
  (`GET /decks/:id`).

## api_down

A API não respondeu a `GET /health/live` em duas avaliações seguidas.

1. `docker service ps evolution_cartinhas` no host: a tarefa está rodando? Reiniciou?
2. Logs do serviço, sem copiar corpo de requisição.
3. Se o host inteiro caiu, este alerta nem chega: é o `BT-OBS-002`.
4. O deploy do backend já reverte sozinho quando falha. Voltar uma versão que já estava no
   ar é `docker service update --rollback evolution_cartinhas`, com a palavra do dono.

## api_not_ready

A API responde, mas `GET /health/ready` não devolve 200 em duas avaliações seguidas.

1. Ler `/health/ready` e ver qual check falhou: banco, schema das migrations, capabilities ou
   worker.
2. Schema incompleto: conferir o ledger de migrations com `with_new_server_pg.sh --read-only`.
   Aplicar migration pede a palavra do dono.
3. Capabilities inválidas: o arquivo de política do release não bate com o digest do deploy.

## postgres_unavailable

O check de banco do `/health/ready` não está `healthy`, ou o avaliador não conseguiu abrir a
conexão só de leitura, em duas avaliações seguidas.

1. `docker service ps evolution_manaloom-postgres` e os logs do contêiner.
2. Espaço em disco do host: a política de capacidade (`BT-CAP-001`) traz os limites.
3. Não reinicie o banco sem backup recente (`BT-DR-001`).

## api_5xx

A taxa de 5xx está queimando o orçamento do SLO. Queima rápida: 7,2% ou mais em 5 minutos,
com ao menos 20 requisições. Queima lenta: 3% ou mais em 60 minutos, com ao menos 100.

1. `/health/metrics` com a chave de ops: em `endpoints`, as rotas com mais `error_count`.
2. Sentry pelo `request_id`: os eventos não levam o ID do usuário.
3. Se começou depois de um deploy, avaliar o rollback com o dono.

## api_read_latency_p95

O p95 das leituras passou de 800 ms em duas janelas seguidas, com ao menos 20 leituras.

1. `/health/metrics`: em `endpoints`, as rotas GET com maior `p95_latency_ms`.
2. Conexões e consultas lentas no PostgreSQL, com leitura READ ONLY.
3. Memória e CPU do host: `scripts/manaloom_capacity_snapshot.sh` e o preflight da política
   de capacidade.

## metrics_unavailable

O avaliador não leu `/health/metrics` em duas avaliações seguidas, com a API no ar. Sem isso
o SLO fica sem medição.

1. `MANALOOM_OPS_API_KEY` do serviço de ops é igual à do backend? Um 401 indica chave
   divergente.
2. `MANALOOM_SLO_API_BASE_URL` aponta para o serviço certo na rede interna?

## postgres_connections_high

As conexões ao banco passaram de 80% de `max_connections`.

1. Contar as sessões por estado, só de leitura: `server/sql/readonly/capacity_postgres.sql`.
2. Jobs ou scripts manuais segurando conexão? O pool da API é de 10 por processo.
3. Aumentar `max_connections` é mudança de configuração do banco, com a palavra do dono.

## job_failed

Um job do daemon de ops terminou com erro na última execução. O código do alerta traz o
nome do job.

1. Ler o log do job, no caminho `latest_output` do manifesto
   (`$MANALOOM_OPS_DATA_DIR/cron/jobs.json`).
2. Jobs com contrato (catálogo, outbox da exclusão, limpeza por prazo) deixam receipt: ler
   antes de repetir.
3. Repetir um job que escreve pede o mesmo cuidado do agendamento normal.

## job_overdue

Um job agendado não começou no último horário previsto, com 30 minutos de tolerância. Um
job que acabou de aparecer no manifesto só conta a partir do primeiro horário depois disso.

1. O daemon de ops está rodando? `GET /health` do serviço de ops lista os jobs ligados.
2. A política de capabilities desligou o job? Então ele sai do manifesto e o alerta some.
3. O lock do job ficou preso? O daemon usa `flock -n`.

## catalog_stale

O último sync com sucesso de `cards` ou de `card_legalities` em `sync_log` tem mais de 7 dias.
A D-18 exige cartas com menos de 7 dias para o GO.

1. O job `manaloom_catalog_reference_refresh` está ligado e rodou? Ver `job_failed` e
   `job_overdue`.
2. O receipt do catálogo está no diretório de artefatos do ops.

## endpoint_cache_large

O cache de rotas em memória desta réplica passou de 5.000 entradas.

1. As entradas vencem em no máximo 24 h (D-23). Um crescimento contínuo indica chave que não
   se repete. Ver quais rotas usam `EndpointCache`.
2. Memória do contêiner da API: a política de capacidade traz os limites do host.

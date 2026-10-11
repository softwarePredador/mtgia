# Receipt: BT-OBS-001, o que falta na produção para o receptor de alerta (2026-10-10)

- **Tarefa:** `BT-OBS-001`, item L-10 do plano do MVP de 2026-10-10. O código está pronto desde
  2026-09-24, mas o receptor de alerta e o teste de alerta reconhecido pelo dono não existem na
  produção.
- **Executado por:** frente OPS-COORTE, worktree `~/.manaloom/coordenacao/wt/ops`, branch
  `feat/ops-cohort-matrix`.
- **Limites:** só documentação. Nada foi configurado, lido ou testado na produção. Não houve SSH nem
  leitura de `.env`, e nenhum alerta foi enviado.

## Estado do código

- **Avaliador:** `server/bin/manaloom_slo_alerts.py`, rodado pelo job `manaloom_slo_alerts` do
  daemon de ops a cada 5 min. O job roda até com política inválida.
- **Política:** `server/config/slo_alert_policy.json`, com a D-47 e a D-51.
- **Runbook:** `docs/runbooks/SLO_E_ALERTAS.md`, seções "Ativação" e "Teste de alerta".
- **Deploy do ops:** desde o S-01 (mesma branch), o deploy confere o `/health` e o `jobs.json`
  contra a lista de jobs que o daemon do SHA publica. Com as 29 off, essa lista tem 5 jobs,
  `manaloom_slo_alerts` entre eles.
- **Sem receptor:** o job grava a observação e termina com
  `BLOCKED: receptor de alerta não configurado`. A cada 5 minutos, ele aparece com erro no
  `jobs.json` e no relatório do governor. O deploy converge mesmo assim, porque confere os nomes dos
  jobs e não o status.

## O que falta configurar no serviço `evolution_manaloom-ops`

É configuração persistente, e fica com o dono (D-47 e runbook).

O daemon lê o ambiente do serviço. A imagem não leva `server/.env`, porque o `git archive` não o
inclui. O deploy do ops só usa `--env-add` nas variáveis fixas dele, então o que o dono acrescentar
continua de um deploy para o outro.

| Variável | Para quê | Regra que o avaliador confere |
| --- | --- | --- |
| `MANALOOM_ALERT_CHANNEL` | Escolhe o canal: `email` ou `telegram` | outro valor ou ausente: `BLOCKED` |
| `MANALOOM_ALERT_EMAIL_TO` | Destino do e-mail (canal `email`) | e-mail válido |
| `RESEND_API_KEY` | Envio pelo Resend (canal `email`) | começa com `re_` e tem 16 caracteres ou mais |
| `RESEND_FROM_EMAIL` | Remetente do domínio verificado no Resend (canal `email`) | e-mail válido |
| `RESEND_FROM_NAME` | Nome do remetente (opcional) | o padrão é `BrewTact` |
| `MANALOOM_ALERT_TELEGRAM_BOT_TOKEN` | Token do bot (canal `telegram`) | `<número>:<30 caracteres ou mais>` |
| `MANALOOM_ALERT_TELEGRAM_CHAT_ID` | Conversa do dono (canal `telegram`) | inteiro, pode ser negativo |
| `MANALOOM_SLO_API_BASE_URL` | Endereço interno da API no Swarm, por exemplo `http://evolution_cartinhas:8080` | `https?://` com host simples, sem caminho |
| `MANALOOM_OPS_API_KEY` | Leitura de `/health/metrics` | o mesmo valor do backend, com 32 caracteres ou mais (o deploy do backend já exige esse tamanho) |
| `MANALOOM_RELEASE_PUBLIC_BASE_URL` | Origem pública para o alerta de release (`BT-OBS-003`) | `https://` com host, sem caminho |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` | Leitura READ ONLY do PostgreSQL | já existem no serviço, usadas pelos outros jobs |

## Teste de alerta reconhecido pelo dono

1. Depois de configurar o serviço, no contêiner de ops:
   `python3 server/bin/manaloom_slo_alerts.py test-alert`. A saída traz `test_id`, canal e horário.
2. O dono confirma à coordenação que a mensagem `[BrewTact] Teste de alerta <test_id>` chegou.
3. A coordenação grava o receipt em `docs/qa/execution/<data>/`, com o `test_id`, o canal, o
   horário e a confirmação do dono. Nenhum endereço, token ou chave entra no receipt.
4. Depois, o `python3 server/bin/manaloom_slo_alerts.py run` tem de sair 0, e o `jobs.json` tem de
   mostrar `manaloom_slo_alerts` com `last_status` `ok`.

## Ordem no lote

- **Antes do deploy do ops** (risco 8 do plano): sem receptor, o job falha a cada 5 minutos desde o
  primeiro boot da imagem nova.
- **Antes da publicação do Android (L-08):** `scripts/manaloom_publish_android_release.sh` recusa
  sem `MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE` (crítica do plano, "Android depois do ops
  configurado"). Então o L-10 vem antes do L-08.
- **O e-mail dos convites** (decisão 19) usa outro caminho (`BETA_INVITE_WEBHOOK_*`) e é
  conferido à parte.

## O que este receipt não fecha

`BT-OBS-001` continua `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`. Ele só fecha com o serviço configurado
e o teste de alerta reconhecido pelo dono, na sessão autorizada do lote.

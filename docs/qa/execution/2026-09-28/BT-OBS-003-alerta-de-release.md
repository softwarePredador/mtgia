# Receipt — BT-OBS-003: alerta de release, separado do BT-OBS-001 (D-51) — 2026-09-28

- **Tarefa:** `BT-OBS-003`. A decisão do dono de 2026-09-22 é a D-51: o alerta de release sai
  do `BT-OBS-001` e depende da identidade do `BT-REL-002`.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, na rodada 4, em modo ensaio.
- **Limites:** nada tocou a produção.
  - A prova roda o avaliador de verdade contra um HTTP falso que serve a identidade de cada
    superfície.
  - Configurar o ops (receptor e origem pública) continua com o dono, como no `BT-OBS-001`.

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `server/bin/manaloom_slo_alerts.py` | O avaliador do `BT-OBS-001` coleta também a identidade de release e avalia as quatro regras `release_*` (detalhe logo abaixo da tabela) |
| `server/config/slo_alert_policy.json` (`2026-09-28.2`) | As quatro regras com `task: BT-OBS-003` e a seção `release` (dona `BT-OBS-003`: fonte das identidades, âncora e classificação), cada limite justificado. O validador exige que só os alertas de release sejam do `BT-OBS-003` (D-51) |
| `docs/runbooks/SLO_E_ALERTAS.md` | A parte "Alertas de release (`BT-OBS-003`, D-51)", com uma seção por alerta |
| `scripts/manaloom_deploy_ops_image.sh` | O image do ops leva `scripts/manaloom_release_identity_gate.py`. Sem ele, o alerta ficaria cego no host: o deploy empacota só `server/`, `scripts/lib` e poucos outros |
| `server/test/slo_alerts_test.py` | 33 testes (detalhe em "Provas") |

- **A coleta:** é a mesma do `BT-REL-002`. Usa o portão de identidade e as fontes de
  `server/config/release_promotion.json`:
  - o backend pela URL interna (`MANALOOM_SLO_API_BASE_URL`);
  - o site, o `/app` e o APK pela origem pública da política, ou por
    `MANALOOM_RELEASE_PUBLIC_BASE_URL`, que tem de ser HTTPS.
- **A âncora:** o próprio ops, que sai na mesma promoção: `GIT_SHA` e a matriz do image
  (`MANALOOM_RELEASE_CAPABILITIES_FILE`).
- **Falha fechado:** sem o portão, sem `GIT_SHA` ou com a matriz ilegível, a coleta vira um
  alerta de identidade ilegível, e o resto do `BT-OBS-001` segue avaliando.
- **A mensagem:** diz `BT-OBS-001 e BT-OBS-003` e leva SHAs curtos (12 caracteres) e a seção do
  runbook.

## As regras

| Alerta | Severidade | Quando | Por quê do limite |
| --- | --- | --- | --- |
| `release_identity_unreadable` | aviso | a identidade de uma superfície não se lê (fonte fora do ar, ops sem identidade ou sem o portão) por 2 avaliações. O backend fora do ar fica com o `api_down` | como a queda: uma leitura perdida não acorda ninguém |
| `release_identity_mixed` | aviso | backend, site ou `/app` num SHA diferente do ops por 12 avaliações (1 h) | uma promoção do BT-REL-001 leva até uma hora; o alerta pega a promoção pela metade e o deploy fora da transação, não a transação em curso |
| `release_capabilities_divergent` | crítico | no mesmo SHA do ops, uma superfície serve outro digest da matriz, outro modo da D-13, outro produto ou superfície, flag ligada com a capability desligada, identidade de desenvolvimento, `/health` e `/capabilities` discordando, ou responde sem a identidade; por 2 avaliações | no mesmo SHA não há motivo legítimo para isso (BT-REL-002) |
| `release_android_behind` | aviso | o APK publicado num SHA diferente do ops por 24 h | o Android sai em transação própria depois do núcleo (D-13), e o app instalado já nega o que não conhece |

Uma superfície num SHA diferente não gera divergência de matriz: a matriz dela é a do SHA dela.
Ela conta como núcleo misturado ou, no Android, como atraso.

## Provas

`server/test/slo_alerts_test.py` tem 33 verdes; eram 24.

- **A política:** mais 7 recusas.
  - regra de release sem o `task`, ou alerta do `BT-OBS-001` marcado como do `BT-OBS-003`
    (D-51);
  - sem a seção `release`, ou com outra fonte;
  - carência zero;
  - `consecutive` inválido;
  - regra sem seção no runbook.
- **`ReleaseAlertTest` (9):**
  - o image do ops leva o portão, a matriz e o `GIT_SHA`;
  - release coerente não alerta, e as URLs certas são lidas;
  - núcleo misturado avisa na 12ª avaliação e fecha quando volta;
  - cinco divergências no mesmo SHA são críticas na 2ª avaliação: outro digest,
    `/health` × `/capabilities`, flag ligada, identidade de desenvolvimento e APK com outra
    matriz;
  - site fora avisa como ilegível, e a API fora não duplica o `api_down`;
  - o ops sem `GIT_SHA` avisa, e o portão ausente não derruba a avaliação;
  - o Android pode atrasar 23 h, avisa às 24 h e a memória limpa quando volta;
  - a origem pública pode ser trocada, e sem TLS vira ilegível;
  - a mensagem leva SHAs curtos e a seção do runbook, sem SHA completo.
- **O resto:** os 24 testes que já existiam seguem verdes com a coleta de release ligada;
  `validate-policy` dá `valid`, versão `2026-09-28.2`.
- **Mutações (`mutacoes_bt_obs_003.json`):** as 17 foram derrubadas.
  - avaliação: mixed, atraso, carência, API fora, divergência, ilegível, origem pública, TLS,
    mensagem, portão ausente e ops sem identidade;
  - política: `task`, seção, carência e o `consecutive` de 12;
  - o image do ops sem o portão.

## Gates

suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (36 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations)

## Passo do lote

O passo é o mesmo do `BT-OBS-001`: o job `manaloom_slo_alerts` já roda a cada 5 minutos no ops.

- **Depois da primeira promoção com os scripts do `BT-REL-002`:** o site passa a servir
  `/release.json` e o `/app` a identidade embarcada, e o alerta deixa de avisar identidade
  ilegível.
- **Se o contêiner do ops não alcançar a origem pública:** o dono define
  `MANALOOM_RELEASE_PUBLIC_BASE_URL` no ops.

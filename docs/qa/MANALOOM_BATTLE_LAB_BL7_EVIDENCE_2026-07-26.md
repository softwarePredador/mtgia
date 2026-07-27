# Evidência BL7 — Spike XMage humano contra IA

- Data: 2026-07-26; reabertura técnica em 2026-07-27
- Resultado da sprint: `PASS_DECISION_GO`
- Decisão de produto: `GO` limitado para iniciar BL8 localmente
- Superfície pública criada: nenhuma

| Task | Estado | Evidência |
|---|---|---|
| BL7-01 | `PASS` | ADR 0002 mantém capability experimental isolada; nenhuma adoção global |
| BL7-02 | `PASS_SPIKE` | harness substitui apenas deck A por `HUMAN`; deck B permanece `COMPUTER_MAD` |
| BL7-03 | `PASS_INVENTORY` | callbacks tratados e não tratados foram inventariados |
| BL7-04 | `PASS_SPIKE` | prompt/opções usam HMAC opaco, message/state version, uso único e rejeição de resposta fora do estado |
| BL7-05 | `PASS_RUNTIME` | timeout de 1.000 ms recebeu `CONCEDE=true`, terminou em `GAME_OVER` e encerrou o processo; não promete takeover para IA |
| BL7-06 | `PASS_RUNTIME` | 3/3 partidas completas, 251/251 respostas aceitas, zero deadlock, zero leak identificável e métricas de latência/memória registradas |
| BL7-07 | `PASS_DECISION_GO` | ADR 0004 substitui o NO-GO histórico e autoriza somente a implementação local, default-off, de BL8 |

## Cobertura observada

Allowlist experimental:

- `GAME_ASK`;
- `GAME_SELECT`;
- `GAME_TARGET`;
- `GAME_CHOOSE_ABILITY` → UUID allowlisted;
- `GAME_CHOOSE_PILE` → boolean;
- `GAME_CHOOSE_CHOICE` → string/opção especial allowlisted;
- `GAME_PLAY_MANA` → UUID presente em `GameView.canPlayObjects`, tipo de mana
  presente no pool privado, ação especial anunciada ou cancelamento;
- `GAME_PLAY_XMANA` → boolean;
- `GAME_GET_AMOUNT` → inteiro dentro dos limites;
- `GAME_GET_MULTI_AMOUNT` → string numérica delimitada e validada.

O inventário conhecido não possui mais família sem tratamento. Para
`GAME_PLAY_MANA`, o envelope não aceita UUID fornecido pelo cliente: ele
transforma somente IDs produzidos pelo servidor em opções HMAC opacas e deixa
a validação final da habilidade de mana com o XMage.

Também não foi encontrada API revisada que prove transição segura de
participante `HUMAN` para IA durante a partida.

## Medição runtime

O probe `HumanVsAiRuntimeSpikeMain` existe somente em `src/test`, recusa host
fora de loopback e usa o mesmo pin do sidecar. Três partidas humanas passivas
contra `COMPUTER_MAD` concluíram normalmente:

| Rodada | Turno final | Respostas | Rejeições | Deadlocks | Leak | p95 | Máximo | Heap cliente |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 19 | 82 | 0 | 0 | 0 | 494 µs | 45.625 µs | 559.792.352 B |
| 2 | 19 | 82 | 0 | 0 | 0 | 317 µs | 546 µs | 250.095.104 B |
| 3 | 20 | 87 | 0 | 0 | 0 | 314 µs | 364 µs | 252.841.312 B |

Total: `251/251` respostas aceitas. O cenário separado de expiração iniciou o
TTL apenas depois de `GAME_INIT/START_GAME`, forçou `1.000 ms`, recebeu
concessão confirmada e `GAME_OVER`, com `3/3` respostas aceitas e zero
deadlock/leak.

A checagem de privacidade usa um confronto sem efeitos de revelação: nenhuma
carta identificável apareceu em `GameView.opponentHands` e a identidade de
`myPlayer` sempre coincidiu com a cadeira humana. Nenhum payload privado é
impresso no relatório.

## Reprodução

```bash
bash -n services/xmage-sidecar/bin/human_vs_ai_spike.sh
services/xmage-sidecar/bin/human_vs_ai_spike.sh
XMAGE_SERVER_PORT=19171 \
  services/xmage-sidecar/bin/human_vs_ai_runtime_spike.sh
```

O harness executa nove testes Maven focados e imprime
`BL7_CALLBACKS_UNHANDLED=none`. O probe runtime executa três partidas normais e
um timeout terminal. O `GO` do ADR 0004 autoriza iniciar BL8 localmente e
default-off; não autoriza deploy, migration live, rollout ou takeover
humano→IA.

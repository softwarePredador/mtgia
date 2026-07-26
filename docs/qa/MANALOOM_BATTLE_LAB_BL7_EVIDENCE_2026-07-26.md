# Evidência BL7 — Spike XMage humano contra IA

- Data: 2026-07-26
- Resultado da sprint: `PASS_DECISION_NO_GO`
- Decisão de produto: `NO_GO`
- Superfície pública criada: nenhuma

| Task | Estado | Evidência |
|---|---|---|
| BL7-01 | `PASS` | ADR 0002 mantém capability experimental isolada; nenhuma adoção global |
| BL7-02 | `PASS_SPIKE` | harness substitui apenas deck A por `HUMAN`; deck B permanece `COMPUTER_MAD` |
| BL7-03 | `PASS_INVENTORY` | callbacks tratados e não tratados foram inventariados |
| BL7-04 | `PASS_SPIKE` | prompt/opções usam HMAC opaco, message/state version, uso único e rejeição de resposta fora do estado |
| BL7-05 | `PASS_SPIKE` | timeout tenta concede/termina processo; não promete takeover para IA |
| BL7-06 | `NO_GO_INSUFFICIENT_RUNTIME` | não houve partida humana completa; portanto zero deadlock/vazamento e cobertura alvo não foram provados |
| BL7-07 | `PASS_DECISION_NO_GO` | ADR 0003 registra decisão e condições de reabertura |

## Cobertura observada

Allowlist experimental:

- `GAME_ASK`;
- `GAME_SELECT`;
- `GAME_TARGET`.

Sem tratamento:

- `GAME_CHOOSE_ABILITY`;
- `GAME_CHOOSE_PILE`;
- `GAME_CHOOSE_CHOICE`;
- `GAME_PLAY_MANA`;
- `GAME_PLAY_XMANA`;
- `GAME_GET_AMOUNT`;
- `GAME_GET_MULTI_AMOUNT`.

Também não foi encontrada API revisada que prove transição segura de
participante `HUMAN` para IA durante a partida.

## Reprodução

```bash
bash -n services/xmage-sidecar/bin/human_vs_ai_spike.sh
services/xmage-sidecar/bin/human_vs_ai_spike.sh
```

O harness executa cinco testes Maven e imprime
`BL7_SPIKE_DECISION=NO_GO`. NO-GO é a saída correta do spike, não falha
silenciosa nem permissão para iniciar BL8.

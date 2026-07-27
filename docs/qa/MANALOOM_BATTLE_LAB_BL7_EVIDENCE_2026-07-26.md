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
- `GAME_TARGET`;
- `GAME_CHOOSE_ABILITY` → UUID allowlisted;
- `GAME_CHOOSE_PILE` → boolean;
- `GAME_CHOOSE_CHOICE` → string/opção especial allowlisted;
- `GAME_PLAY_XMANA` → boolean;
- `GAME_GET_AMOUNT` → inteiro dentro dos limites;
- `GAME_GET_MULTI_AMOUNT` → string numérica delimitada e validada.

Sem tratamento:

- `GAME_PLAY_MANA`, cujo callback revisado não fornece UUIDs permitidos para
  uma resposta remota segura; o spike falha fechado.

Também não foi encontrada API revisada que prove transição segura de
participante `HUMAN` para IA durante a partida.

## Reprodução

```bash
bash -n services/xmage-sidecar/bin/human_vs_ai_spike.sh
services/xmage-sidecar/bin/human_vs_ai_spike.sh
```

O harness executa sete testes Maven focados e imprime
`BL7_SPIKE_DECISION=NO_GO`. NO-GO é a saída correta do spike, não falha
silenciosa nem permissão para iniciar BL8.

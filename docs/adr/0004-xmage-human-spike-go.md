# ADR 0004 — GO limitado do spike XMage humano contra IA

- Estado: aceito
- Data: 2026-07-27
- Programa: `BL7`
- Decisão: `GO`
- Substitui: decisão `NO_GO` do ADR 0003

## Contexto

O ADR 0003 bloqueou BL8 porque o primeiro spike tinha apenas prova estática:
nenhuma partida com cadeira humana havia terminado no XMage real e não
existiam métricas de latência, memória, deadlock ou privacidade. A fronteira do
ADR 0002 permite duas políticas seguras para expiração: takeover humano→IA
comprovado **ou** concessão seguida do encerramento explícito do processo
isolado.

## Evidência runtime

O novo probe continua fora da API e só aceita XMage em loopback. Ele executou
três partidas completas de `Isamaru, Hound of Konda` humano passivo contra
`Krenko, Mob Boss` `COMPUTER_MAD`:

- `3/3` partidas encerradas normalmente, nos turnos `19`, `19` e `20`;
- `251/251` respostas allowlisted aceitas pelo XMage e `0` rejeições;
- `0` deadlocks e `0` hard timeouts nas partidas normais;
- `0` objetos identificáveis da mão adversária e `0` divergências da
  identidade privada do participante;
- p95 de despacho por partida de `494 µs`, `317 µs` e `314 µs`;
- maior despacho observado de `45.625 µs`;
- heap do cliente de `559.792.352` bytes no carregamento frio e até
  `252.841.312` bytes nas repetições aquecidas;
- servidor real pinado em XMage `1.4.60`, commit
  `34d81ea4995ce15d7e1a788dc6d2a3595d35bcec`, limitado a `-Xmx1g`.

Um quarto cenário forçou TTL de `1.000 ms`. Ele encerrou com `CONCEDE`
confirmado pelo servidor, `GAME_OVER`, `3/3` respostas aceitas, zero leak e
zero deadlock. O processo cliente é terminal depois do relatório. O probe
descobriu e corrigiu uma corrida inicial: o TTL agora começa somente após
`GAME_INIT` ou `START_GAME`, quando existe `gameId`.

O caminho normal observou `GAME_ASK`, `GAME_SELECT` e `GAME_TARGET`. As sete
famílias tipadas restantes — `GAME_CHOOSE_ABILITY`, `GAME_CHOOSE_PILE`,
`GAME_CHOOSE_CHOICE`, `GAME_PLAY_MANA`, `GAME_PLAY_XMANA`,
`GAME_GET_AMOUNT` e `GAME_GET_MULTI_AMOUNT` — continuam cobertas por
adaptadores e testes focados com bounds próprios. Qualquer callback, payload,
opção, estado ou confirmação fora do contrato falha fechado e termina a
sessão.

## Decisão

BL7 recebe `GO` para iniciar a implementação local de BL8, com estas
restrições:

1. Coach e sessões interativas permanecem desabilitados por padrão;
2. BL8 usa contrato, persistência e runtime separados da simulação batch;
3. nenhuma rota do spike de teste vira superfície pública;
4. resposta obsoleta, duplicada, não opaca ou rejeitada pelo XMage termina
   fail-closed;
5. “deixar a IA decidir” não existe: timeout concede e termina a sessão;
6. visão privada nunca é reutilizada como replay, log ou stream público;
7. este GO não autoriza migration live, deploy ou rollout.

O GO é suficiente para engenharia de BL8; não é GO de release nem evidência de
homologação BL9/BL10.

## Reprodução

Com um servidor XMage pinado disponível apenas em loopback:

```bash
services/xmage-sidecar/bin/human_vs_ai_spike.sh
XMAGE_SERVER_PORT=19171 \
  services/xmage-sidecar/bin/human_vs_ai_runtime_spike.sh
```

O primeiro comando audita bytecode e adaptadores. O segundo executa três
partidas normais e um cenário obrigatório de timeout/concessão.

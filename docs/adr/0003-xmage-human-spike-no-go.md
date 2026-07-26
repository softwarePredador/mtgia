# ADR 0003 — NO-GO do spike XMage humano contra IA

- Estado: aceito
- Data: 2026-07-26
- Programa: `BL7`
- Decisão: `NO_GO`

## Contexto

O Coach Mode depende de provar que uma única cadeira humana pode responder a
prompts limitados do XMage sem revelar informação privada, bloquear o processo
ou aceitar comandos arbitrários. O ADR 0002 autoriza somente um spike isolado,
sem rota pública, antes de iniciar BL8.

## Evidência observada

O bytecode fixado do XMage `1.4.60` e o harness de teste provaram:

- deck A pode ingressar como `HUMAN`;
- deck B permanece `COMPUTER_MAD`;
- `GAME_ASK`, `GAME_SELECT` e `GAME_TARGET` cobrem o recorte experimental de
  mulligan, ação principal, alvo e combate;
- `messageId` pode compor a versão de estado;
- prompt e opções podem usar IDs HMAC opacos, vinculados ao estado e de uso
  único;
- timeout pode tentar `CONCEDE` e sempre encerrar o processo isolado.

O spike também confirmou bloqueios:

- `GAME_CHOOSE_ABILITY`, `GAME_CHOOSE_PILE`, `GAME_CHOOSE_CHOICE`,
  `GAME_PLAY_MANA`, `GAME_PLAY_XMANA`, `GAME_GET_AMOUNT` e
  `GAME_GET_MULTI_AMOUNT` permanecem sem tratamento;
- nenhuma API remota revisada prova transição segura de `HUMAN` para IA;
- nenhuma partida humana completa foi executada em runtime;
- portanto não há evidência suficiente para medir zero deadlock, zero
  vazamento e cobertura dos prompts-alvo durante uma partida completa.

## Decisão

BL7 termina em `NO_GO`. BL8 permanece `BLOCKED` e BL9/BL10 ficam
`NOT_STARTED_DEPENDENCY_BLOCKED`. Nenhuma rota, feature flag pública, sessão
interativa ou promessa de delegação para IA será criada.

Battle Lab e Live Spectator continuam independentes. O Live é somente leitura:
pausar o cliente não pausa o engine e nenhum payload do stream é um comando.

## Condições para reabrir

Um novo spike, deliberadamente autorizado, precisa:

1. tratar ou delegar explicitamente as sete famílias de callback restantes;
2. provar política de timeout sem alegar takeover humano→IA inexistente;
3. executar partidas humanas completas no runtime isolado;
4. medir latência, memória, deadlocks e vazamento de informação privada;
5. repetir os testes de IDs opacos, estado obsoleto e resposta duplicada;
6. emitir novo ADR com GO explícito.

Até lá, o produto não oferece Coach Mode.

## Provas reproduzíveis

```bash
bash -n services/xmage-sidecar/bin/human_vs_ai_spike.sh
services/xmage-sidecar/bin/human_vs_ai_spike.sh
```

O script valida o pin Maven/bytecode, executa cinco testes e imprime a matriz de
callbacks e a decisão `BL7_SPIKE_DECISION=NO_GO`.

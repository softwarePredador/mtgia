# ADR 0003 — NO-GO do spike XMage humano contra IA

- Estado: substituído pelo ADR 0004 em 2026-07-27
- Data: 2026-07-26
- Programa: `BL7`
- Decisão: `NO_GO`

> Registro histórico: esta decisão era correta para a evidência disponível em
> 2026-07-26. O runtime adicional e a política de encerramento explícito que
> satisfizeram a reabertura estão no ADR 0004.

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
- `GAME_CHOOSE_ABILITY`, `GAME_CHOOSE_PILE`, `GAME_CHOOSE_CHOICE`,
  `GAME_PLAY_MANA`, `GAME_PLAY_XMANA`, `GAME_GET_AMOUNT` e
  `GAME_GET_MULTI_AMOUNT` aceitam adaptadores tipados com
  allowlists/limites próprios;
- `gameId`, `messageId` e versão compõem o estado;
- prompt e opções usam IDs HMAC opacos, vinculados ao jogo/estado e de uso
  único;
- timeout pode tentar `CONCEDE` e sempre encerrar o processo isolado.

Na reabertura técnica de 2026-07-27, `GAME_PLAY_MANA` passou a aceitar somente
IDs presentes em `GameView.canPlayObjects`, tipos existentes no pool privado,
ação especial anunciada ou cancelamento. O cliente nunca fornece UUID bruto e
o XMage mantém a validação final da habilidade de mana.

O spike ainda confirma bloqueios:

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

1. executar partidas humanas completas no runtime isolado;
2. medir latência, memória, deadlocks e vazamento de informação privada;
3. provar política de timeout sem alegar takeover humano→IA inexistente;
4. manter os testes de IDs opacos, estado obsoleto e resposta duplicada;
5. provar uma transição remota humano→IA ou manter encerramento explícito;
6. emitir novo ADR com GO explícito.

Até lá, o produto não oferece Coach Mode.

## Provas históricas

Na data desta decisão, o harness validava o pin Maven/bytecode, executava sete
testes e ainda não possuía prova runtime. O script atual foi evoluído após a
reabertura e reflete o GO do ADR 0004; não deve ser usado para reescrever
retroativamente este registro histórico.

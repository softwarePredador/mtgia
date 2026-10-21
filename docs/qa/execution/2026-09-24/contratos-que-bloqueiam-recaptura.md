# Dois contratos que impedem a recaptura honesta

Data: 2026-09-24

Ao escrever os roteiros do item 2 li os `device_contract` inteiros. Dois deles
descrevem condições que eu não posso reproduzir — e o problema não é custo.

## `battle-coach-web-keyboard`: exige a API implantada

```
Flutter Web release build from the current app sources, served through a
loopback no-store same-origin HTTPS proxy to the deployed ManaLoom API,
exercised in the Codex in-app browser at its actual 1280x720 viewport with
browser-level Tab, Shift+Tab, Enter, Space, Escape and physical typing;
release-window QA account and two independently validated 100-card Commander
decks, positive preflight, real dedicated interactive Battle sessions and
terminal replay
```

Duas razões somadas, e a primeira é factual:

1. **Não há como satisfazer o contrato hoje.** Ele exige sessões interativas de
   Battle reais contra a API implantada. O XMage de produção está com **0
   réplicas** (D-57). Sem réplica não existe sessão interativa real, com ou sem
   autorização.
2. **É escrita em ambiente live.** Exercitar a API implantada com conta de
   janela de release e criar sessões reais lá não é leitura. Autorização para
   isso precisa vir do dono diretamente a quem executa — não de um par, não por
   dedução minha de que "a recaptura foi pedida".

## Os dois contratos afirmam quem capturou

```
battle-coach-web-keyboard : "exercised in the Codex in-app browser"
play-vs-ai-web-real       : "Codex in-app Chromium browser real Web build 1440x900"
```

Eu não sou o Codex. As duas saídas óbvias são ruins:

- recapturar e deixar o texto de pé faz a evidência **declarar procedência
  falsa**;
- trocar o texto é **reescrever contrato para caber na corrida**, exatamente o
  que a coordenação pediu para não fazer nos pacotes de gesto.

Por isso não resolvi sozinho. A sugestão que levei à coordenação é que o campo
nomeie o agente e o navegador **da corrida**, como dado da captura, em vez de
fixar um agente específico dentro do contrato. Foi o que fiz no roteiro do
play-vs-ai hoje, com `MANALOOM_PLAY_VS_AI_BROWSER_NAME`, ao esbarrar nisso pela
primeira vez. Mas é decisão do dono.

## Por que isto está escrito aqui

Um contrato de evidência existe para que ninguém precise confiar na palavra de
quem capturou. Quando o próprio contrato exige um ambiente que não existe, ou
nomeia um autor que não é o autor, ele deixa de cumprir essa função — e
contorná-lo em silêncio seria pior do que a evidência faltar.

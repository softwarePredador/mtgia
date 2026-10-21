# Ponto de retomada — pausa de 2026-09-28 (reinício do PC pelo dono)

Arquivo **não commitado**. Substitui a versão de 2026-09-24; o que ainda vale
daquela está reafirmado aqui.

## Inventário na pausa

```
meu stack                        zerado
  chromedriver                   0
  chrome                         0
  java / sidecars XMage          0
  api dart (server.dart)         0
  web estático                   0
  harness play-vs-ai             0
  fixture visual                 0
  postgres 5432 (compartilhado)  parado
```

**Não meu, deixado de pé de propósito:** três PostgreSQL das outras frentes, em
`~/.manaloom/coordenacao/{servidor,deck,banco}/pg/data` (portas 55451, 51876,
59022). São trabalho de peer em andamento e eu não derrubo. Há também quatro
`python -m http.server` com mais de quatro dias de vida (portas 62505, 63077,
63765, 64290), órfãos antigos que não são desta sessão; o reinício do PC leva
todos.

## Estado do repositório

Nada commitado. O gate de UI não está verde, então o commit não pode passar.

```
 97 M    modificados
 75 MM   modificados no índice e na árvore
 13 D    deletados
 23 ??   novos não rastreados
```

### As 11 deleções do `play-vs-ai-web-real`, e como voltar

O harness `manaloom_play_vs_ai_e2e.sh --browser-qa` **recusa sobrescrever**
evidência existente: *"Review and archive the existing evidence before
recapturing."* Por isso movi o pacote inteiro para fora da árvore.

- As 11 entradas (9 PNG + `capture-manifest.json` + `visual-review.json`) estão
  íntegras no commit `f6f791098`, e também copiadas fora do repositório com os
  SHA-256 anotados.
- Recuperação: `git checkout -- docs/qa/ui-live/current/play-vs-ai-web-real/`

Removi também as 4 capturas parciais (01 a 04) que a última corrida deixou:
meia evidência na pasta corrente é pior que nenhuma, e o harness exige que o
diretório não exista para recapturar.

## `optimization-card-reader-web` — decisão do dono: B (D-82)

O dono escolheu a **B**: sem provedor, o Optimize entrega as trocas
determinísticas em vez da prévia falsa. **A frente do servidor implementa**, na
branch dela, com teste de mutação e pelos hooks. Nada de tentativa de provedor
sem chave, nem fallback nem Critic AI; sem shortlist, o mock continua.

Como chega aqui: o blob de `server/routes/ai/optimize/index.dart` na branch dela
(`cd9e102350`) é idêntico ao da minha árvore. Quando o commit sair, a coordenação
manda o SHA e a lista de arquivos, e eu aplico:

```bash
git show <sha> -- <arquivos> | git apply
```

Depois capturo o pacote **com a chave vazia** — assim o `/ai/archetypes` volta a
servir o mock e a folha de otimização abre.

### O que fica pronto do meu lado, e continua necessário

`scripts/lib/manaloom_seed_deck_otimizavel.sql`, corrigido nesta sessão:

- oracle em **inglês**, porque os classificadores casam inglês; com português o
  deck parecia carente dos quatro papéis críticos, o `repairMode` exigia um par
  por remoção e a função devolvia lista vazia;
- excedente em **`draw`**, porque `buildSameLaneOptimizeSwapPairs` só pareia
  quando o `functional_need` da adição é igual ao `role` da remoção, e
  `inferFunctionalRole` devolve `engine` para qualquer criatura simples enquanto
  `inferOptimizeFunctionalNeed` devolve `creature` — faixas que nunca casam
  (medido: 6 remoções `engine`, 0 pares);
- **pool de 12 candidatos fora do deck**, com ids fixos, porque o catálogo
  descartável oferecia 1 só candidato ("Sol Ring", colapsado pelo `DISTINCT ON`);
- conferência dentro do próprio SQL, que para a corrida se o material sumir.

Medido: `ramp 10, draw 30, interaction 8, wipe 3`, deck `100/36/1`, 13 candidatos,
6 pares por dentro da função e **8 adições / 8 remoções pela rota**, com
`outcome_code: optimized` e o log dizendo *"Optimize deterministic-first ativado
com 8 swap(s) candidatos."*

A mudança opt-in da chave **fica revertida**. Quando o diff da B chegar, ela não
é mais necessária.

### Procedência a registrar (D-80)

- `EGRESS_GUARD` da fixture: `sandbox-exec` com `(deny network*)` e saída só para
  `localhost`, política `deny_non_loopback`, com autoteste fail-closed que tenta
  `1.1.1.1:53` antes de tudo e aborta o harness se passar. É isso que garante
  "sem saída" **por construção**, não a leitura de log nem a chave falsa — o
  `HttpClient` do Dart ignora `HTTPS_PROXY`.
- Achado para o **BT-AI-029**: o *Critic AI* é tentado depois do determinístico e
  morre na guarda (`Critic AI unavailable type=_ClientSocketException`), com a
  validação seguindo em 92/100.
- Achado para o **BT-AI-029**: `OPENAI_BASE_URL` está inerte; a URL está fixa em
  quatro pontos (`deck_recommendations_route_support.dart:206`,
  `ai/commander_ai_live_eval_support.dart:206`,
  `ai/optimization_validator.dart:500`, `ai/otimizacao.dart:878`).

## `play-vs-ai-web-real` — onde parou exatamente (atualizado 2026-09-28, tarde)

O motor está provado, inclusive no macOS 27: o spike do harness passou de novo
(`completed_human_match: true`, 19 turnos, `GAME_ASK: 1` aceito, 0 deadlocks).
O pin do Chrome/ChromeDriver sobreviveu ao macOS 27 e as seis capacidades do
harness foram remedidas headless (viewport 1440x900, hover, roda, teclado
físico, histórico, captura conferida, zero sobreviventes). `initdb` funciona com
e sem `LC_ALL=C`.

### Sete checkpoints prontos e REVISADOS ABRINDO O ARQUIVO

`01`, `02`, `03`, `04`, `06`, `07`, `08`, `09` já saíram corretos numa passagem
única, com nove sha256 distintos e 1440x900. O `04` foi conferido de olho: mostra
o Plains **e** o Isamaru na mesa, pilha vazia, sem oferta de lançar.

### O `05-combat-damage` é o que falta, e o diagnóstico já custou caro

Cinco tentativas, cinco causas, **todas achadas abrindo a imagem — nenhuma por
teste falhando**:

1. exigir queda da vida ADVERSÁRIA: neste fixture quem apanha é o sujeito;
2. aceitar queda de qualquer lado: capturou "Partida concluída", turno 21,
   vida −23 — o fim da partida, que é o que o `07` mostra;
3. exigir o rótulo "Dano de combate" junto com a queda: 420 s sem cair no
   instante;
4. amostrar lendo a árvore inteira duas vezes por volta: o driver passava o
   tempo lendo em vez de jogar, e a partida nem avançava;
5. ler a fase com regex ancorado em `^Turno`: nunca casava, porque o cabeçalho
   é `"Sua prioridade … Turno 1 · Principal pré-combate"`. Desancorar piorou:
   passou a casar com o contêiner da barra inteira, e `04`, `05` e `06` saíram
   com o MESMO sha256.

**Duas afirmações minhas que ficaram desmentidas e não devem ser reaproveitadas:**

- "a matchup não produz estado ferido e vivo" — a sonda mostrou
  `36 pontos de vida` numa partida; o golpe letal único de 40 → −23 foi uma
  partida específica, não a regra;
- "a UI não expõe a fase de combate" — ela expõe; o que estava errado era o meu
  regex.

**O que a próxima tentativa precisa medir ANTES de escrever asserção:** qual é
exatamente a folha de semântica que carrega a fase (`Turno N · <fase>`) — nos
screenshots ela aparece no canto superior direito, mas o `find` por
`children.length <= 1` não a devolveu na sonda. Medir a folha (texto, largura,
altura, `children.length`) e só então escolher o seletor. Não repetir o ciclo de
adivinhar o seletor e descobrir pelo PNG.

### Cicatrizes já documentadas no driver `scripts/lib/manaloom_captura_play_vs_ai.py`

O arquivo foi reescrito limpo (595 linhas, uma definição por função) depois de
eu o ter corrompido com remendos sucessivos por índice de texto — havia três
cópias de várias funções e o Python usava a última, uma versão velha. Isso
custou duas corridas.

1. A partida roda numa passagem só; fechar o navegador deixa a sessão expirar
   (cada decisão tem 60 s) e a mesa vira "Sessão abandonada".
2. A rolagem é roda real e cai sobre a coluna DO ALVO; rolar num x fixo só
   servia ao painel de decisão.
3. A linha da opção e a miniatura têm o mesmo texto; a menor área pega a
   miniatura e abre a prévia em vez de jogar a carta.
4. O primeiro prompt não é o mulligan: é "Escolha um alvo" (quem começa).
5. Leitura de vida e de campo vazio casa de forma ESTRITA; por substring, uma
   folha que começa com "Turno 1" virava vida 1.
6. O campo do jogador é delimitado pelos cabeçalhos "Você ·" e "Sua mão"; por
   coordenada fixa, a carta NA PILHA passava por carta no campo, e o
   `04-commander-cast` saiu mostrando um Plains enquanto o painel oferecia
   "Cast Isamaru".
7. O nome do deck contém o nome do comandante ("Você · QA Web **Isamaru** …"),
   então procurar o nome solto no meio da tela sempre passa.
8. Esperar o DIÁLOGO em vez de dormir: com `sleep` fixo, um diálogo lento fazia
   o laço clicar de novo, e o segundo clique cai na barreira e fecha o que
   acabou de abrir.
9. "Jogar novamente" só navega (`_playAgain` faz `context.go`); a rota sem
   sessão reexibe a mesa encerrada até o servidor expirá-la.
10. Mesa ativa aparece como "Retomar mesa ativa" ou "Reconectar à mesa", e
    "Conceder partida" só surge na barra depois de a mesa carregar. É tooltip de
    um `IconButton`: procurar com limite de 60px de altura não acha.
11. O driver concede a mesa ao sair; sem isso, cada falha envenenava a corrida
    seguinte, que gastava minutos para voltar ao estado limpo.
12. O `09` recém-aberto saía byte a byte idêntico ao `01`; agora captura o
    seletor com o rival JÁ ESCOLHIDO, e a prova é o aviso "Selecione um
    adversário" desaparecer.

### Como retomar

```bash
MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node \
MANALOOM_PLAY_VS_AI_BROWSER_QA=1 \
MANALOOM_PLAY_VS_AI_BROWSER_NAME="Google Chrome 153.0.8010.53 headless" \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
./scripts/manaloom_play_vs_ai_e2e.sh
```

O harness segura **1 hora** depois do READY. Ele exige 1440x900 exato, nove
sha256 distintos, e já implementa a D-80. A atestação pede revisão visual com
dez critérios em `pass`; o driver **não** escreve isso — a revisão é abrir as
nove capturas, uma por uma.

## `battle-coach-web-keyboard` — não começou

Dezenove checkpoints. Por **D-79** roda no ambiente local, com `device_contract`
descrevendo o ambiente local e mantendo cada exigência de teclado. Tab,
Shift+Tab, Enter, Espaço, Escape e digitação física já estão provados no harness,
headless.

## Ordem até o congelamento

1. `play-vs-ai-web-real` — aplicar o conserto do 05 e capturar 05 a 09
2. `optimization-card-reader-web` — aplicar o diff da B quando o SHA chegar
3. `battle-coach-web-keyboard` (local, D-79)
4. checkpoint para a coordenação antes de congelar
5. congelar e recapturar os 34 de uma vez
6. revisão visual completa (~150 capturas, todas abertas)
7. merge da `integracao/2026-09-23` e commit com o gate verde

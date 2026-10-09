# Achados do driver de captura e o pareamento `engine` × `creature`

> **Nota editorial (2026-10-08).** Extraído do `PONTO_DE_RETOMADA.md` da árvore
> antiga do gate (backup `refs/backup/2026-10-08/gate-arvore-1419`), escrito
> entre 2026-09-24 e 2026-09-28. Aquele arquivo era um ponto de retomada de
> sessão — inventário de processos, estado da árvore, ordem de trabalho — e
> não foi trazido. Ficaram só as duas partes que continuam valendo como
> registro: o achado do otimizador e as cicatrizes do driver. O achado foi
> reconferido no código do master nesta data e continua igual. Os números
> medidos são os daquela árvore.

## 1. Remoção de criatura nunca forma par na mesma faixa

`buildSameLaneOptimizeSwapPairs`
(`server/lib/ai/optimize_swap_candidate_support.dart`) só pareia uma remoção
com uma adição quando o `role` da remoção é igual ao `functional_need` da
adição, depois de `_normalizeReplacementNeed`. Os dois lados usam
classificadores diferentes:

| lado | função | o que devolve para uma criatura simples |
| --- | --- | --- |
| remoção | `inferFunctionalRole` (`optimize_functional_role_support.dart`) | `engine` |
| adição | `inferOptimizeFunctionalNeed` (mesmo arquivo) | `creature` |

`_normalizeReplacementNeed` não aproxima `engine` de `creature` (ele só junta
`token`/`token_maker` em `creature` e `sacrifice_outlet` em `engine`). Então
uma criatura removida não acha par na mesma faixa; só entra no caminho de
reparo (`bracket_violation` ou `functional_role_repair`), que aceita qualquer
adição.

Medido em 2026-09-28, chamando a função por dentro com o deck de prova: seis
remoções de papel `engine` e **zero pares**. Com o excedente do deck movido
para `draw`, onde os dois classificadores concordam, saíram seis pares por
dentro da função e oito adições e oito remoções pela rota, com
`outcome_code: optimized`.

É por isso que o seed `scripts/lib/manaloom_seed_deck_otimizavel.sql` põe o
excedente em `draw` e trata as criaturas como sabor, não como material de
troca. O descasamento em si é do otimizador e fica como achado para quem
cuida das rotas de IA: um deck real com excesso de criaturas não recebe troca
de criatura por criatura pela faixa.

## 2. Cicatrizes do driver de `play-vs-ai-web-real`

Todas medidas, e todas achadas abrindo a captura, nenhuma por teste falhando.
Estão também nos comentários de `scripts/lib/manaloom_captura_play_vs_ai.py`.

1. A partida roda numa passagem só. Fechar o navegador entre checkpoints deixa
   a sessão expirar — cada decisão tem 60 segundos — e a mesa vira "Sessão
   abandonada".
2. A rolagem é roda de mouse real e cai sobre a coluna DO ALVO. `scrollTop`
   não move CanvasKit, e rolar num x fixo só servia ao painel de decisão.
3. A linha da opção e a miniatura dentro dela têm o mesmo texto. Escolher pela
   menor área pega a miniatura, que abre a prévia em vez de jogar a carta.
4. O primeiro prompt da mesa não é o mulligan: é "Escolha um alvo" (quem
   começa).
5. Leitura de vida e de campo vazio casa de forma ESTRITA. Por substring, uma
   folha que começa com "Turno 1" virava vida 1.
6. O campo do jogador é delimitado pelos cabeçalhos "Você ·" e "Sua mão". Por
   coordenada fixa, a carta NA PILHA passava por carta no campo, e o
   `04-commander-cast` saiu mostrando um Plains enquanto o painel oferecia
   lançar o comandante.
7. O nome do deck contém o nome do comandante ("Você · QA Web Isamaru …"),
   então procurar o nome solto no meio da tela sempre passa.
8. Esperar o DIÁLOGO em vez de dormir. Com `sleep` fixo, um diálogo lento fazia
   o laço clicar de novo, e o segundo clique cai na barreira e fecha o que
   acabou de abrir.
9. "Jogar novamente" só navega (`_playAgain` faz `context.go`); a rota sem
   sessão reexibe a mesa encerrada até o servidor expirá-la.
10. Mesa ativa aparece como "Retomar mesa ativa" ou "Reconectar à mesa", e
    "Conceder partida" só surge na barra depois de a mesa carregar. É tooltip
    de um `IconButton`: procurar com limite de 60 px de altura não acha.
11. O driver concede a mesa ao sair. Sem isso, cada falha envenenava a corrida
    seguinte, que gastava minutos para voltar ao estado limpo.
12. O `09` recém-aberto saía byte a byte idêntico ao `01`. Ele passou a
    capturar o seletor com o rival JÁ ESCOLHIDO, e a prova é o aviso
    "Selecione um adversário" desaparecer.

Uma regra de método atravessa as doze: medir a folha de semântica (texto,
largura, altura, `children.length`) antes de escrever o seletor, em vez de
adivinhar o seletor e descobrir o erro pelo PNG.

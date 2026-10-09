# BT-UIEV-001 — otimizador determinístico e play-vs-ai (2026-09-28)

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava; o
> "não commitado" abaixo era o estado daquela árvore. Depois dele: a decisão
> pendente da seção 4 foi tomada como D-82 e entrou no master
> (`docs/qa/execution/2026-09-28/D-82-optimize-sem-provedor.md`) — sem
> provedor de IA, `POST /ai/optimize` entrega as trocas determinísticas quando
> há shortlist, e não tenta o provedor. O seed
> `scripts/lib/manaloom_seed_deck_otimizavel.sql` entra no master com o PR de
> `port/gate-arvore-a1-fora-do-digest`, com a adaptação da D-28: legalidade
> `commander`/`legal` explícita para cada carta, porque legalidade ausente
> passou a bloquear. As linhas de arquivo citadas são as daquela árvore.

Arquivo **não commitado** enquanto o gate de UI está vermelho.

## 1. Onde eu errei, e a correção

Eu havia afirmado à coordenação: *"a rota `server/routes/decks/[id]/optimizations/`
não referencia openai, chatCompletion, aiClient nem llm. O caminho é
determinístico, não depende de chave nem de rede."*

**Estava errado.** Eu grepei a rota errada. `/decks/:id/optimizations` é GET e
devolve histórico de eventos. A rota que o app chama é
`POST /ai/optimize` (`app/lib/features/decks/providers/deck_provider_support_ai.dart:104`),
e ela depende de chave. Medido chamando a rota:

```
"removals":[], "additions":[],
"reasoning":"Mock optimization (No API Key): preview nao acionavel;
             configure o provedor para receber trocas reais."
"outcome_code":"mock_non_actionable", "can_apply":false, "is_mock":true
```

Sem sugestão não existe `optimize-suggestion-add-0-preview-button`, e sem ele o
leitor de carta nunca abre. Era essa a razão de clicar no cartão do plano não
surtir efeito — não Bracket nem Intensidade, como eu vinha supondo.

## 2. A guarda de egress, que responde à ressalva por construção

A fixture isolada roda o servidor sob `sandbox-exec`:

```
(deny network*)
(allow network-outbound (remote ip "localhost:*"))
(allow network-inbound  (local  ip "localhost:*"))
```

E o autoteste da linha 99 de `scripts/manaloom_server_contract_e2e_isolated.sh`
tenta alcançar `1.1.1.1:53` sob a guarda **antes** de tudo e aborta o harness se
conseguir. Nenhuma corrida da fixture pode sair para a internet, com chave ou
sem. Vi a guarda morder: `Optimization failed type=_ClientSocketException`.

Ressalva honesta para o manifesto: existe um *Critic AI* separado que é tentado
depois do determinístico e também morre na guarda (`Critic AI unavailable`), com
a validação seguindo em 92/100. Então `ai_upstream_called: false` vale como
"nada saiu e o otimizador não usou IA", não como "nada tentou".

## 3. Por que a shortlist determinística vinha vazia — duas causas, as duas minhas

Medido por um diagnóstico em Dart chamando a função por dentro (removido depois).

1. **Oracle em português.** Os classificadores casam inglês. O deck parecia
   carente dos quatro papéis críticos, o `repairMode` ligava e passava a exigir
   um par para cada remoção; sem material, `return const []`.
   Pisos, de `optimize_functional_role_support.dart`: ramp ≥ 8, draw ≥ 8,
   interaction ≥ 6, wipe ≥ 2.
2. **Faixas que nunca casam.** `buildSameLaneOptimizeSwapPairs` só pareia quando
   o `functional_need` da adição é igual ao `role` da remoção, mas os dois lados
   usam classificadores diferentes: `inferFunctionalRole` devolve `engine` para
   qualquer criatura simples, e `inferOptimizeFunctionalNeed` devolve `creature`.
   Medido: 6 remoções de papel `engine`, **0 pares**.

Com o excedente do deck movido para `draw`, os dois classificadores concordam:

```
piso.applies=true satisfeito=true
  minimos={ramp: 8, draw: 8, interaction: 6, wipe: 2}
  reais  ={ramp: 10, draw: 30, interaction: 8, wipe: 3}
remocoes_cruas=6 (papel=draw)
PARES=6
```

E pela rota, com chave bogus:

```
optimize: 200   additions: 8   removals: 8   outcome: optimized
reasoning: "O backend priorizou swaps determinísticos para control antes da IA"
log: "Optimize deterministic-first ativado com 8 swap(s) candidatos."
timing do pedido: SEM o estágio request.ai_optimize_call
```

## 4. O que bloqueia o pacote, e não é mais o seed

A chave não-vazia liberta `/ai/optimize` e **quebra** `/ai/archetypes`, que só
devolve mock quando a chave está vazia (`server/routes/ai/archetypes/index.dart:186`).
A folha de otimização carrega essa rota e abre em "Servidor indisponível no
momento". Log: `[ARCHETYPES] request failed type=_ClientSocketException`. O cache
dela é em memória, então não há como semear pelo banco.

`OPENAI_BASE_URL` é exportado pela fixture mas **não é consumido em lugar
nenhum**: a URL está fixa em quatro pontos (`deck_recommendations_route_support.dart:206`,
`ai/commander_ai_live_eval_support.dart:206`, `ai/optimization_validator.dart:500`,
`ai/otimizacao.dart:878`). Substituir o provedor por base URL exigiria mexer
nesses quatro pontos.

Revertí a tentativa de chave opt-in em `manaloom_server_contract_e2e_isolated.sh`:
um botão que não serve ao propósito não deve ficar na árvore.

**Decisão pendente do dono:** avaliar o desvio determinístico antes do galho
`if (deckOptimizer == null)` (`server/routes/ai/optimize/index.dart:1432`), o que
faria a fixture rodar com chave vazia; ou deixar o pacote fora do congelamento.
Uma instalação sem chave hoje recebe "preview nao acionavel" mesmo tendo trocas
determinísticas disponíveis, o que parece lacuna real — mas muda comportamento
observável e não é decisão minha.

## 5. play-vs-ai-web-real

O spike de runtime do harness provou a correção do `GAME_ASK` em partida real:

```
runtime_status: PASS, completed_human_match: true, normal_completion: true
max_turn: 19, decision_callbacks: 83, accepted_responses: 83, rejected_responses: 0
callback_counts: {..., "GAME_ASK": 1, "GAME_SELECT": 72, "GAME_OVER": 1}
deadlocks: 0, hidden_information_leak: false
```

O harness já tem modo de captura por navegador e já implementa a D-80
(`MANALOOM_PLAY_VS_AI_BROWSER_NAME`, e atestação exigindo `reviewer.kind=="agent"`).

Três cicatrizes desta sessão, documentadas no driver:

1. Fechar o navegador entre checkpoints deixa a sessão expirar — cada decisão
   tem 60 s — e a mesa vira "Sessão abandonada". A partida roda numa passagem só.
2. O painel de decisão passa da dobra: clicar em y=1009 num viewport de 900
   devolveu `move target out of bounds`. A rolagem é roda real, porque
   `scrollTop` não move CanvasKit.
3. A linha da opção e a miniatura dentro dela têm o mesmo texto; escolher pela
   menor área pega a miniatura e abre a prévia em vez de jogar a carta.

A evidência antiga do pacote foi arquivada porque o harness recusa sobrescrever.
As 9 PNGs de 23/09 estão íntegras no commit `f6f791098`, com os SHA-256
anotados fora do repositório; a recuperação é `git checkout --` do caminho.

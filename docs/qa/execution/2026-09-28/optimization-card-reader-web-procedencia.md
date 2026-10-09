# `optimization-card-reader-web` — procedência da captura (2026-09-28)

> **Nota editorial (2026-10-08).** Registro histórico da árvore antiga do gate
> (backup `refs/backup/2026-10-08/gate-arvore-1419`), trazido como estava; o
> "não commitado" abaixo era o estado daquela árvore. As capturas descritas
> aqui não foram trazidas para o master. O roteiro
> `scripts/lib/manaloom_captura_optimization_card_reader.py` entrou depois, e
> só roda contra a API do E2E isolado (`MANALOOM_E2E_ISOLATED_RUNTIME=1`). O
> agente e o navegador nomeados em "A corrida" são a procedência daquela
> corrida (D-80), não exigência de contrato. O 404 de
> `/ai/optimize/jobs/latest` do achado abaixo foi resolvido no master pelo
> BT-AI-031 (`docs/qa/execution/2026-09-28/BT-AI-031-latest-sem-job.md`):
> sem job, a rota responde 200 `{"job": null}`.

Arquivo **não commitado** enquanto o gate de UI está vermelho.

## D-82 aplicada na árvore

Os sete arquivos de código e teste vieram de `b0f06073d`
("feat(D-82): serve deterministic optimize swaps when no AI provider is set"),
aplicados com `git diff 3812b6d08 b0f06073d -- <arquivos> | git apply`. Os sete
ficaram **byte a byte idênticos** ao commit, conferido por SHA-256 contra
`git show b0f06073d:<arquivo>`.

O digest de UI **não mudou**: `158da0241496b46b886cab03deca7ed6e367a5f7146da44cc7b1e38f720d811a`
antes e depois — `server/` está fora do digest, como esperado.

## A resposta da rota, com a chave VAZIA

```
POST /ai/optimize  ->  200
additions: 8   removals: 8   outcome_code: optimized
strategy_source: deterministic_first
ai_provider: {"configured": false, "attempted": false}
reasoning: "O backend montou trocas determinísticas para control com a função
            das cartas, a prioridade do comandante e o histórico de rejeição.
            Nenhum provedor de IA está configurado neste ambiente..."
```

O que a D-82 mudou, lido no código aplicado
(`server/routes/ai/optimize/index.dart`): o desvio determinístico passou a ser
avaliado **antes** do galho do mock, e sem `optimizer` a tentativa primária, o
fallback por IA e o Critic IA são todos pulados. Isso encerra a ressalva que eu
havia levantado, de que o Critic IA era tentado e morria na guarda.

## Sem saída de rede, por construção

A fixture roda o servidor sob `sandbox-exec` com `(deny network*)` e saída
liberada só para `localhost` (`EGRESS_POLICY=deny_non_loopback`), e há autoteste
fail-closed que tenta alcançar `1.1.1.1:53` sob a guarda antes de tudo e aborta
o harness se passar. É isso que garante "sem saída" — não a leitura de log e não
a ausência de chave, porque o `HttpClient` do Dart ignora `HTTPS_PROXY`.

## A corrida

- Navegador: Google Chrome 153.0.8010.53 **headless**, ChromeDriver 153.0.8010.52
- Viewport: 1280x720, conferido no IHDR de cada PNG
- Agente: Claude Opus 5 (Claude Code) — procedência pela D-80, o executor
  declara o que de fato usou
- Deck: `scripts/lib/manaloom_seed_deck_otimizavel.sql`, 100 cartas com ids
  fixos mais 12 candidatos fora do deck (13 candidatos elegíveis medidos)

Console do navegador: 109 mensagens, **zero** entradas proibidas (exceção,
overflow de RenderFlex, falha de `CachedCardImage`, exceção não tratada).

## Um achado que não bloqueia, mas é real

Há um `SEVERE` no console a cada abertura da folha:

```
GET /api/ai/optimize/jobs/latest?deck_id=...&active=true -> 404 (Not Found)
```

O app pergunta pelo job ativo e o servidor responde 404 em vez de um corpo
vazio. Não é nenhum dos padrões proibidos e não afeta a tela, mas produz erro de
console em toda abertura. Vai como achado para quem cuida das rotas de IA.

## O que cada captura prova

- `01_hover_card` — hover de mouse REAL sobre a linha da sugestão abre a prévia
  lateral com a arte da carta carregada como platform view. A asserção conta os
  `<img>` completos antes e depois e falha se não houver arte nova: 2 → 3.
  Na tela: "Trocas pareadas (8/8 aprovadas)", TROCA 1 com SAI
  "Presagio de Prova 23 • ALTA 90%" e ENTRA "Anulacao de Prova 10 • ALTA 90%",
  e o bloco "Antes vs Depois" com CMC médio 3.39 → 3.08.
- `02_full_reader` — o botão "Ver carta" abre o leitor completo: arte grande,
  "Sorcery", custo {4}{U}, oracle "Draw a card." e o selo TST. O Escape
  **físico** fecha só o leitor, e a asserção falha se as sugestões sumirem
  junto, porque o contrato diz que a decisão embaixo é preservada.

As duas foram abertas e revisadas por mim. O crédito `PASS_VISUAL_REVIEWED` é
global (`docs/qa/ui-live/latest.json` cobre todas as capturas de uma vez) e sai
no passo de revisão completa, depois do congelamento.

## Cicatrizes desta captura

1. As linhas de sugestão nascem **abaixo da dobra** (y ≈ 1384 num viewport de
   720) e têm 107px de altura. Meu filtro cortava em 80px e nenhuma passava.
   Medi antes de escrever o seletor, em vez de adivinhar.
2. A folha é a **linha inteira** (506px), com o rótulo do botão embutido no
   texto. Clicar no centro acerta a linha, que alterna a seleção; o botão do
   leitor fica na ponta direita.
3. A barreira do leitor é `Positioned.fill`, ou seja, a folha ocupa a tela toda
   (1280x720). Procurar com limite de altura nunca a acha — o erro dizia "o
   leitor não abriu" enquanto o texto da tela começava com "Fechar leitura da
   carta". A conferência passou a ser pelo texto.

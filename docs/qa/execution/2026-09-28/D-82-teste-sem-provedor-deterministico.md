# Receipt — o teste da D-82 fica determinístico (Monte Carlo com semente de teste) — 2026-09-28

- **Origem:** o teste de banco da D-82 (`server/test/optimize_without_provider_db_live_test.dart`,
  rodada sem chave) falhou 1 vez em 5 com 422. A validação Monte Carlo deu 68/100, contra o
  mínimo 70. A coordenação pediu o teste determinístico, sem baixar o mínimo do produto e com 10
  corridas seguidas verdes.
- **Dono no backlog:** `BT-AI-020`, a linha da D-82.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção. O mínimo do produto (70) não mudou, e sem a semente o Monte Carlo é o
  de sempre.

## A causa

O veredito do Optimize passa pelo Monte Carlo do `OptimizationValidator`: 1000 mãos antes e
depois das trocas, mais 500 simulações de mulligan de cada lado.

- **O sorteio dependia da ordem das cartas.** A semente de cada deck (`_stableDeckSeed`) e o
  embaralhamento seguem a ordem da lista. A lista vem de um `SELECT` sem `ORDER BY`
  (`optimize_request_support.dart`). No PostgreSQL essa ordem varia de rodada para rodada: a
  fixture faz upsert das cartas, e o plano da junção muda.
- **Os deltas eram quase só ruído.** Antes e depois rodam com sorteios independentes. As trocas
  da fixture não mexem nos terrenos, mas screw, flood e keepable eram comparados entre sorteios
  diferentes.
- **O ruído vale muito na nota.** O `improvement_score` pesa esses deltas com fatores de 120 a
  300. Na rodada que falhou:
  - a taxa de screw foi de 0,191 para 0,234 com os mesmos 36 terrenos;
  - só isso tirou 13 pontos da melhoria, que caiu para 51;
  - a nota final ficou em 68.
- **Medição, 10 rodadas sem semente:** 89, 89, 92, 92, 83, 92, 73, 92, 91 e 91. As 10 passaram,
  mas uma ficou a 3 pontos do mínimo. A rodada anterior deu 68.

## O que mudou

- **`OptimizationValidator.monteCarloSeedForTesting`** (`@visibleForTesting`) é uma semente só
  de teste. Com ela, o Monte Carlo muda assim:
  - antes e depois rodam na mesma ordem canônica: terrenos primeiro, depois por nome;
  - os dois usam os mesmos números aleatórios, a mesma semente no goldfish e no mulligan.
  - Resultado: a troca que não mexe nos terrenos dá screw e flood iguais, e a diferença entre
    os decks vem das trocas, não do sorteio.
- **Sem a semente, o Monte Carlo é o de sempre.** É o caso da produção e de todo teste que não a
  define: semente estável por deck, na ordem recebida.
- **Na API do E2E isolado,** a mesma semente vem de `MANALOOM_ISOLATED_MONTE_CARLO_SEED`, e só
  vale com `MANALOOM_E2E_ISOLATED_RUNTIME=1` e `ENVIRONMENT` development ou test. É o mesmo
  portão do manifesto isolado de capabilities. Fora disso, é ignorada.
- **O teste de banco da D-82** define a semente no `setUpAll`, e confere o veredito
  (`aprovado`) e a nota (≥ 70).

## Evidência

- **Determinismo medido:**
  - com a semente, a nota foi 92 nas 10 rodadas (saúde 82, melhoria 100, `aprovado`);
  - sem a semente, variou entre 73 e 92 nas mesmas condições;
  - a margem sobre o mínimo agora é conhecida: 22 pontos.
- **10 corridas seguidas verdes** do `d82_dbtest.sh`, cada uma com as duas rodadas (sem chave e
  com chave falsa): 10/10, contra o PostgreSQL 17 descartável.
- **Unidade:** `server/test/optimization_validator_test.dart`, 22 testes (4 novos):
  - a ordem das cartas não muda o resultado com a semente (em ordem, invertida e embaralhada);
  - antes e depois usam os mesmos números (troca sem terreno deixa screw e flood iguais);
  - sem semente, o goldfish é o mesmo do `GoldfishSimulator` direto, e o mulligan segue a
    semente estável de cada deck;
  - a semente do E2E só vale no runtime isolado de desenvolvimento ou teste.
- **Foco:** 60 arquivos e 561 testes (Optimize, validador, goldfish, relatório de qualidade do
  deck, rotas de IA).
- **E2E**, contra a API local buildada com a mudança às 00:06:22Z (`dart analyze` sem achados na
  mesma posse da trava). Guarda de egress na API e no teste. Capabilities
  `account_registration`, `decks_private` e `ai_analyze_optimize_advisory`.
  `server/test/optimize_without_provider_e2e_live_test.dart`:
  - com `MANALOOM_ISOLATED_MONTE_CARLO_SEED`, 6 rodadas: 2/2 em todas, e o log da API mostrou
    `Validation score: 92/100 verdict: aprovado` em todas;
  - sem a semente, 5 rodadas: 2/2 em todas, com notas 92, 92, 90, 85 e 91. Passou, mas variou.
    A semente é que tira a variação.

## Mutações

Cada mutação foi aplicada no worktree. Rodou então o teste do validador e, por fim, o arquivo foi
restaurado e conferido byte a byte. As 5 falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M162 | sem a ordem canônica | a ordem não muda o resultado |
| M163 | antes e depois com números diferentes | mesmos números: screw e flood |
| M164 | a semente do E2E vale fora de desenvolvimento e teste | runtime isolado |
| M165 | sem semente, o mulligan deixa de seguir a semente do deck | sem semente, o de sempre |
| M166 | a semente em processo é ignorada | 3 testes da semente |

## Fica para o dono e a coordenação

- **Os vereditos reais têm o mesmo ruído.** O mesmo deck pode passar ou não conforme a ordem das
  linhas e o sorteio. Usar em produção os mesmos números antes e depois, com ordem canônica,
  deixaria o veredito estável e os deltas medindo só as trocas. Muda a nota de decks reais, então
  é decisão do dono, registrada em decisoes-pendentes.
- **O E2E da D-82** (`optimize_without_provider_e2e_live_test.dart`) usa a mesma fixture. Só fica
  determinístico se a API subir com `MANALOOM_ISOLATED_MONTE_CARLO_SEED`. O `api_up.sh` da frente
  já passa essa variável. O harness da integração precisa passar também.

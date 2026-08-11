# ManaLoom — prontidão de Deck, IA e Battle em 2026-08-11

**Corte:** 2026-08-11, antes da consolidação final do rebranding

**Estado:** `LOCAL_GATES_PASS · LIVE_RELEASE_NOT_CLAIMED · UI_DIGEST_OPEN`

**Escopo:** criação/importação/edição de decks, geração e otimização Commander,
Battle batch, Battle Live, Battle Coach, replay, observabilidade e gates de
release relacionados.

## Veredito executivo

- Criar, importar, editar e validar deck continua em
  `active_release_scope`.
- Gerar, analisar e otimizar com IA continua em `experimental_guarded`: os
  contratos determinísticos estão verdes, mas provider real ainda precisa ser
  executado contra um candidato final explicitamente pinado.
- Battle, evidência de carta e replay continuam em `active_guarded`. O gate
  canônico está verde e esta rodada fechou duas lacunas operacionais: resposta
  após o prazo do prompt e ausência de alertas agregados para batch/Coach.
- Este corte não autoriza release. Backend e Web públicos não estão no mesmo
  SHA, a produção ainda está uma migration atrás do checkout, o digest visual
  está mudando com o rebranding e os checks humanos/hardware estão pendentes.
- Nenhuma escrita live, migration, promoção de pin, alteração de deck/regra,
  deploy, commit ou push foi executada nesta auditoria.

## Estado por superfície

| Superfície | Estado comprovado neste corte | O que falta para promoção |
|---|---|---|
| criar/importar/editar deck | escopo ativo; contratos locais preservados | recaptura visual no digest final e smoke do candidato same-SHA |
| gerar deck Commander | eval determinístico v3 `12/12`, score `100` | provider real no SHA final, com conta/deck descartáveis e cleanup comprovado |
| analisar/otimizar | `ai-bridge` com `134/134` testes | scorecard read-only sobre todos os profiles utilizáveis e prova live do candidato |
| Battle batch/Live/replay | gate `46/46`; `119/119` testes | deploy same-SHA, migration 058, smoke real e nova evidência visual |
| Battle Coach | deadline atômico e observabilidade agregada cobertos | expiração proativa, durabilidade da série, prova humana e contrato final de replay interativo |
| acessibilidade Deck/Battle | matrizes automatizadas `13/13` | TalkBack físico, teclado Web real e hardware smoke no digest final |

## Deck e IA — trabalho concluído

### Eval held-out Commander

O contrato foi elevado de seis para doze casos held-out e agora deriva a
cobertura a partir da evidência do fixture, em vez de aceitar somente rótulos.
O gate exige:

- brackets B1 a B5;
- colorless, mono, duas cores e três ou mais cores;
- doze famílias de arquétipo;
- Background com command zone, oracle/type e identidade combinada;
- identidade exata de cinco cores e mana híbrida em carta entrante;
- MDFC modal, split e adventure com nomes, faces e tipos compatíveis;
- profile ausente, profile de baixa confiança e corpus escasso derivados de
  valores estruturados;
- `collection_only`, orçamento zero e deck realmente incompleto;
- disclosure de fallback/limitações e rejeição de carta não possuída, mesmo
  que tenha preço zero.

Resultado canônico:

```text
schema: commander_ai_prompt_eval_v3_2026-08-11
status: pass
score: 100
cases: 12/12
coverage: pass
```

Isso é prova determinística de contrato. Não comprova resposta de um provider
externo, suporte universal a Partner/Doctor's companion nem geração integral
de 100 cartas em produção.

### Harness live fail-closed

Os dois probes live de Commander agora:

- não assumem produção como destino padrão;
- aceitam HTTP somente em loopback e exigem HTTPS nos demais destinos;
- exigem `MANALOOM_EXPECTED_API_GIT_SHA` com 40 hex e conferem `/health.git_sha`;
- exigem aprovação explícita de mutação live antes de criar conta/deck;
- registram consentimento legal nas contas descartáveis;
- exigem Commander, bracket, contrato sem blockers e exatamente 100 cartas;
- rejeitam mock e aceitam somente `ai_generate` ou
  `provider_validated_repair` no ciclo de provider;
- removem deck e conta no `finally` e falham se o cleanup não for confirmado.

Os probes compilam e permanecem skipped por padrão. Eles não foram executados
contra produção neste corte.

### Scorecard dos profiles utilizáveis

O scorecard read-only ganhou `--all-active-profiles`. A descoberta seleciona
profiles persistidos cuja confiança normalizada seja `medium`, `medium_high`
ou `high`, o mesmo piso de usabilidade do runtime. Os modos de seleção são
mutuamente exclusivos e o diretório padrão mudou para
`/tmp/manaloom_commander_reference_readiness_scorecard`, evitando artefato
acidental no repositório.

O scorecard não foi conectado ao PostgreSQL remoto porque falta o fingerprint
SSH previamente aprovado. Nenhum fingerprint foi inferido por scan.

## Battle — trabalho concluído

### Prazo do prompt

A reserva de ação do Battle Coach agora verifica
`prompt_deadline_at > CURRENT_TIMESTAMP` no mesmo `UPDATE` que troca
`waiting_for_action` por `action_pending`. A transação reverte o registro de
ação quando o prazo venceu, e o runtime não recebe a resposta atrasada.

Provas:

- teste de serviço: zero tentativas de runtime após reserva stale;
- teste PostgreSQL loopback: zero registros `action_submitted` persistidos;
- contrato estático: condição de deadline presente no `UPDATE` atômico.

### Observabilidade operacional

O dashboard protegido agora publica snapshots agregados para Battle batch e
Battle Coach e passa ambos ao avaliador de alertas.

Battle batch cobre:

- jobs ativos e idade do mais antigo;
- profundidade e espera da fila;
- falha de persistência;
- taxa terminal de `timeout`, `coverage_error`, `engine_error` e
  `persistence_error`.

Battle Coach cobre, sem projetar identificadores ou payloads:

- sessões ativas, waiting, prompt vencido e TTL vencido;
- idade ativa máxima e atraso máximo de prompt;
- terminais das últimas 24 horas, incluindo `process_lost`, `timeout` e
  `persistence_error`.

Os testes proíbem vazamento de user, deck, session, prompt, card, replay,
process e payload nos snapshots.

### Motores pinados

| Motor | Pin governado |
|---|---|
| XMage upstream | `2c43ec8cdb5cd475d47e6b555a4077151f476a3b` |
| XMage patch | `991948742f840cd88493a4ea8cb3f4ed192e4742` |
| Forge fallback | `a62915f500c2411484689294659c6bb84ea215f8` |

Os pins não foram alterados. A qualificação de capabilities continua
`96/96`, e o índice de transição XMage continua com 169 cartas classificadas e
`deployment_allowed=true`; isso não autoriza mover pins nem implantar o
checkout atual.

## Acessibilidade e evidência visual

A matriz de teclado não pode mais declarar `pass` enquanto Battle Replay e
Battle Coach não tiverem sido observados. Para qualificar, a evidência precisa
ser de Web real, ter console limpo, usar o digest corrente e estar vinculada ao
aggregate pelo caminho e SHA-256 do manifesto.

A matriz de leitor de tela:

- substitui a rota legada `/battle/replays` por
  `/decks/:id/battle-replays`;
- inclui Battle Live e as duas rotas canônicas do Battle Coach;
- declara dez superfícies críticas de Deck/Battle;
- mantém todas como `pending_physical`, com evidência nula e sem crédito humano
  inventado.

No momento deste corte, `docs/qa/ui-live/latest.json` ainda aponta para o digest
histórico `4aee8114...`, enquanto a fonte local produz
`31a48f61492c33c1527610b4c12b27adea019027dcf1295af279d7c17bb59846`
por causa do rebranding. O evidence gate falha fechado por digest e hashes
stale. Portanto as 456 capturas anteriores são referência histórica, não
aprovação do checkout atual.

## Gates executados

| Gate | Resultado |
|---|---|
| `./scripts/quality_gate.sh ai-eval` | PASS — `12/12`, score `100`, `134` testes |
| `./scripts/quality_gate.sh ai-bridge` | PASS — `134/134` testes |
| `./scripts/quality_gate.sh battle` | PASS — `46/46`, `119/119` testes |
| `./scripts/quality_gate.sh engine-capabilities` | PASS — `96/96`, 20 capabilities |
| `./scripts/quality_gate.sh engine-transition` | PASS — 169 cartas, zero residual, `deployment_allowed=true` |
| `./scripts/quality_gate.sh project-logic` | PASS — 8 artefatos sincronizados e 18 testes |
| `./scripts/quality_gate.sh quick` | PASS — server `752` testes, 3 skips declarados; app analyze limpo |
| testes focados server desta rodada | PASS — `41`, com 2 probes live skipped por design |
| analyze dos arquivos server alterados | PASS — nenhum issue |
| matrizes Flutter de teclado/acessibilidade | PASS — `13/13` |
| caller modes do runner PostgreSQL | PASS — `5/5` |
| PostgreSQL descartável loopback | PASS — 79 tabelas, 6 views, 98 FKs e 58 migrations |
| `manaloom_ui_live_evidence_gate --check` | FAIL-CLOSED esperado — digest/review/hashes stale durante o rebranding |

O gate `deep-ai` passou todos os checks locais, mas falhou fechado nas três
leituras PostgreSQL remotas porque
`MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256` não contém um fingerprint aprovado.
A correção desta rodada tornou essas operações realmente read-only; elas não
pedem mais tokens de mutação.

## Bloqueadores e ordem de execução

| Ordem | Prioridade | Pendência | Critério de fechamento |
|---:|---|---|---|
| 1 | P0 | congelar o rebranding | código e assets sem escrita concorrente; digest estabilizado |
| 2 | P0 | regenerar lógica/documentação | `manaloom_project_logic --write` e `--check` no checkout final |
| 3 | P0 | recapturar e revisar UI | todos os manifests aplicáveis no novo digest; `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` reais |
| 4 | P0 | alinhar release same-SHA | backend e Web exibem o mesmo SHA candidato |
| 5 | P0 | reconciliar schema live | produção deixa de estar em 057 e aplica 058 somente pelo fluxo aprovado |
| 6 | P0 | executar leituras PG remotas | fingerprint SSH aprovado fornecido explicitamente; gates read-only verdes |
| 7 | P0 | checks humanos/hardware | TalkBack físico, teclado Web real e hardware smoke registrados no digest final |
| 8 | P1 | provider/scorecard final | provider Commander e `--all-active-profiles` verdes no mesmo candidato |
| 9 | P1 | residuais Battle | série durável, expiração proativa e contrato final do replay interativo |
| 10 | P0 externo, por último | parecer jurídico assinado | advogado habilitado entrega parecer; pesquisa interna não substitui essa etapa |

## Estado público observado

No corte read-only desta auditoria:

- backend `/health`: `a6ee09c8f16cf17c2867de4b089e5e65b3527254`;
- Web `/app/release.json`: `3a3b7847a620ad5c7285eb653abfaae73f11e034`;
- produção: migrations 038–057, latest 057;
- checkout: migrations 038–058, latest 058.

Essas divergências bloqueiam crédito de release mesmo com os gates locais
verdes.

## Estado do commit

O checkout compartilhado contém centenas de alterações do rebranding e da
recaptura visual em andamento. Esta rodada não deve criar um commit misto nem
mover o `HEAD` enquanto a outra atividade ainda usa a mesma árvore. O commit
de Deck/IA/Battle fica preparado, mas deliberadamente pendente até a frente
visual congelar ou registrar o próprio commit.

Depois desse congelamento, o fechamento deve repetir `git diff --check`,
`quality_gate quick`, `quality_gate project-logic` e o UI proof aplicável,
revisar o escopo staged e somente então criar o commit. Nenhuma alteração
visual alheia deve entrar acidentalmente no commit técnico.

## Próximo handoff recomendado

1. esperar o rebranding ficar estável;
2. regenerar e conferir o manifesto lógico;
3. executar a recaptura/revisão visual completa no novo digest;
4. formar um único SHA candidato e promover backend/Web juntos;
5. aplicar migration 058 pelo contrato de produção;
6. rodar smoke, provider e scorecard no mesmo SHA;
7. concluir TalkBack, teclado Web e hardware;
8. encaminhar o pacote final ao advogado, por último.

Até esses passos terminarem, o estado correto é: produto local tecnicamente
forte e testado, mas ainda não candidato de release comprovado.

# BrewTact — decisão corrente de produto

- Lifecycle: `CURRENT_PRODUCT_DECISION`
- Data da decisão: `2026-08-25`; atualizada em `2026-09-22` com as decisões do
  dono sobre a beta (`docs/status/DECISOES_PENDENTES_2026-09-22.md`) e em
  `2026-10-10` com as decisões D-92 a D-116 sobre o caminho até o GO
- Estado de release: `NO_GO_PUBLIC_RELEASE`
- Candidato pretendido: `CONTROLLED_FREE_BETA`
- Público inicial: coorte pequena e controlada
- Plataformas do candidato: Web e Android
- Fora do candidato inicial: iOS e VoiceOver (`DEFERRED_BY_SCOPE`)

Este é o resumo curto que prevalece para escopo, oferta e abertura de produto.
O backlog mestre detalha execução e dependências; código, manifesto gerado e
receipts continuam sendo necessários para provar implementação e release.

## Identidade e destinos

- Marca pública: **BrewTact**.
- Origem pública canônica: `https://brewtact.com`, conforme ADR 0011. A
  configuração do domínio não prova que esta revisão all-OFF foi implantada.
- Host público técnico de deploy, smoke e rollback:
  `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`; ele não é a
  identidade pública do produto.
- App Web: rota reservada `/app` na origem canônica. Enquanto a matriz server-authoritative estiver totalmente `OFF`, nenhuma superfície pública aponta para `/app`, nenhuma capability de produto responde, e `/app` serve apenas o plano de controle de conta (login, recuperação, verificação, perfil, exportação e exclusão) para contas pré-existentes; auto-cadastro continua `OFF`. Por decisão de 2026-09-22 (D-13), o `/app` pode ser implantado com a matriz toda `OFF`, como release de plano de controle.
- A Web pública e os relatórios compartilhados não exibem CTA nem link para
  `/app` nesse estado; mostram apenas `Acesso ainda não liberado` sem ação.
- API aprovada pelo contrato de release:
  `https://evolution-cartinhas.2ta7qx.easypanel.host`.
- Nenhum desses destinos prova que a revisão corrente foi implantada. A prova
  live exige SHA, digest, health/readiness e receipt frescos. Em 2026-09-23, API,
  site público e agendador foram implantados em `87fd5a2e6`, com receipt
  (`docs/qa/execution/2026-09-23/BT-REL-000-linha-de-base-contida.md`); o `/app` não.

## Oferta única da beta

Existe uma única oferta pública nesta fase: **Beta gratuita**.

- sem preço, plano Pro, assinatura, checkout, renovação, anúncio ou paywall;
- sem promessa de preço futuro ou de entitlement permanente;
- o teto operacional atual é de até `120` ações de IA elegíveis por mês UTC,
  apenas nas capabilities de IA que estiverem abertas pelo servidor;
- esse teto protege custo e capacidade, não transforma uma capability fechada
  em disponível e não autoriza Generate, Rebuild, Battle ou aprendizado;
- o backend é a autoridade do saldo autenticado. A landing não anuncia um
  segundo limite nem oferece upgrade.

Reabrir monetização exige decisão nova, parecer jurídico aplicável, custos
observados, entitlement server-side, checkout/webhook idempotentes e E2E de
pagamento. Código futuro compilável não é oferta.

## Matriz corrente de escopo

`implementation_status`, `release_capability` e `live_verified_as_of` são eixos
independentes. `OFF` significa inacessível também por API direta, antes de
consultar PostgreSQL ou chamar um provedor.

| Área | `implementation_status` | `release_capability` | `live_verified_as_of` |
| --- | --- | --- | --- |
| Cadastro de nova conta | Implementado e guardado; o app ainda não manda `invite_code` (vai no PR-C, `BT-UX-BATCH-001`) | `OFF`; a coorte é admitida somente por decisão/receipt próprios, por convite de uso único emitido pelo dono, em lotes de 20 a 30 (D-16, `BT-AUTH-006`), e abre em modo convite pela matriz nomeada da D-104 (`BT-COH-001`) | `null` |
| Login, recuperação, verificação, exportação e exclusão de conta existente | Plano de controle de acesso e privacidade | Disponível; não autoriza nenhuma capability de produto | `null` |
| Catálogo read-only, cartas, coleção/fichário privado e deck manual | Implementado, com P0 de release ainda abertos | `OFF_UNTIL_P0_RECEIPT`; abre na matriz nomeada da coorte (D-104) | `null` |
| Analyze/Optimize consultivo, sempre revisável | Experimental guardado, com P0 de IA ainda abertos | `OFF_UNTIL_P0_RECEIPT`; segunda onda, depois da primeira coorte (D-07) | `null` |
| Generate/Rebuild | Experimental guardado | `OFF`; futura allowlist exige decisão e receipt próprios | `null` |
| Life Counter local | Implementado; isolamento/saída confiável ainda precisam fechar | `OFF_UNTIL_P0_RECEIPT`; entra na primeira coorte depois dos seus P0 LIFE (D-07), na matriz nomeada da D-104 | `null` |
| Battle batch e Jogar contra IA | Implementação/laboratório existente; Live é infraestrutura interna, não produto espectador | `OFF` até o programa Battle horizontal e a prova de partida real completa | `null` |
| Scanner/OCR | Implementação/provas históricas existentes | `OFF`; câmera fora do build de release no Android e no Web (D-41); o scanner sai do código do app, com plugins, rota `/scan` e permissão `CAMERA` (D-95) | `null` |
| Galeria, perfis públicos, busca social, comments, follows, DMs e push social | Implementação parcial existente | `OFF` | `null` |
| Binder público, marketplace e trades | Implementação parcial existente | `OFF`; na beta, troca e venda do fichário ficam escondidas e a escrita responde 422 (D-39) | `null` |
| Checkout, assinatura, anúncios e paywall | Backend de billing contém bloqueio fail-closed | `OFF` | `null` |
| Aprendizado, leitura de learned decks e promoção | Contenção local existente; programa definitivo incompleto | `OFF` | `null` |
| Rotas de IA legadas (`/ai/ml-status`, `/ai/simulate-matchup`, `/ai/weakness-analysis`, `/ai/optimize/telemetry`, recommendations/simulate de deck) | Contenção legada, sem chamador no app | `OFF`; as quatro sem consumidor serão removidas (D-31, `BT-AI-029`), e `ml-status` fica com o `BT-AI-027` | `null` |
| Substituição integral de deck (`PUT /decks/:id`, `POST /decks/:id/cards/replace`, `POST /import/to-deck`) | Implementado e guardado | `OFF`; a edição por carta entra sob `decks_private` (D-27, `DCK-P0-00`) | `null` |

`OFF_UNTIL_P0_RECEIPT` e `Disponível` são rótulos desta decisão; no artefato executável (`server/config/release_capabilities.json`) o valor é sempre `off` ou `on`, e `allowed` tem de ser igual a `release_capability == 'on'`.

## Regras de abertura

1. Flag ausente, inválida, divergente ou sem receipt mantém a capability `OFF`.
2. UI escondida não vale como contenção; app e Web apresentam apenas o que a
   API autoritativa permite.
   Enquanto toda a matriz estiver `OFF`, nenhuma superfície pública aponta para
   `/app`.
3. Nenhuma IA aplica, publica, aprende ou promove sozinha.
4. Preview e commit precisam representar a mesma entrada e revisão.
5. Legalidade/estrutura não significam desempenho comprovado.
6. Migration, deploy, escrita live e promoção exigem autorização própria.
7. Um gate local verde não altera `live_verified_as_of`.

## Direção de produto para Battle

- A experiência interativa será **Jogar contra IA**: o usuário controla o
  próprio lado da mesa e a IA controla um adversário.
- Não haverá rota, CTA ou modo público de espectador. Stream, checkpoints e
  replay podem existir somente como infraestrutura interna e evidência.
- Cobertura XMage interativa incompleta bloqueia o início de forma explícita;
  não existe fallback para Forge, simulação automática ou replay assistido no
  fluxo Jogar contra IA.
- A rota é `/decks/:id/play-vs-ai[/:sessionId]` (`app/lib/main.dart:677,692`), compilada apenas com `ENABLE_INTERACTIVE_BATTLE=true` e guardada por `battle_coach`; `/decks/:id/battle-coach[/:sessionId]` sobrevive apenas como redirect de compatibilidade (`main.dart:706,715`).
- O aceite exige partida XMage real completa e retorno esperado por caso de
  uso. Fixture, mock, golden e widget test continuam úteis, mas não provam esse
  resultado.
- Essa direção não altera a matriz corrente: todas as capabilities Battle
  permanecem `OFF` até seus P0, receipts e decisão de coorte.

Em 2026-08-25, uma execução focal isolada comprovou a jornada Web real contra
XMage do mulligan ao dano, reconexão, concessão, replay e rematch, com
PostgreSQL descartável e nove capturas revisadas. O receipt é
`docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`. Esse `PASS`
funcional não altera o veredito: a evidência global, clean-SHA, Android físico,
acessibilidade, capacidade, segurança horizontal, custo/SLO e rollout ainda
estão abertos; `release_ready=false` e Battle continua `OFF`.

## Próxima decisão permitida

O trabalho atual é a Onda 0: tornar esta decisão executável, fechar oferta e
capabilities server-side, reconciliar lifecycle documental e endurecer os
gates. Somente receipts da mesma revisão podem mover uma linha de
`OFF_UNTIL_P0_RECEIPT` para `ON`.

Decidido em 2026-09-22:

- A linha de base contida foi ao ar em 2026-09-23 (`BT-REL-000`), antecipada por
  decisão do dono: backup local (ele vetou bucket) com ensaio de restauração,
  `master` promovido, migration 058, e backend, site público e agendador em
  `87fd5a2e6` com tudo `OFF` e observação same-SHA. Até então a API aprovada rodava
  `a6ee09c8f` (2026-08-03), sem a política de capabilities. O `/app` segue na
  imagem antiga. Cada passo em produção pede a aprovação do dono (regra 6).
- Os quatro buracos do plano de controle de conta (exportação sem
  reautenticação, exclusão sem limite de tentativas, login que denuncia contas e
  relatório de deck apagado) foram fechados em produção em 2026-09-23
  (`166aaed57`, `docs/qa/execution/2026-09-23/deploy-seguranca-d19.md`). O tempo da recuperação
  de senha (`BT-AUTH-003`) fechou no mesmo dia e está no ar desde 14:49 UTC (`c0f907108`).
- Escrever deck, importar e mexer no fichário exigem e-mail verificado (D-56,
  decidida em 2026-09-23; no ar desde 11:01 UTC, em `22a7749a7`). Na coorte por
  convite, aceitar o convite enviado ao e-mail conta como verificação (`BT-AUTH-006`).
- Em 2026-09-23 o XMage foi desligado até o Battle abrir (D-57) e o host foi
  reiniciado com a atualização de segurança (D-58). O reinício trocou o IP do
  balanceador interno; o backend fixa o IP novo desde `22a7749a7`. Abertas: D-59
  a D-61, com a recomendação em `docs/status/DECISOES_PENDENTES_2026-09-22.md`.
- Em 2026-09-23 à tarde subiu o lote integrado das três frentes da coordenação
  (`c0f907108`). No mesmo dia o dono decidiu a D-62 (o preço de deck usa a
  impressão em papel mais barata) e aceitou as recomendações da D-63 à D-71
  (demanda pelo log, parâmetros do catálogo, reconciliação do schema, itens de
  troca na exclusão, outbox da exclusão, prazos de retenção a confirmar com o
  advogado, limpeza por prazo sem capability e registro dos pedidos de
  exportação).
- À noite, o dono decidiu a D-73 (o preço de deck ignora impressões oversized e
  de borda dourada) e aceitou a D-72 (o total do deck continua gravado), a D-74
  (códigos de set duplicados, com a palavra dele na hora de apagar) e a D-75
  (`price_history` desligada até depois da coorte).
- Em 2026-09-24 o dono decidiu que o MVP não precisa de backup fora do servidor
  (D-81). O `BT-DR-001` fica com o backup local e o ensaio de restauração.
- O GO da primeira coorte exige todas as P0 CORE e P0 LIFE em `PASS`, produção no
  candidato congelado (ver as decisões de 2026-10-10 abaixo; até lá dizia "na linha
  de base contida com a 058"), catálogo com menos de 7 dias, rollback treinado uma
  vez e a assinatura do dono (D-18, `BT-DEC-001`). O catálogo está atualizado desde
  2026-09-23, com o job diário ativado às 15:34 UTC
  (`docs/qa/execution/2026-09-23/BT-CAT-01-ativacao-do-catalogo.md`). O preço de
  deck pela D-62 e pela D-73 está no ar desde 2026-09-23 às 18:53 UTC (`41bab49c9`),
  e a execução diária de 2026-09-24 às 06:20 UTC aplicou os preços
  (`docs/qa/execution/2026-09-23/deploy-preco-de-deck.md`).

Decidido em 2026-10-10 (D-92 a D-116, em `docs/status/DECISOES_PENDENTES_2026-09-22.md`):

- **Critério de produção do GO (D-93).** Troca "produção na 058" por produção no
  candidato congelado, com as migrations até a última do lote (hoje a 076; a 077
  da D-112 entra no mesmo lote), 29/29 capabilities `off` e same-SHA. Os outros
  critérios da D-18 continuam.
- **Rollback treinado (D-103).** Conta como treino uma promoção com falha induzida,
  que dispara a compensação automática, somada ao ensaio de restauração do backup
  do lote. Depois da 059, voltar o backend para `41bab49c9` não vale: rollback é
  restore.
- **Ordem do fecho (D-110).** É esta:
  1. congelar o SHA, com tag;
  2. rodar o `scope_e2e`;
  3. fazer o lote;
  4. fazer as leituras da produção;
  5. dar `PASS` no `BT-REL-001` e no `BT-REL-002`;
  6. rodar o `release` até ficar verde;
  7. `BT-REL-003`;
  8. `BT-QA-001`;
  9. GO.

  Entre o congelamento e a promoção, nada entra no `master`.
- **Abertura da coorte (D-104, D-109).** Depois do GO, numa promoção própria, a
  política versionada liga exatamente `account_registration` (modo convite),
  `catalog_private`, `collection_private`, `decks_private` e `life_counter_local`.
  Além da matriz toda `off`, o contrato do deploy passa a aceitar só essa matriz
  nomeada. Os convites saem em lotes de 20 a 30, e as variáveis de envio e o
  domínio são conferidos antes do primeiro lote (`BT-COH-001`). Até lá, a matriz
  continua toda `OFF`.
- **Superfícies que ficam escondidas na coorte (D-96).** O Generate, o import
  sobre deck existente e o restaurar pela tela da lixeira ficam fora do app da
  primeira coorte. As P0 deles fecham pelo servidor, e a tela da lixeira vai para
  o P1 (`DCK-P1-14`).
- **Telemetria (D-107).** Se o parecer do advogado não chegar a tempo, a coorte
  entra com a telemetria do app desligada, e só a ativação é medida no servidor. A
  baseline do KPI fica para depois da primeira coorte.
- **Prova de UI (D-92, D-113).** Há duas recapturas: a R1 depois do PR-B, e a R2
  depois do PR-C, que é o `BT-UX-PROOF-001`. A sessão de aparelho, com TalkBack e
  teclado, vem junto da R2.

Detalhamento e ordem:
`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`.

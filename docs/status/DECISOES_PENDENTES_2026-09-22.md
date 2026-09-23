# BrewTact — decisões do dono sobre a beta, com a recomendação de cada uma — 2026-09-22

Lifecycle: `CURRENT_CONTEXT · DECISION_REGISTER · NO_PRIORITY_AUTHORITY`. Registro das decisões que
só o dono pode tomar. Este documento não define prioridade nem autoriza mutação: cada decisão vale
pelo que foi escrito em `docs/status/CURRENT_PRODUCT_DECISION.md`, no backlog e na fila.

## Decidido em 2026-09-22

O dono aceitou todas as recomendações abaixo ("siga com todas as indicações que você sugeriu"). O
texto de cada item continua sendo a recomendação que ele aprovou.

Onde cada decisão foi registrada:
- **Decisão de produto** (`docs/status/CURRENT_PRODUCT_DECISION.md`): item 0, D-07, D-13, D-16,
  D-18, D-19, D-27, D-31, D-39 e D-41.
- **Backlog** (`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`): §2.2 e §2.5, e a nota
  "Decisão do dono em 2026-09-22" na linha de cada tarefa afetada.
- **Fila** (`docs/execution/CURRENT_QUEUE.md`): D-02, D-06, D-55 e a ordem da D-53, em duas raias.
- **Design** (`docs/design/`): D-42, D-43 e D-44.

Tarefas criadas pelas decisões (17):
- `BT-REL-000` (item 0) e `BT-GOV-002` (D-02);
- `BT-OBS-003` (D-51) e `BT-DB-006` (D-49, D-50);
- 13 da D-53: `BT-NAV-02`, `BT-NAV-03`, `LC-P0-05`, `BT-AI-033`, `BT-UX-ERR-001`,
  `BT-AUTH-007`, `BT-AUTH-008`, `BT-AUTH-009`, `BT-CAT-04`, `BT-DOC-007`, `BT-AUTH-010`,
  `BT-KPI-002` e `LC-P0-06`.

Mudanças de classe: `BT-PRIV-003` subiu a P0 CORE (D-25); `BT-UX-SWAP-001` passou a P0 AI (D-07).

Com isso o índice tem 244 tarefas e 146 P0 abertas: 64 P0 CORE, 26 P0 AI e 6 P0 LIFE. A primeira
coorte (núcleo + contador de vida, D-07) exige as 70 P0 CORE e P0 LIFE, todas agora ancestrais do
GO/NO-GO (`BT-DEC-001`, D-18). Depois do deploy de 2026-09-23, com o `BT-REL-000` fechado, são
145 P0 abertas, 63 P0 CORE, e a primeira coorte exige 69.

Continuam pedindo a palavra do dono na hora da execução:
- toda escrita, migração, deploy ou exclusão em produção (item 0, D-10, D-11, D-49, D-50);
- a exclusão dos dumps de 2026-07-17 (D-26);
- o bucket e a chave `age` do backup (D-12): criar conta em provedor é dele;
- o parecer do advogado (D-12, D-24);
- o aparelho físico, direto com quem executar (D-15).

Executado pela sessão coordenadora:
- D-01: `BT-WEB-003`, com `npm audit` zerado; falta o receipt same-SHA;
- D-03: o classificador de escopo staged entrou na branch, com um conserto no parser;
- D-52: 6 worktrees removidos, 2 registros podados e backup local dos 4 que tinham trabalho;
- D-54: a correção e as decisões foram commitadas pelos hooks, sem `--no-verify` (`ac70f3d98` a
  `b86df8a20`), e publicadas no mesmo dia com `git push --no-verify`, que o dono autorizou na hora,
  porque o `pre-push` roda o `full`, vermelho até o `BT-UIEV-001` fechar;
- D-55: a sessão do gate retomou logo depois destes commits, com a sequência do `BT-SCP-001`;
- item 0 (`BT-REL-000`), D-09, D-10 e D-11: feitos em 2026-09-23, com a autorização do dono de subir o
  que fosse preciso. Backup local e ensaio de restauração, `master` promovido, 058 aplicada, e
  backend, site e agendador em `87fd5a2e6` com tudo desligado (`docs/qa/execution/2026-09-23/BT-REL-000-linha-de-base-contida.md`);
- D-12 mudou: o dono vetou criar bucket. O backup ficou local e sem cifra, e a cópia fora desta
  máquina continua em aberto (`BT-DR-001`).

O andamento das demais está no backlog e na fila.

---

## As recomendações aprovadas

Onde está a evidência:
- estado verificado: `docs/status/ESTADO_DO_PROJETO_2026-09-22.md` e `docs/verdade/FATOS.md`;
- as 50 decisões da medição das P0, com os códigos A1–E6 usados abaixo: `docs/flows/_p0/README.md` §4;
- a leitura da produção: `docs/qa/execution/2026-09-22/prod-readonly-estrutura-e-contagens.md`.

Formato de cada item: a decisão, **Recomendo**, o porquê e o que destrava, nessa ordem. Os itens
estão ordenados pelo que destrava primeiro. Todo número foi recontado na fonte em 2026-09-22.

---

## 0. A recomendação mais importante: pôr a contenção no ar

### O que está no ar hoje

Observado em 2026-09-22 por `GET` público e pela leitura do banco.

A produção roda o commit `a6ee09c8f`, de 2026-08-03:
- está **39 commits atrás** da branch de trabalho e 10 atrás do próprio `origin/master`;
- não tem a política de capabilities: `/capabilities` responde 404, e o middleware raiz dessa
  versão só trata CORS;
- está na migration 057;
- tem a IA (`gpt-4o-mini`) e o worker de Battle ligados;
- tem o cadastro sem trava: `register.dart` não consulta capability, convite nem lista de
  permitidos.

Na prática, qualquer pessoa pode criar uma conta, e cada conta nova ganha 120 chamadas de IA por mês
(cota do plano gratuito, `plan_service.dart` dessa versão).

Os quatro buracos da D-19 existem nessa versão; conferi no código dela. O vazamento de privacidade
do marketplace também: a busca não filtra visibilidade nem bloqueio entre usuários, e a correção
existe só na árvore de trabalho.

O "tudo desligado" dos documentos descreve o repositório, não o que está no ar.

### A recomendação

**Recomendo:** tratar a implantação da linha de base contida como a entrega mais importante depois
do `BT-SCP-001`, com ID próprio (sugestão: `BT-REL-000`, "Implantar a linha de base contida"). A
sequência:
1. backup cifrado;
2. merge em `master`;
3. migration 058;
4. deploy do backend com as 29 capabilities off;
5. observação same-SHA.

**Por quê:** a contenção só protege quando está no ar. Com a linha de base implantada, cadastro, IA e
Battle fecham, porque no código atual o cadastro depende da capability `account_registration`, que
fica off. Os quatro buracos da D-19 continuam, porque estão no plano de controle, e por isso a D-19
anda junto. A janela é a melhor possível: a produção não registra conta nova nem evento de uso desde
2026-08-03, então desligar não tira nada de ninguém.

**Envolve:** D-09, D-10, D-11, D-12 e D-19. Registrado como `BT-REL-000`.

---

## 1. Destravam o NOW e o caminho crítico

**D-01 · Bump do `npm audit` (A1).**
- A mudança: `next` 15.5.21 → 15.5.25 (RCE crítico), com `eslint-config-next` acompanhando, e
  `overrides.sharp` 0.35.3 → 0.35.4.
- **Recomendo:** confirmar já, direto com a sessão que for executar.
- Por quê: você autorizou na coordenação em 2026-09-21, mas a sessão executora só age com a sua
  palavra direta. É o desbloqueio mais barato (2 a 3 arquivos, fora do digest de UI), e o gate amplo
  morre nele.
- Destrava: `BT-WEB-003` → `BT-SCP-001`, `BT-OFFER-001`, `BT-WEB-001` e o pre-push.

**D-02 · WIP-1 ou raias paralelas (E1).**
- **Recomendo:** duas raias, separadas pela fronteira do digest de UI. Uma para servidor, banco e
  gates; outra para o app. Cada raia com WIP-1.
- Por quê: o digest de UI é a restrição que importa. Com WIP-1 único, o caminho vira as 55 P0 CORE
  mais 9 não-CORE, em série.
- Exige ajustar o contrato da fila, que hoje aceita um só slot.

**D-03 · Política de prova de UI (E2).** 27 tarefas (mais 2) movem o digest, e cada recaptura
completa são 23 manifests e 439 capturas.
- **Recomendo:** recapturar em lote, por onda de telas, e não por tarefa. A prova completa fica
  para o `BT-UX-PROOF-001`.
- Junto: resgatar do worktree `manaloom-bt-scp-001-cleanroom` o classificador de escopo, que faz o
  commit rodar a evidência de UI só quando há UI no commit.

**D-04 · Absorver no slot do `BT-SCP-001` as correções de UI da contenção social, de trade e do
scanner (E5).**
- **Recomendo:** sim, antes da recaptura do `BT-UIEV-001`, para pagar a recaptura uma vez só.

**D-05 · Same-SHA e clean-SHA do `BT-SCP-001` (E3).**
- **Recomendo:** aceitar a prova de mecanismo para fechar o `BT-SCP-001` e levar o same-SHA de
  produção para o item 0.
- Clean-SHA: não reescrever o histórico. O próximo commit tem de passar pelos hooks sem bypass, e o
  receipt registra os 16 commits que citam o `--no-verify` (pelo menos 13 o declaram).

**D-06 · O que vem depois do NOW: kit visual ou banco.**
- Contexto: você escolheu o kit em 2026-09-21. A medição mostra `BT-DB-001` e `BT-DB-004` na
  corrente mais longa, com folga zero, e o kit com folga de 3 elos.
- **Recomendo:** com as raias da D-02, os dois andam juntos. O banco vai na raia de servidor; o kit,
  na de app, logo depois do `BT-UIEV-001`.
- Sem raias, `BT-DB-001` primeiro: a leitura de produção já foi feita, e falta só o script
  reproduzível e o receipt.

**D-07 · Escopo da beta (B1).**
- **Recomendo:** núcleo + contador de vida (55 P0 CORE + 4 P0 LIFE). Analyze/Optimize numa segunda
  onda.
- Por quê o contador entra: é local, não custa servidor, é a superfície que você mais valoriza e tem
  só 4 P0.
- Por quê a IA fica para depois: traz 24 P0 AI não medidas, custo por uso e o problema de qualidade
  descrito no `DECK_QUALITY_MODEL`.
- Consequência: o `BT-UX-SWAP-001`, que é do Optimize, sai do P0 CORE.

**D-08 · Dependências que puxam tarefas de fora da beta (B2).** `A11Y-001`, `PROOF-001` e `REL-003`
dependem de 6 P1 e 2 P0 AI.
- **Recomendo:** re-escopar essas dependências para o escopo da D-07.

---

## 2. Põem a contenção e o release no ar

**D-09 · Merge em `master` (A4).**
- O que entra: os 29 commits da branch de trabalho que não estão em `origin/master`. O `master`
  local parou em 2026-07-16 e não serve de referência.
- **Recomendo:** fazer o merge assim que o `BT-SCP-001` fechar verde, como passo do item 0. Hoje não
  há ID para isso.

**D-10 · Aplicar a 058 em produção (A5).** O ledger de produção está em 057.
- **Recomendo:** aplicar na janela do deploy, depois do backup da D-12.
- Por quê é seguro: a 058 só acrescenta 4 colunas de snapshot em `trade_items`, e a produção tem 0
  listagens.

**D-11 · Deploy e treino de rollback em produção, que não tem staging (A6).**
- **Recomendo:** fazer agora. É a melhor janela possível, sem uso desde 2026-08-03.

**D-12 · Backup cifrado fora do servidor (A7, C5, D2).**
- **Recomendo:**
  - dump cifrado com `age`, com a chave sob a sua custódia;
  - bucket S3-compatível em região no Brasil, o que evita a transferência internacional da LGPD, e
    com contrato de tratamento de dados;
  - RPO de 24 h e RTO de 4 h para a beta;
  - o primeiro backup antes da 058.
- Confirmar com o advogado.

**D-13 · Implantar o `/app` com tudo desligado (B21).**
- O problema: hoje é impossível. O loader canônico exige as 29 capabilities off, e o gate do `/app`
  exige ao menos uma on. O deploy do Flutter Web chama os dois em sequência e está inalcançável desde
  `fd0397a5a` (2026-08-24).
- **Recomendo:**
  - permitir o `/app` com tudo off, como "release de plano de controle". A regra de "ao menos uma
    on" passa a valer só quando uma capability abrir;
  - ordem de implantação: backend → site público → `/app` → Android;
  - Android na primeira coorte por APK no release host que o projeto já tem, sem Play Store por
    enquanto;
  - app com digest divergente (`REL-002`): negar as capabilities que o app instalado não conhece e
    pedir atualização;
  - congelamento: tag e branch protegida.

**D-14 · Leitura do host e capacidade (A3, D1).**
- **Recomendo:** autorizar agora a leitura SSH somente leitura do host: CPU, memória e disco por
  container. Com o resultado, definir limites e reservas por serviço.
- Por quê: é barata e decide se a VPS precisa de upgrade antes de abrir qualquer runtime.

**D-15 · Aparelho físico e quem assina a prova visual (A8, B17).**
- **Recomendo:**
  - autorizar o aparelho uma vez, perto do release, direto com quem executar;
  - você assina `PASS_VISUAL_REVIEWED` nas superfícies principais (onboarding, detalhe do deck,
    contador e home); o agente assina o resto, sempre contra a régua do contador;
  - emulador no gate e aparelho numa passada humana final;
  - matrizes de TalkBack e teclado re-escopadas para a beta da D-07.

**D-16 · Admissão da coorte (B4).** O `BT-AUTH-006` não tem código.
- **Recomendo:** convite de uso único emitido por você, em lotes de 20 a 30, entregue por e-mail,
  com expiração e revogável. Sem lista de espera na primeira versão.
- O convite deixa de ser exigido quando o cadastro abrir.

**D-17 · Gates (B24).**
- **Recomendo:**
  - skip vira SKIP inventariado (resultado PARTIAL), nunca silêncio;
  - o receipt forte começa por Deck/IA e cresce para todos os fluxos;
  - cada fatia roda uma vez: o gate Deck/IA reaproveita o que o `local_ci` já rodou no mesmo SHA (os
    10 Dart, o `--check` do project logic e o auditor de superfície), em vez de rodar de novo;
  - todo release exige receipt do banco de produção, lido no modo somente leitura usado em
    2026-09-22.

**D-18 · Critérios de GO/NO-GO (B25).**
- **Recomendo:**
  - todas as P0 do escopo da D-07 em `PASS`;
  - os quatro buracos da D-19 fechados;
  - produção na linha de base contida, com a 058;
  - cartas com menos de 7 dias de defasagem;
  - rollback treinado uma vez;
  - a sua assinatura.

---

## 3. Segurança e privacidade

**D-19 · Os quatro buracos alcançáveis hoje.** Todos existem no repositório e na versão em produção:
1. a exportação sai só com o token de sessão;
2. `DELETE /users/me` confere a senha sem limite de tentativas;
3. o login denuncia pelo tempo de resposta quais e-mails têm conta e devolve o texto da exceção;
4. `/reports/:id` continua servindo o snapshot de um deck apagado.

- **Recomendo:** fechar antes de qualquer abertura, junto com o item 0:
  - itens 1 e 2: ampliar o `BT-AUTH-004` (reverificação);
  - item 3: ampliar o `BT-AUTH-003` (limite de tentativas e oráculo);
  - item 4: o `/reports/:id` segue público, porque é o compartilhamento, mas é invalidado quando o
    deck é apagado, dentro do `DCK-P0-06`.

**D-20 · Step-up (B7).**
- **Recomendo:** reverificação de senha por requisição, sem migração, na exportação, na exclusão e
  na troca de e-mail, com limite de tentativas.

**D-21 · Erros e login (B22).**
- **Recomendo:**
  - códigos `dominio_motivo`, em snake_case, que acompanham a frase em português sem substituí-la;
  - teto de body de 1 MB, maior só no import;
  - bcrypt fictício para conta inexistente, com aceite de diferença de mediana abaixo de 20 ms em 50
    tentativas;
  - limite por e-mail e por IP.
- O oráculo de enumeração entra no `BT-AUTH-003`. O cadastro também responde "Email já está em uso".
  Com o convite da D-16, essa porta só se abre para quem tem convite.

**D-22 · Exportação de dados (B9).**
- **Recomendo:**
  - gerar sob demanda e entregar como download no app, sem guardar;
  - só dados do próprio usuário, com IDs de outras pessoas anonimizados;
  - sem hashes nem fingerprints internos.

**D-23 · Exclusão de conta (B10).**
- **Recomendo:**
  - exclusão orquestrada por outbox; caches com TTL de até 24 h;
  - no Sentry, parar de enviar o ID do usuário e documentar a retenção do provedor;
  - backups não são reescritos, mas o prazo de rotação entra na política;
  - simulações de terceiros contra o deck público de quem saiu são anonimizadas.

**D-24 · Reaceite legal e histórico (B8, C2).**
- **Recomendo:**
  - o reaceite bloqueia só o que cria ou compartilha dado (deck novo, import, IA); login,
    exportação e exclusão seguem livres;
  - beta só em pt-BR, com o texto legal versionado no repositório;
  - guardar o histórico de aceites, que é a prova de consentimento na LGPD. Confirmar com o
    advogado.

**D-25 · `BT-PRIV-003` (E6).**
- Contexto: o inventário de retenção é insumo da exportação e da exclusão, mas hoje é P1 e depende
  delas (`BT-PRIV-001` e `-002`). O `DCK-P0-04` também precisa dele, para a retenção do prompt.
- **Recomendo:** promover o `BT-PRIV-003` a P0 CORE e inverter a dependência. As P0 CORE passam de
  55 para 56.

**D-26 · Os 3 dumps completos da produção neste disco.** São de 2026-07-17 (dois) e de 2026-08-03,
com 300 MB cada, dados pessoais e fora do git.
- **Recomendo:** testar o restore do dump de 03/08, guardá-lo cifrado e apagar os dois de 17/07.
- Apagar é irreversível: só com o seu sim explícito.

---

## 4. Deck e IA

**D-27 · Editor de deck com `deck_replace_all` desligado (B3).** Hoje o editor não remove carta, não
edita descrição, não alterna público e não troca edição.
- **Recomendo:** criar edição incremental (remoção e PATCH) sob `decks_private`.
- Por quê: esconder as ações deixa o editor quebrado; abrir o replace-all desfaz a contenção.

**D-28 · Legalidade ausente passar a bloquear (B6).**
- **Recomendo:** sim, agora, com os seletores acompanhando.
- Por quê: medido na produção, 0 de 15 decks validados seriam rebaixados.

**D-29 · Concorrência, preview e prompt do deck (B14).**
- **Recomendo:**
  - `If-Match` com transição: primeiro só avisa; passa a ser exigido quando a versão mínima do app
    mandar o cabeçalho, porque o APK não se atualiza sozinho;
  - artifact de preview com TTL de 24 h, reutilizável pelo mesmo usuário (uso único exigiria tabela,
    sem ganho real);
  - preview de import em deck existente, que não grava nada, sob `decks_private`. O commit continua
    sob `deck_replace_all`, porque hoje apaga e regrava o deck até no modo merge. Na beta, o import
    entra por deck novo (`/import`, que já está sob `decks_private`);
  - prompt bruto retido por 30 dias e fora de `decks.description`.

**D-30 · Lixeira de decks (B13).**
- **Recomendo:**
  - purge em 30 dias;
  - deck na lixeira não conta em limite nem em aprendizado, e entra na exportação;
  - restaurar não republica relatório.

**D-31 · Rotas de IA legadas (B20, A9).** São quatro: `POST /decks/:id/recommendations`,
`GET /decks/:id/simulate`, `POST /ai/simulate-matchup` e `POST /ai/weakness-analysis`.
- **Recomendo:** remover as quatro, com os testes que as tratam como recurso.
  - Substitutos: Optimize, Battle e Analyze.
  - `GET /ai/ml-status` fica com o `BT-AI-027`.
- Dispensar a janela de telemetria em produção. Nenhuma das quatro tem consumidor no app, no site
  nem nos scripts, e a produção não tem uso desde 2026-08-03.

**D-32 · Retenção dos jobs de IA (`BT-AI-032`).** Você já decidiu subir a retenção.
- **Recomendo:** 24 h, o que cobre fechar e reabrir o app no mesmo dia.

---

## 5. Catálogo e arte

**D-33 · Catálogo parado (E4).** Cartas e legalidades não sincronizam desde 2026-06-06 (as três
últimas execuções falharam nesse dia); preços, desde 2026-06-27.
- **Recomendo:** religar antes da beta, com um contrato de apply que autorize escrita autônoma **só
  de dado de referência** (cartas, sets, legalidades, preços):
  - upsert idempotente;
  - receipt por execução;
  - nunca em tabela de usuário.
- Junto: corrigir o invólucro do job, que roda `dart run` numa imagem que só tem AOT.

**D-34 · Custo do refresh (D3).**
- **Recomendo:** um download diário do bulk data do Scryfall (`default_cards`), em vez de chamadas
  por carta.

**D-35 · Carta ausente e grão do catálogo (B5).**
- **Recomendo:**
  - carta ausente responde 404 com código `card_not_in_catalog` e frase em português, e soma num
    contador de demanda para o próximo refresh; nenhuma sincronização disparada por usuário;
  - a base do catálogo, hoje no grão Oracle, passa para o grão de impressão pela mesma fonte da D-34,
    que um script do projeto já consome;
  - as linhas-alias Oracle ficam enquanto houver referência em `deck_cards` ou `user_binder_items`,
    e essas referências migram numa correção de dados com receipt. É escrita em produção: aprovação
    por execução.

**D-36 · Limites de leitura do catálogo (`BT-CAT-03`).**
- **Recomendo:**
  - catálogo com mais de 7 dias dispara alerta, sem bloquear a leitura;
  - "leitura cara" é busca textual sem filtro, com limite por IP.

**D-37 · Arte de carta (C1, `BT-ART-01`).**
- **Recomendo:**
  - seguir o contrato de arte: nada de crop, blur ou cover. Sai a proposta de fundo desfocado da
    auditoria visual;
  - implementar no caminho nativo o limitador e o retry que hoje só o Web tem;
  - trocar o User-Agent `ManaLoom/1.0` por `BrewTact/1.0` com contato, como o Scryfall pede;
  - revalidar as políticas do Scryfall e da Wizards sob a marca BrewTact;
  - o contrato fica como documento de engenharia, citado pelo pacote jurídico.

---

## 6. Social, trades e scanner

**D-38 · `trade_visibility` no marketplace.**
- **Recomendo:** respeitar "só seguidores" também na busca global, como o
  `/community/trade-matches` já faz.

**D-39 · Abertura social e troca/venda do fichário (B18).**
- **Recomendo:**
  - abrir as flags uma a uma, depois de corrigir os endpoints compostos que vazam dado de outras
    flags;
  - na beta, esconder troca/venda do fichário e rejeitar a escrita com 422, que é erro explícito,
    em vez de zerar em silêncio.
- Não há listagem a limpar: a produção tem 0.

**D-40 · Pack 05 de evidência, C17 (B18).**
- **Recomendo:** manter o pack, rotulado como evidência de capability futura e fora da contagem de
  evidência da beta.

**D-41 · Scanner fora do artefato (B19).**
- **Recomendo:** fora de verdade:
  - remover permissões e plugins de câmera do build de release, no Android e no Web. O
    `app/web/nginx.conf:41` concede `camera=(self)`, e
    `scripts/manaloom_release_ops_contract_test.sh:286` exige isso, então o teste muda junto;
  - não aceitar probe de APK não canônico: o receipt sai só pelo orquestrador same-SHA.

---

## 7. Visual e UX

**D-42 · Mockups de onboarding e gerador.**
- **Recomendo:**
  - aprovar a direção "Bancada do comandante" do gerador, que venceu o júri;
  - pedir mais uma rodada do onboarding antes de julgá-lo: a última nota foi beleza 6,5 e função 6,
    sem aprovação dos auditores.

**D-43 · Piso do numeral com 7 a 10 jogadores no contador.** O piso é 38% da altura do card. Com 7
e 8 jogadores o numeral cai para 30%; com 9 e 10, para 23%. As opções:
- (a) aceitar o numeral menor acima de seis jogadores, com piso de 23% nessa faixa;
- (b) deixar o numeral usar mais da largura do card, com risco de estouro em vida de 3 dígitos;
- (c) limitar a mesa a 6 jogadores.

- **Recomendo:** (a), documentado.
- Por quê: mesa de 7 ou mais é rara em Commander, e as outras saídas cortam recurso ou arriscam
  estouro.

**D-44 · Decisões visuais do kit (B16).** A §11 da `docs/design/ui-kit-spec.md` ainda mostra os
números antigos (coroa 2,81; fio da placa 1,84; brasa contra assento 1,13). O protótipo já corrigiu
isso: medido em 2026-09-22 com a ferramenta dele (`tools/contrast.py`), são 43 pares, todos dentro do
mínimo — ícone da coroa 3,49, fio da placa 4,09 e "Concedeu" 10,27, agora em vinho, a ΔE ≥ 25 de toda
cor de jogador.
- **Recomendo:**
  - ratificar o que o protótipo resolveu (A7, C2/C3, D1, E1) e atualizar a §11;
  - aprovar as saídas derivadas que o kit propõe (A1–A6, A8, B1–B3; C1 pela saída ii);
  - nas decisões que não são de contraste:
    - F1: literais de cor no `app_theme.dart`;
    - F2: acima de 160% de escala, a palavra de estado desce para a segunda linha;
    - F3: assumir o custo da transparência na beta;
    - F4: `AppRuleTile` ganha texto rico com alvos próprios, que o consentimento legal precisa;
    - F5 e F6: alinhar com a régua (traço 2, raio 12);
  - alvo de toque de 48 dp em todas as peças.

**D-45 · Kit, troca pareada e fixtures (B15).**
- **Recomendo:**
  - kit antes do `BT-UX-SWAP-001`, senão ele é refeito;
  - "trocas" são as do Optimize (a troca pareada que o kit vai desenhar), e entram com a onda da
    IA;
  - as fixtures de deck do worktree `manaloom-bt-ux-fix-001` entram agora; as de Trade esperam
    Trades abrir;
  - nenhuma imagem de carta versionada no repositório, porque o contrato de arte não republica o
    catálogo.

**D-46 · Textos da landing (C4).**
- **Recomendo:** tirar do título e da descrição do site o que a beta não entrega. São eles
  "Commander com IA explicável" e "relatórios compartilháveis", em `web-public/src/app/layout.tsx`.
- Os textos que já dizem "quando esse recurso estiver habilitado" podem ficar.

**D-47 · Telemetria e SLO (B11, B12, C3, D4).**
- **Recomendo:**
  - ativação = primeiro deck criado ou importado em até 24 h do cadastro; retenção = volta na
    segunda semana;
  - guardrails de custo de IA e de taxa de erro; nenhuma decklist em analytics;
  - política de privacidade atualizada quando a telemetria entrar;
  - SLO de 99,5% de disponibilidade e p95 abaixo de 800 ms em leitura;
  - alerta para você por e-mail ou Telegram, sem TSDB: o PostgreSQL e o `/health/metrics` bastam.

---

## 8. Banco, dados e processo

**D-48 · Banco (B23).**
- **Recomendo:**
  - comparar a produção com um ambiente fresco (a leitura de hoje já fez isso);
  - a 059 cria as 7 tabelas que o código usa sem migration e reconcilia as colunas divergentes, sem
    perfil de live-drift;
  - `setup_database.dart` vira tombstone fail-closed, como o `update_schema.dart`;
  - `extract_meta_insights --full` passa a exigir aprovação;
  - `database_indexes.sql` é aposentado: 29 dos seus 36 índices não existem em nenhum outro lugar
    do repositório. Os que a próxima leitura achar na produção viram migration;
  - os 47 pacotes SQL vão para o arquivo e param de criar tabelas em `manaloom_deploy_audit`;
  - `sync_state` com um único DDL.

**D-49 · Tabelas que só existem na produção.**
- **Recomendo:** nada destrutivo antes do backup da D-12.
- Depois do backup:
  - exportar para o arquivo cifrado o schema `manaloom_deploy_audit` (1.033 tabelas, 150 MB) e os 9
    backups manuais do `public`, e apagá-los;
  - as 4 tabelas órfãs, só depois de confirmar que ninguém as lê.
- É irreversível: aprovação por execução.

**D-50 · Correção de dados em produção.**
- **Recomendo:**
  - aprovar o backfill dos 12 decks com formato em maiúscula;
  - nas 2 chaves estrangeiras que faltam em `ml_prompt_feedback`: contar os órfãos primeiro (é
    leitura), depois criar a chave como `NOT VALID` e validar.
- É escrita em produção: aprovação por execução.

**D-51 · Ciclo entre `BT-OBS-001` e `BT-REL-001/002`.**
- **Recomendo:** partir o `BT-OBS-001`. SLOs e alertas de API, banco, jobs e catálogo agora; o
  alerta de release, depois do `BT-REL-002` (virou o `BT-OBS-003`).

**D-52 · Worktrees fora da árvore principal.** Há 4 com trabalho não commitado (42 arquivos, em
branches só locais), 5 limpos e 2 registros mortos.
- **Recomendo:**
  - resgatar o classificador de escopo do cleanroom (é a D-03);
  - publicar `codex/bt-ux-fix-001` e `codex/ui-home-wave-01` como branches remotas, para não perder
    o trabalho, e revisitá-las depois do kit;
  - conferir e descartar o `codex/project-logic-cold-repro-fix`, que o `BT-CI-001` já superou;
  - levar ao `BT-SCP-001` o que faltar do commit-base `0779595e2`. Ele está no remoto
    (`origin/codex/BT-SCP-001-cleanroom`), mas não na branch de trabalho;
  - remover os 5 limpos (`38e8`, `91ba`, `d18b`, `f931` e `manaloom-project-logic-delivery`, cujo
    commit já está na branch) e podar os 2 registros mortos.

**D-53 · Ordem dos achados dos fluxos.**
- **Recomendo** esta ordem, cada achado com ID próprio:
  1. os quatro buracos (D-19);
  2. `capability_unavailable` chegando cru na tela;
  3. expulsão do usuário a cada refresh de capabilities;
  4. beco sem saída do onboarding;
  5. assimetrias de gate, como o apply do Optimize morrendo em 404;
  6. o resto.

**D-54 · Commit desta correção documental.**
- **Recomendo:** commitar agora, em 3 commits focados:
  1. contrato e documentação regenerada;
  2. correção do marketplace, com o teste;
  3. documentação de apoio.
- Declarar o `--no-verify`, como nos commits anteriores, e fazer push na branch de trabalho.
- Por quê: são mais de 60 entradas soltas no `git status`, numa árvore que outras sessões vão
  retomar. Esse é o risco maior.

**D-55 · Retomada das sessões pausadas.**
- **Recomendo:** retomar uma de cada vez, seguindo as raias da D-02:
  1. primeiro a do gate (`BT-WEB-003` → `BT-UIEV-001` → `BT-SCP-001`);
  2. depois a do kit.
- Esta sessão fica na coordenação.

---

## 9. Já resolvidas ou respondidas

| Item | Situação |
| --- | --- |
| Leitura do banco de produção (A2) | Feita em 2026-09-22, só estrutura e contagens |
| Limpar `for_sale=true` em produção (A10) | Desnecessário: 0 linhas |
| Risco de rebaixar decks com legalidade bloqueante (B6) | Medido: 0 de 15 |
| `DECK_QUALITY_MODEL` canônico | Decidido no commit `8e6a7e0ed` (2026-09-18) |
| Cold-repro do project logic que travava o commit | Resolvido pelo `BT-CI-001` |
| Contraste do protótipo do contador (coroa, fio, "Concedeu", colisão de cor) | Resolvido no protótipo e medido em 2026-09-22 (43 pares no mínimo); falta ratificar e atualizar a spec (D-44) |
| Tomadas pelo dono em 2026-09-21, aguardando execução | bump do `npm audit` (D-01); correção do marketplace (feita, sem commit); `integration_test/` no gate; kit como próximo NOW (D-06); onda 8 do contador; retenção dos jobs de IA (D-32); investigação do play-vs-ai; documentar o 3º portão (feito) |

# ManaLoom Sprint 1 — contratos, sessão e dados — 2026-07-21

Evidência incremental do Sprint 1. Nenhum resultado PostgreSQL/live é tratado
como aprovado sem execução no harness isolado e capability guard correspondente.

## S1-01 — shapes app/backend

Resultado: **PASS**.

- Flutter focado em decks, cards, Battle replay, trade match, comentários,
  mensagens, privacidade e trades: `119/119` PASS;
- Dart focado em cards, replays, reports, comunidade, sync, privacidade e schema:
  `54/54` PASS; os três casos live deliberadamente separados foram executados
  depois no harness real e passaram `3/3`;
- E2E API + PostgreSQL descartável:
  - contrato negativo geral + profile/community + social/trade: `119/119` PASS;
  - matriz de shapes sucesso/vazio/inexistente/forbidden: `1/1` PASS;
  - análise de deck sucesso/404/405: `3/3` PASS;
- a primeira execução real revelou `500` em cinco rotas porque o runtime usava
  tabelas sociais que não existiam no schema versionado;
- a migration `041_create_social_trade_messaging_runtime_schema` e o bootstrap
  agora criam `user_binder_items`, trades, histórico, conversas, mensagens e
  notificações, com FKs de privacidade, unicidade de participantes e gatilhos de
  usuário ativo;
- uma segunda execução revelou drift de enum: rota/app aceitavam `correios`,
  `motoboy`, `pessoalmente`, `outro`, enquanto o banco aceitava somente os
  valores legados `mail`/`in_person`; migration e bootstrap agora aceitam o
  domínio atual e preservam leitura compatível dos dois valores legados;
- harness reproduzível fail-closed:
  `scripts/manaloom_server_contract_e2e_isolated.sh`; usa apenas loopback,
  database `manaloom_s1_api_*`, porta efêmera, fixture local determinística,
  build real da API e traps para processo e banco;
- summaries SHA-256:
  - `20e20ceb7eb822685ffb3e89868a8a089c7f817f7be3b6706763d84ca234a1c7`
    — 119 contratos HTTP;
  - `ebbfd68f40d9430a3fe45bad93e093b50607cd20bb2b4dabf0f8402efaa5cec9`
    — matriz de shapes;
  - `865c9fea12aa32b0dcbd394799edbec3429167dce36c510be81ef17217dde6ff`
    — análise de deck;
- hash do diff focado:
  `165a671f77c01e23d36379f5e0a8fff42c4588c81d18ff53e847b19c22c2c4d9`;
- cleanup pós-gate: zero database `manaloom_s1_api_*` ou
  `manaloom_s1_migrations_*`, zero listener Dart do harness;
- `git diff --check`: PASS.

## S1-02 — sessão e rate limit

Resultado: **PASS**.

- Flutter: `14/14` testes em
  `auth_provider_initialize_test.dart` e `auth_screens_test.dart`;
- backend: `51/51` testes em rate limit, política JWT, auth service, senha de
  cadastro e preflight de release;
- `GET /auth/me`: `401` encerra e limpa a sessão; `429`, `500`, `503`, timeout
  e falha de rede preservam token e usuário locais;
- token sem usuário, usuário sem token e JSON malformado são removidos com copy
  explícita e acessível na tela de login;
- `POST /auth/login` e `POST /auth/register` continuam dentro do bucket de
  credenciais; `GET /auth/me` não o consome nem sofre seu bloqueio;
- SHA-256 do diff focado:
  `a014c5409e7c8304d5809fc71f997981bc2b750cd3a056945039c5e53daf52f0`;
- `git diff --check`: PASS.

## S1-03 — migrations 038–040 isoladas

Resultado: **PASS**.

- harness fail-closed novo:
  `scripts/manaloom_migrations_038_040_isolated.sh`;
- alvo: PostgreSQL `16.9`, exclusivamente loopback, bancos efêmeros com prefixo
  `manaloom_s1_migrations_*`;
- fresh schema + apply do ledger atual (46 migrations, incluindo 038–046):
  PASS;
- fresh reapply/idempotência: PASS;
- clone anterior com ledger 001–037 + apply 038–040: PASS;
- upgrade reapply/idempotência: PASS;
- rollback manual exigido pelas migrations: dump do estado anterior restaurado
  em outro banco e `assert-prior`: PASS;
- forward recovery após restore + postcheck funcional: PASS;
- migration 040 converte `is_reserved=NULL` para `false` e impõe `NOT NULL`;
- migration 039 invalida deck `validated` para `draft` após mutação de
  `deck_cards`;
- tabelas críticas da 038 e ledger 038/039/040 validados;
- testes determinísticos de harness/migrations: `30/30` PASS;
- summary SHA-256:
  `c1c76d20f6eeae53f664a3f783f65835d46e8e9f4deb184b24890a9db99cbf88`;
- dump anterior SHA-256:
  `2c01f9a7374a5a2cf660083865d30684ace0362f5cfced53a37b7699b5ed73fe`;
- cleanup: zero database com prefixo do harness após a execução;
- a primeira tentativa abortou antes do restore ao detectar `pg_dump 14.18`
  contra servidor `16.9`; o harness passou a selecionar automaticamente o
  cliente do mesmo major e a segunda execução passou integralmente.

Hashes dos arquivos do harness:

- `9533cbf7f5662a0dadbe5b5434b7cd5db09c332c96d313ce9a79b63678eef464`
  — shell entrypoint;
- `2bf2194ef843810915e462b2dd82b858bf20b50467b2d3d6d93df03cb927f1e7`
  — helper Dart;
- `5958d5483db3beb7dc52df7b341b56ab7e0722f1ff034e4f48a4b399dcadd1bf`
  — contract test.

## S1-04 — sync e tombstones em dois clientes

Resultado: **PASS**.

- Flutter store/sessão: `12/12` PASS;
- contrato backend determinístico: `5/5` PASS;
- E2E API + PostgreSQL descartável com dois tokens da mesma conta: `1/1`
  PASS;
- matriz de convergência:

| Entidade/estado | Cliente A | Cliente B | Resultado canônico |
|---|---|---|---|
| nota nova + `play_session_id` | cria em revision 1 | lê via cursor incremental | uma nota, snapshot do deck persistido |
| retry da criação | reenvia o mesmo ID | — | mesmo ID, nenhuma duplicata |
| atualização concorrente | mantém revision antiga | grava revision 3 | stale recebe 409 e `current_note` |
| tombstone | recebe delta pelo cursor | exclui com `If-Match` | revision 4, `is_deleted=true` |
| ressurreição stale | tenta upsert revision 3 | — | 409; tombstone preservado |
| retry de delete | repete DELETE | — | 204 idempotente |

- um segundo ID com o mesmo `play_session_id` é rejeitado com 409;
- leitura sem `include_deleted` fica vazia após exclusão, enquanto a leitura de
  sync mantém exatamente um tombstone com `deck_id`;
- outro usuário recebe 404 e não observa as notas;
- summary SHA-256:
  `f49f7d917f4587f162b37f4fef494690deaa23d5578b8c8318070bce4957e405`;
- arquivo do teste SHA-256:
  `9bd8177572eb95bde6943dabdca7a2a4b8e97e96b074eec81f8b58b5f09b21ed`;
- cleanup: zero database `manaloom_s1_api_*`, zero listener Dart;
- `git diff --check`: PASS.

## S1-05 — exportação e exclusão de conta

Resultado: **PASS**.

- Flutter service/UI de privacidade: `5/5` PASS;
- contratos backend de export, anonimização, visibilidade e migration:
  `13/13` PASS;
- E2E API + PostgreSQL descartável: `1/1` PASS;
- export sem autenticação: 401; export autenticado: 200 com `no-store`,
  `no-cache` e filename de download;
- conteúdo comprovado no export: conta, plano, deck, `deck_cards`, binder e
  nota pós-jogo; inspeção recursiva não encontrou chaves `password_hash` ou
  `fcm_token`; a lista `omitted_secrets` declara explicitamente o que foi
  excluído;
- confirmação incorreta: 400; senha incorreta: 401; após ambas as falhas o JWT,
  o login e o deck permaneceram válidos;
- exclusão correta: 200, `account_deleted=true`, modo `anonymized` e recibo de
  retenção; somente após esse sucesso o JWT antigo, login antigo e novo export
  passaram a 401;
- deck público da conta excluída deixou de existir para descoberta (404);
- summary SHA-256:
  `1c21dcee046e96ae80d9f8455fd78f6dbf34bf3c43bafb198a26be230ae9ab54`;
- arquivo do teste SHA-256:
  `d0894b1c1dd2a8f1218135183c26e3045cd549288b8319f81ae2705142def915`;
- cleanup: zero database `manaloom_s1_api_*`, zero listener Dart;
- `git diff --check`: PASS.

## S1-06 — identidade e fanout

Resultado: **PASS**.

- contratos determinísticos de migrations, identidade de printing/oracle,
  hidratação de decks, fundação de qualidade e mapa da API: `36/36` PASS;
- o primeiro fingerprint fornecido divergia do ED25519 anunciado pelo servidor
  em um caractere (`0` versus `O`); o guard recusou o host antes de enviar chave
  ou senha, e o fingerprint observado foi confirmado explicitamente pelo
  responsável antes do retry;
- o runner do contrato foi reclassificado de `--write-approved` para
  `--read-only`: o wrapper permite somente `psql` ou o path canônico deste
  auditor, injeta `default_transaction_read_only=on`, e o Python força e
  confirma `SHOW transaction_read_only` em cada conexão;
- o cache Hermes/SQLite também é aberto com URI `mode=ro`; somente os relatórios
  sanitizados em `/tmp` são gravados;
- contratos do wrapper: `4/4` PASS; testes do auditor: `8/8` PASS; Python
  arbitrário foi rejeitado antes de ler `.env` ou abrir rede;
- `./scripts/quality_gate.sh pg-contract`: exit `0`, `55/55` PASS, zero FAIL e
  zero WARN, PostgreSQL acessado apenas pelo túnel loopback efêmero;
- relatório confirma `mutations_performed=[]`;
- hashes SHA-256 da prova bruta em `/tmp`:
  - `4e5131b24c9335bbb74d99b75f27aaccd56cb500ae92b14cadff78f3e36b2b57`
    — JSON;
  - `d8d31d0f8ad929d8cad0f0d99b539f90dbd5ce4aa6ec50c3360f320715f1a63f`
    — Markdown;
  - `4cb58005d2aab64bf68a675e57fc4732f326e04449ca8d71369f1bb7a288e0d8`
    — log do gate;
- cleanup pós-gate: zero processo do wrapper/túnel, zero listener SSH e zero
  arquivo temporário recente de scan/known-hosts.

## S1-07 — coleção, alocação, disponibilidade e concorrência

Resultado: **PASS**.

- semântica canônica única por usuário e identidade jogável
  `COALESCE(cards.oracle_id, cards.id)`:
  - `owned_quantity`: cópias `have` fisicamente possuídas;
  - `allocated_quantity`: soma da necessidade de todos os decks ativos;
  - `committed_trade_quantity`: soma reservada por propostas ativas;
  - `free_quantity = max(owned - allocated - committed, 0)`;
  - `missing_quantity = max(allocated - owned, 0)`;
- as views `collection_availability_snapshot` e
  `binder_item_availability` são idênticas no bootstrap e na migration `045`;
  a distribuição por item é determinística e prioriza os itens explicitamente
  marcados para troca/venda sem fabricar cópias;
- Binder privado expõe possuído, alocado, comprometido, livre, faltante e
  disponível; Binder público e Marketplace retornam apenas quantidade
  disponível maior que zero;
- o otimizador de deck usa `free_quantity` por identidade jogável para
  `collection_match` e orçamento. Uma cópia já alocada ou comprometida não é
  mais considerada compra evitada;
- `POST /trades` bloqueia participantes e itens em ordem determinística e
  recalcula disponibilidade dentro da transação; ids duplicados são rejeitados
  e races retornam conflito 409 tipado;
- o primeiro E2E encontrou um drift anterior real: Marketplace dependia de
  `price_history`, mas a tabela não estava no ledger/geração de schema. A
  migration `046_restore_price_history_runtime_contract` e o bootstrap agora
  restauram a relação e seus índices; ausência de pontos continua sendo estado
  válido, ausência da tabela não;
- Flutter 3.44.6 fixado: Binder provider/UI/resiliência/overflow `13/13` PASS;
- servidor focado: contrato, rotas, optimizer, migrations e payloads `42/42`
  PASS; rodada adicional de migration/schema `32/32` PASS; `dart analyze` sem
  issues;
- suíte completa não-live do servidor: `698/698` PASS e três testes live
  deliberadamente skipped; nenhuma regressão fora do recorte;
- E2E API + PostgreSQL descartável: `1/1` PASS. O cenário possui quatro cópias,
  dois decks alocando uma cada e duas propostas simultâneas pedindo as duas
  livres: exatamente uma retorna 201, a outra 409
  `trade_quantity_unavailable`; depois, comprometido=2, livre=0 e o item some
  do Marketplace;
- harness de migrations fresh/reapply/upgrade/restore/forward: PASS com o
  ledger atual em 46 migrations;
- summaries SHA-256:
  - `758344cccd00ffe19751cf637c14b2b0490b4dddc63eadaebbda798f465d2995`
    — E2E concorrente;
  - `c1c76d20f6eeae53f664a3f783f65835d46e8e9f4deb184b24890a9db99cbf88`
    — ciclo isolado de migrations;
- logs SHA-256:
  - `fed71815491adc1b3537259f4c404d0198b4e11ac6c6d469751a7a6681d75495`
    — E2E concorrente;
  - `b22bd66afddc15fcdf80ca6d514343c259fd811b70e60136039338bfb3d7877f`
    — migrations isoladas;
  - `9574e0c358a5f5eb5398ab26ee6c1c4548e01e1218764a0d69703d7e1f694738`
    — Flutter focado;
  - `62cfc78f13d6f28f234f05a5e55914621a6c1ce2048ece7c64c9e30f534cddd5`
    — servidor focado;
- cleanup pós-gate: zero database `manaloom_s1_api_*` ou
  `manaloom_s1_migrations_*`, zero servidor/fixture/listener do harness.

## S1-08 — recuperação e proteção da conta

Resultado: **PASS no contrato e no E2E isolado**.

- migrations `042` e `044` criam estado de versão de autenticação e tokens de
  recuperação/verificação armazenados somente como SHA-256, com expiração e
  consumo único;
- esqueci a senha mantém resposta neutra; token expirado ou reutilizado é
  rejeitado; senha fraca não consome o token; reset e troca de senha incrementam
  `auth_version` e invalidam JWTs antigos;
- troca de senha e revogação com senha incorreta preservam a sessão; no sucesso
  retornam um JWT substituto e revogam as demais sessões;
- login, cadastro, recuperação, reset, troca, revogação, verificação e reenvio
  permanecem no bucket de credenciais;
- conta sem e-mail verificado recebe `403 email_verification_required` nas
  mutações de Community, Trades, Conversations e Binder; o mesmo JWT passa após
  verificar o e-mail, sem precisar relogar;
- entrega de recuperação e verificação foi exercitada por webhook exclusivamente
  loopback. O log persistido contém somente template, domínio do destinatário e
  presença de link — nenhum token ou URL sensível;
- preflight de produção falha fechado sem URLs HTTPS, tokens de webhook com
  tamanho mínimo e URLs de app de recuperação/verificação; exposição de token
  de teste é recusada em produção;
- Flutter focado de modelo, provider, serviço, telas de auth/perfil e legal:
  `41/41` PASS;
- backend focado de schema/migrations/rate limit/runtime: `54/54` PASS; política
  e preflight de release: `17/17` PASS;
- E2E API + PostgreSQL descartável combinado: `3/3` PASS, migrations `44`,
  oito entregas e templates `email_verification,password_reset`;
- summary SHA-256:
  `1d7d6f0a97e84bf12bca22b24a5f7318d7098d15642f7583ad99120863dbce99`;
- hashes dos principais artefatos:
  - `3d9d98b92ee22074f96ed0fecc64f4f9d2364e225cf8978fdcdbce26154d4e0a`
    — harness E2E;
  - `90160db7ac45647dbdfbf837dba37378b49216d257f1bddfee5394ab707b02a0`
    — fixture de entrega sanitizada;
  - `57e109cf948a2986ad086f1d6d0f16418079241e6fd5bac49d37f352d91e2218`
    — teste live de segurança de conta;
  - `2e723671af4fa6f81487709724ba82b5fd8fd1e4c463427c6eda7396394a653a`
    — teste live de verificação de e-mail;
- cleanup pós-gate: zero database `manaloom_s1_api_*`, zero listener Dart ou
  fixture de e-mail; `git diff --check`: PASS.

O adaptador e seu contrato estão provados. O deploy real continua bloqueado,
de forma intencional, até serem configuradas coordenadas HTTPS e credenciais do
provedor de e-mail; isso é configuração de release, não um bypass no runtime.

## S1-09 — legal e consentimento no ciclo da conta

Resultado: **PASS**.

- Termos e Política de privacidade são públicos, boot-safe e consultáveis antes
  do login;
- cadastro envia e persiste as versões exatas `2026-07-21` com timestamps de
  aceite; produção exige sempre as versões correntes;
- usuário, plano gratuito e consentimento são gravados na mesma transação;
  cadastro ausente ou com versão antiga retorna `400` e deixa zero linha de
  conta; cadastro válido deixa exatamente uma conta e um plano;
- a UI exige aceite explícito, mostra as versões, oferece links pré-login e,
  após sucesso, segue para a verificação de e-mail preservando o deep link;
- migrations/bootstrap impõem consistência entre versão e timestamp de Termos
  e Privacidade;
- teste live legal está incluído no E2E combinado `3/3`, cujo summary tem
  SHA-256
  `1d7d6f0a97e84bf12bca22b24a5f7318d7098d15642f7583ad99120863dbce99`;
- teste live legal SHA-256:
  `c344e77f1af5855aeffb5656dc0d1cf21222f1d83fd0f6a1a9b5e5fb6a42b454`;
- nenhum cadastro falho prendeu a navegação em rota protegida e o cleanup do
  harness foi integral.

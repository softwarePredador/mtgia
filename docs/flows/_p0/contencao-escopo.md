# P0 CORE — Contenção de escopo: manifesto de capabilities, oferta, rotas órfãs, social/trade/scanner

- **Medido em** 2026-09-22 14:39 -03, contra `codex/free-beta-release-candidate-2026-07-17` @ `d15beb05b` (branch sincronizada com o origin; **29 commits à frente de `origin/master`**).
- **Worktree compartilhado:** 62 entradas modificadas por outras sessões — docs, `project_logic_manifest.json` e dois fontes de servidor que ninguém commitou: `server/routes/community/marketplace/index.dart` (+25 linhas de filtro de privacidade) e `server/test/community_marketplace_privacy_contract_test.dart` (novo, não rastreado). As linhas citadas conferem com o worktree. Onde o diff não commitado desloca a numeração, a citação diz `@HEAD`.
- **Somente leitura.** Não rodei build nem teste. Para auditar a classificação por rota, escrevi um port read-only de `requiredCapabilityForRequest` e `isReleaseCapabilityControlPlaneRequest` (`scratchpad/p0/work/classify.py`, fora do repo). Ele reproduz o teste exaustivo do servidor: 147 combinações rota×método, e nenhuma fica sem classificação fora do plano de controle.
- Esta versão **substitui** a das 10:48 deste mesmo arquivo. As divergências estão listadas na seção "Divergências".
- **[ADV] Revisão adversarial em 2026-09-22 15:07 -03**, mesmo SHA, somente leitura. As marcas **[ADV]** indicam o que a revisão corrigiu no lugar. O detalhe, com o que caiu e o que subiu, está na seção final "Verificação adversarial".
- **[ADV] Atenção ao "estado declarado".** No backlog **commitado** (`git show HEAD:docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:546-547`), `SCOPE-P0-SOC-00` e `SCOPE-P0-TRD-00` estão `TODO`. O `EVIDENCE_REQUIRED` só existe na árvore de trabalho, editada por outra sessão (o arquivo mudou de novo às 14:29, sha corrente `064aec38…`). O mesmo vale para as linhas de `BT-UIEV-001` e `BT-WEB-003` e para as dependências novas de `BT-SCP-001`: não existem em `HEAD`.

Este projeto separa três eixos de propósito:

- **IMPLEMENTADO**: o código existe.
- **PROVADO**: um teste ou receipt exercita o código.
- **ABERTO**: a capability deixa alguém alcançar a superfície.

No repositório, o eixo ABERTO vale `0/29` para todas as capabilities: todas estão `off/false` em `server/config/release_capabilities.json:9-184`, com digest `ace782b3…`. **Em produção a situação é outra.** A última observação read-only registrada é de 2026-08-14. Ela mostra o servidor em `a6ee09c8` (`SERVER_BEHIND`), com `/capabilities` → `404` e os runtimes de IA e Battle habilitados (`docs/qa/execution/2026-08-14/BT-GOV-001.md:114-124`; `docs/execution/CURRENT_QUEUE.md:100-103`). Ou seja, a contenção medida aqui existe no repositório, não no servidor publicado, e não há observação posterior.

## Tabela-resumo do grupo

Legendas:

- **Asserções:** PRONTO_E_PROVADO / PRONTO_SEM_PROVA / PARCIAL / NAO_ENCONTRADO.
- **Trabalho:** arquivos a tocar · testes a escrever · migração · prova viva.

| ID | Declarado | Medido | Implementado | Provado | Aberto | Asserções | Trabalho | O que realmente falta |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `BT-SCP-001` | IN_PROGRESS_CONTAINED | **metade [ADV]** (era quase-la) | quase completo; **falta a contenção do fichário sob `collection_private` [ADV]** | unitário forte no app; parser Dart do backend com ~10 casos de falha sem teste **[ADV]**; gate amplo nunca alcançado | 0/29 | **10 / 3 / 4 / 0 [ADV]** (17 asserções; A1 e A6 desdobradas) | **7** (+2 do fichário, contados em TRD) · **3** (~10 casos de mutação + push + parametrizado compartilhado) · não · sim | Falta a contenção de troca/venda/matches no fichário, que o app apresenta sob `collection_private` (A8, **[ADV]**). Falta o gate amplo, e ele está mais longe do que parecia: a correção que falta a `BT-UIEV-001` mexe em scripts que estão no escopo do digest de UI e zera os 22/23 manifests capturados (**[ADV]**). Os três estágios que nunca rodaram podem exigir correção em `app/lib`, o que força outra recaptura. Faltam ainda as mutações do parser Dart, o teste de push/polling, a decisão same-SHA, o clean-SHA, a auditoria e o receipt. |
| `BT-OFFER-001` | IMPLEMENTED_LOCAL_PENDING_FULL_GATE | **quase-la** (mantido) | sim | 6 de 8 asserções | n/a (sem comércio) | 6 / 1 / 0 / 1 | 3 · 0 · não · sim | Não há trabalho próprio: a oferta está unificada e testada nas quatro camadas, com 0 commits nas superfícies desde o receipt de `BT-GOV-001`. **[ADV] Mas a data de fechamento é a do gate amplo de `BT-SCP-001`, que está longe.** O receipt depende de `BT-WEB-003`, dependência não declarada: o smoke morre no `npm audit` antes de checar a oferta no HTML. A autorização do bump é contraditória (achado 16). |
| `BT-AI-029` | TODO | **mal-comecada** (mantido) | contenção sim; registry não | 1 de 6 | 0/1 | 1 / 2 / 1 / 2 | **19 [ADV]** · 9 · não · sim (se a janela de telemetria for mantida) | A contenção veio de `BT-SCP-001`. Faltam: o registry machine-readable, a fixação em teste de `legacy_ai_routes` nas 4 rotas, a telemetria com grão de rota, a janela em produção (ou dispensa formal), a decisão adapter/410/remove e a execução. **[ADV]** A execução também mexe no mapa de contratos e no teste que o trava. Pela fila, a tarefa só entra depois de ~15 IDs (achado 15). |
| `SCOPE-P0-SOC-00` | EVIDENCE_REQUIRED (**`TODO` em HEAD [ADV]**) | **quase-la** (mantido, com ressalva) | sim, na matriz all-OFF. **[ADV] Não há separação real por flag nos endpoints compostos** | negação atual provada por composição; capability fixada em teste só em 8 das 32 combinações sociais | 0/9 | 7 / 1 / 2 / 1 | **7 [ADV]** · 2 · não · sim | Teste parametrizado que fixe a capability de cada uma das 40 combinações sociais e passe pelo middleware real; teste de push/polling; esconder o CTA de matches no fichário (compartilhado com TRD); receipt. **[ADV]** Perfil, feed de seguidos, detalhe de deck da galeria e marketplace devolvem dados de outras flags. Hoje isso não aparece porque as 9 flags estão OFF, mas decide se as flags podem abrir uma a uma (achado 13). |
| `SCOPE-P0-TRD-00` | EVIDENCE_REQUIRED (**`TODO` em HEAD [ADV]**) | **metade** (mantido) | proposta e match sim; **listagem não** | proposta e match por composição; **copy web sem prova em português [ADV]** | 0/2 | **3 / 1 / 2 / 1 [ADV]** | **12 [ADV]** · 3 (+3 ajustados) · não · sim, e move o digest de UI | A listagem nasce por `POST /binder` e `PUT /binder/:id` (`for_sale`, `for_trade`, `price`) sob `collection_private`. O app expõe troca/venda no fichário sem olhar capability. Contido só enquanto `collection_private` estiver OFF, e é capability core da beta. **[ADV]** Nenhum gate verifica "troca" ou "venda" em português, e o `.mjs` manual não tem "venda". |
| `BT-SCN-00` | TODO | **metade** (mantido) | CTA, rota e capability sim; câmera removida só no manifesto Android; **Web permite câmera [ADV]**; sync não | **2 de 6 [ADV]** | 0/1 | **2 / 1 / 2 / 1 [ADV]** | **5 [ADV]** · **2 [ADV]** · não · sim (APK release) | Receipt do verificador sobre um APK release. O único APK inspecionado (2026-07-17) **declarava câmera**. **[ADV]** O artefato Web da beta concede `camera=(self)` (`app/web/nginx.conf:41`), e um contrato de release trava esse valor (`scripts/manaloom_release_ops_contract_test.sh:286`). A cláusula de sync é o aceite de `BT-CAT-02`, que depende de `BT-CAT-01` (TODO). |

## Achados transversais

1. **Um gate amplo fecha quatro linhas do backlog, e hoje ele não chega ao fim.**
   - As linhas são `BT-SCP-001`, `BT-OFFER-001`, `SCOPE-P0-SOC-00` e `SCOPE-P0-TRD-00`. Todas pedem a bateria consolidada mais um receipt (backlog §5.2 `:171,:173`).
   - O `full` de 2026-09-21 terminou `EXIT=1` no `npm audit` (`docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:1-3`; `scripts/manaloom_public_web_smoke.sh:199`). O motivo: `web-public/package.json` ainda fixa `"next": "15.5.21"` (`:22`) e `overrides.sharp: "0.35.3"` (`:15-19`).
   - Depois viria `ui-audit`, que chama `ui_live_evidence` e portanto exige `BT-UIEV-001`. O `latest.json` segue no digest antigo `865e6041…`.
   - `custom-lint`, `patrol-smoke` e `dependency_audit` **nunca rodaram neste SHA**. Passaram em `fd0397a5a` (receipt de `BT-GOV-001`, `docs/qa/execution/2026-08-14/BT-GOV-001.md:66-68`). Depois disso entrou `f6f791098` (313 arquivos, `--no-verify`).
   - ~~Um mesmo `full` verde, com receipts separados por ID, move as quatro linhas.~~ **[ADV] Isso só vale sob uma condição, e hoje ela não se cumpre.** Ver 1a e 1b.
   - **1a. [ADV] `BT-UIEV-001` não está a um manifest de fechar. O conserto que falta zera os 22 já capturados.**
     - O digest de UI é global. Toda captura precisa ter `source_digest` igual ao corrente (`app/tool/ui_runtime_evidence.dart:598-599`, `capture source digest is stale`).
     - O escopo do digest inclui `scripts/manaloom_play_vs_ai_e2e.sh` e `scripts/manaloom_server_contract_e2e_isolated.sh` (`scripts/manaloom_ui_source_digest.sh:77-78`).
     - O manifest que falta, `play-vs-ai-web-real`, está bloqueado por uma corrida de handoff justamente entre esses dois scripts (`PONTO_DE_RETOMADA.md:40-46`; guarda em `manaloom_server_contract_e2e_isolated.sh:353-365`).
     - Consertar a corrida move o digest e invalida os 22 manifests já capturados em `8bba809c`: 216 screenshots dos 18 packs web e os 4 perfis `p0-matrix`, inclusive o do emulador Android, que só voltou a funcionar depois de `-wipe-data`. Depois disso é preciso reler todas as capturas (`reviewer_must_open_every_screenshot`) e reescrever `latest.json`.
     - O mesmo efeito vem de qualquer mudança em `app/lib` (`:27`) ou em `app/web` (`:29`).
   - **1b. [ADV] WIP-1 e o digest global se contradizem na tese de "um full, quatro linhas".**
     - SOC-00 (CTA de matches e teste de push) e TRD-00 (troca/venda do fichário) exigem mudanças em `app/lib`.
     - Sob WIP-1 (`CURRENT_QUEUE.md:41`), essas mudanças não podem entrar antes de `BT-SCP-001` sair do slot.
     - Se entrarem depois, movem o digest e pedem **um segundo ciclo completo** de recaptura e de gate para SOC-00 e TRD-00. `BT-OFFER-001` não mexe em código e pode ir junto com `BT-SCP-001`.
     - Saída legítima: essas correções de UI são aceite de `BT-SCP-001` ("app só apresenta o permitido", A8). Podem entrar no slot de `BT-SCP-001` **antes** da recaptura. Depois disso, SOC-00 e TRD-00 ficam só com trabalho de servidor e de teste, que não movem o digest.
   - **1c. [ADV] Ordem recomendada**, para não pagar a recaptura duas vezes:
     1. Rodar isoladamente os três estágios que nunca rodaram (`scripts/quality_gate.sh custom-lint`, `quality_gate.sh patrol-smoke`, `scripts/manaloom_dependency_audit.sh`; `quality_gate.sh:205-219`), antes de qualquer captura.
     2. Consertar a corrida do E2E.
     3. Fazer todas as mudanças de `app/lib` e `app/web` desta família.
     4. Só então recapturar.
2. **A oferta nunca foi checada no HTML renderizado neste SHA.**
   - O smoke roda com `set -euo pipefail` (`manaloom_public_web_smoke.sh:2`). Ele morre no `npm audit` (`:199`) antes de `manaloom_public_web_assert_free_beta_files` (`:300`).
   - O contrato de fonte mais amplo, `web-public/tests/free-beta-offer-contract.mjs`, é o único que cobre `troca`, `mercado` e `social` em todo o `src`. **Nenhum gate o invoca.** `git grep` só o acha em `package.json:13` e numa checagem de existência (`server/test/public_web_product_contract_test.dart:179-183`).
   - A checagem de oferta que roda no gate é `public_web_product_contract_test.dart:106-143`. Ela olha 3 arquivos e cobre só `trades?` em inglês.
   - **[ADV]** A landing é composta por mais arquivos do que esses 3: `layout.tsx` → `components/site-shell.tsx` (navegação e rodapé), `components/ui.tsx` e `components/brand-page-intro.tsx`. Nenhum deles está no teste do gate.
   - **[ADV]** O próprio `.mjs` não cobre "venda", "vender" nem "comprar". Ele tem `trocas?`, `mercado`, `preç`, `pro`, `upgrade`, `marketplace` e `social` (`web-public/tests/free-beta-offer-contract.mjs:20-28`). Hoje o `src` está limpo: meu grep só achou "plano" no sentido de plano de jogo e "compr" em "compreender".
3. **A lib de release só aceita a matriz all-OFF.**
   - `scripts/lib/manaloom_release_capabilities_contract.sh:114-115` exige `release_capability == "off"` e `allowed == false` em todas as entradas.
   - Esse loader é chamado por `manaloom_release_identity.sh:78`, `manaloom_deploy_backend_image.sh:1209`, `manaloom_deploy_ops_image.sh:218`, `manaloom_deploy_battle_sidecars.sh:43` e `manaloom_deploy_flutter_web.sh:38`.
   - O deploy do Flutter Web chama em seguida `manaloom_require_public_app_release_open` (`:40-41`), que exige ao menos uma capability ON com `live_verified_as_of` (`contract.sh:171-189`). As duas condições se excluem: **o deploy do Flutter Web é impossível em qualquer matriz**. E, no dia em que qualquer capability ligar, backend, ops, sidecars e identity também bloqueiam.
   - `docs/MAPA_OPERACIONAL_DO_PROJETO.md:251` registra só a primeira metade ("exige capability aberta").
   - Nenhuma tarefa do backlog nomeia a transição da lib para fora de all-OFF. É trabalho do eixo ABERTO, não defeito de contenção.
4. **A telemetria de negação não tem grão de rota.**
   - A métrica é gravada com a chave literal `RELEASE_CAPABILITY_DENIAL $denialReason` (`server/routes/_middleware.dart:117-121`), sem capability e sem método ou path.
   - O log tem a capability mas não o path (`:122-127`). A variável `endpoint` (`:60-61`) só é usada depois do handler (`:200-205`).
   - As métricas ficam em memória, por processo (`server/lib/request_metrics_service.dart:63-78`). `/health/metrics` exige chave operacional (`server/routes/health/_middleware.dart:6-11`; `lib/admin_access_support.dart:14-22` não a lista como pública).
   - Dois testes fixam a string literal da chave (`server/test/release_capability_policy_test.dart:380-381`, `:471-472`).
   - Isso impede `BT-AI-029` ("telemetria decide") e deixa qualquer receipt "por rota" de SOC/TRD dependente do corpo da resposta.
5. **Sob a matriz atual, a negação de toda rota está provada por composição. O que falta é fixar *qual* capability cada rota exige.**
   - A composição tem três peças:
     - o teste exaustivo percorre todo `routes/` e exige classificação não nula ou plano de controle (`release_capability_policy_test.dart:309-342`; meu port confirma 147/147);
     - com 29/29 OFF (`:14-36`), qualquer classificação não nula é negada;
     - o middleware real nega antes do handler (`:393-415`, `:417-438`, `:468-507`).
   - O risco aparece quando uma capability **core** abrir. Só 37 pares rota→capability estão fixados em teste (`:187-225`).
   - O caso concreto: se a regra de `server/lib/release_capability_policy.dart:450-452` sumir, `/decks/:id/recommendations|simulate` caem em `decks_private` (`:537-541`) e o teste exaustivo continua verde. As rotas sociais e `/ai/*` são fail-safe por estrutura: caem em "não classificada".
   - Só 4 requisições atravessam o middleware real em teste.
   - Um único teste parametrizado resolve SOC-00 D4, TRD-00 E7 e AI-029 C1, e reforça SCP-001: uma tabela `método path → capability esperada`, com passagem pelo middleware afirmando 404 e handler não chamado.
   - **[ADV] Duas correções a esta tese.**
     - O teste só fecha a rota futura (SCP A6b) se for **fechado por tabela**: toda combinação encontrada em `routes/` tem de estar na tabela, e combinação ausente falha. Sem isso, rota nova sob `/decks/`, `/binder/`, `/cards/` etc. herda a capability core em silêncio.
     - Ele **não** resolve D4 inteiro: fixa a flag por rota, mas não o dado que os endpoints compostos devolvem (achado 13).
6. **`collection_private` é a porta lateral de marketplace e trades.** Hoje só está contida porque `collection_private` está OFF, e ela abre na beta core.
   - **Servidor:** `POST /binder` (`server/routes/binder/index.dart:13-14,335-337,343-364`) e `PUT /binder/:id` (`server/routes/binder/[id]/index.dart:17,572-585`) gravam `for_trade`, `for_sale` e `price` sem consultar `marketplace` nem `trades`. `grep ReleaseCapability routes/binder lib/binder_item_contract.dart` dá zero.
   - **App:** o editor mostra "Disponível para troca/venda" e preço em R$ (`app/lib/features/binder/widgets/binder_item_editor.dart:1093-1160`). O fichário mostra "Troca"/"Venda" nos stats (`binder_screen.dart:963-976`), o CTA "Ver matches para faltantes" (`:993-1001`), chips de filtro (`:1702-1740`) e badges (`:2012-2023`). Nada disso olha capability.
   - **Documentação:** o contrato de API documenta `POST /binder` com `for_trade`, `for_sale` e `price` como `stable` (`server/doc/API_CONTRACTS_AND_DATA_MAP.md:146`). `docs/flows/social_trade.md:17-21` lista três achados que "sobrevivem ao desligamento", e esta porta lateral não está entre eles.
7. **Mexer em `app/lib` move o digest de UI** (`scripts/manaloom_ui_source_digest.sh:27`) e invalida os manifests de evidência viva.
   - A correção de app de TRD-00 carrega esse custo de recaptura.
   - As correções só de servidor (teste de SOC, telemetria de AI-029, bloqueio de TRD-00 no servidor) não carregam.
   - **[ADV] A lista de correções deste grupo que movem o digest é maior:**
     - o teste de push/polling de SCP A9 e SOC D5b. Os gates estão em métodos privados de `_ManaLoomAppState` (`app/lib/main.dart:932-949,1009-1026`). Um teste de comportamento praticamente exige extrair o predicado para um arquivo em `app/lib`;
     - o CTA de matches (SOC D5c) e troca/venda (TRD E6), em `binder_screen.dart` e `binder_item_editor.dart`;
     - a política de câmera do artefato Web (SCN F4): `app/web/nginx.conf` está no escopo (`:29`);
     - a correção da corrida do E2E, que pertence a `BT-UIEV-001` (achado 1a);
     - a correção de uma linha de `interactive_battle_service.dart` que aguarda o dono (`PONTO_DE_RETOMADA.md:55-63`).
   - **[ADV]** A fila da árvore de trabalho põe `BT-UX-KIT-001` (primitivas visuais em `app/lib`) logo depois de `BT-UIEV-001` (`CURRENT_QUEUE.md:55`). Ele também move o digest.
8. **Governança e dependências.**
   - WIP-1 vale: "Nenhum outro ID pode receber implementação enquanto este slot estiver aberto" (`docs/execution/CURRENT_QUEUE.md:41`). SOC-00, TRD-00 e AI-029 são os itens 9-11 da onda 01 (`docs/execution/waves/01-platform-safety.md:23-25`). SCN-00 está PARKED (`:27-28`).
   - A dependência declarada em `BT-SCP-001` é **tecnicamente formal**: manifesto, middleware e guards existem desde `b2d3fc04f` (2026-08-13) e `406d7dd53` (2026-08-25). **Pela governança ela é real.**
9. **O registry está defasado em relação ao backlog.**
   - `docs/generated/TASK_REGISTRY.json` (14:13) foi gerado de um backlog com sha `7584fbd…`. O backlog corrente (14:21) é `70bfb1d…` e o de HEAD é `333b6c0…`.
   - O registry ainda diz que `BT-SCP-001` depende só de `BT-GOV-001` e que `BT-UIEV-001` depende de `BT-SCP-001`.
   - O backlog já inverteu as duas: `BT-SCP-001` depende de `BT-GOV-001`, `BT-UIEV-001` e `BT-WEB-003` (`:225`), e `BT-UIEV-001` passou a não depender de ninguém (`:624`).
   - A circularidade foi resolvida no texto e falta regenerar.
   - **[ADV] Ela foi resolvida só na árvore de trabalho.** Em `HEAD`, a linha de `BT-SCP-001` ainda declara apenas `BT-GOV-001`, e `BT-UIEV-001` e `BT-WEB-003` nem existem no backlog. A fila admite isso: "ganharam linha no backlog em árvore de trabalho de 2026-09-22, ainda sem commit" (`CURRENT_QUEUE.md:44-47`, "Exceções ocorridas"). O backlog mudou de novo às 14:29 (sha `064aec38…`), depois da medição.
10. **Higiene de evidência (C17).**
    - `docs/qa/ui-live/current/ux-pack-05-social-trade-web-*` (`PASS_RUNTIME` em `8bba809c`) mostra marketplace, `R$` e CTAs de compra como superfície viva.
    - O pack monta as telas direto, sem passar pelo router (`app/integration_test/social_trade_visual_runtime_proof_test.dart:713,734`).
    - Está pendente decisão do dono: marcar ou aposentar o pack (`docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md:87`; `MAPA_OPERACIONAL:399,415-434`).
    - A decisão afeta o 23/23 de `BT-UIEV-001` e a leitura de "copy não promete venda/troca".
11. **Trabalho não commitado de outra sessão toca a rota de marketplace** (filtro de visibilidade e bloqueio). É ortogonal ao kill switch: a rota continua sob `marketplace` OFF. Não deve entrar em commit destas tarefas (`PONTO_DE_RETOMADA.md:108-117`).
12. **[ADV] O artefato Web da beta concede câmera, e um contrato de release trava esse valor.**
    - A beta é "Web e Android" (`docs/status/CURRENT_PRODUCT_DECISION.md:8`).
    - O nginx do Flutter Web emite `Permissions-Policy "camera=(self), microphone=(), geolocation=()"` (`app/web/nginx.conf:41`). O deploy empacota esse arquivo (`scripts/manaloom_deploy_flutter_web.sh:487,490`).
    - `scripts/manaloom_release_ops_contract_test.sh:286` **exige** esse literal. Consertar exige inverter o contrato.
    - O código do scanner também entra no bundle. `binder_screen.dart:368` e `binder_import_screen.dart:208` fazem `Navigator.push` direto para `CardScannerScreen`, com guarda só em runtime, e `main.dart:47` importa a tela sem condição.
    - O manifesto Android (`app/android/app/src/release/AndroidManifest.xml:3-15`) não tem equivalente para Web. SCN F4 vira PARCIAL.
13. **[ADV] As flags sociais estão separadas por rota, mas não por dado: os endpoints compostos vazam o conteúdo de outras flags.** O servidor exige **uma** capability por rota (`requiredCapabilityForRequest` devolve `String?`, `release_capability_policy.dart:377`). O app exige a conjunção (AND).
    - `GET /community/users/:id` exige só `profiles_public` (`:480-482`). Devolve `public_decks` (galeria), `follower_count` e `is_following` (follows) (`server/routes/community/users/[id].dart:29-60,114,170`). No app, `/community/user/*` exige 6 flags (`app/lib/core/config/release_capabilities.dart:419-429`).
    - `GET /community/decks/following` exige só `follows` (`:464-466`). É o feed de decks públicos (`community/decks/[id]/index.dart:17`). No app, a aba 1 exige `gallery_public` e `follows` (`:444-447`).
    - `GET /community/decks/:id` exige só `gallery_public`. Devolve dono e `comments_summary` (`community/decks/[id]/index.dart:43-44,235`). No app, exige 4 flags (`:431-439`).
    - O marketplace devolve nome e localização do dono (`community/marketplace/index.dart` @HEAD `:132-135,265-266`).
    - Com 9/9 OFF isso não aparece. No dia em que **uma** flag social abrir sozinha, a API autoritativa entrega mais do que o app mostra. Isso contraria a regra 2 da decisão ("app e Web apresentam apenas o que a API autoritativa permite", `CURRENT_PRODUCT_DECISION.md:76-77`) e o "flags separadas" da entrega de SOC-00.
    - O teste parametrizado do achado 5 **não** resolve isso: ele fixa a flag de cada rota, não o conteúdo que a rota devolve.
    - Decisão humana: declarar que as flags sociais abrem em bloco, ou fazer o servidor exigir um conjunto de capabilities por rota (lib, middleware e testes).
14. **[ADV] O padrão "porta lateral via capability core" do achado 6 se repete fora do fichário.** São três casos, fora do escopo destas tarefas, mas que o dono precisa ver junto:
    - **Deck público nasce sob `decks_private`.** `POST /decks` grava `is_public` do corpo (`server/routes/decks/index.dart:335,358-359`) sem olhar `gallery_public`. O app esconde o switch (`deck_list_screen.dart:434-436`). É aceite de `DCK-P0-00` ("deck novo privado").
    - **Visibilidade social se escreve pelo plano de controle.** `PATCH /users/me` é plano de controle, alcançável hoje com 29/29 OFF (`release_capability_policy.dart:610`). Aceita `profile_visibility`, `binder_visibility`, `trade_visibility`, `message_visibility` e `trade_notes` (`server/routes/users/me/index.dart:196-221`), e os defaults no banco são `public`/`everyone` (`server/bin/migrate.dart:2535-2537`; `server/database_setup.sql:17-21`). No dia em que uma flag social abrir, toda conta existente já é pública. É `SOC-P0-01` (`DEFERRED_BY_SCOPE`).
    - **`/market/*` tem classificação diferente no app e no servidor.** O app trata `/market` como `marketplace` (`release_capabilities.dart:495-499`). O servidor classifica `/market/movers` e `/market/card/:id` como `catalog_private` (`release_capability_policy.dart:531`), que é core. Não é promessa de venda, são cotações, mas as duas classificações divergem.
15. **[ADV] A dependência real de SOC-00, TRD-00 e AI-029 não é só `BT-SCP-001`.** A fila de trabalho (árvore de trabalho, não commitada) põe 12 IDs no horizonte imediato antes da onda 01, entre eles `BT-UIEV-001`, `BT-UX-KIT-001`, `BT-OFFER-001`, `BT-GATE-001/002`, `BT-DB-001/004/005`, `BT-CAP-001`, `BT-DR-001`, `BT-KPI-001` e `BT-OBS-001`. Dentro da onda 01, SOC-00, TRD-00 e AI-029 são os itens 9-11, depois de `DCK-P0-00` (`waves/01-platform-safety.md:22-25`). O horizonte está em `CURRENT_QUEUE.md:49-65`. Sob WIP-1, são ~13 IDs na frente de SOC-00, contando o próprio `BT-SCP-001`, e mais 1-2 para TRD-00 e AI-029. O registry não declara nada disso. A fila deriva do backlog e pode ser reordenada, mas hoje é a ordem publicada.
16. **[ADV] A autorização do bump de `BT-WEB-003` está em conflito.**
    - A linha nova do backlog, **não commitada** e escrita por outra sessão, diz "Bump autorizado pelo dono em 2026-09-21".
    - O `PONTO_DE_RETOMADA.md:69-74`, **commitado** em `d15beb05b`, diz "Aguarda decisão do dono — foi relatado por outra sessão que ele autorizou, mas autorização repassada por terceiro não foi aceita; precisa vir dele direto".
    - Até o dono confirmar diretamente, esse bloqueio do gate amplo depende de uma decisão humana, e não só de trabalho.

---

## BT-SCP-001 — Manifesto server-authoritative de capabilities

- **Backlog:** `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:225`.
- **Estado declarado:** `IN_PROGRESS_CONTAINED`. Slot `NOW` desde 2026-08-24T21:14Z (`docs/execution/tasks/BT-SCP-001.md:24`).
- **Dependências:** o registry diz `[BT-GOV-001]`; o backlog de trabalho diz `BT-GOV-001`, `BT-UIEV-001`, `BT-WEB-003`.
- **Aceite:** decomposto em 15 asserções. **[ADV]** Agora são 17: A1 virou A1a e A1b, e A6 virou A6a e A6b.
- **[ADV] Estado medido: `metade`** (era `quase-la`). O código está quase todo pronto, mas o fechamento, que é a condição de `PASS`, não está perto:
  - há uma lacuna real de contenção no fichário (A8);
  - rota nova sob prefixo core nasce com a capability core, e não negada (A6b);
  - o parser autoritativo tem ~10 casos de falha sem teste (A1b);
  - o gate amplo tem três estágios que nunca rodaram neste SHA e depende de `BT-UIEV-001`, que a própria correção pendente vai zerar (achado 1a);
  - a autorização do bump de `BT-WEB-003` é contraditória (achado 16).
  
  `BT-SCP-001` é dono do gate amplo: cada falha nos estágios não exercitados é trabalho dele, como foram os 5 defeitos de `07014b431` e `d26f23a16`.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| A1a **[ADV]** | Policy **ausente**, `allowed` contradizendo `release_capability`, `implementation_status` desconhecido (topo e entrada) ou override isolado não autorizado deixam as 29 capabilities OFF no backend | PRONTO_E_PROVADO | `server/lib/release_capability_policy.dart:257-260` (ausente), `:318-322` (contradição), `:292-294,310-312` (status), `:228-240,346-375` (override), `:629-644` (`_invalidPolicy`), `:150-152` (`isAllowed` exige `isValid`) | `server/test/release_capability_policy_test.dart:38-70`: arquivo inexistente dá `invalid_fail_closed` e 29 `allowed=false`; cópia com `catalog_private.allowed=true` fica inválida e toda OFF. `:72-108`: `implementation_status` desconhecido (topo e entrada) fica inválido e todo OFF. `:110-157`: override isolado rejeitado em 4 ambientes | — |
| A1b **[ADV]** | Policy **ilegível**, **JSON inválido**, JSON que não é objeto, **envelope errado** (`schema_version`, `product`, `release_channel`, `offer_mode`, `policy_version` vazio, `live_verified_as_of` inválido), `release_capability` fora do enum, `allowed` não booleano ou timestamp de entrada inválido deixam tudo OFF no backend | PRONTO_SEM_PROVA **[ADV]** (era PRONTO_E_PROVADO, dentro de A1) | `:262-268` (ilegível), `:271-279` (JSON e não-mapa), `:286-297` (envelope), `:313-315` (enum, bool, timestamp) | **Nenhum teste Dart exercita estes ramos.** Os únicos `load(configPath:)` com arquivo inválido são os de `:38-70` e `:72-108` (grep em `server/test`: nenhum outro arquivo carrega policy inválida). O shell testa enum e `allowed` para o parser dele (`manaloom_release_capabilities_contract_test.sh:110-112`), e o app testa o parser do cliente (`app/test/core/config/release_capabilities_test.dart:73-98`). **O parser autoritativo é o Dart do servidor, e ele não tem esses casos.** | ~8 mutações no mesmo loop de A2 (bytes não-JSON, lista, 4 campos de envelope, enum, `allowed:"false"`, timestamp sem `Z`) |
| A2 | Chave extra ou faltante (topo, `capabilities`, entrada) invalida a policy **no parser Dart** | PRONTO_SEM_PROVA | `_hasExactKeys` em `:286`, `:300-301`, `:309`, `:646-649` | Nenhuma mutação Dart remove ou acrescenta chave: o loop `:81-90` só muda status. Outros parsers têm prova: shell (`scripts/manaloom_release_capabilities_contract_test.sh:107-108`) e daemon Python (`server/test/manaloom_ops_daemon_test.py:110-155`) | 2-3 mutações no loop `:81-90` (`del capabilities.ads`, `capabilities.unknown=…`, chave extra na entrada) |
| A3 | Snapshot inválido, HTTP ≠ 200, exceção ou resposta antiga deixam OFF no app | PRONTO_E_PROVADO | `app/lib/core/config/release_capabilities.dart:112-142`, `:193-208`, `:273-304`, `:306-311`, `:319-321` | `app/test/core/config/release_capabilities_test.dart:51-71` (contradição); `:73-98` (8 mutações de envelope, inclusive chave extra e `capabilities` removida); `:100-141` (entrada faltando, malformada ou extra); `:166-196` (503 e exceção dão `unavailable` e OFF); `:220-253` (reset invalida load em voo); `:255-305` (falha nunca preserva permissão anterior); `:307-349` (resposta antiga não sobrescreve a nova) | — |
| A4 | Scripts de release e daemon ops falham fechado | PRONTO_E_PROVADO | `scripts/lib/manaloom_release_capabilities_contract.sh:56-122`; `server/bin/manaloom_ops_daemon.py:145-192`, `:711-743` | `manaloom_release_capabilities_contract_test.sh:107-138`: 7 mutações, policy ausente, digest misto e chave desconhecida bloqueiam. `manaloom_ops_daemon_test.py:87-155,182-219`: triggers suprimidos com OFF; policy inválida agenda só o governor | — |
| A5 | API nega antes de PG e observabilidade (mecanismo) | PRONTO_E_PROVADO | `server/routes/_middleware.dart:105-144` antes de `:146-161` (`ensureObservabilityInitialized`, `_db.connect()`) | `:371-391`: ordem no fonte. `:393-415`: `GET /ai/battle/jobs` dá 404 `capability_unavailable`, `capability=battle_batch`, handler não chamado (o contexto lança em qualquer `read`, `:538`). `:440-466`: policy inválida dá 503 antes do handler | Só 4 requisições atravessam o middleware real (achado 5) |
| A6a **[ADV]** | Toda rota existente é classificada ou plano de controle | PRONTO_E_PROVADO | `:168-177` (`capability_route_unclassified`), `:377-545`, `:547-620` | `:309-342` percorre `routes/` (meu port: 147 combinações, 0 órfãs); `:344-368` (allowlist exata, 10 negativos) | — |
| A6b **[ADV]** | Rota futura falha fechada | PARCIAL **[ADV]** (era PRONTO_E_PROVADO, dentro de A6) | Falha fechada **só fora das famílias de prefixo**: `POST /future-unclassified-mutation` e `POST /ai/<novo>` caem em `null` e depois em `capability_route_unclassified`. **Dentro** de `/decks/`, `/import/`, `/binder/`, `/cards/`, `/sets/`, `/rules/` e `/market/`, rota nova herda a capability core da família (`:525-542`). No port: `POST /decks/:id/ai-autopilot` dá `decks_private`, `POST /binder/:id/publish` dá `collection_private`, `POST /cards/:id/sync` dá `catalog_private` | `:295-307` e `:468-507` só testam um caminho de nível raiz. O teste exaustivo aceita qualquer valor não nulo | Com a matriz-alvo (core ON), uma funcionalidade nova sob `/decks/:id/` nasce aberta sem ninguém classificar. É o mesmo mecanismo pelo qual `recommendations` e `simulate` escapariam (achado 5). Correção sem mudar o desenho: o teste parametrizado do achado 5 deve exigir que **toda** combinação encontrada em `routes/` esteja na tabela. Rota nova então falha no teste até ser classificada de propósito |
| A7 | App roteia só para o permitido | PRONTO_E_PROVADO | Guard `release_capabilities.dart:350-534`; ligado em `app/lib/main.dart:104-109,426-434` | `release_capabilities_test.dart:361-406` (29 destinos negados redirecionam); `:408-461` (servidor AND build); `:463-487`, `:489-522`, `:524-575`. Vivo: pack `p0-matrix` `PASS_RUNTIME` em `8bba809c` (receipt `btuiev001-chromedriver-e-recaptura.md`) | `latest.json` não reescrito (`BT-UIEV-001`) |
| A8 | App apresenta só o permitido: navegação, home, perfil, login, menus **e as superfícies alcançáveis de cada capability** | PARCIAL **[ADV]** (era PRONTO_E_PROVADO) | Gates corretos em `app/lib/core/widgets/main_scaffold.dart:26-65`; `main.dart:447-452` com `login_screen.dart:289`; `_ProfileReleaseAccess`. **Falha [ADV]:** sob `collection_private`, o fichário apresenta o CTA "Ver matches para faltantes" (`binder_screen.dart:472,993-1001`), que é superfície de `trades`, e troca/venda com preço em R$ (`binder_item_editor.dart:1093-1160`; `binder_screen.dart:963-976,1702-1740,2012-2023`), sem olhar `trades` nem `marketplace` | `main_scaffold_test.dart:76-130` (sem glifo Comunidade com só decks+coleção) e `:132` (presente com `galleryPublic`). `home_screen_test.dart:390-422`: all-off, nenhum botão de produto, `fetchCalls == 0`. `profile_screen_test.dart:485-560`: "Perfil não publicado", 11 chaves ausentes, Marketplace, Meu Fichário e Ações de IA ausentes. `auth_screens_test.dart:68-77`: "Criar conta" ausente. **Todos esses testes estão certos, mas nenhum cobre o fichário** | Condicionar o CTA de matches a `trades`, e troca/venda a `trades`/`marketplace` (ou decidir que são metadado privado). É o mesmo trabalho de TRD E6 e SOC D5c, contado em TRD. O que conta é a matriz que o produto abre primeiro: `collection_private` é `OFF_UNTIL_P0_RECEIPT` (`CURRENT_PRODUCT_DECISION.md:58`), e a regra 2 da decisão proíbe apresentar o que a API não permite (`:76-77`). "Nenhum código de contenção falta" era falso |
| A9 | Push e polling sociais só com capability | PRONTO_SEM_PROVA | `main.dart:921-930` (callbacks de push), `:932-949` (`_canHandleRealtimeData`), `:1009-1026` (`_onReleaseCapabilitiesChanged` para polling e push), `:1041-1083` (warmup só inicia com capability), `:1085-1100` | Só presença de token (`release_capability_surface_contract_test.dart:14-15`). Nenhum teste de comportamento: `grep socialPush\|startPolling app/test` não acha teste do gate | 1 teste (unitário do predicado extraído, ou widget com provider semeado). **[ADV]** Os três gates são métodos privados de `_ManaLoomAppState`, que usa singletons globais. Na prática, testar exige extrair o predicado para `app/lib`, e isso move o digest de UI (achado 7). Detalhe menor: com `social_push` ON, payloads que não são DM, trade nem follower passam sem checar `comments` ou `gallery_public` (`:950`) |
| A10 | Nenhuma rota espectador pública | PRONTO_E_PROVADO | Servidor `:403-405` (`battle_live`); app `app/lib/core/config/launch_features.dart:20-25` (default false); `main.dart` sem `battle-live` | Servidor `:207`. App `release_capability_surface_contract_test.dart:109-119` (sem `battle-live/:jobId` e sem `BattleLiveSpectatorScreen`) e `:133-148` (5 tokens de espectador ausentes no Battle Lab) | — |
| A11 | Implementação interativa guardada usa a direção Jogar contra IA | PRONTO_E_PROVADO (fonte e rota) | `main.dart:675-718` (`play-vs-ai` atrás de `LaunchFeatures.interactiveBattleSupported`; `battle-coach` virou redirect); servidor `:399-402` (`battle_coach`) | `surface_contract_test.dart:17-19,120-132` (sem `.runBattleTest(` e sem `automatic`); `release_capabilities_test.dart:370-371,524-575`; `launch_features_test.dart:26-59` | E2E real ainda não voltou a passar no HEAD (`BT-SCP-001.md:163-166`). Isso é de `BT-PLAY-*` e `BT-UIEV-001`, não da contenção. **[ADV]** Mantido como provado **só no nível de contrato**: guard de rota comportamental (`:524-575`), rejeição de replay com `engine: forge` no runtime interativo (`server/test/interactive_battle_runtime_client_test.dart:232-260`) e varredura de fonte. A própria decisão avisa que "fixture, mock, golden e widget test [...] não provam esse resultado" (`CURRENT_PRODUCT_DECISION.md:96-98`). A prova real é o manifest `play-vs-ai-web-real`, preso em `BT-UIEV-001` (achado 1a) |
| A12 | Cadastro novo tem capability própria e OFF; login, recuperação e privacidade são plano de controle | PRONTO_E_PROVADO | Servidor `:385-387`, `:590-620`; json `:10-15`; app `release_capabilities.dart:358-361`, `main.dart:320-329,447-452` | Servidor `:417-438` (runtime `POST /auth/register` dá 404 antes do handler); `:248-277` (16 rotas de plano de controle dão `null`); `:344-368`. App `:363` e `auth_screens_test.dart:68-77` | — |
| A13 | Same-SHA registra a matriz | PARCIAL | `scripts/manaloom_release_identity.sh:76-97` embute policy e digest; `manaloom_deploy_backend_image.sh:1764-1766` compara `/capabilities` vivo pós-deploy | `manaloom_release_capabilities_contract_test.sh:25-47`: em repo fixture, a identity carrega o digest `ace782b3…` e 29 entradas OFF | Identity do SHA real é recusada: exige `source == HEAD == origin/master` (`identity.sh:45-52`) e worktree limpo (`:54-60`). A branch está 29 à frente e o worktree tem 62 entradas. Produção está `SERVER_BEHIND`, com `/capabilities` 404. **Sobrepõe `BT-REL-002`** (backlog `:612`, `BLOCKED_BY_P0` via `BT-REL-001`, que depende de `BT-SCP-001`). **[ADV]** O mecanismo só registra a matriz all-OFF: o loader recusa qualquer entrada `on` (`scripts/lib/manaloom_release_capabilities_contract.sh:114-115`). "Registra a matriz" está provado para uma única matriz (achado 3) |
| A14 | `implementation_status`, `release_capability` e `live_verified_as_of` são eixos distintos | PRONTO_E_PROVADO | Servidor `:58-63,80-99,198-211`; `allowed` derivado por contrato (`:320`); app `:46-68` (cliente não infere acesso dos eixos informativos) | Servidor `:14-36` (29/29 `liveVerifiedAsOf == null`); app `:34-49` | — |
| A15 | Gate amplo verde no SHA, clean-SHA, auditoria independente e receipt (condição de `PASS`) | PARCIAL **[ADV]** (era NAO_ENCONTRADO; o rótulo sobe, a conclusão não muda) | Existe uma execução parcial documentada. O `full` rodou até o `npm audit` com zero falha de teste nos estágios alcançados, 5 defeitos corrigidos e revisão adversarial (`btscp001-gate-amplo.md:240-260,346-391`), num SHA anterior (base `b4473a98a`). **Em `d15beb05b`, nenhum estágio rodou** | `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:1-3` (`PARCIAL · GATE_AMPLO_NAO_ALCANCADO`); ficha `:311-317` (produção não reobservada; 5 bloqueios); 16 commits com `--no-verify` (`git log --grep=no-verify -i`) | `BT-WEB-003`, com autorização contraditória (achado 16); `BT-UIEV-001` 23/23, que será zerado pela própria correção pendente (achado 1a); `custom-lint`, `patrol-smoke` e `dependency_audit`; hooks; auditor; receipt. **[ADV]** O clean-SHA também exige checkout isolado: o worktree compartilhado tem 62 entradas sujas de outras sessões, uma delas em fonte de servidor (`server/routes/community/marketplace/index.dart`) |

**O que realmente falta.**

~~Não falta código de contenção~~ **[ADV] Falta um pedaço de código de contenção:** o fichário apresenta troca, venda e o CTA de matches sob `collection_private` (A8). Manifesto, parsers, middleware, guard, plano de controle, cadastro separado e eixos existem. Faltam quatro frentes.

0. **[ADV] Contenção do fichário (A8).** Condicionar o CTA de matches e troca/venda a `trades`/`marketplace`, em `binder_screen.dart` e `binder_item_editor.dart`. O trabalho está contado em TRD E6. **Recomendo fazer no slot de `BT-SCP-001`, antes da recaptura** (achado 1b).
1. **Provas pequenas:**
   - A1b + A2: **~10 mutações Dart** **[ADV]** (eram 2-3), no loop de `:81-90`;
   - A9: 1 teste de push/polling, que na prática exige extrair o predicado de `main.dart` e move o digest.
   - **[ADV]** A6b: o teste parametrizado fechado por tabela (achado 5). É compartilhado com SOC D4, TRD E7 e AI C1, e só de servidor. Estava contado nas outras tarefas e agora conta aqui também.
2. **Fechamento, que depende de outros IDs:**
   - `BT-WEB-003`: `web-public/package.json` e `package-lock.json`. ~~bump autorizado pelo dono em 2026-09-22 (backlog `:632`)~~ **[ADV]** A linha não commitada diz autorizado em 2026-09-21. O `PONTO_DE_RETOMADA.md:69-74`, commitado, diz que a autorização veio por terceiro e não foi aceita. Precisa de confirmação direta do dono (achado 16);
   - `BT-UIEV-001`: consertar a corrida do E2E e recapturar `play-vs-ai-web-real`. **[ADV] O conserto move o digest e invalida os outros 22 manifests.** Na prática: recapturar 18 packs web (216 screenshots) e 4 perfis `p0-matrix` (inclusive o do emulador Android), reler tudo e reescrever `latest.json` (achado 1a);
   - rodar os três estágios que nunca rodaram. O número de arquivos que eles vão exigir é **desconhecido**. **[ADV]** Rode-os isoladamente **antes** da recaptura: uma correção de lint em `app/lib` depois dela zera a evidência de novo (achado 1c).
3. **Decisão humana sobre A13:** aceitar a prova de mecanismo (identity em fixture) e deixar a observação de produção para `BT-REL-002`, ou exigir merge em `origin/master` com observação read-only ou deploy autorizado.

Números:

- Arquivos próprios: ~~6~~ **7 [ADV]**: o teste de servidor, um teste de app, o arquivo de `app/lib` com o predicado de push extraído, a ficha, o receipt, a linha do backlog e o registry regenerado. Somam-se os 2 do fichário (A8, contados em TRD), 4 via dependências (mais os 23 manifests e `latest.json` de `BT-UIEV-001`) e os desconhecidos dos estágios que nunca rodaram.
- Testes: ~~2~~ **3 [ADV]**: mutações do parser (~10 casos, não 2-3), push/polling e o parametrizado fechado por tabela (compartilhado; pode ficar no mesmo `release_capability_policy_test.dart`).
- Migração: não.
- Prova viva: sim (gate com `ui-audit`).
- Serviço externo: registry npm para o bump. Produção só se A13 exigir observação.
- Dependências: `BT-GOV-001` é real e está `PASS`. `BT-UIEV-001` e `BT-WEB-003` são reais, mas **[ADV]** só estão no backlog da árvore de trabalho, não em `HEAD`. O registry está defasado.
- **[ADV] Decisões humanas, somando às 3 da medição:**
  - (4) confirmar diretamente o bump de `BT-WEB-003`;
  - (5) troca e venda do fichário: metadado privado permitido por `collection_private` ou superfície de `trades`/`marketplace`. O CTA de matches é superfície de `trades` em qualquer leitura;
  - (6) absorver as correções de UI de SOC e TRD no slot de SCP, ou aceitar dois ciclos de recaptura.

---

## BT-OFFER-001 — Oferta pública unificada

- **Backlog:** `:226`.
- **Estado declarado:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **Dependências:** o registry diz `[BT-GOV-001]`.
- **Aceite:** 8 asserções.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| B1 | Landing: uma única oferta (Beta gratuita, sem cobrança), sem Pro, preço, checkout, upgrade, trade ou marketplace | PRONTO_E_PROVADO | `web-public/src/app/pricing/page.tsx:13-67` ("Uma única oferta", "Sem cobrança durante a beta"); `web-public/src/lib/product-data.ts:39-44` | **No gate:** `server/test/public_web_product_contract_test.dart:106-143`. Em `page.tsx`, `pricing` e `product-data`, exige `id: "free-beta"`, "Beta gratuita", gratuit/grátis e "sem cobrança", e proíbe `pro`, `checkout`, `trades?`, `marketplace`, `upgrade` e `R$ n`. Passou nas 46 batches de backend de 2026-09-21. **Fora do gate:** `web-public/tests/free-beta-offer-contract.mjs:20-72` (todo o `src`, inclusive `troca` e `mercado`) não é chamado por nenhum script. O HTML renderizado (`manaloom_public_web_surface_contract.sh:107-146`, via smoke `:300`) não rodou neste SHA (achado 2). **[ADV] Mantido como provado, com ressalva:** a oferta vive nos 3 arquivos testados, e isso sustenta a parte positiva. A parte negativa ("sem Pro, preço…") só é verificada nesses 3 dos ~6 arquivos que compõem landing e pricing. `site-shell.tsx`, `ui.tsx` e `brand-page-intro.tsx` ficam fora do gate. Hoje estão limpos (meu grep) | Plugar `npm run test:contract` no smoke (1 linha; opcional) |
| B2 | App: mesma oferta, tier único, sem checkout ou upgrade funcional | PRONTO_E_PROVADO | `app/lib/features/commercial/models/commercial_launch_policy.dart:6-14` (`paidCheckoutEnabled=false`, const); `manaloom_plan.dart:3,13-20,33,49-67`; `checkout_screen.dart:37-44`; `upgrade_screen.dart:10-40` | `manaloom_plan_test.dart:6-20`: `paidCheckoutEnabled` false, tier único, "Sem cobrança", 120, "não define preço". `checkout_screen_test.dart:6-18`: painel "Checkout não está disponível", sem botões de pagar e sem `R$` | — |
| B3 | Backend: mesma oferta; checkout 403 `beta_free_only`, webhook 410, sem escape hatch | PRONTO_E_PROVADO | `server/routes/users/me/plan/index.dart:17-29`; `server/lib/plan_service.dart:75-116` (`PaidPlanActivationDisabled`, `activeOfferName='free'`); `server/lib/billing/payment_provider.dart` | `server/test/payment_provider_url_test.dart:15-30`, em runtime: checkout `pro` dá 403 e webhook dá 410. `plan_checkout_contract_test.dart:6-49`: sem `MANALOOM_INTERNAL_CHECKOUT_ENABLED`, `ALLOW_INTERNAL_PRO_ACTIVATION`, `checkout_url` e `2500`. **[ADV]** O provider é provado em runtime. A ligação rota→provider, `is_free` do `GET /users/me/plan` e `activatePro` que lança exceção são provados só por leitura de fonte (`plan_checkout_contract_test.dart:6-49`; `plan_service_test.dart:63-100`). Somado a B5 (capability OFF antes do handler), é suficiente | — |
| B4 | Contratos documentados usam a mesma oferta | PRONTO_SEM_PROVA | `server/doc/API_CONTRACTS_AND_DATA_MAP.md:93-95` ("no upgrade offer"; checkout `beta-disabled`); `docs/status/CURRENT_PRODUCT_DECISION.md:31-46` | `api_contracts_data_map_guard_test.dart` não cobre plan/checkout. Nenhum teste lê a semântica desses docs | Risco baixo; opcional |
| B5 | Checkout e paywall inacessíveis no servidor por API direta | PRONTO_E_PROVADO | Capability `billing_checkout` OFF (`release_capability_policy.dart:519-523`; json `:136-141`) somada ao provider fail-closed (B3); `art_paywall`/`ads` `not_implemented` e OFF (json `:148-159`) | `release_capability_policy_test.dart:221,278-285` (`POST` checkout/webhook dão `billing_checkout`; `GET` webhook dá `null`); runtime do provider em B3 | — |
| B6 | Checkout e paywall inacessíveis no app | PRONTO_E_PROVADO | Guard `release_capabilities.dart:514-518`; `main.dart:104-109` (`billingCheckout: CommercialLaunchPolicy.paidCheckoutEnabled`, const false); nenhum `context.go/push` para `/upgrade` ou `/checkout` em `app/lib` (grep) | `release_capabilities_test.dart:388-389` (dá `/plans`); `:453-460` (dá `/plans` mesmo com capability ON se o build não suporta) | — |
| B7 | Limites coerentes entre app e backend (teto operacional 120) | PRONTO_E_PROVADO | App `manaloom_plan.dart:33`; servidor `plan_service.dart:94`; a landing não anuncia número (`product-data.ts:54`) | `manaloom_plan_test.dart:12` (`== 120`); `server/test/plan_service_test.dart:68` (`== 120`) | — |
| B8 | Bateria consolidada e receipt próprio no SHA corrente | NAO_ENCONTRADO | — | Único receipt é o de `BT-GOV-001` (`docs/qa/execution/2026-08-14/BT-GOV-001.md:36-60`, @ `fd0397a5a`). `git log fd0397a5a..HEAD` nas superfícies de oferta (web-public/src e tests, app/lib/features/commercial, rotas plan e billing, `plan_service`, lib/billing) dá **0 commits**. A DoD 8 (`backlog:187`) proíbe reuso histórico | Gate amplo mais receipt |

**O que realmente falta.**

A substância do aceite está entregue e testada nas quatro camadas. O código de oferta é idêntico ao que `BT-GOV-001` provou com `full` verde.

Falta só o receipt no SHA corrente. Ele depende do mesmo gate amplo de `BT-SCP-001` e de uma dependência **não declarada**, `BT-WEB-003`: o smoke do site que carrega a oferta morre no `npm audit` (`:199`) antes de verificar a oferta no HTML (`:300`).

Números:

- Arquivos: 3 (receipt, linha do backlog, registry regenerado); mais 1 opcional (plugar o `.mjs` no smoke).
- Testes: 0.
- Migração: não.
- Prova viva: sim (gate; o smoke é local, e nenhum contrato bate na URL pública).
- Decisão humana: ~~nenhuma~~ **[ADV]** nenhuma sobre a oferta. O caminho de fechamento, porém, passa pela confirmação direta do bump de `BT-WEB-003` (achado 16) e pela decisão C17, que mexe nos 23 manifests.
- Dependência `BT-GOV-001`: real e `PASS`.

**Sobreposição:** `BT-GOV-001` já provou esta oferta, e este ID fecha com o mesmo `full` que fechar `BT-SCP-001`.

**[ADV] `quase-la` mantido, lido como "sem trabalho próprio".** Não há código a escrever. A data de fechamento, porém, é exatamente a do gate amplo de `BT-SCP-001`, que está longe (achados 1a-1c). Quem planejar por este rótulo não deve esperar este ID fechado antes de `BT-SCP-001`.

---

## BT-AI-029 — Registry de rotas IA: consumer, writes, capability, owner e substituto

- **Backlog:** `:450`.
- **Estado declarado:** `TODO`.
- **Dependências:** `BT-SCP-001`, `BT-DOC-004` (`PASS`).
- **Descrição na onda 01** (`waves/01-platform-safety.md:25`): acrescenta "reachability real, registry validation-only, owner/substituto/expiry e zero órfão desconhecido". Isso é praticamente o aceite de `BT-GATE-004` (P1, backlog `:619`), que depende deste ID.
- **Aceite:** 6 asserções.

Nota sobre "simulate legado": é `GET /decks/:id/simulate`, conforme `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md:372,415-418`. `/ai/simulate` é superfície atual sob `battle_batch`, consumida pelo app (`battle_replay_service.dart:440,503`).

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| C1 | As 4 rotas nomeadas ficam sob capability própria OFF (`legacy_ai_routes`) e não abrem junto com `decks_private` | PRONTO_SEM_PROVA | `release_capability_policy.dart:446-454`; json `:172-177` (`contained_legacy`, OFF). Meu port confirma que `POST /decks/:id/recommendations`, `GET /decks/:id/simulate`, `POST /ai/simulate-matchup` e `POST /ai/weakness-analysis` dão `legacy_ai_routes` | Só `GET /ai/ml-status` está fixado (`release_capability_policy_test.dart:224`). O teste exaustivo `:309-342` só exige "não nulo": sem a regra de `:450-452`, as duas rotas `/decks/:id/…` cairiam em `decks_private` (`:537-541`, core) e ele continuaria verde | 4 linhas no mapa `expected` (`:187-225`) |
| C2 | Negação antes de PG e provider, na matriz atual | PRONTO_E_PROVADO (por composição) | Middleware raiz `_middleware.dart:105-144` antes de `:146-161`. Handlers só leem `Pool` e provider por dentro: weakness `:43` (INSERT `deck_weakness_reports` `:654`); simulate-matchup `:54` (upsert `deck_matchups` `:490-493`); recommendations `:23,26` (`OpenAiRuntimeConfig`); decks simulate `:15`. Middlewares aninhados rodam depois (`routes/ai/_middleware.dart:63-89`; `routes/decks/[id]/recommendations/_middleware.dart:7-10`) | `:309-342` (as 4 dão não nulo), `:14-36` (29 OFF), `:393-415` (runtime nega antes do handler) | Nenhuma das 4 atravessa o middleware real em teste (entra no teste parametrizado do achado 5) |
| C3 | Registry machine-readable de **todas** as rotas IA (consumer, writes, capability, owner, substituto; e, pela onda 01, expiry e zero órfão) | NAO_ENCONTRADO | Só existe: a tabela manual `…CURRENT_FLOW…:357-373` (14 linhas, sem owner, substituto ou expiry), que diz em `:375-376` que "deve virar registry machine-readable em BT-AI-029"; `docs/generated/openapi.generated.json` (121 paths; só `x-manaloom-source`, `-contract-level` e `-tests`, e `tests` é heurístico e ruidoso); `project_logic_manifest.json > api_routes` (path, métodos, middleware); `TASK_REGISTRY.json > route_consumers` (57 entradas por fluxo, nenhuma rota legada). Nenhuma fonte tem campo "reason" (`MAPA_OPERACIONAL:396`, C14) | — | Universo: 26 combinações em `server/routes/ai/**` (21 arquivos) mais ~10 IA de deck (analysis, ai-analysis, optimizations, rollback, recommendations, simulate, battle-*). Arquivo de dados, validador ou gerador no project-logic, e teste de consistência com `requiredCapabilityForRequest` |
| C4 | As rotas nomeadas não têm consumer no app, web ou ops | PRONTO_SEM_PROVA | `app/lib`: só `app/lib/core/api/api_client.dart:196-199` (heurística de timeout `endsWith('/recommendations')`); `web-public/src`: nada; scripts, tools e `server/bin`: nada (`cron_sync_combos.sh:9` é comentário) | Nenhum teste afirma ausência | 1 teste de fonte (app) |
| C5 | Telemetria por rota capaz de decidir adapter/410/remove | PARCIAL | Achado 4: chave sem capability e sem rota (`_middleware.dart:117-121`); log sem path (`:122-127`); métrica em memória por processo, atrás da chave operacional. Produção não roda este SHA (última observação: `/capabilities` 404) | `:468-507` afirma só o contador de `capability_route_unclassified` | 1 fonte, 2 testes ajustados (`:380-381`, `:471-472`) e 1 novo. Depois, uma janela em produção (deploy do SHA, que exige autorização; leitura de `/health/metrics` com chave ops) **ou** dispensa formal da janela: com a rota OFF e consumer zero, o dado esperado é 0 |
| C6 | Decisão por rota (adapter, 410 ou remover) e execução, com "zero consumidor ativo e substituto canônico" (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:177`) | NAO_ENCONTRADO | — | Testes existentes que tratam as rotas como feature e teriam de sair ou mudar: `server/test/deck_recommendations_route_adapter_test.dart` (338 l.), `deck_simulate_route_adapter_test.dart` (277 l.), `ai_weakness_analysis_live_test.dart`, `ai_optimize_telemetry_contract_test.dart`, `e2e_ml_tests.py`, `test_reco.sh`. **[ADV]** Mais dois: `server/test/api_contracts_data_map_guard_test.dart:91-128` trava a documentação dessas rotas como contrato vivo ("This is a write route", `legacy_monte_carlo`, `simulation.{runs,seed,wins,losses`), e `server/doc/API_CONTRACTS_AND_DATA_MAP.md` precisa mudar junto. `scripts/manaloom_e2e_suite.sh:595` roda os dois adapter tests no E2E | Decisão humana por rota; depois, 4 handlers, ~5 arquivos de teste, **o mapa de contratos e o guard dele [ADV]** e a linha do E2E suite |

**O que realmente falta.**

A metade "fica OFF antes de PG/provider" foi entregue por `BT-SCP-001` (`b2d3fc04f`/`406d7dd53`), e ninguém moveu o estado. A entrega nominal desta tarefa não começou: o registry. Além dele, faltam telemetria com grão de rota, uma janela de observação ou a dispensa dela, a decisão por rota e a execução.

**Antes da decisão:** ~8 arquivos.

- registry de dados;
- validador;
- teste de consistência;
- `_middleware.dart`;
- `release_capability_policy_test.dart`;
- teste de fonte no app;
- docs gerados pela ferramenta;
- receipt.

**Depois da decisão:** ~~~9~~ **~11 [ADV]** arquivos: 4 handlers, 5 de teste, `API_CONTRACTS_AND_DATA_MAP.md` e seu guard. O total vai de 17 para **~19**. **[ADV]** Base parcial para a parte "reachability" da onda 01: `server/lib/source_reachability_audit.dart` (131 l.) já classifica **arquivos** em runtime, operacional, validation-only e órfão. Não conhece rotas, consumers nem owners, então não reduz o registry de C3. Reduz trabalho de `BT-GATE-004`.

**Testes:** 9 no total.

- 5 antes: fixação de C1, runtime parametrizado, chave de telemetria, ausência de consumer, consistência do registry.
- 4 depois: um por rota em 410 ou remoção.

**Migração:** não. Descartar `deck_weakness_reports` e `deck_matchups` seria decisão separada, próxima de `BT-AI-027` e `BT-DB-005`.

**Prova viva:** sim, se a janela de telemetria for mantida. Nesse caso exige produção (Easypanel) e a chave ops.

**Dependências:**

- `BT-SCP-001`: formal técnica (a classificação existe); real pela WIP-1.
- `BT-DOC-004`: real e `PASS`.
- Não declarada: autorização de deploy, para que a telemetria exista.

**Sobreposições:**

- C2 coincide com SCP-001 A5/A6.
- O teste parametrizado é o mesmo de SOC-00 e TRD-00.
- `ml-status` também é de `BT-AI-027` (backlog `:448`).
- A descrição da onda 01 coincide com `BT-GATE-004`.

---

## SCOPE-P0-SOC-00 — Flags sociais separadas, todas OFF

- **Backlog:** `:552`.
- **Estado declarado:** `EVIDENCE_REQUIRED`. **[ADV]** Só na árvore de trabalho. Em `HEAD` é `TODO` (`git show HEAD:…:546`).
- **Dependências:** `BT-SCP-001`. **[ADV]** Pela fila, também os ~12 IDs do horizonte e `DCK-P0-00` (achado 15).
- **Onda 01** (`:23`): "cada rota e consumer negados antes de PG; release identity registra OFF".
- **Aceite:** 11 asserções.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| D1 | 9 flags server-side separadas (gallery, profiles, comments, follows, user search, DM, public binder, trades, push) | PRONTO_E_PROVADO | `release_capability_policy.dart:27-35`; json `:76-129`; app `release_capabilities.dart:19-27` | Servidor `:23` (conjunto exato de chaves) e `:211-219` (uma rota por flag); app `release_capability_surface_contract_test.dart:162-177` (enum igual às chaves do json) | — |
| D2 | Todas OFF | PRONTO_E_PROVADO | json `:76-129` | Servidor `:26-29`; shell `manaloom_release_capabilities_contract_test.sh:45-47` | — |
| D3 | API direta nega antes de PG, na matriz atual, para toda rota social | PRONTO_E_PROVADO (por composição) | Classificação `:456-514`; plano de controle `:547-586`; middleware `_middleware.dart:105-144`. 34 arquivos e 40 combinações rota×método em `routes/{community,trades,conversations,notifications,users/*}`: 32 dão flag social, 8 dão plano de controle (meu port) | `:309-342`, `:26-29` e `:393-415` (achado 5) | Nenhuma rota social atravessa o middleware real em teste |
| D4 | Separação real por rota: cada rota e método social exige a **sua** flag | PARCIAL | Mesma classificação | Das 40 combinações **reais**, só **14** têm resultado fixado: 8 de capability (`:212-220`, exceto `:217`) e 6 de plano de controle (`:253-259`, exceto `:256`). Outras 2 linhas fixam um método que nenhum handler declara: `POST /community/decks` (o handler só aceita GET, `server/routes/community/decks/index.dart:10`) e `POST /users/me/fcm-token` (o handler usa PUT e DELETE, `fcm-token/index.dart:17-18`). Elas exercitam a mesma regra, não a rota real. Sem fixação, por exemplo: `GET /conversations/:id/messages`, `PUT /trades/:id/respond`, `GET /community/decks/:id/comments`, `PUT /users/me/fcm-token`, `GET /users/:id/followers`. **[ADV] Há um motivo mais forte para PARCIAL:** a separação é por rota, não por dado. Os endpoints compostos devolvem conteúdo de outras flags. O perfil entrega decks públicos e contagem de seguidores só com `profiles_public`. O feed de seguidos entrega decks públicos só com `follows`. O detalhe de deck da galeria entrega dono e contagem de comentários só com `gallery_public`. O app exige a conjunção dessas flags (achado 13) | Tabela parametrizada com as 40 combinações e passagem pelo middleware (achado 5). **[ADV]** Isso fixa a flag de cada rota, mas não resolve o dado composto, que exige decisão: abrir as flags sociais em bloco, ou fazer o servidor exigir um conjunto de capabilities por rota |
| D5a | UI social ausente: navegação, home, perfil, hub Comunidade | PRONTO_E_PROVADO | `main_scaffold.dart:32-60`; `community_screen.dart:28-37` (abas e `showTradeGrowth` por capability); `_ProfileReleaseAccess` | `main_scaffold_test.dart:76-130,132`; `home_screen_test.dart:371-386,390-422`; `profile_screen_test.dart:485-560`; tokens `surface_contract_test.dart:51-60,76-80` | — |
| D5b | Push e polling sociais ausentes sem flag | PRONTO_SEM_PROVA | `main.dart:921-949,1009-1026,1041-1083` | Só tokens (`surface_contract_test.dart:14-15`) | 1 teste (o mesmo de SCP A9) |
| D5c | Nenhum CTA de `trades` fora de superfície guardada por `trades` | PARCIAL | `binder_screen.dart:472,993-1001` (`binder-open-trade-matches-action` depende só de `collection_private`); a rota de destino é guardada (`release_capabilities.dart:490-493`), então o CTA existe e a navegação quica | Nenhum | Condicionar a `trades` (compartilhado com TRD-00 E6) |
| D6 | Deep links sociais ausentes | PRONTO_E_PROVADO | Guard `release_capabilities.dart:414-468` (`/community/user/*` exige 6 flags; `/community/decks/*` exige 4) | `release_capabilities_test.dart:373-378` (6 deep links sociais dão `/home`); `:463-487` (aba desconhecida não autoriza outra superfície) | — |
| D7 | Flags registradas no release identity | PRONTO_E_PROVADO | `manaloom_release_identity.sh:78-97` (a policy inteira entra na identity) | `manaloom_release_capabilities_contract_test.sh:25-47` | Mesma ressalva de SCP A13 (SHA real) |
| D8 | Exceções de segurança ficam no plano de controle sem abrir superfície social | PRONTO_E_PROVADO | `:456-458` (report de deck), `:459-463` (DELETE comment), `:483-491` (DELETE follow), `:496-504` (DELETE fcm-token), `:547-586` (block, appeals, moderation, `GET /reports/:id`) | `:248-277` (16 rotas dão `null`); `:344-368` (10 negativos, por exemplo DELETE comment sem id) | `GET /reports/:id` segue como leitura pública residual, por decisão de `BT-GOV-001` (`web-public/tests/free-beta-offer-contract.mjs:57`); registrar no receipt |
| D9 | Receipt próprio | NAO_ENCONTRADO | `grep -rl SCOPE-P0-SOC-00 docs/qa` dá vazio | — | Receipt com a saída do teste parametrizado e o digest da policy |

**O que realmente falta.**

A implementação está completa **para a matriz all-OFF [ADV]**, e a negação de hoje está provada por composição. O rótulo `EVIDENCE_REQUIRED` está correto, mas só existe na árvore de trabalho. Faltam:

1. **O teste parametrizado das 40 combinações.** É isso que dá sentido a "flags **separadas**", e é o que a onda 01 pede ("cada rota").
2. **O teste de push e polling.**
3. **Condicionar o CTA de matches do fichário a `trades`** (a mesma correção de TRD-00).
4. **O receipt.**

Números:

- Arquivos: ~~6~~ **7 [ADV]**: teste de servidor, teste de app, o predicado de push extraído em `app/lib` (compartilhado com SCP A9), `binder_screen.dart` (compartilhado), receipt, linha do backlog e registry regenerado. Se o servidor passar a exigir conjunto de capabilities, somam-se ~3 arquivos (lib, middleware, teste) e ~2 testes.
- Testes: 2.
- Migração: não.
- Prova viva: sim (receipt). Se `binder_screen.dart` mudar, o digest de UI se move (achado 7). **[ADV]** Sob WIP-1, essa mudança só entra depois de SCP-001, e isso custa um segundo ciclo de recaptura, a não ser que seja absorvida no slot de SCP (achado 1b).
- Decisão humana: ~~só confirmar `GET /reports/:id` como leitura pública~~ **[ADV]** confirmar `GET /reports/:id` como leitura pública **e** decidir se as flags sociais podem abrir uma a uma (achado 13).
- Dependência `BT-SCP-001`: formal técnica, real pela WIP-1.
- **[ADV] `quase-la` mantido** porque, para a beta, as 9 flags sociais ficam OFF e o aceite literal está atendido em código. O rótulo não vale para "abrir uma flag social": para isso, D4 é trabalho de desenho, não de teste.

**Sobreposição:** TRD-00 (flag `trades` e CTA do fichário) e SCP-001 (teste parametrizado).

---

## SCOPE-P0-TRD-00 — Kill switch de marketplace/trades e copy sem promessa

- **Backlog:** `:553`.
- **Estado declarado:** `EVIDENCE_REQUIRED`. **[ADV]** Só na árvore de trabalho. Em `HEAD` é `TODO` (`git show HEAD:…:547`).
- **Dependências:** `BT-SCP-001`. **[ADV]** Pela fila, também o horizonte, `DCK-P0-00` e SOC-00 (achado 15).
- **[ADV] Onda 01** (`waves/01-platform-safety.md:24`): "criação/listagem/match/proposta e copy pública bloqueados; **nenhuma promessa comercial**". O fichário com "Disponível para venda" e preço em R$ é promessa comercial dentro do app.
- **Aceite:** 7 asserções. "API direta" é julgada na **matriz-alvo da beta**: capabilities core (`collection_private`, `catalog_private`, `decks_private`) ON e `marketplace`/`trades` OFF. É nessa matriz que o kill switch precisa segurar.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| E1 | Kill switch explícito: `marketplace` e `trades` são capabilities separadas e OFF | PRONTO_E_PROVADO | `release_capability_policy.dart:509-518`; json `:124-135` | `:219-220` (`POST /trades` dá `trades`; `GET /community/marketplace` dá `marketplace`); `:26-29` | — |
| E2 | Proposta não pode ser criada via API direta | PRONTO_E_PROVADO (por composição) | `server/routes/trades/index.dart:17-20` (`POST` chama `_createTrade`) sob `trades` (`:509-514`), que segue OFF na matriz-alvo | `:219` (a classificação fixada) mais o achado 5 | Passagem pelo middleware real vai para E7 |
| E3 | Match não pode ser criado via API direta | PRONTO_E_PROVADO (por composição) | `server/routes/community/trade-matches/index.dart:8-9` (só GET, calculado) sob `trades` (`:509-510`); se a regra sumir, cai em "não classificada", que é fail-safe | `:309-342` (não nulo); sem linha que fixe `trades` para esse path | 1 linha no mapa `expected` |
| E4 | **Listagem** não pode ser criada via API direta | PARCIAL | `POST /binder` (`server/routes/binder/index.dart:13-14,335-337,343-364`) e `PUT /binder/:id` (`server/routes/binder/[id]/index.dart:17,572-585`) gravam `for_trade`, `for_sale` e `price` sob `collection_private` (`:534-536`). Não há checagem de capability em `routes/binder` nem em `lib/binder_item_contract.dart`. Só o import força `FALSE` (`routes/binder/import/apply/index.dart:148-168`). O marketplace lê exatamente essas colunas (`community/marketplace/index.dart` @HEAD `:25-31,50-53,111,250-251`) | Nenhum teste rejeita ou zera. `server/test/binder_route_test.dart:15-16` fixa `for_trade` e `for_sale` na resposta de listagem | Servidor rejeita (422) ou força `false/null` quando `marketplace`/`trades` estão OFF (2 fontes, talvez 3); 1 teste de contrato |
| E5 | Copy pública (web) não promete venda nem troca | PRONTO_SEM_PROVA **[ADV]** (era PRONTO_E_PROVADO) | `web-public/src`: 0 ocorrências de `troca`, `venda`, `vender`, `comprar`, `mercado`, `marketplace` e `trade` (grep, confirmado na revisão); sem rota de marketplace | No gate, `public_web_product_contract_test.dart:128-142` (`trades?`, `marketplace`, `checkout`, `upgrade`, `R$`; **só inglês**) e `:170-176` (páginas aposentadas ausentes). Os termos em português só existem no `.mjs` manual (`:24-27`). **[ADV] O teste do gate afirma menos que a asserção.** O site é pt-BR, e "Troque cartas" ou "Venda sua coleção" passariam no gate. O teste só lê 3 arquivos, e o `.mjs` não tem "venda", "vender" nem "comprar" | Plugar o `.mjs` no gate (achado 2) **e acrescentar `vend`/`compr[ae]` a ele, ou pôr os termos em português no teste Dart do gate** **[ADV]** |
| E6 | Copy e UI do app não prometem venda nem troca | PARCIAL | A tela legal diz o contrário, corretamente: "Trocas, propostas, conversas de trade e pagamentos não são oferecidos nesta revisão" (`app/lib/features/commercial/screens/legal_screen.dart:162-165`). Mas o fichário (`collection_private`) mostra "Disponível para troca/venda" e preço em R$ (`binder_item_editor.dart:1093-1160`; payload `:319-328`), stats Troca/Venda (`binder_screen.dart:963-976`), CTA de matches (`:993-1001`), chips (`:1702-1740`) e badges (`:2012-2023`), tudo sem capability | Nenhum teste esconde nada disso. **Ao contrário:** `app/test/features/binder/widgets/binder_item_editor_validation_test.dart:184-255` e `:294-339` exercitam `binder-editor-for-sale-switch` como feature | Condicionar a `ReleaseCapabilitiesProvider` (`binder_item_editor.dart`, `binder_screen.dart`); 1 widget test; reescrever 2 testes existentes |
| E7 | Receipt de negação por rota (listagem, match, proposta) | NAO_ENCONTRADO | `grep -rl SCOPE-P0-TRD-00 docs/qa` dá vazio | — | Receipt com a saída do teste parametrizado cobrindo `POST /trades`, `GET /community/trade-matches`, `GET /community/marketplace` e `POST`/`PUT /binder` com `for_sale` |

**O que realmente falta.**

Proposta e match estão mortos por capability. A **listagem não está**: o fichário privado é a origem dos dados do marketplace e não consulta as capabilities de comércio, nem no servidor nem no app. Enquanto `collection_private` estiver OFF isso fica invisível. Mas coleção é core e abre antes de marketplace. Linhas criadas com `for_sale=true` nesse intervalo apareceriam no dia em que `marketplace` ligasse.

**Trabalho:**

1. **Servidor:** 2 fontes (talvez 3) e 1 teste.
2. **App:** 2 fontes e 1 widget test. Reescrever `binder_item_editor_validation_test.dart` e, talvez, `binder_route_test.dart`.
3. **Teste runtime parametrizado:** compartilhado.
4. **Receipt.**

**Números:**

- Arquivos: ~~~11~~ **~12 [ADV]**. Soma-se o gate web: o smoke ou o `.mjs`, ou o teste Dart, para os termos em português.
- Testes: 3 novos e ~~2~~ **3 [ADV]** ajustados (o contrato web ganha os termos em português).
- Migração: não. Limpar linhas existentes seria DML live, com autorização própria.
- Prova viva: sim. **A mudança em `app/lib` move o digest de UI e força recapturar os manifests** (achado 7). **[ADV]** Sob WIP-1, ela só pode entrar depois de SCP-001, e isso custa um segundo ciclo completo de recaptura. Para evitar, faça essa parte no slot de SCP-001 como A8 (achado 1b). As partes de servidor (E4, teste parametrizado) não movem o digest.

**Decisões humanas:**

1. Rejeitar com 422 ou zerar em silêncio.
2. O que fazer com linhas que já têm `for_sale=true`: mascarar na leitura ou limpar.
3. C17: marcar ou aposentar o pack 05.
4. Manter ou esconder "Troca/Venda" como metadado privado do fichário.

**Dependências:**

- `BT-SCP-001`: formal técnica, real pela WIP-1.
- **Não declarada:** esta tarefa tem de fechar antes de qualquer abertura de `collection_private`.

**Sobreposições:**

- SOC-00 D5c (o mesmo CTA).
- O diff não commitado de privacidade do marketplace, de outra sessão (achado 11).
- `BT-UIEV-001` (C17).

---

## BT-SCN-00 — Scanner fora do artefato e das capabilities da beta

- **Backlog:** `:389`.
- **Estado declarado:** `TODO`.
- **Dependências:** `BT-SCP-001` e `BT-CAT-02`. `BT-CAT-02` está `BLOCKED_BY_P0` e depende de `BT-CAT-01`, que está `TODO` (`:384-385`).
- **[ADV] Plataformas da beta:** "Web e Android" (`CURRENT_PRODUCT_DECISION.md:8`). "Sem câmera no artefato" vale para os dois artefatos, e a medição olhou só o APK.
- **Onda:** PARKED na onda 01 (`waves/01-platform-safety.md:27-28`); entra na onda 07, depois de `BT-CAT-02`.
- **Aceite:** 6 asserções.

| # | Asserção | Estado | Onde está | Teste (o que afirma de verdade) | O que falta |
| --- | --- | --- | --- | --- | --- |
| F1 | Capability `scanner` OFF e nenhuma rota de servidor própria | PRONTO_E_PROVADO | json `:70-75`; app `release_capabilities.dart:17,391-395`. O scanner só consome `/cards*` (`app/lib/features/scanner/services/scanner_card_search_service.dart:23,53,96`), sob `catalog_private` (`:525-533`); nenhuma rota OCR ou scanner em `server/routes` | App `release_capabilities_test.dart:43` (`scanner` negado); servidor `:26-29` | — |
| F2 | Sem CTA | PRONTO_SEM_PROVA **[ADV]** (era PRONTO_E_PROVADO; menu: widget; demais: token) | `app/lib/features/decks/widgets/deck_add_cards_menu.dart:13,29`; `binder_screen.dart:356-364,445-449,473,479,657-660`; `binder_import_screen.dart:198-205,240-243`; `deck_details_screen.dart:1486-1508` (todos exigem build E capability; o default de `scannerBuildSupported` é `LaunchFeatures.scannerEnabled`, `binder_screen.dart:28`) | `deck_add_cards_menu_test.dart:24-42` ("Escanear Carta" ausente por padrão) e `:44+`; `launch_features_test.dart:7-9`; tokens `surface_contract_test.dart:81-84`. **[ADV] Nenhum teste exercita a lógica do gate.** O teste do menu monta o widget isolado com o booleano `scannerEnabled` como parâmetro, sem passar pelo cálculo de `deck_details_screen.dart:1487-1492`. Fichário e importação só têm tokens (`grep 'binder-empty-scan\|Escanear\|onScan' app/test` só acha o menu) | ~~Widget test (opcional)~~ **[ADV] 1 widget test obrigatório para chamar de provado**: fichário (stats, compacto e vazio) e importação com provider semeado `scanner` ON e build OFF, e o inverso |
| F3 | Sem deep link | PRONTO_E_PROVADO | `main.dart:607-614` (rota `scan` só com `LaunchFeatures.scannerSupported`, default false em `launch_features.dart:8-15`); guard `:391-395` | `launch_features_test.dart:61-81` (o `if` no fonte e o guard); `release_capabilities_test.dart:367` (`/scan` vira `/search`); `:445-452` (mesmo com capability ON, se o build não suporta) | — |
| F4 | Sem câmera no artefato de beta (APK release **e Flutter Web [ADV]**) | PARCIAL **[ADV]** (era PRONTO_SEM_PROVA) | `app/android/app/src/release/AndroidManifest.xml:3-15` (`tools:node="remove"` em CAMERA e 3 features); `scripts/manaloom_build_android_release.sh:180` (`ENABLE_SCANNER_RELEASE=false`); verificador `scripts/manaloom_verify_android_release_artifacts.sh:92-99` (aapt falha se o APK declarar câmera) | `app/test/platform/release_security_contract_test.dart:6-63` lê o **texto** do manifesto e do verificador; não toca APK. `launch_features_test.dart:83-92`. **O único APK inspecionado em receipt** (`docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md:277-287`, probe de 2026-07-17) lista `camera`. Ele é anterior à remoção (`51b9a2480`, 2026-07-31; verificador em `2139ec9f6`, 2026-07-23). Nenhum receipt posterior menciona APK ou aapt | Build release e verificador, com receipt. O caminho canônico exige `HEAD == origin/master`, worktree limpo e keystore (`manaloom_build_android_release.sh:55-64`; `identity.sh:45-60`). Os plugins continuam no binário: `app/pubspec.yaml:47-48` e o import incondicional em `main.dart:47`. **[ADV] Web: contrário ao aceite.** `app/web/nginx.conf:41` concede `camera=(self)`, e o deploy empacota esse arquivo (`manaloom_deploy_flutter_web.sh:487,490`). `scripts/manaloom_release_ops_contract_test.sh:286` **exige** esse valor, então o gate protege o comportamento errado. O caminho até `CardScannerScreen` também está no bundle web, com guarda só em runtime (`binder_screen.dart:368`, `binder_import_screen.dart:208`). Correção: `camera=()` no nginx, inverter a asserção do contrato e decidir se o bundle pode carregar o plugin. `app/web` está no escopo do digest de UI (achado 7) |
| F5 | Chamada direta não aciona sync, na matriz-alvo com `catalog_private` ON | PARCIAL | `server/routes/cards/printings/index.dart:23,43-46` honra `sync=true`; `server/routes/cards/resolve/index.dart:80-96,151-166,342-430,532` cai no Scryfall e insere em `cards`; o app envia `sync=true` (`app/lib/features/cards/providers/card_provider.dart:528-531`); o scanner chama `resolve` (`scanner_card_search_service.dart:96`). Hoje está contido só porque `catalog_private` está OFF | Nenhum | É exatamente o aceite de `BT-CAT-02` (backlog `:385`) |
| F6 | Receipt próprio | NAO_ENCONTRADO | `grep -rl BT-SCN-00 docs/qa` dá vazio | — | Receipt reunindo F1-F4 e a saída do verificador sobre o APK |

**O que realmente falta.**

A contenção de superfície existe em quatro camadas: capability, CTA, rota e manifesto de release com verificador. ~~Três delas estão provadas.~~ **[ADV]** Duas estão provadas (capability e deep link). O CTA tem código correto sem teste do gate, e a câmera só foi tratada no Android. O rótulo `TODO` está defasado no eixo IMPLEMENTADO. Sobram ~~três~~ **cinco [ADV]** coisas:

1. **Prova viva de F4 no Android.** Build release, verificador e receipt. **A única evidência de APK que existe contradiz a asserção.**
2. **[ADV] F4 no Web.** `camera=()` em `app/web/nginx.conf:41` e inversão de `manaloom_release_ops_contract_test.sh:286`. Move o digest de UI.
3. **[ADV] F2.** 1 widget test do gate do scanner no fichário e na importação.
4. **F5.** É trabalho de `BT-CAT-02`: 2 fontes de servidor, 1 do app e 2-3 testes. Fica atrás de **duas** tarefas abertas (CAT-01 e depois CAT-02).
5. **O receipt.**

Números:

- Arquivos próprios: ~~2~~ **5 [ADV]**: receipt, linha do backlog, `app/web/nginx.conf`, `scripts/manaloom_release_ops_contract_test.sh` e o widget test.
- Testes: ~~0~~ **2 [ADV]**: o widget test de F2 e a asserção invertida de F4 Web.
- Migração: não.
- Prova viva: sim, no APK. O cabeçalho do artefato Web só pode ser provado localmente, no build/imagem, porque o deploy do Flutter Web é impossível na matriz atual (achado 3).
- Serviço externo: keystore Android.

**Decisão humana:**

1. Aceitar um probe não canônico desta branch, ou exigir o orquestrador same-SHA em `origin/master`.
2. "Fora do artefato" basta como manifesto e rota, ou exige remover o plugin por flavor ou target. **[ADV]** A mesma pergunta vale para o bundle Web.

**Dependências:**

- `BT-SCP-001`: formal técnica, real pela WIP-1.
- `BT-CAT-02`: real e única para F5, e transitivamente `BT-CAT-01`.

**Sobreposição:** F5 coincide com `BT-CAT-02`. `BT-SCN-01` e `BT-SCN-02` (`DEFERRED_BY_SCOPE`) não são tocadas.

---

## Divergências em relação à versão das 10:48 deste arquivo

1. **Circularidade `BT-SCP-001` ↔ `BT-UIEV-001`:** já resolvida no backlog de trabalho (`:225`, `:624`, 2026-09-22). O que sobra é o registry não regenerado (achado 9).
2. **D3 (SOC), C2 (AI-029), E2 e E3 (TRD) sobem para PRONTO_E_PROVADO por composição.**
   - Com 29/29 OFF, o teste exaustivo, o all-OFF e o runtime do middleware provam juntos a negação de toda rota.
   - A lacuna real foi separada em asserções próprias: D4 (separação por rota) e C1 (fixação de `legacy_ai_routes`). Elas importam quando uma capability core abrir.
3. **Achado novo:** a checagem da oferta no HTML não rodou neste SHA (o smoke morre em `:199`, antes de `:300`), e o `.mjs` não está em gate nenhum. O teste de oferta que roda no gate é `public_web_product_contract_test.dart:106-143`.
4. **Achado novo:** superfícies de `trades` sem capability no fichário, além do editor: CTA de matches, chips de filtro e stats.
5. **Achado novo:** a mudança de app de TRD-00 move o digest de UI (`manaloom_ui_source_digest.sh:27`).
6. **Achado novo:** a contenção não está em produção (última observação: `/capabilities` 404).
7. **Sobreposições novas:**
   - `BT-REL-002` com SCP A13;
   - `BT-GATE-004` com a descrição de AI-029 na onda 01;
   - `BT-WEB-003` como dependência não declarada de `BT-OFFER-001`.
8. **Status:** `BT-AI-029` passa de "um-terço" para `mal-comecada`, dentro do enum.
9. **Contagens:**
   - SCP: 11/2/1/1 (A1 e A7 foram desdobradas);
   - SOC: 7/1/2/1;
   - TRD: 4/0/2/1;
   - AI-029: 1/2/1/2;
   - OFFER: 6/1/0/1;
   - SCN: 3/1/1/1.

---

## Verificação adversarial

- **Quando e contra o quê:** 2026-09-22 15:07 -03, contra `d15beb05b`, somente leitura.
- **Sem execução.** Não rodei flutter, dart test, build, emulador nem servidor.
- **Como verifiquei:**
  - abri todo teste citado como PRONTO_E_PROVADO;
  - reli todo `arquivo:linha` marcado PRONTO_SEM_PROVA;
  - rodei o port do classificador da medição (`scratchpad/p0/work/classify.py`) contra rotas hipotéticas;
  - li o escopo do digest de UI;
  - comparei o backlog de `HEAD` com o da árvore de trabalho.
- **Reexaminei as 53 asserções da medição.**

### Veredito em uma frase

A medição acertou quase tudo no nível do código. A porta lateral do fichário, o paradoxo all-OFF da lib de release, a falta de grão de rota na telemetria e o risco da regra legada resistiram à reverificação.

Foi **otimista** em três pontos que mudam o plano:

1. a distância até o gate amplo;
2. cinco rótulos de "provado";
3. a frase "nenhum código de contenção falta".

Também **não viu** a câmera do artefato Web nem o vazamento dos endpoints sociais compostos.

### O que caiu

| Tarefa | Asserção | De → para | Por quê |
| --- | --- | --- | --- |
| `BT-SCP-001` | A1b: policy ilegível, JSON inválido, não-mapa, envelope errado, enum, `allowed` não booleano, timestamp inválido | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | O teste citado só carrega policy **ausente**, **contraditória** e com **status desconhecido** (`release_capability_policy_test.dart:38-108`). Nenhum outro teste Dart carrega policy inválida. O parser autoritativo é o do servidor, e esses ~10 ramos (`release_capability_policy.dart:262-297,313-315`) não têm teste |
| `BT-SCP-001` | A6b: rota futura falha fechada | PRONTO_E_PROVADO → PARCIAL | Só vale fora das famílias de prefixo. Dentro de `/decks/`, `/binder/`, `/cards/`, `/import/`, `/market/` etc., rota nova herda a capability core (`:525-542`). O port confirma: `POST /decks/:id/ai-autopilot` dá `decks_private`. Os testes `:295-307` e `:468-507` só usam um caminho de nível raiz |
| `BT-SCP-001` | A8: app apresenta só o permitido | PRONTO_E_PROVADO → PARCIAL | Os testes citados estão certos, mas nenhum cobre o fichário. Sob `collection_private`, o app apresenta o CTA de matches, que é superfície de `trades` (`binder_screen.dart:472,993-1001`), e troca/venda com preço em R$ (`binder_item_editor.dart:1093-1160`), sem olhar `trades` nem `marketplace`. A regra 2 da decisão proíbe isso (`CURRENT_PRODUCT_DECISION.md:76-77`), e `collection_private` é a próxima capability a abrir (`:58`) |
| `SCOPE-P0-TRD-00` | E5: copy web não promete venda nem troca | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | O teste do gate (`public_web_product_contract_test.dart:128-142`) procura só `trades?` e `marketplace` em inglês, em 3 arquivos, num site pt-BR. O `.mjs` não está em gate nenhum e não tem "venda", "vender" nem "comprar" (`free-beta-offer-contract.mjs:20-28`). O código está limpo hoje (grep), mas nada prova isso |
| `BT-SCN-00` | F2: sem CTA de scanner | PRONTO_E_PROVADO → PRONTO_SEM_PROVA | O único teste de widget monta `DeckAddCardsMenu` isolado, com o booleano como parâmetro (`deck_add_cards_menu_test.dart:24-42`). A lógica do gate em `deck_details_screen.dart:1487-1492`, `binder_screen.dart:445-449,657-660` e `binder_import_screen.dart:240-243` não é exercitada. Fichário e importação só têm tokens |
| `BT-SCN-00` | F4: sem câmera no artefato | PRONTO_SEM_PROVA → PARCIAL | A beta é Web e Android (`CURRENT_PRODUCT_DECISION.md:8`). O artefato Web concede `camera=(self)` (`app/web/nginx.conf:41`), e o contrato de release **exige** esse valor (`scripts/manaloom_release_ops_contract_test.sh:286`). A medição só olhou o APK |
| `BT-SCP-001` | **status medido** | quase-la → **metade** | Soma de A8, A6b e A1b com a distância real do gate (achados 1a-1c e 16). `BT-SCP-001` é dono do gate amplo: cada falha dos três estágios nunca exercitados é trabalho dele |

### O que subiu

| Tarefa | Asserção | De → para | Por quê |
| --- | --- | --- | --- |
| `BT-SCP-001` | A15: gate amplo, clean-SHA, auditoria, receipt | NAO_ENCONTRADO → PARCIAL | Existe algo: execução parcial documentada do `full`, com zero falha de teste até o `npm audit`, 5 defeitos corrigidos e revisão adversarial (`btscp001-gate-amplo.md:240-260,346-391`). Foi num SHA anterior e não satisfaz o aceite. **O rótulo sobe, a conclusão não muda** |

O resto resistiu à tentativa de derrubar:

- **PRONTO_E_PROVADO:** A1a, A3, A4, A5, A6a, A7, A10, A12, A14, B1, B2, B5, B6, B7, C2, D1, D2, D3, D5a, D6, D7, D8, E1, E2, E3, F1 e F3.
- **Provados com ressalva:**
  - A11: só no nível de contrato, porque a decisão diz que widget test não prova Jogar contra IA;
  - B1: 3 dos ~6 arquivos da landing;
  - B3: ligação rota→provider só por fonte.
- **PRONTO_SEM_PROVA:** A2, A9 (= D5b), B4, C1 e C4.
- **PARCIAL:** A13, C5, D4 (com motivo mais forte, achado 13), D5c, E4, E6 e F5.
- **NAO_ENCONTRADO:** B8, C3, C6, D9, E7 e F6.

**Não fui duro onde a medição estava certa.** `BT-OFFER-001` não tem trabalho próprio, então `quase-la` fica, com a ressalva da data. `SCOPE-P0-SOC-00` atende o aceite literal com as 9 flags OFF, então `quase-la` fica, com a ressalva do achado 13.

### Contagens revisadas

PRONTO_E_PROVADO / PRONTO_SEM_PROVA / PARCIAL / NAO_ENCONTRADO:

- **SCP:** 10/3/4/0 (17 asserções; era 11/2/1/1 em 15).
- **OFFER:** 6/1/0/1 (igual).
- **AI-029:** 1/2/1/2 (igual).
- **SOC:** 7/1/2/1 (igual).
- **TRD:** 3/1/2/1 (era 4/0/2/1).
- **SCN:** 2/1/2/1 (era 3/1/1/1).

### Trabalho revisado

| Tarefa | Arquivos | Testes | Por quê |
| --- | --- | --- | --- |
| `BT-SCP-001` | 6 → **7** (+2 do fichário, contados em TRD) | 2 → **3** | Predicado de push extraído em `app/lib`; ~10 mutações do parser em vez de 2-3; teste parametrizado fechado por tabela |
| `BT-OFFER-001` | 3 | 0 | Sem mudança |
| `BT-AI-029` | 17 → **19** | 9 | `API_CONTRACTS_AND_DATA_MAP.md` e `api_contracts_data_map_guard_test.dart:91-128`, que trava as rotas legadas como contrato vivo |
| `SCOPE-P0-SOC-00` | 6 → **7** | 2 | Predicado de push. Mais ~3 arquivos e ~2 testes se o servidor passar a exigir conjunto de capabilities |
| `SCOPE-P0-TRD-00` | 11 → **12** | 3 (+2 → **+3** ajustados) | Termos em português no gate web |
| `BT-SCN-00` | 2 → **5** | 0 → **2** | `nginx.conf`, contrato de ops invertido, widget test do gate do scanner |

### O que muda no plano do dono

1. **O gate amplo está mais longe do que "falta `npm audit` e 23/23".**
   - A correção que falta a `BT-UIEV-001`, a corrida do E2E, mexe em dois scripts que estão no escopo do digest global (`manaloom_ui_source_digest.sh:77-78`). Isso zera os 22 manifests capturados.
   - Depois vêm três estágios nunca exercitados neste SHA.
   - A autorização do bump de `next` é contraditória entre o backlog não commitado e o `PONTO_DE_RETOMADA.md:69-74` commitado.
2. **"Um full fecha quatro linhas" é incompatível com WIP-1**, porque SOC e TRD precisam mexer em `app/lib`.
   - Para pagar a recaptura uma vez só: fazer as correções de UI do fichário no slot de `BT-SCP-001` (A8), rodar antes os três estágios isolados, consertar a corrida e só então recapturar.
   - Caso contrário, são dois ciclos completos: 216 screenshots, 4 perfis `p0-matrix` e o E2E real.
3. **SOC-00, TRD-00 e AI-029 estão ~13-15 IDs atrás na fila publicada**, sob WIP-1. SCN-00 está estacionado até a onda de catálogo.
4. **Antes de abrir qualquer capability core**, fechar as portas laterais:
   - fichário → marketplace/trades (TRD E4/E6);
   - deck público sob `decks_private` (`DCK-P0-00`);
   - defaults públicos gravados pelo plano de controle (`SOC-P0-01`);
   - rota nova sob prefixo core (SCP A6b).

   **Antes de abrir qualquer flag social isolada**, decidir o dado composto (achado 13).
5. **O "estado declarado" que a medição usou é de árvore de trabalho.** Em `HEAD`, SOC-00 e TRD-00 são `TODO`, e `BT-UIEV-001` e `BT-WEB-003` não existem.

### Limites desta revisão

- Não observei produção. O eixo ABERTO em produção segue sendo o de 2026-08-14.
- Não rodei nenhum teste. "Provado" aqui quer dizer que o teste existe e afirma o que está escrito, não que passa em `d15beb05b`. A última execução verde da suíte de backend e do app é do `full` de 2026-09-21, num SHA anterior.
- O backlog e a fila estão sendo editados por outra sessão enquanto escrevo (backlog às 14:29). As linhas citadas conferem com o estado das 15:07.

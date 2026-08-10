# UX-PACK-02 — implementação de ingestão da coleção

- Início autorizado: 2026-08-05, “pode seguir para os proximos passos”
- Estado: `PHASE_1_IMPLEMENTED · AUTOMATED_PASS_FULL_LOCAL_COMPONENTS · FOCAL_PASS_RUNTIME · FOCAL_PASS_VISUAL_REVIEWED · GLOBAL_P0_RECAPTURE_REQUIRES_EXPLICIT_AUTH`
- Migration: nenhuma
- Contrato: [MANALOOM_COLLECTION_INGESTION_CONTRACT.md](../MANALOOM_COLLECTION_INGESTION_CONTRACT.md)

## Decisão executada

A decisão `PRODUCT_DECISION_REQUIRED` foi resolvida como entrega em fases:

1. importação em lote por texto e revisão segura primeiro;
2. scanner conectado à mesma fila, publicado somente sob feature flag;
3. localização estruturada depois de autorização separada de migration.

## Entregue no checkout

- rota persistente `/collection/import` para `Tenho` e `Quero`;
- entrada visível no vazio, no dashboard e no layout compacto do Fichário;
- parser de `quantidade + nome`, hints de set/collector, comentários, linhas
  inválidas e agrupamento de duplicatas;
- resolução em lote pelo catálogo backend e busca manual recuperável;
- escolha visual explícita de impressão com arte completa, set e collector;
- condição, idioma, foil físico e quantidade corrigíveis por candidato;
- draft local por usuário, retomada offline e histórico dos dez últimos lotes;
- preflight read-only com `create/update/rejected`, baseline, target e resumo de
  disponibilidade;
- apply por item com compare-and-set, replay `unchanged`, falha parcial e retry;
- sessão contínua de scanner sob `ENABLE_SCANNER_RELEASE`, sem escrita antes do
  apply;
- troca de `card_id` em item existente, bloqueada quando compromisso ativo ou
  colisão física impedir a mudança.

## Arquivos centrais

- app:
  - `features/binder/screens/binder_import_screen.dart`
  - `features/binder/providers/binder_import_provider.dart`
  - `features/binder/models/binder_import_models.dart`
  - `features/binder/services/binder_import_draft_store.dart`
- backend:
  - `lib/binder_import_contract.dart`
  - `routes/binder/import/preview/index.dart`
  - `routes/binder/import/apply/index.dart`

## Prova automatizada e runtime focal

- app focal: parser, draft/provider, fila mobile/wide, cancelamento, apply,
  partial failure, retry, editor de impressão, Binder responsivo e scanner;
- servidor focal: validação do lote, invariantes de replay/preflight e mutation
  do Binder;
- analyzers focais Flutter/Dart: limpos com toolchain fixado 3.44.6.
- build Web release controlado, sem API de produto ou PostgreSQL, em três perfis:
  - `web_binder_import_mobile_390x844`;
  - `web_binder_import_desktop_1440x900`;
  - `web_binder_import_wide_1920x1080`;
- sete checkpoints por perfil: fonte preenchida, revisão com duplicata e linha
  inválida, plano, confirmação cancelável, falha parcial, retry concluído e
  histórico aberto;
- 21 PNGs foram abertos individualmente e aprovados visualmente;
- digest da captura: `3bf0cbbd97df6123469eb2e3481cc549fa240e92b2a3339b920dd86b7f69bbd3`.

Manifestos focais:

- [mobile 390x844](ui-live/current/ux-pack-02-collection-import-web-mobile/capture-manifest.json);
- [desktop 1440x900](ui-live/current/ux-pack-02-collection-import-web-desktop/capture-manifest.json);
- [wide 1920x1080](ui-live/current/ux-pack-02-collection-import-web-wide/capture-manifest.json).

O harness usa API, draft e histórico controlados em memória e imagens locais
governadas. Ele prova o fluxo e a composição Web release, mas não escreve em
PostgreSQL nem recebe crédito de integração live.

## Defeitos encontrados pela revisão visual

1. a barra inferior ocupava praticamente todo o `Scaffold` porque seu `Center`
   expandia na altura solta de `bottomNavigationBar`; o workspace ficava
   encoberto e só o resumo da ação era visível. A barra passou a usar altura
   intrínseca e ganhou regressão automatizada menor que 100 px;
2. após falha parcial, a prioridade de ações escondia `Revisar falhas`, e após
   o preview do retry escondia `Aplicar lote`; a ordem agora preserva retry,
   apply, concluir e preview conforme o estado;
3. o checkpoint de histórico mostrava somente o cabeçalho recolhido e era
   visualmente igual ao sucesso. O harness agora abre o histórico e exige os
   resultados do lote parcial e do retry antes da captura.

Nenhuma captura vazia ou coberta recebeu crédito. A primeira rodada foi
rejeitada pelo próprio validador e descartada antes dos manifestos finais.

## Validação local final

- `quality_gate.sh full` confirmou os 44 lotes determinísticos do servidor, o
  analyzer Flutter sem issues e `1472` testes Flutter aprovados com `1` skip
  declarado. A invocação parou antes do Web porque o shell selecionava Node
  `20.11.1`, abaixo do mínimo explícito do repositório; isso é bloqueio de
  toolchain, não falha de teste do produto;
- com o Node `26.0.0` já instalado em `/opt/homebrew/bin`, o modo `web` passou
  por `npm ci`, lint, build Next.js, `npm audit` com `0` vulnerabilidades e
  smoke HTTP loopback das rotas públicas;
- o modo `performance` aprovou `17` testes Python do harness, `2` contratos
  Dart do servidor e `3` testes Flutter de homologação local;
- os `8` artefatos de project logic foram regenerados pelo script oficial e o
  check terminou sincronizado;
- os três manifestos focais foram revalidados contra os `21` hashes e tamanhos
  reais dos PNGs, e o digest UI permaneceu
  `3bf0cbbd97df6123469eb2e3481cc549fa240e92b2a3339b920dd86b7f69bbd3`.

O gate `ui-proof` global continua recusando corretamente o aggregate anterior:
os três perfis focais novos ainda não pertencem à matriz P0 global e as cinco
provas globais estão no digest anterior. Nenhuma evidência antiga foi
reclassificada como atual.

## Pendente para fechar o pacote global

- contrato e migration autorizada para área, caixa/fichário e posição;
- runtime Android físico da sessão de scanner quando o flag for homologado;
- TalkBack humano e teclado Web real como gates separados;
- recaptura da matriz P0 global no novo digest. O harness global cria e remove
  fixture em PostgreSQL loopback e, pelo contrato do projeto, exige uma
  autorização humana específica por execução; ela não foi inferida desta
  atividade focal.

Notas livres continuam notas. Nenhuma UI afirma que existe localização
estruturada enquanto o PostgreSQL não tiver esse contrato.

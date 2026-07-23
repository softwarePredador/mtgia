# Evidência executável — Sprint 2 visual

Data da execução: 2026-07-21
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD: `2813152121c4d41069f9ebbb3334eb4c6b8b1110`
Flutter: `3.44.6`
Dart: `3.12.2`
Artefato local: release Web `/app/`, renderer real `canvaskit`
Hash da árvore das fontes Web de runtime (`app/lib`, `app/web`, `app/assets`,
`pubspec.yaml` e `pubspec.lock`, incluindo arquivos ainda não rastreados):
`fd2fb4070ac86da9fa5d55c5560d6b88642698d281b74dcfe1d90d90dc037b74`

Esta evidência converte uma task em `PASS` somente quando o comando fresco e o
aceite correspondente aparecem abaixo. Nesta revisão, todas as tasks S2-01 a
S2-09 fecharam seus critérios.

## Resultado executivo

- A suíte visual focada passou em `72/72`.
- Os contratos backend de sets, bootstrap Web e identidade do artefato passaram
  em `11/11`.
- O gate oficial `quality_gate.sh ui-audit` passou em `13/13`, após encontrar e
  corrigir um alvo de toque de `65,68×45` no cadastro.
- Os contratos de release passaram em `25/25`.
- O build Web release sob `/app/` concluiu com Flutter `3.44.6`; o aviso de fonte
  Cupertino ausente foi eliminado com a dependência de asset explícita.
- O smoke no navegador real encontrou e corrigiu a ausência de `meta viewport`,
  que fazia a interface de 390×844 ocupar somente uma fração da tela.
- O artefato final foi carregado em 390×844, 1440×900 e 1920×1080, com canvas
  ativo, zero overflow horizontal e zero erro/aviso no console.
- O servidor local ganhou proxy de QA opcional sob `/api`, limitado a loopback,
  com verificação TLS obrigatória. Isso permite consultar a API real sem ampliar
  a allowlist CORS de produção.
- A matriz de geometria também passou em 320×568, 412×915, 599/600, 768×1024,
  839/840, 1024×768, 1199/1200 e 1599/1600.
- Em 390×844, a geometria real permaneceu estável em DPR 1, 2 e 3. O transporte
  de screenshot do navegador reduz a captura de DPR alto; por isso os DPR 2/3
  contam como prova geométrica/renderer, não como aprovação humana de pixel.
- A revalidação final de S2-01 migrou a dívida de spacing cru de `1355` linhas
  em `78` arquivos para `0` em `0`, sem alterar os valores renderizados. O app
  completo passou em `1011/1011`, com um único skip declarado Web-only.
- O smoke autenticado final usou API e PostgreSQL reais, ambos descartáveis e
  em loopback. Home, decks, sets e detalhe de carta foram revisados em
  390×844, 1440×900 e 1920×1080; rede normal/cache, imagem 404 e 1,2 s de
  latência tiveram estado estável e recuperação, com zero warning/error no
  console.

## Alterações comprovadas por task

### S2-01 — tokens e responsividade (`PASS`)

- Breakpoints canônicos e sem sobreposição: 600, 840, 1200 e 1600.
- `ResponsivePageFrame` usa a fonte única de gutter do tema.
- O tema ganhou contrato de alvo de toque que compensa a densidade compacta de
  desktop sem reduzir a área abaixo de 48 px.
- Limites 599/600, 839/840, 1199/1200 e 1599/1600 têm testes exatos.
- A escala passou a ter `31` tokens canônicos, mantendo os valores existentes
  para uma migração visualmente neutra e auditável.
- Todos os `1355` usos detectáveis de `EdgeInsets`, `SizedBox` e `Gap` numéricos
  foram migrados; o inventário versionado agora congela `0` usos em `0`
  arquivos e reprova qualquer reintrodução.
- O analisador Flutter passou sem issues e a suíte completa passou em
  `1011/1011`; o único skip é o contrato `lotus_web_host_runtime_test_stub`,
  cuja execução é deliberadamente exclusiva do target Web.

### S2-02 — padrão de carta/arte (`PASS`)

- `CardArtwork` possui variantes explícitas `Gallery`, `Spotlight`,
  `RecentDeck`, `FullCard`, `ArtCrop` e `SetArt`.
- Carta impressa usa 63:88 + `BoxFit.contain`; crops intencionais usam 16:9 ou
  3:2 + `cover`; clipping, alignment/focal point, semântica e placeholders são
  parâmetros do componente.
- `DeckCardItem` preserva `layout` e `card_faces` do backend, inclusive JSONB
  serializado. Split/transform/MDFC sem imagem raiz usa a face frontal em
  `normal`, nunca `art_crop`, e payload de faces inválido degrada com segurança.
- O provider de busca foi testado de ponta a ponta até o modelo de UI.
- A revalidação fresca dos helpers de URL, cache, componente, modelo de faces e
  provider passou em `25/25`, exit `0`; log
  `/tmp/manaloom_s2_02_card_artwork_20260721.log`, SHA-256
  `c64f8f0ca9c3b3553d23a29c77d369b83a3655c2d0cf3bdf5dd4edeee513c451`.

### S2-03 — detalhe da carta (`PASS`)

- Desktop limita a carta completa a 400 px; tablet a 420 px; mobile usa a largura
  disponível sem crop.
- Fixtures cobrem 390, 800, 1440 e 1920, imagem 404, imagem ausente, face dupla,
  título/Oracle longos e texto a 200%.
- Um overflow horizontal real de 63 px em texto a 200% foi reproduzido e
  eliminado antes do gate final.
- A revalidação fresca passou em `6/6`, exit `0`; log
  `/tmp/manaloom_s2_03_card_detail_20260721.log`, SHA-256
  `85d98cd91e1d4ab86804065582edd7d85eb947908e7e8320dda365c3355e34c7`.

### S2-04 — imagens de decks (`PASS`)

- Gallery e Spotlight preservam 63:88 e `contain`; RecentDeck mantém padding em
  todos os lados e não invade o texto.
- O teste cobre CDN de carta, API por printing, API por nome, host desconhecido,
  URL malformada, URL nula, fallback neutro e nome split/double-faced.
- O golden determinístico da galeria usa o fallback offline para validar frame
  63:88, contenção, padding, borda e separação do rodapé sem depender de rede ou
  `path_provider`; SHA-256
  `f0d4fe6f6438aef218efacf7ea4944f56d009ee830c90b260678903de2a059c4`.
- A revalidação fresca conjunta de lista, recentes e fluxo runtime passou em
  `16/16`, exit `0`. O fluxo runtime agora prova também aceite legal e a parada
  na verificação de email antes de gerar, salvar, otimizar, aplicar e validar o
  deck. Log `/tmp/manaloom_s2_04_deck_images_20260721.log`, SHA-256
  `1679477697fea4f687e75f8e708f17706a8f1537192f0cdab7492326ff0c820f`.

### S2-05 — Home/Planeswalker (`PASS`)

- Bordas, clipping, foco da arte e padding dos decks recentes têm asserts.
- Matriz 320/390/768/1200/1440/1920 passa; texto 200% passa.
- `disableAnimations` evita a animação de entrada.
- Goldens revisados existem em 390, 1200, 1440 e 1920. Os goldens 1440 e 1920
  têm o mesmo hash porque o hero é intencionalmente limitado pelo mesmo canvas.
- A revalidação fresca passou em `12/12`, exit `0`; log
  `/tmp/manaloom_s2_05_home_20260721.log`, SHA-256
  `21342a98d798d37c6308438e5ba52a1685bd9a9cc41ed129f7e608415f221a11`.

### S2-06 — símbolos (`PASS`)

- Há `84` assets SVG no inventário local.
- O guard cobre W/U/B/R/G/C, genérico, X, híbrido, Phyrexian, snow, tap, untap e
  energy, além de confirmar a declaração no `pubspec`.
- Custos, identidades e Oracle usam o componente canônico; letras aparecem
  somente no fallback terminal de asset, com semântica preservada.
- A revalidação fresca do inventário, parsing, SVG, semântica e uso em overview
  passou em `14/14`, exit `0`; log
  `/tmp/manaloom_s2_06_mana_symbols_20260721.log`, SHA-256
  `f67923c81fa1da2524162695e93aa615ef1f4c0920a4c7ea2216a4256e407730`.

### S2-07 — representação de coleções (`PASS`)

- A API retorna arte representativa elegível e ícone oficial como fallback.
- A UI usa frame 3:2 estável, distingue arte de set e ícone, e não expõe erro
  técnico cru.
- Cache de ícone bem-sucedido dura sete dias; falha expira em 30 segundos e é
  testada para permitir retry, eliminando cache negativo eterno.
- A revalidação fresca passou no app em `11/11` e no servidor em `8/8`, ambos
  exit `0`. Logs e SHA-256: `/tmp/manaloom_s2_07_sets_app_20260721.log`
  (`9fdf7bdf88176475991745ccc4b4f7a561bc01acd8ca6736a2b58c1d3ec22664`) e
  `/tmp/manaloom_s2_07_sets_server_20260721.log`
  (`792ae3111cc8689a4510927f11a0caa42aa9a45d7e5cc0f77832f8585dc0c39a`).

### S2-08 — QA final de imagens (`PASS`)

- Pixel diff existente e novos goldens P0 de Home estão verdes.
- O golden revisado da galeria de decks também está verde sem atualizar a
  baseline durante o gate.
- Matriz real do bootstrap `/app/`, limites e DPR 1/2/3 está verde.
- O build atual foi autenticado contra Dart Frog/PostgreSQL descartáveis em
  loopback, com usuário, seis decks, seis comandantes e cinco sets de QA. Nada
  foi criado no ambiente remoto.
- A revisão cobriu Home, galeria/lista de decks, sets com arte representativa e
  detalhe de Lorehold. Em desktop, a carta completa ficou limitada ao painel;
  em 390 px ocupou a largura disponível sem overflow.
- Uma URL Scryfall inexistente produziu placeholder estável, sem invadir texto
  ou emitir warning/error no console. A emulação de 1,2 s de latência exibiu
  progresso e depois convergiu para o catálogo completo; a rede foi restaurada
  ao final.
- O browser reportou `console_warning_error_count=0`. O gate oficial
  `quality_gate.sh ui-audit` passou em `13/13`, exit `0`; log
  `/tmp/manaloom_s2_08_ui_audit_20260721.log`, SHA-256
  `39083ae86c929195f833a6f1513ddf5b5df8b7328c5646e2afde42f1170cfac3`.

### S2-09 — identidade do artefato Web (`PASS`)

- `release.json` registra SHA, hash do bundle, Flutter/Dart, contrato de
  renderer e base `/app/`.
- O guard rejeita SHA de commit antigo, hash incorreto de `main.dart.js`, DPR
  zero e, para builds locais sujos, árvore divergente das fontes de runtime. A
  árvore inclui arquivos não rastreados, evitando uma falsa identidade baseada
  somente em `git diff`.
- Evidência emitida registra renderer real, viewport, DPR e dataset.

## Comandos e hashes

### Suíte visual focada

Comando: `flutter test` sobre tema, helpers de imagem, frame responsivo,
`CardArtwork`, mana, provider/modelo de faces, card detail, decks, Home, cache de
ícones e sets. Resultado: `72/72 PASS`.

Log: `/tmp/manaloom_s2_visual_aggregate_final3.log`
SHA-256: `d7d9ca93d5076e2b3361c1be7f50c15fb4396dad176b899740f11440848e88c2`

### Fechamento de S2-01 na árvore atual

- Testes de tema, botões, dívida de spacing e frame responsivo → `7/7 PASS`,
  exit `0`; log `/tmp/manaloom_s2_01_tokens_20260721.log`, SHA-256
  `17c0ff73a668e667ee52c48af526fade7986581d3609b74d18fb994b561926e4`.
- `flutter analyze --no-pub` → `No issues found`, exit `0`; log
  `/tmp/manaloom_s2_01_analyze_20260721.log`, SHA-256
  `f3a9dc872c08793ad3bca4bb996b3a7a1452a8bb1cd48cd2055904f54c4235a2`.
- `flutter test --no-pub --reporter compact` → `1011 PASS / 0 FAIL /
  1 SKIP`, exit `0`; log `/tmp/manaloom_s2_01_full_flutter_20260721.log`,
  SHA-256
  `c59e74b88d8aff9a9e676936bbcd1027f97e314d314ce74e4081e949a68bfbc8`.
- `git diff --check` → exit `0`; scanner do mesmo matcher versionado →
  `raw_spacing_lines=0`, `raw_spacing_files=0`.

### Backend e release

- `dart test test/sets_route_test.dart test/web_artifact_identity_contract_test.dart test/flutter_web_deploy_contract_test.dart`
  → `11/11 PASS`; log SHA-256
  `ce4fed92634b5c6c267ba95af82241c3fb707c590f059e600b08203357c1e2fd`.
- `manaloom_release_ops_contract_test.sh` com Flutter pinado → `25/25 PASS`;
  log SHA-256
  `03ccc5df147336d756ab46c101700ecfabffffa8b3f4a9bb69a88033df7703ba`.
- `quality_gate.sh ui-audit` com Flutter pinado → `13/13 PASS`;
  log SHA-256
  `ed1ac7f5b465b8200bde9cf2e2924892a7a5692e281ff0354f2274214387f7fc`.
- `flutter pub run dependency_validator` → `No dependency issues found`.
- `git diff --check` → exit `0`.

### Identidade do build de base que fechou S2-09

- `main.dart.js` SHA-256:
  `de0fb3c4478dcb64430a9f5405b1face39cbd16ad33f252834d7fea096f99f37`.
- 390×844 DPR 1:
  `72fec7bc0d8dcd5d8b173d51aed300f7122e19686b3e046aacf51dcbd11a502b`.
- 390×844 DPR 2:
  `3220c0b9bc4b8a8f02cc42af12488754e74b43210ed636e95374d871621800db`.
- 390×844 DPR 3:
  `0373b07bbfbc9dbcfd726c540ba26a305b913492b290b64eaff9e90f541ed299`.
- 1440×900 DPR 1:
  `c277f4de2a957821f553dd028cbca1071704c347c315d880c4d80971c45bda13`.
- 1920×1080 DPR 1:
  `73ddc65891a4fb7f7eea823da208988b2ae973bc461b3a2cbea378733907902b`.

### Build e screenshots do smoke autenticado final

- `main.dart.js` atual, compilado com Flutter `3.44.6` para `/app/` e API
  loopback descartável: SHA-256
  `8552f2e60e57ca4f93fc10fb47a1fbeee20d935f470341adb4dc6049e8fc9321`.
- Home 390×844: `a273fe5e83b2e7c0266c5ab2acb2fc3db3a1c6a5e0961c7d3fa37cc071dba658`.
- Home 1440×900: `a5d594655a50a29f681278edd06d79ee824958f4e59235c58132e990a735db14`.
- Decks 390×844: `7c793eb9ea6ee328fd3f7df6b30c265cb2d6f62c0c0d6e9caac86acf09739c86`.
- Decks 1920×1080: `f0ac8dc79990c5e44ad79864723a29af5881f661f6cb148ebc6dd593f19d8278`.
- Detalhe 1280: `2522a6b09908695336e0ed28a1013ccacc51e6f33551571eae15c329f248b8a7`.
- Detalhe 390×844: `e4fb2854112b27b640657c4e7c9b46d605f1ff8ca9988f55d8c02736d8ad3883`.
- Sets 1280: `d2f8ae4a62a47444761fcf7a912f4d1643b0eb9dbe52a89ca264730b9c773384`.
- Fallback 404 1440: `61a80c985fc6c1dd9de0c216fa5d0165f94401b6389f02818eb7da4141da1d13`.
- Latência loading/resolvido 1440:
  `fdc50fefa92f557e168d05f104e944d048f178d5fde98d7531ac33001c09c48e` /
  `1bd774d3f481ca20cf970aa0c6f62f184c54c4f6fa9036f5b50759c96e8f207a`.

## Cleanup e limites

- Nenhum deploy, banco, conta, e-mail ou mutação remota foi executado.
- A tentativa remota histórica continuou em `401` e não emitiu sessão. O smoke
  final autenticou somente a fixture loopback descartável, com credencial
  sintética não reutilizável fora daquele processo.
- O servidor local continua deliberadamente ativo em
  `http://127.0.0.1:8088/app/` para teste do usuário.
- O PostgreSQL/API/Web descartáveis do smoke final foram encerrados; banco
  removido, listeners `52554=0` e `8089=0`, processos restantes `0`. A fixture
  sintética e seus tokens desapareceram com o banco; nada foi persistido.
- O checkout segue compartilhado e sujo; nenhum arquivo foi staged, commitado
  ou revertido.
- O Sprint 2 está fechado. Sprint 3 permanece sem crédito herdado e começa pelo
  inventário executável S3-01.

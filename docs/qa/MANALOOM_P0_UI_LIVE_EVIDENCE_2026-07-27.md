# ManaLoom — prova viva P0 Web + Android

**Data:** 2026-07-28

**Branch:** `codex/free-beta-release-candidate-2026-07-17`

**Toolchain:** Flutter `3.44.6`, Dart `3.12.2`

**Digest visual:** `591dab359d13ea87eb06a60a7c9fc81470fda1cf1123029be69380621ebb083a`
**Decisão:** `PASS` para S3-05 e S3-07; TalkBack humano continua pendente em S3-04

## Escopo realmente comprovado

A matriz executável possui 54 checkpoints de telas/estados P0. Ela cobre as
rotas públicas e autenticadas correntes e seus estados representativos:
autenticação, cadastro e consentimento, Termos, Privacidade, onboarding, Home,
decks, coleção, cartas e sets, Community e usuários, perfil, Life Counter,
Battle/Replays/Coach/Live disabled, pós-jogo, mensagens, notificações e trades.
Success, empty, error, modal, disabled e conteúdo acima/abaixo da dobra são
declarados no fixture; não foram inferidos de uma única tela feliz.

Foram produzidas e abertas as seguintes capturas:

| Manifesto/perfil | Runtime | Capturas | Dimensão |
|---|---|---:|---:|
| Web mobile | build release real | 54 | viewport 390×844; raster 500×844 |
| Web desktop | build release real | 53 | 1440×900 |
| Web wide | build release real | 53 | 1920×1080 |
| Android físico | profile, `kDebugMode=false` | 54 | 1080×2408; Life Counter 2408×1080 |
| Battle Coach Android | integration test físico | 7 | 1080×2408 |
| Battle Coach teclado Web | build release + teclado físico | 9 | 1280×720 |
| Fallback de arte Web | build release real | 1 | 1280×720 |
| Preview → detalhe de carta Web | build release real | 3 | 1280×720 |
| **Total revisado** |  | **234** |  |

As 214 imagens da matriz foram inspecionadas em contact sheets e resolução
original, além das folhas dedicadas ao Battle Coach Android, teclado Web e
fallback de arte e navegação do preview. A revisão verificou hierarquia,
identidade MTG, contraste, tipografia, espaçamento, adaptação, clareza de
ação, estados, acessibilidade visual e atratividade. Não restou finding visual
bloqueante para esta correção.
Os estados centrais de Deckbuilder e Battle também foram reabertos em resolução
original; a aba Análise foi conferida no build real e não recebeu crédito
duplicado no total versionado.

O inventário estrutural continua maior que esta matriz porque também contém
dialogs, sheets, menus, transient states e redirects. A prova acima é o
conjunto de telas/estados P0 definido pelo contrato executável; não apresenta
cada ocorrência transitória do inventário como se fosse uma rota autônoma.

## Falhas encontradas e correções

1. **Identidade MTG genérica fora das telas hero:** apenas Obsidian e Brass
   ainda podiam ser lidos como fantasia genérica. A pesquisa comparativa de
   Arena, Companion, Gatherer, Scryfall, Archidekt e ManaBox mostrou que a
   essência vem dos objetos e verbos do jogo, não de ornamentação. Estados
   vazios e de erro receberam motivo original de carta/campo, carta ganhou
   fallback emoldurado com WUBRG, Community e jogador ganharam glifos próprios,
   Battle passou a explicitar `MÃO · PILHA · CAMPO · PRIORIDADE`, e o Life
   Counter ganhou halo central de cinco cores.
2. **Cadastro e consentimento legal:** os links de Termos e Privacidade
   quebravam em linhas desconectadas, com hierarquia e alvo de foco fracos.
   O bloco foi refeito com composição responsiva, checkbox material, links
   reais para a seção correta, versões legíveis, ordem de foco, autofill,
   submissão pelo teclado e scroll/foco no erro de consentimento.
3. **Termos e Privacidade:** a página única longa não deixava claro qual
   documento estava sendo lido. A rota agora aceita `?section=terms|privacy`,
   oferece navegação explícita e apresenta os documentos em seções legíveis
   com título, vigência e hierarquia consistente.
4. **Battle/Replays:** Enter no resultado filtrado do seletor de oponente não
   completava a seleção/preflight. O fluxo ganhou ativação determinística e
   teste de regressão.
5. **Community:** a normalização da tab da rota pai expulsava rotas filhas de
   busca, perfil e deck público de volta para Explore. A canonização agora só
   ocorre em `/community`.
6. **Mensagens/notificações:** entradas diretas podiam não oferecer retorno
   explícito. As duas telas receberam ação Voltar com fallback canônico.
7. **Chat indisponível:** o composer continuava parecendo utilizável quando a
   conversa falhava. Campo e envio agora ficam desabilitados com texto e
   contraste coerentes.
8. **Perfil:** o FAB de salvar podia cobrir conteúdo. A ação foi movida para
   uma barra inferior responsiva, full-width no compacto e limitada no
   desktop.
9. **Life Counter:** ao sair do modo de apresentação, alguns aparelhos
   preservavam a última rotação landscape. A saída fixa portrait primeiro,
   aguarda a convergência e só então restaura a lista completa de orientações.
10. **Imagens Web locais:** o servidor de prova passou a servir assets locais e
   o fixture usa URL same-origin, eliminando a dependência de CDN/CORS na
   regressão visual.
11. **Harness Android:** o splash de uma tentativa inicial exibia o banner
    DEBUG do `MaterialApp` do próprio harness; ele foi removido e a captura foi
    repetida.
12. **Orientação global indevidamente restrita:** o manifesto PWA ainda
    declarava `portrait-primary`. Web, Android e iOS agora aceitam portrait e
    landscape; somente o Life Counter aplica o lock temporário de apresentação
    em runtime nativo e restaura todas as orientações ao sair. A matriz
    executável ganhou 844×390 e 915×412.
13. **Deckbuilder e persistência de rascunho:** a Análise podia sugerir
    legalidade sem resposta canônica e os últimos caracteres de geração/import
    podiam ficar fora do `SharedPreferences` durante dispose. A UI agora deriva
    `Validado`, `Revisar` ou `Não verificado` de `deck_state` e
    `review_reasons`; gravações são serializadas e drenadas, e importação
    parcial preserva lista e rascunho.
14. **Coerência do Battle Coach:** o seletor reutilizava linguagem de simulação
    automática, campos sem efeito e estados terminais com o mesmo sucesso
    visual. O modo Coach passou a usar CTA e texto próprios, omitiu parâmetros
    inertes, mantém o aviso `ALPHA` e diferencia conclusão, interrupção e erro
    por cor, ícone, título e mensagem.
15. **Fallback genérico de imagem:** carta sem arte ou ainda carregando usava
    um símbolo abstrato sem comunicar imediatamente o objeto. O estado agora
    mostra um verso autoral ManaLoom com moldura dupla, órbitas, glifo da marca
    e cinco pontos WUBRG. Ele preserva a proporção da carta, funciona em
    loading, URL ausente e erro de rede e não reproduz o verso oficial,
    logotipos ou trade dress da Wizards.
16. **Preview persistia sobre a rota de detalhes:** o dialog era criado no
    navegador raiz, mas o callback tentava fechá-lo pelo contexto do
    `ShellRoute`. A rota completa era empilhada no navegador interno e o
    `DialogRoute` permanecia por cima. O dialog agora retorna uma intenção,
    fecha explicitamente o root navigator e só depois aguarda a navegação.
    O teste de regressão cobre navegador aninhado, retorno ao deck e
    reabertura/fechamento sem ressuscitar o modal.

## Life Counter e platform view

O screenshot da surface Flutter não compõe uma WebView Android e produziu uma
imagem preta. A conversão seguinte deixou o Android usando uma surface
`ImageView`; por isso o compositor capturou onboarding antigo e uma marca
esticada mesmo com o DOM do Life pronto. Essa imagem também foi recusada.

A correção restaurou explicitamente a surface Flutter real antes de montar a
WebView. A prova válida aguardou skin visual, quatro jogadores, viewport
landscape, `document.fonts.ready` e overflow zero; só então capturou o
compositor do Samsung via `adb screencap`. O PNG final:

- possui 2408×1080 em landscape;
- contém 559.443 bytes;
- mostra a mesa de quatro jogadores sem overflow;
- passou alvo/semântica automatizados;
- a persistência e restauração continuam cobertas pelos testes funcionais
  dedicados do host/store, separadas da prova visual.

O helper `scripts/manaloom_capture_android_platform_view.sh` recusa arquivo que
não seja PNG, captura portrait e arquivo suspeitosamente pequeno.

## Teclado/foco real do Battle Coach Web

O roteiro usou eventos físicos no build release, sem chamar diretamente
callbacks Flutter:

1. estado base com foco em Voltar;
2. Tab para Abrir replays;
3. Tab para Escolher adversário;
4. Shift+Tab de volta a Abrir replays;
5. Tab + Enter abre o dialog e foca a busca;
6. Escape fecha e restaura foco em Escolher adversário;
7. Space reabre e foca a busca;
8. digitação física filtra o rival público;
9. Enter seleciona e executa o preflight real.

O preflight final bloqueia corretamente a simulação porque o motor do fixture
não está configurado; o CTA fica disabled em vez de iniciar uma operação
inválida. O log sanitizado contém 9/9 `PASS`, nenhuma credencial e zero entrada
proibida.

Os nove arquivos finais são PNG reais em 1280×720, foram reindexados pelo
digest corrente e abertos na folha dedicada; somente esse conjunto entrou no
aggregate.

## Verso autoral para arte indisponível

A prova Web abriu o detalhe de uma carta do banco PostgreSQL loopback, tornou a
URL de imagem temporariamente nula, aguardou o render real e capturou o fallback
ao lado dos dados da carta. Em seguida, restaurou a URL original antes do
cleanup. O manifesto versionado comprova um PNG 1280×720 no digest corrente.

O desenho é deliberadamente próprio do ManaLoom: moldura, elipses de campo,
glifo central e cinco pontos de cor. Ele comunica “carta” durante carregamento,
ausência de URL ou falha da imagem sem usar a imagem oficial apresentada como
referência pelo usuário.

## Tentativas recusadas

Não contam como aprovação:

- SDK Flutter global `3.41.6` misturado com package config/engine `3.44.6`;
- assertion de Material ausente no primeiro harness do cadastro;
- screenshot Flutter preto da platform view;
- onboarding antigo e frame Android distorcido após a conversão deixar a
  surface `ImageView` ativa;
- banner DEBUG introduzido pelo harness;
- uma tentativa do Battle Coach Android rejeitada por assertion transitória
  do binding de gesto; o app foi reiniciado e os sete checkpoints foram
  recapturados com os dois testes runtime aprovados;
- arquivos JPEG apenas renomeados como PNG.

Cada causa foi eliminada e o cenário inteiro relevante foi repetido com a
toolchain pinada.

## Dados, segurança e cleanup

Usuários, peer, deck, card e set pertencem exclusivamente a
PostgreSQL/API loopback descartáveis. As imagens da fixture são same-origin.
Nenhuma coordenada de produção, EasyPanel, SSH, identidade pessoal ou mutation
live foi usada. Credenciais efêmeras não entram nos manifestos nem nos logs
versionados. Ao final, banco, listeners temporários, `adb reverse` e arquivo de
credenciais devem convergir a zero; essa condição é verificada no fechamento
do gate.

## Evidência versionada

- aggregate revisado: `docs/qa/ui-live/latest.json`;
- P0: `docs/qa/ui-live/current/p0-matrix`;
- Battle Coach Android:
  `docs/qa/ui-live/current/battle-coach-android`;
- Battle Coach Web:
  `docs/qa/ui-live/current/battle-coach-web-keyboard`;
- fallback de arte:
  `docs/qa/ui-live/current/card-back-fallback-web`;
- navegação preview → detalhe:
  `docs/qa/ui-live/current/card-details-navigation-web`;
- baselines: `app/test/ui/goldens/runtime`;
- matriz: `app/test/ui/fixtures/ui_authenticated_visual_matrix.json`;
- teclado: `app/test/ui/fixtures/ui_keyboard_focus_matrix.json`.

O aggregate foi verificado com 234 screenshots e os três níveis:
`PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`.

## Findings de acompanhamento

Não bloqueiam a correção do modal, mas ficaram registrados no aggregate:

- o conteúdo de Privacidade ainda é conciso para um documento jurídico
  completo e deve passar por revisão de conteúdo/governança antes de promoção
  comercial;
- o carrossel de ações rápidas pode deixar fragmentos laterais após scroll em
  telas estreitas;
- os CTAs do estado vazio de decks devem receber largura máxima em
  desktop/wide;
- o raster Web do harness mantém margens externas do host; uma evolução deve
  recortar e certificar também o viewport físico de cada perfil.

## Pendência honesta

S3-04 continua `BLOCKED` somente pelo roteiro humano TalkBack no Samsung alvo.
A revisão de imagem e os testes de semantics não substituem uma pessoa
navegando com o leitor ligado. VoiceOver/iOS permanece
`DEFERRED_BY_SCOPE` para a beta Web + Android e não é apresentado como
executado.

## Validação final

A recertificação deste digest fechou com:

- 314/314 testes do domínio Deck aprovados;
- 129/129 testes do domínio Battle aprovados;
- 126/126 testes focados das superfícies anteriores e 10/10 testes focados do
  diálogo de detalhes aprovados;
- 91 testes focados do backend aprovados e uma integração de alias delegada
  ao schema descartável;
- 1.342 testes Flutter completos aprovados e um skip declarado;
- 12/12 checks focados de orientação e responsividade aprovados;
- `flutter analyze` sem issues;
- 53/53 testes do gate `ui-audit` e 54 checkpoints na matriz de captura;
- 234/234 screenshots aceitos pelo gate `ui-proof`;
- 9/9 passos físicos de teclado/foco do Battle Coach Web;
- sete estados visuais e dois testes de runtime do Battle Coach no Samsung;
- `manaloom_project_logic --write` e `--check` sincronizados;
- CI local `quick` aprovada;
- CI local `full` aprovada, incluindo 62 auditorias determinísticas, 27
  contratos de release, 9 jornadas Patrol e auditoria de dependências;
- schema descartável aprovado com 79 tabelas, 6 views, 98 FKs e 56 migrations;
- build Web release e smoke test em `/app/` aprovados.

O mesmo gate `full` permanece obrigatório no `pre-push`; a execução acima é a
prova prévia e o hook repete a proteção no envio Git.

O `main.dart.js` do Web release validado tem SHA-256
`a044b90d0c9ac2fc9fd6d99776d85726aa7b70639b647265c0d52c448842901d`.
O digest definitivo das fontes da UI é
`591dab359d13ea87eb06a60a7c9fc81470fda1cf1123029be69380621ebb083a`.

# ManaLoom — prova viva P0 Web + Android

**Data:** 2026-07-28

**Branch:** `codex/free-beta-release-candidate-2026-07-17`

**Toolchain:** Flutter `3.44.6`, Dart `3.12.2`

**Digest visual:** `25a74e45b91e0849d442c85ee05cd72f8bdb6cea3e42270a87f1fddcee04a274`
**Decisão:** `PASS` para S3-05 e S3-07; TalkBack humano continua pendente em S3-04

## Escopo realmente comprovado

A matriz executável possui 53 checkpoints de telas/estados P0. Ela cobre as
rotas públicas e autenticadas correntes e seus estados representativos:
autenticação, cadastro e consentimento, Termos, Privacidade, onboarding, Home,
decks, coleção, cartas e sets, Community e usuários, perfil, Life Counter,
Battle/Replays/Coach/Live disabled, pós-jogo, mensagens, notificações e trades.
Success, empty, error, modal, disabled e conteúdo acima/abaixo da dobra são
declarados no fixture; não foram inferidos de uma única tela feliz.

Foram produzidas e abertas as seguintes capturas:

| Manifesto/perfil | Runtime | Capturas | Dimensão |
|---|---|---:|---:|
| Web mobile | build release real | 53 | viewport 390×844; raster 500×844 |
| Web desktop | build release real | 52 | 1440×900 |
| Web wide | build release real | 52 | 1920×1080 |
| Android físico | profile, `kDebugMode=false` | 53 | 1080×2408; Life Counter 2408×1080 |
| Battle Coach Android | integration test físico | 7 | 1080×2408 |
| Battle Coach teclado Web | build release + teclado físico | 9 | 1280×720 |
| **Total revisado** |  | **226** |  |

As 210 imagens da matriz foram divididas em 24 contact sheets e inspecionadas
em resolução útil, além das folhas dedicadas ao Battle Coach Android e teclado
Web, totalizando 26 folhas abertas. A revisão verificou hierarquia, identidade
MTG, contraste, tipografia, espaçamento, adaptação, clareza de ação, estados,
acessibilidade visual e atratividade. Não restou finding visual bloqueante.
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
- contém 16.809 cores e 567.841 bytes;
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

## Tentativas recusadas

Não contam como aprovação:

- SDK Flutter global `3.41.6` misturado com package config/engine `3.44.6`;
- assertion de Material ausente no primeiro harness do cadastro;
- screenshot Flutter preto da platform view;
- onboarding antigo e frame Android distorcido após a conversão deixar a
  surface `ImageView` ativa;
- banner DEBUG introduzido pelo harness;
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
- baselines: `app/test/ui/goldens/runtime`;
- matriz: `app/test/ui/fixtures/ui_authenticated_visual_matrix.json`;
- teclado: `app/test/ui/fixtures/ui_keyboard_focus_matrix.json`.

O aggregate foi verificado com 226 screenshots e os três níveis:
`PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`.

## Pendência honesta

S3-04 continua `BLOCKED` somente pelo roteiro humano TalkBack no Samsung alvo.
A revisão de imagem e os testes de semantics não substituem uma pessoa
navegando com o leitor ligado. VoiceOver/iOS permanece
`DEFERRED_BY_SCOPE` para a beta Web + Android e não é apresentado como
executado.

## Validação final

A recertificação deste digest fechou com:

- 292/292 testes do domínio Deck aprovados;
- 129/129 testes do domínio Battle aprovados;
- 12/12 checks focados de orientação e responsividade aprovados;
- `flutter analyze` sem issues;
- 53/53 checks do gate `ui-audit`;
- 226/226 screenshots aceitos pelo gate `ui-proof`;
- 9/9 passos físicos de teclado/foco do Battle Coach Web;
- sete estados visuais e dois testes de runtime do Battle Coach no Samsung;
- `manaloom_project_logic --write` e `--check` sincronizados;
- CI local `quick` aprovada;
- build Web release e smoke test em `/app/` aprovados.

O gate `full` continua obrigatório no `pre-push`; seu resultado pertence ao
registro da entrega Git, sem ser antecipado por este documento visual.

O `main.dart.js` do Web release validado tem SHA-256
`ea153b96bc81ba247598b33fe188863e69fd7ba019e00b1728b9c92e3792409a`.
O digest definitivo das fontes da UI é
`25a74e45b91e0849d442c85ee05cd72f8bdb6cea3e42270a87f1fddcee04a274`.

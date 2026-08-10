# ManaLoom — implementação do polish responsivo P2

Data: 2026-08-07
Digest UI: `ebacfe42e89ef071404621d08811480fd6b205899942cc2c4d454c383beb64bc`
Estado: `IMPLEMENTATION_COMPLETE_LOCAL · AUTOMATED_FULL_PASS · PASS_RUNTIME_25_MANIFESTS_402_SCREENSHOTS · VISUAL_REVIEW_456_OPENED · OFFICIAL_LEGAL_RESEARCH_COMPLETE · COUNSEL_SIGNOFF_PENDING · ANDROID_PHYSICAL_REANCHOR_BLOCKED`

## Resultado

As quatro frentes P2 deixadas pelo polish P1 foram encerradas no escopo local
autorizado:

1. cartas, impressões e evidências horizontais comunicam continuidade sem
   cobrir, recortar ou distorcer a arte da carta;
2. nomes longos no Profile e perfil público ocupam até duas linhas, com
   elipse visual previsível e nome integral preservado em semântica/tooltip;
3. as fixtures de Deck Workshop e Battle Learning usam identidades, imagens e
   estados distintos, removendo conteúdo artificial ou duplicado da prova;
4. Legal/Privacy foi auditado como superfície sóbria de leitura: a composição
   de UI está adequada e a aprovação do texto permanece uma revisão jurídica
   externa, não uma tarefa de decoração ou engenharia.

O patch não altera rotas, APIs, schema, pins, regras, decks persistidos,
runtime ou deploy. Nenhuma escrita foi executada em PostgreSQL, Hermes ou
SQLite.

## Implementação

### Descoberta horizontal sem cobrir card art

`app/lib/core/widgets/horizontal_discovery_rail.dart` introduz um rail
reutilizável que:

- mede overflow real e só exibe continuidade quando ela existe;
- mantém instrução e controle direcional fora das imagens;
- oferece ação semântica de avançar/voltar e alvo de 48 px;
- respeita movimento reduzido com salto imediato;
- mantém o controle no lado de continuidade e troca sua direção ao chegar ao
  fim, sem reposicionar o conteúdo.

O rail foi aplicado a:

- seleção de impressão no editor do Fichário;
- cartas observadas e evidências salvas no pós-jogo;
- evidência usada pela recomendação do Optimize.

`SampleHandWidget` preserva seu `PageView` e setas, mas agora mostra
explicitamente `x de 7 · deslize ou use as setas`. O viewport da carta não foi
reduzido para acomodar a instrução.

### Identidade de jogador com nome longo

`app/lib/core/widgets/player_identity_name.dart` centraliza o contrato de
identidade:

- máximo de duas linhas e elipse somente na apresentação visual;
- nome completo exposto em semântica;
- tooltip com o nome completo em superfícies com ponteiro;
- uso no Profile próprio e no perfil público.

As fixtures exercitam nomes de 45–50 caracteres em vez de exemplos curtos que
mascaravam a quebra responsiva.

### Fixtures e checkpoints mais honestos

Deck Workshop passou a provar:

- comandante canônico visível junto do CTA pai de geração;
- deck determinístico de 99 cartas com quatro identidades visuais;
- checkpoint novo `deck_workshop_08_sample_hand_continuity` com sete cartas,
  seleção atual, instrução e ações Keep/Mulligan.

Battle Learning passou a usar imagens distintas para comandante, Sol Ring e
Thought Vessel e substituiu rótulos artificiais por `Token de Tesouro` e
`Pista criada por efeito`. A interação do harness usa o controle de
continuidade antes de selecionar a evidência fora do primeiro viewport.

Essas imagens são fixtures determinísticas de interface. Elas não recebem
crédito como prova de printing oficial nem substituem o contrato de fonte,
cache e direitos de card art.

### Legal e privacidade

`CommercialLegalScreen` já apresenta:

- largura de leitura limitada;
- título, versões vigentes e status de revisão;
- navegação direta para Termos e Privacidade;
- seções separadas para uso, IP/conteúdo de fã, fonte das cartas, IA, trades,
  monetização e dados do usuário;
- ícones funcionais e hierarquia sóbria, sem arte decorativa irrelevante.

Nenhuma copy jurídica foi reescrita neste P2. A composição de UI é considerada
concluída localmente; validade, jurisdição, retenção, direitos do titular e
adequação comercial continuam dependentes de profissional jurídico.

## Verificação executada

- analyzer focal: sem issues;
- suíte focal dos novos rails, nomes, Binder, pós-jogo, Optimize e perfis:
  `28/28 PASS`;
- política, Binder e Sample Hand em invocação complementar: `20/20 PASS`;
- recorte Legal/Privacidade, deep links, 200% de texto e consentimento:
  `14/14 PASS`;
- harnesses Deck Workshop e Battle Learning em `flutter-tester`: `PASS`;
- suíte Flutter completa: `1527 PASS + 1 skip governado`;
- `quality_gate.sh full`: backend determinístico, Flutter, Web público,
  auditoria de dependências, smoke HTTP e harnesses locais em `PASS`;
- project logic: `8/8` artefatos regenerados e sincronizados;
- `quality_gate.sh ui-audit`: analyzer limpo e `56/56 PASS` antes de o gate
  de evidência recusar corretamente o aggregate/P0 stale;
- scripts Web release dos Packs 02–08 e Battle Live: `22/22` manifests e
  `242/242` PNGs em `PASS_RUNTIME`, todos no digest desta página.

O recorte diretamente alterado pelo P2 corresponde a 12 manifests e 153
capturas:

- Deck Workshop: 9 por perfil, 27 no total;
- Battle Learning: 10 por perfil, 30 no total;
- Visual System/Profile: 10 por perfil, 30 no total;
- Critical Overlays/estados: 22 por perfil, 66 no total.

## Revisão visual focal

Foram abertas em resolução original 21 capturas no digest final:

- `deck_workshop_00_commander` e
  `deck_workshop_08_sample_hand_continuity`: `6/6`;
- `battle_learning_07_postgame_signals` e
  `battle_learning_09_optimize_evidence`: `6/6`;
- `ux_pack08_14_binder_printings_recovered`: `3/3`;
- `visual_system_00_profile_clean` e `visual_system_05_public_profile`: `6/6`.

O recorte não apresenta overflow, campo estreito, perda de CTA, arte coberta ou
controle de continuidade ambíguo. No mobile, a seta e a instrução aparecem
quando o conteúdo excede a largura; em desktop/wide elas desaparecem quando os
itens já cabem. A elipse dos nomes é intencional e o nome integral permanece
acessível.

Essa inspeção concede `FOCAL_WEB_VISUAL_PASS` somente aos checkpoints listados.
Ela não relabela os 242 PNGs como integralmente revisados e não promove o
aggregate global.

## Estado da evidência global

`docs/qa/ui-live/latest.json` permanece corretamente ligado ao digest anterior
`f45f96e3…`. Os quatro perfis P0 — Web mobile, desktop, wide e Samsung físico —
somam 214 capturas nesse digest antigo.

O verificador fail-closed recusou:

- o digest do review e do aggregate antigos;
- os quatro manifests P0 stale;
- os hashes do aggregate, que ainda apontam para a rodada anterior;
- a contagem de revisão, porque os manifests atuais não foram integralmente
  abertos.

A recaptura P0 autenticada exige a fixture que escreve em PostgreSQL loopback
descartável. Como esta atividade proíbe qualquer escrita em PostgreSQL, ela não
foi iniciada. Nenhum hash antigo foi transportado e nenhum
`PASS_VISUAL_REVIEWED` global foi declarado.

### Atualização da continuação autorizada em 2026-08-07

Em atividade posterior, a fixture PostgreSQL loopback descartável foi
explicitamente autorizada. Os três perfis P0 Web foram recapturados, elevando a
cobertura corrente para `25/26` manifests e `402/456` PNGs no digest desta
página. As `456/456` imagens foram abertas e reconciliadas, mas o Samsung
SM-A135M não estava conectado e suas 54 capturas permanecem no digest anterior.
O aggregate não foi promovido. Detalhes e achados visuais estão em
[`MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md`](MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md).

A pesquisa jurídica em fontes oficiais também foi concluída e organizada em
[`MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md`](MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md).
Isso não substitui parecer de advogado habilitado e não libera lançamento
comercial.

## Próximas prioridades

1. **Jurídico externo:** encaminhar o briefing concluído e obter parecer
   assinado; engenharia só reage depois a textos ou contratos aprovados.
2. **Release humano/hardware:** TalkBack humano, teclado Web físico e smoke no
   Samsung continuam verificações separadas.
3. **Reancoragem global:** conectar o Samsung SM-A135M, recapturar seus 54
   checkpoints, reabrir esse perfil e só então gerar `latest.json` pela
   ferramenta oficial.
4. **Decisões de produto separadas:** localização estruturada da coleção,
   scanner físico, progresso cross-device e mediação comercial não fazem parte
   do P2 concluído.

Não resta implementação visual dentro do `POLISH-RESPONSIVO-P2`. Restam
governança externa, prova humana/hardware e a reancoragem global condicionada à
autorização de banco descartável.

## Limites

Não houve commit, push, migration, deploy, alteração de pins, promoção de
deck/regra, escrita live ou limpeza do checkout sujo preexistente. O
ChromeDriver 151 usado para compatibilidade com o Chrome local foi temporário
e não foi incorporado ao projeto.

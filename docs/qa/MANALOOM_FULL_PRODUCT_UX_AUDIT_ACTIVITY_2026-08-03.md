# Atividade preparada — auditoria integral de produto e UX do ManaLoom

**Preparada em:** 2026-08-03

**Estado:** `DIAGNOSTIC_COMPLETE · UX_PACKS_01_08_COMPLETE_LOCAL · GLOBAL_UI_EVIDENCE_26_453_PASS · RELEASE_HUMAN_GATES_PENDING` — auditoria, oito pacotes e reancoragem visual concluídos; release continua não autorizado

**Escopo de produto:** aplicativo Flutter Web e Android; iOS entra na inspeção estática e só recebe crédito runtime quando houver build/dispositivo elegível

**Documento operacional:** [tracker de execução](MANALOOM_FULL_PRODUCT_UX_AUDIT_TRACKER_2026-08-03.md)

**Ficha por superfície:** [worksheet](MANALOOM_SCREEN_UX_AUDIT_WORKSHEET.md)

**Resultado da rodada:** [relatório integral](MANALOOM_FULL_PRODUCT_UX_AUDIT_REPORT_2026-08-03.md)

**Pacotes preparados:** [pacotes de implementação](MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md)

> **Situação em 2026-08-05:** a matriz P0, Battle Live, Binder Import, Deck
> Workshop e Battle Learning foram recapturados no digest `93009fc2…`.
> `14/14` manifests e `294/294` PNGs foram abertos, reconciliados por hash e
> aprovados nos três níveis obrigatórios. O Samsung SM-A135M físico forneceu
> `54/54` checkpoints. Não houve finding visual bloqueante; integridade de arte
> exata nas fixtures, truncamentos móveis, composição wide, copy e validações
> humanas de acessibilidade permanecem follow-ups explícitos. O resultado está
> em [MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

> **Situação em 2026-08-06:** o `UX-PACK-05` foi autorizado na sequência e
> concluiu localmente matches acionáveis, Marketplace/Cotações canônicos,
> proposta recuperável, contraproposta atômica de troca pura, comentário
> contextual e vazios sociais acionáveis. `48/48` capturas Web release foram
> abertas nos perfis 390×844, 1440×900 e 1920×1080. A falha de largura mobile
> observada pelo usuário foi corrigida, testada e recapturada antes da revisão.
> O aggregate de 294 imagens é histórico para o digest anterior e deve falhar
> fechado até reancoragem integral. Resultado:
> [MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md).

> **Continuação em 2026-08-06:** os Packs 06 e 07 também foram autorizados e
> concluídos localmente. Onboarding passou a iniciar pela intenção e concluir
> após tarefa real; Profile, perfil público, primeiro deck, quota e estados
> transversais foram recompostos como workbench de jogador. As provas focais
> abriram `15/15` e `30/30` capturas Web release, respectivamente. A política
> corrente exigia 23 manifests/387 capturas naquele ponto, mas `latest.json` permanece no
> digest global anterior até congelamento e reancoragem integral. Resultado do
> último pacote:
> [MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md).

> **Fechamento do Pack 08 em 2026-08-06:** Profile/security, delete de deck,
> recuperação de comandante, Fichário, Trade, sessão expirada e permissão
> negada foram ligados a 22 checkpoints executáveis por perfil. `55/55` testes
> passaram; `66/66` PNGs Web release finais foram abertos e aprovados no digest
> `60bbef19…`. A política passa a exigir 26 manifests/453 capturas. O aggregate
> global anterior não foi promovido e os gates de TalkBack, teclado real,
> hardware e jurídico continuam pendentes. Resultado:
> [MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md).

> **Reancoragem global final em 2026-08-06:** a continuação autorizou o
> fechamento documental e visual. P0, Battle Live e os Packs 02–08 foram
> recapturados no digest `f45f96e3…`; `26/26` manifests e `453/453` PNGs foram
> abertos individualmente e reconciliados por bytes, dimensão e SHA-256. O
> aggregate registra `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`,
> sem finding bloqueante. O resultado e as prioridades restantes estão em
> [MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

## 1. Resultado esperado

Produzir uma leitura completa, baseada em evidência, de como um jogador de Magic percebe e usa o ManaLoom. A auditoria deve responder:

1. o que o usuário tenta realizar em cada tela;
2. o que o produto já oferece de forma funcional, compreensível e atraente;
3. o que existe no código, mas não está perceptível ou convincente na interface;
4. o que está ausente, quebrado, genérico, excessivamente informativo ou sem continuidade;
5. onde imagens de cartas, comandante, deck ou partida ajudariam reconhecimento e decisão;
6. quais modais, sheets, menus e mensagens deveriam permanecer, virar conteúdo contextual ou evoluir para um fluxo;
7. quais mudanças merecem ser executadas primeiro e como validá-las.

O resultado não será uma lista abstrata de opiniões. Cada achado deve ligar **pessoa → job → evidência → problema → consequência → proposta → critério de aceite**.

## 2. Sinal de início e limites de autorização

O sinal sugerido para iniciar a fase de diagnóstico é:

> **INICIAR AUDITORIA UX INTEGRAL DO MANALOOM**

Esse sinal autoriza inspeção, pesquisa, execução de testes read-only, captura de evidência e criação/atualização de artefatos de QA. Ele **não** autoriza alteração de UI, regra, rota, banco, runtime, deploy, pin, commit ou push.

### Autorização posterior registrada

Em 2026-08-03, “do que montou e organizou comece” autorizou a implementação
progressiva do `UX-PACK-01`; em 2026-08-05, “pode fazer” reiterou essa
autorização e permitiu concluir o pacote, inclusive o reparo de evidência
`UX-019`. “Pode seguir para os próximos passos”, “okay então pode prosseguir”
e as continuações subsequentes autorizaram progressivamente os pacotes 02–08.
As continuações posteriores autorizaram a reancoragem global read-only e sua
consolidação documental. O escopo autorizado não se estende a migration,
release, deploy, commit ou push. Resultados e limites ficam nos relatórios
próprios de cada pacote e no aggregate canônico.

Depois do diagnóstico, uma implementação deve ser autorizada por onda, por exemplo:

> **IMPLEMENTAR ONDA UX 2 APROVADA**

Mesmo com essa autorização futura, continuam válidos os contratos do projeto, a verdade PostgreSQL e os três níveis obrigatórios de prova para mudança app-facing: `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`.

## 3. Base canônica congelada para o kickoff

O inventário estruturado atual declara:

| Superfície | Total atual |
|---|---:|
| `GoRoute` | 41 |
| `ShellRoute` | 1 |
| `MaterialPageRoute` | 5 |
| Diálogos | 49 |
| Bottom sheets | 23 |
| Menus | 9 |
| Abas | 10 |
| Navegações globais | 2 |
| Transientes/snackbars | 108 |
| Arquivos-fonte inventariados | 57 |
| Domínios com contrato | 18 |
| **Ocorrências de UI no total** | **248** |

Esses números são o congelamento do kickoff. Após os pacotes autorizados, o
inventário executável de 2026-08-06 declara `45` GoRoutes e `263` ocorrências;
a diferença inclui importação do Binder, matches e aliases semânticos. O
tracker corrente, não esta tabela histórica, é a fonte para reconciliação.

Fontes internas que devem ser relidas no início da execução:

- `AGENTS.md`;
- `project_logic_manifest.json`, incluindo `semantic_analysis` e `lineage`;
- `docs/generated/CURRENT_SYSTEM.md`;
- `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`;
- `docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md`;
- `app/doc/UI_TEST_SURFACE_MAP.md`;
- `app/test/ui/fixtures/ui_surface_inventory.json`;
- `app/test/ui/fixtures/ui_authenticated_visual_matrix.json`.

A matriz P0 atual contém até 54 checkpoints por perfil e quatro perfis: Web
mobile 390 × 844, Web desktop 1440 × 900, Web wide 1920 × 1080 e Android. O
aggregate final também inclui Battle Live e as jornadas focais dos Packs
02–08, totalizando `26` manifests e `453` capturas revisadas no mesmo digest.
Essa prova é válida para os checkpoints que realmente cobre; não equivale a
pesquisa quantitativa com usuários nem a uma prova individual das 263
ocorrências inventariadas.

### Limites da evidência existente

- A auditoria de 2026-07-16 cobriu 33 rotas; o inventário do kickoff tinha 41.
  O inventário executável corrente possui 45 ocorrências de `GoRoute`, três
  deferidas e três redirects de compatibilidade/semântica. A rodada anterior é
  baseline histórica, não conclusão vigente.
- Capturas e relatórios históricos não herdam `PASS_VISUAL_REVIEWED` quando o digest da UI mudou.
- O checkout estava sujo quando esta atividade foi preparada. Esta preparação não gerou nem promoveu novas imagens; ela apenas registrou o aggregate já existente e preservou todas as alterações locais.
- Código que referencia imagem de carta prova capacidade técnica, não prova presença adequada, carregamento correto, composição ou utilidade para o usuário.
- `scanner` e as duas rotas de `battle-coach` estão `deferred_by_scope`; `/market` é redirect de compatibilidade, não tela própria.

### Fila inicial levantada por inspeção estática

Estes itens orientam a primeira execução. Eles não devem ser convertidos diretamente em patch:

| Evidência inicial | Etiqueta | Verificação necessária |
|---|---|---|
| O fixture atual declara 49 dialogs, 5 `MaterialPageRoute` e 248 ocorrências, enquanto `UI_TEST_SURFACE_MAP.md` ainda narra 47, 6 e 246 | `CODE_SEEN` | Reconciliar a documentação pelo fluxo gerado/autorizado, sem edição manual de artefato derivado |
| O aggregate atual tem 219 capturas, mas a matriz canônica possui apenas 5 checkpoints abaixo da dobra e 1 modal | `CODE_SEEN` | Expandir prova visual para conteúdo longo e overlays acionados |
| Loading, progress, saving, retry, offline, stale, loading-more, session-expired e permission-denied não têm cobertura visual ampla na matriz canônica | `CODE_SEEN` | Capturar estados aplicáveis por domínio; Battle Live não pode servir de representante universal |
| 49 dialogs, 23 sheets e 9 menus existem, porém quase todos estão fora de uma captura action-open-final atual | `CODE_SEEN` | Abrir e revisar cada overlay ou grupo comprovadamente equivalente |
| `DeckGenerateScreen` apresenta preview de comandante/lista em texto sem widget de arte de carta | `CODE_SEEN` | Julgar no runtime se a ausência prejudica reconhecimento, desejo e confirmação; desenhar proposta antes de implementar |
| `OnboardingCoreFlowScreen` usa painéis textuais homogêneos sem arte de carta/deck | `CODE_SEEN` | Testar compreensão e atratividade com as personas de primeiro uso |
| `BattleLiveSpectatorScreen` mostra nomes, mas o contrato observado não entrega `card_id`/URL de imagem | `CODE_SEEN` | Tratar eventual arte como decisão de contrato e dados, não simples decoração de UI |
| `PostGameNotesScreen` registra boas/ruins como nomes livres | `CODE_SEEN` | Validar o job; uma seleção visual de cartas exigiria identidade estruturada e compatibilidade de dados |
| A infraestrutura de imagem aparece em 24 arquivos de produto e cobre áreas centrais | `CODE_SEEN` | Inspecionar utilidade, impressão correta, fallback, crop e densidade no runtime; não criar dívida duplicada |

## 4. Tese de produto que a auditoria deve testar

> **ManaLoom deve parecer uma mesa de jogo premium e um espaço de decisão de Commander, não um dashboard administrativo com tema escuro.**

O ciclo diferencial a validar é:

`descobrir/importar → montar → compreender → otimizar → confirmar → validar → jogar → registrar → aprender → ajustar`

O produto só forma uma experiência quando estado e intenção atravessam as transições. Ter todos os módulos no menu não é suficiente.

### Teste de cinco segundos por viewport

Em cada superfície, o jogador deve conseguir responder:

1. onde estou;
2. o que está acontecendo agora;
3. qual é a próxima ação principal;
4. que carta, deck, partida ou pessoa está em contexto;
5. como continuo ou me recupero se algo falhar.

## 5. Pesquisa de usuários: leitura atual

As fontes comunitárias são qualitativas e autoselecionadas. Elas revelam dores e hipóteses, mas não medem prevalência.

### 5.1 Jobs e dores recorrentes

| Job do jogador | Evidência observada | Pergunta obrigatória para o ManaLoom |
|---|---|---|
| Reconhecer e compreender cartas rapidamente | Busca, imagens, impressão, legalidade, preço e rulings aparecem juntas em produtos maduros | O resultado mostra a carta e a decisão possível, ou apenas texto? |
| Digitalizar uma coleção grande sem retrabalho | Scanner por sessão, revisão, correção de edição/foil/idioma/condição e ações em lote reduzem a dor | Há fila de confirmação, ambiguidade visível e correção antes de salvar? |
| Saber o que possui e o que está livre | Usuários misturam apps porque coleção, alocação e deckbuilding raramente fecham o ciclo | A UI distingue `total`, `alocada`, `livre` e `faltante`? |
| Montar um deck com intenção | Comandante, tema, orçamento, coleção, categorias, curva, legalidade e playtest orientam a construção | A tela começa pelo objetivo do jogador ou por uma lista genérica de staples? |
| Entender uma recomendação | Popularidade não prova qualidade; usuários desconfiam de recomendações e IA opacas | Origem, amostra, motivo, confiança e impacto estão visíveis antes de aplicar? |
| Testar antes de gastar ou jogar | Sample hand, goldfish e playtest ajudam a validar o plano | O diagnóstico termina em ação e teste ou em modal informativo? |
| Usar o app durante a partida | Vida, commander damage, veneno, dados, histórico e retomada precisam de poucos gestos | A mesa tem identidade e prioridade próprias ou parece formulário administrativo? |
| Compartilhar e receber feedback | Revisores alternam entre várias abas para ver cartas, plano e mudanças | Comentário e compartilhamento carregam carta, categoria, diagnóstico e intenção? |
| Confiar em preços e propriedade | Impressão, tratamento, mercado, moeda e atualização alteram o significado do valor | Todo preço informa contexto e evita edição escolhida por engano? |
| Não ficar preso ao produto | CSV, texto, URL, IDs e sync reduzem retrabalho entre ferramentas | Importação/exportação mostram prévia, ambiguidades e erros corrigíveis? |

### 5.2 Personas mínimas

1. iniciante com o primeiro precon de Commander;
2. jogador retornando com caixas de cartas não catalogadas;
3. colecionador/trader preocupado com impressão, condição e preço;
4. brewer experiente que usa filtros, sintaxe, categorias e playtest;
5. jogador de mesa que precisa localizar cartas, compartilhar deck, jogar e registrar aprendizado.

### 5.3 Jornadas obrigatórias

1. descobrir comandante, tema ou ponto de partida;
2. pesquisar e compreender uma carta;
3. importar ou escanear coleção;
4. corrigir impressão e organizar localização;
5. criar, gerar ou importar deck;
6. montar com cartas possuídas e realmente disponíveis;
7. interpretar diagnóstico e recomendação;
8. comparar, adicionar, remover, desfazer e testar;
9. localizar, negociar ou comprar cartas faltantes;
10. compartilhar o deck e receber feedback contextual;
11. iniciar, retomar e encerrar partida;
12. transformar a partida em ajuste do deck.

## 6. Critérios da auditoria por superfície

Cada rota, página imperativa, aba e overlay recebe a ficha padrão. A avaliação não usa somente uma nota; registra evidência e consequência.

| Dimensão | Pergunta central |
|---|---|
| Clareza | O usuário compreende contexto, estado e ação principal sem explorar menus? |
| Continuidade | Entrada, saída, back, deep link e retomada preservam intenção e trabalho? |
| Valor | A superfície ajuda um job real ou apenas expõe dados/capacidade técnica? |
| Ação | Informação termina em próxima ação segura, comparação ou decisão? |
| Identidade visual | A tela pertence ao universo ManaLoom/Magic ou parece template genérico? |
| Imagem significativa | Arte ajuda a reconhecer, escolher ou confirmar o objeto em contexto? |
| Densidade e hierarquia | Conteúdo importante vence cards, chips, filtros e CTAs concorrentes? |
| Confiança | Origem, atualidade, preço, regra, IA e estado da mutation são honestos? |
| Recuperação | Loading, vazio, erro, offline, retry, conflito e sessão expirada são distintos? |
| Inclusão | Alvos, semântica, contraste, escala de texto, teclado e movimento são adequados? |
| Responsividade | Mobile, desktop e wide recompõem a tarefa, sem apenas esticar layout? |
| Desejabilidade | A tela desperta vontade de explorar e voltar sem sacrificar eficiência? |

Escala por dimensão:

- `0 — ausente ou enganoso`;
- `1 — bloqueia ou confunde`;
- `2 — funcional, porém frágil/genérico`;
- `3 — claro e coerente`;
- `4 — distintivo, eficiente e comprovado`.

Uma média nunca neutraliza risco de segurança, privacidade, perda de dados, regra incorreta ou ação destrutiva.

## 7. Auditoria de imagens e interesse visual

Não se deve “colocar imagem em todo lugar”. Deve-se usar imagem quando ela realiza trabalho narrativo ou de decisão.

### 7.1 Imagem provavelmente necessária

- carta em busca, recomendação, coleção, trade, set, deck, replay ou batalha;
- comandante como identidade e âncora do deck;
- impressão exata quando edição, foil, idioma, condição ou preço importam;
- comparação antes/depois em otimização;
- contexto compartilhado em comentários e feedback.

### 7.2 Imagem provavelmente opcional

- autenticação, privacidade, segurança de conta e textos legais;
- confirmação curta sem objeto visual ambíguo;
- áreas densas em que modo compacto é necessário.

### 7.3 Checklist de imagem

1. A imagem ajuda a reconhecer, decidir ou confirmar?
2. É a carta/impressão correta, inclusive double-faced e fallback?
3. O crop preserva informação relevante?
4. Loading, falha, offline e ausência possuem fallback honesto?
5. Existe modo compacto/lista para densidade, dados limitados e acessibilidade?
6. A arte domina a hierarquia certa ou virou ruído decorativo?
7. Fonte, cache, uso e atribuição respeitam a política aplicável?

Cada superfície recebe um dos rótulos:

- `IMAGE_REQUIRED_MISSING`;
- `IMAGE_PRESENT_USEFUL`;
- `IMAGE_PRESENT_DECORATIVE`;
- `IMAGE_PRESENT_HARMFUL_DENSITY`;
- `COMPACT_MODE_NEEDED`;
- `IMAGE_NOT_APPLICABLE`;
- `RUNTIME_NOT_VERIFIED`.

## 8. Auditoria de modais, sheets, menus e mensagens

O inventário atual tem 49 diálogos, 23 sheets, 9 menus e 108 transientes. Eles não são dívida automaticamente; cada ocorrência deve provar que o contêiner corresponde ao job.

### 8.1 Taxonomia

| Rótulo | Uso correto | Tratamento provável |
|---|---|---|
| `SAFETY_CONFIRMATION` | Ação curta, destrutiva ou irreversível | Manter modal, com consequência e foco corretos |
| `BOUNDED_PICKER` | Escolha pequena e contextual | Sheet/modal pode permanecer |
| `QUICK_EDIT` | Edição curta, reversível e sem navegação própria | Sheet pode permanecer; preservar draft |
| `INLINE_EDUCATION` | Explicação necessária para a decisão atual | Levar para o contexto, progressive disclosure ou tooltip acessível |
| `FLOW_CANDIDATE` | Várias etapas, comparação, imagens ou trabalho persistente | Promover para rota/painel dedicado |
| `DEAD_END_INFO` | Informa algo e encerra sem ação útil | Reescrever como estado acionável ou remover |
| `HIDDEN_PRIMARY_ACTION` | Ação frequente escondida em menu genérico | Tornar visível no contexto certo |
| `TRANSIENT_MISUSE` | Snackbar carrega erro, instrução ou decisão que precisa persistir | Substituir por estado inline/recuperável |
| `SCOPE_OR_PAYWALL` | Explica recurso desabilitado, beta ou limite | Ser transparente; não simular CTA disponível |

### 8.2 Regra de promoção para fluxo

Um modal vira candidato a rota ou painel persistente quando possui duas ou mais destas condições:

- mais de uma etapa ou decisão dependente;
- comparação entre cartas, versões ou diffs;
- entrada longa, upload/importação ou correção por item;
- conteúdo que precisa ser retomado, compartilhado ou deep-linked;
- imagem de carta necessária para decidir;
- falha que exige recuperação sem perder trabalho;
- ação recorrente central ao produto;
- scroll longo ou controles avançados escondidos.

## 9. Estados e plataformas

Para cada superfície aplicável, a execução verifica:

- `initial`, `loading`, `progress`, `partial`, `stale`, `loading_more`;
- `saving`, `optimistic`, `disabled`;
- `empty`, `error`, `retry`, `offline`;
- `session_expired`, `permission_denied`, `conflict`;
- `success`, `reduced_motion`, `image_fallback`.

Plataformas/visões mínimas:

- Web real mobile 390 × 844;
- Web real desktop 1440 × 900;
- Web real wide 1920 × 1080;
- Android em runtime elegível;
- teclado Web real nas jornadas críticas;
- Android físico quando o contrato exigir aparelho físico;
- TalkBack humano como verificação separada de release.

## 10. Semântica de evidência

Cada afirmação recebe uma etiqueta. É proibido escrever somente “tem”, “funciona” ou “está bom”.

| Etiqueta | Significado |
|---|---|
| `CODE_SEEN` | A estrutura existe no código/manifesto |
| `AUTOMATED_PASS` | Teste automatizado relevante passou na execução corrente |
| `RUNTIME_SEEN` | Comportamento foi exercitado no runtime indicado |
| `VISUAL_OPENED` | Captura fresca foi aberta e inspecionada por inteiro |
| `USER_EVIDENCE` | Fonte externa relata diretamente a necessidade/dor |
| `INFERENCE` | Hipótese derivada das evidências; ainda exige validação |
| `GAP_CONFIRMED` | Problema reproduzido com evidência fresca |
| `PROPOSAL_ONLY` | Solução sugerida; ainda não implementada nem validada |
| `NOT_APPLICABLE` | Critério não pertence à superfície, com justificativa |

## 11. Método de execução

### Fase 0 — kickoff seguro

- reler contratos e confirmar `semantic_analysis`/`lineage`;
- registrar `git status` sem limpar o checkout;
- congelar SHA, digest de UI, inventário e matriz usados;
- marcar evidência histórica como baseline;
- criar diretório da rodada somente sob QA/evidência autorizada.

### Fase 1 — pesquisa e hipóteses

- atualizar fontes oficiais e relatos recentes;
- separar `O` (declaração oficial), `U` (usuário) e `I` (inferência);
- consolidar personas, jobs, dores e jornadas;
- formular hipóteses testáveis, sem copiar concorrente por reflexo.

### Fase 2 — inventário completo

- reconciliar 41 rotas com páginas imperativas, abas e overlays;
- enumerar cada diálogo, sheet, menu e transiente por arquivo/linha/trigger;
- mapear entradas, saídas, source of truth, mutations e estados;
- localizar uso e ausência de imagens por job, não apenas por widget.

### Fase 3 — prova automatizada e runtime

- executar gates proporcionais e registrar comandos/resultados;
- capturar os viewports previstos em build/runtime real;
- percorrer success, empty, error, modal, above/below fold e disabled;
- abrir todas as capturas; arquivo não aberto não recebe revisão visual;
- nunca usar imagem histórica para aprovar fonte alterada.

### Fase 4 — auditoria por superfície

- preencher a worksheet para cada rota e ocorrência não-route;
- executar teste de cinco segundos;
- classificar imagem, modal, ação, informação e continuidade;
- separar defeito, dívida, oportunidade, hipótese e não aplicável;
- registrar no mínimo uma evidência visual para cada finding visual.

### Fase 5 — auditoria de jornadas

- percorrer as 12 jornadas completas;
- medir mudanças de contexto, voltas, perda de filtros/drafts e becos sem saída;
- confirmar que coleção informa deck, deck informa partida e partida retorna aprendizado;
- registrar pontos em que o usuário precisa abandonar o ManaLoom ou usar outra ferramenta.

### Fase 6 — síntese e decisão

- consolidar mapa de lacunas, dívida modal e oportunidades de imagem;
- agrupar causa raiz para evitar dezenas de patches locais;
- priorizar por criticidade da jornada, alcance, frequência, confiança e esforço;
- criar pacote executável por onda, sem implementar;
- submeter decisões de produto que mudam escopo ao responsável humano.

## 12. Ondas de trabalho

| Onda | Escopo | Pergunta de decisão |
|---|---|---|
| 0 | Evidência, shell, autenticação e baseline | O usuário entra e retoma intenção com confiança? |
| 1 | Onboarding e Home | O ManaLoom entende o objetivo e mostra um próximo passo convincente? |
| 2 | Cartas, sets, coleção, fichário, mercado e scanner deferido | O usuário reconhece a carta e entende posse, impressão e disponibilidade? |
| 3 | Decks, geração, importação, análise e otimização | A construção assistida preserva intenção, criatividade e controle? |
| 4 | Life Counter, Battle, replays e pós-jogo | A mesa é imediata, legível, retomável e gera aprendizado? |
| 5 | Comunidade, social, mensagens, notificações e trades | Compartilhamento e coordenação mantêm contexto e confiança? |
| 6 | Perfil, legal e comercial | Segurança, privacidade e beta gratuita são transparentes sem UI genérica? |
| 7 | Jornada transversal, acessibilidade e responsividade | O ciclo completo funciona entre telas, tamanhos e falhas? |

## 13. Priorização

### Severidade

- `P0`: bloqueio do job principal, perda/corrupção, segurança/privacidade, regra enganosa, ação destrutiva ambígua ou fluxo sem recuperação;
- `P1`: quebra importante de continuidade, confiança, compreensão ou acessibilidade;
- `P2`: densidade, consistência, desejabilidade ou refinamento com workaround aceitável;
- `P3`: oportunidade experimental sem dor comprovada.

### Ordenação dentro da severidade

Usar `impacto × frequência × centralidade da jornada × confiança ÷ esforço`, todos documentados. A fórmula ordena itens da mesma severidade; não rebaixa P0.

## 14. Entregáveis da rodada de auditoria

1. ledger completo de rotas e superfícies não-route;
2. pesquisa atualizada com fatos, relatos e inferências separados;
3. mapa das 12 jornadas e seus pontos de ruptura;
4. scorecard tela a tela com evidência;
5. inventário de imagem: presente útil, ausente, decorativa, densa ou não aplicável;
6. inventário de modais: manter, tornar inline, promover a fluxo ou remover;
7. mapa de funcionalidade: existente/perceptível, existente/oculta, incompleta, ausente, deferida;
8. backlog priorizado por causa raiz e onda;
9. pacotes de solução com wireflow, conteúdo, tese visual, interação e aceite;
10. relatório executivo com recomendação `GO`, `GO_CONDITIONAL` ou `NO_GO` por onda.

## 15. Definition of done da auditoria

A atividade só termina quando:

- as 41 rotas têm disposição explícita, inclusive deferred e redirect;
- os 5 `MaterialPageRoute`, 49 diálogos, 23 sheets, 9 menus, 10 abas, 2 navegações e 108 transientes foram reconciliados por ocorrência ou grupo realmente equivalente;
- as 12 jornadas foram percorridas e documentadas;
- toda conclusão visual possui captura fresca aberta;
- toda alegação funcional informa plataforma, estado e evidência;
- toda ausência de imagem foi julgada pelo job, não por preferência estética;
- todo modal recebeu taxonomia e decisão;
- todo finding possui consequência para o usuário e critério de fechamento;
- backlog e pacotes de execução não misturam diagnóstico confirmado com ideia;
- nenhuma mudança de produto foi realizada sem autorização separada.

## 16. Stack recomendado para executar a atividade

- **Product Design plugin:** principal para heurísticas, pesquisa, jornadas, arquitetura de informação e crítica de produto;
- **Browser:** percorrer o build Web, interagir e capturar estados reais;
- **Computer Use / Screenshot:** inspecionar runtime nativo e superfícies fora do navegador;
- **frontend-skill:** lente de hierarquia, tipografia, composição, imagem, densidade e aparência genérica;
- **Figma plugin, se houver frames/fontes de design:** comparar intenção e runtime, além de preparar wireflows;
- **PostHog plugin, se houver telemetria real:** validar frequência, abandono e caminhos; ausência de dados não deve ser preenchida por suposição.

Product Design é o plugin principal para esta atividade. Os demais fornecem evidência e execução; nenhum substitui observação humana de jogador nem os contratos de release.

## 17. Fontes externas de partida

Fontes oficiais/de produto:

- [ManaBox](https://www.manabox.app/)
- [ManaBox — scanner](https://www.manabox.app/guides/scanner/getting-started/)
- [ManaBox — decks na coleção](https://www.manabox.app/guides/decks/collection-decks/)
- [Archidekt — visão oficial](https://archidekt.com/landing)
- [Moxfield — resumo público de recursos](https://github-wiki-see.page/m/moxfield/moxfield-public/wiki/Features)
- [EDHREC — como usar](https://edhrec.com/guides/how-to-use-edhrec)
- [EDHREC — metodologia de lift](https://edhrec.com/articles/from-synergy-to-lift-the-math-behind-edhrecs-new-era/)
- [Scryfall — sintaxe de busca](https://scryfall.com/docs/syntax)
- [Magic Companion](https://magic.wizards.com/en/products/companion-app)
- [Magic Companion — perfis e histórico, 2026](https://magic.wizards.com/en/news/announcements/companion-app-update-magic-player-profiles)
- [TopDecked — visão do produto](https://www.topdecked.com/about)

Sinais comunitários qualitativos:

- [O que apps de coleção/deckbuilding fazem mal — jun. 2026](https://www.reddit.com/r/mtg/comments/1ud8jyh/what_do_current_mtg_collectiondeckbuilding_apps/)
- [Qual deckbuilder e por quê — abr. 2025](https://www.reddit.com/r/EDH/comments/1k49c28/which_deck_builder_app_do_you_use_and_why/)
- [Scanner + deckbuilder em ferramentas separadas — dez. 2024](https://www.reddit.com/r/EDH/comments/1hksefi/what_do_apps_do_you_use_for_collection/)
- [Apps usados durante Commander — jun. 2025](https://www.reddit.com/r/EDH/comments/1lhweuc)
- [Confiabilidade de IA em regras e sugestões — dez. 2025](https://www.reddit.com/r/EDH/comments/1q0epg2/do_not_use_ai_to_make_deck_suggestions_or_clarify/)

**Regra de pesquisa:** concorrentes demonstram modelos mentais e expectativas; eles não definem automaticamente o roadmap do ManaLoom.

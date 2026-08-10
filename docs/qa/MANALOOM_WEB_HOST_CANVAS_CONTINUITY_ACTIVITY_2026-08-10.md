# ManaLoom — atividade de continuidade do canvas Web

Data: 2026-08-10
Estado: `IMPLEMENTED_LOCAL · AUTOMATED_PASS · TARGETED_RUNTIME_PASS · FULL_REANCHOR_PENDING`
Prioridade: `P1 QA/VISUAL · BEFORE_FINAL_REANCHOR`
Origem: revisão humana da janela Chrome que executava o checkpoint
`battle_learning_00_play_entry`

## Decisão

Eliminar as faixas brancas que aparecem fora da superfície Flutter durante a
execução Web controlada. Elas não pertencem à linguagem visual ManaLoom e não
devem ser confundidas com conteúdo, margem intencional ou estado vazio.

A captura governada de `1440×900` contém somente a superfície Flutter e não
apresenta as faixas. Mesmo assim, a janela de QA expõe o fundo padrão do host e
produz uma prévia visual enganosa. O problema será tratado antes da reancoragem
final para que runtime observado e evidência materializada comuniquem o mesmo
canvas.

## Checkpoint anterior à implementação

O hook oficial aprovou contratos locais, fonte Commander revisada, MCP,
varreduras de segredo, project logic e seus 18 testes. O commit normal foi
recusado somente pelo vínculo global de UI já conhecido: `latest.json` e o
perfil físico continuam no digest anterior. Em 2026-08-10, o responsável pelo
produto concedeu autorização explícita total para criar o checkpoint local com
`--no-verify` e iniciar este pacote.

Essa exceção não muda o estado da evidência, não promove `latest.json` e não
autoriza release, push, deploy ou escrita live.

## Diagnóstico confirmado

1. os harnesses Web chamam `setSurfaceSize` com o viewport governado;
2. quando a área visível do Chrome não coincide com essa proporção, o host de
   teste centraliza a superfície Flutter;
3. `app/web/index.html` não declara fundo para `html`/`body`, portanto a área
   externa usa branco do navegador;
4. o driver possui proteção para margens near-white horizontais, mas a janela
   humana pode mostrar sobra vertical antes da materialização do PNG;
5. a barreira cinza observada no centro é o overlay correto do bottom sheet; as
   faixas brancas acima e abaixo são host, não app.

## Direção de frontend

### Tese visual

O canvas Web deve permanecer uma superfície Obsidian contínua do primeiro
pixel do bootstrap ao último pixel disponível, mesmo quando o Flutter estiver
temporariamente menor, carregando ou sendo redimensionado.

### Plano de conteúdo

Esta atividade não adiciona conteúdo. A ordem permanece app shell → contexto
da Home → deck → decisão de partida; apenas o plano externo deixa de competir
com a interface.

### Tese de interação

- bootstrap, resize e abertura de overlay não podem revelar flash branco;
- o viewport solicitado pelo harness continua determinístico e mensurável;
- nenhuma mudança de movimento, navegação ou comportamento do bottom sheet é
  permitida neste pacote.

## Escopo autorizado

- declarar fundo Obsidian, margem zero e ocupação integral no host Web;
- preservar safe areas e o dimensionamento responsivo do Flutter;
- adicionar contrato automatizado que recuse regressão para host sem fundo;
- verificar se o driver precisa reconhecer sobra vertical sem recortar
  conteúdo legítimo;
- validar Web real nos viewports governados aplicáveis;
- atualizar digest, documentação gerada e ledger de evidência depois da
  implementação.

## Não objetivos

- redesenhar Home ou o bottom sheet de entrada de partida;
- alterar tokens, tipografia, imagens, copy, navegação ou breakpoints do app;
- promover `latest.json` manualmente;
- transportar crédito de capturas do digest anterior;
- executar migration, PostgreSQL live, Hermes/SQLite, deploy, commit adicional
  não revisado ou push.

## Critérios de aceite

### Automatizado

- `app/web/index.html` possui contrato explícito de canvas Obsidian;
- `html` e `body` não introduzem margem e ocupam a área disponível;
- o bootstrap Flutter continua same-origin e funcional em `/app/`;
- testes do contrato Web e do recorte de screenshot passam;
- analyzer não apresenta issue nos arquivos tocados;
- project logic permanece sincronizado.

### Runtime

- a janela Chrome não mostra faixa branca durante bootstrap, resize ou overlay;
- as capturas governadas continuam com dimensões exatas para mobile, desktop e
  wide;
- nenhuma faixa externa é incorporada ao PNG aprovado;
- nenhum overflow, corte de CTA ou deslocamento do bottom sheet é introduzido.

### Revisão visual

- abrir individualmente cada captura nova aplicável;
- confirmar continuidade Obsidian, hierarquia preservada e ausência de flash
  ou margem branca;
- não conceder `PASS_VISUAL_REVIEWED` global enquanto o Samsung físico estiver
  stale.

## Impacto na evidência existente

`app/web/index.html`, o driver e os contratos do harness participam do digest
de UI. Qualquer mudança nesses arquivos gera novo digest e invalida o crédito
corrente de `25 manifests/402 capturas Web`, ainda que o conteúdo Flutter seja
visualmente idêntico.

O digest local depois da implementação é
`df08241c0cbdf1f3ca52ac08ce2b711675a107f4c44afa1979ea8128edfd8925`.
Consequentemente, os manifests Web do digest anterior não são apresentados
como prova corrente e o aggregate oficial não foi promovido.

## Implementação e validação focal de 2026-08-10

- `app/web/index.html` passou a declarar `color-scheme: dark`, canvas
  `#0B0D12`, margem e padding zero, ocupação integral e overflow controlado em
  `html`/`body`, além do mesmo fundo no host Flutter;
- o `theme-color` do navegador foi alinhado ao token `backgroundAbyss` do app;
- `server/test/flutter_web_deploy_contract_test.dart` agora recusa regressão
  do contrato de canvas;
- o recortador de screenshot não foi alterado: sua suíte confirma que ele
  preserva uma captura escura integral e recusa recortar conteúdo assimétrico;
- o build Flutter Web release com base `/app/` concluiu e carregou todos os
  artefatos essenciais com resposta HTTP 200;
- no navegador real, `390×844`, `1440×900` e `1920×1080` apresentaram
  `html`, `body` e `flutter-view` em `rgb(11, 13, 18)`, margem `0px` e bounds
  exatamente iguais ao viewport, sem faixa branca visível.

Validações aprovadas:

- `dart test test/flutter_web_deploy_contract_test.dart`;
- `flutter test --no-pub --no-version-check test/tool/runtime_screenshot_crop_test.dart`;
- `flutter build web --release --no-pub --no-web-resources-cdn --base-href /app/`;
- inspeção visual focal nos três viewports oficiais.

Esta inspeção focal demonstra a correção do host, mas não substitui a
recaptura/revisão integral dos fluxos nem concede `PASS_VISUAL_REVIEWED`
global.

O gate `./scripts/quality_gate.sh ui-proof` foi executado depois da mudança e
falhou de forma esperada e saudável: o review e os manifests ainda apontam
para o digest anterior, os hashes não cobrem as capturas do digest novo e a
contagem revisada não cobre todo o runtime. Nenhuma evidência antiga foi
promovida ou marcada como corrente.

Depois da implementação, a sequência obrigatória é:

1. gerar e registrar o novo digest;
2. executar testes automatizados focais;
3. recapturar e revisar os perfis Web exigidos pela política;
4. conectar o Samsung SM-A135M e recapturar 54 checkpoints físicos;
5. reconciliar `26 manifests/456 capturas` e gerar o aggregate oficial;
6. executar gates humanos/hardware;
7. por último, obter o parecer jurídico externo assinado.

## Rollback

Reverter somente as declarações do host e seus testes, regenerar project logic
e repetir a prova afetada. Nunca restaurar manualmente hashes ou
`PASS_VISUAL_REVIEWED` de um digest anterior.

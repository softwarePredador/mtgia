# Ficha de execução (proposta) — `BT-UX-KIT-001`

> **Ledger de execução não autoritativo e ainda não registrado.** O ID, a prioridade, o estado,
> as dependências e o aceite são resolvidos no backlog mestre e no registry gerado — nada aqui
> cria autoridade. Esta ficha existe para que o trabalho possa entrar no `NOW` sem perder um dia
> de preparo quando o slot abrir. Enquanto não for registrada, mora em `docs/design/execution/`
> e não em `docs/execution/tasks/`.

## Autoridade

- Task ID proposto: `BT-UX-KIT-001` (não existe no registry em 2026-09-21; os 13 IDs `BT-UX-*`
  atuais cobrem telas, nenhum cobre o kit compartilhado)
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` (Épico D)
- Registry consultado: `docs/generated/TASK_REGISTRY.json` · sha256 `f895dbf96b4620ebab8ba80e81c0c2ab25e8a9c7168c5314154a976ab67131ac` · 220 tasks
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`
- Origem da decisão: o dono definiu em 2026-09-21 que o layout novo do contador é o padrão do
  app inteiro, e que o kit é o próximo `NOW` quando o gate de evidência fechar.
- Especificação técnica: `docs/design/ui-kit-spec.md` (1.635 linhas)
- Fonte da verdade visual: `docs/design/life-counter-prototype/`
- Diagnóstico que originou: `docs/design/visual-audit-2026-09-21/README.md`
- Sequência das telas: `docs/design/sequencia-e-esforco.md`

## Identidade da execução

- Owner: `pendente — quem estiver com o slot NOW`
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA no preparo: `b397f477bffafb25e2ee3dea51186e5989b8d456`
- Início/fim UTC: `pendente`
- Classe de fechamento: `LOCAL_CODE`
- Autorização máxima: `local-read-only` para o preparo; a execução precisa de escrita em
  `app/lib` e `app/test`, e de nenhuma capability nova.
- Worktree: **próprio**, conforme instrução do dono. Não compartilhar árvore com a sessão de
  evidência de UI.

## Critérios de entrada (todos obrigatórios)

1. **Gate de evidência fechado.** `BT-UIEV-001` / `BT-SCP-001` concluídos e o digest congelado
   (`8bba809c`, 216 capturas) publicado. Enquanto a sessão de evidência estiver capturando,
   qualquer escrita em `app/lib`, `app/assets` ou `app/web` invalida o trabalho dela na hora.
2. **Slot `NOW` livre.** `docs/execution/CURRENT_QUEUE.md` mostra WIP máximo 1; hoje o slot é do
   `BT-SCP-001`.
3. **Protótipo estável.** `docs/design/life-counter-prototype/README.md` ainda lista telas na
   linguagem antiga (teclado de vida, resumo, partidas guardadas). O kit cobre o que já foi
   convertido; ver Limites. Reler o snapshot imediatamente antes de começar.
4. **Decisões de produto respondidas.** As da §11 da spec que mudam pixel: A7 (ícone da coroa),
   C2/C3 (brasa cheia), D1 (fio da placa), E1 (colisão brasa × assento). Sem elas, as primitivas
   entram com o valor do protótipo e um `// TODO(A7)` — o que é aceitável, mas vira retrabalho.
5. **Baseline reproduzível:** `flutter test test/core/theme/` verde antes de qualquer edição, com
   o comando e a saída colados na ficha.

## Resultado pretendido

### Dentro do escopo

- Cinco primitivas em `app/lib/core/widgets/`, conforme §4 da spec: `AppTile`, `AppNumeral`,
  `AppTileBoard`, `AppTileOverlay`, `AppHeroTile`.
- As peças derivadas de §5 que são composição direta e não custam tela nova: `AppChoicePiece`
  (miniatura), `AppNumeralPiece`, `AppRuleTile` (a peça-regra que acende e diz VALE),
  `AppActionBar` e `AppPlaque` (entrada de texto livre, §6).
- Tokens do kit como `ThemeExtension`, em `app/lib/core/theme/bt_tokens.dart`.
- As **quatro revogações** em `app/lib/core/theme/app_theme.dart` (§7.1).
- Remoção dos 52 tokens `lifeCounter*` sem uso em `app/lib` (§7.2), com a busca que prova o
  não-uso colada na ficha.
- Guarda de regressão de §9 em `app/test/`, com catraca inicial em 24.
- Uma tela de espécimes em `app/test/` (golden), para que a regressão visual do kit seja pega
  por imagem e não só por regex.

### Fora do escopo (limite explícito)

- **Nenhuma tela de produto é redesenhada nesta task.** O kit entra sem cliente. As telas vêm na
  ordem de `docs/design/sequencia-e-esforco.md`, uma task por onda, cada uma com mockup aprovado
  pelo dono antes de abrir.
- Nenhuma capability muda. Nenhuma rota muda. Nenhum contrato de servidor é tocado.
- Nenhum asset novo. As fontes Fraunces e Inter já estão registradas no `pubspec.yaml`.
- Os sheets nativos do próprio contador (`life_counter/*_sheet.dart`, 196 pontos de conversão)
  ficam de fora: eles pertencem à sessão que converte o protótipo.

### Capabilities

- Antes e depois: **sem mudança.** Nenhuma capability é lida, criada ou alterada.
- Evidência default-deny: não aplicável — a task não toca em gate de capability.

## Decisão técnica F1 — onde moram os ~25 valores de cor novos

A spec deixou a escolha em aberto. **Decido pela opção (a): os literais de cor ficam em
`app/lib/core/theme/app_theme.dart`; `bt_tokens.dart` não tem nenhum literal de cor.**

Razão: o teste `app/test/core/theme/app_theme_token_usage_test.dart` isenta hoje quatro caminhos
(`app_theme.dart`, `features/scanner/`, `features/home/life_counter/`, `features/home/lotus/`) e
a própria mensagem dele diz que a isenção existe porque scanner e contador *têm sistemas visuais
independentes*. O kit é o contrário disso: ele existe para unificar. Abrir uma quinta isenção
enfraqueceria exatamente a guarda que esta task veio reforçar, e a `§9` propõe uma guarda nova em
cima da mesma ideia. Mantendo os literais num arquivo só, uma troca de marca continua sendo um
arquivo só.

`bt_tokens.dart` fica sendo um `ThemeExtension<BtTokens>` que **compõe** os valores de
`AppTheme` em gradientes, sombras, raios, numerais e escalas de tipo. Isso é o que a extensão
precisa carregar de qualquer forma, porque gradiente e sombra não cabem no `ColorScheme`.

Custo assumido: o orçamento de cor declarado em `app_theme.dart` vai de 24 para ~50 tokens, e a
frase que fixa 24 precisa ser reescrita — é a revogação (3) da §7.1. Registrar na própria ficha.

## Plano de implementação

Cada passo fecha com `flutter analyze` e `flutter test` verdes antes do próximo.

1. `bt_tokens.dart` como `ThemeExtension<BtTokens>`, sem literal de cor, lendo de `AppTheme`.
   Inclui os assentos, os vitrais, os gradientes (vidro 160°, vitral 158°, latão 158°), as três
   camadas de sombra, o véu radial e os numerais. Teste de unidade: `lerp` não perde token e
   `of(context)` resolve nos dois temas.
2. Acrescentar em `app_theme.dart` os ~25 valores novos e registrar a extensão nos dois temas.
   Ainda **sem** revogar nada: o app continua igual e a suíte continua verde.
3. `AppNumeral` primeiro, porque é a peça sem dependência: Fraunces, `FontVariation` no eixo
   óptico conforme §4.2 (o kit usa `opsz` automático, não fixo em 144 — foi o defeito que a
   revisão do kit pegou), `FittedBox` com piso, `lining`/`tabular` figures.
4. `AppTile`, com os nove estados e a precedência de §4.1d. É a peça central: 161 classes
   privadas `_Card`/`_Tile`/`_Panel` espalhadas pelas features existem porque ela não existia.
5. `AppTileBoard` e `AppHeroTile`.
6. `AppTileOverlay`, com o véu e o ✕ nos dois tamanhos (64 no board, 44 no cabeçalho da folha —
   a regra corrigida de §2).
7. Peças derivadas: `AppChoicePiece`, `AppNumeralPiece`, `AppRuleTile`, `AppActionBar`,
   `AppPlaque`.
8. **As quatro revogações** em `app_theme.dart`, juntas e num passo só, porque a (4) muda o
   comportamento padrão de todo `TextField` do app:
   - (1) linha 18, a regra dos gradientes;
   - (2) linhas 183–188, `cardGradient` "intentionally flat" → vidro do azulejo, mantendo o nome
     como alias depreciado para não quebrar as caixas chapadas de decks de uma vez;
   - (3) linhas 20–22, o orçamento de cor;
   - (4) linhas 717–731 e 858–872, `inputDecorationTheme` nos dois temas.
   Este é o passo de maior risco visual: ele muda telas que ninguém redesenhou ainda. Capturar
   antes e depois das telas mais afetadas e olhar as imagens.
9. Remover os 52 tokens `lifeCounter*` sem uso, com a prova de não-uso.
10. Guarda de regressão de §9 + golden do espécime.

### Fontes previstas

- `app/lib/core/theme/bt_tokens.dart` (novo)
- `app/lib/core/theme/app_theme.dart` (editado)
- `app/lib/core/widgets/app_tile.dart`, `app_numeral.dart`, `app_tile_board.dart`,
  `app_tile_overlay.dart`, `app_hero_tile.dart`, `app_choice_piece.dart`,
  `app_numeral_piece.dart`, `app_rule_tile.dart`, `app_action_bar.dart`, `app_plaque.dart` (novos)
- `app/test/core/theme/bt_tokens_test.dart`, `app/test/core/widgets/app_tile_test.dart` e irmãos (novos)
- `app/test/ui/legacy_pattern_guard_test.dart` (novo, §9)

### Gerados derivados esperados

- Golden do espécime do kit. Nenhum outro golden deve mudar neste ID; se mudar, é regressão e
  precisa de justificativa por imagem, não por número.

### Migration/DDL

- Não aplicável. Nada de banco, nada de servidor.

## Plano de prova

### Funcional

- Positivo: cada primitiva monta em todos os estados e dispara o callback certo; o armado desarma
  em 6 s conforme §4.1c; a precedência de estados de §4.1d é respeitada.
- Negativo: peça desabilitada não dispara callback; peça em erro não parece peça acesa
  (é o defeito que a revisão do kit pegou no CSS e não pode voltar em Dart).
- Concorrência: não aplicável — widgets sem I/O. Justificar na ficha.
- Retry/idempotência: não aplicável pelo mesmo motivo.
- Failure injection: `BtTokens` ausente no tema → a primitiva cai no padrão do `AppTheme` em vez
  de estourar.

### UI/runtime

- `PASS_AUTOMATED`: suíte de widget das primitivas + a guarda de §9.
- `PASS_RUNTIME`: espécime renderizado nos quatro perfis (390 / 834 / 1440 / 1920).
- `PASS_VISUAL_REVIEWED`: **olhar as imagens**, com o critério da régua, não só "passou".
  Comparar o espécime em Flutter lado a lado com `docs/design/ui-kit/specimen-390.png` e com as
  provas do protótipo. O contrato de evidência exige decisão explícita sobre atratividade; aqui
  ela tem referência concreta, que é justamente o que a auditoria apontou faltar no resto do app.
- Acessibilidade: contraste conforme a tabela de §11 (os pares que passam, medidos no ponto em
  que o texto cai sobre o gradiente); alvo de toque ≥ 44pt / 48dp; `Semantics` com
  `label`/`value`/`selected`/`button`; foco por teclado na web; texto a 200% sem estourar;
  `MediaQuery.disableAnimations` desliga a varredura do estado carregando.

### Observabilidade

- Eventos/métricas: nenhum. A task não instrumenta nada.
- PII: não aplicável — nenhuma dessas peças toca dado de usuário.

## Aceite canônico proposto

| Cláusula | Evidência |
| --- | --- |
| As cinco primitivas e as cinco peças derivadas existem, com a API de §4 e §5 | Arquivos + suíte de widget verde |
| Nenhum literal de cor fora de `app_theme.dart` | `app_theme_token_usage_test.dart` verde, sem isenção nova |
| As quatro revogações estão aplicadas | Diff do `app_theme.dart` + a suíte inteira verde |
| A guarda de §9 existe e está na catraca 24 | Teste novo verde, com a contagem no receipt |
| O espécime em Flutter é a mesma peça do protótipo | Comparação por imagem, com as capturas anexadas |
| Nenhuma tela de produto mudou de comportamento | Goldens existentes inalterados, ou cada mudança justificada por imagem |
| Nenhuma capability mudou | Matriz de capability idêntica antes e depois |

## Rollback

`git revert` do commit único da task. Não há migração, dado ou capability para desfazer. O risco
real de rollback está no passo 8: se as revogações piorarem telas que ninguém redesenhou, dá para
reverter só elas mantendo as primitivas, porque elas são independentes — os passos 1 a 7 não
dependem das revogações para compilar.

## Riscos

1. **O passo 8 muda telas sem dono.** Revogar o `inputDecorationTheme` tira a caixa de todo
   `TextField` do app de uma vez. Mitigação: capturar antes e depois e olhar; se ficar pior em
   alguma tela, adiar a revogação (4) para a onda 6, que é quando auth e perfil entram.
2. **O protótipo ainda está mudando.** Três provas novas apareceram durante a extração do kit e
   trouxeram sete peças que faltavam. Mitigação: reler o snapshot antes de começar e tratar o kit
   como versão, não como verdade final.
3. **Espécime bonito, telas feias.** O kit por si não melhora nenhuma tela. O ganho só aparece na
   primeira onda. Mitigação: não fechar esta task como "visual melhorado" — ela é infraestrutura.
4. **Divergência com quem estiver mexendo em `app/lib` em paralelo.** Mitigação: worktree próprio
   e WIP-1, como a fila já exige.

## Bloqueios conhecidos em 2026-09-21

- `BT-SCP-001` ocupa o slot `NOW`.
- A sessão de evidência de UI está com 216 capturas congeladas no digest `8bba809c`; escrever em
  `app/lib` antes de ela fechar invalida o gate.
- As decisões A7, C2/C3, D1 e E1 da §11 continuam com o dono.

# ManaLoom UX-PACK-08 — overlays, estados críticos e prova focal

Data: 2026-08-06
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_PASS · ACCESSIBILITY_RELEASE_PENDING`
Autorização: continuações explícitas do usuário até “continue”.

## Resultado

O Pack 08 fechou o elo executável entre risco de UX e evidência:

```text
estado anterior verificável
  → ação/modal/sheet aberto por anchor estável
  → erro, cancelamento ou recuperação preservando contexto
  → checkpoint final causal
  → teste automatizado + runtime real + PNG aberto
```

No recorte focal Web, os três níveis obrigatórios passaram no mesmo digest:

- `PASS_AUTOMATED`: analyzer, 55 testes focais e harness controlado verdes;
- `PASS_RUNTIME`: `22/22` checkpoints em cada um dos três builds Web release;
- `PASS_VISUAL_REVIEWED`: os 66 PNGs finais foram abertos individualmente e
  aprovados depois da recaptura final.

O resultado não promove `docs/qa/ui-live/latest.json`. A matriz global e os
gates humanos/físicos continuam pendentes e fail-closed.

## Mudanças entregues

### Profile e segurança

- ações de segurança abaixo da dobra ganharam prova endereçável;
- avatar, senha, revogação de sessões e exclusão de conta possuem anchors
  próprios para open/cancel/validation;
- blocked users diferencia loading, erro com retry e lista recuperada;
- o dialog de bloqueados passou a usar altura dependente do conteúdo, e a linha
  mobile preserva nome, handle e ação sem estreitar o texto;
- erros longos de confirmação podem ocupar duas linhas sem cortar a mensagem.

### Decks e Commander

- o menu de ações, a confirmação destrutiva e o cancelamento do delete são uma
  sequência causal, sem depender de texto ou índice do Overlay;
- a confirmação limita o conteúdo a 520 px em desktop/wide, evitando o modal
  excessivamente largo;
- o deck permanece visível depois de cancelar;
- a seleção de comandante recuperada preserva arte, tipo, identidade de cor e
  ações de troca/remoção.

### Fichário

- lookup de edições diferencia falha/retry e recuperação;
- a impressão selecionada mantém set, collector, finish, idioma, raridade,
  preço e arte de referência governada no ponto de decisão;
- confirmação de remoção é cancelada na fixture;
- erro de save fica persistente junto às ações e preserva o editor.

### Trades

- o item picker usa altura proporcional à quantidade de resultados; uma única
  carta não abre mais um sheet quase vazio;
- a revisão mostra identidade exata, quantidade, condição, idioma, finish e
  valores dos dois lados antes do envio;
- falha de envio preserva a proposta e oferece retry inline;
- o snackbar duplicado foi removido, portanto o CTA não fica encoberto;
- quantidade oferecida respeita as cópias atualmente disponíveis.

### Estados transversais e Battle Coach

- sessão expirada e permissão negada usam estado, causa, consequência e saída
  específicos, com composição própria em mobile e wide;
- a política executável liga os 22 checkpoints a source, anchor, teste, fluxo,
  estágio e política de mutation;
- o harness do Battle Coach passou de sete para nove checkpoints, separando
  confirmação, progresso e terminal causal de concessão do progresso/terminal
  de uma ação comum. Essa superfície Android continua separada da prova Web
  focal e não recebeu crédito visual novo neste pacote.

## Escopo da prova focal

Os 22 checkpoints cobrem:

1. Profile/security: oito estados;
2. Deck/delete/commander: cinco estados;
3. Binder/printing/delete/save: quatro estados;
4. Trade/picker/review/retry: três estados;
5. sessão expirada e permissão negada: dois estados.

Comando:

```bash
./scripts/manaloom_critical_overlays_states_visual_qa.sh
```

O script usa Flutter 3.44.6 pinado, Chrome/ChromeDriver compatíveis, asset
same-origin em loopback e providers/gateways em memória. Ele recusa console
com falha proibida, quantidade diferente de 22 ou PNG inválido.

## Evidência automatizada e runtime

Digest de UI:

```text
60bbef19248d02022c4f2521efc0583cf72a6f98c680efbb7674ab9d4c00bc33
```

Resultados:

- analyzer focal: 12 entradas, sem issues;
- testes automatizados focais: `55/55 PASS`;
- integration test controlado no Flutter tester: `PASS`;
- `web_critical_overlays_mobile_390x844`: `22/22 PASS_RUNTIME`;
- `web_critical_overlays_desktop_1440x900`: `22/22 PASS_RUNTIME`;
- `web_critical_overlays_wide_1920x1080`: `22/22 PASS_RUNTIME`;
- consoles dos três perfis: zero entrada proibida;
- `66/66 PASS_VISUAL_REVIEWED`, após abrir cada PNG final em resolução
  original.

Manifests:

```text
mobile   2efbb1ab9bc6f2dd241ffdb4e66a0f0bcd179228fac67621356e9c58a34069d5
desktop  18973d251d2c3284051bda5da702f7390cd87ee15a62e1fc8bc74830b2cfb382
wide     adfefa7b306614f9acebdb6acde1b7ce66b2e92fd7c07bc58ec1d25670ab1b96
```

Digest ordenado dos hashes das 66 imagens:

```text
5b8249fa152cc7576d7b7006534ac4142ad791a43e9e4fc34ce02813c34e56b5
```

Diretórios:

- `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile`;
- `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-desktop`;
- `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-wide`.

## Revisão visual iterativa

A rodada intermediária foi recusada por dois defeitos bloqueantes do recorte:

1. o picker com um único item ocupava quase toda a altura disponível;
2. a falha de envio mostrava aviso inline e snackbar duplicado, encobrindo a
   ação principal.

Ambos foram corrigidos, cobertos por regressão e os 66 checkpoints foram
recapturados. A revisão final não encontrou corte, overflow ou sobreposição
bloqueante. O espaço amplo na galeria desktop/wide quando existe apenas um deck
permanece um follow-up `P2` de densidade da tela-base; ele não prejudica o menu
nem o fluxo destrutivo auditado.

## Aggregate e acessibilidade de release

A política corrente passa a exigir 26 manifests e 453 capturas:

- 214 da matriz P0;
- 5 Battle Live;
- 21 Binder Import;
- 24 Deck Workshop;
- 30 Battle Learning;
- 48 Social/Trade;
- 15 Onboarding Intent;
- 30 Visual System Workspace;
- 66 Critical Overlays and States.

Em continuação autorizada no mesmo dia, a UI foi congelada no digest
`f45f96e34ca6b00c34952b25631c6ff3157e85e39afc06e1f8394e1484f0e90e` e
a reancoragem integral foi concluída. `latest.json` agora contém os `26/26`
manifests e as `453/453` capturas exigidas, sem carry-forward de hash antigo.
O Samsung físico `android_physical_sm_a135m` produziu novamente seus `54/54`
checkpoints; os 12 perfis Web dos Packs 05–08 foram recapturados junto com P0,
Battle Live e Packs 02–04.

Todos os PNGs foram abertos individualmente e reconciliados por arquivo,
dimensão e SHA-256. O aggregate registra `PASS_AUTOMATED`, `PASS_RUNTIME` e
`PASS_VISUAL_REVIEWED`, com zero finding bloqueante. O fechamento global e os
follow-ups de polish estão em
[MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

Continuam separados e pendentes:

- TalkBack humano no Android físico;
- smoke de hardware/release no Samsung;
- teclado Web de hardware real;
- revisão jurídica externa antes de release comercial.

## Limites e segurança

As fixtures do pacote são read-only, canceladas, de validação, estados
sintéticos ou falhas interceptadas. Não houve mutation live, migration,
escrita em PostgreSQL, Hermes/SQLite, alteração automática de regra/deck,
deploy, commit ou push. O checkout sujo preexistente foi preservado.

## Próximo passo

Preservar o aggregate `26/453` enquanto o digest não mudar e executar, como
gates separados, TalkBack humano, teclado Web real e smoke de hardware. O
primeiro pacote visual posterior deve priorizar as abas mobile truncadas do
detalhe de deck e a densidade das composições desktop/wide; qualquer patch
app-facing exige nova reancoragem.

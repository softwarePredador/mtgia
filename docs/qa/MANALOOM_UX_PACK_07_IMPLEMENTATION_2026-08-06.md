# ManaLoom UX-PACK-07 — sistema visual, perfis e workspace wide

Data: 2026-08-06
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`
Autorização: continuações explícitas do usuário até “continue”.

## Resultado

O Pack 07 deixou de tratar telas administrativas como uma coluna mobile
esticada e estabeleceu um workbench de jogador:

```text
identidade e contexto à esquerda
  → tarefa, campos e decisão à direita
  → Brass somente para prioridade/ação
  → Frost para contexto e leitura
  → feedback persistente no ponto da ação
```

O escopo focal fecha `UX-013`, `UX-014`, `UX-015`, `UX-016` e `UX-018` nas
superfícies autorizadas. `UX-005` continua governado pelos pacotes de identidade
de carta: o perfil público mostra arte quando há identidade exata, mas fixture
visual determinística não recebe crédito de integridade de printing oficial.

## Mudanças entregues

### Perfil próprio

- o layout wide usa `profile-wide-workbench`, com identidade do jogador,
  privacidade, localização pública, quota e atalhos em uma rail lateral;
- preferências, contexto de troca, visibilidade, segurança e conta usam seções
  planas com divisores, em vez de cards aninhados;
- os campos usam a largura útil disponível em desktop/wide;
- Save fica desabilitado sem alterações;
- `dirty`, `saving`, `success` e `error` aparecem inline no dock de ação;
- falha preserva os dados editados e permite nova tentativa;
- conta e segurança permanecem separadas da identidade pública.

### Perfil público

- identidade, histórico social e ações formam a rail pública;
- decks passam a ocupar a mesa principal em grid no wide e lista no mobile;
- o deck em destaque e a lista exibem arte de carta governada;
- as quatro abas cabem no mobile sem truncar `Fichário`;
- ausência e falha usam estados contextuais, sem transformar localização privada
  em conteúdo público.

### Primeiro deck e estados de jornada

- o primeiro uso de Decks vira um workspace de escolha entre criar, gerar com
  IA e importar;
- `primeiro uso`, `sem resultados`, `erro`, `offline`, `indisponível` e
  `loading` possuem eyebrow, cor, ícone, motivo e ação próprios;
- o estado compartilhado deixou de ser um card central genérico no wide e usa
  composição responsiva com motivo visual;
- CTA só aparece quando existe uma recuperação ou próxima ação real.

### Quota e polish

- a quota de IA usa um único modelo mental: **ações usadas**;
- percentual, barra e texto agora dizem `34 de 120 usadas · 86 disponíveis`;
- `Reconstruir` no pós-jogo não quebra no viewport compacto;
- importação usa concordância singular: `1 carta detectada` e
  `1 carta não identificada`.

## Tese visual aplicada

A lente do `frontend-skill` definiu uma “bancada do jogador”, não um dashboard
administrativo. Obsidian sustenta o fundo, Frost organiza informação e Brass
marca somente a prioridade. Perfil próprio, perfil público, primeiro deck e
estados de jornada têm composições diferentes porque representam jobs
diferentes; a unidade vem de tipografia, tokens, motivos e hierarquia.

Plano de conteúdo: identidade/contexto → tarefa/estado → evidência → decisão →
feedback. Tese de interação: a próxima ação fica inequívoca, alterações nunca
são salvas implicitamente e falha não apaga o trabalho do jogador.

## Evidência automatizada

A suíte focal repetida com Flutter 3.44.6 pinado passou `44/44` testes:

- linguagem e responsividade de `AppStatePanel`;
- modelo único de quota;
- Profile clean/dirty/saving/success/error e geometria 1920×1080;
- perfil público mobile/wide e deck art;
- primeiro deck mobile/wide e ações de criação/importação;
- concordância da importação e CTA pós-jogo;
- política executável de prova viva.

O analyzer focal passou sem issues. O harness controlado também passou no
Flutter tester antes da captura Web real.

`./scripts/manaloom_project_logic.sh --write` gerou oito artefatos e
`--check` confirmou sincronização. Os três diretórios focais passaram
novamente em `validate-directory`, com `10/10` PNGs íntegros cada.

## Evidência runtime e revisão visual

Comando focal:

```bash
./scripts/manaloom_visual_system_workspace_qa.sh
```

Digest de UI:
`a408c2a38564ae23dc94b97e2949fc404249a10d935fd4a416dd49666ca1fbd5`.

Foram exercitados dez checkpoints por perfil:

1. Profile limpo;
2. Profile dirty;
3. salvando;
4. erro de persistência;
5. salvo;
6. perfil público com decks e card art;
7. primeiro deck;
8. sem resultados;
9. offline;
10. indisponível.

Resultados:

- `web_visual_system_mobile_390x844`: `10/10 PASS_RUNTIME`;
- `web_visual_system_desktop_1440x900`: `10/10 PASS_RUNTIME`;
- `web_visual_system_wide_1920x1080`: `10/10 PASS_RUNTIME`;
- consoles dos três perfis: zero entrada proibida;
- `30/30 PASS_VISUAL_REVIEWED`, depois de abrir cada PNG final
  individualmente em resolução original.

Manifests:

```text
mobile   594308788e32a89b9d86a7c598203f593ab0b974f091377cb60aebff53731db6
desktop  4d45e5bdf95a28ea59ad8b9da4451dce94b9376b10098e7faa2fc33ddcfa8266
wide     00f18ff0b871a6191be795960f06c75c0489c22c14d8c2f1c67ed956dafc0ee8
```

Digest ordenado das 30 imagens:

```text
acd1cbfb47ea43615338d58174d9d252a1443131ed0b9dcee98d996c4a0f508d
```

Diretórios:

- `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile`;
- `docs/qa/ui-live/current/ux-pack-07-visual-system-web-desktop`;
- `docs/qa/ui-live/current/ux-pack-07-visual-system-web-wide`.

## Aggregate e release

O aggregate `docs/qa/ui-live/latest.json` permanece propositalmente no digest
global anterior `93009fc2…`, com 14 manifests e 294 capturas. A política
corrente passa a exigir 23 manifests e 387 capturas: 214 P0, 5 Battle Live, 21
Binder Import, 24 Deck Workshop, 30 Battle Learning, 48 Social/Trade, 15
Onboarding Intent e 30 Visual System Workspace.

A prova focal deste pacote não promove o aggregate nem reaproveita hashes
stale. A reancoragem integral depende do congelamento da UI e do Samsung físico
`android_physical_sm_a135m`. TalkBack humano, teclado Web real e smoke de
hardware continuam gates separados de release.

`./scripts/quality_gate.sh ui-proof` foi executado no digest corrente e falhou
fechado como esperado: review e os 14 manifests do aggregate estão stale, e os
nove perfis Social/Trade, Onboarding Intent e Visual System Workspace ainda
não pertencem a `latest.json`. Nenhum `PASS` global foi forçado. Entre os
alvos Android detectados existe somente `emulator-5554`; o Samsung físico
obrigatório não está conectado.

## Limites e segurança

Não houve migration, escrita em PostgreSQL, Hermes/SQLite, mudança de regra ou
deck, deploy, commit ou push. O checkout sujo preexistente foi preservado.

Para liberar espaço de build, foi executado somente `flutter clean` no app com
o toolchain pinado e depois `flutter pub get`; isso removeu artefatos Flutter
regeneráveis (`build` e `.dart_tool`), sem limpar mudanças do checkout.

## Próximo passo

O próximo pacote de trabalho é `UX-PACK-08`: ampliar prova de overlays,
estados de falha, below-fold e acessibilidade enquanto a UI é congelada. A
reancoragem global 23/387 deve ocorrer somente depois desse congelamento e com
o Samsung físico disponível.

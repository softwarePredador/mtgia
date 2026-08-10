# ManaLoom UX-PACK-04 — implementação e evidência local

Data: 2026-08-05
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_PASS`
Autorização: continuação explícita do usuário — “okay então pode prosseguir” e
“continue”.

## Resultado

O pacote fechou localmente o ciclo que antes terminava em telemetria ou texto
solto:

```text
Home / revisão do deck
  → iniciar, retomar ou encerrar uma sessão explícita
  → Life Counter ou Battle
  → mesa pública + replay imutável
  → cartas realmente observadas + problemas
  → recibo offline-first ligado à revisão
  → Optimize reabre a evidência autenticada
  → preview mostra preservar/revisar
  → aplicação continua sujeita aos gates existentes
```

A tese visual aplicada foi “registro de mesa pós-partida”: arte exata ancora a
revisão, verde identifica cartas a preservar, Brass identifica cartas a rever e
o recibo permanece visível antes do handoff. O fluxo não depende de nomes de
carta digitados livremente.

## Escopo implementado

### Home e sessão de mesa

- `Jogar agora` abre um seletor com arte do deck e revisão confirmada;
- o usuário pode declarar uma partida rápida sem deck, sem criar uma associação
  falsa;
- uma sessão pausada expõe `Retomar` e `Encerrar e registrar` como ações
  distintas;
- o encerramento preserva `play_session_id`, início, fim, deck, hash e versão da
  revisão no handoff para o pós-jogo;
- nenhuma sessão anterior é apagada silenciosamente para abrir outra.

### Battle Live e replay

- o cursor público aceita identidade visual somente quando recebe UUID exato em
  evento ou zona pública;
- campo, comando e timeline mostram arte de carta quando essa identidade existe;
- nome sem UUID permanece textual e nunca é convertido em arte por inferência;
- reconexão preserva registros já recebidos; timeout, conclusão e replay final
  têm ações próprias;
- o replay mostra resultado, zonas públicas e identidade exata disponível;
- `Registrar aprendizado` abre o pós-jogo com
  `play_session_id=battle-replay:<replay_id>` e revisão do deck, sem mutar o
  replay.

### Pós-jogo estruturado e offline-first

- cartas vêm do deck real e são selecionadas em três estados: neutra,
  `Preservar` e `Revisar`;
- cada sinal novo carrega `card_id`, nome, quantidade, papel de comandante e URL
  de imagem; notas legadas por nome continuam legíveis sem ganhar identidade
  inventada;
- issues usam vocabulário limitado (`mana`, compra, remoção, condição de
  vitória, velocidade e proteção);
- o recibo salvo mostra quantidade de problemas/cartas, vínculo de origem e a
  próxima ação;
- fila local, merge e tombstones preservam o comportamento offline-first;
- se a tela foi aberta para uma revisão histórica, mas o app só consegue
  carregar outra revisão atual, a seleção de cartas é bloqueada em vez de
  atribuir evidência à lista errada.

### Optimize autenticado

- o app envia apenas `post_game_note_id` como referência do contexto;
- o backend reabre a nota usando `user_id + deck_id + note_id`, rejeitando nota
  ausente, removida, de outro usuário ou de outro deck;
- os IDs escolhidos são canonicalizados contra as cartas do deck pertencente ao
  usuário; nome e imagem confiáveis são hidratados no servidor;
- notas livres não entram no prompt. Somente issues e sinais estruturados cruzam
  para a recomendação;
- a revisão da nota participa da assinatura de cache;
- o preview mostra a evidência usada, a revisão e as cartas `PRESERVAR` e
  `REVISAR` com arte;
- a evidência orienta a recomendação, mas não autoriza aplicação automática. Os
  gates de legalidade, assinatura, validação e `can_apply` continuam soberanos.

## Contrato de dados e privacidade

PostgreSQL continua sendo a verdade. A implementação reutiliza
`post_game_notes`, os endpoints owner-scoped existentes e a rota de Optimize;
não houve migration.

O contrato `post_game_optimize_evidence_v1` contém somente:

- identificadores e revisão do recibo;
- origem Life Counter, replay ou manual;
- issues estruturadas;
- cartas explicitamente marcadas para preservar/revisar;
- comparação entre hash registrado e hash atual do deck.

Zonas privadas, mão, library oculta, decisões do motor, notas livres e payload
bruto de replay não atravessam esse handoff. Replay e anotação pós-jogo
permanecem registros separados.

## Principais artefatos

- app:
  - `app/lib/features/home/home_screen.dart`;
  - `app/lib/features/battle/models/battle_live_cursor.dart`;
  - `app/lib/features/battle/screens/battle_live_spectator_screen.dart`;
  - `app/lib/features/battle/screens/battle_replays_screen.dart`;
  - `app/lib/features/retention/models/post_game_note.dart`;
  - `app/lib/features/retention/services/post_game_note_store.dart`;
  - `app/lib/features/retention/screens/post_game_notes_screen.dart`;
  - widgets de fluxo e preview do Optimize;
- backend:
  - `server/lib/retention/post_game_note_service.dart`;
  - parser/contexto e rota de `POST /ai/optimize`;
- prova:
  - `app/integration_test/battle_learning_visual_runtime_proof_test.dart`;
  - `scripts/manaloom_battle_learning_visual_qa.sh`;
  - política, perfis exclusivos, contrato de runtime e digest de evidência
    visual.

## Evidência automatizada e runtime

O harness usa Chrome real, build Web release e assets determinísticos empacotados
na mesma origem do app. Ele não depende de CDN para as artes de Home, replay,
pós-jogo e Optimize. Dez checkpoints são exigidos por perfil:

1. `battle_learning_00_play_entry`;
2. `battle_learning_01_active_session`;
3. `battle_learning_02_live_table`;
4. `battle_learning_03_reconnect`;
5. `battle_learning_04_timeout`;
6. `battle_learning_05_completed`;
7. `battle_learning_06_replay_evidence`;
8. `battle_learning_07_postgame_signals`;
9. `battle_learning_08_postgame_receipt`;
10. `battle_learning_09_optimize_evidence`.

Comando focal:

```bash
./scripts/manaloom_battle_learning_visual_qa.sh
```

Resultado: `PASS_RUNTIME` nos três perfis e 30 PNGs abertos individualmente por
`Codex /root`, todos com `PASS_VISUAL_REVIEWED`:

- `web_battle_learning_mobile_390x844` —
  `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/`;
- `web_battle_learning_desktop_1440x900` —
  `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-desktop/`;
- `web_battle_learning_wide_1920x1080` —
  `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-wide/`.

Os nomes exclusivos impedem colisão com os perfis homônimos da matriz P0. O
harness e o script de captura participam do digest; qualquer alteração neles
torna esta evidência stale.

Fonte UI capturada:

```text
93009fc2a9215288336406015b4583473c8520b75c409f9214852cec607452df
```

Hashes dos manifests:

```text
mobile   611184b4063aa5d39c81f3ed81d6d286ab1fd73f6cfa3ceb5cefe45cfcf6388e
desktop  ca678e98dbaa4adf9c7ebf2b94d3435309574646a3ea2780f21ca39bd5b05012
wide     993097317b7bb3cb4ff316d993b389e19f02bc51897298462c24fd4da7f0f40f
```

Digest ordenado das 30 imagens:

```text
1639d20c8b3dacb3a9fd0c2261ee978ac61848e7b3a38147d354fd536ccc92df
```

A primeira rodada de capturas foi recusada porque artes locais ainda estavam no
placeholder de carregamento. A prova passou a aguardar explicitamente cada arte
e a usar assets da própria origem do build; os três perfis foram regenerados e
as 30 novas imagens foram reabertas antes da aprovação. No trilho horizontal do
Optimize mobile, a segunda carta fica parcialmente visível como affordance de
rolagem; texto, estado e CTA permanecem acessíveis no trilho e ficam completos
nos perfis desktop/wide.

## Verificações focais

- análise estática dos 21 arquivos do harness: `PASS`;
- smoke controlado no `flutter-tester`: `PASS`;
- testes focais Flutter: `107/107 PASS`;
- testes focais do servidor: `46/46 PASS`;
- suíte Flutter completa: `1489 PASS · 1 skip declarado · 0 falhas`;
- suíte do servidor completa: `752 PASS · 3 skips declarados · 0 falhas`;
- analyzers Flutter e servidor: `PASS · no issues found`;
- inventário de superfícies: `260` ocorrências reconciliadas e testes
  `4/4 PASS`;
- Chrome release 390x844, 1440x900 e 1920x1080: `30/30 PASS_RUNTIME`;
- revisão manual de cada PNG: `30/30 PASS_VISUAL_REVIEWED`;
- consoles dos três perfis: zero entrada proibida;
- política de evidência do Battle Learning: `3/3 PASS`;
- project logic: `--write` e `--check`, 8 artefatos sincronizados;
- reancoragem global: `14/14` manifests, `294/294` capturas e os três níveis
  obrigatórios no digest `93009fc2…`;
- `quality_gate.sh ui-proof` e `quality_gate.sh ui-audit`: `PASS` após a
  revisão individual das 294 imagens e a reconciliação dos hashes.

O resultado agregado, os hashes e os follow-ups visuais estão em
[MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

## Limites e trabalho remanescente

- a matriz P0 e os perfis focais exigidos estão reancorados no digest corrente;
  esse crédito expira quando o digest de UI mudar;
- Android físico, TalkBack humano e teclado Web real continuam verificações de
  release separadas;
- o pacote não prova estratégia ideal, win rate, promoção de aprendizado do
  motor ou aplicação contra PostgreSQL live;
- arte de Battle só aparece com identidade exata publicada; fallback textual é
  intencional quando o contrato não possui UUID;
- a conclusão local não autoriza release, deploy, migration, alteração de pin,
  regra ou deck.

## Segurança de entrega

Não houve commit, push, deploy, migration, limpeza de checkout, escrita em
PostgreSQL live ou alteração de Hermes/SQLite. O checkout sujo preexistente foi
preservado.

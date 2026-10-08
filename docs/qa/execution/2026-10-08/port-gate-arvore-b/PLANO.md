# PR-B: consertos de app da árvore antiga do gate (insumos para a sessão de nuvem)

**O que é este diretório.** São os insumos para o PR-B da reconciliação da árvore antiga do gate. Essa árvore nunca foi commitada e está guardada localmente na ref `refs/backup/2026-10-08/gate-arvore-1419`, que não está no GitHub.

- Os patches em `patches/` são diffs por arquivo, de `47dc3b698` (a base, ancestral do master) para a árvore antiga.
- Os 28 arquivos com 0 no `MANIFESTO.md` não mudaram no master desde a base, então o patch aplica direto.
- Os outros 10 mudaram no master e precisam de reescrita à mão.

Origem: o workflow de classificação de 2026-10-08 (119 unidades de mudança, cada uma verificada por céticos) e o plano que saiu dele.

**Decisões do dono (2026-10-08):**
- **D-89:** este PR é feito na nuvem, sem os hooks locais, e depois entra uma recaptura única da prova de UI.
- **D-90:** com troca ou venda desligadas, o editor do fichário limpa as flags ao salvar um item antigo, em vez de deixar o servidor devolver 422.
  - Ele manda explicitamente `for_trade: false` (trocas fechadas) e `for_sale: false` com `price: null` (marketplace fechado).
  - Omitir os campos **não** basta. O `PUT /binder/:id` é parcial: campo ausente mantém o valor antigo no banco (`server/routes/binder/[id]/index.dart`, os blocos `body.containsKey('for_trade' | 'for_sale' | 'price')`).
  - O servidor aceita `false`/`null` com a capability fechada, que é como se tira uma oferta (`server/lib/binder_item_contract.dart`, `ensureBinderCommerceAllowed`).
- **D-88:** o ADR 0014, da pergunta genérica do motor, está aceito. Ele vai no PR-A2.
- **D-91:** os goldens do herói da Home são refeitos no Mac do gate. Não fazem parte deste PR.

**Pré-requisitos:**
- O PR-A1 (`port/gate-arvore-a1-fora-do-digest`) entrou no master. Ele traz o `scripts/lib/manaloom_fixture_asset_server.py`, de que o B11 depende.
- Faça a branch a partir do master atualizado.

**Ao terminar:**
- A prova de UI fica velha: todo este PR mexe em raízes do digest (`app/lib`, `app/integration_test` e os scripts de QA visual).
- A recaptura única dos 23 manifestos, mais os opcionais (battle-coach-android, core-product-android e battle-coach-web-keyboard), vem num PR seguinte, junto com as outras mudanças de app da fila. Precisa de `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`, `./scripts/quality_gate.sh ui-proof` e `project_logic --write/--check`.

## Passos (do plano de 2026-10-08)

Legenda:
- **P**: patch direto deste diretório.
- **R**: reescrita sobre o master.
- **3W**: `git apply --3way`.

**B6. Battle no app** (risco médio)
- `interactive_battle_session.dart` (**P**) e `app/test/.../interactive_battle_ability_art_test.dart` (**P**).
- `battle_coach_screen.dart` (**P**, os três hunks):
  - autofocus no índice 0 e no halo, com `_pedirFocoAteAssentar(4)`;
  - `_EnvoltorioDeFocoDoPrompt`, que recebe o `ValueKey(prompt.id)`;
  - slot da carta virada (`card.tapped ? height : width`).
  - Depois, `dart format`.
- Testes desse arquivo:
  - `battle_coach_prompt_focus_test.dart` e `battle_coach_tapped_card_slot_test.dart` (**P**);
  - novo widget test com prompt `integer`/`multi_amount`: `primaryFocus` fica no painel, não em "Abrir replays".
- `battle_replays_screen.dart`: **P** para "Mão" e "neste replay"; **R** para trocar "Exilio" por "Exílio".
- `interactive_battle_service.dart` (**P**, ramo `not_waiting`) e `interactive_battle_friendly_message_test.dart` (**P**).
- Rodar: `battle_coach_screen_test.dart` (31 testes), `battle_local_homologation_test.dart` e a mutação `autofocus: false`.

**B7. Fichário D-04/A8** (risco médio)
- `binder_screen.dart` (**P**). No mesmo commit, esconder também os chips de filtro Troca/Venda, as tags e o preço dos itens, e ajustar o `showStats`.
- `binder_item_editor.dart` (**3W**; a6c0859c0 não encosta nos hunks) e `binder_item_editor_validation_test.dart` (**P**).
- Teste novo do `binder_screen` com `ReleaseCapabilitiesProvider.seeded`, nos dois sentidos.
- **R**: semear trades e marketplace em `app/integration_test/binder_marketplace_trade_runtime_test.dart` (`_runtimeApp`) e em `app/patrol_test/manaloom_patrol_smoke_test.dart` (harness do editor).
- Rodar: `flutter test app/test/features/binder/`, que inclui os testes de resiliência, overflow e acessibilidade.
- Atualizar o A8 em `docs/flows/_p0/contencao-escopo.md` e `UI_TEST_SURFACE_MAP.md:508`.

**B8. Perfil, lado app do BT-AUTH-004** (risco **alto**: a exportação está quebrada em produção, porque o app manda GET e o servidor responde 405)
- `account_privacy_service.dart` e o teste dele (**P**).
- `profile_screen.dart` (**P**; a linha mudada por 5d1e7cf56 fica fora dos hunks). Trocar a chave fixa por `Key('${widget.keyPrefix}-dialog')`.
- `profile_screen_test.dart` (**P**), acrescentando asserts de `profile-export-data-dialog` e `profile-revoke-sessions-dialog`.
- `app/test/ui/fixtures/ui_surface_inventory.json` (**R**): `profile_screen` com `dialog` 7; `expected_totals.dialog` de 52 para 53.
- `ui_surface_inventory_test.dart` (**R**): baseline de 267 para 268, com a reason citando 24f4e4c9f e BT-AUTH-004.
- Rodar: `flutter test test/features/profile/ test/ui/ui_surface_inventory_test.dart`.
- Atualizar no backlog BT-AUTH-004 e BT-PRIV-001, e `CURRENT_QUEUE.md:84`.

**B9. Núcleo do app** (risco médio)
- `app/lib/core/services/realtime_push_gate.dart` (novo, cópia do REF) e o teste dele (cópia).
- `main.dart` (**R**): o import e o corpo de `_canHandleRealtimeData` delegando a `canHandleRealtimePushData`. O hunk de import do REF conflita por contexto.
- `friendly_error_mapper.dart` (**R**): `_machineErrorCodePattern` passa a aceitar código de palavra única, com no mínimo 3 caracteres, igual ao `isStablePublicErrorCode` do servidor.
- `friendly_error_mapper_test.dart` (**R**):
  - 403 com `{'error':'forbidden'}` mostra a frase de permissão;
  - 403 com `email_verification_required`, com e sem `message`, não mostra "não tem permissão";
  - 403 sem corpo ou com `access_forbidden` mostra "não tem permissão";
  - incluir o código no laço "never shows the raw code".
- Atualizar A9 e D5b em `contencao-escopo.md`.

**B10. Testes de integração que são raiz do digest** (risco médio)
- `battle_coach_visual_runtime_proof_test.dart` (**P**, as três unidades juntas): desmontar com `SizedBox.shrink`, limiar `>= 1` e `_waitForFinderWithRealTime`.
- `core_product_acceptance_runtime_test.dart` (**P**, os três hunks mais o import): semente do fichário, semente do DeckListScreen e `optimize-paired-swap-checkbox-0`.
- Rodar o pré-voo em flutter-tester (esperado `+4`; a mutação sem o bootstrap ffi dá `+0 -4`). Depois `--capture-core-product` e `--capture-battle-coach` com o emulador `-no-window`.

**B11. Scripts shell que são raiz do digest** (risco médio)
- `manaloom_authenticated_visual_qa_isolated.sh` (**P**, `fail_check`).
- `manaloom_play_vs_ai_e2e.sh` (**R**): só a função `fail_check` depois do `umask 077` e as 17 conversões, uma a uma. Não trazer Kari Zev nem o bloco de nome e device_contract do REF; o D-80 do master fica.
- `scripts/manaloom_errexit_lint_pending.json` (**R**): remover as 21 entradas, deixando `pending` vazio, e atualizar o `reason`. Também tirar a palavra "rascunho" da linha BT-CI-002 no backlog e no receipt.
- `manaloom_server_contract_e2e_isolated.sh` (**R**): só a mensagem `after 30s: $output` com PID e comando. Não trazer o seed Kari Zev.
- Os 5 scripts `*_visual_qa.sh` (**P**) e a linha 184 de `manaloom_ui_live_evidence_gate.sh` (**R**): trocar o servidor de assets por `manaloom_fixture_asset_server.py`.
- Opcional: pôr o `.py` em `SOURCE_ROOTS`.
- Rodar:
  - `python3 scripts/manaloom_errexit_lint.py --scan . --pending scripts/manaloom_errexit_lint_pending.json`
  - `python3 server/test/errexit_postdeploy_test.py`
  - `scripts/manaloom_release_ops_contract_test.sh`
  - `bash -n` nos scripts
  - `curl -I` no servidor de assets, conferindo `Access-Control-Allow-Origin`.

**Acréscimo pela D-90, no B7:** com a capability correspondente desligada, o `binder_item_editor.dart` manda `for_trade: false` e, para venda, `for_sale: false` com `price: null`. Ele não omite os campos, porque o PUT é parcial e a omissão deixaria a oferta antiga gravada. Assim, um item antigo com oferta salva sem 422, e as flags caem no banco.

Testes:
- Salvar um item antigo com `for_trade`, `for_sale` e preço, com trocas e marketplace desligados: o corpo do PUT leva `for_trade: false`, `for_sale: false` e `price: null`.
- Com as capabilities ligadas, os valores do formulário vão como estão.
- Mutação omitindo os campos: o teste falha.
- Do lado do servidor, um PUT com `false`/`null` e a capability fechada responde 200 e zera as colunas. Use o teste que já existir na matriz mista do `server/test/binder_item_contract_test.dart` (PR-A1); se não existir, acrescente.

**Recibos que entram com o código** (os patches 35 a 38):
- `pva-primeira-pergunta-mata-a-mesa.md`: corrija o caminho de referência e marque o GAME_SELECT como fechado pelo PR-A2.
- `itens-1-a-3-antes-do-congelamento.md`
- `battle-coach-web-keyboard-achado-foco.md`
- `btuiev001-play-vs-ai-recaptura-digest-novo.md`

O patch 34 traz a regra BT-CI-002 para `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, que é bootstrap do pre-commit.

**Abrir no backlog:**
- F-02: opções idênticas repetidas no painel do Battle;
- F-03: o rótulo "Ability" aparece em inglês;
- F-01: vai para o BT-UX-KIT-001;
- `jq -e` sem mensagem em `validate_browser_qa_real_session`;
- descasamento engine×creature no otimizador;
- caso QUESTION em `promptTitle`, com o texto e os rótulos próprios do motor (ADR 0014).

**Fica de fora de propósito:**
- O Kari Zev no lugar do Krenko: o master fechou o checkpoint 05 sem trocar o deck.
- O bloco de nome e de `device_contract` do `play_vs_ai_e2e.sh` do REF: o D-80 do master fica.
- O `binder_commerce_capability_test.dart` e a API antiga do fichário: o master já tem `ensureBinderCommerceAllowed`.

# Receipt — LC-P0-03: saída fail-closed sem flush — 2026-10-05

- Branch `claude/frente-contador-de-vida-ibnawb`. Raia do app. Nada tocou a produção.
- `lotus_life_counter_screen.dart`: se a barreira de flush não confirma (falha, timeout de 900 ms, host sem barreira ou conta fechada), a mesa não fecha. Abre o diálogo "A mesa não foi salva" com "Tentar salvar de novo", "Continuar jogando" e "Sair sem salvar". A escolha vira evento `exit_unsaved_choice`.
- `home_screen.dart`: com `storageFlushed=false` não diz "Sessão pausada"; avisa que a mesa volta ao último ponto salvo.
- `deck_details_screen.dart`: com `storageFlushed=false` não diz "salva" e oferece "Registrar pós-jogo" mesmo sem atividade detectada, porque o falso negativo do A8 vinha justamente daí.

## Evidência

`app/test/features/home/lotus_life_counter_screen_test.dart`: o teste do timeout agora exige o diálogo e só sai por "Sair sem salvar"; o teste novo cobre "Continuar jogando" (a mesa fica) e "Tentar salvar de novo" (sai com `storageFlushed=true`). Arquivo inteiro passa.

Falta: as capturas do diálogo no lote do `BT-UIEV-001`.

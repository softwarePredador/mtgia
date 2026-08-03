# Prova Web publicada — Battle Live

Capturas obtidas no Web público em 2026-08-03, após publicar o commit
`3a3b7847a620ad5c7285eb653abfaae73f11e034` com Battle interativo e espectador
ao vivo habilitados.

- `production_02_censored_max_turns.png`: encerramento terminal por limite de
  turnos, mantendo mesa e timeline públicas visíveis.
- `production_03_completed_replay_persisted.png`: execução anterior concluída
  sincronizada como `Concluído` e `Replay persistido`.
- `production_04_replay_opened.png`: replay persistido aberto no Battle Lab.

Durante a execução recém-criada, a interface mostrou `Iniciando a simulação`
aos 3 segundos e, aos 25 segundos, `Partida em andamento`, turno 13, zonas dos
dois decks e 80 eventos públicos. Esses checkpoints intermediários também têm
equivalentes determinísticos na pasta pai (`battle_live_00_waiting.png` e
`battle_live_01_active_feed.png`).

Nenhuma credencial da conta E2E foi preservada.

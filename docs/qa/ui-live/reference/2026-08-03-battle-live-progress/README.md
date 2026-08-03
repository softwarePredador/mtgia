# Referência visual — Battle Live, 2026-08-03

Este diretório preserva a prova visual da correção que tornou o processamento
da Battle observável do início ao replay. As imagens foram produzidas por um
build Flutter Web release real e abertas individualmente durante a revisão.

## Estados preservados

- `battle_live_00_waiting.png`: sessão criada e aguardando os primeiros dados.
- `battle_live_01_active_feed.png`: registros públicos recebidos e estágio
  apresentado como partida em andamento.
- `battle_live_02_recoverable_reconnect.png`: reconexão sem apagar mesa e
  timeline já recebidas.
- `battle_live_03_timeout_terminal.png`: encerramento por limite com ações de saída e
  nova tentativa.
- `battle_live_04_completed_replay.png`: status concluído e replay persistido.

O `capture-manifest.json` registra o digest do código, viewport, runtime e
hashes das capturas. O resultado consolidado está em
[`../../latest.json`](../../latest.json).

## Matriz completa da mesma rodada

As 214 capturas complementares continuam nas pastas canônicas abaixo e ficam
preservadas pelo mesmo commit, sem duplicar dezenas de megabytes de PNGs:

- Android: [`../../../../../app/test/ui/goldens/runtime/android_emulator`](../../../../../app/test/ui/goldens/runtime/android_emulator)
- Web mobile: [`../../../../../app/test/ui/goldens/runtime/web_mobile`](../../../../../app/test/ui/goldens/runtime/web_mobile)
- Web desktop: [`../../../../../app/test/ui/goldens/runtime/web_desktop`](../../../../../app/test/ui/goldens/runtime/web_desktop)
- Web wide: [`../../../../../app/test/ui/goldens/runtime/web_wide`](../../../../../app/test/ui/goldens/runtime/web_wide)

Ao todo, 219 capturas receberam revisão visual nesta rodada. A única melhoria
cosmética observada fora do escopo Battle foi a quebra da última letra de
“Reconstruir” no Pós-jogo Web wide; ela está registrada no relatório vigente.

# Lorehold Battle Validation - 2026-06-17

Este diretório guarda provas controladas pequenas do slice local de
`Lorehold, the Historian` no `battle_analyst_v9.py`.

## Arquivos

- `lorehold_controlled_miracle_summary.json`
  - cenário com `Lorehold + Library of Leng + Sensei's Divining Top`;
  - prova:
    - reorder parcial do topo;
    - `lorehold_upkeep_rummage`;
    - uso da replacement de `Library of Leng`.
- `lorehold_controlled_miracle_cast_summary.json`
  - cenário com mana suficiente para o caso base;
  - prova:
    - `lorehold_upkeep_rummage`;
    - primeiro draw do turno do oponente;
    - `miracle_cast` efetivo no upkeep do oponente;
    - resolução do spell após passes de prioridade.

## Escopo

Esses artefatos não tentam provar uma partida inteira "ótima". Eles existem
para provar que o caminho mínimo do Lorehold agora funciona no runtime:

1. trigger de upkeep do oponente;
2. discard/draw com trace;
3. replacement de `Library of Leng`;
4. janela de miracle fora do draw step próprio;
5. reorder parcial com `Sensei's Divining Top`.

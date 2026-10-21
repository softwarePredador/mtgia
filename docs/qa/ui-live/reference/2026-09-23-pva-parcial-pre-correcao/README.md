# Corrida parcial 2026-09-23 — bloqueada por defeito do motor

Capturas genuínas, cada uma aberta e conferida antes de ser mantida, da corrida
dedicada de 2026-09-23 no digest de UI `108f74a9`:

- `01-opponent-picker.png`
- `02-private-hand-mulligan.png`
- `03-land-played.png` — Plains no **meu** campo, turno 4
- `04-commander-cast.png` — Isamaru resolvido no meu campo, turno 5

**Não** são evidência de release: o manifesto exige nove checkpoints e para no
quarto. A mesa morria na primeira pergunta de sim/não do motor (turno 4, fase
principal) com `engine_error` / `interactive_callback_failed` /
`IllegalArgumentException`.

Estas capturas são de ANTES da correção do motor. Causa, correção e provas:
`docs/qa/execution/2026-09-23/pva-primeira-pergunta-mata-a-mesa.md`.

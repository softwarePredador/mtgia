# Evidência BL2 — Replay visual rico

- Data: 2026-07-26
- Resultado: `PASS_LOCAL`

| Task | Estado | Evidência |
|---|---|---|
| BL2-01 | `PASS_LOCAL` | snapshot XMage normaliza step, ativo/prioridade, command, exile, stack e combat quando observados |
| BL2-02 | `PASS_LOCAL` | parser Forge aceita lados `deck_a/deck_b` e declara capacidades ausentes |
| BL2-03 | `PASS_LOCAL` | decisões native mostram escolha/alternativas/score/rationale apenas quando fornecidos e rotulados como heurística |
| BL2-04 | `PASS_LOCAL` | mesa responsiva separa oponente, centro de stack/combat, usuário e zonas; stack em `<1200`, dois panes em `>=1200` |
| BL2-05 | `PASS_LOCAL` | playback inclui play/pause, velocidade, anterior/próximo, slider e teclado |
| BL2-06 | `PASS_LOCAL` | momentos-chave derivam somente de eventos tipados |
| BL2-07 | `PASS_LOCAL` | diferenças de snapshot destacam mudanças observadas sem inventar causa |
| BL2-08 | `PASS_LOCAL` | timeline monta janela incremental/filtros e possui caso de 20 mil eventos |
| BL2-09 | `PASS_LOCAL` | JSON bruto fica em dados técnicos, não como leitura primária |
| BL2-10 | `PASS_LOCAL` | campo ausente vira `não disponível`; zonas ocultas usam contagem |

## Provas e limites

Testes de modelo/serviço/tela cobrem payloads XMage, Forge e native, unknown,
truncamento, filtro/timeline, teclado, reduced motion, texto 200% e viewports
mobile/desktop. A homologação visual Android física pertence a BL4 e continua
bloqueada por ausência de dispositivo nesta rodada.

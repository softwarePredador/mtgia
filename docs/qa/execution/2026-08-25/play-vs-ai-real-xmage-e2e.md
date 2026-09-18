# Receipt focal — Jogar contra IA em XMage real

Lifecycle: `FOCAL_PASS · NOT_TASK_CLOSURE · NOT_RELEASE`

Este receipt registra uma prova funcional contida da superfície **Jogar contra
IA**. Ele não move o slot `NOW`, não fecha `BT-PLAY-001/002`, não liga uma
capability e não substitui os P0 de topologia, capacidade, segurança, custo,
acessibilidade física ou rollout do programa Battle.

## Resultado

- Resultado do runner: `PASS`.
- Relatório local:
  `~/Library/Application Support/ManaLoom/e2e/play-vs-ai/20260825T193821Z_67071_13837/report.json`.
- Escopo: PostgreSQL novo e descartável em loopback, API local, dois processos
  sidecar distintos e XMage pinado; nenhuma coordenada de produção.
- UI: build Flutter Web release real em `1440x900`, autenticada contra a mesma
  API loopback e revisada em nove checkpoints.
- Estado de produto preservado: `release_ready=false`,
  `strategy_superiority_proven=false`, capabilities commitadas `OFF`.

## Identidade da prova

- Git HEAD observado pelo runner:
  `406d7dd533f0ff0ae8294f8b9de94fecc07bf24e`.
- Worktree status SHA-256:
  `b6920381ca59e71d83abf107286dc11b1cc9a1a1d577147d45ac5293d217e607`.
- UI source digest:
  `a81e8c2a6aed97aa57783786abc0df8cd15fe7348d8ba48659c95285734f2f17`.
- Bundle Web SHA-256:
  `84e09d1fe44eb81bf0c31d894a9d67462dd067d409fcce11d989032fb9918570`.
- XMage upstream:
  `2c43ec8cdb5cd475d47e6b555a4077151f476a3b`.
- Patch XMage governado:
  `991948742f840cd88493a4ea8cb3f4ed192e4742`.
- Build identity:
  `xmage-sidecar-v2@2c43ec8cdb5cd475d47e6b555a4077151f476a3b+patch.991948742f840cd88493a4ea8cb3f4ed192e4742`.

Esta primeira emissão está ligada ao conteúdo exato pelo digest da UI, pelo
hash do worktree e pelo bundle, mas ainda não reivindica `same clean Git SHA`.
O fechamento deve repetir o runner depois do commit de implementação e anexar
essa identidade em uma atualização deste receipt.

## Casos de uso comprovados

| Caso | Evidência observada |
| --- | --- |
| Escolha de adversário e preflight | deck Commander de 100 cartas validado antes de iniciar |
| Privacidade | mão própria visível; mão adversária protegida |
| Mulligan | mulligan, seleção da carta ao fundo e keep persistidos |
| Ação card-first | Plains jogado pela opção legal associada à carta |
| Mana e conjuração | fonte virou, Isamaru entrou na pilha e no campo |
| Prioridade | prompts e passes reais exercitados sem delegação global |
| Combate | Isamaru declarado atacante; vida adversária caiu de 40 para 38 |
| Reconexão | reload reconstruiu o mesmo UUID e o mesmo estado persistido |
| Terminal | concessão produziu `user_conceded`, nunca vitória fabricada |
| Replay e rematch | replay canônico aberto e seletor de revanche reaberto |

O runner registrou 23 ações submetidas, 24 prompts abertos e 232 registros no
PostgreSQL descartável para a sessão exercitada. O replay confirmou identidade
do engine, execução canônica de regras, entrada/virada de Plains, cast/entrada
de Isamaru, declaração de atacante, mudança de vida e decisões de `mulligan`,
`target`, `main_action`, `mana` e `combat`.

## UI/runtime

- `PASS_AUTOMATED`: contratos e testes focais aplicáveis.
- `PASS_RUNTIME`:
  [capture-manifest.json](../../ui-live/current/play-vs-ai-web-real/capture-manifest.json).
- `PASS_VISUAL_REVIEWED`:
  [visual-review.json](../../ui-live/current/play-vs-ai-web-real/visual-review.json).
- Checkpoints: seletor, mão/mulligan, land drop, comandante, dano, reconexão,
  terminal, replay e revanche.
- Todas as nove capturas foram abertas, têm `1440x900`, assinatura PNG, hashes
  distintos e console Web com zero warning/error registrado.
- O review focal declara explicitamente
  `overall_ui_proof_claimed=false`, sem crédito para TalkBack humano ou teclado
  Web físico.

## Cleanup e tentativa negativa preservada

- Cleanup final: `success=true`, `forced_kill_used=false`, nenhum processo ou
  listener pertencente ao runtime permaneceu ativo.
- Uma execução anterior falhou honestamente no estágio
  `validate_browser_qa_real_session` porque `psql -c` recebeu a expressão
  literal `:'deck_a_id'`. O relatório negativo foi preservado em
  `~/Library/Application Support/ManaLoom/e2e/play-vs-ai/20260825T191905Z_46723_9297/`.
- As capturas dessa tentativa foram arquivadas dentro do mesmo diretório do
  relatório antes da recaptura. O runner foi corrigido para interpolar somente
  UUIDs previamente validados e recebeu um teste de regressão estrutural.

## Comando reproduzível

```bash
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_PLAY_VS_AI_BROWSER_QA=1 \
./scripts/manaloom_play_vs_ai_e2e.sh
```

As frases acima autorizam exclusivamente os dados descartáveis criados pela
rotina local. Não autorizam escrita live, deploy, migration, pin, deck ou regra.

## Veredito e próximos gates

`PASS` focal para a funcionalidade exercitada e para a prova visual Web real.
Continuam abertos: commit + repetição no SHA limpo, gate amplo da task `NOW`,
auditoria independente do diff, aggregate `ui-proof` global, Android físico,
teclado/TalkBack, topologia horizontal, capacidade, SLO/custo, kill switch,
rollback e decisão de coorte.

# Audit Report — 2026-05-31 (Incremento)

> Auditoria incremental: 2 commits desde 21768cca ate 84553ef8.
> Atualizado em: 2026-05-31T03:00Z.
> Validacao: dart analyze optimization_quality_gate.dart — No issues found.

## Resumo Executivo

2 commits incrementais que completam o ciclo F1/F3 iniciado em 2026-05-30:

1. **weakness-analysis agora usa adapter F1** — ~80 linhas de heuristicas oracle_text removidas
2. **Wincon adicionado a _criticalRolesForArchetype** — Quality gate protege win conditions em TODOS os arquetipos
3. **manual-de-instrucao atualizado** — Write-only tables documentadas como audit logs

## Mudancas Detalhadas

### 6fa76bac — Refactor weakness-analysis + Wincon Detection (P1)

| Aspecto | Antes | Depois |
|---------|-------|--------|
| weakness-analysis counting | ~80 linhas oracle_text ad-hoc | resolveCardFunctionalRoles() (F1 adapter) |
| Wincon detection | oracle_text pattern matching | roles.contains('wincon') \|\| roles.contains('combo_piece') |
| _criticalRolesForArchetype | Sem 'wincon' | 'wincon' adicionado a aggro/control/midrange/default |
| Lines changed | — | +34/-101 |

Impacto: weakness-analysis agora usa a mesma pipeline de classificacao que optimize/validator. Elimina drift entre modulos. Wincon detection integrado ao quality gate previne swaps que removem cartas de fechamento.

Risco residual: As recommendacoes hardcoded do weakness-analysis nao foram removidas — sao exemplos estaticos que nao afetam a logica.

### 84553ef8 — Documentacao write-only tables + Manual update (P2/P3)

- deck_matchups, deck_weakness_reports, ml_prompt_feedback documentados como audit logs
- Politica de retencao recomendada: DELETE > 90 dias
- manual-de-instrucao.md secao 2026-05-30 adicionada com status F1/F3/bracket

## Riscos Conhecidos (Atualizados)

| ID | Risco | Status | Prioridade |
|----|-------|--------|------------|
| NR.1 | BracketCategory.gameChanger removido sem deprecacao | ATIVO — Verificar referencias residuais | P2 |
| NR.2 | Migration F2 sem framework de controle | MITIGADO — Documentado em manual | P2 → P3 |
| NR.3 | Remocao write-only tables pode afetar analise historica | ATIVO — Backup antes de aplicar | P3 |
| NR.4 | weakness-analysis com heuristicas locais | RESOLVIDO — Agora usa F1 adapter | — |

## Commit Hygiene
Ambos os commits tem mensagens descritivas com tipo prefixado. Nenhum commit viola regras de segredo.

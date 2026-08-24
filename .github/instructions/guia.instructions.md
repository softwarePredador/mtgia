---
applyTo: '**'
---

# Roteador de instruções ManaLoom/BrewTact

Policy: `MANALOOM_AGENT_POLICY_V1`.

Antes de qualquer ação, leia `AGENTS.md` e `.github/AGENT_POLICY.md`. Em seguida,
use esta ordem:

1. `docs/status/CURRENT_PRODUCT_DECISION.md` — decisão e escopo de release;
2. `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` — IDs, prioridade,
   dependências e aceite;
3. `docs/execution/CURRENT_QUEUE.md` — coordenação WIP 1;
4. `docs/generated/CURRENT_SYSTEM.md` — estrutura gerada;
5. contrato específico da área e `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.

Este arquivo é somente um roteador. Ele não autoriza mutação live, commit,
push, deploy, mudança de capability, migration, pin, regra, deck ou dado.
Material histórico permanece consultável, mas não orienta execução corrente.

# ManaLoom project logic generator

Extrator determinístico que usa `package:analyzer` para indexar a estrutura Dart e
combina o resultado com rotas, migrations, SQL, dependências, scripts, testes e o
contrato humano em `docs/project_logic_contracts.json`.

```bash
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
./scripts/quality_gate.sh project-logic
```

O primeiro comando atualiza o manifesto e os documentos derivados. O segundo
falha quando qualquer artefato está ausente ou diferente. O gate também executa
os testes do gerador e `dart doc --dry-run` sem tolerar warnings.

O gerador descreve estrutura; decisões e intenção continuam nos ADRs. Não capture
valores de ambiente, credenciais ou DSNs no manifesto.

Entradas humanas ativas também participam do digest: `AGENTS.md`, README raiz,
`docs/README.md`, documentos correntes declarados pelo lifecycle e todas as
instruções/perfis `.github`. Perfis de agente precisam herdar
`MANALOOM_AGENT_POLICY_V1`, permanecer user-invoked e não podem reintroduzir
autoridade histórica, ferramentas de subagente ou mutação GitHub implícita.
Documentos classificados como `historical_evidence` continuam versionados, mas
não entram no digest de fontes ativas.

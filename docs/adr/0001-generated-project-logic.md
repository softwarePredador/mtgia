# ADR 0001 — Manifesto gerado da lógica do projeto

- Estado: aceito
- Data: 2026-07-21
- Responsáveis: ManaLoom engineering

## Contexto

Relatórios manuais envelheceram em ritmos diferentes do código, das rotas e das
migrations. Nenhum extrator consegue deduzir com fidelidade total a intenção de
produto, mas a estrutura executável pode e deve ser inventariada de forma
determinística e revisável.

## Decisão

`project_logic_manifest.json` é o índice estrutural gerado do código Dart,
inventário de UI, rotas Dart Frog, migrations/SQL, dependências, scripts, gates,
testes (incluindo `app/integration_test`) e declarações humanas em
`docs/project_logic_contracts.json`. `package:analyzer` resolve os contextos
reais de app/server e registra cobertura, referências de tipo e arestas de
chamada internas; isso é diferente de apenas parsear texto ou AST sintática.

Documentos em `docs/generated/` são derivados e não podem ser editados
manualmente. O projeto não usa GitHub Actions: hooks versionados executam gates
no hardware local do desenvolvedor. `pre-commit` verifica MCP, segredos,
manifesto e testes do gerador; `pre-push` executa o gate local completo.
Dart/Flutter MCP confirma símbolos, erros e runtime vivo; `dart doc` valida APIs
documentáveis. O gate `tbls` inicializa um PostgreSQL loopback descartável,
aplica DDL e migrations, gera Mermaid e compara o schema aplicado com o
manifesto antes de apagar o cluster. Nenhuma dessas ferramentas substitui E2E.

PostgreSQL/backend permanece fonte de verdade do produto. Hermes/SQLite é
cache/laboratório. XMage pinado é a primeira referência comportamental de cartas;
Forge pinado cobre gaps estruturados; promoção para regra nativa exige evidência.

## Alternativas rejeitadas

- Documentação apenas manual: não bloqueia divergência estrutural.
- Wiki gerada apenas por IA: não é determinística nem prova o runtime.
- Apenas OpenAPI: não cobre UI, banco, jobs, regras ou rastreabilidade.
- Apenas introspecção MCP: depende de sessão viva e não produz artefato canônico.
- GitHub Actions hospedado: adiciona custo recorrente e duplica uma validação
  que pode ser executada deterministicamente no ambiente local controlado.

## Consequências

- Mudanças relevantes exigem `./scripts/manaloom_project_logic.sh --write` e
  revisão do diff.
- Cada checkout deve executar `./scripts/manaloom_install_local_hooks.sh
  --install`; sem hooks ativos, o gate local falha fechado.
- O gate verde prova sincronização e consistência estrutural, não conclusão do
  produto, segurança absoluta, equivalência de engines ou autorização de deploy.
- Intenção, exceções e riscos continuam manuais em ADRs e contratos canônicos.
- O OpenAPI permanece estrutural até que handlers possuam DTOs tipados completos.

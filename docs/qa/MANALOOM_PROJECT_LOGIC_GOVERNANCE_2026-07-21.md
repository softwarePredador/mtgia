# ManaLoom — governança gerada da lógica do projeto

Data da revalidação: 2026-07-22
Branch observada: `codex/free-beta-release-candidate-2026-07-17`
HEAD observado: `2813152121c4`
Estado: **implementado e validado em infraestrutura local gratuita**

## Resultado

O projeto passou a ter uma fonte estrutural única,
`project_logic_manifest.json`, gerada deterministicamente a partir do código,
rotas, migrations, contratos, scripts e testes. Os documentos Markdown,
diagramas Mermaid, mapa estrutural de API e ERD são derivados; o modo `--check`
falha quando qualquer um dos oito artefatos diverge.

Não há workflow hospedado em GitHub Actions. O controle equivalente roda no Mac
do projeto por comandos versionados e hooks Git locais:

- `pre-commit` executa `./scripts/manaloom_local_ci.sh quick`;
- `pre-push` executa `./scripts/manaloom_local_ci.sh full`;
- `schema` cria PostgreSQL descartável, aplica o bootstrap e todas as migrations,
  executa `tbls` e compara o banco vivo ao manifesto;
- `e2e` e `release` ampliam o gate somente quando a operação correspondente for
  deliberadamente solicitada.

O inventário desta execução encontrou:

- 571 arquivos Dart, 49 fontes de produto não Dart e 3.745 símbolos;
- 136 módulos, 38 rotas Flutter, 14 rotas da Web pública e 99 rotas de API;
- 69 tabelas, 6 views, 67 chaves estrangeiras e 50 migrations;
- 633 scripts/jobs, 596 nomes de variáveis e 1.053 arquivos de teste;
- 8 fluxos ponta a ponta e 10 regras rastreáveis;
- 423 pacotes Node resolvidos pelo lockfile da Web pública;
- zero métodos de rota não resolvidos no mapa estrutural de API.

Variáveis são inventariadas somente por nome, classificação e arquivo de
origem; valores não são capturados. PostgreSQL/backend permanece a fonte de
verdade do produto. Hermes/SQLite permanece cache, laboratório e evidência.

## Análise semântica Dart

O gerador usa `package:analyzer` com contextos resolvidos, não apenas regex ou
AST sintática:

- cobertura: `complete`, 571/571 arquivos resolvidos;
- arquivos não resolvidos: 0;
- arquivos com diagnóstico de erro: 0;
- diagnósticos informativos: 5;
- 50.979 call sites e 31.769 arestas resolvidas;
- 8.249 arestas entre símbolos do próprio workspace;
- 12.455 referências de tipo, 2.136 delas internas ao workspace.

`app/integration_test` participa tanto do inventário quanto do digest. Fontes
operacionais Web, Flutter Web, Android, iOS, Docker e scripts também entram no
controle de drift.

## Componentes implantados

- Gerador/analisador: `tools/project_logic/`.
- Declarações humanas: `docs/project_logic_contracts.json`.
- Manifesto: `project_logic_manifest.json`.
- Derivados: `docs/generated/`.
- Gate de drift: `./scripts/quality_gate.sh project-logic`.
- Gates gratuitos: `scripts/manaloom_local_ci.sh` e comandos `local:*` do Melos.
- Hooks: `.githooks/` e `scripts/manaloom_install_local_hooks.sh`.
- Documentação Dart: `scripts/manaloom_dart_doc.sh`.
- Preflight MCP: `scripts/manaloom_dart_mcp_preflight.sh`.
- Banco/ERD: `.tbls.yml` e `scripts/manaloom_tbls_local_gate.sh`.
- Decisão arquitetural: `docs/adr/0001-generated-project-logic.md`.
- Contrato de agentes: `AGENTS.md`.

## Provas frescas

| Prova | Resultado |
|---|---|
| `./scripts/manaloom_local_ci.sh full` | PASS; nenhum runner hospedado |
| `dart analyze` no gerador | PASS, zero issues |
| testes do gerador | PASS, 14/14 |
| cobertura semântica | PASS, 571/571; zero erro/não resolvido |
| drift dos oito artefatos | PASS, fail-closed |
| documentação Dart | PASS, zero warning/erro |
| backend completo | PASS |
| Flutter completo | PASS, 1.113 + 1 skip Web-only declarado |
| Web pública | lint, build, smoke e audit PASS; zero vulnerabilidade |
| auditoria de UI | PASS, 48/48 |
| custom lint | PASS no app, backend e pacote |
| Patrol local | PASS, 9/9 |
| auditoria de dependências | PASS nos quatro pacotes |
| contratos operacionais de release | PASS, 25 contratos |
| secret scan local | PASS; zero credencial literal detectada |
| PostgreSQL/tbls descartável | PASS: 69 tabelas, 6 views, 67 FKs, 50 migrations |
| cleanup | PASS; nenhum banco/processo/listener temporário permaneceu |

O harness Patrol foi executado localmente. O CLI com device físico continua uma
prova separada e só roda quando `MANALOOM_RUN_PATROL_DEVICE_TESTS=1` for
explicitamente definido.

## Integridade

- Digest das fontes no manifesto:
  `020f7508bf3d01cf78d78f3ded3612f1c6a4825901d15c265da92563ec927ef1`.
- SHA-256 do manifesto:
  `facbeaa516193b4ca78469ac27cf1a451ae1084d57774b9780fc218e3e07dc62`.
- Contrato estrutural gerado, digest SHA-256:
  `1a74b08b71171402e4a7e4c4f31297b23671a9077d0f8fd3fe0fb6e144cede1c`.

Nenhuma conexão ao PostgreSQL de produção, escrita remota, deploy, commit ou
push foi executado. O PostgreSQL usado pelo `tbls` teve porta aleatória, diretório
temporário, migrations locais e remoção automática. A Web preexistente em
`127.0.0.1:8088` e o PostgreSQL preexistente em `127.0.0.1:5432` foram
preservados.

## Limites e uso correto

Gate verde prova sincronismo estrutural e regressão local do escopo exercitado.
Não prova, sozinho, conclusão de todas as regras de Magic, equivalência total
XMage/Forge, acessibilidade humana em aparelho físico ou prontidão final de
Store. Battle, Deckbuilder, social, resiliência e homologação final continuam
nas Sprints 5–10 e exigem suas próprias evidências.

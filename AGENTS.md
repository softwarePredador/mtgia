# ManaLoom agent contract

Antes de analisar ou editar:

1. Leia `project_logic_manifest.json` e `docs/generated/CURRENT_SYSTEM.md`;
   consulte `semantic_analysis` para tipos/chamadas resolvidos e `lineage` para
   saber exatamente quais fontes participam do digest.
2. Leia o contrato específico da área e `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.
3. Confirme código/runtime com Dart/Flutter MCP quando houver app em execução.
4. Trate PostgreSQL/backend como verdade; Hermes/SQLite é cache/laboratório.

Não edite `project_logic_manifest.json` nem `docs/generated/*` manualmente.
Depois de alterar código, rota, migration, script, gate ou contrato, rode:

```bash
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
```

Este projeto não usa GitHub Actions. Ative os gates gratuitos do checkout uma
vez com `./scripts/manaloom_install_local_hooks.sh --install`. O `pre-commit`
executa `./scripts/manaloom_local_ci.sh quick`; o `pre-push` executa
`./scripts/manaloom_local_ci.sh full`. Para schema, E2E e release use,
respectivamente, os modos `schema`, `e2e` e `release`.

O gate de schema cria um PostgreSQL exclusivamente loopback em `/tmp`, aplica o
DDL/migrations, roda `tbls`/Mermaid, compara tabelas, views, colunas e FKs com o
manifesto e remove o cluster ao terminar. Ele nunca aponta para o banco live.

Decisões, motivos, exceções e riscos ficam em ADRs/contratos manuais. Um gate de
drift verde prova sincronização documental, não conclusão E2E nem autorização
para escrita live, migration, deploy ou promoção de deck/regra.

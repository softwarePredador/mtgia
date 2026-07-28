# Auditoria semanal de deltas XMage e Forge

Status: `current_local_read_only_schedule`.

Esta rotina acompanha os repositórios oficiais de XMage e Forge sem atualizar
automaticamente o runtime. Ela executa a auditoria canônica
`scripts/manaloom_external_engine_delta_audit.sh`, compara os pins versionados
com os branches oficiais e produz uma fila de revisão de cartas, regras,
fixtures e alterações de engine.

## Limites de segurança

- A rotina nunca altera `XMAGE_COMMIT`, `FORGE_COMMIT` ou seus mirrors.
- Ela não compila, reinicia ou implanta sidecars.
- Ela não escreve em PostgreSQL, Hermes ou SQLite e não promove regras/decks.
- Um checkout com alterações tracked ou arquivos untracked gera
  `status=skipped` e
  `reason=dirty_worktree`; nenhuma consulta de upstream é feita.
- Os relatórios usam uma superfície exclusiva fora do checkout:
  `~/Library/Application Support/ManaLoom/external-engine-delta`.
- `latest.json` é uma cópia do resultado mais recente. Relatórios
  `external-engine-delta-<UTC>-<pid>.json` têm retenção de 180 dias.
- A retenção só remove arquivos timestampados pertencentes a essa rotina; logs
  e arquivos com outro nome são preservados.

O resultado `review_required` é o comportamento esperado quando o upstream
avança. Ele não autoriza avanço de pin. `fail` significa que a comparação ficou
desconhecida ou um contrato local divergiu; `skipped` nunca deve ser comunicado
como `PASS`. O modo `--check` também falha quando não existe relatório, quando
o resultado mais recente é `fail`/`skipped` ou quando `latest.json` tem mais de
oito dias.

## Operação no macOS

O projeto não usa GitHub Actions. O agendamento é um LaunchAgent local,
domingo às 09:17 no fuso do Mac, e dispara uma primeira execução na instalação:

```bash
./scripts/manaloom_install_external_engine_delta_schedule.sh --install
./scripts/manaloom_install_external_engine_delta_schedule.sh --check
./scripts/manaloom_install_external_engine_delta_schedule.sh --run-now
```

Para remover apenas o agendamento e preservar todo o histórico:

```bash
./scripts/manaloom_install_external_engine_delta_schedule.sh --uninstall
```

`--uninstall` desabilita o label para impedir uma execução residual.
`--install` sempre executa `launchctl enable` antes de carregar o plist, por
isso uma reinstalação reverte com segurança esse estado persistente.

Também é possível executar sem rede para validar apenas pins e mirrors:

```bash
./scripts/manaloom_external_engine_delta_weekly.sh --local-only
```

O LaunchAgent é
`~/Library/LaunchAgents/com.manaloom.external-engine-delta-weekly.plist`.
Saída e erro do agendador ficam em `scheduler.stdout.log` e
`scheduler.stderr.log` no mesmo diretório exclusivo dos relatórios.

## Critério para atualizar um pin

O relatório serve somente como entrada de revisão. Uma atualização controlada
continua exigindo, no mínimo:

1. leitura dos commits/arquivos classificados e dos fixtures candidatos;
2. avanço explícito e consistente de todos os mirrors do pin;
3. build reproduzível dos sidecars;
4. testes focados das regras alteradas e gates de Battle/capacidades;
5. replay, persistência e identidade de runtime coerentes;
6. commit e implantação separados, sem promoção automática de regra.

## Validação do contrato

```bash
bash -n \
  scripts/manaloom_external_engine_delta_weekly.sh \
  scripts/manaloom_install_external_engine_delta_schedule.sh
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_engine_delta_schedule_contract.py
./scripts/quality_gate.sh engine-capabilities
```

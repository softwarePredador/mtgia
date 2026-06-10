# Hermes UI Audit Cron — 2026-06-04

## Status

PASS_WITH_RISKS.

O Hermes agora tem um auditor UI estatico versionado e sincronizado para o
container AWS. A cron serve como radar automatico de padronizacao/acessibilidade,
nao como prova visual viva.

## Mudancas

- Versionado `server/bin/flutter_ui_static_auditor.py`.
- Versionado `server/bin/flutter_ui_static_auditor.sh`.
- Endurecido `server/bin/ui_audit_pipeline.py`:
  - paths configuraveis por env;
  - escrita de relatorio controlada pelo script;
  - parse obrigatorio de `UI_AUDIT_BATCH_RESULT`;
  - estado so avanca quando o batch e valido.
- `server/bin/ui_audit_pipeline.sh` agora resolve o script relativo ao proprio
  diretorio antes de cair no caminho Hermes `/opt/data/scripts`.
- Cron remota `manaloom-flutter-ui-auditor` ajustada para `every 180m`.
- Ownership remoto corrigido para `hermes:hermes` em:
  - `/opt/data/scripts/flutter_ui_static_auditor.py`;
  - `/opt/data/scripts/flutter_ui_static_auditor.sh`;
  - `/opt/data/scripts/ui_audit_pipeline.py`;
  - `/opt/data/scripts/ui_audit_pipeline.sh`;
  - `/opt/data/workspace/mtgia/docs/hermes-analysis`.

## Resultado local apos correcoes app

Com `UI_STATIC_REPORT_FILE=/tmp/manaloom_flutter_ui_static_audit_after_reclass.md`:

```text
UI_AUDIT_RESULT: findings=215 P0=0 P1=0 P2=215
```

Os P1 objetivos de `icon_button_missing_tooltip` foram zerados localmente com
tooltips em acoes claras de voltar, limpar busca, enviar mensagem, abrir menu e
incrementar/decrementar valores.

## Resultado remoto antes do novo commit estar no master

No Hermes, antes do commit/push das correcoes app, o auditor ainda reportava:

```text
UI_AUDIT_RESULT: findings=239 P0=0 P1=24 P2=215
```

Motivo: a cron audita `/opt/data/workspace/mtgia-sync`, que seguia em
`origin/master` sem os tooltips locais. A expectativa apos push/sync e o mesmo
radar cair para `P1=0`.

## Regras operacionais

- A cron UI nao substitui prova viva no iPhone Simulator.
- Achados P2 de cor/touch target devem ser triados por screenshot antes de virar
  tarefa P1.
- `ui_audit_pipeline.py` deve ser usado como auditoria LLM incremental
  controlada, nao como gate automatico de release.
- Relatorios gerados pelo Hermes pertencem a `docs/hermes-analysis` na branch de
  memoria `codex/hermes-analysis-docs`.

## Validacoes

- `python3 -m py_compile server/bin/ui_audit_pipeline.py server/bin/flutter_ui_static_auditor.py`.
- Auditor local com report temporario.
- Sync manual dos scripts no Hermes.
- Execucao manual remota de `/opt/data/scripts/flutter_ui_static_auditor.sh`.

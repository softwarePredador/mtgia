#!/usr/bin/env bash
set -euo pipefail

# Outbox da exclusão de conta (BT-PRIV-002, decisão D-68 do dono).
#
# Roda na imagem de ops (server/Dockerfile.manaloom-ops), agendado pelo
# manaloom_ops_daemon.py como `manaloom_account_deletion_outbox`, sem
# capability. Consome as linhas que a exclusão grava em
# account_deletion_outbox. Cria a linha que falta para todo recibo de exclusão
# e conclui os consumidores que já sabe concluir: endpoint_cache pelo teto de
# 24 h, o sidecar pelo tempo máximo da sessão (D-77) e sentry porque os
# eventos do servidor não levam o usuário. O hermes_learning_sqlite conclui
# depois de apagar os decks apagados do knowledge.db (HERMES_KNOWLEDGE_DB, via
# bin/hermes_learning_purge.py, BT-PRIV-002). Marca os bloqueados (backups)
# com o motivo e deixa um recibo por execução, sem identificador.
#
# O recibo vai para MANALOOM_ACCOUNT_DELETION_OUTBOX_OUTPUT_DIR (o daemon aponta
# para o diretório de artefatos) ou para --output-dir <dir>.
#
# Uso:
#   ./server/bin/cron_account_deletion_outbox.sh
#   ./server/bin/cron_account_deletion_outbox.sh --output-dir <dir>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

exec dart run bin/account_deletion_outbox_worker.dart "$@"

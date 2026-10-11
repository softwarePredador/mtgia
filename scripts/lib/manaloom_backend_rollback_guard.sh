#!/usr/bin/env bash

# Guarda do rollback automático do backend (revisão da promoção, item 2; D-104 e
# item 12 do pacote de decisões de 2026-10-10: depois da 059, rollback é restore).
#
# O readiness do backend (`server/lib/health_readiness_support.dart`) exige que o
# MAX(version) de `schema_migrations` seja exatamente a última migration que a
# imagem conhece (`... = 'NNN' AS latest_migration_ready` e
# `'latest_migration': 'NNN'`); com qualquer outra, `/health/ready` responde 503.
# Depois das migrations do lote, voltar o backend para a imagem anterior (pelo
# `--update-failure-action rollback` do Swarm ou pelo trap do deploy) deixaria a
# API em 503. Então a volta automática só vale quando a imagem anterior exige a
# mesma migration em que o banco está; em qualquer outro caso, inclusive quando não
# dá para saber o que ela exige, o Swarm pausa e o trap recusa a volta e imprime o
# caminho de restore.

# A migration que o readiness da imagem do commit <sha> exige como a última do
# banco, lida de server/lib/health_readiness_support.dart naquele commit. As duas
# formas do arquivo têm de concordar. Falha (código 1, sem saída) se o SHA não é
# um SHA completo, se o commit não está no repositório ou se o arquivo não diz.
manaloom_readiness_required_migration() {
  local repo_root="$1"
  local sha="$2"
  local readiness_source in_sql declared

  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || return 1
  readiness_source="$(git -C "$repo_root" show "$sha:server/lib/health_readiness_support.dart" \
    2>/dev/null)" || return 1
  in_sql="$(printf '%s\n' "$readiness_source" |
    sed -n -E "s/.*=[[:space:]]*'([0-9]{3})'[[:space:]]+AS[[:space:]]+latest_migration_ready.*/\1/p" |
    LC_ALL=C sort -u)"
  declared="$(printf '%s\n' "$readiness_source" |
    sed -n -E "s/.*'latest_migration'[[:space:]]*:[[:space:]]*'([0-9]{3})'.*/\1/p" |
    LC_ALL=C sort -u)"
  if [[ ! "$in_sql" =~ ^[0-9]{3}$ || "$in_sql" != "$declared" ]]; then
    return 1
  fi
  printf '%s\n' "$in_sql"
}

# `rollback` quando a imagem anterior exige exatamente a migration em que o banco
# está; `restore` em qualquer outro caso (diferente, ilegível ou vazio).
manaloom_backend_rollback_policy() {
  local previous_required="$1"
  local database_latest="$2"

  if [[ "$previous_required" =~ ^[0-9]{3}$ &&
        "$database_latest" =~ ^[0-9]{3}$ &&
        "$previous_required" == "$database_latest" ]]; then
    echo rollback
  else
    echo restore
  fi
}

# A ação do Swarm para uma falha do update, pela política acima.
manaloom_swarm_update_failure_action() {
  case "$1" in
    rollback) echo rollback ;;
    *) echo pause ;;
  esac
}

# O caminho de restore, para o operador, quando a volta automática é recusada.
manaloom_backend_restore_path() {
  local previous_required="${1:-}"
  local database_latest="${2:-}"

  cat >&2 <<MESSAGE
CRITICAL: rollback automatico do backend recusado (D-104, item 12: depois da 059, rollback e restore).
  a imagem anterior exige a migration ${previous_required:-desconhecida}; o banco esta na ${database_latest:-desconhecida}.
  voltar o backend para ela deixaria /health/ready em 503. O servico fica como esta (o Swarm pausa o update).
  caminho de restore: docs/runbooks/BACKUP_E_RESTAURACAO.md, "Restauracao da producao (RTO de 4 h)",
  com o dump do passo 1 do lote (o backup tirado antes da primeira migration), so com a palavra do dono;
  ou corrigir para frente: um deploy novo de uma imagem que exige a migration ${database_latest:-do banco}.
MESSAGE
}

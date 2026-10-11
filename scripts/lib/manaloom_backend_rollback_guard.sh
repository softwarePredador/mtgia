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

# O caminho de restore, para o operador, quando a volta automática é recusada, com a
# verdade sobre o estado em que o deploy deixou o Swarm:
#   $1 a migration que a imagem anterior exige; $2 a do banco;
#   $3 1 se o update do Swarm convergiu (a imagem nova rodando, 1/1, completed) antes
#      da falha, 0 se não convergiu (com --update-failure-action pause, o Swarm para em
#      paused, ou segue em updating), vazio se não se sabe;
#   $4 1 se o deploy já trocou a origem no EasyPanel para a imagem nova;
#   $5 o serviço do Swarm; $6 a imagem anterior (repo@sha256).
# O deploy seguinte só aceita o serviço com 1/1, spec igual à tarefa e update vazio,
# completed ou rollback_completed (scripts/manaloom_deploy_backend_image.sh, baseline
# rollback-safe); paused e updating são recusados.
manaloom_backend_restore_path() {
  local previous_required="${1:-}"
  local database_latest="${2:-}"
  local converged="${3:-}"
  local source_mutated="${4:-0}"
  local service="${5:-<servico>}"
  local previous_image="${6:-a imagem anterior}"
  local state_line

  case "$converged" in
    1) state_line="estado do Swarm: o update terminou (completed) e a imagem nova esta rodando; o que falhou foi uma conferencia depois dele. O Swarm nao pausou nada, e o servico assim (1/1, completed) e aceito pelo proximo deploy." ;;
    0) state_line="estado do Swarm: o update nao convergiu. Com --update-failure-action pause o Swarm para o update em paused (ou ele segue em updating); a replica pode nao estar pronta. O proximo deploy recusa esse servico ate ele voltar a 1/1, spec igual a tarefa e update completed ou rollback_completed." ;;
    *) state_line="estado do Swarm: desconhecido nesta saida; confira antes de agir. O proximo deploy so aceita o servico com 1/1, spec igual a tarefa e update vazio, completed ou rollback_completed (paused e updating sao recusados)." ;;
  esac

  cat >&2 <<MESSAGE
CRITICAL: rollback automatico do backend recusado (D-104, item 12: depois da 059, rollback e restore).
  a imagem anterior exige a migration ${previous_required:-desconhecida}; o banco esta na ${database_latest:-desconhecida}.
  voltar o backend para ela deixaria /health/ready em 503; esta saida nao mandou nada ao Swarm nem ao EasyPanel.
  ${state_line}
  confira: docker service inspect '${service}' --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' e docker service ls --filter name='${service}'.
MESSAGE
  if [[ "$source_mutated" == "1" ]]; then
    echo "  a origem no EasyPanel ja aponta para a imagem nova; um redeploy pelo painel sobe a imagem nova de novo." >&2
  fi
  cat >&2 <<MESSAGE
  saidas, todas com a palavra do dono (escrita na producao), em docs/runbooks/BACKUP_E_RESTAURACAO.md:
  - corrigir para frente, sem restore ("Deploy do backend que falhou depois do lote"): com o update em paused ou updating, tire o servico desse estado antes do deploy de correcao.
    docker service update --force '${service}' refaz o update da mesma imagem (serve se a falha foi passageira);
    se ela nao sobe, docker service rollback '${service}' volta a spec para ${previous_image}: o servico pode voltar a 1/1 (o healthcheck do container e o /health/live, que nao olha o banco), mas /health/ready segue 503, porque ela exige a ${previous_required:-migration anterior}.
    com o servico em 1/1 e completed ou rollback_completed, rode o deploy de uma imagem que exige a migration ${database_latest:-do banco}.
  - restore ("Restauracao da producao (RTO de 4 h)"): o dump do passo 1 do lote (o backup tirado antes da primeira migration); so depois do banco restaurado, o passo 7 volta o backend para ${previous_image}.
MESSAGE
}

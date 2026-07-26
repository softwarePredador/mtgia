#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
SIDECAR_DIR="$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)"
XMAGE_VERSION="1.4.60"
XMAGE_COMMIT="$(tr -d '[:space:]' < "$SIDECAR_DIR/XMAGE_COMMIT")"
MAVEN_REPO_LOCAL="${MAVEN_REPO_LOCAL:-${HOME:?HOME is required}/.m2/repository}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 2
  }
}

require_file() {
  [[ -s "$1" ]] || {
    echo "Required pinned XMage artifact not found: $1" >&2
    exit 2
  }
}

require_text() {
  local file_path="$1"
  local expected="$2"
  grep -Fq "$expected" "$file_path" || {
    echo "Pinned XMage API evidence missing: $expected" >&2
    exit 1
  }
}

require_command java
require_command javap
require_command mvn
require_command grep

"$SCRIPT_DIR/bootstrap_pinned_xmage_maven.sh"

COMMON_JAR="$MAVEN_REPO_LOCAL/org/mage/mage-common/$XMAGE_VERSION/mage-common-$XMAGE_VERSION.jar"
SERVER_JAR="$MAVEN_REPO_LOCAL/org/mage/mage-server/$XMAGE_VERSION/mage-server-$XMAGE_VERSION.jar"
HUMAN_JAR="$MAVEN_REPO_LOCAL/org/mage/mage-player-human/$XMAGE_VERSION/mage-player-human-$XMAGE_VERSION.jar"
CORE_JAR="$MAVEN_REPO_LOCAL/org/mage/mage/$XMAGE_VERSION/mage-$XMAGE_VERSION.jar"
PIN_MARKER="$MAVEN_REPO_LOCAL/.manaloom-xmage-pin"

require_file "$COMMON_JAR"
require_file "$SERVER_JAR"
require_file "$HUMAN_JAR"
require_file "$CORE_JAR"
require_file "$PIN_MARKER"
require_text "$PIN_MARKER" "$XMAGE_COMMIT xmage=$XMAGE_VERSION"

AUDIT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-human-xmage-spike.XXXXXX")"
cleanup() {
  find "$AUDIT_DIR" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

CLASSPATH="$COMMON_JAR:$SERVER_JAR:$HUMAN_JAR:$CORE_JAR"
javap -classpath "$CLASSPATH" -public mage.players.PlayerType \
  >"$AUDIT_DIR/player_type.txt"
javap -classpath "$CLASSPATH" -public mage.remote.SessionImpl \
  >"$AUDIT_DIR/session.txt"
javap -classpath "$CLASSPATH" -public mage.interfaces.callback.ClientCallbackMethod \
  >"$AUDIT_DIR/callbacks.txt"
javap -classpath "$CLASSPATH" -public mage.interfaces.callback.ClientCallback \
  >"$AUDIT_DIR/client_callback.txt"
javap -classpath "$CLASSPATH" -public mage.player.human.HumanPlayer \
  >"$AUDIT_DIR/human_player.txt"
javap -classpath "$CLASSPATH" -p mage.server.game.GameSessionPlayer \
  >"$AUDIT_DIR/game_session_player.txt"
javap -classpath "$CLASSPATH" -p mage.server.game.GameController \
  >"$AUDIT_DIR/game_controller.txt"

require_text "$AUDIT_DIR/player_type.txt" "mage.players.PlayerType HUMAN"
require_text "$AUDIT_DIR/player_type.txt" "mage.players.PlayerType COMPUTER_MAD"
require_text "$AUDIT_DIR/session.txt" "joinTable("
require_text "$AUDIT_DIR/session.txt" "sendPlayerUUID("
require_text "$AUDIT_DIR/session.txt" "sendPlayerBoolean("
require_text "$AUDIT_DIR/session.txt" "sendPlayerInteger("
require_text "$AUDIT_DIR/session.txt" "sendPlayerString("
require_text "$AUDIT_DIR/session.txt" "sendPlayerAction("
require_text "$AUDIT_DIR/human_player.txt" "chooseMulligan("
require_text "$AUDIT_DIR/human_player.txt" "priority("
require_text "$AUDIT_DIR/human_player.txt" "selectAttackers("
require_text "$AUDIT_DIR/human_player.txt" "selectBlockers("
require_text "$AUDIT_DIR/human_player.txt" "signalPlayerConcede("
require_text "$AUDIT_DIR/client_callback.txt" "getMessageId("
require_text "$AUDIT_DIR/client_callback.txt" "setMessageId("
require_text "$AUDIT_DIR/game_controller.txt" "private boolean useResponseIdleTimeout"
require_text "$AUDIT_DIR/game_controller.txt" "public void onResponseIdleTimeout("
require_text "$AUDIT_DIR/game_controller.txt" "public void sendPlayerAction("

for callback_name in \
  GAME_ASK \
  GAME_SELECT \
  GAME_TARGET \
  GAME_CHOOSE_ABILITY \
  GAME_CHOOSE_PILE \
  GAME_CHOOSE_CHOICE \
  GAME_PLAY_MANA \
  GAME_PLAY_XMANA \
  GAME_GET_AMOUNT \
  GAME_GET_MULTI_AMOUNT; do
  require_text "$AUDIT_DIR/callbacks.txt" "$callback_name"
done

if grep -Eiq \
  ' (delegate|replacePlayer|convertPlayer|changePlayerType)[A-Za-z0-9_]*\(' \
  "$AUDIT_DIR/session.txt"; then
  echo "Unexpected remote human-to-AI transition API found; review required" >&2
  exit 1
fi

(
  cd "$SIDECAR_DIR"
  mvn -B -Dstyle.color=never -Dtest=HumanVsAiSpikeTest test
)

echo "BL7_SPIKE_SCOPE=isolated_test_and_pinned_bytecode"
echo "BL7_SEATS=deck_a:HUMAN,deck_b:COMPUTER_MAD"
echo "BL7_CALLBACKS_ALLOWLISTED=GAME_ASK,game_mulligan_only;GAME_SELECT,main_or_combat;GAME_TARGET,target_or_combat"
echo "BL7_CALLBACKS_UNHANDLED=GAME_CHOOSE_ABILITY,GAME_CHOOSE_PILE,GAME_CHOOSE_CHOICE,GAME_PLAY_MANA,GAME_PLAY_XMANA,GAME_GET_AMOUNT,GAME_GET_MULTI_AMOUNT"
echo "BL7_STATE_CONTRACT=callback_message_id_plus_hmac_opaque_single_use_options"
echo "BL7_TIMEOUT_POLICY=concede_then_terminate_process"
echo "BL7_HUMAN_TO_AI_TRANSITION=unproven"
echo "BL7_RUNTIME_HUMAN_MATCH_COMPLETED=false"
echo "BL7_SPIKE_DECISION=NO_GO"

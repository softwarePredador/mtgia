#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ADB_BIN="${MANALOOM_ADB_BIN:-$(command -v adb || true)}"
DART_BIN="${MANALOOM_DART_BIN:-$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart}"
POLICY_FILE="$ROOT_DIR/app/test/ui/fixtures/ui_live_evidence_policy.json"

RUN_ID=""
SERIAL=""
PACKAGE=""
SOURCE_DIGEST=""
PROFILE=""
TARGET="android_physical"
RUNTIME_LOG=""
NATIVE_LOG=""
PID_TRACE=""
RECEIPT=""
API_PORT=""
WEB_PORT=""
CHILD=()

usage() {
  cat <<'EOF'
usage: manaloom_android_ui_egress_guard.sh run \
  --run-id <run-id> --serial <adb-serial> --package <application-id> \
  --source-digest <sha256> --profile <profile> \
  --runtime-log <absolute-log> --native-log <absolute-log> \
  --pid-trace <absolute-tsv> --receipt <absolute-json> \
  --api-port <port> --web-port <port> -- <governed-command> [args...]

The app must already be installed. The guard owns Android network state,
presentation settings, ADB reverse mappings, UID-scoped logging, PID sampling,
app-data hygiene and the terminal v2 receipt. An unprovable step is NO-GO.
EOF
}

fail() {
  printf 'NO_GO_ANDROID_NETWORK_ISOLATION_UNPROVABLE: %s\n' "$1" >&2
  exit 1
}

is_port() {
  [[ "$1" =~ ^[0-9]+$ ]] && ((10#$1 > 0 && 10#$1 < 65536))
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

adb_device() {
  "$ADB_BIN" -s "$SERIAL" "$@"
}

trim_cr() {
  tr -d '\r'
}

safe_remove_state_dir() {
  [[ -n "$STATE_DIR" && -d "$STATE_DIR" && ! -L "$STATE_DIR" ]] || return 0
  local resolved
  resolved="$(CDPATH='' cd -- "$STATE_DIR" && pwd -P)" || return 1
  [[ "$resolved" == "$RUN_ROOT_REAL"/.android-egress-state.* ]] || return 1
  find "$resolved" -depth -delete
  [[ ! -e "$resolved" && ! -L "$resolved" ]]
}

# Every handle exists before the first temporary, snapshot or device mutation.
STATE_DIR=""
JOURNAL=""
RUN_ROOT=""
RUN_ROOT_REAL=""
STATE_BEFORE=""
STATE_ISOLATED=""
STATE_AFTER=""
APP_UID=""
MODEL=""
API=""
WIFI_BEFORE=""
DATA_BEFORE=""
AIRPLANE_BEFORE=""
ACCEL_PRESENT="false"
ACCEL_VALUE="__MANALOOM_ABSENT__"
USER_ROTATION_PRESENT="false"
USER_ROTATION_VALUE="__MANALOOM_ABSENT__"
IMMERSIVE_PRESENT="false"
IMMERSIVE_VALUE="__MANALOOM_ABSENT__"
network_snapshot_complete=false
presentation_snapshot_complete=false
network_mutated=false
wifi_mutated=false
data_mutated=false
presentation_mutated=false
accelerometer_mutated=false
user_rotation_mutated=false
immersive_mutated=false
reverse_mutated=false
api_reverse_mutated=false
web_reverse_mutated=false
logcat_pid=""
sampler_pid=""
child_pid=""
cleanup_running=false
normal_completed=false
pre_launch_clean=false
post_run_clean=false
restore_exact=false
presentation_restore_exact=false
isolation_confirmed=false
usb_preserved=false
reverse_confirmed=false
begin_confirmed=false
end_confirmed=false
first_drain_confirmed=false
final_drain_confirmed=false
sampler_started=false
sampler_clean=false
logcat_started=false
logcat_clean=false
state_dir_absent=false
launcher_exit=1
LAST_SAMPLE_MATCHED=0

collect_descendants() {
  local parent="$1" child
  while IFS= read -r child; do
    [[ "$child" =~ ^[0-9]+$ ]] || continue
    collect_descendants "$child"
    printf '%s\n' "$child"
  done < <(pgrep -P "$parent" 2>/dev/null || true)
}

terminate_child_tree() {
  local root_pid="$1" remaining="" descendant descendants
  [[ "$root_pid" =~ ^[0-9]+$ ]] || return 0
  descendants="$(collect_descendants "$root_pid")"
  while IFS= read -r descendant; do
    [[ "$descendant" =~ ^[0-9]+$ ]] || continue
    kill -TERM "$descendant" >/dev/null 2>&1 || true
  done <<<"$descendants"
  kill -TERM "$root_pid" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    remaining="$(
      {
        kill -0 "$root_pid" >/dev/null 2>&1 && printf '%s\n' "$root_pid"
        collect_descendants "$root_pid"
      } | awk '/^[0-9]+$/' | sort -u
    )"
    [[ -z "$remaining" ]] && break
    sleep 0.1
  done
  while IFS= read -r descendant; do
    [[ "$descendant" =~ ^[0-9]+$ ]] || continue
    kill -KILL "$descendant" >/dev/null 2>&1 || true
  done <<<"$remaining"
  kill -KILL "$root_pid" >/dev/null 2>&1 || true
  wait "$root_pid" >/dev/null 2>&1 || true
  ! kill -0 "$root_pid" >/dev/null 2>&1 &&
    [[ -z "$(collect_descendants "$root_pid")" ]]
}

read_setting_snapshot() {
  local namespace="$1" key="$2" listing matches count
  listing="$(adb_device shell settings list "$namespace" | trim_cr)" || return 1
  matches="$(printf '%s\n' "$listing" | awk -v prefix="$key=" 'index($0,prefix)==1 {print}')"
  count="$(printf '%s\n' "$matches" | awk 'NF{count++} END{print count+0}')"
  [[ "$count" -le 1 ]] || return 1
  if [[ "$count" -eq 0 ]]; then
    printf 'false\t__MANALOOM_ABSENT__\n'
  else
    [[ "$matches" != *$'\n'* ]] || return 1
    printf 'true\t%s\n' "${matches#*=}"
  fi
}

restore_setting() {
  local namespace="$1" key="$2" present="$3" value="$4" observed
  if [[ "$present" == "true" ]]; then
    adb_device shell settings put "$namespace" "$key" "$value" >/dev/null || return 1
  else
    adb_device shell settings delete "$namespace" "$key" >/dev/null || return 1
  fi
  observed="$(read_setting_snapshot "$namespace" "$key")" || return 1
  [[ "$observed" == "$present"$'\t'"$value" ]]
}

write_device_state() {
  local output="$1" wifi="$2" data="$3" airplane="$4"
  local reverse_file="$5" routes4_file="$6" routes6_file="$7"
  local connectivity_file="$8" accel_present="$9"
  shift 9
  local accel_value="$1" user_present="$2" user_value="$3"
  local immersive_present="$4" immersive_value="$5"
  jq --null-input \
    --arg wifi "$wifi" --arg data "$data" --arg airplane "$airplane" \
    --arg reverse_sha256 "$(sha256_file "$reverse_file")" \
    --arg routes4_sha256 "$(sha256_file "$routes4_file")" \
    --arg routes6_sha256 "$(sha256_file "$routes6_file")" \
    --arg connectivity_sha256 "$(sha256_file "$connectivity_file")" \
    --argjson reverse_lines "$(jq -Rsc 'split("\n") | map(select(length > 0))' <"$reverse_file")" \
    --argjson routes4_lines "$(jq -Rsc 'split("\n") | map(select(length > 0))' <"$routes4_file")" \
    --argjson routes6_lines "$(jq -Rsc 'split("\n") | map(select(length > 0))' <"$routes6_file")" \
    --argjson connectivity_lines "$(jq -Rsc 'split("\n") | map(select(length > 0))' <"$connectivity_file")" \
    --argjson accel_present "$accel_present" --arg accel_value "$accel_value" \
    --argjson user_present "$user_present" --arg user_value "$user_value" \
    --argjson immersive_present "$immersive_present" \
    --arg immersive_value "$immersive_value" \
    '{
      network: {
        wifi_on: $wifi, mobile_data: $data, airplane_mode_on: $airplane,
        reverse_sha256: $reverse_sha256,
        routes4_sha256: $routes4_sha256,
        routes6_sha256: $routes6_sha256,
        connectivity_sha256: $connectivity_sha256,
        adb_reverse: $reverse_lines,
        routes4: $routes4_lines,
        routes6: $routes6_lines,
        connectivity: $connectivity_lines
      },
      presentation: {
        accelerometer_rotation: {present: $accel_present, value: $accel_value},
        user_rotation: {present: $user_present, value: $user_value},
        immersive_mode_confirmations: {
          present: $immersive_present, value: $immersive_value
        }
      }
    }' >"$output"
}

capture_connectivity_state() {
  local output="$1" raw transport token connected
  raw="$(adb_device shell dumpsys connectivity | trim_cr)" || return 1
  for transport in CELLULAR VPN WIFI; do
    token="$transport"
    connected=0
    if printf '%s\n' "$raw" |
       grep -Ei "($token|TRANSPORT_$token).*(CONNECTED|VALIDATED)|(CONNECTED|VALIDATED).*($token|TRANSPORT_$token)" \
         >/dev/null; then
      connected=1
    fi
    printf '%s_connected=%s\n' "$(printf '%s' "$transport" | tr '[:upper:]' '[:lower:]')" "$connected"
  done >"$output"
}

sample_uid_pids() {
  local phase="$1" output timestamp header matched malformed
  LAST_SAMPLE_MATCHED=0
  timestamp="$(date -u +%s)"
  output="$(adb_device shell ps -A -n -o UID,PID,NAME | trim_cr)" || {
    printf 'error\t%s\t%s\t%s\t0\tps_failed\t%s\n' \
      "$phase" "$timestamp" "${APP_UID:-0}" "$RUN_ID" >>"$PID_TRACE"
    return 1
  }
  header="$(printf '%s\n' "$output" | awk 'NF{print; exit}')"
  [[ "$header" == *"UID"* && "$header" == *"PID"* && "$header" == *"NAME"* ]] || {
    printf 'error\t%s\t%s\t%s\t0\tps_header_invalid\t%s\n' \
      "$phase" "$timestamp" "$APP_UID" "$RUN_ID" >>"$PID_TRACE"
    return 1
  }
  matched=0
  malformed=0
  while IFS=$'\t' read -r uid pid name; do
    [[ -n "$uid" ]] || continue
    if [[ ! "$uid" =~ ^[0-9]+$ || ! "$pid" =~ ^[0-9]+$ || -z "$name" ]]; then
      malformed=1
      continue
    fi
    [[ "$uid" == "$APP_UID" ]] || continue
    printf 'sample\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$phase" "$timestamp" "$uid" "$pid" "$name" "$RUN_ID" >>"$PID_TRACE"
    matched=$((matched + 1))
  done < <(printf '%s\n' "$output" | awk 'NR>1 && NF>=3 {print $1"\t"$2"\t"$3}')
  [[ "$malformed" -eq 0 ]] || {
    printf 'error\t%s\t%s\t%s\t0\tps_row_invalid\t%s\n' \
      "$phase" "$timestamp" "$APP_UID" "$RUN_ID" >>"$PID_TRACE"
    return 1
  }
  if [[ "$matched" -eq 0 ]]; then
    printf 'empty\t%s\t%s\t%s\t0\t-\t%s\n' \
      "$phase" "$timestamp" "$APP_UID" "$RUN_ID" >>"$PID_TRACE"
  fi
  LAST_SAMPLE_MATCHED="$matched"
}

pid_sampler_loop() {
  trap 'exit 0' HUP INT TERM QUIT
  while true; do
    sample_uid_pids continuous || exit 1
    sleep 0.2
  done
}

stop_sampler() {
  [[ -n "$sampler_pid" ]] || return 0
  if kill -0 "$sampler_pid" >/dev/null 2>&1; then
    kill -TERM "$sampler_pid" >/dev/null 2>&1 || return 1
  fi
  wait "$sampler_pid" >/dev/null 2>&1 || return 1
  sampler_pid=""
  sampler_clean=true
}

stop_logcat() {
  [[ -n "$logcat_pid" ]] || return 0
  if kill -0 "$logcat_pid" >/dev/null 2>&1; then
    kill -TERM "$logcat_pid" >/dev/null 2>&1 || return 1
  fi
  wait "$logcat_pid" >/dev/null 2>&1 || true
  kill -0 "$logcat_pid" >/dev/null 2>&1 && return 1
  logcat_pid=""
  logcat_clean=true
}

wait_for_marker() {
  local marker="$1" expected_count="$2" count
  for _ in $(seq 1 50); do
    count="$(grep -Fc "$marker" "$NATIVE_LOG" 2>/dev/null || true)"
    [[ "$count" == "$expected_count" ]] && return 0
    [[ "$count" -gt "$expected_count" ]] && return 1
    sleep 0.1
  done
  return 1
}

emit_uid_marker() {
  local marker="$1"
  adb_device shell run-as "$PACKAGE" /system/bin/log -t ManaLoomEgress "$marker" >/dev/null
}

drain_uid_processes() {
  local phase="$1" consecutive=0
  for _ in $(seq 1 40); do
    sample_uid_pids "$phase" || return 1
    if [[ "$LAST_SAMPLE_MATCHED" -eq 0 ]]; then
      consecutive=$((consecutive + 1))
      [[ "$consecutive" -ge 3 ]] && return 0
    else
      consecutive=0
    fi
    sleep 0.1
  done
  return 1
}

force_stop_and_clear() {
  adb_device shell am force-stop "$PACKAGE" >/dev/null || return 1
  adb_device shell cmd jobscheduler cancel -u 0 "$PACKAGE" >/dev/null || return 1
  [[ "$(adb_device shell pm clear "$PACKAGE" | trim_cr)" == "Success" ]] || return 1
  if adb_device shell dumpsys jobscheduler | grep -F "$PACKAGE" >/dev/null; then
    return 1
  fi
  adb_device shell run-as "$PACKAGE" sh -c \
    'test ! -e databases/com.google.android.datatransport.events && test ! -e databases/com.google.android.datatransport.events-journal' \
    >/dev/null || return 1
}

restore_network() {
  local restore_failed=0 wifi_now data_now airplane_now routes_match reverse_match
  local connectivity_match
  adb_device reverse --remove-all >/dev/null || restore_failed=1
  if [[ "$WIFI_BEFORE" == "1" ]]; then
    adb_device shell svc wifi enable >/dev/null || restore_failed=1
  else
    adb_device shell svc wifi disable >/dev/null || restore_failed=1
  fi
  if [[ "$DATA_BEFORE" == "1" ]]; then
    adb_device shell svc data enable >/dev/null || restore_failed=1
  else
    adb_device shell svc data disable >/dev/null || restore_failed=1
  fi
  for _ in $(seq 1 40); do
    wifi_now="$(adb_device shell settings get global wifi_on | trim_cr)"
    data_now="$(adb_device shell settings get global mobile_data | trim_cr)"
    airplane_now="$(adb_device shell settings get global airplane_mode_on | trim_cr)"
    adb_device reverse --list | trim_cr | LC_ALL=C sort >"$STATE_DIR/reverse.restore-probe" || restore_failed=1
    adb_device shell ip -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes4.restore-probe" || restore_failed=1
    adb_device shell ip -6 -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes6.restore-probe" || restore_failed=1
    capture_connectivity_state "$STATE_DIR/connectivity.restore-probe" || restore_failed=1
    reverse_match=false
    routes_match=false
    connectivity_match=false
    cmp -s "$STATE_DIR/reverse.before" "$STATE_DIR/reverse.restore-probe" && reverse_match=true
    if cmp -s "$STATE_DIR/routes4.before" "$STATE_DIR/routes4.restore-probe" &&
       cmp -s "$STATE_DIR/routes6.before" "$STATE_DIR/routes6.restore-probe"; then
      routes_match=true
    fi
    cmp -s "$STATE_DIR/connectivity.before" "$STATE_DIR/connectivity.restore-probe" && connectivity_match=true
    [[ "$wifi_now" == "$WIFI_BEFORE" && "$data_now" == "$DATA_BEFORE" &&
       "$airplane_now" == "$AIRPLANE_BEFORE" && "$reverse_match" == "true" &&
       "$routes_match" == "true" && "$connectivity_match" == "true" ]] && break
    sleep 0.25
  done
  [[ "$wifi_now" == "$WIFI_BEFORE" && "$data_now" == "$DATA_BEFORE" &&
     "$airplane_now" == "$AIRPLANE_BEFORE" && "$reverse_match" == "true" &&
     "$routes_match" == "true" && "$connectivity_match" == "true" ]] || restore_failed=1
  [[ "$restore_failed" -eq 0 ]]
}

restore_presentation() {
  local failed=0
  restore_setting system accelerometer_rotation "$ACCEL_PRESENT" "$ACCEL_VALUE" || failed=1
  restore_setting system user_rotation "$USER_ROTATION_PRESENT" "$USER_ROTATION_VALUE" || failed=1
  restore_setting secure immersive_mode_confirmations "$IMMERSIVE_PRESENT" "$IMMERSIVE_VALUE" || failed=1
  [[ "$failed" -eq 0 ]] || return 1
  presentation_restore_exact=true
}

write_and_seal_receipt() {
  local sampled_pids_json begin_count end_count samples_before samples_continuous
  local drain_samples sampler_errors zeros_before_end zeros_after_end
  sampled_pids_json="$(awk -F '\t' '$1=="sample" && $5 ~ /^[0-9]+$/ {print $5}' "$PID_TRACE" |
    LC_ALL=C sort -nu | jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)')"
  [[ "$(jq 'length' <<<"$sampled_pids_json")" -gt 0 ]] || return 1
  begin_count="$(grep -Fc "MANALOOM_ANDROID_EGRESS_BEGIN run_id=$RUN_ID uid=$APP_UID" "$NATIVE_LOG")"
  end_count="$(grep -Fc "MANALOOM_ANDROID_EGRESS_END run_id=$RUN_ID uid=$APP_UID" "$NATIVE_LOG")"
  samples_before="$(awk -F '\t' '$2=="pre_launch"{n++} END{print n+0}' "$PID_TRACE")"
  samples_continuous="$(awk -F '\t' '$2=="continuous"{n++} END{print n+0}' "$PID_TRACE")"
  drain_samples="$(awk -F '\t' '$2 ~ /^drain/{n++} END{print n+0}' "$PID_TRACE")"
  sampler_errors="$(awk -F '\t' '$1=="error"{n++} END{print n+0}' "$PID_TRACE")"
  zeros_before_end="$(awk -F '\t' '$2=="drain_before_end" {if ($1=="empty") n++; else n=0} END{print n+0}' "$PID_TRACE")"
  zeros_after_end="$(awk -F '\t' '$2=="drain_after_end" {if ($1=="empty") n++; else n=0} END{print n+0}' "$PID_TRACE")"

  jq --null-input \
    --arg run_id "$RUN_ID" --arg run_root "$RUN_ROOT_REAL" \
    --arg source_digest "$SOURCE_DIGEST" --arg profile "$PROFILE" \
    --arg target "$TARGET" --arg serial "$SERIAL" --arg model "$MODEL" \
    --arg package "$PACKAGE" --arg native_log_path "$NATIVE_LOG" \
    --arg pid_trace_path "$PID_TRACE" --arg state_before_path "$STATE_BEFORE" \
    --arg state_isolated_path "$STATE_ISOLATED" --arg state_after_path "$STATE_AFTER" \
    --arg before_sha256 "$(sha256_file "$STATE_BEFORE")" \
    --arg isolated_sha256 "$(sha256_file "$STATE_ISOLATED")" \
    --arg after_sha256 "$(sha256_file "$STATE_AFTER")" \
    --argjson api "$API" --argjson uid "$APP_UID" \
    --argjson api_port "$API_PORT" --argjson web_port "$WEB_PORT" \
    --argjson sampled_pids "$sampled_pids_json" \
    --argjson begin_count "$begin_count" --argjson end_count "$end_count" \
    --argjson samples_before "$samples_before" \
    --argjson samples_continuous "$samples_continuous" \
    --argjson drain_samples "$drain_samples" \
    --argjson sampler_errors "$sampler_errors" \
    --argjson zeros_before_end "$zeros_before_end" \
    --argjson zeros_after_end "$zeros_after_end" \
    '{
      schema_version: "manaloom.android_ui_egress_receipt.v2",
      status: "PENDING_DERIVED_ASSESSMENT",
      run_id: $run_id, run_root: $run_root, source_digest: $source_digest,
      profile: $profile, target: $target,
      identity: {
        serial: $serial, model: $model, api: $api, package: $package, uid: $uid,
        sampled_pids: $sampled_pids, logged_pids: [], observed_pids: []
      },
      detector: {
        temporal_anchor: "-T 1", log_format: "epoch_uid",
        logcat_started_before_begin: true,
        begin_marker_count: $begin_count, end_marker_count: $end_count,
        begin_before_child: true, end_after_force_stop_and_drain: true,
        sampler_started_before_launch: true, sampler_failures: $sampler_errors,
        samples_before_launch: $samples_before,
        samples_during_journey: $samples_continuous,
        drain_samples: $drain_samples,
        consecutive_zero_samples_before_end: $zeros_before_end,
        consecutive_zero_samples_after_end: $zeros_after_end,
        all_uid_pids_enumerated: (
          $sampler_errors == 0 and $samples_before > 0 and
          $samples_continuous > 0 and $zeros_before_end >= 3 and
          $zeros_after_end >= 3
        )
      },
      app_data: {
        pre_launch_clean: true, post_run_clean: true,
        datatransport_store_absent: true
      },
      network: {
        snapshot_complete: true, isolation_confirmed: true,
        adb_usb_preserved: true, reverse_loopback_only: true,
        restored_exactly: true,
        api_port: $api_port, web_port: $web_port
      },
      presentation: {
        snapshot_complete: true,
        rotation_and_immersive_restored_exactly: true,
        before_sha256: $before_sha256, isolated_sha256: $isolated_sha256,
        restored_sha256: $after_sha256
      },
      cleanup: {
        app_processes: 0, sampler_processes: 0, logcat_processes: 0,
        external_routes: 0, restore_failures: 0, guard_processes: 0,
        state_dir_absent: true
      },
      artifacts: {
        native_log_path: $native_log_path, pid_trace_path: $pid_trace_path,
        state_before_path: $state_before_path,
        state_isolated_path: $state_isolated_path,
        state_after_path: $state_after_path
      }
    }' >"$RECEIPT"

  "$DART_BIN" --packages="$ROOT_DIR/app/.dart_tool/package_config.json" \
    "$ROOT_DIR/app/tool/ui_runtime_evidence.dart" seal-android-egress-receipt \
    --receipt "$RECEIPT" --runtime-log "$RUNTIME_LOG" \
    --native-log "$NATIVE_LOG" --pid-trace "$PID_TRACE" \
    --policy "$POLICY_FILE" --run-id "$RUN_ID" \
    --source-digest "$SOURCE_DIGEST" --profile "$PROFILE" \
    --target "$TARGET" >/dev/null
}

finalize() {
  local original_exit="$?" cleanup_exit=0 current_accel current_user current_immersive
  local wifi_after data_after airplane_after end_marker
  if [[ "$cleanup_running" == "true" ]]; then
    exit 1
  fi
  cleanup_running=true
  trap - EXIT HUP INT TERM QUIT
  set +e

  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" >/dev/null 2>&1; then
    terminate_child_tree "$child_pid" || cleanup_exit=1
  fi
  # Stop the continuous writer before synchronous drain samples so each TSV
  # row remains atomic and the terminal zero run is derivable.
  stop_sampler || cleanup_exit=1
  if [[ -n "$APP_UID" && "$network_snapshot_complete" == "true" ]]; then
    sample_uid_pids pre_force_stop || cleanup_exit=1
    force_stop_and_clear || cleanup_exit=1
    if drain_uid_processes drain_before_end; then
      first_drain_confirmed=true
    else
      cleanup_exit=1
    fi
    if [[ "$logcat_started" == "true" && "$first_drain_confirmed" == "true" ]]; then
      end_marker="MANALOOM_ANDROID_EGRESS_END run_id=$RUN_ID uid=$APP_UID"
      emit_uid_marker "$end_marker" || cleanup_exit=1
      wait_for_marker "$end_marker" 1 || cleanup_exit=1
      end_confirmed=true
      if drain_uid_processes drain_after_end; then
        final_drain_confirmed=true
      else
        cleanup_exit=1
      fi
    fi
  fi
  stop_logcat || cleanup_exit=1

  if [[ "$presentation_mutated" == "true" ]]; then
    restore_presentation || cleanup_exit=1
  fi
  if [[ "$network_mutated" == "true" || "$reverse_mutated" == "true" ]]; then
    restore_network || cleanup_exit=1
  fi

  if [[ "$network_snapshot_complete" == "true" &&
        "$presentation_snapshot_complete" == "true" ]]; then
    adb_device reverse --list | trim_cr | LC_ALL=C sort >"$STATE_DIR/reverse.after" || cleanup_exit=1
    adb_device shell ip -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes4.after" || cleanup_exit=1
    adb_device shell ip -6 -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes6.after" || cleanup_exit=1
    capture_connectivity_state "$STATE_DIR/connectivity.after" || cleanup_exit=1
    wifi_after="$(adb_device shell settings get global wifi_on | trim_cr)"
    data_after="$(adb_device shell settings get global mobile_data | trim_cr)"
    airplane_after="$(adb_device shell settings get global airplane_mode_on | trim_cr)"
    current_accel="$(read_setting_snapshot system accelerometer_rotation)" || cleanup_exit=1
    current_user="$(read_setting_snapshot system user_rotation)" || cleanup_exit=1
    current_immersive="$(read_setting_snapshot secure immersive_mode_confirmations)" || cleanup_exit=1
    write_device_state "$STATE_AFTER" "$wifi_after" "$data_after" "$airplane_after" \
      "$STATE_DIR/reverse.after" "$STATE_DIR/routes4.after" "$STATE_DIR/routes6.after" \
      "$STATE_DIR/connectivity.after" \
      "${current_accel%%$'\t'*}" "${current_accel#*$'\t'}" \
      "${current_user%%$'\t'*}" "${current_user#*$'\t'}" \
      "${current_immersive%%$'\t'*}" "${current_immersive#*$'\t'}" || cleanup_exit=1
    if cmp -s "$STATE_BEFORE" "$STATE_AFTER"; then
      restore_exact=true
    else
      cleanup_exit=1
    fi
  fi

  safe_remove_state_dir || cleanup_exit=1
  [[ ! -e "$STATE_DIR" && ! -L "$STATE_DIR" ]] && state_dir_absent=true || cleanup_exit=1

  if [[ "$normal_completed" == "true" && "$launcher_exit" -eq 0 &&
        "$original_exit" -eq 0 && "$cleanup_exit" -eq 0 &&
        "$pre_launch_clean" == "true" && "$isolation_confirmed" == "true" &&
        "$usb_preserved" == "true" && "$reverse_confirmed" == "true" &&
        "$restore_exact" == "true" && "$presentation_restore_exact" == "true" &&
        "$begin_confirmed" == "true" && "$end_confirmed" == "true" &&
        "$first_drain_confirmed" == "true" && "$final_drain_confirmed" == "true" &&
        "$sampler_clean" == "true" && "$logcat_clean" == "true" &&
        "$state_dir_absent" == "true" && -f "$RUNTIME_LOG" ]]; then
    post_run_clean=true
    write_and_seal_receipt || cleanup_exit=1
  fi

  if [[ "$cleanup_exit" -ne 0 ]]; then
    if [[ ! -f "$RECEIPT" ]] ||
       ! jq -e '.status == "FAIL_ANDROID_EGRESS"' "$RECEIPT" >/dev/null 2>&1; then
      rm -f "$RECEIPT"
    fi
    printf 'NO_GO_ANDROID_NETWORK_ISOLATION_UNPROVABLE: cleanup/receipt failed\n' >&2
    exit 1
  fi
  exit "$original_exit"
}

signal_exit() {
  local code="$1"
  launcher_exit="$code"
  exit "$code"
}

if [[ "${1:-}" != "run" ]]; then
  usage >&2
  exit 2
fi
shift
while (($#)); do
  case "$1" in
    --run-id) RUN_ID="${2:-}"; shift 2 ;;
    --serial) SERIAL="${2:-}"; shift 2 ;;
    --package) PACKAGE="${2:-}"; shift 2 ;;
    --source-digest) SOURCE_DIGEST="${2:-}"; shift 2 ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --runtime-log) RUNTIME_LOG="${2:-}"; shift 2 ;;
    --native-log) NATIVE_LOG="${2:-}"; shift 2 ;;
    --pid-trace) PID_TRACE="${2:-}"; shift 2 ;;
    --receipt) RECEIPT="${2:-}"; shift 2 ;;
    --api-port) API_PORT="${2:-}"; shift 2 ;;
    --web-port) WEB_PORT="${2:-}"; shift 2 ;;
    --) shift; CHILD=("$@"); break ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for tool in awk cat cmp find grep jq mktemp pgrep python3 sed seq shasum sort stat tr wc; do
  command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done
[[ -x "$ADB_BIN" && "$ADB_BIN" == /* ]] || fail "ADB must be an absolute executable"
[[ -x "$DART_BIN" && "$DART_BIN" == /* ]] || fail "Dart must be an absolute executable"
[[ -f "$POLICY_FILE" && ! -L "$POLICY_FILE" ]] || fail "UI evidence policy is missing or unsafe"
[[ "$RUN_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$ ]] || fail "invalid run ID"
[[ "$SERIAL" =~ ^[A-Za-z0-9._:-]+$ ]] || fail "invalid Android serial"
[[ "$PACKAGE" =~ ^[A-Za-z][A-Za-z0-9_.]+$ ]] || fail "invalid package"
[[ "$SOURCE_DIGEST" =~ ^[0-9a-f]{64}$ ]] || fail "invalid UI source digest"
[[ "$PROFILE" == android_physical_* ]] || fail "guard requires a physical profile"
is_port "$API_PORT" || fail "invalid API port"
is_port "$WEB_PORT" || fail "invalid Web port"
[[ "$API_PORT" != "$WEB_PORT" ]] || fail "loopback ports must differ"
[[ ${#CHILD[@]} -gt 0 ]] || fail "governed command is required"
for output in "$RUNTIME_LOG" "$NATIVE_LOG" "$PID_TRACE" "$RECEIPT"; do
  [[ "$output" == /* ]] || fail "logs and receipt must use absolute paths"
done

RUN_ROOT="$(dirname -- "$RECEIPT")"
for output in "$RUNTIME_LOG" "$NATIVE_LOG" "$PID_TRACE"; do
  [[ "$(dirname -- "$output")" == "$RUN_ROOT" ]] || fail "receipt and logs must share one canonical run root"
done
[[ -d "$RUN_ROOT" && ! -L "$RUN_ROOT" ]] || fail "run root must exist and not be a symlink"
RUN_ROOT_REAL="$(CDPATH='' cd -- "$RUN_ROOT" && pwd -P)"
SYSTEM_TEMP_REAL="$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)"
POSIX_TEMP_REAL="$(CDPATH='' cd -- /tmp && pwd -P)"
[[ "$RUN_ROOT_REAL" == "$SYSTEM_TEMP_REAL"/* || "$RUN_ROOT_REAL" == "$POSIX_TEMP_REAL"/* ]] ||
  fail "run root must resolve below the governed system or /tmp root"
STATE_BEFORE="${NATIVE_LOG%.log}.state-before.json"
STATE_ISOLATED="${NATIVE_LOG%.log}.state-isolated.json"
STATE_AFTER="${NATIVE_LOG%.log}.state-after.json"
for output in "$RUNTIME_LOG" "$NATIVE_LOG" "$PID_TRACE" "$RECEIPT" \
  "$STATE_BEFORE" "$STATE_ISOLATED" "$STATE_AFTER"; do
  [[ ! -e "$output" && ! -L "$output" ]] || fail "output already exists: $output"
done

# Traps are active before the first mktemp, snapshot or device mutation.
trap finalize EXIT
trap 'signal_exit 129' HUP
trap 'signal_exit 130' INT
trap 'signal_exit 143' TERM
trap 'signal_exit 131' QUIT

policy_package="$(jq -r '.android_physical_egress.package // empty' "$POLICY_FILE")"
policy_profile="$(jq -r '.android_physical_egress.required_profile // empty' "$POLICY_FILE")"
policy_receipt="$(jq -r '.android_physical_egress.receipt_schema // empty' "$POLICY_FILE")"
[[ "$PACKAGE" == "$policy_package" && "$PROFILE" == "$policy_profile" &&
   "$policy_receipt" == "manaloom.android_ui_egress_receipt.v2" ]] ||
  fail "package/profile/receipt do not match the governed policy"

device_line="$("$ADB_BIN" devices -l | awk -v serial="$SERIAL" '$1 == serial && $2 == "device" {print}')"
[[ "$device_line" == *"usb:"* ]] || fail "device is not an authorized USB ADB transport"
[[ "$(adb_device get-state | trim_cr)" == "device" ]] || fail "ADB device is not ready"
MODEL="$(adb_device shell getprop ro.product.model | trim_cr)"
API="$(adb_device shell getprop ro.build.version.sdk | trim_cr)"
[[ -n "$MODEL" && "$API" =~ ^[0-9]+$ ]] || fail "device identity is incomplete"
APP_UID="$(adb_device shell dumpsys package "$PACKAGE" |
  awk -F= '/^[[:space:]]*userId=/{gsub(/[[:space:]\r]/, "", $2); print $2; exit}')"
[[ "$APP_UID" =~ ^[0-9]+$ && "$APP_UID" -gt 0 ]] || fail "installed package UID is unavailable"

STATE_DIR="$(mktemp -d "$RUN_ROOT/.android-egress-state.XXXXXX")"
chmod 700 "$STATE_DIR"
JOURNAL="$STATE_DIR/journal"
printf 'schema=manaloom_android_ui_egress_guard_journal_v2\nrun_id=%s\nserial=%s\n' \
  "$RUN_ID" "$SERIAL" >"$JOURNAL"
chmod 600 "$JOURNAL"
touch "$PID_TRACE" "$NATIVE_LOG"
chmod 600 "$PID_TRACE" "$NATIVE_LOG"

WIFI_BEFORE="$(adb_device shell settings get global wifi_on | trim_cr)"
DATA_BEFORE="$(adb_device shell settings get global mobile_data | trim_cr)"
AIRPLANE_BEFORE="$(adb_device shell settings get global airplane_mode_on | trim_cr)"
[[ "$WIFI_BEFORE" =~ ^[01]$ && "$DATA_BEFORE" =~ ^[01]$ &&
   "$AIRPLANE_BEFORE" =~ ^[01]$ ]] || fail "network settings cannot be snapshotted"
accel_snapshot="$(read_setting_snapshot system accelerometer_rotation)" || fail "accelerometer rotation snapshot failed"
ACCEL_PRESENT="${accel_snapshot%%$'\t'*}"
ACCEL_VALUE="${accel_snapshot#*$'\t'}"
user_snapshot="$(read_setting_snapshot system user_rotation)" || fail "user rotation snapshot failed"
USER_ROTATION_PRESENT="${user_snapshot%%$'\t'*}"
USER_ROTATION_VALUE="${user_snapshot#*$'\t'}"
immersive_snapshot="$(read_setting_snapshot secure immersive_mode_confirmations)" || fail "immersive snapshot failed"
IMMERSIVE_PRESENT="${immersive_snapshot%%$'\t'*}"
IMMERSIVE_VALUE="${immersive_snapshot#*$'\t'}"
presentation_snapshot_complete=true

adb_device reverse --list | trim_cr | LC_ALL=C sort >"$STATE_DIR/reverse.before"
[[ ! -s "$STATE_DIR/reverse.before" ]] || fail "preexisting ADB reverse mappings make ownership unprovable"
adb_device shell ip -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes4.before"
adb_device shell ip -6 -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes6.before"
capture_connectivity_state "$STATE_DIR/connectivity.before" ||
  fail "connectivity snapshot failed"
if grep -Fx 'vpn_connected=1' "$STATE_DIR/connectivity.before" >/dev/null; then
  fail "active VPN cannot be safely isolated on this stock device"
fi
write_device_state "$STATE_BEFORE" "$WIFI_BEFORE" "$DATA_BEFORE" "$AIRPLANE_BEFORE" \
  "$STATE_DIR/reverse.before" "$STATE_DIR/routes4.before" "$STATE_DIR/routes6.before" \
  "$STATE_DIR/connectivity.before" \
  "$ACCEL_PRESENT" "$ACCEL_VALUE" "$USER_ROTATION_PRESENT" "$USER_ROTATION_VALUE" \
  "$IMMERSIVE_PRESENT" "$IMMERSIVE_VALUE"
network_snapshot_complete=true

force_stop_and_clear || fail "pre-launch app/DataTransport state could not be cleared"
pre_launch_clean=true

wifi_mutated=true
network_mutated=true
adb_device shell svc wifi disable >/dev/null
data_mutated=true
adb_device shell svc data disable >/dev/null
accelerometer_mutated=true
presentation_mutated=true
adb_device shell settings put system accelerometer_rotation 0 >/dev/null
user_rotation_mutated=true
adb_device shell settings put system user_rotation 0 >/dev/null
immersive_mutated=true
adb_device shell settings put secure immersive_mode_confirmations confirmed >/dev/null
isolated_accel="$(read_setting_snapshot system accelerometer_rotation)" ||
  fail "isolated accelerometer rotation readback failed"
isolated_user="$(read_setting_snapshot system user_rotation)" ||
  fail "isolated user rotation readback failed"
isolated_immersive="$(read_setting_snapshot secure immersive_mode_confirmations)" ||
  fail "isolated immersive readback failed"
[[ "$isolated_accel" == $'true\t0' && "$isolated_user" == $'true\t0' &&
   "$isolated_immersive" == $'true\tconfirmed' ]] ||
  fail "isolated presentation settings did not apply exactly"
for _ in $(seq 1 40); do
  wifi_now="$(adb_device shell settings get global wifi_on | trim_cr)"
  data_now="$(adb_device shell settings get global mobile_data | trim_cr)"
  routes4_now="$(adb_device shell ip -o route show table all | trim_cr)"
  routes6_now="$(adb_device shell ip -6 -o route show table all | trim_cr)"
  connectivity_now="$(adb_device shell dumpsys connectivity | trim_cr)"
  if [[ "$wifi_now" == "0" && "$data_now" == "0" &&
        ! "$routes4_now" =~ (^|$'\n')[^$'\n']*default[[:space:]] &&
        ! "$routes6_now" =~ (^|$'\n')[^$'\n']*default[[:space:]] &&
        ! "$connectivity_now" =~ (CONNECTED|VALIDATED).*(WIFI|CELLULAR|VPN) &&
        ! "$connectivity_now" =~ (WIFI|CELLULAR|VPN).*(CONNECTED|VALIDATED) ]]; then
    isolation_confirmed=true
    break
  fi
  sleep 0.25
done
[[ "$isolation_confirmed" == "true" ]] || fail "external routes remain after isolation"
capture_connectivity_state "$STATE_DIR/connectivity.isolated" ||
  fail "isolated connectivity snapshot failed"
[[ "$(cat "$STATE_DIR/connectivity.isolated")" == $'cellular_connected=0\nvpn_connected=0\nwifi_connected=0' ]] ||
  fail "external connectivity remains after isolation"
[[ "$(adb_device get-state | trim_cr)" == "device" ]] || fail "USB ADB was lost during isolation"
usb_preserved=true

api_reverse_mutated=true
reverse_mutated=true
adb_device reverse "tcp:$API_PORT" "tcp:$API_PORT" >/dev/null
web_reverse_mutated=true
adb_device reverse "tcp:$WEB_PORT" "tcp:$WEB_PORT" >/dev/null
adb_device reverse --list | trim_cr | LC_ALL=C sort >"$STATE_DIR/reverse.isolated"
reverse_count="$(wc -l <"$STATE_DIR/reverse.isolated" | tr -d '[:space:]')"
[[ "$reverse_count" == "2" ]] || fail "isolated reverse mapping set is not exact"
grep -F "tcp:$API_PORT tcp:$API_PORT" "$STATE_DIR/reverse.isolated" >/dev/null || fail "API reverse mapping is missing"
grep -F "tcp:$WEB_PORT tcp:$WEB_PORT" "$STATE_DIR/reverse.isolated" >/dev/null || fail "Web reverse mapping is missing"
reverse_confirmed=true
adb_device shell ip -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes4.isolated"
adb_device shell ip -6 -o route show table all | trim_cr | LC_ALL=C sort >"$STATE_DIR/routes6.isolated"
write_device_state "$STATE_ISOLATED" "0" "0" "$AIRPLANE_BEFORE" \
  "$STATE_DIR/reverse.isolated" "$STATE_DIR/routes4.isolated" "$STATE_DIR/routes6.isolated" \
  "$STATE_DIR/connectivity.isolated" \
  "${isolated_accel%%$'\t'*}" "${isolated_accel#*$'\t'}" \
  "${isolated_user%%$'\t'*}" "${isolated_user#*$'\t'}" \
  "${isolated_immersive%%$'\t'*}" "${isolated_immersive#*$'\t'}"

sample_uid_pids pre_launch || fail "UID PID sampler preflight failed"
[[ "$LAST_SAMPLE_MATCHED" -eq 0 ]] || fail "app UID process remains before launch"
pid_sampler_loop &
sampler_pid="$!"
sampler_started=true
sleep 0.2
kill -0 "$sampler_pid" >/dev/null 2>&1 || fail "UID PID sampler did not remain active"

adb_device logcat -b all --uid="$APP_UID" -v epoch -v uid -T 1 >>"$NATIVE_LOG" 2>&1 &
logcat_pid="$!"
logcat_started=true
sleep 0.2
kill -0 "$logcat_pid" >/dev/null 2>&1 || fail "UID logcat detector did not remain active"
begin_marker="MANALOOM_ANDROID_EGRESS_BEGIN run_id=$RUN_ID uid=$APP_UID"
emit_uid_marker "$begin_marker" || fail "UID BEGIN marker could not be emitted"
wait_for_marker "$begin_marker" 1 || fail "UID BEGIN marker is absent or ambiguous"
begin_confirmed=true

set +e
"${CHILD[@]}" &
child_pid="$!"
wait "$child_pid"
launcher_exit="$?"
child_pid=""
set -e
normal_completed=true
exit "$launcher_exit"

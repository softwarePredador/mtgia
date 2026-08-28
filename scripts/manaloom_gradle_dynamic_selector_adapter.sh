#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
INIT_SOURCE="$ROOT_DIR/scripts/lib/manaloom_gradle_dynamic_selector_pins.init.gradle"

EXPECTED_FLUTTER_VERSION="3.44.6"
EXPECTED_DART_VERSION="3.12.2"
EXPECTED_FLUTTER_COMMIT="ee80f08bbf97172ec030b8751ceab557177a34a6"
EXPECTED_FLUTTER_VERSION_SHA256="9809948372bd1645e5ff4628e2314d826bc2dffde10daf59fb0ff6964ea92ea2"
EXPECTED_PLUGIN_SHA256="0839288b76144c10774df10c04161f58c8f4c75a9a3eac12dab4fc3c4c9e8f9b"
EXPECTED_LOCK_SHA256="f26494d2a1b9c6e2f2c0e7892613089235aae01dad51eb329f657ba6ec971396"
EXPECTED_VERIFICATION_SHA256="240cd189b8cba717f329e056817601dfdd54f553d99cb84c1061ec10580a0353"
EXPECTED_APP_SETTINGS_SHA256="30668d609823397c450586539767ad3458b2e374463bd9d949fd81abcebae889"
EXPECTED_FLUTTER_SETTINGS_SHA256="56fe45270044d31615e1d9b8aa1410511a05b83ef431c24613b7907f225f9779"
EXPECTED_ROOT_BUILD_SHA256="deec203cc57f135e1682188b64a4607b04a818009167c9228784858a1a2a6fd3"
EXPECTED_APP_BUILD_SHA256="d263383a6ff695a3894458d4bc3bdda76c896bb46062a949469c4b80ab4fa2eb"
EXPECTED_MAIN_MANIFEST_SHA256="761a3873a269ebefa83e624ef29b7a5f14f5d359edf6e7e1040c74efbd93a234"
EXPECTED_RELEASE_MANIFEST_SHA256="7722a5f3c24d92999c3e0df297a55c6e3fe1c38db6ed72b563c334b32e996bbc"
EXPECTED_PROFILE_MANIFEST_SHA256="ff6fbd7f0c41fd6c2db82374a55898109e922497645f7846995e353a3776aa96"
EXPECTED_PUSH_GUARD_SHA256="f70f5ced7511090486514976a9b3dc62ac374d85f4adce7b91bdd1fad4b6701b"
EXPECTED_GRADLE_VERSION="8.14"

FLUTTER_BIN=""
APP_DIR=""
GRADLE_SOURCE_HOME="${MANALOOM_GRADLE_CACHE_HOME:-$HOME/.gradle}"
WORK_DIR=""
BUILD_LOG=""
RECEIPT=""
APK_PATH=""
MERGED_MANIFEST=""
APK_MANIFEST=""
TELEMETRY_LOG=""
TELEMETRY_RUN_ID=""
APKANALYZER_BIN="${MANALOOM_APKANALYZER_BIN:-$HOME/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer}"
POLICY_FILE="$ROOT_DIR/app/test/ui/fixtures/ui_live_evidence_policy.json"
FLUTTER_ARGS=()

usage() {
  cat <<'EOF'
usage:
  manaloom_gradle_dynamic_selector_adapter.sh preflight \
    --flutter-bin <flutter> --app-dir <app> --output <json>

  manaloom_gradle_dynamic_selector_adapter.sh run \
    --flutter-bin <flutter> --app-dir <app> \
    --gradle-source-home <gradle-home> --work-dir <new-dir> \
    --build-log <new-log> --receipt <new-json> --apk <new-apk> \
    --merged-manifest <new-xml> --apk-manifest <new-xml> \
    --apkanalyzer <bin> --policy <json> -- <flutter build arguments>

  manaloom_gradle_dynamic_selector_adapter.sh telemetry-check \
    --telemetry-log <log-show-json> --run-id <run-id> --output <json>

The adapter is limited to ManaLoom's offline Android profile proof. It derives
three approved selector pins from the checked-in lock, installs the versioned
init file only in an ephemeral GRADLE_USER_HOME and emits a terminal receipt.
EOF
}

fail() {
  printf 'NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: %s\n' "$1" >&2
  exit 1
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

require_regular_file() {
  local path="$1" label="$2"
  [[ -f "$path" && ! -L "$path" ]] || fail "$label is missing, non-regular or a symlink"
}

require_hash() {
  local path="$1" expected="$2" label="$3"
  require_regular_file "$path" "$label"
  [[ "$(sha256_file "$path")" == "$expected" ]] || fail "$label hash drift"
}

require_absolute() {
  [[ "$1" == /* ]] || fail "$2 must be absolute"
}

parse_common_args() {
  while (($#)); do
    case "$1" in
      --flutter-bin) FLUTTER_BIN="${2:-}"; shift 2 ;;
      --app-dir) APP_DIR="${2:-}"; shift 2 ;;
      --gradle-source-home) GRADLE_SOURCE_HOME="${2:-}"; shift 2 ;;
      --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
      --build-log) BUILD_LOG="${2:-}"; shift 2 ;;
      --receipt) RECEIPT="${2:-}"; shift 2 ;;
      --apk) APK_PATH="${2:-}"; shift 2 ;;
      --merged-manifest) MERGED_MANIFEST="${2:-}"; shift 2 ;;
      --apk-manifest) APK_MANIFEST="${2:-}"; shift 2 ;;
      --telemetry-log) TELEMETRY_LOG="${2:-}"; shift 2 ;;
      --run-id) TELEMETRY_RUN_ID="${2:-}"; shift 2 ;;
      --apkanalyzer) APKANALYZER_BIN="${2:-}"; shift 2 ;;
      --policy) POLICY_FILE="${2:-}"; shift 2 ;;
      --output) RECEIPT="${2:-}"; shift 2 ;;
      --) shift; FLUTTER_ARGS=("$@"); break ;;
      *) fail "unknown argument: $1" ;;
    esac
  done
}

validate_static_inputs() {
  require_absolute "$FLUTTER_BIN" "Flutter binary"
  require_absolute "$APP_DIR" "app directory"
  [[ -x "$FLUTTER_BIN" && ! -L "$FLUTTER_BIN" ]] || fail "Flutter binary is not a regular executable"
  [[ -d "$APP_DIR" && ! -L "$APP_DIR" ]] || fail "app directory is unsafe"
  APP_DIR="$(CDPATH='' cd -- "$APP_DIR" && pwd -P)"
  local flutter_sdk
  flutter_sdk="$(CDPATH='' cd -- "$(dirname -- "$FLUTTER_BIN")/.." && pwd -P)"
  local dart_bin="$flutter_sdk/bin/cache/dart-sdk/bin/dart"
  local version_json="$flutter_sdk/bin/cache/flutter.version.json"
  local plugin_file="$flutter_sdk/packages/integration_test/android/build.gradle.kts"
  local flutter_settings="$flutter_sdk/packages/flutter_tools/gradle/settings.gradle.kts"
  local lock_file="$APP_DIR/android/app/gradle.lockfile"
  local verification_file="$APP_DIR/android/gradle/verification-metadata.xml"
  local app_settings="$APP_DIR/android/settings.gradle.kts"
  local root_build="$APP_DIR/android/build.gradle.kts"
  local app_build="$APP_DIR/android/app/build.gradle.kts"
  local main_manifest="$APP_DIR/android/app/src/main/AndroidManifest.xml"
  local release_manifest="$APP_DIR/android/app/src/release/AndroidManifest.xml"
  local profile_manifest="$APP_DIR/android/app/src/profile/AndroidManifest.xml"
  local push_guard="$APP_DIR/lib/core/services/push_notification_service.dart"

  [[ -x "$dart_bin" && ! -L "$dart_bin" ]] || fail "pinned Dart binary is missing"
  [[ "$(git -C "$flutter_sdk" rev-parse HEAD 2>/dev/null)" == "$EXPECTED_FLUTTER_COMMIT" ]] ||
    fail "Flutter commit drift"
  [[ -z "$(git -C "$flutter_sdk" status --porcelain --untracked-files=no 2>/dev/null)" ]] ||
    fail "Flutter SDK tracked files are dirty"
  require_hash "$version_json" "$EXPECTED_FLUTTER_VERSION_SHA256" "Flutter version manifest"
  [[ "$(jq -r '.frameworkVersion' "$version_json")" == "$EXPECTED_FLUTTER_VERSION" ]] ||
    fail "Flutter version manifest drift"
  [[ "$(jq -r '.dartSdkVersion' "$version_json")" == "$EXPECTED_DART_VERSION" ]] ||
    fail "Dart version manifest drift"
  [[ "$(jq -r '.frameworkRevision' "$version_json")" == "$EXPECTED_FLUTTER_COMMIT" ]] ||
    fail "Flutter revision manifest drift"
  require_hash "$plugin_file" "$EXPECTED_PLUGIN_SHA256" "integration_test Gradle plugin"
  require_hash "$lock_file" "$EXPECTED_LOCK_SHA256" "application Gradle lock"
  require_hash "$verification_file" "$EXPECTED_VERIFICATION_SHA256" "Gradle verification metadata"
  require_hash "$app_settings" "$EXPECTED_APP_SETTINGS_SHA256" "application Gradle settings"
  require_hash "$flutter_settings" "$EXPECTED_FLUTTER_SETTINGS_SHA256" "Flutter tools Gradle settings"
  require_hash "$root_build" "$EXPECTED_ROOT_BUILD_SHA256" "root Android Gradle build"
  require_hash "$app_build" "$EXPECTED_APP_BUILD_SHA256" "app Android Gradle build"
  require_hash "$main_manifest" "$EXPECTED_MAIN_MANIFEST_SHA256" "main Android manifest"
  require_hash "$release_manifest" "$EXPECTED_RELEASE_MANIFEST_SHA256" "release Android manifest"
  require_hash "$profile_manifest" "$EXPECTED_PROFILE_MANIFEST_SHA256" "profile Android manifest"
  require_hash "$push_guard" "$EXPECTED_PUSH_GUARD_SHA256" "push initialization guard"
  require_regular_file "$INIT_SOURCE" "versioned Gradle init"
  require_regular_file "$POLICY_FILE" "UI evidence policy"

  printf '%s\n' "$flutter_sdk" "$dart_bin" "$version_json" "$plugin_file" \
    "$flutter_settings" "$lock_file" "$verification_file" "$app_settings" \
    "$root_build" "$app_build" "$main_manifest" "$release_manifest" \
    "$profile_manifest" "$push_guard"
}

write_input_attestation() {
  local output="$1"
  local input_lines flutter_sdk dart_bin version_json plugin_file flutter_settings
  local lock_file verification_file app_settings root_build app_build
  local main_manifest release_manifest profile_manifest push_guard
  input_lines="$(validate_static_inputs)"
  flutter_sdk="$(printf '%s\n' "$input_lines" | sed -n '1p')"
  dart_bin="$(printf '%s\n' "$input_lines" | sed -n '2p')"
  version_json="$(printf '%s\n' "$input_lines" | sed -n '3p')"
  plugin_file="$(printf '%s\n' "$input_lines" | sed -n '4p')"
  flutter_settings="$(printf '%s\n' "$input_lines" | sed -n '5p')"
  lock_file="$(printf '%s\n' "$input_lines" | sed -n '6p')"
  verification_file="$(printf '%s\n' "$input_lines" | sed -n '7p')"
  app_settings="$(printf '%s\n' "$input_lines" | sed -n '8p')"
  root_build="$(printf '%s\n' "$input_lines" | sed -n '9p')"
  app_build="$(printf '%s\n' "$input_lines" | sed -n '10p')"
  main_manifest="$(printf '%s\n' "$input_lines" | sed -n '11p')"
  release_manifest="$(printf '%s\n' "$input_lines" | sed -n '12p')"
  profile_manifest="$(printf '%s\n' "$input_lines" | sed -n '13p')"
  push_guard="$(printf '%s\n' "$input_lines" | sed -n '14p')"
  require_absolute "$output" "attestation output"
  [[ ! -e "$output" && ! -L "$output" ]] || fail "attestation output already exists"
  mkdir -p "$(dirname -- "$output")"

  python3 - "$plugin_file" "$lock_file" "$verification_file" \
    "$GRADLE_SOURCE_HOME" "$output" <<'PY'
import hashlib
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

plugin_path, lock_path, verification_path, gradle_home, output_path = map(pathlib.Path, sys.argv[1:])
expected_selectors = {
    "androidx.test:runner": "1.2+",
    "androidx.test:rules": "1.2+",
    "androidx.test.espresso:espresso-core": "3.3+",
}
expected_artifacts = {
    "androidx.test:runner": {
        "aar": "a43c3e07e721a95a3645b58d048d4d2aa1de37981f081c0421a74300bf908002",
        "pom": "491e2cddf453bf3f9f65cd0fc0011d29647c45468fbc595d92672bb2be74b0d7",
    },
    "androidx.test:rules": {
        "aar": "24bd7111e0db91b4a5f6d5c3e3e89698580dc90d29273d04a775bb7fe7c2a761",
        "pom": "4746045af7a8b3f4de3f4dce9d8dd2ab0044087b8b7a4866a3c66892516a90f1",
    },
    "androidx.test.espresso:espresso-core": {
        "aar": "34b0493f4e002f205d961e562add0c0c31bb0acc657e89d89d4b188ac13f242c",
        "pom": "9e672028617979dab465678efdd1650b53c929634c399b1f5fef28252483684d",
    },
}
profile_configs = {
    "profileCompileClasspath",
    "profileRuntimeClasspath",
    "profileUnitTestCompileClasspath",
    "profileUnitTestRuntimeClasspath",
}

def die(message):
    raise SystemExit(f"NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: {message}")

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

plugin = plugin_path.read_text(encoding="utf-8")
coordinate_pattern = re.compile(r'["\']([A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:([^"\']+))["\']')
dynamic = {}
for full, version in coordinate_pattern.findall(plugin):
    is_dynamic = "+" in version or version.lower().startswith("latest.") or (
        "," in version
        and version[:1] in {"[", "(", "]"}
        and version[-1:] in {"]", ")", "["}
    )
    if not is_dynamic:
        continue
    group, name, _ = full.rsplit(":", 2)
    coordinate = f"{group}:{name}"
    if coordinate in dynamic and dynamic[coordinate] != version:
        die(f"ambiguous selector for {coordinate}")
    dynamic[coordinate] = version
if dynamic != expected_selectors:
    die(f"dynamic selector set is not exact: {dynamic}")

pins = {}
lock_configs = {}
for raw in lock_path.read_text(encoding="utf-8").splitlines():
    if "=" not in raw:
        continue
    module, config_text = raw.split("=", 1)
    parts = module.rsplit(":", 1)
    if len(parts) != 2:
        continue
    coordinate, version = parts
    if coordinate not in expected_selectors:
        continue
    if coordinate in pins and pins[coordinate] != version:
        die(f"ambiguous pin for {coordinate}")
    pins[coordinate] = version
    lock_configs[coordinate] = sorted(set(filter(None, config_text.split(","))))
expected_pins = {
    "androidx.test:runner": "1.5.1",
    "androidx.test:rules": "1.2.0",
    "androidx.test.espresso:espresso-core": "3.5.0",
}
if pins != expected_pins:
    die(f"lock-derived pin set is not exact: {pins}")
for coordinate, configs in lock_configs.items():
    if not profile_configs.issubset(configs):
        die(f"profile lock configurations are incomplete for {coordinate}")

tree = ET.parse(verification_path)
root = tree.getroot()
components = {}
for component in root.findall(".//{*}component"):
    coordinate = f"{component.attrib.get('group')}:{component.attrib.get('name')}"
    if coordinate not in pins or component.attrib.get("version") != pins[coordinate]:
        continue
    artifacts = {}
    for artifact in component.findall("{*}artifact"):
        name = artifact.attrib.get("name", "")
        suffix = pathlib.Path(name).suffix.lstrip(".")
        sha = artifact.find("{*}sha256")
        if suffix in {"aar", "pom"} and sha is not None:
            artifacts[suffix] = sha.attrib.get("value", "")
    if coordinate in components:
        die(f"duplicate verification component for {coordinate}")
    components[coordinate] = artifacts
if components != expected_artifacts:
    die("verification metadata does not attest the exact six AAR/POM hashes")

cache_root = gradle_home / "caches" / "modules-2" / "files-2.1"
cache_files = []
for coordinate, version in pins.items():
    group, name = coordinate.split(":", 1)
    version_root = cache_root / group / name / version
    for suffix, expected_hash in expected_artifacts[coordinate].items():
        matches = sorted(version_root.glob(f"*/{name}-{version}.{suffix}"))
        if len(matches) != 1 or matches[0].is_symlink() or not matches[0].is_file():
            die(f"cache miss or ambiguity for {coordinate}:{version}.{suffix}")
        observed = digest(matches[0])
        if observed != expected_hash:
            die(f"cache hash drift for {coordinate}:{version}.{suffix}")
        cache_files.append({
            "coordinate": coordinate,
            "version": version,
            "kind": suffix,
            "path": str(matches[0].resolve()),
            "sha256": observed,
        })

payload = {
    "schema_version": "manaloom.gradle_dynamic_selector_inputs.v1",
    "selectors": dict(sorted(dynamic.items())),
    "pins": dict(sorted(pins.items())),
    "profile_configurations": sorted(profile_configs),
    "lock_configurations": {key: lock_configs[key] for key in sorted(lock_configs)},
    "cache_files": sorted(cache_files, key=lambda item: (item["coordinate"], item["kind"])),
}
temporary = output_path.with_name(output_path.name + ".tmp")
temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
temporary.replace(output_path)
PY

  local init_hash
  init_hash="$(sha256_file "$INIT_SOURCE")"
  jq --arg flutter_sdk "$flutter_sdk" \
    --arg flutter_bin "$FLUTTER_BIN" \
    --arg dart_bin "$dart_bin" \
    --arg flutter_version_sha256 "$(sha256_file "$version_json")" \
    --arg plugin_path "$plugin_file" \
    --arg plugin_sha256 "$(sha256_file "$plugin_file")" \
    --arg lock_path "$lock_file" \
    --arg lock_sha256 "$(sha256_file "$lock_file")" \
    --arg verification_path "$verification_file" \
    --arg verification_sha256 "$(sha256_file "$verification_file")" \
    --arg app_settings_path "$app_settings" \
    --arg app_settings_sha256 "$(sha256_file "$app_settings")" \
    --arg flutter_settings_path "$flutter_settings" \
    --arg flutter_settings_sha256 "$(sha256_file "$flutter_settings")" \
    --arg root_build_path "$root_build" \
    --arg root_build_sha256 "$(sha256_file "$root_build")" \
    --arg app_build_path "$app_build" \
    --arg app_build_sha256 "$(sha256_file "$app_build")" \
    --arg main_manifest_path "$main_manifest" \
    --arg main_manifest_sha256 "$(sha256_file "$main_manifest")" \
    --arg release_manifest_path "$release_manifest" \
    --arg release_manifest_sha256 "$(sha256_file "$release_manifest")" \
    --arg profile_manifest_path "$profile_manifest" \
    --arg profile_manifest_sha256 "$(sha256_file "$profile_manifest")" \
    --arg push_guard_path "$push_guard" \
    --arg push_guard_sha256 "$(sha256_file "$push_guard")" \
    --arg init_path "$INIT_SOURCE" \
    --arg init_sha256 "$init_hash" \
    '. + {
      flutter: {
        version: "3.44.6", dart_version: "3.12.2",
        commit: "ee80f08bbf97172ec030b8751ceab557177a34a6",
        sdk: $flutter_sdk, flutter_bin: $flutter_bin, dart_bin: $dart_bin,
        version_manifest_sha256: $flutter_version_sha256
      },
      plugin: {path: $plugin_path, sha256: $plugin_sha256},
      lock: {path: $lock_path, sha256: $lock_sha256},
      verification_metadata: {path: $verification_path, sha256: $verification_sha256},
      build_roots: {app_root: ($app_settings_path | sub("/settings.gradle.kts$"; "")), flutter_tools_included: ($flutter_settings_path | sub("/settings.gradle.kts$"; ""))},
      settings: {
        app_root: {path: $app_settings_path, sha256: $app_settings_sha256},
        flutter_tools_included: {path: $flutter_settings_path, sha256: $flutter_settings_sha256}
      },
      release_semantics_inputs: {
        root_build: {path: $root_build_path, sha256: $root_build_sha256},
        app_build: {path: $app_build_path, sha256: $app_build_sha256},
        main_manifest: {path: $main_manifest_path, sha256: $main_manifest_sha256},
        release_manifest: {path: $release_manifest_path, sha256: $release_manifest_sha256},
        profile_manifest: {path: $profile_manifest_path, sha256: $profile_manifest_sha256},
        push_guard: {path: $push_guard_path, sha256: $push_guard_sha256}
      },
      init: {path: $init_path, sha256: $init_sha256}
    }' "$output" >"$output.enriched"
  mv "$output.enriched" "$output"
}

snapshot_protected_inputs() {
  local attestation="$1" output="$2"
  jq -r '[
      .flutter.sdk + "/bin/cache/flutter.version.json",
      .plugin.path,
      .lock.path,
      .verification_metadata.path,
      .settings.app_root.path,
      .settings.flutter_tools_included.path,
      .init.path,
      .release_semantics_inputs.root_build.path,
      .release_semantics_inputs.app_build.path,
      .release_semantics_inputs.main_manifest.path,
      .release_semantics_inputs.release_manifest.path,
      .release_semantics_inputs.profile_manifest.path,
      .release_semantics_inputs.push_guard.path
    ] + [.cache_files[].path] | unique[]' "$attestation" |
    while IFS= read -r path; do
      printf '%s\t%s\n' "$(sha256_file "$path")" "$path"
    done | LC_ALL=C sort >"$output"
}

snapshot_tree_inventory() {
  local root="$1" output="$2" require_read_only="$3"
  python3 - "$root" "$output" "$require_read_only" <<'PY'
import hashlib
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
require_read_only = sys.argv[3] == "true"
if not root.is_dir() or root.is_symlink():
    raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: cache inventory root is unsafe")
root = root.resolve()
records = []
for current, directory_names, file_names in os.walk(root):
    current_path = pathlib.Path(current)
    for name in directory_names:
        path = current_path / name
        if path.is_symlink():
            raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: cache directory symlink detected")
    for name in file_names:
        path = current_path / name
        if path.is_symlink() or not path.is_file():
            raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: cache file is unsafe")
        mode = stat.S_IMODE(path.stat().st_mode)
        if require_read_only and mode & 0o222:
            raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: read-only cache contains writable file")
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        records.append(
            f"{path.relative_to(root).as_posix()}\t{mode:04o}\t{digest.hexdigest()}"
        )
output.write_text("\n".join(sorted(records)) + ("\n" if records else ""), encoding="utf-8")
PY
}

snapshot_ephemeral_dependency_artifacts() {
  local root="$1" output="$2"
  python3 - "$root" "$output" <<'PY'
import hashlib
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
if not root.exists():
    output.write_text("", encoding="utf-8")
    raise SystemExit(0)
if not root.is_dir() or root.is_symlink():
    raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: writable dependency cache is unsafe")
records = []
for current, directory_names, file_names in os.walk(root):
    current_path = pathlib.Path(current)
    for name in directory_names:
        if (current_path / name).is_symlink():
            raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: writable cache directory symlink detected")
    for name in file_names:
        path = current_path / name
        if path.is_symlink() or not path.is_file():
            raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: writable cache file is unsafe")
        if name.endswith(".lock") or name == "gc.properties":
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        mode = stat.S_IMODE(path.stat().st_mode)
        records.append(
            f"{path.relative_to(root).as_posix()}\t{mode:04o}\t{digest}"
        )
output.write_text("\n".join(sorted(records)) + ("\n" if records else ""), encoding="utf-8")
if records:
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: writable cache contains dependency artifacts or metadata"
    )
PY
}

snapshot_optional_build_tree() {
  local root="$1" output="$2"
  python3 - "$root" "$output" <<'PY'
import hashlib
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
if not root.exists():
    if root.is_symlink():
        raise SystemExit(
            "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: app/build is a dangling symlink"
        )
    output.write_text("", encoding="utf-8")
    raise SystemExit(0)
if not root.is_dir() or root.is_symlink():
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: app/build inventory root is unsafe"
    )
records = []
root = root.resolve()
records.append(f".\tdir\t{stat.S_IMODE(root.stat().st_mode):04o}\t-")
for current, directory_names, file_names in os.walk(root):
    current_path = pathlib.Path(current)
    for name in sorted(directory_names):
        path = current_path / name
        if path.is_symlink() or not path.is_dir():
            raise SystemExit(
                "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: app/build directory is unsafe"
            )
        records.append(
            f"{path.relative_to(root).as_posix()}\tdir\t"
            f"{stat.S_IMODE(path.stat().st_mode):04o}\t-"
        )
    for name in sorted(file_names):
        path = current_path / name
        if path.is_symlink() or not path.is_file():
            raise SystemExit(
                "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: app/build file is unsafe"
            )
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        records.append(
            f"{path.relative_to(root).as_posix()}\tfile\t"
            f"{stat.S_IMODE(path.stat().st_mode):04o}\t{digest.hexdigest()}"
        )
output.write_text("\n".join(sorted(records)) + "\n", encoding="utf-8")
PY
}

verify_unified_log_window() {
  local telemetry_log="$1" run_id="$2" output="$3"
  require_regular_file "$telemetry_log" "sandbox unified-log window"
  [[ "$run_id" =~ ^gradle-profile-[0-9TZ-]+-[0-9]+-[0-9]+$ ]] ||
    fail "sandbox telemetry run identity is invalid"
  [[ ! -e "$output" && ! -L "$output" ]] ||
    fail "sandbox telemetry summary already exists"
  python3 - "$telemetry_log" "$run_id" "$output" <<'PY'
import hashlib
import json
import pathlib
import sys

telemetry_path = pathlib.Path(sys.argv[1])
run_id = sys.argv[2]
output_path = pathlib.Path(sys.argv[3])
marker = f"MANALOOM_GRADLE_NETWORK_ATTEMPT run_id={run_id}"
canary = f"MANALOOM_GRADLE_TELEMETRY_CANARY run_id={run_id}"
try:
    payload = json.loads(telemetry_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    raise SystemExit(
        f"NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: malformed sandbox telemetry: {error}"
    )
if not isinstance(payload, list):
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: sandbox telemetry is not a JSON array"
    )
findings = []
canary_events = []
for event in payload:
    if not isinstance(event, dict):
        raise SystemExit(
            "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: sandbox telemetry event is malformed"
        )
    message = event.get("eventMessage", event.get("composedMessage", ""))
    process = str(event.get("processImagePath", event.get("process", "")))
    message = str(message)
    if canary in message:
        if not (
            process == "/kernel"
            and message.startswith("Sandbox: ")
            and " deny(1) network-outbound " in message
            and message.endswith("\n" + canary)
        ):
            raise SystemExit(
                "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: sandbox-decision "
                "telemetry canary drift"
            )
        canary_events.append(event)
        continue
    if marker not in message:
        raise SystemExit(
            "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: sandbox telemetry is cross-run"
        )
    findings.append({
        "message": message[:500],
        "process": process[:500],
        "timestamp": str(event.get("timestamp", ""))[:100],
    })
if len(canary_events) != 1:
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: unified-log canary was not "
        "delivered exactly once"
    )
if findings:
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: sandbox unified log records "
        f"network attempts: {findings[:5]}"
    )
receipt = {
    "schema_version": "manaloom.gradle_sandbox_telemetry.v2",
    "run_id": run_id,
    "marker": marker,
    "canary": canary,
    "canary_entries": 1,
    "canary_source": "sandbox_denied_loopback_probe",
    "canary_process": "/kernel",
    "network_attempt_entries": 0,
    "total_entries": len(payload),
    "findings": [],
    "raw_sha256": hashlib.sha256(telemetry_path.read_bytes()).hexdigest(),
}
temporary = output_path.with_name(output_path.name + ".tmp")
temporary.write_text(
    json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
temporary.replace(output_path)
PY
}

validate_flutter_args() {
  [[ ${#FLUTTER_ARGS[@]} -ge 2 ]] || fail "Flutter build arguments are missing"
  [[ "${FLUTTER_ARGS[0]}" == "build" && "${FLUTTER_ARGS[1]}" == "apk" ]] ||
    fail "only flutter build apk is allowed"
  local joined=" ${FLUTTER_ARGS[*]} "
  [[ "$joined" == *" --profile "* ]] || fail "profile mode is required"
  [[ "$joined" == *" --no-pub "* ]] || fail "--no-pub is required"
  [[ "$joined" == *" --no-version-check "* ]] || fail "--no-version-check is required"
  [[ "$joined" == *" --target-platform=android-arm "* ]] ||
    fail "the governed android-arm target is required"
  [[ "$joined" == *" --target=integration_test/app_existing_user_visual_audit_test.dart "* ]] ||
    fail "the governed integration-test target is required"
  [[ "$joined" != *" --release "* && "$joined" != *" --debug "* ]] ||
    fail "release/debug builds are outside the adapter scope"
}

canonical_fresh_path() {
  local path="$1" label="$2" parent base resolved_parent
  require_absolute "$path" "$label"
  parent="$(dirname -- "$path")"
  base="$(basename -- "$path")"
  [[ -n "$base" && "$base" != "." && "$base" != ".." ]] ||
    fail "$label basename is invalid"
  [[ -d "$parent" ]] || fail "$label parent directory is absent"
  resolved_parent="$(CDPATH='' cd -- "$parent" && pwd -P)"
  printf '%s/%s\n' "$resolved_parent" "$base"
}

ADAPTER_APP_BUILD_ROOT=""
ADAPTER_APP_BUILD_BACKUP=""
ADAPTER_FRESH_BUILD_QUARANTINE=""
ADAPTER_APP_BUILD_BEFORE=""
ADAPTER_APP_BUILD_BACKUP_INVENTORY=""
ADAPTER_APP_BUILD_AFTER=""
ADAPTER_APP_BUILD_PREEXISTED=false
ADAPTER_BUILD_STATE="idle"
ADAPTER_BUILD_STATE_FILE=""
ADAPTER_RECOVERY_REQUIRED_FILE=""
ADAPTER_BUILD_PID=""
ADAPTER_BUILD_PGID=""
ADAPTER_BUILD_WAITED=true
ADAPTER_SIGNAL_REQUESTED=0
ADAPTER_CLEANUP_ACTIVE=false
ADAPTER_CLEANUP_COMPLETE=false
ADAPTER_CLEANUP_FAILED=false

adapter_write_build_state() {
  local state="$1" temporary
  ADAPTER_BUILD_STATE="$state"
  [[ -n "$ADAPTER_BUILD_STATE_FILE" ]] || return 0
  temporary="$ADAPTER_BUILD_STATE_FILE.tmp.$$"
  printf '%s\n' "$state" >"$temporary"
  mv "$temporary" "$ADAPTER_BUILD_STATE_FILE"
}

adapter_mark_recovery_required() {
  [[ -n "$ADAPTER_RECOVERY_REQUIRED_FILE" ]] || return 0
  printf 'state=%s\napp_build=%s\nbackup=%s\nfresh=%s\n' \
    "$ADAPTER_BUILD_STATE" "$ADAPTER_APP_BUILD_ROOT" \
    "$ADAPTER_APP_BUILD_BACKUP" "$ADAPTER_FRESH_BUILD_QUARANTINE" \
    >"$ADAPTER_RECOVERY_REQUIRED_FILE"
}

adapter_state_allows_fresh_build() {
  local state="${1:-$ADAPTER_BUILD_STATE}"
  case "$state" in
    build_started|build_finished|artifacts_externalized|cleanup_started|cleanup_complete)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

adapter_process_group_members() {
  [[ "$ADAPTER_BUILD_PGID" =~ ^[0-9]+$ ]] || return 0
  ps -axo pgid=,pid=,stat=,command= | awk -v group="$ADAPTER_BUILD_PGID" \
    '$1 == group && $3 !~ /^Z/ {sub(/^[[:space:]]+/, ""); print}'
}

adapter_build_leader_active() {
  local state
  [[ "$ADAPTER_BUILD_PID" =~ ^[0-9]+$ ]] || return 1
  state="$(ps -o stat= -p "$ADAPTER_BUILD_PID" 2>/dev/null | awk 'NR == 1 {print $1}')"
  [[ -n "$state" && "$state" != Z* ]]
}

adapter_assert_no_build_processes() {
  local members work_members
  members="$(adapter_process_group_members)"
  work_members=""
  if [[ -n "$WORK_DIR" ]]; then
    work_members="$(
      ps -axo pid=,ppid=,pgid=,command= |
        MANALOOM_PROCESS_SCAN_TOKEN="$WORK_DIR/gradle-user-home" \
        awk 'index($0, ENVIRON["MANALOOM_PROCESS_SCAN_TOKEN"]) {
          sub(/^[[:space:]]+/, ""); print
        }'
    )"
  fi
  [[ -z "$members" && -z "$work_members" ]]
}

adapter_stop_build_processes() {
  local remaining
  if [[ "$ADAPTER_BUILD_WAITED" != "true" &&
        "$ADAPTER_BUILD_PID" =~ ^[0-9]+$ ]]; then
    if [[ "$ADAPTER_BUILD_PGID" =~ ^[0-9]+$ ]]; then
      kill -TERM -- "-$ADAPTER_BUILD_PGID" >/dev/null 2>&1 || true
    fi
    kill -TERM "$ADAPTER_BUILD_PID" >/dev/null 2>&1 || true
    for _ in {1..50}; do
      remaining="$(adapter_process_group_members)"
      if [[ -z "$remaining" ]] && ! adapter_build_leader_active; then
        break
      fi
      /bin/sleep 0.1
    done
    remaining="$(adapter_process_group_members)"
    if [[ "$ADAPTER_BUILD_PGID" =~ ^[0-9]+$ ]]; then
      kill -KILL -- "-$ADAPTER_BUILD_PGID" >/dev/null 2>&1 || true
    fi
    if [[ -n "$remaining" ]] || adapter_build_leader_active; then
      kill -KILL "$ADAPTER_BUILD_PID" >/dev/null 2>&1 || true
    fi
    wait "$ADAPTER_BUILD_PID" >/dev/null 2>&1 || true
    ADAPTER_BUILD_WAITED=true
    for _ in {1..50}; do
      remaining="$(adapter_process_group_members)"
      [[ -z "$remaining" ]] && break
      /bin/sleep 0.1
    done
  fi
  adapter_assert_no_build_processes
}

adapter_cleanup_build_tree() {
  if [[ "$ADAPTER_CLEANUP_COMPLETE" == "true" ]]; then
    [[ "$ADAPTER_CLEANUP_FAILED" == "false" ]]
    return
  fi
  if [[ "$ADAPTER_CLEANUP_ACTIVE" == "true" ]]; then
    ADAPTER_CLEANUP_FAILED=true
    return 1
  fi
  ADAPTER_CLEANUP_ACTIVE=true
  local cleanup_failed=0 cleanup_entry_state="$ADAPTER_BUILD_STATE"
  adapter_write_build_state cleanup_started || cleanup_failed=1
  adapter_assert_no_build_processes || cleanup_failed=1

  if [[ -n "$ADAPTER_APP_BUILD_ROOT" && "$cleanup_failed" -eq 0 ]]; then
    if [[ -L "$ADAPTER_APP_BUILD_ROOT" ||
          ( -e "$ADAPTER_APP_BUILD_ROOT" && ! -d "$ADAPTER_APP_BUILD_ROOT" ) ||
          -L "$ADAPTER_APP_BUILD_BACKUP" ||
          ( -e "$ADAPTER_APP_BUILD_BACKUP" && ! -d "$ADAPTER_APP_BUILD_BACKUP" ) ||
          -L "$ADAPTER_FRESH_BUILD_QUARANTINE" ||
          ( -e "$ADAPTER_FRESH_BUILD_QUARANTINE" &&
            ! -d "$ADAPTER_FRESH_BUILD_QUARANTINE" ) ]]; then
      cleanup_failed=1
    fi
  fi

  if [[ -n "$ADAPTER_APP_BUILD_ROOT" && "$cleanup_failed" -eq 0 ]]; then
    if [[ "$ADAPTER_APP_BUILD_PREEXISTED" == "true" ]]; then
      if [[ -d "$ADAPTER_APP_BUILD_BACKUP" ]]; then
        if ! snapshot_optional_build_tree \
          "$ADAPTER_APP_BUILD_BACKUP" "$ADAPTER_APP_BUILD_BACKUP_INVENTORY"; then
          cleanup_failed=1
        elif ! cmp -s \
          "$ADAPTER_APP_BUILD_BEFORE" "$ADAPTER_APP_BUILD_BACKUP_INVENTORY"; then
          cleanup_failed=1
        elif [[ -d "$ADAPTER_APP_BUILD_ROOT" ]]; then
          if adapter_state_allows_fresh_build "$cleanup_entry_state" &&
             [[ ! -e "$ADAPTER_FRESH_BUILD_QUARANTINE" &&
                ! -L "$ADAPTER_FRESH_BUILD_QUARANTINE" ]]; then
            mv "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_FRESH_BUILD_QUARANTINE" ||
              cleanup_failed=1
          else
            cleanup_failed=1
          fi
        fi
        if [[ "$cleanup_failed" -eq 0 ]]; then
          [[ ! -e "$ADAPTER_APP_BUILD_ROOT" && ! -L "$ADAPTER_APP_BUILD_ROOT" ]] ||
            cleanup_failed=1
        fi
        if [[ "$cleanup_failed" -eq 0 ]]; then
          mv "$ADAPTER_APP_BUILD_BACKUP" "$ADAPTER_APP_BUILD_ROOT" ||
            cleanup_failed=1
        fi
      elif [[ -d "$ADAPTER_APP_BUILD_ROOT" &&
              "$cleanup_entry_state" =~ ^(initialized|quarantine_planned)$ ]]; then
        if ! snapshot_optional_build_tree \
          "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_APP_BUILD_AFTER"; then
          cleanup_failed=1
        elif ! cmp -s "$ADAPTER_APP_BUILD_BEFORE" "$ADAPTER_APP_BUILD_AFTER"; then
          cleanup_failed=1
        fi
      else
        cleanup_failed=1
      fi
      if [[ "$cleanup_failed" -eq 0 ]]; then
        if ! snapshot_optional_build_tree \
          "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_APP_BUILD_AFTER"; then
          cleanup_failed=1
        elif ! cmp -s "$ADAPTER_APP_BUILD_BEFORE" "$ADAPTER_APP_BUILD_AFTER"; then
          cleanup_failed=1
        fi
      fi
    else
      [[ ! -e "$ADAPTER_APP_BUILD_BACKUP" &&
         ! -L "$ADAPTER_APP_BUILD_BACKUP" ]] || cleanup_failed=1
      if [[ -d "$ADAPTER_APP_BUILD_ROOT" ]]; then
        if adapter_state_allows_fresh_build "$cleanup_entry_state" &&
           [[ ! -e "$ADAPTER_FRESH_BUILD_QUARANTINE" &&
              ! -L "$ADAPTER_FRESH_BUILD_QUARANTINE" ]]; then
          mv "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_FRESH_BUILD_QUARANTINE" ||
            cleanup_failed=1
        else
          cleanup_failed=1
        fi
      fi
      [[ ! -e "$ADAPTER_APP_BUILD_ROOT" && ! -L "$ADAPTER_APP_BUILD_ROOT" ]] ||
        cleanup_failed=1
      : >"$ADAPTER_APP_BUILD_AFTER"
    fi
  fi

  if [[ "$cleanup_failed" -eq 0 &&
        -d "$ADAPTER_FRESH_BUILD_QUARANTINE" &&
        ! -L "$ADAPTER_FRESH_BUILD_QUARANTINE" ]]; then
    find "$ADAPTER_FRESH_BUILD_QUARANTINE" -depth -delete || cleanup_failed=1
  fi
  [[ -z "$ADAPTER_FRESH_BUILD_QUARANTINE" ||
     ( ! -e "$ADAPTER_FRESH_BUILD_QUARANTINE" &&
       ! -L "$ADAPTER_FRESH_BUILD_QUARANTINE" ) ]] || cleanup_failed=1
  [[ -z "$ADAPTER_APP_BUILD_BACKUP" ||
     ( ! -e "$ADAPTER_APP_BUILD_BACKUP" &&
       ! -L "$ADAPTER_APP_BUILD_BACKUP" ) ]] || cleanup_failed=1

  ADAPTER_CLEANUP_ACTIVE=false
  ADAPTER_CLEANUP_COMPLETE=true
  if [[ "$cleanup_failed" -ne 0 ]]; then
    ADAPTER_CLEANUP_FAILED=true
    adapter_mark_recovery_required || true
    return 1
  fi
  ADAPTER_CLEANUP_FAILED=false
  adapter_write_build_state cleanup_complete || {
    ADAPTER_CLEANUP_FAILED=true
    adapter_mark_recovery_required || true
    return 1
  }
  return 0
}

adapter_finalize() {
  local original_exit="$?"
  trap - EXIT
  trap '' HUP INT TERM QUIT
  if ! adapter_stop_build_processes; then
    adapter_mark_recovery_required || true
    original_exit=1
  elif ! adapter_cleanup_build_tree; then
    original_exit=1
  fi
  exit "$original_exit"
}

adapter_signal_exit() {
  ADAPTER_SIGNAL_REQUESTED="$1"
  if [[ "$ADAPTER_CLEANUP_ACTIVE" != "true" ]]; then
    exit "$1"
  fi
}

run_adapter() {
  for tool in awk chmod cmp cp date find git jq mktemp mv python3 sed shasum stat tee; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
  done
  [[ -x /usr/bin/log ]] || fail "macOS unified-log reader is unavailable"
  for value_label in \
    "$GRADLE_SOURCE_HOME|Gradle source home" "$WORK_DIR|work directory" \
    "$BUILD_LOG|build log" "$RECEIPT|receipt" "$APK_PATH|APK" \
    "$MERGED_MANIFEST|merged manifest" "$APK_MANIFEST|APK manifest" \
    "$APKANALYZER_BIN|apkanalyzer"; do
    value="${value_label%%|*}"
    label="${value_label#*|}"
    require_absolute "$value" "$label"
  done
  [[ -d "$GRADLE_SOURCE_HOME" && ! -L "$GRADLE_SOURCE_HOME" ]] || fail "Gradle source home is unsafe"
  [[ -x "$APKANALYZER_BIN" && ! -L "$APKANALYZER_BIN" ]] || fail "apkanalyzer is unavailable"
  validate_flutter_args
  validate_static_inputs >/dev/null

  WORK_DIR="$(canonical_fresh_path "$WORK_DIR" "work directory")"
  BUILD_LOG="$(canonical_fresh_path "$BUILD_LOG" "build log")"
  RECEIPT="$(canonical_fresh_path "$RECEIPT" "receipt")"
  APK_PATH="$(canonical_fresh_path "$APK_PATH" "APK")"
  MERGED_MANIFEST="$(canonical_fresh_path "$MERGED_MANIFEST" "merged manifest")"
  APK_MANIFEST="$(canonical_fresh_path "$APK_MANIFEST" "APK manifest")"
  local governed_paths=(
    "$WORK_DIR" "$BUILD_LOG" "$RECEIPT" "$APK_PATH"
    "$MERGED_MANIFEST" "$APK_MANIFEST"
  )
  local path_index other_index
  for ((path_index = 0; path_index < ${#governed_paths[@]}; path_index++)); do
    for ((other_index = path_index + 1; other_index < ${#governed_paths[@]}; other_index++)); do
      [[ "${governed_paths[$path_index]}" != "${governed_paths[$other_index]}" ]] ||
        fail "work and evidence paths must be pairwise distinct"
    done
  done
  for output in "$BUILD_LOG" "$RECEIPT" "$APK_PATH" "$MERGED_MANIFEST" "$APK_MANIFEST"; do
    [[ "$output" != "$WORK_DIR/"* ]] ||
      fail "evidence outputs must be outside the adapter work directory"
  done
  [[ ! -e "$WORK_DIR" && ! -L "$WORK_DIR" ]] ||
    fail "adapter work directory already exists"
  for output in "$BUILD_LOG" "$RECEIPT" "$APK_PATH" "$MERGED_MANIFEST" "$APK_MANIFEST"; do
    [[ ! -e "$output" && ! -L "$output" ]] || fail "fresh output precondition failed: $output"
    [[ "$output" != "$APP_DIR/build" && "$output" != "$APP_DIR/build/"* ]] ||
      fail "governed outputs must be outside app/build"
  done
  [[ "$WORK_DIR" != "$APP_DIR/build" && "$WORK_DIR" != "$APP_DIR/build/"* ]] ||
    fail "adapter work directory must be outside app/build"

  ADAPTER_APP_BUILD_ROOT="$APP_DIR/build"
  ADAPTER_CLEANUP_ACTIVE=false
  ADAPTER_CLEANUP_COMPLETE=false
  ADAPTER_CLEANUP_FAILED=false
  ADAPTER_BUILD_STATE="idle"
  ADAPTER_BUILD_STATE_FILE=""
  ADAPTER_RECOVERY_REQUIRED_FILE=""
  ADAPTER_BUILD_PID=""
  ADAPTER_BUILD_PGID=""
  ADAPTER_BUILD_WAITED=true
  ADAPTER_SIGNAL_REQUESTED=0
  trap adapter_finalize EXIT
  trap 'adapter_signal_exit 129' HUP
  trap 'adapter_signal_exit 130' INT
  trap 'adapter_signal_exit 143' TERM
  trap 'adapter_signal_exit 131' QUIT

  mkdir -p "$WORK_DIR"
  WORK_DIR="$(CDPATH='' cd -- "$WORK_DIR" && pwd -P)"
  chmod 700 "$WORK_DIR"
  python3 - "$APP_DIR" "$WORK_DIR" <<'PY'
import os
import pathlib
import sys

app = pathlib.Path(sys.argv[1])
work = pathlib.Path(sys.argv[2])
if os.stat(app).st_dev != os.stat(work).st_dev:
    raise SystemExit(
        "NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: work directory must share "
        "the app filesystem for atomic build quarantine"
    )
PY
  ADAPTER_BUILD_STATE_FILE="$WORK_DIR/app-build.state"
  ADAPTER_RECOVERY_REQUIRED_FILE="$WORK_DIR/RECOVERY_REQUIRED"
  ADAPTER_APP_BUILD_BACKUP="$WORK_DIR/preexisting-app-build"
  ADAPTER_FRESH_BUILD_QUARANTINE="$WORK_DIR/fresh-app-build-owned"
  ADAPTER_APP_BUILD_BEFORE="$WORK_DIR/app-build.before.tsv"
  ADAPTER_APP_BUILD_BACKUP_INVENTORY="$WORK_DIR/app-build.backup.tsv"
  ADAPTER_APP_BUILD_AFTER="$WORK_DIR/app-build.after.tsv"
  adapter_write_build_state initialized
  snapshot_optional_build_tree "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_APP_BUILD_BEFORE"
  if [[ -d "$ADAPTER_APP_BUILD_ROOT" && ! -L "$ADAPTER_APP_BUILD_ROOT" ]]; then
    ADAPTER_APP_BUILD_PREEXISTED=true
  elif [[ ! -e "$ADAPTER_APP_BUILD_ROOT" && ! -L "$ADAPTER_APP_BUILD_ROOT" ]]; then
    ADAPTER_APP_BUILD_PREEXISTED=false
  else
    fail "application build tree is unsafe and cannot be quarantined"
  fi
  adapter_write_build_state quarantine_planned
  if [[ "$ADAPTER_APP_BUILD_PREEXISTED" == "true" ]]; then
    mv "$ADAPTER_APP_BUILD_ROOT" "$ADAPTER_APP_BUILD_BACKUP" ||
      fail "could not quarantine the preexisting app/build tree"
    adapter_write_build_state original_quarantined
    snapshot_optional_build_tree \
      "$ADAPTER_APP_BUILD_BACKUP" "$ADAPTER_APP_BUILD_BACKUP_INVENTORY"
    cmp -s "$ADAPTER_APP_BUILD_BEFORE" "$ADAPTER_APP_BUILD_BACKUP_INVENTORY" ||
      fail "app/build quarantine inventory drift"
  else
    : >"$ADAPTER_APP_BUILD_BACKUP_INVENTORY"
    adapter_write_build_state original_absent
  fi
  [[ ! -e "$ADAPTER_APP_BUILD_ROOT" && ! -L "$ADAPTER_APP_BUILD_ROOT" ]] ||
    fail "fresh app/build precondition failed after quarantine"
  local inputs="$WORK_DIR/inputs.json"
  write_input_attestation "$inputs"
  local before="$WORK_DIR/protected-inputs.before.tsv"
  local after="$WORK_DIR/protected-inputs.after.tsv"
  snapshot_protected_inputs "$inputs" "$before"

  local run_id
  run_id="gradle-profile-$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"
  local gradle_home="$WORK_DIR/gradle-user-home"
  local ro_cache="$WORK_DIR/ro-cache"
  local events="$WORK_DIR/events"
  local config="$WORK_DIR/config.json"
  local sandbox_profile="$WORK_DIR/deny-all-network.sb"
  local source_dist="$GRADLE_SOURCE_HOME/wrapper/dists/gradle-$EXPECTED_GRADLE_VERSION-all"
  local source_cache_before="$WORK_DIR/source-cache.before.tsv"
  local source_cache_after="$WORK_DIR/source-cache.after.tsv"
  local ro_cache_before="$WORK_DIR/ro-cache.before.tsv"
  local ro_cache_after="$WORK_DIR/ro-cache.after.tsv"
  local writable_cache_before="$WORK_DIR/writable-cache.before.tsv"
  local writable_cache_after="$WORK_DIR/writable-cache.after.tsv"
  local telemetry_log="$WORK_DIR/sandbox-unified-log.json"
  local telemetry_stderr="$WORK_DIR/sandbox-unified-log.stderr"
  local telemetry_summary="$WORK_DIR/sandbox-unified-log-summary.json"
  local telemetry_canary_stderr="$WORK_DIR/sandbox-canary.stderr"
  local build_process_identity="$WORK_DIR/build-process.json"
  local generated_apk="$APP_DIR/build/app/outputs/flutter-apk/app-profile.apk"
  local generated_merged_manifest="$APP_DIR/build/app/intermediates/merged_manifest/profile/processProfileMainManifest/AndroidManifest.xml"
  [[ -d "$GRADLE_SOURCE_HOME/caches/modules-2" && -d "$source_dist" ]] ||
    fail "Gradle 8.14 distribution or dependency cache is absent"
  snapshot_tree_inventory \
    "$GRADLE_SOURCE_HOME/caches/modules-2" "$source_cache_before" false
  mkdir -p "$gradle_home/init.d" "$gradle_home/wrapper/dists" "$ro_cache" "$events"
  cp -cR "$source_dist" "$gradle_home/wrapper/dists/"
  cp -cR "$GRADLE_SOURCE_HOME/caches/modules-2" "$ro_cache/"
  find "$ro_cache" -type f \( -name '*.lock' -o -name 'gc.properties' \) -delete
  chmod -R a-w "$ro_cache"
  snapshot_tree_inventory "$ro_cache/modules-2" "$ro_cache_before" true
  snapshot_ephemeral_dependency_artifacts \
    "$gradle_home/caches/modules-2" "$writable_cache_before"
  install -m 0444 "$INIT_SOURCE" "$gradle_home/init.d/manaloom-gradle-dynamic-selector-pins.init.gradle"
  local init_copy_sha
  init_copy_sha="$(sha256_file "$gradle_home/init.d/manaloom-gradle-dynamic-selector-pins.init.gradle")"
  [[ "$init_copy_sha" == "$(jq -r '.init.sha256' "$inputs")" ]] || fail "ephemeral init copy drift"

  jq --null-input \
    --arg run_id "$run_id" \
    --arg event_directory "$events" \
    --arg init_sha256 "$init_copy_sha" \
    --arg app_root "$(jq -r '.build_roots.app_root' "$inputs")" \
    --arg flutter_root "$(jq -r '.build_roots.flutter_tools_included' "$inputs")" \
    --arg app_settings_sha "$(jq -r '.settings.app_root.sha256' "$inputs")" \
    --arg flutter_settings_sha "$(jq -r '.settings.flutter_tools_included.sha256' "$inputs")" \
    --arg gradle_version "$EXPECTED_GRADLE_VERSION" \
    --argjson selectors "$(jq '.selectors' "$inputs")" \
    --argjson pins "$(jq '.pins' "$inputs")" \
    --argjson profile_configurations "$(jq '.profile_configurations' "$inputs")" \
    '{
      schema_version: "manaloom.gradle_dynamic_selector_adapter_config.v1",
      run_id: $run_id,
      event_directory: $event_directory,
      init_sha256: $init_sha256,
      gradle_version: $gradle_version,
      selectors: $selectors,
      pins: $pins,
      profile_configurations: $profile_configurations,
      build_roots: {app_root: $app_root, flutter_tools_included: $flutter_root},
      settings_sha256: {app_root: $app_settings_sha, flutter_tools_included: $flutter_settings_sha}
    }' >"$config"
  chmod 600 "$config"
  local config_before_sha init_copy_before_sha
  config_before_sha="$(sha256_file "$config")"
  init_copy_before_sha="$(sha256_file "$gradle_home/init.d/manaloom-gradle-dynamic-selector-pins.init.gradle")"

  local flutter_sdk
  flutter_sdk="$(jq -r '.flutter.sdk' "$inputs")"
  local telemetry_marker="MANALOOM_GRADLE_NETWORK_ATTEMPT run_id=$run_id"
  local telemetry_canary="MANALOOM_GRADLE_TELEMETRY_CANARY run_id=$run_id"
  escape_scheme() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
  printf '%s\n' \
    '(version 1)' \
    '(allow default)' \
    "(deny network* (with telemetry) (with message \"$telemetry_marker\"))" \
    "(deny network-outbound (remote ip \"localhost:9\") (with telemetry) (with message \"$telemetry_canary\"))" \
    "(deny file-write* (subpath \"$(escape_scheme "$flutter_sdk")\"))" \
    "(deny file-write* (subpath \"$(escape_scheme "$GRADLE_SOURCE_HOME")\"))" \
    >"$sandbox_profile"
  chmod 600 "$sandbox_profile"

  local started_at telemetry_started_at telemetry_finished_at
  started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  telemetry_started_at="$(date -u '+%Y-%m-%d %H:%M:%S+0000')"
  local build_exit
  adapter_write_build_state build_started
  set +e
  (
    cd "$APP_DIR"
    exec env \
      -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      -u http_proxy -u https_proxy -u all_proxy \
      CI=true \
      DART_DISABLE_ANALYTICS=1 \
      DART_SUPPRESS_ANALYTICS=true \
      GRADLE_USER_HOME="$gradle_home" \
      GRADLE_RO_DEP_CACHE="$ro_cache" \
      MANALOOM_GRADLE_DYNAMIC_SELECTOR_CONFIG="$config" \
      python3 - "$BUILD_LOG" "$build_process_identity" \
        "$sandbox_profile" "$FLUTTER_BIN" "${FLUTTER_ARGS[@]}"
  ) <<'PY' &
import json
import os
import pathlib
import sys

log_path = pathlib.Path(sys.argv[1])
identity_path = pathlib.Path(sys.argv[2])
sandbox_profile = sys.argv[3]
flutter_bin = sys.argv[4]
flutter_args = sys.argv[5:]
log_fd = os.open(log_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
os.setsid()
payload = {
    "schema_version": "manaloom.gradle_build_process.v1",
    "pid": os.getpid(),
    "pgid": os.getpgrp(),
}
temporary = identity_path.with_name(identity_path.name + f".tmp.{os.getpid()}")
temporary.write_text(json.dumps(payload, sort_keys=True) + "\n", encoding="utf-8")
temporary.replace(identity_path)
os.dup2(log_fd, 1)
os.dup2(log_fd, 2)
os.close(log_fd)
os.execv(
    "/usr/bin/sandbox-exec",
    ["sandbox-exec", "-f", sandbox_profile, flutter_bin, *flutter_args],
)
PY
  # The Python launcher calls setsid(), so its PID is the reserved process-group
  # identity. Own it immediately: a signal must not wait for identity-file I/O.
  ADAPTER_BUILD_PID="$!" ADAPTER_BUILD_PGID="$!"
  ADAPTER_BUILD_WAITED=false
  for _ in {1..100}; do
    [[ -f "$build_process_identity" && ! -L "$build_process_identity" ]] && break
    kill -0 "$ADAPTER_BUILD_PID" >/dev/null 2>&1 || break
    /bin/sleep 0.05
  done
  if [[ ! -f "$build_process_identity" || -L "$build_process_identity" ]]; then
    wait "$ADAPTER_BUILD_PID"
    build_exit="$?"
    ADAPTER_BUILD_WAITED=true
    set -e
    fail "profile build process group did not publish its identity (exit $build_exit)"
  fi
  local observed_build_pid observed_build_pgid
  observed_build_pid="$(jq -r '.pid // empty' "$build_process_identity")"
  observed_build_pgid="$(jq -r '.pgid // empty' "$build_process_identity")"
  [[ "$(jq -r '.schema_version // empty' "$build_process_identity")" == \
       "manaloom.gradle_build_process.v1" &&
     "$observed_build_pid" == "$ADAPTER_BUILD_PID" &&
     "$observed_build_pgid" == "$ADAPTER_BUILD_PID" ]] || {
    set -e
    fail "profile build process identity is malformed or cross-run"
  }
  wait "$ADAPTER_BUILD_PID"
  build_exit="$?"
  ADAPTER_BUILD_WAITED=true
  set -e
  adapter_assert_no_build_processes ||
    fail "profile build process group or descendant survived wait"
  adapter_write_build_state build_finished

  local telemetry_canary_exit
  set +e
  /usr/bin/sandbox-exec -f "$sandbox_profile" /usr/bin/python3 -c '
import errno
import socket
import sys

probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    probe.connect(("127.0.0.1", 9))
except PermissionError as error:
    if error.errno != errno.EPERM:
        raise
    sys.stderr.write("SANDBOX_CANARY_DENIED errno=1\n")
    raise SystemExit(73)
except OSError as error:
    sys.stderr.write(f"SANDBOX_CANARY_UNEXPECTED errno={error.errno}\n")
    raise SystemExit(74)
else:
    sys.stderr.write("SANDBOX_CANARY_UNEXPECTED connected\n")
    raise SystemExit(75)
finally:
    probe.close()
' >/dev/null 2>"$telemetry_canary_stderr"
  telemetry_canary_exit="$?"
  set -e
  [[ "$telemetry_canary_exit" -eq 73 &&
     "$(<"$telemetry_canary_stderr")" == "SANDBOX_CANARY_DENIED errno=1" ]] ||
    fail "sandbox-decision telemetry canary was not denied locally"

  local telemetry_stable_count=0 telemetry_previous_sha="" telemetry_current_sha
  for _ in {1..30}; do
    /bin/sleep 0.5
    telemetry_finished_at="$(date -u '+%Y-%m-%d %H:%M:%S+0000')"
    /usr/bin/log show \
      --style json \
      --info \
      --debug \
      --no-pager \
      --start "$telemetry_started_at" \
      --end "$telemetry_finished_at" \
      --predicate "eventMessage CONTAINS \"$telemetry_marker\" OR eventMessage CONTAINS \"$telemetry_canary\"" \
      >"$telemetry_log.next" 2>"$telemetry_stderr.next" ||
      fail "could not read the run-bound sandbox unified-log window"
    [[ ! -s "$telemetry_stderr.next" ]] ||
      fail "sandbox unified-log reader emitted diagnostics"
    jq -e --arg canary "$telemetry_canary" --arg marker "$telemetry_marker" '
      type == "array" and
      ([.[] | select(
        ((.eventMessage // .composedMessage // "") | contains($canary)) and
        (.processImagePath == "/kernel") and
        ((.eventMessage // .composedMessage // "") | startswith("Sandbox: ")) and
        ((.eventMessage // .composedMessage // "") | contains(" deny(1) network-outbound "))
      )] | length) == 1 and
      ([.[] | select(
        (.eventMessage // .composedMessage // "") | contains($marker)
      )] | length) == 0
    ' "$telemetry_log.next" >/dev/null || {
      if jq -e --arg marker "$telemetry_marker" '
        [.[] | select(
          (.eventMessage // .composedMessage // "") | contains($marker)
        )] | length > 0
      ' "$telemetry_log.next" >/dev/null 2>&1; then
        fail "sandbox unified log records a network attempt"
      fi
      telemetry_stable_count=0
      telemetry_previous_sha=""
      continue
    }
    telemetry_current_sha="$(sha256_file "$telemetry_log.next")"
    if [[ "$telemetry_current_sha" == "$telemetry_previous_sha" ]]; then
      telemetry_stable_count=$((telemetry_stable_count + 1))
    else
      telemetry_stable_count=1
      telemetry_previous_sha="$telemetry_current_sha"
    fi
    if [[ "$telemetry_stable_count" -ge 4 ]]; then
      mv "$telemetry_log.next" "$telemetry_log"
      mv "$telemetry_stderr.next" "$telemetry_stderr"
      break
    fi
  done
  [[ "$telemetry_stable_count" -ge 4 &&
     -f "$telemetry_log" && -f "$telemetry_stderr" ]] ||
    fail "sandbox unified-log channel did not deliver and drain the run-bound canary"
  [[ ! -s "$telemetry_stderr" ]] ||
    fail "sandbox unified-log reader emitted diagnostics"
  verify_unified_log_window "$telemetry_log" "$run_id" "$telemetry_summary"

  if [[ "$build_exit" -eq 0 ]]; then
    require_regular_file "$generated_apk" "fresh generated profile APK"
    require_regular_file "$generated_merged_manifest" "fresh generated merged profile manifest"
    cp "$generated_apk" "$APK_PATH"
    cp "$generated_merged_manifest" "$MERGED_MANIFEST"
    require_regular_file "$APK_PATH" "externalized profile APK"
    require_regular_file "$MERGED_MANIFEST" "externalized merged profile manifest"
    "$APKANALYZER_BIN" manifest print "$APK_PATH" >"$APK_MANIFEST"
    adapter_write_build_state artifacts_externalized
  fi
  snapshot_protected_inputs "$inputs" "$after"
  cmp -s "$before" "$after" || fail "SDK, lock, metadata or global cache mutated"
  snapshot_tree_inventory \
    "$GRADLE_SOURCE_HOME/caches/modules-2" "$source_cache_after" false
  cmp -s "$source_cache_before" "$source_cache_after" ||
    fail "global Gradle dependency cache mutated"
  snapshot_tree_inventory "$ro_cache/modules-2" "$ro_cache_after" true
  cmp -s "$ro_cache_before" "$ro_cache_after" ||
    fail "ephemeral read-only dependency cache mutated"
  snapshot_ephemeral_dependency_artifacts \
    "$gradle_home/caches/modules-2" "$writable_cache_after"
  cmp -s "$writable_cache_before" "$writable_cache_after" ||
    fail "ephemeral writable dependency cache gained artifacts"
  local config_after_sha init_copy_after_sha
  config_after_sha="$(sha256_file "$config")"
  init_copy_after_sha="$(sha256_file "$gradle_home/init.d/manaloom-gradle-dynamic-selector-pins.init.gradle")"
  [[ "$config_before_sha" == "$config_after_sha" &&
     "$init_copy_before_sha" == "$init_copy_after_sha" ]] ||
    fail "adapter config or init copy mutated during build"
  [[ "$ADAPTER_SIGNAL_REQUESTED" -eq 0 ]] ||
    fail "signal received before application build tree cleanup"
  adapter_cleanup_build_tree ||
    fail "application build tree cleanup or exact restoration failed"
  [[ "$ADAPTER_SIGNAL_REQUESTED" -eq 0 ]] ||
    fail "signal received during application build tree cleanup"

  python3 - "$inputs" "$config" "$events" "$BUILD_LOG" "$build_exit" \
    "$APK_PATH" "$MERGED_MANIFEST" "$APK_MANIFEST" "$POLICY_FILE" \
    "$RECEIPT" "$started_at" "$before" "$after" "$sandbox_profile" \
    "$source_cache_before" "$source_cache_after" \
    "$ro_cache_before" "$ro_cache_after" \
    "$writable_cache_before" "$writable_cache_after" \
    "$config_before_sha" "$config_after_sha" \
    "$init_copy_before_sha" "$init_copy_after_sha" \
    "$telemetry_summary" "$telemetry_log" "$telemetry_stderr" \
    "$telemetry_started_at" "$telemetry_finished_at" \
    "$ADAPTER_APP_BUILD_BEFORE" "$ADAPTER_APP_BUILD_AFTER" \
    "$ADAPTER_APP_BUILD_BACKUP_INVENTORY" \
    "$ADAPTER_APP_BUILD_PREEXISTED" \
    "$build_process_identity" "$ADAPTER_BUILD_STATE_FILE" \
    "$ADAPTER_RECOVERY_REQUIRED_FILE" <<'PY'
import hashlib
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from urllib.parse import urlsplit

args = sys.argv[1:]
if len(args) != 36:
    raise SystemExit("NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: verifier argv is incomplete")
inputs_path = pathlib.Path(args[0])
config_path = pathlib.Path(args[1])
events_path = pathlib.Path(args[2])
build_log_path = pathlib.Path(args[3])
build_exit = int(args[4])
apk_path = pathlib.Path(args[5])
merged_path = pathlib.Path(args[6])
packaged_path = pathlib.Path(args[7])
policy_path = pathlib.Path(args[8])
receipt_path = pathlib.Path(args[9])
started_at = args[10]
before_path = pathlib.Path(args[11])
after_path = pathlib.Path(args[12])
sandbox_path = pathlib.Path(args[13])
source_cache_before_path = pathlib.Path(args[14])
source_cache_after_path = pathlib.Path(args[15])
ro_cache_before_path = pathlib.Path(args[16])
ro_cache_after_path = pathlib.Path(args[17])
writable_cache_before_path = pathlib.Path(args[18])
writable_cache_after_path = pathlib.Path(args[19])
config_before_sha = args[20]
config_after_sha = args[21]
init_copy_before_sha = args[22]
init_copy_after_sha = args[23]
telemetry_summary_path = pathlib.Path(args[24])
telemetry_log_path = pathlib.Path(args[25])
telemetry_stderr_path = pathlib.Path(args[26])
telemetry_started_at = args[27]
telemetry_finished_at = args[28]
app_build_before_path = pathlib.Path(args[29])
app_build_after_path = pathlib.Path(args[30])
app_build_backup_path = pathlib.Path(args[31])
app_build_preexisted = args[32] == "true"
build_process_identity_path = pathlib.Path(args[33])
app_build_state_path = pathlib.Path(args[34])
recovery_required_path = pathlib.Path(args[35])

def die(message):
    raise SystemExit(f"NO_GO_GRADLE_DYNAMIC_SELECTOR_ADAPTER: {message}")

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

inputs = json.loads(inputs_path.read_text(encoding="utf-8"))
config = json.loads(config_path.read_text(encoding="utf-8"))
policy = json.loads(policy_path.read_text(encoding="utf-8"))
run_id = config.get("run_id")
init_copy_path = events_path.parent / "gradle-user-home" / "init.d" / "manaloom-gradle-dynamic-selector-pins.init.gradle"
if not init_copy_path.is_file() or init_copy_path.is_symlink():
    die("ephemeral Gradle init copy is unsafe")
if not (
    config_before_sha == config_after_sha == digest(config_path)
    and init_copy_before_sha == init_copy_after_sha == digest(init_copy_path)
    and init_copy_before_sha == inputs["init"]["sha256"]
):
    die("adapter config or init copy hash drift")
if build_exit != 0:
    die(f"profile build failed with exit {build_exit}")
for path, label in [
    (build_log_path, "build log"), (apk_path, "APK"),
    (merged_path, "merged manifest"), (packaged_path, "packaged manifest"),
]:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        die(f"{label} is missing, empty or unsafe")

events = []
event_files = sorted(events_path.glob("*.jsonl"))
if len(event_files) != 2:
    die(f"expected exactly two Gradle settings roots, got {len(event_files)}")
for event_file in event_files:
    if event_file.is_symlink() or not event_file.is_file():
        die("event file is unsafe")
    for line in event_file.read_text(encoding="utf-8").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError as error:
            die(f"malformed Gradle event: {error}")
        if event.get("schema_version") != "manaloom.gradle_dynamic_selector_adapter_event.v1" or event.get("run_id") != run_id:
            die("Gradle event is malformed or cross-run")
        events.append(event)

roots = [event for event in events if event.get("type") == "settings_root"]
if len(roots) != 2 or {event.get("role") for event in roots} != {"app_root", "flutter_tools_included"}:
    die("Gradle settings root set is missing, duplicate or unexpected")
for event in roots:
    role = event["role"]
    if event.get("root") != config["build_roots"][role] or event.get("settings_sha256") != config["settings_sha256"][role]:
        die(f"Gradle settings root identity drift for {role}")
    if event.get("gradle_version") != "8.14" or event.get("offline") is not True or event.get("init_sha256") != config["init_sha256"]:
        die(f"Gradle settings root attestation drift for {role}")

expected_declarations = {
    (coordinate, selector, inputs["pins"][coordinate])
    for coordinate, selector in inputs["selectors"].items()
}
declaration_events = [event for event in events if event.get("type") == "dynamic_declaration"]
declarations = {
    (event.get("coordinate"), event.get("requested"), event.get("pin"))
    for event in declaration_events
}
if len(declaration_events) != 3 or declarations != expected_declarations:
    die(f"dynamic declaration set is not exact: {sorted(declarations)}")
for event in declaration_events:
    if event.get("root_role") != "app_root" or event.get("project") != ":integration_test" or event.get("configuration") != "api":
        die("dynamic declaration escaped :integration_test:api")

substitutions = [event for event in events if event.get("type") == "substitution"]
required_substitutions = {
    (":integration_test", configuration, coordinate, inputs["selectors"][coordinate], inputs["pins"][coordinate])
    for configuration in ("profileCompileClasspath", "profileRuntimeClasspath")
    for coordinate in inputs["selectors"]
}
actual_substitutions = {
    (event.get("project"), event.get("configuration"), event.get("coordinate"), event.get("requested"), event.get("pin"))
    for event in substitutions
}
if len(substitutions) != len(actual_substitutions):
    die("profile substitution event set contains duplicates")
if not required_substitutions.issubset(actual_substitutions):
    die(f"required profile substitution set is incomplete: {sorted(actual_substitutions)}")
if any(
    event.get("root_role") != "app_root" or
    event.get("project") not in {":app", ":integration_test"} or
    event.get("configuration") not in inputs["profile_configurations"] or
    event.get("scope") != "project" or
    event.get("coordinate") not in inputs["selectors"] or
    event.get("requested") != inputs["selectors"][event.get("coordinate")] or
    event.get("pin") != inputs["pins"][event.get("coordinate")]
    for event in substitutions
):
    die("selector substitution escaped the governed profile graphs")
for project, configuration in {
    (event.get("project"), event.get("configuration")) for event in substitutions
}:
    coordinates = {
        event.get("coordinate") for event in substitutions
        if event.get("project") == project and event.get("configuration") == configuration
    }
    if coordinates != set(inputs["selectors"]):
        die(f"profile substitution coordinate set is incomplete in {project}:{configuration}")

graphs = [event for event in events if event.get("type") == "resolved_graph"]
graph_keys = [(event.get("project"), event.get("configuration")) for event in graphs]
required_graph_keys = {
    (":integration_test", "profileCompileClasspath"),
    (":integration_test", "profileRuntimeClasspath"),
}
allowed_graph_keys = required_graph_keys | {
    (":app", "profileCompileClasspath"),
    (":app", "profileRuntimeClasspath"),
}
if (
    len(graph_keys) != len(set(graph_keys))
    or not required_graph_keys.issubset(set(graph_keys))
    or not set(graph_keys).issubset(allowed_graph_keys)
):
    die("resolved profile graph set is incomplete, duplicate or unexpected")
for event in graphs:
    if event.get("root_role") != "app_root":
        die("resolved profile graph escaped the application root")
    if event.get("selected") != inputs["pins"]:
        die(f"final profile graph pin drift in {event.get('project')}:{event.get('configuration')}")
    encoded = json.dumps(event.get("graph"), separators=(",", ":"))
    if hashlib.sha256(encoded.encode()).hexdigest() != event.get("graph_sha256"):
        die(f"final profile graph hash drift in {event.get('configuration')}")

android = "{http://schemas.android.com/apk/res/android}"
egress = policy.get("android_physical_egress", {})
forbidden = set(egress.get("forbidden_profile_components", []))
required_metadata = egress.get("required_profile_metadata", {})

def inspect_manifest(path):
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        die(f"manifest XML is malformed: {path}: {error}")
    applications = root.findall("application")
    if len(applications) != 1:
        die(f"manifest must contain exactly one application: {path}")
    application = applications[0]
    components = []
    for kind in ("activity", "activity-alias", "provider", "service", "receiver"):
        for node in application.findall(kind):
            name = node.attrib.get(android + "name", "")
            if name in forbidden:
                die(f"forbidden auto-initialized component {name} in {path}")
            components.append({"kind": kind, "name": name})
    metadata = {}
    for name, expected_value in required_metadata.items():
        matches = [
            node for node in application.findall("meta-data")
            if node.attrib.get(android + "name") == name
        ]
        if len(matches) != 1 or matches[0].attrib.get(android + "value") != expected_value:
            die(f"required metadata {name} is missing, duplicate or mismatched in {path}")
        metadata[name] = expected_value
    permissions = sorted({
        node.attrib.get(android + "name", "")
        for node in root.findall("uses-permission")
    })
    return {
        "application_count": 1,
        "components": sorted(components, key=lambda item: (item["kind"], item["name"])),
        "permissions": permissions,
        "required_metadata": dict(sorted(metadata.items())),
    }

manifest_attestation = {
    "parser": "python.xml.etree.ElementTree.namespace_aware",
    "merged": inspect_manifest(merged_path),
    "packaged": inspect_manifest(packaged_path),
}
if manifest_attestation["merged"] != manifest_attestation["packaged"]:
    die("merged and packaged profile manifest structures differ")
if before_path.read_bytes() != after_path.read_bytes():
    die("protected input mutation detected")
for first, second, label in [
    (source_cache_before_path, source_cache_after_path, "global source cache"),
    (ro_cache_before_path, ro_cache_after_path, "ephemeral read-only cache"),
    (writable_cache_before_path, writable_cache_after_path, "ephemeral writable cache"),
]:
    if first.read_bytes() != second.read_bytes():
        die(f"{label} inventory drift")
if writable_cache_after_path.read_text(encoding="utf-8"):
    die("ephemeral writable dependency cache contains artifacts or metadata")
expected_marker = f"MANALOOM_GRADLE_NETWORK_ATTEMPT run_id={run_id}"
expected_canary = f"MANALOOM_GRADLE_TELEMETRY_CANARY run_id={run_id}"
if expected_marker not in sandbox_path.read_text(encoding="utf-8"):
    die("sandbox network-attempt marker is absent")
for path, label in [
    (telemetry_summary_path, "sandbox telemetry summary"),
    (telemetry_log_path, "sandbox telemetry log"),
    (telemetry_stderr_path, "sandbox telemetry stderr"),
    (app_build_before_path, "app/build before inventory"),
    (app_build_after_path, "app/build after inventory"),
    (app_build_backup_path, "app/build quarantine inventory"),
    (build_process_identity_path, "build process identity"),
    (app_build_state_path, "app/build state"),
]:
    if not path.is_file() or path.is_symlink():
        die(f"{label} is missing or unsafe")
if telemetry_stderr_path.read_bytes():
    die("sandbox unified-log reader emitted diagnostics")
try:
    telemetry = json.loads(telemetry_summary_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as error:
    die(f"sandbox telemetry summary is malformed: {error}")
if not (
    telemetry.get("schema_version") == "manaloom.gradle_sandbox_telemetry.v2"
    and telemetry.get("run_id") == run_id
    and telemetry.get("marker") == expected_marker
    and telemetry.get("canary") == expected_canary
    and telemetry.get("canary_entries") == 1
    and telemetry.get("canary_source") == "sandbox_denied_loopback_probe"
    and telemetry.get("canary_process") == "/kernel"
    and telemetry.get("network_attempt_entries") == 0
    and telemetry.get("total_entries") == 1
    and telemetry.get("findings") == []
    and telemetry.get("raw_sha256") == digest(telemetry_log_path)
):
    die("sandbox telemetry summary is malformed or cross-run")
try:
    telemetry_started = datetime.strptime(
        telemetry_started_at, "%Y-%m-%d %H:%M:%S%z"
    )
    telemetry_finished = datetime.strptime(
        telemetry_finished_at, "%Y-%m-%d %H:%M:%S%z"
    )
except ValueError as error:
    die(f"sandbox telemetry window timestamp is malformed: {error}")
if telemetry_finished < telemetry_started:
    die("sandbox telemetry window is reversed")
if app_build_before_path.read_bytes() != app_build_after_path.read_bytes():
    die("preexisting app/build was not restored exactly")
if app_build_preexisted:
    if not app_build_before_path.read_bytes():
        die("preexisting app/build inventory is unexpectedly empty")
    if app_build_before_path.read_bytes() != app_build_backup_path.read_bytes():
        die("quarantined app/build inventory drift")
elif app_build_before_path.read_bytes() or app_build_backup_path.read_bytes():
    die("absent app/build has a non-empty quarantine inventory")
try:
    build_process = json.loads(
        build_process_identity_path.read_text(encoding="utf-8")
    )
except json.JSONDecodeError as error:
    die(f"build process identity is malformed: {error}")
if not (
    build_process.get("schema_version") == "manaloom.gradle_build_process.v1"
    and isinstance(build_process.get("pid"), int)
    and build_process.get("pid") > 0
    and build_process.get("pgid") == build_process.get("pid")
):
    die("build process identity is malformed")
if app_build_state_path.read_text(encoding="utf-8").strip() != "cleanup_complete":
    die("app/build cleanup state is not terminal")
if recovery_required_path.exists() or recovery_required_path.is_symlink():
    die("app/build recovery is still required")
build_log = build_log_path.read_text(encoding="utf-8", errors="replace")
attempt_patterns = [
    r"MANALOOM_GRADLE_NETWORK_ATTEMPT",
    r"sandbox(?:-exec)?.{0,80}deny.{0,80}network",
    r"SocketException",
    r"ConnectException",
    r"UnknownHostException",
    r"Unable to resolve host",
    r"getaddrinfo",
    r"nodename nor servname",
    r"Name or service not known",
    r"Operation not permitted",
    r"Could not (?:GET|HEAD|resolve)",
    r"No cached version listing",
]
network_findings = []
for line_number, line in enumerate(build_log.splitlines(), start=1):
    if any(re.search(pattern, line, flags=re.IGNORECASE) for pattern in attempt_patterns):
        network_findings.append({"line": line_number, "text": line.strip()[:500]})
        continue
    for raw_url in re.findall(r"https?://[^\s<>'\"]+", line, flags=re.IGNORECASE):
        host = (urlsplit(raw_url.rstrip(".,);]")).hostname or "").lower()
        if host not in {"127.0.0.1", "localhost", "::1"}:
            network_findings.append({"line": line_number, "text": line.strip()[:500]})
            break
if network_findings:
    die(f"build log records resolver/network attempts: {network_findings[:5]}")

def inventory(path):
    lines = [line for line in path.read_text(encoding="utf-8").splitlines() if line]
    return {
        "path": str(path.resolve()),
        "sha256": digest(path),
        "entries": len(lines),
    }

receipt = {
    "schema_version": "manaloom.gradle_dynamic_selector_adapter_receipt.v1",
    "status": "PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER",
    "run_id": run_id,
    "started_at": str(started_at),
    "finished_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "inputs": inputs,
    "events": {
        "settings_roots": roots,
        "dynamic_declarations": sorted(declarations),
        "substitutions": sorted(actual_substitutions),
        "resolved_graphs": graphs,
    },
    "network": {
        "policy": "macos_sandbox_deny_all",
        "gradle_offline": True,
        "resolver_or_egress_attempts": 0,
        "attempt_detector": "run_bound_sandbox_decision_canary_plus_build_log_v3",
        "sandbox_profile_sha256": digest(sandbox_path),
        "unified_log": {
            "schema_version": telemetry["schema_version"],
            "marker": expected_marker,
            "canary": expected_canary,
            "started_at": telemetry_started_at,
            "finished_at": telemetry_finished_at,
            "canary_entries": 1,
            "canary_source": telemetry["canary_source"],
            "canary_process": telemetry["canary_process"],
            "network_attempt_entries": 0,
            "total_entries": telemetry["total_entries"],
            "raw_log_path": str(telemetry_log_path.resolve()),
            "raw_log_sha256": digest(telemetry_log_path),
            "stderr_sha256": digest(telemetry_stderr_path),
            "summary_sha256": digest(telemetry_summary_path),
        },
        "findings": [],
    },
    "mutation": {
        "sdk_lock_metadata_cache_changed": False,
        "protected_inputs_before_sha256": digest(before_path),
        "protected_inputs_after_sha256": digest(after_path),
        "ephemeral_gradle_user_home": str(pathlib.Path(config["event_directory"]).parent / "gradle-user-home"),
        "config_before_sha256": config_before_sha,
        "config_after_sha256": config_after_sha,
        "init_copy_before_sha256": init_copy_before_sha,
        "init_copy_after_sha256": init_copy_after_sha,
        "global_source_cache_before": inventory(source_cache_before_path),
        "global_source_cache_after": inventory(source_cache_after_path),
        "ephemeral_read_only_cache_before": inventory(ro_cache_before_path),
        "ephemeral_read_only_cache_after": inventory(ro_cache_after_path),
        "ephemeral_writable_cache_before": inventory(writable_cache_before_path),
        "ephemeral_writable_cache_after": inventory(writable_cache_after_path),
        "app_build": {
            "preexisting": app_build_preexisted,
            "quarantined_before_build": True,
            "fresh_tree_removed": True,
            "restored_exactly": True,
            "before": inventory(app_build_before_path),
            "quarantine": inventory(app_build_backup_path),
            "after": inventory(app_build_after_path),
        },
    },
    "artifact": {
        "apk_path": str(apk_path.resolve()),
        "apk_sha256": digest(apk_path),
        "merged_manifest_path": str(merged_path.resolve()),
        "merged_manifest_sha256": digest(merged_path),
        "packaged_manifest_path": str(packaged_path.resolve()),
        "packaged_manifest_sha256": digest(packaged_path),
        "manifest_attestation": manifest_attestation,
        "release_semantics": {
            "status": "PASS_SOURCE_DEFAULTS_ONLY",
            "release_artifact_equivalence": "NOT_CLAIMED",
            "release_build": "BLOCKED_NOT_RUN_PROFILE_ONLY",
            "gradle_and_lock_inputs_pinned": True,
            "release_manifest_input_pinned": True,
            "shared_push_guard_default": "DISABLE_PUSH_INIT=false",
            "profile_merged_packaged_structure_equal": True,
            "profile_delta": (
                "capture-only profile removes 15 auto-initialized telemetry components "
                "and binds four disabling metadata nodes; release Gradle, lock, main and "
                "release manifest inputs remain pinned"
            ),
            "inputs": inputs["release_semantics_inputs"],
        },
    },
    "build": {
        "exit": build_exit,
        "log_path": str(build_log_path.resolve()),
        "log_sha256": digest(build_log_path),
        "fresh_app_build_tree": True,
        "app_build_cleanup": "PASS_EXACT_RESTORE_OR_ABSENCE",
        "profile_only": True,
        "release_artifact_comparison": "BLOCKED_NOT_RUN_PROFILE_ONLY",
        "process_group": {
            "schema_version": build_process["schema_version"],
            "pid": build_process["pid"],
            "pgid": build_process["pgid"],
            "waited": True,
            "remaining_processes": 0,
        },
    },
}
receipt_path = pathlib.Path(receipt_path)
temporary = receipt_path.with_name(receipt_path.name + ".tmp")
temporary.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
temporary.replace(receipt_path)
PY

  jq -e --arg run_id "$run_id" '
    .schema_version == "manaloom.gradle_dynamic_selector_adapter_receipt.v1" and
    .status == "PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER" and
    .run_id == $run_id and
    .network.resolver_or_egress_attempts == 0 and
    .network.findings == [] and
    .network.attempt_detector ==
      "run_bound_sandbox_decision_canary_plus_build_log_v3" and
    .network.unified_log.canary_entries == 1 and
    .network.unified_log.canary_source == "sandbox_denied_loopback_probe" and
    .network.unified_log.canary_process == "/kernel" and
    .network.unified_log.network_attempt_entries == 0 and
    .network.unified_log.total_entries == 1 and
    .network.unified_log.marker ==
      ("MANALOOM_GRADLE_NETWORK_ATTEMPT run_id=" + $run_id) and
    .network.unified_log.canary ==
      ("MANALOOM_GRADLE_TELEMETRY_CANARY run_id=" + $run_id) and
    .mutation.sdk_lock_metadata_cache_changed == false and
    .mutation.global_source_cache_before.sha256 ==
      .mutation.global_source_cache_after.sha256 and
    .mutation.ephemeral_read_only_cache_before.sha256 ==
      .mutation.ephemeral_read_only_cache_after.sha256 and
    .mutation.ephemeral_writable_cache_after.entries == 0 and
    .mutation.config_before_sha256 == .mutation.config_after_sha256 and
    .mutation.init_copy_before_sha256 == .mutation.init_copy_after_sha256 and
    .mutation.app_build.quarantined_before_build == true and
    .mutation.app_build.fresh_tree_removed == true and
    .mutation.app_build.restored_exactly == true and
    .mutation.app_build.before.sha256 == .mutation.app_build.after.sha256 and
    .artifact.release_semantics.status == "PASS_SOURCE_DEFAULTS_ONLY" and
    .artifact.release_semantics.release_artifact_equivalence == "NOT_CLAIMED" and
    .build.process_group.waited == true and
    .build.process_group.remaining_processes == 0 and
    .build.exit == 0
  ' "$RECEIPT" >/dev/null || fail "terminal adapter receipt is invalid or cross-run"
  trap - EXIT HUP INT TERM QUIT
  printf 'status=PASS_GRADLE_DYNAMIC_SELECTOR_ADAPTER\n'
  printf 'run_id=%s\n' "$run_id"
  printf 'receipt=%s\n' "$RECEIPT"
  printf 'receipt_sha256=%s\n' "$(sha256_file "$RECEIPT")"
}

[[ $# -gt 0 ]] || { usage >&2; exit 2; }
COMMAND="$1"
shift
parse_common_args "$@"

case "$COMMAND" in
  preflight)
    for tool in git jq python3 sed shasum; do
      command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
    done
    [[ -n "$RECEIPT" ]] || fail "preflight --output is required"
    write_input_attestation "$RECEIPT"
    printf 'status=PASS_GRADLE_DYNAMIC_SELECTOR_PREFLIGHT\n'
    printf 'attestation=%s\n' "$RECEIPT"
    printf 'attestation_sha256=%s\n' "$(sha256_file "$RECEIPT")"
    ;;
  telemetry-check)
    [[ -n "$TELEMETRY_LOG" ]] || fail "telemetry-check --telemetry-log is required"
    [[ -n "$TELEMETRY_RUN_ID" ]] || fail "telemetry-check --run-id is required"
    [[ -n "$RECEIPT" ]] || fail "telemetry-check --output is required"
    TELEMETRY_LOG="$(canonical_fresh_path "$TELEMETRY_LOG" "telemetry log")"
    RECEIPT="$(canonical_fresh_path "$RECEIPT" "telemetry output")"
    verify_unified_log_window "$TELEMETRY_LOG" "$TELEMETRY_RUN_ID" "$RECEIPT"
    printf 'status=PASS_GRADLE_SANDBOX_TELEMETRY\n'
    printf 'summary=%s\n' "$RECEIPT"
    ;;
  run)
    run_adapter
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

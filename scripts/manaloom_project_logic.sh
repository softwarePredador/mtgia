#!/usr/bin/env bash
set -euo pipefail

readonly EXPECTED_FLUTTER_VERSION="3.44.6"
readonly EXPECTED_FLUTTER_REVISION="ee80f08bbf97172ec030b8751ceab557177a34a6"
readonly EXPECTED_ENGINE_REVISION="83675ed27633283e7fc296c8bca22e841224c096"
readonly EXPECTED_DART_VERSION="3.12.2"

SCRIPT_DIR_LOGICAL="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -L)"
ROOT_DIR_LOGICAL="$(CDPATH='' cd -- "$SCRIPT_DIR_LOGICAL/.." && pwd -L)"
SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(CDPATH='' cd -P -- "$SCRIPT_DIR/.." && pwd -P)"
MODE="${1:---check}"

source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
resolve_manaloom_dart
resolve_manaloom_flutter_root
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"
FLUTTER_ROOT="$MANALOOM_FLUTTER_ROOT_RESOLVED"
FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"

export FLUTTER_ROOT
export MANALOOM_PROJECT_LOGIC_LOGICAL_ROOT="$ROOT_DIR_LOGICAL"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true

case "$MODE" in
  --check|--write)
    ;;
  *)
    echo "Uso: ./scripts/manaloom_project_logic.sh [--check|--write]" >&2
    exit 2
    ;;
esac

if [[ ! -x "$DART_BIN" ]]; then
  echo "Dart não encontrado: $DART_BIN" >&2
  exit 2
fi

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter não encontrado: $FLUTTER_BIN" >&2
  exit 2
fi

canonical_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (CDPATH='' cd -P -- "$path" && pwd -P)
    return
  fi
  if [[ -e "$path" ]]; then
    local directory basename
    directory="$(CDPATH='' cd -P -- "$(dirname "$path")" && pwd -P)"
    basename="$(basename "$path")"
    printf '%s/%s\n' "$directory" "$basename"
    return
  fi
  return 1
}

json_string_value() {
  local file="$1"
  local key="$2"
  sed -nE 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$file" | head -n 1
}

FLUTTER_VERSION_FILE="$FLUTTER_ROOT/bin/cache/flutter.version.json"
if [[ ! -f "$FLUTTER_VERSION_FILE" ]]; then
  echo "Identidade do Flutter ausente: $FLUTTER_VERSION_FILE" >&2
  exit 2
fi
actual_flutter_version="$(json_string_value "$FLUTTER_VERSION_FILE" frameworkVersion)"
actual_flutter_revision="$(json_string_value "$FLUTTER_VERSION_FILE" frameworkRevision)"
actual_engine_revision="$(json_string_value "$FLUTTER_VERSION_FILE" engineRevision)"
actual_dart_version="$(json_string_value "$FLUTTER_VERSION_FILE" dartSdkVersion)"
if [[ "$actual_flutter_version" != "$EXPECTED_FLUTTER_VERSION" || "$actual_flutter_revision" != "$EXPECTED_FLUTTER_REVISION" || "$actual_engine_revision" != "$EXPECTED_ENGINE_REVISION" || "$actual_dart_version" != "$EXPECTED_DART_VERSION" ]]; then
  echo "Toolchain Flutter/Dart divergente do pin de project logic." >&2
  exit 2
fi

approved_dart="$(canonical_path "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart")"
resolved_dart="$(canonical_path "$DART_BIN")"
if [[ "$resolved_dart" != "$approved_dart" ]]; then
  echo "Project logic exige o Dart real do Flutter pinado: $approved_dart" >&2
  exit 2
fi

GLOBAL_PUB_CACHE="${MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE:-${PUB_CACHE:-$HOME/.pub-cache}}"
if ! GLOBAL_PUB_CACHE="$(canonical_path "$GLOBAL_PUB_CACHE")"; then
  echo "Cache Pub global read-only não encontrado." >&2
  exit 2
fi

TASK_CACHE_OWNED=0
TASK_PUB_CACHE=""
STATE_DIR=""

early_cleanup() {
  local original_exit="$?"
  local cleanup_exit=0
  trap - EXIT INT TERM
  set +e
  if [[ "$TASK_CACHE_OWNED" == "1" && -n "$TASK_PUB_CACHE" ]]; then
    if [[ -d "$TASK_PUB_CACHE" && "$(basename "$TASK_PUB_CACHE")" == manaloom_project_logic_pub_cache.* ]]; then
      /bin/rm -rf -- "$TASK_PUB_CACHE" || cleanup_exit=1
    elif [[ -e "$TASK_PUB_CACHE" || -L "$TASK_PUB_CACHE" ]]; then
      cleanup_exit=1
    fi
  fi
  if [[ -n "$STATE_DIR" ]]; then
    if [[ -d "$STATE_DIR" && "$(basename "$STATE_DIR")" == manaloom_project_logic_state.* ]]; then
      /bin/rm -rf -- "$STATE_DIR" || cleanup_exit=1
    elif [[ -e "$STATE_DIR" || -L "$STATE_DIR" ]]; then
      cleanup_exit=1
    fi
  fi
  if [[ "$cleanup_exit" != "0" ]]; then
    exit 2
  fi
  exit "$original_exit"
}
trap early_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

paths_overlap() {
  local left="${1%/}"
  local right="${2%/}"
  [[ -n "$left" ]] || left="/"
  [[ -n "$right" ]] || right="/"
  [[ "$left" == "$right" || "$left" == "$right/"* || "$right" == "$left/"* ]]
}

if [[ -n "${MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE:-}" ]]; then
  task_cache_candidate="$MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE"
  if [[ -L "$task_cache_candidate" ]]; then
    echo "Cache task-scoped não pode ser symlink." >&2
    exit 2
  fi
  if [[ -e "$task_cache_candidate" ]]; then
    if [[ ! -d "$task_cache_candidate" ]]; then
      echo "Cache task-scoped deve ser um diretório." >&2
      exit 2
    fi
    TASK_PUB_CACHE="$(canonical_path "$task_cache_candidate")"
  else
    task_cache_parent="$(dirname "$task_cache_candidate")"
    if ! task_cache_parent="$(canonical_path "$task_cache_parent")"; then
      echo "Pai do cache task-scoped não existe." >&2
      exit 2
    fi
    TASK_PUB_CACHE="$task_cache_parent/$(basename "$task_cache_candidate")"
  fi
  if paths_overlap "$TASK_PUB_CACHE" "$GLOBAL_PUB_CACHE"; then
    echo "Caches Pub task-scoped e global não podem se sobrepor." >&2
    exit 2
  fi
  mkdir -p -- "$TASK_PUB_CACHE"
  TASK_PUB_CACHE="$(canonical_path "$TASK_PUB_CACHE")"
else
  task_cache_temp_root="${TMPDIR:-/tmp}"
  if ! task_cache_temp_root="$(canonical_path "$task_cache_temp_root")"; then
    echo "Raiz temporária do cache task-scoped não existe." >&2
    exit 2
  fi
  if paths_overlap "$task_cache_temp_root" "$GLOBAL_PUB_CACHE"; then
    echo "Raiz temporária não pode se sobrepor ao cache Pub global." >&2
    exit 2
  fi
  TASK_CACHE_OWNED=1
  TASK_PUB_CACHE="$(mktemp -d "$task_cache_temp_root/manaloom_project_logic_pub_cache.XXXXXX")"
  TASK_PUB_CACHE="$(canonical_path "$TASK_PUB_CACHE")"
fi
if paths_overlap "$TASK_PUB_CACHE" "$GLOBAL_PUB_CACHE"; then
  echo "Caches Pub task-scoped e global não podem se sobrepor." >&2
  exit 2
fi

STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_project_logic_state.XXXXXX")"
STATE_DIR="$(canonical_path "$STATE_DIR")"
readonly TASK_PUB_CACHE STATE_DIR GLOBAL_PUB_CACHE

export PUB_CACHE="$TASK_PUB_CACHE"
export MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE="$TASK_PUB_CACHE"
export MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE="$GLOBAL_PUB_CACHE"

readonly LOCK_PATHS=(
  "$ROOT_DIR/pubspec.lock"
  "$ROOT_DIR/app/pubspec.lock"
  "$ROOT_DIR/server/pubspec.lock"
  "$ROOT_DIR/tools/project_logic/pubspec.lock"
  "$ROOT_DIR/tools/manaloom_lints/pubspec.lock"
)
readonly PACKAGE_DIRS=(
  "$ROOT_DIR/tools/project_logic"
  "$ROOT_DIR"
  "$ROOT_DIR/app"
  "$ROOT_DIR/server"
)

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

sha256_stream() {
  shasum -a 256 | awk '{print $1}'
}

collect_hosted_pins() {
  local lock
  for lock in "${LOCK_PATHS[@]}"; do
    if [[ ! -f "$lock" ]]; then
      echo "Lock obrigatório ausente: $lock" >&2
      return 2
    fi
    awk '
      /^  [A-Za-z_][A-Za-z0-9_]*:$/ {
        package_name=$1
        sub(/:$/, "", package_name)
        package_source=""
        next
      }
      /^    source: / {
        package_source=$2
        if (package_source != "hosted" && package_source != "path" && package_source != "sdk") {
          printf "unsupported-source\t%s\t%s\n", package_name, package_source
        }
        next
      }
      /^    version: "/ {
        version=$2
        gsub(/"/, "", version)
        if (package_source == "hosted") {
          printf "%s\t%s\n", package_name, version
        }
      }
    ' "$lock"
  done
}

PINS_FILE="$STATE_DIR/hosted-pins.tsv"
collect_hosted_pins | LC_ALL=C sort -u >"$PINS_FILE"
if grep -q '^unsupported-source' "$PINS_FILE"; then
  echo "Lock contém fonte não suportada pelo bootstrap offline." >&2
  exit 2
fi
if [[ ! -s "$PINS_FILE" ]]; then
  echo "Nenhum pacote hosted foi derivado dos locks." >&2
  exit 2
fi

lock_fingerprint() {
  local lock
  for lock in "${LOCK_PATHS[@]}"; do
    printf '%s\t%s\n' "${lock#"$ROOT_DIR"/}" "$(sha256_file "$lock")"
  done | LC_ALL=C sort | sha256_stream
}

cache_source_paths() {
  local cache_root="$1"
  local package version package_root hash_file file
  while IFS=$'\t' read -r package version; do
    package_root="$cache_root/hosted/pub.dev/$package-$version"
    hash_file="$cache_root/hosted-hashes/pub.dev/$package-$version.sha256"
    if [[ ! -d "$package_root" || ! -f "$hash_file" ]]; then
      echo "Cache offline incompleto para $package $version." >&2
      return 2
    fi
    while IFS= read -r file; do
      printf '%s\n' "${file#"$cache_root"/}"
    done < <(find "$package_root" \( -type f -o -type l \) -print)
    printf '%s\n' "${hash_file#"$cache_root"/}"
  done <"$PINS_FILE"
}

cache_source_fingerprint() {
  local cache_root="$1"
  perl -MDigest::SHA -e '
    use strict;
    use warnings;
    my ($root, $list_path) = @ARGV;
    open my $list, "<", $list_path or die "cannot read cache path list: $!";
    my $digest = Digest::SHA->new(256);
    while (my $relative = <$list>) {
      chomp $relative;
      my $path = "$root/$relative";
      $digest->add($relative, "\0");
      if (-l $path) {
        my $target = readlink $path;
        defined $target or die "cannot read cache symlink: $path";
        $digest->add("link\0", $target, "\0");
      } elsif (-f $path) {
        $digest->add("file\0");
        open my $file, "<", $path or die "cannot read cache file: $path";
        binmode $file;
        $digest->addfile($file);
        close $file or die "cannot close cache file: $path";
        $digest->add("\0");
      } else {
        die "attested cache path missing: $path";
      }
    }
    close $list or die "cannot close cache path list";
    print $digest->hexdigest, "\n";
  ' "$cache_root" "$CACHE_PATHS_FILE"
}

CACHE_PATHS_FILE="$STATE_DIR/cache-paths.txt"
cache_source_paths "$GLOBAL_PUB_CACHE" | LC_ALL=C sort -u >"$CACHE_PATHS_FILE"
if [[ ! -s "$CACHE_PATHS_FILE" ]]; then
  echo "Inventário do cache offline está vazio." >&2
  exit 2
fi

active_roots_fingerprint() {
  local directory="$1/active_roots"
  if [[ ! -d "$directory" ]]; then
    printf 'absent\n' | sha256_stream
    return
  fi
  local file
  while IFS= read -r file; do
    printf '%s\t%s\n' "${file#"$directory"/}" "$(sha256_file "$file")"
  done < <(find "$directory" -type f -print | LC_ALL=C sort) | sha256_stream
}

clone_path() {
  local source="$1"
  local destination="$2"
  mkdir -p -- "$(dirname "$destination")"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    /bin/cp -cRpP -- "$source" "$destination"
  else
    /bin/cp -a --reflink=auto -- "$source" "$destination"
  fi
}

validate_task_cache_links() {
  local link resolved
  while IFS= read -r link; do
    if ! resolved="$(realpath "$link" 2>/dev/null)"; then
      echo "Symlink quebrado no cache task-scoped: $link" >&2
      return 2
    fi
    case "$resolved" in
      "$TASK_PUB_CACHE"/*) ;;
      *)
        echo "Symlink do cache task-scoped escapa da cópia: $link" >&2
        return 2
        ;;
    esac
  done < <(find "$TASK_PUB_CACHE/hosted" -type l -print 2>/dev/null | LC_ALL=C sort)
  if find "$TASK_PUB_CACHE/hosted" -type f -links +1 -print -quit 2>/dev/null | grep -q .; then
    echo "Hardlink proibido detectado no cache task-scoped." >&2
    return 2
  fi
}

seed_task_cache() {
  local source_fingerprint="$1"
  local lock_hash="$2"
  local marker="$TASK_PUB_CACHE/.manaloom-project-logic-seed-v1"
  if [[ -f "$marker" ]]; then
    if [[ "$(sed -n '1p' "$marker")" != "$source_fingerprint" || "$(sed -n '2p' "$marker")" != "$lock_hash" ]]; then
      echo "Cache task-scoped pertence a outro seed/lock." >&2
      return 2
    fi
  else
    if find "$TASK_PUB_CACHE" -mindepth 1 -print -quit | grep -q .; then
      echo "Cache task-scoped não vazio e sem marcador governado." >&2
      return 2
    fi
    local package version source destination source_hash hash_destination
    while IFS=$'\t' read -r package version; do
      source="$GLOBAL_PUB_CACHE/hosted/pub.dev/$package-$version"
      destination="$TASK_PUB_CACHE/hosted/pub.dev/$package-$version"
      source_hash="$GLOBAL_PUB_CACHE/hosted-hashes/pub.dev/$package-$version.sha256"
      hash_destination="$TASK_PUB_CACHE/hosted-hashes/pub.dev/$package-$version.sha256"
      clone_path "$source" "$destination"
      clone_path "$source_hash" "$hash_destination"
    done <"$PINS_FILE"
    printf '%s\n%s\n' "$source_fingerprint" "$lock_hash" >"$marker"
  fi
  validate_task_cache_links
  if [[ "$(cache_source_fingerprint "$TASK_PUB_CACHE")" != "$source_fingerprint" ]]; then
    echo "Seed task-scoped diverge dos bytes globais atestados." >&2
    return 2
  fi
}

dot_tool_other_fingerprint() {
  local package_dir="$1"
  local dot_tool="$package_dir/.dart_tool"
  if [[ ! -d "$dot_tool" ]]; then
    printf '' | sha256_stream
    return
  fi
  local entry relative metadata
  while IFS= read -r entry; do
    relative="${entry#"$dot_tool"/}"
    case "$relative" in
      package_config.json|package_graph.json) continue ;;
    esac
    if [[ -L "$entry" ]]; then
      metadata="link:$(readlink "$entry")"
    elif [[ -f "$entry" ]]; then
      if [[ "$(uname -s)" == "Darwin" ]]; then
        metadata="file:$(sha256_file "$entry"):$(stat -f '%Sp' "$entry")"
      else
        metadata="file:$(sha256_file "$entry"):$(stat -c '%A' "$entry")"
      fi
    else
      if [[ "$(uname -s)" == "Darwin" ]]; then
        metadata="directory:$(stat -f '%Sp' "$entry")"
      else
        metadata="directory:$(stat -c '%A' "$entry")"
      fi
    fi
    printf '%s\t%s\n' "$relative" "$metadata"
  done < <(find "$dot_tool" -mindepth 1 -print | LC_ALL=C sort) | sha256_stream
}

snapshot_package_metadata() {
  local index=0 package_dir state_dir metadata
  for package_dir in "${PACKAGE_DIRS[@]}"; do
    state_dir="$STATE_DIR/package-$index"
    mkdir -p -- "$state_dir"
    if [[ -L "$package_dir/.dart_tool" ]] || [[ -e "$package_dir/.dart_tool" && ! -d "$package_dir/.dart_tool" ]]; then
      echo "Metadata .dart_tool deve ser diretório real: $package_dir/.dart_tool" >&2
      return 2
    fi
    if [[ -d "$package_dir/.dart_tool" ]]; then
      printf 'present\n' >"$state_dir/directory-state"
    else
      printf 'absent\n' >"$state_dir/directory-state"
    fi
    dot_tool_other_fingerprint "$package_dir" >"$state_dir/other-before"
    for metadata in package_config.json package_graph.json; do
      if [[ -L "$package_dir/.dart_tool/$metadata" ]] || [[ -e "$package_dir/.dart_tool/$metadata" && ! -f "$package_dir/.dart_tool/$metadata" ]]; then
        echo "Metadata de pacote linked/não regular é proibida: $package_dir/.dart_tool/$metadata" >&2
        return 2
      fi
      if [[ -f "$package_dir/.dart_tool/$metadata" && ! -L "$package_dir/.dart_tool/$metadata" ]]; then
        printf 'present\n' >"$state_dir/$metadata.state"
        /bin/cp -p -- "$package_dir/.dart_tool/$metadata" "$state_dir/$metadata"
      else
        printf 'absent\n' >"$state_dir/$metadata.state"
      fi
    done
    index=$((index + 1))
  done
}

restore_package_metadata() {
  local index=0 package_dir state_dir metadata original_state after
  local restore_status=0
  for package_dir in "${PACKAGE_DIRS[@]}"; do
    state_dir="$STATE_DIR/package-$index"
    for metadata in package_config.json package_graph.json; do
      original_state="$(cat "$state_dir/$metadata.state")"
      if [[ "$original_state" == "present" ]]; then
        mkdir -p -- "$package_dir/.dart_tool"
        /bin/cp -p -- "$state_dir/$metadata" "$package_dir/.dart_tool/$metadata" || restore_status=1
        if ! /usr/bin/cmp -s -- "$state_dir/$metadata" "$package_dir/.dart_tool/$metadata"; then
          echo "Metadata não foi restaurada byte a byte: $package_dir/.dart_tool/$metadata" >&2
          restore_status=1
        fi
      elif [[ -e "$package_dir/.dart_tool/$metadata" || -L "$package_dir/.dart_tool/$metadata" ]]; then
        /bin/unlink "$package_dir/.dart_tool/$metadata" || restore_status=1
      fi
    done
    after="$(dot_tool_other_fingerprint "$package_dir")"
    if [[ "$after" != "$(cat "$state_dir/other-before")" ]]; then
      echo "Bootstrap criou/alterou conteúdo inesperado em $package_dir/.dart_tool." >&2
      restore_status=1
    fi
    if [[ "$(cat "$state_dir/directory-state")" == "absent" && -d "$package_dir/.dart_tool" ]]; then
      rmdir "$package_dir/.dart_tool" 2>/dev/null || {
        echo "Diretório .dart_tool residual em $package_dir." >&2
        restore_status=1
      }
    fi
    index=$((index + 1))
  done
  return "$restore_status"
}

remove_owned_directory() {
  local directory="$1"
  local expected_prefix="$2"
  local basename
  basename="$(basename "$directory")"
  if [[ "$basename" != "$expected_prefix".* || ! -d "$directory" ]]; then
    echo "Recusa ao remover diretório temporário não governado: $directory" >&2
    return 2
  fi
  /bin/rm -rf -- "$directory"
  [[ ! -e "$directory" ]]
}

LOCK_FINGERPRINT_BEFORE="$(lock_fingerprint)"
GLOBAL_CACHE_FINGERPRINT_BEFORE="$(cache_source_fingerprint "$GLOBAL_PUB_CACHE")"
GLOBAL_ACTIVE_ROOTS_BEFORE="$(active_roots_fingerprint "$GLOBAL_PUB_CACHE")"
snapshot_package_metadata

cleanup() {
  local original_exit="$?"
  local cleanup_exit=0
  trap - EXIT INT TERM
  set +e

  restore_package_metadata || cleanup_exit=1
  if [[ "$(lock_fingerprint)" != "$LOCK_FINGERPRINT_BEFORE" ]]; then
    echo "Locks mudaram durante a execução de project logic." >&2
    cleanup_exit=1
  fi
  if [[ "$(cache_source_fingerprint "$GLOBAL_PUB_CACHE")" != "$GLOBAL_CACHE_FINGERPRINT_BEFORE" ]]; then
    echo "Cache Pub global consumido mudou durante a execução." >&2
    cleanup_exit=1
  fi
  if [[ "$(active_roots_fingerprint "$GLOBAL_PUB_CACHE")" != "$GLOBAL_ACTIVE_ROOTS_BEFORE" ]]; then
    echo "active_roots do cache Pub global mudou durante a execução." >&2
    cleanup_exit=1
  fi
  if [[ "$TASK_CACHE_OWNED" == "1" ]]; then
    remove_owned_directory "$TASK_PUB_CACHE" manaloom_project_logic_pub_cache || cleanup_exit=1
  fi
  remove_owned_directory "$STATE_DIR" manaloom_project_logic_state || cleanup_exit=1

  if [[ "$cleanup_exit" != "0" ]]; then
    exit 2
  fi
  exit "$original_exit"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
seed_task_cache "$GLOBAL_CACHE_FINGERPRINT_BEFORE" "$LOCK_FINGERPRINT_BEFORE"

PACKAGE_DIR="$ROOT_DIR/tools/project_logic"
(
  cd "$PACKAGE_DIR"
  "$DART_BIN" pub get --offline --enforce-lockfile --no-precompile
)

(
  cd "$PACKAGE_DIR"
  "$DART_BIN" bin/manaloom_project_logic.dart "$MODE" --root "$ROOT_DIR"
)

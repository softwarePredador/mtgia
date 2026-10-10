#!/usr/bin/env bash

# D-83 (BT-AUTH-002): "o teto do proxy é conferido no deploy". O backend aceita
# até 5 MiB nas rotas de import, 1 MiB no resto e 16 KiB em /auth
# (server/lib/request_body_limits.dart). Se o proxy na frente da API (o Traefik do
# EasyPanel, ou um nginx, cujo client_max_body_size padrão é 1m) cortar antes, o
# import grande para no proxy com um 413 que não é o envelope do backend, e o app
# não tem como explicar o erro.
#
# A conferência manda, pela URL pública da API, um POST sem credencial a uma rota
# de import com um corpo JSON de exatamente o teto do import, e exige que a
# resposta venha do backend: status abaixo de 500 e diferente de 413, com um
# objeto JSON que tem `error` em texto. Nada é gravado: sem token, o backend
# recusa (401), ou a capability fechada responde 404, antes de qualquer escrita.

# O teto do import, em bytes, lido da constante do backend
# (`const importRequestBodyLimitBytes = 5 * 1024 * 1024;`).
manaloom_import_body_limit_bytes() {
  local source_path="$1"
  local expression
  local pattern='^[0-9]+( [*] [0-9]+)*$'
  expression="$(sed -n -E \
    's/^const importRequestBodyLimitBytes = ([0-9]+( [*] [0-9]+)*);$/\1/p' \
    "$source_path")"
  if [[ ! "$expression" =~ $pattern ]]; then
    echo "teto de corpo do import ilegivel em $source_path" >&2
    return 2
  fi
  printf '%s\n' "$((expression))"
}

# Falha fechado se o proxy na frente de <api_base_url> não leva um corpo de
# <limit_bytes> bytes até o backend. <probe_path> é a rota de import (padrão
# /import/validate).
manaloom_require_proxy_body_ceiling() {
  local api_base_url="$1"
  local limit_bytes="$2"
  local probe_path="${3:-/import/validate}"
  local work payload response status curl_status verdict

  if [[ ! "$limit_bytes" =~ ^[1-9][0-9]*$ ]]; then
    echo "deploy recusado: teto de corpo do import invalido: '$limit_bytes'" >&2
    return 2
  fi
  work="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-proxy-body.XXXXXX")"
  payload="$work/payload.json"
  response="$work/response"

  if ! python3 - "$payload" "$limit_bytes" <<'PY'
import sys

path, size = sys.argv[1], int(sys.argv[2])
prefix, suffix = b'{"list":"', b'"}'
filler = size - len(prefix) - len(suffix)
if filler < 0:
    raise SystemExit("teto menor que o envelope JSON")
with open(path, "wb") as handle:
    handle.write(prefix + b"a" * filler + suffix)
PY
  then
    rm -rf "$work"
    echo "deploy recusado: nao foi possivel montar o corpo da conferencia do proxy" >&2
    return 2
  fi

  curl_status=0
  status="$(curl -sS -o "$response" -w '%{http_code}' \
    --connect-timeout 10 --max-time 120 \
    -X POST \
    -H 'Content-Type: application/json' \
    -H 'Expect:' \
    --data-binary "@$payload" \
    "${api_base_url%/}$probe_path")" || curl_status=$?

  verdict="$(python3 - "$response" "$status" "$curl_status" <<'PY'
import json
import sys

path, status, curl_status = sys.argv[1], sys.argv[2], sys.argv[3]
if curl_status != "0":
    print(f"a conexao caiu antes da resposta (curl {curl_status})")
    raise SystemExit
if status == "413":
    print("413: o proxy recusou o corpo; o teto dele e menor que o do import")
    raise SystemExit
if not (status.isdigit() and len(status) == 3 and 100 <= int(status) < 500):
    print(f"status {status}: a resposta nao veio do backend")
    raise SystemExit
try:
    with open(path, "rb") as handle:
        body = json.loads(handle.read().decode("utf-8"))
except (OSError, UnicodeDecodeError, ValueError):
    body = None
if not isinstance(body, dict) or not isinstance(body.get("error"), str):
    print(f"status {status} sem o envelope JSON do backend")
    raise SystemExit
print("ok")
PY
)" || verdict="a conferencia da resposta falhou"
  rm -rf "$work"

  if [[ "$verdict" != "ok" ]]; then
    echo "deploy recusado: teto de corpo do proxy (D-83) em ${api_base_url%/}$probe_path com $limit_bytes bytes: $verdict" >&2
    return 2
  fi
  echo "proxy_body_ceiling_ok status=$status bytes=$limit_bytes path=$probe_path"
}

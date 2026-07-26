#!/bin/sh
set -eu

api_pid=''
worker_pid=''

terminate_children() {
  if [ -n "$worker_pid" ]; then
    kill -TERM "$worker_pid" 2>/dev/null || true
  fi
  if [ -n "$api_pid" ]; then
    kill -TERM "$api_pid" 2>/dev/null || true
  fi
  if [ -n "$worker_pid" ]; then
    wait "$worker_pid" 2>/dev/null || true
  fi
  if [ -n "$api_pid" ]; then
    wait "$api_pid" 2>/dev/null || true
  fi
}

trap 'terminate_children; exit 143' TERM
trap 'terminate_children; exit 130' INT

/app/server/manaloom-server \
  --hostname 0.0.0.0 \
  --port "${PORT:-8080}" &
api_pid=$!

if [ "${BATTLE_JOB_WORKER_ENABLED:-true}" != "true" ]; then
  wait "$api_pid"
  exit $?
fi

/app/server/manaloom-battle-worker &
worker_pid=$!

while :; do
  if ! kill -0 "$api_pid" 2>/dev/null; then
    wait "$api_pid" || status=$?
    terminate_children
    exit "${status:-1}"
  fi
  if ! kill -0 "$worker_pid" 2>/dev/null; then
    wait "$worker_pid" || status=$?
    terminate_children
    exit "${status:-1}"
  fi
  sleep 1
done

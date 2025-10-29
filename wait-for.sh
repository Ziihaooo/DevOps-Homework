#!/bin/sh
# safer wait-for.sh (works with Docker + tail)

HOST="$1"
PORT="$2"
shift 2

TIMEOUT=60
CMD=""

# parse args
for arg in "$@"; do
  case "$arg" in
    --timeout=*)
      TIMEOUT="${arg#*=}"
      ;;
    --)
      shift
      CMD="$@"
      break
      ;;
  esac
done

echo "⏳ Waiting for $HOST:$PORT (timeout: ${TIMEOUT}s)..."
start_ts=$(date +%s)

while true; do
  nc -z "$HOST" "$PORT" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$HOST:$PORT is available!"
    break
  fi
  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "Timeout after ${TIMEOUT}s waiting for $HOST:$PORT"
    exit 1
  fi
  sleep 1
done

if [ -n "$CMD" ]; then
  echo "Executing command: $CMD"
  exec $CMD
fi

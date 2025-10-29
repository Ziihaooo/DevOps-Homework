#!/bin/sh
# wait-for.sh - universal wait script for any service
# Usage:
#   ./wait-for.sh host port [--timeout=SECONDS] [-- command args...]
#before 

#exit when script got error
set -e

#distinguish host and port
if echo "$1" | grep -q ":"; then
  HOST=$(echo "$1" | cut -d: -f1)
  PORT=$(echo "$1" | cut -d: -f2)
  shift 1
else
  HOST="$1"
  PORT="$2"
  shift 2
fi

TIMEOUT=60
CMD=""

# Parse optional args like timeout or CMD
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

echo "Waiting for $HOST:$PORT (timeout: ${TIMEOUT}s)..."

start_ts=$(date +%s)

#loop until we find find the host and port
#fail after the timeout
while true; do
  if nc -z "$HOST" "$PORT" >/dev/null 2>&1; then
    echo "$HOST:$PORT is available!"
    break
  fi

  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))

  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "❌ Timeout after ${TIMEOUT}s waiting for $HOST:$PORT"
    exit 1
  fi

  sleep 1
done

# Run the next command if provided
if [ -n "$CMD" ]; then
  echo " Executing command: $CMD"
  exec $CMD
fi

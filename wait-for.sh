#!/bin/sh
# safer wait-for.sh (works with Docker + tail)

#get the host and port
HOST="$1"
PORT="$2"
shift 2

TIMEOUT=60
#command to run after the serice is ready like a variable
CMD=""

# distinguish the timeout and command
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

#just a statement for saying start checking
echo "Waiting for $HOST:$PORT (timeout: ${TIMEOUT}s)..."
start_ts=$(date +%s)

#keep trying to connect to the host and port within the timeout specified
while true; do
  nc -z "$HOST" "$PORT" >/dev/null 2>&1
  #connected
  if [ $? -eq 0 ]; then
    echo "$HOST:$PORT is available!"
    break
  fi
  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  #exit with error if cannot
  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "Timeout after ${TIMEOUT}s waiting for $HOST:$PORT"
    exit 1
  fi
  sleep 1
done

#run the command
if [ -n "$CMD" ]; then
  echo "Executing command: $CMD"
  exec $CMD
fi

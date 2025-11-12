#!/usr/bin/env bash
# server_control.sh - start/stop/restart the Dart server in background
# Usage: ./server_control.sh start|stop|restart [port]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="server.dart"
DEFAULT_PORT=3000
LOG_FILE="$SCRIPT_DIR/server.log"

# Allow overriding dart executable via env var DART_EXEC
: "${DART_EXEC:=dart}"

PORT=${2:-$DEFAULT_PORT}

function get_server_pid() {
  pgrep -f "${DART_EXEC} run $APP" || true
}

function start_server() {
  pid=$(get_server_pid)
  if [ -n "$pid" ]; then
    echo "Server already running (pid $pid)."
    return 0
  fi

  echo "Starting server on port $PORT..."
  # Change to server/bin so relative paths inside server.dart still work
  cd "$SCRIPT_DIR"
  # Overwrite log file on start
  nohup ${DART_EXEC} run "$APP" "$PORT" > "$LOG_FILE" 2>&1 &
  pid=$!
  # Brief pause to allow process to potentially fail fast
  sleep 0.5
  if ! kill -0 "$pid" 2>/dev/null; then
      echo "Server failed to start. Check logs for details: $LOG_FILE"
      return 1
  fi
  echo "Started (pid $pid). Logs: $LOG_FILE"
}

function stop_server() {
  pid=$(get_server_pid)
  if [ -z "$pid" ]; then
    echo "Server not running."
    return 0
  fi

  echo "Stopping server (pid $pid)..."
  kill "$pid"
  # Wait for process to exit
  for i in {1..10}; do
    if kill -0 "$pid" 2>/dev/null; then
      sleep 1
    else
      pid="" # clear pid
      break
    fi
  done

  if [ -n "$pid" ]; then
    echo "Process did not exit gracefully, sending SIGKILL..."
    kill -9 "$pid" || true
  fi
  echo "Stopped."
}

function status_server() {
  pid=$(get_server_pid)
  if [ -n "$pid" ]; then
    echo "Running (pid $pid)."
    exit 0
  else
    echo "Not running."
    exit 1
  fi
}

case "${1:-}" in
  start)
    # allow optional second arg as port
    if [ -n "${2:-}" ]; then
      PORT="$2"
    fi
    start_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server || true
    sleep 1
    if [ -n "${2:-}" ]; then
      PORT="$2"
    fi
    start_server
    ;;
  status)
    status_server
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status} [port]"
    exit 2
    ;;
esac

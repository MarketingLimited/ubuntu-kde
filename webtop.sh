#!/bin/bash
set -euo pipefail

APP_NAME="webtop-kde"
COMPOSE_FILE="docker-compose.yml"
ACTION=${1:-up}  # Default action is 'up'

# Detect whether the Docker Compose plugin or the standalone docker-compose
# binary is available. Prefer the plugin when possible for compatibility.
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker-compose)
else
    echo "❌ Neither 'docker compose' nor 'docker-compose' is installed." >&2
    exit 1
fi

function build_container() {
    echo "🔧 Building $APP_NAME..."
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" build --no-cache
}

function start_container() {
    echo "🚀 Starting $APP_NAME..."
    if ! grep -q "^\s*privileged:\s*true" "$COMPOSE_FILE"; then
        echo "⚠️  $COMPOSE_FILE does not enable privileged mode."
        echo "   PolicyKit and other desktop components may fail to start."
        echo "   Add 'privileged: true' or run with '--security-opt seccomp=unconfined'."
    fi
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" up -d
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" ps
}

function stop_container() {
    echo "🛑 Stopping $APP_NAME..."
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" down
}

function show_logs() {
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" logs -f
}

function open_shell() {
    "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" exec webtop bash
}

function show_help() {
    echo "Usage: ./webtop.sh [build|up|down|restart|status|logs|shell|help]"
}

case "$ACTION" in
    build)
        build_container
        ;;
    up)
        start_container
        ;;
    down)
        stop_container
        ;;
    restart)
        stop_container
        build_container
        start_container
        ;;
    status)
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" ps
        ;;
    logs)
        show_logs
        ;;
    shell)
        open_shell
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❗ Unknown action: $ACTION"
        show_help
        ;;
esac

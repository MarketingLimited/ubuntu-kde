#!/bin/bash

APP_NAME="webtop-kde"
COMPOSE_FILE="docker-compose.yml"
ACTION=${1:-up}  # Default action is 'up'

function build_container() {
    echo "🔧 Building $APP_NAME..."
    docker compose -f "$COMPOSE_FILE" build --no-cache
}

function start_container() {
    echo "🚀 Starting $APP_NAME..."
    docker compose -f "$COMPOSE_FILE" up -d
    docker compose -f "$COMPOSE_FILE" ps
}

function stop_container() {
    echo "🛑 Stopping $APP_NAME..."
    docker compose -f "$COMPOSE_FILE" down
}

function show_help() {
    echo "Usage: ./webtop.sh [build|up|down|restart|status|help]"
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
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❗ Unknown action: $ACTION"
        show_help
        ;;
esac

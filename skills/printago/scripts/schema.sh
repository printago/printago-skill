#!/bin/bash
# Fetch Printago API schemas (no auth required)
set -euo pipefail

show_help() {
  cat << 'EOF'
Usage: ./scripts/schema.sh COMMAND [NAME]

Commands:
  types [name]    List all types, or get schema for a specific type
  paths [path]    List all paths, or get schema for a specific endpoint

Environment:
  PRINTAGO_API_URL   Base URL (default: https://api.printago.io)

Examples:
  # List all available type names
  ./scripts/schema.sh types

  # Get full schema for a type
  ./scripts/schema.sh types Part
  ./scripts/schema.sh types PrintJob
  ./scripts/schema.sh types SkuOptionProperty

  # List all API paths
  ./scripts/schema.sh paths

  # Get schema for an endpoint (shows parameters, request body, response)
  ./scripts/schema.sh paths v1/parts
  ./scripts/schema.sh paths v2/builds
  ./scripts/schema.sh paths v1/sku-option-properties
EOF
  exit 0
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -lt 1 ]] && show_help

COMMAND="$1"
NAME="${2:-}"

API_URL="${PRINTAGO_API_URL:-https://api.printago.io}"

case "$COMMAND" in
  types|paths)
    URL="${API_URL}/v1/hints/schema/${COMMAND}${NAME:+/$NAME}"
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'. Use 'types' or 'paths'."
    exit 1
    ;;
esac

if command -v jq &> /dev/null; then
  curl -sS "$URL" | jq .
else
  curl -sS "$URL"
fi

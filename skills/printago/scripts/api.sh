#!/bin/bash
# Printago API wrapper - handles authentication automatically
set -euo pipefail

show_help() {
  cat << 'EOF'
Usage: ./scripts/api.sh METHOD ENDPOINT [BODY]

Methods: GET, POST, PATCH, PUT, DELETE

Examples:
  ./scripts/api.sh GET /v1/parts
  ./scripts/api.sh GET "/v1/parts?limit=5"
  ./scripts/api.sh POST /v1/parts '{"name":"Test","type":"stl","description":"","fileUris":[],"parameters":[],"printTags":{},"overriddenProcessProfileId":null}'
  ./scripts/api.sh PATCH /v1/parts/abc123 '{"name":"Updated"}'
  ./scripts/api.sh DELETE /v1/parts/abc123

Environment:
  PRINTAGO_API_URL   Base URL (default: https://api.printago.io)
  PRINTAGO_API_KEY    API key (or use keychain)
  PRINTAGO_STORE_ID   Store ID (or use keychain)

  Examples:
    export PRINTAGO_API_URL=http://localhost:3001   # Local dev
    export PRINTAGO_API_URL=https://api.printago.io # Production (default)

Authentication:
  Credentials are loaded from (in order):
  1. Environment variables: PRINTAGO_API_KEY, PRINTAGO_STORE_ID
  2. System keychain (macOS Keychain, Linux secret-tool)

  To store credentials in keychain:
    macOS:  security add-generic-password -s "Printago" -a "apiKey" -w "your-api-key"
            security add-generic-password -s "Printago" -a "storeId" -w "your-store-id"
    Linux:  secret-tool store --label="Printago API Key" service Printago key apiKey
            secret-tool store --label="Printago Store ID" service Printago key storeId
EOF
  exit 0
}

# Get credentials from keychain or env vars
get_credentials() {
  # Try env vars first
  if [[ -n "${PRINTAGO_API_KEY:-}" && -n "${PRINTAGO_STORE_ID:-}" ]]; then
    echo "env"
    return 0
  fi

  # Try system keychain
  case "$(uname -s)" in
    Darwin)
      # macOS Keychain
      PRINTAGO_API_KEY=$(security find-generic-password -s "Printago" -a "apiKey" -w 2>/dev/null) || true
      PRINTAGO_STORE_ID=$(security find-generic-password -s "Printago" -a "storeId" -w 2>/dev/null) || true
      if [[ -n "$PRINTAGO_API_KEY" && -n "$PRINTAGO_STORE_ID" ]]; then
        export PRINTAGO_API_KEY PRINTAGO_STORE_ID
        echo "keychain"
        return 0
      fi
      ;;
    Linux)
      # Linux secret-tool (libsecret)
      if command -v secret-tool &> /dev/null; then
        PRINTAGO_API_KEY=$(secret-tool lookup service Printago key apiKey 2>/dev/null) || true
        PRINTAGO_STORE_ID=$(secret-tool lookup service Printago key storeId 2>/dev/null) || true
        if [[ -n "$PRINTAGO_API_KEY" && -n "$PRINTAGO_STORE_ID" ]]; then
          export PRINTAGO_API_KEY PRINTAGO_STORE_ID
          echo "keychain"
          return 0
        fi
      fi
      ;;
  esac

  echo "none"
  return 1
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && show_help

# Validate arguments
if [[ $# -lt 2 ]]; then
  echo "Error: METHOD and ENDPOINT required" >&2
  echo "Usage: ./api.sh METHOD ENDPOINT [BODY]" >&2
  echo "Run with --help for examples" >&2
  exit 1
fi

# Get credentials - call function directly (not in subshell) so exports persist
get_credentials > /dev/null || {
  echo "Error: No credentials found" >&2
  echo "" >&2
  echo "Set credentials via environment variables:" >&2
  echo "  export PRINTAGO_API_KEY=your-api-key" >&2
  echo "  export PRINTAGO_STORE_ID=your-store-id" >&2
  echo "" >&2
  echo "Or store in system keychain (run --help for instructions)" >&2
  exit 1
}

METHOD="$1"
ENDPOINT="$2"
BODY="${3:-}"

# Auto-inject hints=true for GET requests (provides next-action suggestions)
if [[ "$METHOD" == "GET" ]]; then
  if [[ "$ENDPOINT" == *"?"* ]]; then
    ENDPOINT="${ENDPOINT}&hints=true"
  else
    ENDPOINT="${ENDPOINT}?hints=true"
  fi
fi

# API base URL (default to production)
API_URL="${PRINTAGO_API_URL:-https://api.printago.io}"

# Build curl command
CURL_ARGS=(
  -sS
  -X "$METHOD"
  "${API_URL}${ENDPOINT}"
  -H "Authorization: ApiKey $PRINTAGO_API_KEY"
  -H "X-Printago-StoreId: $PRINTAGO_STORE_ID"
  -H "Content-Type: application/json"
)

# Add body if provided
if [[ -n "$BODY" ]]; then
  CURL_ARGS+=(-d "$BODY")
fi

# Execute and format output
if command -v jq &> /dev/null; then
  curl "${CURL_ARGS[@]}" | jq .
else
  curl "${CURL_ARGS[@]}"
fi

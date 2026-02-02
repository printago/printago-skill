#!/bin/bash
# Upload a file to Printago storage
set -euo pipefail

show_help() {
  cat << 'EOF'
Usage: ./scripts/upload.sh FILE

Uploads a file to Printago storage and returns the path for use in Part creation.

Examples:
  ./scripts/upload.sh model.stl
  ./scripts/upload.sh benchy.3mf

  # Then create part with the returned path:
  api.sh POST /v1/parts '{"name":"My Model","description":"","type":"stl","fileUris":["<path>"],"parameters":[],"printTags":{},"overriddenProcessProfileId":null}'

Environment:
  PRINTAGO_API_URL   Base URL (default: https://api.printago.io)
  PRINTAGO_API_KEY    API key (or use keychain)
  PRINTAGO_STORE_ID   Store ID (or use keychain)

Authentication:
  Credentials are loaded from (in order):
  1. Environment variables: PRINTAGO_API_KEY, PRINTAGO_STORE_ID
  2. System keychain (macOS Keychain, Linux secret-tool)

  Run api.sh --help for keychain setup instructions.
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

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "Error: FILE argument required" >&2
  echo "Usage: ./scripts/upload.sh FILE" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

# Get credentials - call function directly (not in subshell) so exports persist
get_credentials > /dev/null || {
  echo "Error: No credentials found" >&2
  echo "Run api.sh --help for setup instructions" >&2
  exit 1
}

FILENAME=$(basename "$FILE")
API_URL="${PRINTAGO_API_URL:-https://api.printago.io}"

# Step 1: Get signed upload URL
SIGNED_RESPONSE=$(curl -sS -X POST "$API_URL/v1/storage/signed-upload-urls" \
  -H "Authorization: ApiKey $PRINTAGO_API_KEY" \
  -H "X-Printago-StoreId: $PRINTAGO_STORE_ID" \
  -H "Content-Type: application/json" \
  -d "{\"filenames\":[\"$FILENAME\"]}")

UPLOAD_URL=$(echo "$SIGNED_RESPONSE" | jq -r '.signedUrls[0].uploadUrl')
FILE_PATH=$(echo "$SIGNED_RESPONSE" | jq -r '.signedUrls[0].path')

if [[ "$UPLOAD_URL" == "null" || -z "$UPLOAD_URL" ]]; then
  echo "Error: Failed to get signed URL" >&2
  echo "$SIGNED_RESPONSE" | jq . >&2
  exit 1
fi

# Step 2: Upload file
HTTP_CODE=$(curl -sS -X PUT "$UPLOAD_URL" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$FILE" \
  -w "%{http_code}" \
  -o /dev/null)

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "Error: Upload failed with HTTP $HTTP_CODE" >&2
  exit 1
fi

# Output just the path
echo "$FILE_PATH"

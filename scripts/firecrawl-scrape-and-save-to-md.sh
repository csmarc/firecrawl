#!/usr/bin/env bash
set -euo pipefail

# Simple Firecrawl scraper: scrape URL and auto-generate filename

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") URL" >&2
  exit 1
fi

URL="$1"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required" >&2
  exit 1
fi

# Generate safe filename from URL
url_to_filename() {
  local url="$1"
  # Remove protocol
  url="${url#http://}"
  url="${url#https://}"
  # Remove query parameters and fragments
  url="${url%%\?*}"
  url="${url%%#*}"
  # Handle root paths
  if [[ "$url" == */ ]]; then
    url="${url}index"
  fi
  # Replace slashes with double underscores
  url="${url//\//__}"
  # Keep only alphanumeric, dots, dashes, and underscores
  url=$(echo "$url" | tr -cd '[:alnum:]._-')
  # Ensure it's not empty and add extension
  if [[ -z "$url" ]]; then
    url="scraped_content"
  fi
  echo "${url}.md"
}

OUTPUT_FILE=$(url_to_filename "$URL")

# Build request JSON
req_json=$(jq -n --arg url "$URL" '{url: $url, formats: ["markdown"], onlyMainContent: false}')

# Call Firecrawl API
resp=$(curl -sS -X POST "http://localhost:3002/v1/scrape" \
  -H 'Content-Type: application/json' \
  -d "$req_json")

# Extract markdown content
content=$(jq -r '(.data.markdown // .markdown) // empty' <<<"$resp")

if [[ -z "$content" ]]; then
  echo "Error: No markdown content returned" >&2
  exit 1
fi

# Save content
printf '%s' "$content" > "$OUTPUT_FILE"
echo "Saved: $OUTPUT_FILE"



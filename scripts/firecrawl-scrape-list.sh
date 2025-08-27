#!/usr/bin/env bash
set -euo pipefail

# Batch Firecrawl scraper: read URLs from file and scrape each one

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <urls_file>" >&2
  echo "  urls_file: Text file with one URL per line" >&2
  exit 1
fi

URLS_FILE="$1"

# Check if file exists
if [[ ! -f "$URLS_FILE" ]]; then
  echo "Error: File '$URLS_FILE' not found" >&2
  exit 1
fi

# Check if scraping script exists
SCRAPER_SCRIPT="./firecrawl-scrape-and-save-to-md.sh"
if [[ ! -f "$SCRAPER_SCRIPT" ]]; then
  echo "Error: Scraping script '$SCRAPER_SCRIPT' not found" >&2
  exit 1
fi


# Count total URLs
TOTAL_URLS=$(wc -l < "$URLS_FILE" | tr -d ' ')
echo "Found $TOTAL_URLS URLs to scrape from '$URLS_FILE'"
echo "Starting batch scrape..."
echo ""

# Process each URL
CURRENT=0
SUCCESS=0
FAILED=0

while IFS= read -r url || [[ -n "$url" ]]; do
  # Skip empty lines and comments
  if [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]]; then
    continue
  fi
  
  # Trim whitespace
  url=$(echo "$url" | xargs)
  
  # Skip if empty after trimming
  if [[ -z "$url" ]]; then
    continue
  fi
  
  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL_URLS] Scraping: $url"
  
  if ./firecrawl-scrape-and-save-to-md.sh "$url"; then
    echo "  ✅ Success"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ❌ Failed"
    FAILED=$((FAILED + 1))
  fi
  
  echo ""
done < "$URLS_FILE"

# Summary
echo "=== Batch Scrape Complete ==="
echo "Total URLs processed: $CURRENT"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi

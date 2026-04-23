#!/usr/bin/env zsh
# macos_screenshots.sh — Build and screenshot the macOS GiphyDemoApp.
#
# 1. Launch with AUTO_SEARCH=cat → wait for results → screenshot grid
# 2. Click first GIF cell → wait → screenshot detail sheet
#
# Usage (from repo root):
#   GIPHY_API_KEY=your_key bash scripts/macos_screenshots.sh

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/screenshots/macos"
APP="$REPO/.build/debug/GiphyDemoApp"

mkdir -p "$OUT"

KEY="${GIPHY_API_KEY:-}"
[[ -z "$KEY" && -f /tmp/GIPHY_API_KEY ]] && KEY="$(cat /tmp/GIPHY_API_KEY | tr -d '[:space:]')"
[[ -z "$KEY" ]] && { echo "Error: set GIPHY_API_KEY or write key to /tmp/GIPHY_API_KEY"; exit 1; }

echo "▶ Building…"
cd "$REPO"
swift build --product GiphyDemoApp 2>&1 | tail -2

get_bounds() {
  python3 "$REPO/scripts/get_window_bounds.py" GiphyDemoApp
}

screenshot() {
  local name="$1"
  local bounds
  bounds=$(get_bounds) || { echo "  window not found for $name"; exit 1; }
  read -r WX WY WW WH <<< "$bounds"
  screencapture -x -R "$WX,$WY,$WW,$WH" "$OUT/${name}.png"
  echo "📸 ${name}.png  (${WW}x${WH})"
}

# 1. Search results — AUTO_SEARCH triggers viewModel.search() on appear
echo "▶ Launching (AUTO_SEARCH=cat)…"
GIPHY_API_KEY="$KEY" AUTO_SEARCH=cat "$APP" &
APP_PID=$!
trap 'kill $APP_PID 2>/dev/null; true' EXIT
sleep 15  # wait for search results + thumbnail downloads
screenshot "macos_search_results"

# 2. Click first GIF cell (approximate centre of first thumbnail)
bounds=$(get_bounds)
read -r WX WY WW WH <<< "$bounds"
CLICK_X=$((WX + 80))
CLICK_Y=$((WY + 200))
echo "▶ Clicking first GIF cell at ($CLICK_X, $CLICK_Y)…"
cliclick c:${CLICK_X},${CLICK_Y}
sleep 10  # wait for original GIF download
screenshot "macos_gif_detail"

echo "▶ Done."
ls "$OUT"

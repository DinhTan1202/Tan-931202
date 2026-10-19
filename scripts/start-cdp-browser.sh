#!/bin/bash
# Mở Chromium headless với cổng CDP để REA quan sát trang web.
# Dùng: scripts/start-cdp-browser.sh [URL] [PORT]
set -euo pipefail

URL=${1:-about:blank}
PORT=${2:-9222}
CHROME=${REA_BROWSER_EXECUTABLE:-$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | head -1)}
PROFILE=$(mktemp -d -t rea-chrome-XXXXXX)

"$CHROME" --headless=new --no-sandbox --disable-gpu \
  --remote-debugging-address=127.0.0.1 --remote-debugging-port="$PORT" \
  --user-data-dir="$PROFILE" "$URL" >/dev/null 2>&1 &

for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
    echo "CDP endpoint: http://127.0.0.1:$PORT (pid $!, profile $PROFILE)"
    exit 0
  fi
  sleep 0.2
done
echo "Chromium không mở được cổng $PORT" >&2
exit 1

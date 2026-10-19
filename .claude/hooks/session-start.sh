#!/bin/bash
# Cài công cụ cho REA trong phiên Claude Code cloud (Linux x64).
# Idempotent: bỏ qua bước nào đã có sẵn.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GHIDRA_VERSION=12.1.4
GHIDRA_ZIP=ghidra_${GHIDRA_VERSION}_PUBLIC_20260921.zip
GHIDRA_SHA256=ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db
GHIDRA_DIR=/opt/ghidra_${GHIDRA_VERSION}_PUBLIC
REA_VERSION=6.7.0

log() { echo "[rea-setup] $*" >&2; }

# Ghidra (cần JDK 21+, container đã có sẵn)
if [ ! -x "$GHIDRA_DIR/support/analyzeHeadless" ]; then
  log "Tải Ghidra $GHIDRA_VERSION"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/$GHIDRA_ZIP" \
    "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/$GHIDRA_ZIP"
  echo "$GHIDRA_SHA256  $tmp/$GHIDRA_ZIP" | sha256sum -c - >&2
  unzip -q "$tmp/$GHIDRA_ZIP" -d /opt
  rm -rf "$tmp"
fi
ln -sfn "$GHIDRA_DIR" /opt/ghidra

# UPX, Wine (64 + 32-bit) và Xvfb cho .exe
need_apt=()
command -v upx >/dev/null || need_apt+=(upx-ucl)
command -v wine >/dev/null || need_apt+=(wine wine64 wine32:i386 xvfb)
if [ ${#need_apt[@]} -gt 0 ]; then
  log "apt install ${need_apt[*]}"
  dpkg --print-foreign-architectures | grep -qx i386 || dpkg --add-architecture i386
  apt-get update -qq >&2
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${need_apt[@]}" >&2
fi

# asar CLI và cache sẵn gói REA để MCP server khởi động nhanh
command -v asar >/dev/null || npm install -g --silent @electron/asar >&2
npx -y "rea-agents@$REA_VERSION" --version >/dev/null 2>&1 || true

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export GHIDRA_INSTALL_DIR=/opt/ghidra"
    echo "export REA_BROWSER_EXECUTABLE=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | head -1)"
    echo "export WINEDEBUG=-all"
  } >> "$CLAUDE_ENV_FILE"
fi

log "Xong"

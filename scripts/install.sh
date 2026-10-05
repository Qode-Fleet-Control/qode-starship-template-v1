#!/bin/sh
# Install starship with its OFFICIAL installer (https://starship.rs/install.sh), pinned to
# one release, into BIN_DIR (default ./.bin). The Dockerfile runs it with BIN_DIR=/usr/local/bin.
set -eu
STARSHIP_VERSION="${STARSHIP_VERSION:-v1.26.0}"
BIN_DIR="${BIN_DIR:-$(cd "$(dirname "$0")/.." && pwd)/.bin}"
mkdir -p "$BIN_DIR"
installer=$(mktemp)
curl -fsSL https://starship.rs/install.sh -o "$installer"
sh "$installer" --yes --version "$STARSHIP_VERSION" --bin-dir "$BIN_DIR"
rm -f "$installer"
"$BIN_DIR/starship" --version | head -1

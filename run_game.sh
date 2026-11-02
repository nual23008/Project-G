#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -n "${GODOT_BIN:-}" ]]; then
    ENGINE="$GODOT_BIN"
elif command -v godot4 >/dev/null 2>&1; then
    ENGINE="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
    ENGINE="$(command -v godot)"
else
    ENGINE="/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64"
fi
if [[ ! -x "$ENGINE" ]]; then
    echo 'Không tìm thấy Godot 4. Đặt GODOT_BIN=/đường/dẫn/Godot rồi chạy lại.' >&2
    exit 1
fi
exec "$ENGINE" --path "$PROJECT_ROOT/game" "$@"

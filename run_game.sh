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
# GNOME's typing guard disables a laptop touchpad while WASD is held. Scope
# the override to this game process and restore the exact prior preference.
touchpad_previous=""
game_pid=""
restore_pointer() {
    if [[ -n "$touchpad_previous" ]]; then
        gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing "$touchpad_previous" >/dev/null 2>&1 || true
    fi
}
trap restore_pointer EXIT
trap '[[ -z "$game_pid" ]] || kill -TERM "$game_pid" 2>/dev/null; exit 130' INT
trap '[[ -z "$game_pid" ]] || kill -TERM "$game_pid" 2>/dev/null; exit 143' TERM HUP
if [[ " $* " != *" --headless "* && " $* " != *" --script "* && " $* " != *" --editor "* ]] && command -v gsettings >/dev/null 2>&1; then
    touchpad_previous="$(gsettings get org.gnome.desktop.peripherals.touchpad disable-while-typing 2>/dev/null || true)"
    if [[ "$touchpad_previous" == "true" ]]; then
        gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false >/dev/null 2>&1 || touchpad_previous=""
    else
        touchpad_previous=""
    fi
fi
"$ENGINE" --path "$PROJECT_ROOT/game" "$@" &
game_pid=$!
wait "$game_pid"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/home/luan/Downloads/Godot_v4.7.2-stable_linux.x86_64}"
mkdir -p tests/output
"$GODOT_BIN" --headless --path . --import --log-file "$PWD/tests/output/import.log"
if rg -n 'SCRIPT ERROR|^ERROR:' tests/output/import.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/progression_model_test.gd --log-file "$PWD/tests/output/progression-model.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/progression-model.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/progression_combat_test.gd --log-file "$PWD/tests/output/progression-combat.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/progression-combat.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/progression_ui_test.gd --log-file "$PWD/tests/output/progression-ui.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/progression-ui.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/progression_integration_test.gd --log-file "$PWD/tests/output/progression-integration.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/progression-integration.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/art_contract_test.gd --log-file "$PWD/tests/output/art-contract.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/art-contract.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/phase1_test.gd --log-file "$PWD/tests/output/phase2-regression.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/phase2-regression.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/phase2_test.gd --log-file "$PWD/tests/output/phase2-integration.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/phase2-integration.log; then exit 1; fi
"$GODOT_BIN" --headless --path . --fixed-fps 60 --script res://tests/phase2_journey.gd --log-file "$PWD/tests/output/phase2-journey.log"
if rg -n 'SCRIPT ERROR|^ERROR:|^FAIL:' tests/output/phase2-journey.log; then exit 1; fi

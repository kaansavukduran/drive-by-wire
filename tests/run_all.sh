#!/usr/bin/env bash
# Runs every headless test suite; exits non-zero if any suite fails.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
status=0
for t in test_parser test_momo test_garage_save test_run_scene test_arcade_scene test_full_run test_title_ui; do
  out="$("$GODOT" --headless --quit-after 600 --path "$ROOT" --script "res://tests/$t.gd" 2>&1)"
  code=$?
  echo "$out" | grep -E "^(FAIL|-- |RESULT)|SCRIPT ERROR|Parse Error"
  if [ $code -ne 0 ] || ! echo "$out" | grep -q "^RESULT .*: PASS"; then
    echo "SUITE $t FAILED (exit $code)"
    status=1
  fi
done
if [ $status -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit $status

#!/usr/bin/env bash
# Runs every headless test suite; exits non-zero if any suite fails.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
TEST_RUNTIME="$(mktemp -d "${TMPDIR:-/tmp}/drivebywire-tests.XXXXXX")"
trap 'rm -rf "$TEST_RUNTIME"' EXIT
export XDG_DATA_HOME="$TEST_RUNTIME/data"
export XDG_CONFIG_HOME="$TEST_RUNTIME/config"
export XDG_CACHE_HOME="$TEST_RUNTIME/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
status=0
for t in test_parser test_momo test_garage_save test_run_scene test_arcade_scene test_full_run test_title_ui test_save_recovery test_controller_flow test_settings_access test_swipe_story test_story_book test_appearance test_book_flow test_run_fairness test_enemy_warnings test_free_drive test_rear_defense test_briefing_fit test_garage_stage test_result_input test_hud_text test_boss_encounters test_paged_ui test_road_story test_visual_art test_cliff_rescue test_road_presentation test_truck_hatch test_ui_readability; do
  export XDG_DATA_HOME="$TEST_RUNTIME/$t/data"
  export XDG_CONFIG_HOME="$TEST_RUNTIME/$t/config"
  export XDG_CACHE_HOME="$TEST_RUNTIME/$t/cache"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  frame_budget=600
  if [ "$t" = test_road_story ]; then frame_budget=1200; fi
  if [ "$t" = test_paged_ui ]; then frame_budget=3000; fi
  out="$("$GODOT" --headless --quit-after "$frame_budget" --path "$ROOT" --script "res://tests/$t.gd" 2>&1)"
  code=$?
  echo "$out" | grep -E "^(FAIL|-- |RESULT)|SCRIPT ERROR|Parse Error"
  if [ $code -ne 0 ] || ! echo "$out" | grep -q "^RESULT .*: PASS" || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
    echo "SUITE $t FAILED (exit $code)"
    status=1
  fi
done
if [ $status -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit $status

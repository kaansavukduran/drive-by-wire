# scripts/core: Drive-By Wire game logic

Pure GDScript (`extends RefCounted`): no nodes, no Input, no scenes. Randomness only through a `RandomNumberGenerator` you pass in. Load the scripts with `preload`; they do not rely on `class_name`. Every tunable number is in `data/balance.json`.

| File | Role |
|---|---|
| `data_loader.gd` | `load_json(path, fallback={}) -> Dictionary` (never crashes), `parse_json_text(text)`, `dig(dict, "a.b.c", default)`, `num(dict, path, default) -> float`. Path consts: `INTENTS_PATH`, `BALANCE_PATH`, `MOMO_LINES_PATH`, `GARAGE_PATH`. |
| `command_parser.gd` | Text → commands. |
| `momo.gd` | MOMO brain: trust, mood, events, `interpret`, lines, run summary. |
| `garage.gd` | Garage dialogue, memory facts, upgrades as balance modifiers. |
| `save_store.gd` | `user://save.json` load/save (the only file writer). |

## Parser: `command_parser.gd`
- `Parser.new(intents: Dictionary = {}, balance: Dictionary = {})`: empty dictionaries load the default files.
- `parse(text) -> Array[Dictionary]`. Empty or whitespace-only input returns `[]`. Text it cannot match returns `{"intent": "unknown"}`. It never raises an error.
- Command: `{"intent": String, "text": String (normalized segment), "fuzzy": bool, "index": int}`.
  `fire`/`ram` also carry `"target": {"type": "rammer"|"pickup"|"truck"|"", "position": "front"|"behind"|"nearest"|"", "side": "left"|"right"|""}`.
- Intents: `lane_left lane_right speed_up slow_down fire drop_mine dodge ram comfort insult unknown`.
- `parse_intents(text) -> PackedStringArray`; statics `tokenize(text)`, `normalize(text)`, `levenshtein(a, b, max=-1, transpositions=false)`.
- Rules:
  - Chain separators come from `intents.json`.
  - The longest phrase wins, then the lowest edit distance.
  - Target and side words accept Turkish suffixes (`kamyona`, `öndekine`).
  - A bare `sağ`/`sol` is a lane change, but in the same segment as `fire`/`ram` it becomes the target side ("sola ateş et" means shoot the left one; "sola geç ve ateş" is two commands).
  - Repeated insult or comfort commands in one message merge into one.
  - Words in `fuzzy_blocklist` only ever match exactly.

## MOMO: `momo.gd`
- `Momo.new(balance = {}, momo_lines = {}, initial_trust = -1.0)`. Moods: `"scared" "calm" "excited" "sulky"`. Display names: `Momo.mood_name_tr(mood)` → korkmuş/sakin/heyecanlı/küskün.
- Fields: `trust: float` (0–100), `mood: String`, `run_stats: Dictionary`. Methods: `get_state()`, `add_trust(d) -> float applied`, `set_trust(v)`, `set_mood(m)`, `trust_factor()`.
- `start_run()`: records the starting trust and resets the run counters. Mood carries over from the garage. Trust below `start_scared_below_trust` starts the run scared.
- `apply_event(event, rng = null) -> Dictionary`:
  - `event` is a type string or `{"type": "damage", "amount": 30}`.
  - Types: `damage near_miss insult comfort|praise contradictory manoeuvre_success kill unknown_command`.
  - Returns `{type, mood_before, mood, mood_changed, trust_delta, trust, line, line_category}`.
- `note_command(intent, now_sec) -> bool` detects contradictions: an opposite pair (from `contradictory_pairs`) arriving within `contradiction_window_seconds`.
- `interpret(command, rng, now_sec = -1.0) -> Dictionary`. Pass the game time as `now_sec` to turn on contradiction detection. Returns:
  `{action: "execute"|"delay"|"refuse"|"none", command, delay: float s, speed: float, extra: Array[command with "extra": true], line: String ("" = silent), line_category, mood_before, mood, mood_changed, trust, trust_delta, contradictory: bool}`.
  - `none` is returned for comfort, insult and unknown. The event is already applied and `line` holds the reaction.
  - When `action` is `delay`, run the command after `delay` seconds.
  - Run the commands in `extra` as well.
  - Use `speed` as the manoeuvre speed multiplier.
- `pick_line(category, rng = null) -> String`:
  - `category` is a dotted path such as `ack.calm` or `run_end.destroyed.up`.
  - The same line never comes twice in a row within a category.
  - Without an rng it cycles through the lines in order.
- `end_run(outcome: "destroyed"|"survived", rng = null) -> {outcome, trust_before, trust, trust_delta, band: "up"|"flat"|"down", comment, stats}`. `run_trust_delta() -> float`.
- Persistence: `to_save() -> {"trust"}` and `load_save(dict)`. Mood is not saved.

## Garage: `garage.gd`
- `Garage.new(garage_data = {}, balance = {})`.
- Memory: `Garage.default_memory()`, `Garage.sanitize_memory(v)`, `Garage.record_run(memory, run_or_end_run_result) -> new memory`.
  - Memory shape: `{runs, last_outcome, best_distance, total_distance, total_kills, last_trust_delta, insults_total, comforts_total, choice_counts{tag:n}, last_dialogue_id}`.
- `greeting(momo, memory, rng = null) -> {text, band: low|mid|high, memory_key}`.
- `pick_dialogue(trust, memory, rng = null) -> dialogue {id, prompt, options[{id, tag, text, effects, reply}]}`. Returns `{}` when nothing is eligible.
- `eligible_dialogues(trust, memory)` and `find_dialogue(id)`.
- `apply_choice(dialogue, option_id, momo_or_null, memory) -> {ok, reply, tag, trust_delta, mood, next_run_modifiers, memory}`.
  - It changes the trust and mood of the MOMO instance you pass in.
  - The memory you pass in is not modified: store the returned `memory`.
- Upgrades: owned upgrades are `{upgrade_id: level}`.
  - `offer_upgrades(owned, rng = null, count = -1) -> Array` (each item has a `next_level` field).
  - `apply_upgrade(owned, id) -> new owned`.
  - `modifiers_for(owned)`.
  - `effective_balance(balance, owned, extra_modifiers = []) -> Dictionary`: a deep copy with the modifiers applied. Use it for both MOMO and the run.
  - `Garage.apply_modifiers(balance, [{path, op: add|mul|set, value}])`.

## Save: `save_store.gd`
- `SaveStore.new(path = "user://save.json", trust_default = 50.0)`.
- `load_data() -> {version, trust, memory, upgrades}` always returns a valid dictionary, falling back to defaults. `last_error` is one of `"" | missing | unreadable | corrupt | newer_version`.
- `save_data(state) -> bool` writes a temp file, then renames it over the save.
- Also: `defaults()`, `exists()`, `clear()`.

## Example
```gdscript
const DataLoader := preload("res://scripts/core/data_loader.gd")
const Parser := preload("res://scripts/core/command_parser.gd")
const Momo := preload("res://scripts/core/momo.gd")
const Garage := preload("res://scripts/core/garage.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")

var balance := DataLoader.load_json(DataLoader.BALANCE_PATH)
var store := SaveStore.new()
var save := store.load_data()
var garage := Garage.new()
var run_balance := garage.effective_balance(balance, save["upgrades"])
var parser := Parser.new({}, run_balance)
var momo := Momo.new(run_balance, {}, save["trust"])
var rng := RandomNumberGenerator.new()

momo.start_run()
for cmd in parser.parse("sağa geç ve kamyona ateş et"):
    var r := momo.interpret(cmd, rng, game_time)
    show_bubble(r["line"], Momo.mood_name_tr(r["mood"]))
    if r["action"] == "execute": do_command(cmd, r["speed"])
    elif r["action"] == "delay": schedule(cmd, r["delay"])
    for extra in r["extra"]: do_command(extra, r["speed"])
momo.apply_event({"type": "damage", "amount": 15}, rng)   # from gameplay
var summary := momo.end_run("destroyed", rng)              # summary["comment"], ["trust_delta"]
save["memory"] = Garage.record_run(save["memory"], summary)
save["trust"] = momo.trust
store.save_data(save)
```

Tests: `tests/run_all.sh` (or `godot --headless --path . --script tests/test_parser.gd`).

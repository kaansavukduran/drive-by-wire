extends RefCounted
## Tiny assertion helper for headless tests. Each test script extends SceneTree,
## creates a harness, runs checks and calls `quit(h.finish())`.

var suite: String = ""
var passed: int = 0
var failed: int = 0
var failures: PackedStringArray = []


func _init(suite_name: String) -> void:
	suite = suite_name
	print("== %s ==" % suite)


func check(name: String, condition: bool, detail: String = "") -> bool:
	if condition:
		passed += 1
		print("PASS  %s" % name)
	else:
		failed += 1
		var msg := "FAIL  %s%s" % [name, ("  -- " + detail) if detail != "" else ""]
		failures.append(msg)
		print(msg)
	return condition


func eq(name: String, actual: Variant, expected: Variant) -> bool:
	return check(name, actual == expected, "expected %s, got %s" % [str(expected), str(actual)])


func near(name: String, actual: float, expected: float, tolerance: float) -> bool:
	return check(name, absf(actual - expected) <= tolerance, "expected %s ± %s, got %s" % [expected, tolerance, actual])


## Prints the summary and returns the process exit code (0 = all passed).
func finish() -> int:
	print("-- %s: %d passed, %d failed, %d total" % [suite, passed, failed, passed + failed])
	if failed > 0:
		for f in failures:
			print(f)
		print("RESULT %s: FAIL" % suite)
		return 1
	print("RESULT %s: PASS" % suite)
	return 0

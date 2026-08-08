extends SceneTree
## Runs every test_*.gd in res://tests/ and reports a single pass or fail.
##
## Usage:
##     godot --headless --script res://tests/run_all.gd
##
## Optional args:
##     --suite=<substring>   only run suites whose file name contains this
##     --seed=<int>          reproduce a specific random run
##
## Exits 0 when everything passes and 1 when anything fails, so CI can gate on it.

const TESTS_DIR := "res://tests/"

const C_RESET := "[0m"
const C_GREEN := "[32m"
const C_RED := "[31m"
const C_DIM := "[90m"
const C_BOLD := "[1m"


## Nodes added to root during _initialize() never fire _enter_tree, because the tree is not
## live yet. Anything relying on tree callbacks would silently do nothing, so the run waits
## for the first real frame instead.
func _process(_delta: float) -> bool:
	_run()
	return true


func _run() -> void:
	var filter := _arg_value("--suite", "")
	var seed_value := int(_arg_value("--seed", "20260808"))

	var files := _discover(filter)
	files.sort()

	if files.is_empty():
		print("No test files found in %s" % TESTS_DIR)
		quit(1)
		return

	print("")
	print("%sFoxFabric test run%s   %d suites   seed %d" % [C_BOLD, C_RESET, files.size(), seed_value])
	print(_rule())

	var total_passed := 0
	var total_failed := 0
	var broken: Array[String] = []

	for path in files:
		var script: Resource = load(path)
		if script == null:
			broken.append("%s could not be loaded" % path)
			continue

		var suite: Object = script.new()
		if not suite.has_method("run"):
			broken.append("%s has no run() method" % path)
			continue

		suite.root = root
		suite.rng.seed = seed_value
		if suite.suite == "unnamed":
			suite.suite = path.get_file().trim_prefix("test_").trim_suffix(".gd")

		suite.run()

		var passed: int = suite.passed_count()
		var fails: Array = suite.failures()
		suite.cleanup()

		total_passed += passed
		total_failed += fails.size()

		if fails.is_empty():
			print("%s  PASS %s %-22s %s%d checks%s" % [C_GREEN, C_RESET, suite.suite, C_DIM, passed, C_RESET])
		else:
			print("%s  FAIL %s %-22s %s%d passed, %d failed%s" % [C_RED, C_RESET, suite.suite, C_DIM, passed, fails.size(), C_RESET])
			for f in fails:
				print("         %s%s%s" % [C_RED, f, C_RESET])

	print(_rule())

	for b in broken:
		print("%s  BROKEN %s %s" % [C_RED, C_RESET, b])

	if total_failed == 0 and broken.is_empty():
		print("%s  All %d checks passed across %d modules.%s" % [C_GREEN, total_passed, files.size(), C_RESET])
		print("")
		quit(0)
	else:
		print("%s  %d checks failed (%d passed).%s" % [C_RED, total_failed, total_passed, C_RESET])
		print("%s  Reproduce this exact run with --seed=%d%s" % [C_DIM, seed_value, C_RESET])
		print("")
		quit(1)


func _discover(filter: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		return found

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.begins_with("test_") and name.ends_with(".gd"):
			if filter == "" or name.contains(filter):
				found.append(TESTS_DIR + name)
		name = dir.get_next()
	dir.list_dir_end()
	return found


func _arg_value(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with(key + "="):
			return a.split("=", true, 1)[1]
	return fallback


func _rule() -> String:
	return "%s%s%s" % [C_DIM, "-".repeat(62), C_RESET]

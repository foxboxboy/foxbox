extends RefCounted
## Shared engine behind both test entry points.
##
## res://tests/run_all.gd drives this from the command line for CI.
## res://tests/test_runner.tscn drives it from the editor so results can be read on screen.

const TESTS_DIR := "res://tests/"
const DEFAULT_SEED := 20260808


## Finds every test_*.gd, runs it, and returns the collected results.
## [br][br]
## [param root] is where node based tests get parented, so it must be a live tree.
## Returns a dictionary with [code]suites[/code], [code]total_passed[/code],
## [code]total_failed[/code] and [code]broken[/code].
func run(root: Node, filter: String = "", seed_value: int = DEFAULT_SEED) -> Dictionary:
	var files := _discover(filter)
	files.sort()

	var suites: Array[Dictionary] = []
	var broken: Array[String] = []
	var total_passed := 0
	var total_failed := 0

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

		var entry := {
			"name": str(suite.suite),
			"passed": int(suite.passed_count()),
			"failures": suite.failures().duplicate(),
		}
		suite.cleanup()

		total_passed += entry["passed"]
		total_failed += entry["failures"].size()
		suites.append(entry)

	return {
		"suites": suites,
		"total_passed": total_passed,
		"total_failed": total_failed,
		"broken": broken,
		"seed": seed_value,
	}


## Formats results as BBCode. Suitable for [method print_rich] and for a [RichTextLabel],
## which is why both entry points can share one report.
func format(results: Dictionary) -> String:
	var lines: PackedStringArray = []
	var suites: Array = results["suites"]

	lines.append("[b]FoxFabric test run[/b]   %d suites   seed %d" % [suites.size(), results["seed"]])
	lines.append("[color=gray]%s[/color]" % "-".repeat(58))

	for s in suites:
		var fails: Array = s["failures"]
		if fails.is_empty():
			lines.append("[color=green]  PASS[/color]  %s  [color=gray]%d checks[/color]"
				% [s["name"].rpad(22), s["passed"]])
		else:
			lines.append("[color=red]  FAIL[/color]  %s  [color=gray]%d passed, %d failed[/color]"
				% [s["name"].rpad(22), s["passed"], fails.size()])
			for f in fails:
				lines.append("        [color=red]%s[/color]" % f)

	lines.append("[color=gray]%s[/color]" % "-".repeat(58))

	for b in results["broken"]:
		lines.append("[color=red]  BROKEN[/color]  %s" % b)

	if _is_green(results):
		lines.append("[color=green]  All %d checks passed across %d modules.[/color]"
			% [results["total_passed"], suites.size()])
	else:
		lines.append("[color=red]  %d checks failed (%d passed).[/color]"
			% [results["total_failed"], results["total_passed"]])
		lines.append("[color=gray]  Reproduce this exact run with --seed=%d[/color]" % results["seed"])

	return "\n".join(lines)


## Returns [code]true[/code] when nothing failed and nothing was broken.
func _is_green(results: Dictionary) -> bool:
	return results["total_failed"] == 0 and (results["broken"] as Array).is_empty()


func is_green(results: Dictionary) -> bool:
	return _is_green(results)


func _discover(filter: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		return found

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("test_") and entry.ends_with(".gd"):
			# test_runner.gd is an entry point, not a suite
			if entry != "test_runner.gd" and (filter == "" or entry.contains(filter)):
				found.append(TESTS_DIR + entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return found

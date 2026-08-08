extends RefCounted
## Shared engine behind both test entry points.
##
## res://tests/terminal/run_all.gd drives this from the command line for CI.
## res://tests/test_runner/test_runner.tscn drives it from the editor so results can be read
## on screen.
##
## Suites are found by scanning res://tests/ recursively for test_*.gd, so they can be
## organised into any folder layout.

## Suites are typed against their base class rather than duck typed, so calling into them does
## not produce unsafe access warnings.
const FoxTest = preload("res://tests/fox_test.gd")

const TESTS_DIR: String = "res://tests/"

## Passing this as the seed picks a fresh one each run, so repeated runs cover different random
## cases instead of the same ones forever. The chosen seed is printed in the report, and passing
## it back with --seed reproduces that run exactly.
const RANDOM_SEED: int = 0


## One suite's outcome. A class rather than a Dictionary so the fields carry types.
class SuiteResult extends RefCounted:
	var name: String = ""
	var passed: int = 0
	var failures: Array[String] = []


## Everything a run produced.
class RunResult extends RefCounted:
	var suites: Array[SuiteResult] = []
	var broken: Array[String] = []
	var total_passed: int = 0
	var total_failed: int = 0
	var seed_used: int = 0

	## A run with no suites in it is a failure, not a pass. A mistyped filter or a moved tests
	## folder finds nothing, and reporting that as green is how a broken CI job looks healthy.
	func is_green() -> bool:
		return not suites.is_empty() and total_failed == 0 and broken.is_empty()


## Finds every test_*.gd, runs it, and returns the collected results.
## [br][br]
## [param root] is where node based tests get parented, so it must be a live tree.
func run(root: Node, filter: String = "", seed_value: int = RANDOM_SEED) -> RunResult:
	if seed_value == RANDOM_SEED:
		seed_value = randi()

	var results: RunResult = RunResult.new()
	results.seed_used = seed_value

	var files: Array[String] = _discover(filter)
	files.sort()

	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null:
			results.broken.append("%s could not be loaded" % path)
			continue

		var suite: FoxTest = script.new()
		if suite == null:
			results.broken.append("%s does not extend fox_test.gd" % path)
			continue

		suite.root = root
		suite.rng.seed = seed_value
		if suite.suite == "unnamed":
			suite.suite = path.get_file().trim_prefix("test_").trim_suffix(".gd")

		suite.run()

		var entry: SuiteResult = SuiteResult.new()
		entry.name = suite.suite
		entry.passed = suite.passed_count()
		entry.failures = suite.failures().duplicate()
		suite.cleanup()

		results.total_passed += entry.passed
		results.total_failed += entry.failures.size()
		results.suites.append(entry)

	return results


## Formats results as BBCode. Suitable for [method print_rich] and for a [RichTextLabel],
## which is why both entry points can share one report.
func format(results: RunResult) -> String:
	var lines: PackedStringArray = []

	lines.append("[b]FoxFabric test run[/b]   %d suites   seed %d"
		% [results.suites.size(), results.seed_used])
	lines.append("[color=gray]%s[/color]" % "-".repeat(58))

	for s: SuiteResult in results.suites:
		if s.failures.is_empty():
			lines.append("[color=green]  PASS[/color]  %s  [color=gray]%d checks[/color]"
				% [s.name.rpad(22), s.passed])
		else:
			lines.append("[color=red]  FAIL[/color]  %s  [color=gray]%d passed, %d failed[/color]"
				% [s.name.rpad(22), s.passed, s.failures.size()])
			for f: String in s.failures:
				lines.append("        [color=red]%s[/color]" % f)

	lines.append("[color=gray]%s[/color]" % "-".repeat(58))

	for b: String in results.broken:
		lines.append("[color=red]  BROKEN[/color]  %s" % b)

	if results.suites.is_empty():
		lines.append("[color=red]  No suites ran. Check the --suite filter and %s.[/color]"
			% TESTS_DIR)
	elif results.is_green():
		lines.append("[color=green]  All %d checks passed across %d modules.[/color]"
			% [results.total_passed, results.suites.size()])
	else:
		lines.append("[color=red]  %d checks failed (%d passed).[/color]"
			% [results.total_failed, results.total_passed])
		lines.append("[color=gray]  Reproduce this exact run with --seed=%d[/color]"
			% results.seed_used)

	return "\n".join(lines)


func _discover(filter: String) -> Array[String]:
	var found: Array[String] = []
	_scan(TESTS_DIR, filter, found)
	return found


func _scan(path: String, filter: String, found: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = path.path_join(entry)
		if dir.current_is_dir():
			_scan(full, filter, found)
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			# test_runner.gd is an entry point, not a suite
			if entry != "test_runner.gd" and (filter == "" or entry.contains(filter)):
				found.append(full)
		entry = dir.get_next()
	dir.list_dir_end()

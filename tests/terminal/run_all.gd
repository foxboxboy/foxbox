extends SceneTree
## Command line entry point for the test suite. For the editor, open test_runner.tscn instead.
##
## Usage:
##     godot --headless --path . --script res://tests/terminal/run_all.gd
##
## Optional args:
##     --suite=<substring>   only run suites whose file name contains this
##     --seed=<int>          reproduce a specific random run
##
## Exits 0 when everything passes and 1 when anything fails, so CI can gate on it.

const Runner = preload("res://tests/fox_test_runner.gd")

var _attempted: bool = false


## Nodes added to root during _initialize() never fire _enter_tree, because the tree is not
## live yet. Anything relying on tree callbacks would silently do nothing, so the run waits
## for the first real frame instead.
func _process(_delta: float) -> bool:
	# Returning false asks for another frame, and an error anywhere below aborts this function
	# before quit() is reached. Without this, that error repeats every frame and the process never
	# ends: a broken suite once produced 18000 rounds of it. One attempt is all a run gets.
	if _attempted:
		printerr("The test run did not finish. See the errors above.")
		quit(1)
		return true
	_attempted = true

	var runner: Runner = Runner.new()
	var results: Runner.RunResult = runner.run(
		root,
		_arg_value("--suite", ""),
		int(_arg_value("--seed", str(Runner.RANDOM_SEED)))
	)

	print("")
	print_rich(runner.format(results))
	print("")

	quit(0 if results.is_green() else 1)
	return true


func _arg_value(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with(key + "="):
			return a.split("=", true, 1)[1]
	return fallback

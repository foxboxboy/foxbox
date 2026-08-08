extends SceneTree
## Command line entry point for the test suite. For the editor, open test_runner.tscn instead.
##
## Usage:
##     godot --headless --path . --script res://tests/run_all.gd
##
## Optional args:
##     --suite=<substring>   only run suites whose file name contains this
##     --seed=<int>          reproduce a specific random run
##
## Exits 0 when everything passes and 1 when anything fails, so CI can gate on it.

const Runner: GDScript = preload("res://tests/fox_test_runner.gd")


## Nodes added to root during _initialize() never fire _enter_tree, because the tree is not
## live yet. Anything relying on tree callbacks would silently do nothing, so the run waits
## for the first real frame instead.
func _process(_delta: float) -> bool:
	var runner: RefCounted = Runner.new()
	var results: Dictionary = runner.run(
		root,
		_arg_value("--suite", ""),
		int(_arg_value("--seed", str(Runner.RANDOM_SEED)))
	)

	print("")
	print_rich(runner.format(results))
	print("")

	quit(0 if runner.is_green(results) else 1)
	return true


func _arg_value(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with(key + "="):
			return a.split("=", true, 1)[1]
	return fallback

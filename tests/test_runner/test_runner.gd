extends Control
## Editor entry point for the test suite. Open test_runner.tscn and press F6.
##
## Results are drawn on screen and printed to the Output panel. For CI, use
## res://tests/terminal/run_all.gd from the command line instead.

const Runner = preload("res://tests/fox_test_runner.gd")

## Only run suites whose file name contains this. Leave blank to run everything.
@export var suite_filter: String = ""

## Seed for the randomised cases. Leave at 0 to pick a fresh one each run, or paste a seed from
## an earlier report to reproduce it exactly.
@export var random_seed: int = Runner.RANDOM_SEED

@onready var _output: RichTextLabel = $Report


func _ready() -> void:
	# One frame of breathing room so the tree is fully live before node based tests parent into it.
	await get_tree().process_frame

	var runner: Runner = Runner.new()
	var results: Runner.RunResult = runner.run(self, suite_filter, random_seed)
	if results == null:
		_output.text = "[color=red]The run did not finish. See the Output panel.[/color]"
		printerr("The test run did not finish.")
		return

	var report: String = runner.format(results)

	_output.text = report
	print_rich(report)

	var headline: String = "ALL PASSED" if results.is_green() else "FAILURES"
	print_rich("[b]%s[/b]  %d passed, %d failed"
		% [headline, results.total_passed, results.total_failed])

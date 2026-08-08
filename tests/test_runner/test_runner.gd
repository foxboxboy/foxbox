extends Control
## Editor entry point for the test suite. Open test_runner.tscn and press F6.
##
## Results are drawn on screen and printed to the Output panel. For CI, use
## res://tests/run_all.gd from the command line instead.

const Runner := preload("res://tests/fox_test_runner.gd")

## Only run suites whose file name contains this. Leave blank to run everything.
@export var suite_filter: String = ""

## Seed for the randomised cases. Keeping it fixed makes failures reproducible.
@export var random_seed: int = Runner.DEFAULT_SEED

@onready var _output: RichTextLabel = $Report


func _ready() -> void:
	# One frame of breathing room so the tree is fully live before node based tests parent into it.
	await get_tree().process_frame

	var runner := Runner.new()
	var results := runner.run(self, suite_filter, random_seed)
	var report := runner.format(results)

	_output.text = report
	print_rich(report)

	var headline := "ALL PASSED" if runner.is_green(results) else "FAILURES"
	print_rich("[b]%s[/b]  %d passed, %d failed" % [headline, results["total_passed"], results["total_failed"]])

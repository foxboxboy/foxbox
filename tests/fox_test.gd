extends RefCounted
## Base class for every FoxFabric test file.
##
## Subclass it, override [method run], and call the assert helpers. The runner collects results
## and never lets a failure stop the rest of the suite.

## Human readable name for this suite, shown in the report.
var suite: String = "unnamed"

## Populated by the runner so node based tests have somewhere to parent to.
var root: Node = null

## Seeded so a failing random case can always be reproduced.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _passed: int = 0
var _failures: Array[String] = []
var _current: String = ""
var _nodes: Array[Node] = []


## Override this. Call the helpers below as many times as you like.
func run() -> void:
	pass


## Groups the checks that follow under a readable label.
func case(label: String) -> void:
	_current = label


## Passes when [param condition] is true.
func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_fail(label, "expected true, got false")


## Passes when [param actual] equals [param expected].
func eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_fail(label, "expected %s, got %s" % [_show(expected), _show(actual)])


## Passes when two floats are within [param epsilon].
func almost(actual: float, expected: float, label: String, epsilon: float = 0.00001) -> void:
	if absf(actual - expected) <= epsilon:
		_passed += 1
	else:
		_fail(label, "expected %f, got %f" % [expected, actual])


## Registers a node with the tree so its _ready runs, and queues it for cleanup.
func track(node: Node) -> Node:
	_nodes.append(node)
	if root:
		root.add_child(node)
	return node


## Frees everything created through [method track]. The runner calls this automatically.
func cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()


func passed_count() -> int:
	return _passed


func failures() -> Array[String]:
	return _failures


func _fail(label: String, detail: String) -> void:
	var where: String = _current + " / " if _current != "" else ""
	_failures.append("%s%s  ->  %s" % [where, label, detail])


func _show(v: Variant) -> String:
	if v is float:
		return "%.6f" % v
	return str(v)

extends "res://tests/fox_test.gd"
## The 2D half of the interaction pipeline.
##
## Mirrors test_interaction.gd. Kept as its own suite so the report shows at a glance whether 2D
## is covered, rather than hiding it inside the 3D one.


## Records what the virtual hooks receive. The base implementations do nothing, so without a
## subclass there is no way to tell that they ran.
class ProbeInteractable extends FoxInteractableArea2D:
	var interacts: Array[Variant] = []
	var focuses: Array[Node] = []
	var unfocuses: Array[Node] = []

	func _interact(context: Variant) -> void:
		interacts.append(context)

	func _focus(sensor: Node) -> void:
		focuses.append(sensor)

	func _unfocus(sensor: Node) -> void:
		unfocuses.append(sensor)


func run() -> void:
	suite = "interaction_2d"
	_interact_routes_the_context()
	_focus_and_unfocus()
	_interaction_range()
	_no_target_is_harmless()
	_unfocus_reports_settled_state()


func _interact_routes_the_context() -> void:
	case("interact")
	var area: ProbeInteractable = track(ProbeInteractable.new()) as ProbeInteractable
	var seen: Array[Variant] = []
	area.interacted.connect(func(c: Variant) -> void: seen.append(c))

	area.interact({"who": "player", "hand": &"right"})

	eq(seen.size(), 1, "interacting emits once")
	eq(seen[0]["who"], "player", "the context arrives untouched")
	eq(area.interacts.size(), 1, "the virtual hook runs as well")
	check(area.interacts[0] == seen[0], "signal and hook get the same context")

	case("no context")
	area.interact()
	eq(seen[1], null, "context defaults to null")


func _focus_and_unfocus() -> void:
	case("focus")
	var area: ProbeInteractable = track(ProbeInteractable.new()) as ProbeInteractable
	var sensor: Node2D = track(Node2D.new()) as Node2D
	var focused: Array[Node] = []
	var unfocused: Array[Node] = []
	area.focused.connect(func(s: Node) -> void: focused.append(s))
	area.unfocused.connect(func(s: Node) -> void: unfocused.append(s))

	area.focus(sensor)
	eq(focused.size(), 1, "focusing emits")
	check(focused[0] == sensor, "the sensor is passed along")
	eq(area.focuses.size(), 1, "the virtual hook runs")

	area.unfocus(sensor)
	eq(unfocused.size(), 1, "unfocusing emits")
	check(unfocused[0] == sensor, "the sensor is passed along again")
	eq(area.unfocuses.size(), 1, "the virtual hook runs")


func _interaction_range() -> void:
	case("interaction range")
	var ray: FoxInteractionRayCast2D = track(FoxInteractionRayCast2D.new()) as FoxInteractionRayCast2D
	var reported: Array[float] = []
	ray.interaction_range_changed.connect(func(r: float) -> void: reported.append(r))

	ray.interaction_range = 5.0
	# 2D casts along +X, which is the direction Node2D.look_at orients towards. The 3D node
	# casts along -Z for the same reason, and the difference is the engine's, not this class's.
	check(ray.target_position.is_equal_approx(Vector2(5.0, 0.0)),
		"the range casts along local +X")
	eq(reported.size(), 1, "changing the range emits")

	case("the sentinel leaves target_position alone")
	ray.target_position = Vector2(12.0, 0.0)
	ray.interaction_range = -1.0
	check(ray.target_position.is_equal_approx(Vector2(12.0, 0.0)),
		"-1.0 means the target_position set in the inspector wins")
	eq(reported.size(), 2, "the sentinel still reports the change")


func _no_target_is_harmless() -> void:
	case("nothing focused")
	var ray: FoxInteractionRayCast2D = track(FoxInteractionRayCast2D.new()) as FoxInteractionRayCast2D

	check(ray.get_current_target() == null, "nothing is focused to begin with")

	# Interacting with empty air is normal, not an error.
	ray.interact_with_target({"any": "payload"})
	check(ray.get_current_target() == null, "interacting with nothing changes nothing")


## Regression: unfocused used to be emitted before the target was cleared, so a handler that
## asked the sensor what it was pointing at was told the node it had just lost. A readout built
## that way claimed to be aimed at a prop while the ray pointed at nothing.
func _unfocus_reports_settled_state() -> void:
	case("unfocus ordering")
	var ray: FoxInteractionRayCast2D = track(FoxInteractionRayCast2D.new()) as FoxInteractionRayCast2D
	var area: FoxInteractableArea2D = track(FoxInteractableArea2D.new()) as FoxInteractableArea2D
	ray._current_target = area

	# an Array, because a lambda captures a plain local by value and the write would be lost
	var during: Array = []
	var passed: Array = []
	ray.unfocused.connect(func(a: FoxInteractableArea2D) -> void:
		during.append(ray.get_current_target())
		passed.append(a))

	ray._clear_target()

	eq(during.size(), 1, "unfocused fired once")
	eq(during[0], null, "the sensor already reports no target while the signal is handled")
	eq(passed[0], area, "and the signal still says which one was lost")

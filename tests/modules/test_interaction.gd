extends FoxTest
## Checks focus routing and the interaction payload.
##
## Finding a target needs a physics step, so what is covered here is the range setter and the
## routing that does not depend on a collision.


## Records what the virtual hooks receive. The base implementations do nothing, so without a
## subclass there is no way to tell that they ran.
class ProbeInteractable extends FoxInteractableArea3D:
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
	suite = "interaction"
	_interact_routes_the_context()
	_focus_and_unfocus()
	_interaction_range()
	_no_target_is_harmless()
	_unfocus_reports_settled_state()


func _interact_routes_the_context() -> void:
	start_case("interact")
	var area: ProbeInteractable = track(ProbeInteractable.new()) as ProbeInteractable
	var seen: Array[Variant] = []
	area.interacted.connect(func(c: Variant) -> void: seen.append(c))

	area.interact({"who": "player", "hand": &"right"})

	check_equal(seen.size(), 1, "interacting emits once")
	check_equal(seen[0]["who"], "player", "the context arrives untouched")
	check_equal(area.interacts.size(), 1, "the virtual hook runs as well")
	check(area.interacts[0] == seen[0], "signal and hook get the same context")

	start_case("no context")
	area.interact()
	check_equal(seen[1], null, "context defaults to null")


func _focus_and_unfocus() -> void:
	start_case("focus")
	var area: ProbeInteractable = track(ProbeInteractable.new()) as ProbeInteractable
	var sensor: Node3D = track(Node3D.new()) as Node3D
	var focused: Array[Node] = []
	var unfocused: Array[Node] = []
	area.focused.connect(func(s: Node) -> void: focused.append(s))
	area.unfocused.connect(func(s: Node) -> void: unfocused.append(s))

	area.focus(sensor)
	check_equal(focused.size(), 1, "focusing emits")
	check(focused[0] == sensor, "the sensor is passed along")
	check_equal(area.focuses.size(), 1, "the virtual hook runs")

	area.unfocus(sensor)
	check_equal(unfocused.size(), 1, "unfocusing emits")
	check(unfocused[0] == sensor, "the sensor is passed along again")
	check_equal(area.unfocuses.size(), 1, "the virtual hook runs")


func _interaction_range() -> void:
	start_case("interaction range")
	var ray: FoxInteractionRayCast3D = track(FoxInteractionRayCast3D.new()) as FoxInteractionRayCast3D
	var reported: Array[float] = []
	ray.interaction_range_changed.connect(func(r: float) -> void: reported.append(r))

	ray.interaction_range = 5.0
	check(ray.target_position.is_equal_approx(Vector3(0.0, 0.0, -5.0)),
		"the range casts down local -Z")
	check_equal(reported.size(), 1, "changing the range emits")

	start_case("the sentinel leaves target_position alone")
	ray.target_position = Vector3(0.0, 0.0, -12.0)
	ray.interaction_range = -1.0
	check(ray.target_position.is_equal_approx(Vector3(0.0, 0.0, -12.0)),
		"-1.0 means the target_position set in the inspector wins")
	check_equal(reported.size(), 2, "the sentinel still reports the change")


func _no_target_is_harmless() -> void:
	start_case("nothing focused")
	var ray: FoxInteractionRayCast3D = track(FoxInteractionRayCast3D.new()) as FoxInteractionRayCast3D

	check(ray.get_current_target() == null, "nothing is focused to begin with")

	# Interacting with empty air is normal, not an error. Every frame the player presses use
	# while looking at nothing lands here.
	ray.interact_with_target({"any": "payload"})
	check(ray.get_current_target() == null, "interacting with nothing changes nothing")


## Regression: unfocused used to be emitted before the target was cleared, so a handler that
## asked the sensor what it was pointing at was told the node it had just lost. A readout built
## that way claimed to be aimed at a prop while the ray pointed at nothing.
func _unfocus_reports_settled_state() -> void:
	start_case("unfocus ordering")
	var ray: FoxInteractionRayCast3D = track(FoxInteractionRayCast3D.new()) as FoxInteractionRayCast3D
	var area: FoxInteractableArea3D = track(FoxInteractableArea3D.new()) as FoxInteractableArea3D
	ray._current_target = area

	# an Array, because a lambda captures a plain local by value and the write would be lost
	var during: Array = []
	var passed: Array = []
	ray.unfocused.connect(func(a: FoxInteractableArea3D) -> void:
		during.append(ray.get_current_target())
		passed.append(a))

	ray._clear_target()

	check_equal(during.size(), 1, "unfocused fired once")
	check_equal(during[0], null, "the sensor already reports no target while the signal is handled")
	check_equal(passed[0], area, "and the signal still says which one was lost")

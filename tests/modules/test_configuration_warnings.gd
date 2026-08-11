extends FoxTest
## Checks the editor configuration warnings.
##
## These call _get_configuration_warnings() directly rather than going through the editor, so
## they verify the detection logic, not that Godot draws the triangle. A warning that fires when
## it should not is just as bad as one that never fires, so both directions are covered.
## [br][br]
## Nothing here covers a shape missing from an area or a body. Godot already warns for those, and
## repeating an engine warning only makes the node show the same problem twice.


class ProbeState extends FoxState:
	func enter() -> void: pass
	func exit() -> void: pass
	func update(_delta: float) -> void: pass
	func physics_update(_delta: float) -> void: pass


func run() -> void:
	suite = "configuration_warnings"
	_hit_raycast()
	_hit_shapecast()
	_hit_casts_2d()
	_interaction_raycasts()
	_state_machine()
	_effect_slot_policy()
	_socket_marker()
	_socket_map()
	_aim_gimbal()
	_zoom_spring_arm()
	_shop_menu()


## True when any warning mentions [param fragment].
func _has(warnings: PackedStringArray, fragment: String) -> bool:
	for w: String in warnings:
		if w.contains(fragment):
			return true
	return false


func _hit_raycast() -> void:
	start_case("FoxHitRayCast3D")
	var ray: FoxHitRayCast3D = track(FoxHitRayCast3D.new()) as FoxHitRayCast3D

	ray.collide_with_areas = false
	ray.enabled = true
	check(_has(ray._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")

	ray.collide_with_areas = true
	check(not _has(ray._get_configuration_warnings(), "Collide With Areas"),
		"silent once areas are enabled")

	# fire() calls force_raycast_update(), which the engine documents as ignoring enabled.
	ray.enabled = false
	check_equal(ray._get_configuration_warnings().size(), 0, "stays quiet about enabled, since fire() works regardless")


func _hit_shapecast() -> void:
	start_case("FoxHitShapeCast3D")
	var cast: FoxHitShapeCast3D = track(FoxHitShapeCast3D.new()) as FoxHitShapeCast3D

	cast.collide_with_areas = false
	check(_has(cast._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")

	cast.collide_with_areas = true
	check_equal(cast._get_configuration_warnings().size(), 0, "silent once areas are enabled")


func _hit_casts_2d() -> void:
	start_case("FoxHitRayCast2D")
	var ray: FoxHitRayCast2D = track(FoxHitRayCast2D.new()) as FoxHitRayCast2D

	ray.collide_with_areas = false
	check(_has(ray._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")
	check(_has(ray._get_configuration_warnings(), "FoxHurtArea2D"),
		"and names the 2D hurtbox, not the 3D one")

	ray.collide_with_areas = true
	check_equal(ray._get_configuration_warnings().size(), 0, "silent once areas are enabled")

	start_case("FoxHitShapeCast2D")
	var cast: FoxHitShapeCast2D = track(FoxHitShapeCast2D.new()) as FoxHitShapeCast2D

	cast.collide_with_areas = false
	check(_has(cast._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")

	cast.collide_with_areas = true
	# ShapeCast2D reports a missing shape itself, so there is nothing left to say.
	check_equal(cast._get_configuration_warnings().size(), 0, "silent once areas are enabled")


func _interaction_raycasts() -> void:
	start_case("FoxInteractionRayCast3D")
	var ray: FoxInteractionRayCast3D = track(FoxInteractionRayCast3D.new()) as FoxInteractionRayCast3D

	ray.collide_with_areas = false
	check(_has(ray._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")
	check(_has(ray._get_configuration_warnings(), "FoxInteractableArea3D"),
		"and names what it is looking for")

	ray.collide_with_areas = true
	check_equal(ray._get_configuration_warnings().size(), 0, "silent once areas are enabled")

	start_case("FoxInteractionRayCast2D")
	var flat: FoxInteractionRayCast2D = track(FoxInteractionRayCast2D.new()) as FoxInteractionRayCast2D

	flat.collide_with_areas = false
	check(_has(flat._get_configuration_warnings(), "Collide With Areas"),
		"warns when it cannot see areas")
	check(_has(flat._get_configuration_warnings(), "FoxInteractableArea2D"),
		"and names the 2D interactable, not the 3D one")

	flat.collide_with_areas = true
	check_equal(flat._get_configuration_warnings().size(), 0, "silent once areas are enabled")


func _state_machine() -> void:
	start_case("FoxStateMachine")
	var empty: FoxStateMachine = track(FoxStateMachine.new()) as FoxStateMachine
	check(_has(empty._get_configuration_warnings(), "No FoxState children"),
		"warns with no states")

	var sm: FoxStateMachine = FoxStateMachine.new()
	var idle: ProbeState = ProbeState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	track(sm)

	check(_has(sm._get_configuration_warnings(), "No Initial State"),
		"warns when no initial state is set")

	sm.initial_state = idle
	check_equal(sm._get_configuration_warnings().size(), 0, "silent once configured")

	start_case("initial state from another machine")
	var other: FoxStateMachine = FoxStateMachine.new()
	var stray: ProbeState = ProbeState.new()
	stray.name = "Stray"
	other.add_child(stray)
	track(other)

	sm.initial_state = stray
	check(_has(sm._get_configuration_warnings(), "not a child"),
		"warns when the initial state belongs elsewhere")

	start_case("colliding state keys")
	# Godot renames duplicate sibling node names, so a collision can only come from state_id.
	var dupes: FoxStateMachine = FoxStateMachine.new()
	var a: ProbeState = ProbeState.new()
	var b: ProbeState = ProbeState.new()
	a.name = "A"
	b.name = "B"
	a.state_id = &"same"
	b.state_id = &"same"
	dupes.add_child(a)
	dupes.add_child(b)
	dupes.initial_state = a
	track(dupes)

	check(_has(dupes._get_configuration_warnings(), "resolve to the key 'same'"),
		"warns when two states share a key")


func _effect_slot_policy() -> void:
	start_case("FoxEffectSlotPolicy")
	var orphan: FoxEffectSlotPolicy = track(FoxEffectSlotPolicy.new()) as FoxEffectSlotPolicy
	check(_has(orphan._get_configuration_warnings(), "not a FoxEffectManager"),
		"warns when the parent is not a manager")

	var manager: FoxEffectManager = track(FoxEffectManager.new()) as FoxEffectManager
	var policy: FoxEffectSlotPolicy = FoxEffectSlotPolicy.new()
	manager.add_child(policy)
	check_equal(policy._get_configuration_warnings().size(), 0, "silent under a manager")

	policy.max_slots = 0
	check(_has(policy._get_configuration_warnings(), "no effect can ever be admitted"),
		"warns when no slots are available")


func _socket_marker() -> void:
	start_case("FoxSocket3D")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var socket: FoxSocket3D = FoxSocket3D.new()
	holder.add_child(socket)

	check_equal(socket._get_configuration_warnings().size(), 0, "an untouched socket warns about nothing")

	var outsider: Node3D = Node3D.new()
	holder.add_child(outsider)
	socket.marker = outsider
	check(_has(socket._get_configuration_warnings(), "not this socket"),
		"warns when the marker sits outside the socket")

	var inner: Node3D = Node3D.new()
	socket.add_child(inner)
	socket.marker = inner
	check_equal(socket._get_configuration_warnings().size(), 0, "a descendant marker is fine")


func _socket_map() -> void:
	start_case("FoxSocketMap3D")
	var empty: FoxSocketMap3D = track(FoxSocketMap3D.new()) as FoxSocketMap3D
	check(_has(empty._get_configuration_warnings(), "manages nothing"),
		"warns when it holds no sockets")

	var map: FoxSocketMap3D = FoxSocketMap3D.new()
	var one: FoxSocket3D = FoxSocket3D.new()
	one.name = "Driver"
	map.add_child(one)
	track(map)
	check_equal(map._get_configuration_warnings().size(), 0, "silent with one socket")

	start_case("colliding socket names")
	# Siblings get auto renamed, so a collision needs sockets under different parents.
	var branch: Node3D = Node3D.new()
	var two: FoxSocket3D = FoxSocket3D.new()
	two.name = "Driver"
	branch.add_child(two)
	map.add_child(branch)

	check(_has(map._get_configuration_warnings(), "named 'Driver'"),
		"warns when two nested sockets share a name")


func _aim_gimbal() -> void:
	start_case("FoxAimGimbal3D")
	var g: FoxAimGimbal3D = track(FoxAimGimbal3D.new()) as FoxAimGimbal3D
	check_equal(g._get_configuration_warnings().size(), 0, "defaults warn about nothing")

	g.min_pitch_deg = 40.0
	g.max_pitch_deg = -40.0
	check(_has(g._get_configuration_warnings(), "Min Pitch"), "warns on an inverted pitch range")

	g.clamp_pitch = false
	check(not _has(g._get_configuration_warnings(), "Min Pitch"),
		"silent when pitch is not clamped, since the range is unused")

	g.clamp_yaw = true
	g.min_yaw_deg = 30.0
	g.max_yaw_deg = -30.0
	check(_has(g._get_configuration_warnings(), "Min Yaw"), "warns on an inverted yaw range")


func _zoom_spring_arm() -> void:
	start_case("FoxZoomSpringArm3D")
	var arm: FoxZoomSpringArm3D = track(FoxZoomSpringArm3D.new()) as FoxZoomSpringArm3D
	check_equal(arm._get_configuration_warnings().size(), 0, "defaults warn about nothing")

	arm.max_length = 0.0
	check(_has(arm._get_configuration_warnings(), "never extend"), "warns on a zero max length")

	arm.max_length = 200.0
	arm.zoom_speed = 0.0
	check(_has(arm._get_configuration_warnings(), "never reach"), "warns on a zero zoom speed")


func _shop_menu() -> void:
	start_case("FoxShopMenu")
	var menu: FoxShopMenu = track(FoxShopMenu.new()) as FoxShopMenu
	var warnings: PackedStringArray = menu._get_configuration_warnings()

	check(_has(warnings, "No Slot Scene"), "warns with no slot scene")
	check(_has(warnings, "No Container"), "warns with no container")

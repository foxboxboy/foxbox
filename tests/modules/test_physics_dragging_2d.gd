extends "res://tests/fox_test.gd"
## The 2D half of physics dragging.
##
## Only the target rotation is covered here, same as the 3D suite: everything else applies forces
## to a live RigidBody2D and needs a physics step to mean anything.


const Dragger = preload("res://addons/foxfabric/physics_dragging/2d/fox_physics_dragger_2d.gd")


func run() -> void:
	suite = "physics_dragging_2d"
	_defaults_leave_rotation_free()
	_off_copies_the_dragger()
	_on_holds_it_level()
	_profile_is_shared_with_3d()


func _defaults_leave_rotation_free() -> void:
	case("defaults")
	var profile: FoxPhysicsDragProfile = FoxPhysicsDragProfile.new()
	check(not profile.keep_upright, "a fresh profile leaves rotation free")

	var dragger: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	check(not dragger.default_keep_upright, "so does a dragger with no profile")


func _off_copies_the_dragger() -> void:
	case("keep upright off")
	for degrees: float in [0.0, 35.0, -120.0, 179.0]:
		var radians: float = deg_to_rad(degrees)
		almost(Dragger.target_rotation_for(radians, false), radians,
			"at %d degrees the body copies the dragger" % int(degrees))


func _on_holds_it_level() -> void:
	case("keep upright on")
	for degrees: float in [0.0, 35.0, -120.0, 179.0]:
		almost(Dragger.target_rotation_for(deg_to_rad(degrees), true), 0.0,
			"at %d degrees the body is still held level" % int(degrees))

	case("invariant across random angles")
	var tilted: int = 0
	for i: int in 200:
		var angle: float = rng.randf_range(-TAU, TAU)
		if not is_equal_approx(Dragger.target_rotation_for(angle, true), 0.0):
			tilted += 1

	eq(tilted, 0, "no angle produced a tilted target across 200 tries")


## The profile is deliberately not duplicated per dimension, so it has to keep working for both.
func _profile_is_shared_with_3d() -> void:
	case("one profile, both dimensions")
	var profile: FoxPhysicsDragProfile = FoxPhysicsDragProfile.new()
	profile.stiffness = 123.0
	profile.damping = 4.0
	profile.keep_upright = true

	var flat: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	var solid: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D

	# grab() is what reads a profile. Accepting it is guaranteed by the type, so what is worth
	# checking is that both draggers actually take the values off it.
	var body_2d: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	var body_3d: RigidBody3D = track(RigidBody3D.new()) as RigidBody3D

	flat.grab(body_2d, Vector2.ZERO, profile)
	solid.grab(body_3d, Vector3.ZERO, profile)

	almost(flat._current_stiffness, 123.0, "the 2D dragger took the profile's stiffness")
	almost(solid._current_stiffness, 123.0, "and so did the 3D one")
	almost(flat._current_damping, 4.0, "the 2D dragger took the profile's damping")
	almost(solid._current_damping, 4.0, "and so did the 3D one")
	check(flat._current_keep_upright, "the 2D dragger took keep_upright")
	check(solid._current_keep_upright, "and so did the 3D one")

	case("and fall back to their own defaults without one")
	flat.grab(body_2d, Vector2.ZERO)
	almost(flat._current_stiffness, flat.default_stiffness, "no profile means the node's default")

	flat.release()
	solid.release()

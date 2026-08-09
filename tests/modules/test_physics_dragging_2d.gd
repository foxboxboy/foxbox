extends "res://tests/fox_test.gd"
## The 2D half of physics dragging.
##
## Only the target rotation is covered here, same as the 3D suite: everything else applies forces
## to a live RigidBody2D and needs a physics step to mean anything.


const Dragger = preload("res://addons/foxfabric/physics_dragging/2d/fox_physics_dragger_2d.gd")


func run() -> void:
	suite = "physics_dragging_2d"
	_grab_point_rides_the_body()
	_the_command_cannot_outrun_the_body()
	_defaults_leave_rotation_free()
	_off_copies_the_dragger()
	_on_holds_it_level()
	_profile_is_shared_with_3d()
	_torque_scale_guards_bad_input()
	_swing_cannot_outrun_the_spring()


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


## A body's inertia is in pixels squared, so it dwarfs its mass and an unscaled torque turns
## nothing. The scale cancels that, but only the guards are checkable here: the real figure comes
## from the physics server, which has nothing to report until a body has been through a physics
## step, and this harness never runs one.
func _torque_scale_guards_bad_input() -> void:
	case("torque scale guards")
	almost(Dragger.torque_scale_for(null), 1.0, "a null body scales by one")

	# There is no massless case to cover. RigidBody2D refuses a mass of zero, so the guard against
	# it is unreachable from outside and testing it would only prove the engine clamps.

	# No shape means no rotational inertia for the server to report.
	var shapeless: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	almost(Dragger.torque_scale_for(shapeless), 1.0, "a body with no shape scales by one")

	case("the rotation gains are matched")
	# They were briefly not. Rotation was damped harder to make up for demo profiles whose
	# damping sat far below critical; fixing those removed the reason. A mismatch now would mean
	# the same two numbers describe a different response for turning than for pulling.
	almost(Dragger.TORQUE_DAMPING_GAIN, Dragger.TORQUE_SPRING_GAIN,
		"turning uses the same gain as pulling, so one profile describes both")


## Regression: the pull used to be applied straight at the grab point, which is the same as a
## central pull plus the torque that lever produces. On a long prop that torque was larger than
## the orientation spring could remove, so a flicked plank span one way, was dragged back the
## other, and never settled. Measured six seconds after a flick it was still turning.
func _swing_cannot_outrun_the_spring() -> void:
	case("swing response")
	var dragger: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D

	check(dragger.swing_response > 0.0,
		"some of the lever survives, or a plank held by one end would not trail behind")
	check(dragger.swing_response < 1.0,
		"but not all of it, or the pull out torques the spring and the prop never settles")


## Where a body is being held, for drawing a marker or spawning something there. It is a fixed
## spot on the body, so it has to travel with it rather than stay put in the world.
func _grab_point_rides_the_body() -> void:
	case("grab point")
	var dragger: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	dragger.global_position = Vector2(10, 20)

	check(not dragger.is_holding(), "nothing is held to begin with")
	check(dragger.get_grab_point().is_equal_approx(Vector2(10, 20)),
		"with nothing held it reports its own position, so a marker parked on it stays put")

	var body: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	body.global_position = Vector2(100, 100)
	dragger.grab(body, Vector2(140, 100))

	check(dragger.is_holding(), "holding once a grab lands")
	check(dragger.get_grab_point().is_equal_approx(Vector2(140, 100)),
		"the point is where the body was taken hold of, not its centre")

	case("and travels with the body")
	body.global_position = Vector2(300, 100)
	check(dragger.get_grab_point().is_equal_approx(Vector2(340, 100)),
		"moving the body carries the grab point along")

	dragger.release()
	check(not dragger.is_holding(), "not holding once released")


## Regression: the torque takes the shortest way to its target, so a command more than half a turn
## ahead of the body pointed backwards and the body unwound against the drag instead of following.
func _the_command_cannot_outrun_the_body() -> void:
	case("the command cannot get more than a quarter turn ahead")
	var dragger: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	var body: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	dragger.grab(body, Vector2.ZERO)

	# Wind the command a long way past what the body has managed to follow.
	for i: int in 20:
		dragger.rotate(deg_to_rad(45.0))
		dragger._rein_in_rotation()

	var lead: float = angle_difference(body.global_rotation, dragger.global_rotation)
	check(absf(lead) <= dragger.max_rotation_lead + 0.001,
		"twenty 45 degree turns leave the command within the lead, not wrapped around behind")
	check(lead > 0.0, "and ahead of the body, which is the way it was turned")

	case("winding the other way is just as bounded")
	for i: int in 20:
		dragger.rotate(deg_to_rad(-45.0))
		dragger._rein_in_rotation()

	var back: float = angle_difference(body.global_rotation, dragger.global_rotation)
	check(absf(back) <= dragger.max_rotation_lead + 0.001, "still within the lead")
	check(back < 0.0, "and behind the body now")

	case("keep_upright has no command to outrun")
	var upright: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	var held: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	upright.default_keep_upright = true
	upright.grab(held, Vector2.ZERO)
	# Not PI, which sits exactly on the wrap boundary and reads back as -PI.
	upright.global_rotation = 2.0
	upright._rein_in_rotation()
	almost(upright.global_rotation, 2.0, "the node is left exactly where it was put")

	case("the lead is tunable")
	var tight: FoxPhysicsDragger2D = track(FoxPhysicsDragger2D.new()) as FoxPhysicsDragger2D
	var prop: RigidBody2D = track(RigidBody2D.new()) as RigidBody2D
	tight.max_rotation_lead = deg_to_rad(20.0)
	tight.grab(prop, Vector2.ZERO)

	for i: int in 20:
		tight.rotate(deg_to_rad(45.0))
		tight._rein_in_rotation()

	var held_close: float = angle_difference(prop.global_rotation, tight.global_rotation)
	almost(held_close, deg_to_rad(20.0), "a shorter lead is honoured", 0.001)
	almost(FoxPhysicsDragger2D.DEFAULT_ROTATION_LEAD, PI / 2.0, "and the default is still a quarter turn")

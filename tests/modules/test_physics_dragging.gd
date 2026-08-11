extends FoxTest
## Checks the orientation a dragger pulls a held body towards.
##
## Only the target basis is covered. Everything else in the module applies forces to a live
## RigidBody3D, which needs a physics step to mean anything.


const Dragger = preload("res://addons/foxfabric/physics_dragging/3d/fox_physics_dragger_3d.gd")

## How far the result may sit off world up before it counts as tipped.
const TILT_EPSILON: float = 0.0001


func run() -> void:
	suite = "physics_dragging"
	_grab_point_rides_the_body()
	_defaults_leave_rotation_free()
	_off_copies_the_dragger()
	_on_stays_level()
	_on_still_follows_yaw()
	_straight_down()
	_random_orientations_never_tip()
	_the_command_cannot_outrun_the_body()


## The basis of a dragger pitched, yawed, and rolled by the given degrees.
func _posed(pitch: float, yaw: float, roll: float) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), deg_to_rad(roll)))


func _defaults_leave_rotation_free() -> void:
	start_case("defaults")
	# A profile saved before keep_upright existed does not store it, so it falls back to this.
	# Defaulting it on silently turned free rotation into yaw only for every existing profile.
	var profile: FoxPhysicsDragProfile = FoxPhysicsDragProfile.new()
	check(not profile.keep_upright, "a fresh profile leaves rotation free")

	var dragger: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	check(not dragger.default_keep_upright, "so does a dragger with no profile")


func _off_copies_the_dragger() -> void:
	start_case("keep upright off")
	var posed: Basis = _posed(35.0, 20.0, 15.0)
	var result: Basis = Dragger.target_basis_for(posed, false)

	check(result.is_equal_approx(posed), "the body copies the dragger exactly")


func _on_stays_level() -> void:
	start_case("keep upright on")
	var result: Basis = Dragger.target_basis_for(_posed(35.0, 20.0, 15.0), true)

	check_almost_equal(result.y.angle_to(Vector3.UP), 0.0, "up axis points at world up", TILT_EPSILON)
	check_almost_equal(result.z.y, 0.0, "forward axis is level", TILT_EPSILON)
	check_almost_equal(result.x.y, 0.0, "side axis is level", TILT_EPSILON)


func _on_still_follows_yaw() -> void:
	start_case("yaw is preserved")
	# Yaw only, so flattening should leave the basis untouched.
	var flat: Basis = _posed(0.0, 70.0, 0.0)
	var result: Basis = Dragger.target_basis_for(flat, true)

	check(result.is_equal_approx(flat), "a level dragger is already its own target")

	start_case("yaw survives pitch and roll")
	var tilted: Basis = _posed(40.0, 70.0, 25.0)
	var upright: Basis = Dragger.target_basis_for(tilted, true)
	var forward: Vector3 = -tilted.z
	forward.y = 0.0

	check_almost_equal((-upright.z).angle_to(forward.normalized()), 0.0,
		"facing matches the dragger flattened onto the horizon", TILT_EPSILON)


func _straight_down() -> void:
	start_case("looking straight down")
	# The usual case for a camera mounted dragger, and the one that hands looking_at a zero
	# vector if the fallback is missing.
	for pitch: float in [-90.0, 90.0]:
		var result: Basis = Dragger.target_basis_for(_posed(pitch, 0.0, 0.0), true)

		check(result.determinant() > 0.0, "pitch %d produces a usable basis" % int(pitch))
		check_almost_equal(result.y.angle_to(Vector3.UP), 0.0,
			"pitch %d still resolves to level" % int(pitch), TILT_EPSILON)


func _random_orientations_never_tip() -> void:
	start_case("invariant across random orientations")
	var tipped: int = 0
	var degenerate: int = 0

	for i: int in 300:
		var posed: Basis = _posed(
			rng.randf_range(-180.0, 180.0),
			rng.randf_range(-180.0, 180.0),
			rng.randf_range(-180.0, 180.0))
		var result: Basis = Dragger.target_basis_for(posed, true)

		if not is_finite(result.determinant()) or result.determinant() <= 0.0:
			degenerate += 1
		elif result.y.angle_to(Vector3.UP) > 0.001:
			tipped += 1

	check_equal(degenerate, 0, "no orientation produced an unusable basis")
	check_equal(tipped, 0, "no orientation tipped the target across 300 tries")


## Where a body is being held, for drawing a marker or spawning something there. It is a fixed
## spot on the body, so it has to travel with it rather than stay put in the world.
func _grab_point_rides_the_body() -> void:
	start_case("grab point")
	var dragger: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	dragger.global_position = Vector3(10, 20, 0)

	check(not dragger.is_holding(), "nothing is held to begin with")
	check(dragger.get_grab_point().is_equal_approx(Vector3(10, 20, 0)),
		"with nothing held it reports its own position, so a marker parked on it stays put")

	var body: RigidBody3D = track(RigidBody3D.new()) as RigidBody3D
	body.global_position = Vector3(100, 100, 0)
	dragger.grab(body, Vector3(140, 100, 0))

	check(dragger.is_holding(), "holding once a grab lands")
	check(dragger.get_grab_point().is_equal_approx(Vector3(140, 100, 0)),
		"the point is where the body was taken hold of, not its centre")

	start_case("and travels with the body")
	body.global_position = Vector3(300, 100, 0)
	check(dragger.get_grab_point().is_equal_approx(Vector3(340, 100, 0)),
		"moving the body carries the grab point along")

	dragger.release()
	check(not dragger.is_holding(), "not holding once released")


## Regression: the same shortest-way problem as in 2D, but the axis flips instead of the sign.
func _the_command_cannot_outrun_the_body() -> void:
	start_case("the command cannot get more than a quarter turn ahead")
	var dragger: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	var body: RigidBody3D = track(RigidBody3D.new()) as RigidBody3D
	dragger.grab(body, Vector3.ZERO)

	for i: int in 20:
		dragger.rotate(Vector3.UP, deg_to_rad(45.0))
		dragger._rein_in_rotation()

	var held: Basis = body.global_transform.basis.orthonormalized()
	var lead: Quaternion = (dragger.global_transform.basis.orthonormalized() * held.inverse()).get_rotation_quaternion()
	var angle: float = lead.get_angle()
	if angle > PI:
		angle -= TAU

	check(absf(angle) <= dragger.max_rotation_lead + 0.001,
		"twenty 45 degree turns leave the command within the lead, not wrapped around behind")

	start_case("keep_upright has no command to outrun")
	var upright: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	var carried: RigidBody3D = track(RigidBody3D.new()) as RigidBody3D
	upright.default_keep_upright = true
	upright.grab(carried, Vector3.ZERO)
	upright.rotate(Vector3.UP, PI)
	var before: Basis = upright.global_transform.basis
	upright._rein_in_rotation()
	check(upright.global_transform.basis.is_equal_approx(before),
		"the node is left exactly where it was put")

	start_case("reining the command in does not touch the node's scale")
	var scaled: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	var lifted: RigidBody3D = track(RigidBody3D.new()) as RigidBody3D
	scaled.scale = Vector3(2.0, 3.0, 4.0)
	scaled.grab(lifted, Vector3.ZERO)

	for i: int in 20:
		scaled.rotate(Vector3.UP, deg_to_rad(45.0))
		scaled._rein_in_rotation()

	check(scaled.scale.is_equal_approx(Vector3(2.0, 3.0, 4.0)),
		"a scaled dragger keeps its scale, which writing the basis back would have flattened")

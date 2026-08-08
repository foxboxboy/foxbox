extends "res://tests/fox_test.gd"
## Checks the orientation a dragger pulls a held body towards.
##
## Only the target basis is covered. Everything else in the module applies forces to a live
## RigidBody3D, which needs a physics step to mean anything.


const Dragger = preload("res://addons/foxfabric/physics_dragging/fox_physics_dragger_3d.gd")

## How far the result may sit off world up before it counts as tipped.
const TILT_EPSILON: float = 0.0001


func run() -> void:
	suite = "physics_dragging"
	_defaults_leave_rotation_free()
	_off_copies_the_dragger()
	_on_stays_level()
	_on_still_follows_yaw()
	_straight_down()
	_random_orientations_never_tip()


## The basis of a dragger pitched, yawed, and rolled by the given degrees.
func _posed(pitch: float, yaw: float, roll: float) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), deg_to_rad(roll)))


func _defaults_leave_rotation_free() -> void:
	case("defaults")
	# A profile saved before keep_upright existed does not store it, so it falls back to this.
	# Defaulting it on silently turned free rotation into yaw only for every existing profile.
	var profile: FoxPhysicsDragProfile = FoxPhysicsDragProfile.new()
	check(not profile.keep_upright, "a fresh profile leaves rotation free")

	var dragger: FoxPhysicsDragger3D = track(FoxPhysicsDragger3D.new()) as FoxPhysicsDragger3D
	check(not dragger.default_keep_upright, "so does a dragger with no profile")


func _off_copies_the_dragger() -> void:
	case("keep upright off")
	var posed: Basis = _posed(35.0, 20.0, 15.0)
	var result: Basis = Dragger.target_basis_for(posed, false)

	check(result.is_equal_approx(posed), "the body copies the dragger exactly")


func _on_stays_level() -> void:
	case("keep upright on")
	var result: Basis = Dragger.target_basis_for(_posed(35.0, 20.0, 15.0), true)

	almost(result.y.angle_to(Vector3.UP), 0.0, "up axis points at world up", TILT_EPSILON)
	almost(result.z.y, 0.0, "forward axis is level", TILT_EPSILON)
	almost(result.x.y, 0.0, "side axis is level", TILT_EPSILON)


func _on_still_follows_yaw() -> void:
	case("yaw is preserved")
	# Yaw only, so flattening should leave the basis untouched.
	var flat: Basis = _posed(0.0, 70.0, 0.0)
	var result: Basis = Dragger.target_basis_for(flat, true)

	check(result.is_equal_approx(flat), "a level dragger is already its own target")

	case("yaw survives pitch and roll")
	var tilted: Basis = _posed(40.0, 70.0, 25.0)
	var upright: Basis = Dragger.target_basis_for(tilted, true)
	var forward: Vector3 = -tilted.z
	forward.y = 0.0

	almost((-upright.z).angle_to(forward.normalized()), 0.0,
		"facing matches the dragger flattened onto the horizon", TILT_EPSILON)


func _straight_down() -> void:
	case("looking straight down")
	# The usual case for a camera mounted dragger, and the one that hands looking_at a zero
	# vector if the fallback is missing.
	for pitch: float in [-90.0, 90.0]:
		var result: Basis = Dragger.target_basis_for(_posed(pitch, 0.0, 0.0), true)

		check(result.determinant() > 0.0, "pitch %d produces a usable basis" % int(pitch))
		almost(result.y.angle_to(Vector3.UP), 0.0,
			"pitch %d still resolves to level" % int(pitch), TILT_EPSILON)


func _random_orientations_never_tip() -> void:
	case("invariant across random orientations")
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

	eq(degenerate, 0, "no orientation produced an unusable basis")
	eq(tipped, 0, "no orientation tipped the target across 300 tries")

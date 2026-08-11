extends FoxTest

## The editor gizmo. Only its static side is reachable: the engine refuses to instantiate an
## EditorNode3DGizmoPlugin outside the editor.
const GIZMO_PATH: String = "res://addons/foxfabric/aim_gimbal/editor/fox_aim_gimbal_3d_gizmo.gd"

## Arc segments plus a spoke at each end, two points per segment.
const ARC_POINTS: int = 32 * 2 + 4


func run() -> void:
	suite = "aim_gimbal"
	_pitch_clamps_by_default()
	_pitch_wraps_when_unclamped()
	_yaw_wraps_by_default()
	_yaw_clamps_when_enabled()
	_rotation_follows_the_values()
	_random_input_never_escapes_the_clamp()
	_gizmo_draws_the_range()


func _gimbal() -> FoxAimGimbal3D:
	return track(FoxAimGimbal3D.new()) as FoxAimGimbal3D


func _gizmo_draws_the_range() -> void:
	start_case("gizmo")
	var gizmo: GDScript = load(GIZMO_PATH) as GDScript
	check(gizmo != null, "the gizmo script loads")
	if gizmo == null:
		return

	var g: FoxAimGimbal3D = _gimbal()
	check(gizmo.handles(g), "it claims FoxAimGimbal3D nodes")
	check(not gizmo.handles(track(Node3D.new()) as Node3D), "and nothing else")
	check(FoxFabric.GIZMOS.has(GIZMO_PATH), "the plugin lists it")

	start_case("the arc spans the clamp range")
	g.min_yaw_deg = -60.0
	g.max_yaw_deg = 60.0
	var yaw_arc: PackedVector3Array = gizmo.build_yaw_arc(g)
	check_equal(yaw_arc.size(), ARC_POINTS, "the sweep is segments plus two spokes")

	# Every arc point sits on the radius. The spokes start at the origin, so they are skipped.
	var off_radius: int = 0
	for i: int in 32 * 2:
		if not is_equal_approx(yaw_arc[i].length(), gizmo.RADIUS):
			off_radius += 1
	check_equal(off_radius, 0, "every arc point sits on the radius")

	# Yaw sweeps the horizontal plane, so nothing in it should leave that plane.
	var lifted: int = 0
	for i: int in 32 * 2:
		if absf(yaw_arc[i].y) > 0.0001:
			lifted += 1
	check_equal(lifted, 0, "the yaw arc stays flat")

	start_case("the pitch arc leaves the horizontal plane")
	g.min_pitch_deg = -45.0
	g.max_pitch_deg = 45.0
	var pitch_arc: PackedVector3Array = gizmo.build_pitch_arc(g)
	check_equal(pitch_arc.size(), ARC_POINTS, "the sweep is segments plus two spokes")

	var highest: float = -999.0
	var lowest: float = 999.0
	for i: int in 32 * 2:
		highest = maxf(highest, pitch_arc[i].y)
		lowest = minf(lowest, pitch_arc[i].y)
	check_almost_equal(highest, gizmo.RADIUS * sin(deg_to_rad(45.0)), "the arc reaches the upper limit")
	check_almost_equal(lowest, gizmo.RADIUS * sin(deg_to_rad(-45.0)), "and the lower one")

	start_case("the arc ignores the gimbal's own rotation")
	# The range is measured against the parent, so aiming the gimbal must not drag the arc with
	# it. Undoing the rotation is the one part of this easy to get subtly wrong.
	var resting: PackedVector3Array = gizmo.build_yaw_arc(g)
	g.rotation = Vector3(deg_to_rad(30.0), deg_to_rad(70.0), 0.0)
	var aimed: PackedVector3Array = gizmo.build_yaw_arc(g)

	var matched: int = 0
	for i: int in resting.size():
		# Back into the parent's frame, where both should describe the same arc.
		if (g.transform.basis * aimed[i]).is_equal_approx(resting[i]):
			matched += 1
	check_equal(matched, resting.size(), "the arc stays put in the parent's frame while the gimbal aims")


func _pitch_clamps_by_default() -> void:
	start_case("pitch clamping")
	var g: FoxAimGimbal3D = _gimbal()
	check(g.clamp_pitch, "pitch is clamped by default")

	g.pitch = deg_to_rad(45.0)
	check_almost_equal(rad_to_deg(g.pitch), 45.0, "a value inside the range is kept", 0.001)

	g.pitch = deg_to_rad(500.0)
	check_almost_equal(rad_to_deg(g.pitch), g.max_pitch_deg, "above the range clamps to max", 0.001)

	g.pitch = deg_to_rad(-500.0)
	check_almost_equal(rad_to_deg(g.pitch), g.min_pitch_deg, "below the range clamps to min", 0.001)


func _pitch_wraps_when_unclamped() -> void:
	start_case("pitch wrapping")
	var g: FoxAimGimbal3D = _gimbal()
	g.clamp_pitch = false

	g.pitch = PI * 3.0
	check(g.pitch >= -PI and g.pitch <= PI, "an unclamped pitch is wrapped into range")


func _yaw_wraps_by_default() -> void:
	start_case("yaw wrapping")
	var g: FoxAimGimbal3D = _gimbal()
	check(not g.clamp_yaw, "yaw wraps rather than clamps by default")

	g.yaw = PI * 4.5
	check(g.yaw >= -PI and g.yaw <= PI, "yaw was wrapped into range")

	# turning all the way around returns close to where it started
	var h: FoxAimGimbal3D = _gimbal()
	h.yaw = 0.0
	h.yaw = TAU
	check_almost_equal(h.yaw, 0.0, "a full turn wraps back to zero", 0.0001)


func _yaw_clamps_when_enabled() -> void:
	start_case("yaw clamping")
	var g: FoxAimGimbal3D = _gimbal()
	g.clamp_yaw = true
	g.min_yaw_deg = -30.0
	g.max_yaw_deg = 30.0

	g.yaw = deg_to_rad(90.0)
	check_almost_equal(rad_to_deg(g.yaw), 30.0, "above the range clamps to max", 0.001)

	g.yaw = deg_to_rad(-90.0)
	check_almost_equal(rad_to_deg(g.yaw), -30.0, "below the range clamps to min", 0.001)


func _rotation_follows_the_values() -> void:
	start_case("node rotation")
	var g: FoxAimGimbal3D = _gimbal()
	g.pitch = deg_to_rad(30.0)
	g.yaw = deg_to_rad(45.0)

	check_almost_equal(g.rotation.x, g.pitch, "rotation.x tracks pitch")
	check_almost_equal(g.rotation.y, g.yaw, "rotation.y tracks yaw")


func _random_input_never_escapes_the_clamp() -> void:
	start_case("invariant under random input")
	var breaches: int = 0

	for i: int in 200:
		var g: FoxAimGimbal3D = _gimbal()
		g.min_pitch_deg = rng.randf_range(-89.0, -10.0)
		g.max_pitch_deg = rng.randf_range(10.0, 89.0)

		for j: int in 25:
			g.pitch += deg_to_rad(rng.randf_range(-200.0, 200.0))

			var deg: float = rad_to_deg(g.pitch)
			if deg < g.min_pitch_deg - 0.001 or deg > g.max_pitch_deg + 0.001:
				breaches += 1

	check_equal(breaches, 0, "pitch stayed inside its limits across 5000 random movements")

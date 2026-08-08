extends "res://tests/fox_test.gd"


func run() -> void:
	suite = "aim_gimbal"
	_pitch_clamps_by_default()
	_pitch_wraps_when_unclamped()
	_yaw_wraps_by_default()
	_yaw_clamps_when_enabled()
	_rotation_follows_the_values()
	_random_input_never_escapes_the_clamp()


func _gimbal() -> FoxAimGimbal3D:
	return track(FoxAimGimbal3D.new()) as FoxAimGimbal3D


func _pitch_clamps_by_default() -> void:
	case("pitch clamping")
	var g := _gimbal()
	check(g.clamp_pitch, "pitch is clamped by default")

	g.pitch = deg_to_rad(45.0)
	almost(rad_to_deg(g.pitch), 45.0, "a value inside the range is kept", 0.001)

	g.pitch = deg_to_rad(500.0)
	almost(rad_to_deg(g.pitch), g.max_pitch_deg, "above the range clamps to max", 0.001)

	g.pitch = deg_to_rad(-500.0)
	almost(rad_to_deg(g.pitch), g.min_pitch_deg, "below the range clamps to min", 0.001)


func _pitch_wraps_when_unclamped() -> void:
	case("pitch wrapping")
	var g := _gimbal()
	g.clamp_pitch = false

	g.pitch = PI * 3.0
	check(g.pitch >= -PI and g.pitch <= PI, "an unclamped pitch is wrapped into range")


func _yaw_wraps_by_default() -> void:
	case("yaw wrapping")
	var g := _gimbal()
	check(not g.clamp_yaw, "yaw wraps rather than clamps by default")

	g.yaw = PI * 4.5
	check(g.yaw >= -PI and g.yaw <= PI, "yaw was wrapped into range")

	# turning all the way around returns close to where it started
	var h := _gimbal()
	h.yaw = 0.0
	h.yaw = TAU
	almost(h.yaw, 0.0, "a full turn wraps back to zero", 0.0001)


func _yaw_clamps_when_enabled() -> void:
	case("yaw clamping")
	var g := _gimbal()
	g.clamp_yaw = true
	g.min_yaw_deg = -30.0
	g.max_yaw_deg = 30.0

	g.yaw = deg_to_rad(90.0)
	almost(rad_to_deg(g.yaw), 30.0, "above the range clamps to max", 0.001)

	g.yaw = deg_to_rad(-90.0)
	almost(rad_to_deg(g.yaw), -30.0, "below the range clamps to min", 0.001)


func _rotation_follows_the_values() -> void:
	case("node rotation")
	var g := _gimbal()
	g.pitch = deg_to_rad(30.0)
	g.yaw = deg_to_rad(45.0)

	almost(g.rotation.x, g.pitch, "rotation.x tracks pitch")
	almost(g.rotation.y, g.yaw, "rotation.y tracks yaw")


func _random_input_never_escapes_the_clamp() -> void:
	case("invariant under random input")
	var breaches := 0

	for i in 200:
		var g := _gimbal()
		g.min_pitch_deg = rng.randf_range(-89.0, -10.0)
		g.max_pitch_deg = rng.randf_range(10.0, 89.0)

		for j in 25:
			g.pitch += deg_to_rad(rng.randf_range(-200.0, 200.0))

			var deg := rad_to_deg(g.pitch)
			if deg < g.min_pitch_deg - 0.001 or deg > g.max_pitch_deg + 0.001:
				breaches += 1

	eq(breaches, 0, "pitch stayed inside its limits across 5000 random movements")

extends "res://tests/fox_test.gd"
## Checks the zoom arithmetic and its bounds.
##
## The interpolation itself runs in _process and needs frames, so what is covered here is the
## target the arm interpolates towards, which is where the clamping lives.


func run() -> void:
	suite = "zoom_spring_arm"
	_stepping()
	_clamping()
	_zoom_enabled_gate()
	_percentage()
	_random_zooming_stays_in_range()


## An arm in the tree, so _ready has run, sitting halfway out.
func _arm() -> FoxZoomSpringArm3D:
	var arm: FoxZoomSpringArm3D = track(FoxZoomSpringArm3D.new()) as FoxZoomSpringArm3D
	arm.max_length = 10.0
	arm.zoom_step = 1.0
	arm.target_length = 5.0
	return arm


func _stepping() -> void:
	case("stepping")
	var arm: FoxZoomSpringArm3D = _arm()

	arm.zoom_out()
	almost(arm.target_length, 6.0, "zooming out adds a step")

	arm.zoom_in()
	almost(arm.target_length, 5.0, "zooming in takes it back")


func _clamping() -> void:
	case("bounds")
	var arm: FoxZoomSpringArm3D = _arm()

	arm.change_zoom(9999.0)
	almost(arm.target_length, 10.0, "cannot go past max_length")

	arm.change_zoom(-9999.0)
	almost(arm.target_length, 0.0, "cannot go below zero")


func _zoom_enabled_gate() -> void:
	case("zoom_enabled")
	var arm: FoxZoomSpringArm3D = _arm()
	arm.zoom_enabled = false

	arm.zoom_out()
	arm.zoom_in()
	almost(arm.target_length, 5.0, "stepping is ignored while disabled")

	case("change_zoom is not gated")
	# zoom_in and zoom_out are the input facing calls. change_zoom is the direct one, so
	# disabling input does not lock out a script driving the arm itself.
	arm.change_zoom(2.0)
	almost(arm.target_length, 7.0, "setting the zoom directly still works")


func _percentage() -> void:
	case("percentage")
	var arm: FoxZoomSpringArm3D = _arm()

	arm.spring_length = 5.0
	almost(arm.get_zoom_percentage(), 0.5, "halfway out is 0.5")

	arm.spring_length = 10.0
	almost(arm.get_zoom_percentage(), 1.0, "fully out is 1.0")

	arm.spring_length = 0.0
	almost(arm.get_zoom_percentage(), 0.0, "fully in is 0.0")

	case("no capacity")
	arm.max_length = 0.0
	almost(arm.get_zoom_percentage(), 0.0,
		"a zero maximum returns 0.0 rather than dividing by zero")


func _random_zooming_stays_in_range() -> void:
	case("invariant under random zooming")
	var breaches: int = 0

	for i: int in 200:
		# Left out of the tree deliberately. _ready would overwrite target_length with
		# spring_length, and this is about the clamping, not the startup value.
		var arm: FoxZoomSpringArm3D = FoxZoomSpringArm3D.new()
		arm.max_length = rng.randf_range(1.0, 500.0)
		arm.target_length = arm.max_length * 0.5

		for j: int in 25:
			arm.change_zoom(rng.randf_range(-100.0, 100.0))
			if arm.target_length < -0.0001 or arm.target_length > arm.max_length + 0.0001:
				breaches += 1

		arm.free()

	eq(breaches, 0, "target_length stayed between zero and max across 5000 changes")

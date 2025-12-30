extends RigidBody3D

@onready var model: Marker3D = $Model

const TARGET_SPEED := 5.0

var mouse_sensitivity := 0.0015
var _pid := Pid3D.new(60.0, 0.1, 1.0)
var acceleration := 0.5

var last_mouse_position := Vector2.ZERO
var input_direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	_movement(delta)


func _movement(delta):
	var forward = -model.global_transform.basis.z
	var right = model.global_transform.basis.x

	var move_direction : Vector3 = (forward * input_direction.y + right * input_direction.x).normalized()
	
	print(input_direction)
	
	var target_velocity : Vector3 = move_direction * TARGET_SPEED
	
	var velocity_error := target_velocity - linear_velocity
	
	var correction_impulse := _pid.update(velocity_error, delta) * acceleration
	
	apply_central_impulse(correction_impulse)


func _on_pc_input_handler_look_input(mouse_relative: Vector2) -> void:
	var mouse_difference := (last_mouse_position - mouse_relative)
	
	model.rotate_y(mouse_difference.x * mouse_sensitivity)


func _on_pc_input_handler_move_input(new_input_direction: Vector2) -> void:
	input_direction = new_input_direction

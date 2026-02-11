extends TateCharacterMotor3D
class_name TateAdvancedCharacterMotor3D
## A more advanced and robust character motor. Less flexible for a greater variety
## of games but designed to have generic behavior and features built in that many 
##games/projects require (better jumping, interacting, sprinting, etc).

@export_group("Advanced Jump")
## (Optional) Raycast3D that detects if the body is on the ground.
## Exists to allow more responsive jumping.
@export var ground_cast : RayCast3D
## (Optional) The max time spent in the air before a player can no
## longer jump. 
@export var coyote_time := 0.3
@export var can_double_jump := false

@export_group("Smoothing")
## How responsive input is.
@export var acceleration := 1000.0
## How quickly the character will slow down.
## Use lower numbers for a "walking on ice" feel.
@export var friction := 1500.0

@export_group("Sprint")
## How quickly the body moves while sprinting.
@export var sprint_speed := 15.0

var _air_time_elapsed := 0.0
var _has_jumped := false
var _has_double_jumped := false
var _is_sprinting := false
#var _acceleration := 0.0


func _physics_process(delta):
	_update_movement_advanced(delta)
	
	_update_y_velocity(delta)
	
	if body.is_on_floor():
		reset_jump()


func _process(delta: float) -> void:
	if not ground_cast.is_colliding():
		_air_time_elapsed += delta
		_air_time_elapsed = clampf(_air_time_elapsed, 0.0, coyote_time * 2)
	else:
		_air_time_elapsed = 0.0


## More advanced can_jump() that checks for a ground cast. 
func can_jump():
	if body.is_on_floor():
		_has_jumped = false
		_has_double_jumped = false
		return true
	if ground_cast != null:
		if not _has_jumped:
			return _air_time_elapsed < coyote_time
		elif can_double_jump:
			if not _has_double_jumped:
				return true
	
	return super.can_jump()


func _update_movement():
	return


func _update_movement_advanced(delta):
	var forward := -body.basis.z #var direction = (-forward_marker.global_basis.z * input_direction.y) + (forward_marker.global_basis.x * input_direction.x)
	var right := body.basis.x
	var direction = (forward * input_direction.y) + (right * input_direction.x)
	direction = direction * input_strength
	
	
	if direction:
		var target_vector := Vector3(direction.x, 0.0, direction.z)
		
		if _is_sprinting:
			target_vector *= sprint_speed
		else:
			target_vector *= speed
		
		target_vector += Vector3(0, body.velocity.y, 0)
		
		body.velocity = body.velocity.move_toward(target_vector, delta * acceleration)
	else:
		body.velocity = body.velocity.move_toward(Vector3(0, body.velocity.y, 0), delta * friction)
	
	_push_away_rigid_bodies()
	
	body.move_and_slide()


func jump(multiplier := 1.0):
	if not _jump_pressed:
		body.velocity.y = jump_strength * multiplier
		_jump_pressed = true
		
		if _has_jumped:
			_has_double_jumped = true
		
		jumped.emit()
		
	_has_jumped = true


func start_sprinting():
	_is_sprinting = true


func stop_sprinting():
	_is_sprinting = false








func _push_away_rigid_bodies():
	for i in body.get_slide_collision_count():
		var c := body.get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			# How much velocity the object needs to increase to match player velocity in the push direction
			var velocity_diff_in_push_dir = body.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			# Only count velocity towards push dir, away from character
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
			const MY_APPROX_MASS_KG = 80.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			# Optional add: Don't push object at all if it's 4x heavier or more
			if mass_ratio < 0.25:
				continue
			# Don't push object from above/below
			push_dir.y = 0
			# 5.0 is a magic number, adjust to your needs
			var push_force = mass_ratio * 5.0
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)

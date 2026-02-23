extends FoxCharacterMotor3D
class_name FoxAdvancedCharacterMotor3D
## A more advanced and robust FoxCharacterMotor3D used to propell a human like actor.

## Unlike the FoxCharacterMotor3D, this motor has extra features like coyote time,
## acceleration, friction, and interactions with RigidBody3D. 
## [br]
## This gives it an overall higher fidelity "feel".

@export_group("Advanced Jump")
## (Optional) Raycast3D that detects if the body is on the ground.
## Helps prevent missed inputs when running down steep slopes.
@export var _ground_cast : RayCast3D
## The max time spent in the air before a player can no longer jump. 
## Set to -1 to always let a player jump once in the air.
@export var coyote_time : float = 0.25

@export_group("Smoothing")
## How responsive input is.
@export var acceleration := 1000.0
## How quickly the character will slow down.
## Use lower numbers for a "walking on ice" feel.
@export var friction := 1500.0


## Time spent in air.
var _air_time_elapsed := 0.0




#region Virtual Methods

func _physics_process(delta):
	if not active:
		return
	
	# math
	_update_y_velocity(delta)
	_update_movement(delta)
	_update_airtime(delta)
	
	# appyling the math
	_push_away_rigid_bodies()
	body.move_and_slide()
	
	# If the player hits the floor and is holding jump,
	# automatically start another jump
	if body.is_on_floor():
		reset_jump_pressed()

#endregion





#region Public API

## More advanced can_jump() from FoxCharacterMotor3D.
## If there is a ground cast lets the character jump before they hit
## the ground and use coyote time. 
func can_jump() -> bool:
	if not active:
		return false
	
	if _jump_pressed:
		return false
	
	# Standard
	if super.can_jump():
		return true
	
	# Raycast check
	if _ground_cast and _ground_cast.is_colliding() and body.velocity.y <= 0:
		return true
	
	# Coyote Time check
	if coyote_time < 0:
		return true
	elif _air_time_elapsed < coyote_time:
		return true
		
	return false

#endregion






#region Private Helpers

func _update_airtime(delta: float) -> void:
	var is_grounded := body.is_on_floor()
	
	# If we have a raycast, it can override the grounded check
	if _ground_cast:
		is_grounded = is_grounded or _ground_cast.is_colliding()
		
	if not is_grounded:
		_air_time_elapsed += delta
		# Clamp it safely to prevent floating point overflow if falling for hours
		_air_time_elapsed = clampf(_air_time_elapsed, 0.0, coyote_time * 2.0)
	else:
		_air_time_elapsed = 0.0


## More advanced _update_movement() from FoxCharacterMotor3D. 
func _update_movement(delta):
	var forward := -body.global_basis.z
	var right := body.global_basis.x
	var direction = (forward * input_direction.y) + (right * input_direction.x)
	direction = direction * input_strength
	
	var body_velocity_2d := Vector2(body.velocity.x, body.velocity.z)
	
	
	if direction:
		var target_vector := Vector2(direction.x, direction.z) * speed

		body_velocity_2d = body_velocity_2d.move_toward(target_vector, delta * acceleration)

	else:
		body_velocity_2d = body_velocity_2d.move_toward(Vector2(0,0), delta * friction)
	
	body.velocity.x = body_velocity_2d.x
	body.velocity.z = body_velocity_2d.y



## Thank you Majikayo Games for this function!
# https://www.youtube.com/watch?v=Uh9PSOORMmA
# CC0/public domain/use for whatever you want no need to credit
# Call this function directly before move_and_slide() on your CharacterBody3D script
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

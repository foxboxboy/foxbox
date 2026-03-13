extends FoxCharacterMotor3D
class_name FoxAdvancedCharacterMotor3D
## A more advanced and robust FoxCharacterMotor3D used to propell a human like actor.

## Unlike the FoxCharacterMotor3D, this motor has extra features like,
## acceleration, friction, and interactions with RigidBody3D. 
## [br]
## This gives it an overall higher fidelity "feel".

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
	
	# appyling the math
	_push_away_rigid_bodies()
	body.move_and_slide()

#endregion






#region Private Helpers


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

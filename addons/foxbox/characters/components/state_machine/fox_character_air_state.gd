class_name FoxCharacterAirState
extends FoxCharacterState

## A state that handles falling, coyote time, and multiple mid-air jumps.

#region Exports

@export_group("Dependencies")
@export var state_id: StringName = &"Air"
@export var motor: FoxCharacterMotor3D 

@export_group("Air Parameters")
## How long the player can still jump after leaving a ledge.
@export var coyote_duration: float = 0.15
## How many jumps are allowed (1 = Coyote/Normal, 2 = Double Jump).
@export var max_jumps: int = 3

#endregion





#region Variables

var _time_since_grounded: float = 0.0
var _jumps_made: int = 0

#endregion





#region State Virtual Methods

func enter() -> void:
	if motor: 
		motor.enable()

	if model:
		model.enter_air()


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	_time_since_grounded += delta
	
	# --- VISUALS ---
	# Feed the continuous velocity data to the model for the AnimationTree to blend
	if model:
		model.set_move_speed(snappedf(character.get_speed_percent(), 0.1))
		model.set_vertical_speed(motor.body.velocity.y)
	
	# --- DASH CHECK ---
	# We safely ask the character if the cooldown is finished before dashing
	if character.wants_to_dash and character.can_dash():
		character.wants_to_dash = false
		transitioned.emit(self, &"Dash")
		return
	
	# --- JUMP CHECK ---
	if character.wants_to_jump:
		if _can_jump_in_air():
			_execute_jump()

	# --- LANDING CHECK ---
	if motor.body.velocity.y <= 0.0 and not character.is_in_air():
		transitioned.emit(self, &"Grounded")
		return

	# --- MOVEMENT ---
	motor.input_direction = character.input_direction
	motor._physics_process(delta)

#endregion





#region Private

func _can_jump_in_air() -> bool:
	if not character.can_jump():
		return false
	
	# Rule 1: Within Coyote Window
	var time_since_ground: float = (Time.get_ticks_msec() - character.last_grounded_time) / 1000.0
	
	if character.jumps_made == 0 and time_since_ground <= coyote_duration:
		return true
		
	# Rule 2: Multi-Jump Logic    
	if character.jumps_made < max_jumps:
		return true
		
	return false


func _execute_jump() -> void:
	character.wants_to_jump = false # Consume the token
	character.jumps_made += 1       # INCREMENT CHARACTER MEMORY
	character.last_jump_time = Time.get_ticks_msec()
	motor.jump()

#endregion

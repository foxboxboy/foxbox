class_name FoxCharacterAirState
extends FoxCharacterState

@export var state_id: StringName = &"Air"
@export var motor: FoxCharacterMotor3D 

## How long the player can still jump after leaving a ledge.
@export var coyote_duration: float = 0.15
## How many jumps are allowed (1 = Coyote/Normal, 2 = Double Jump).
@export var max_jumps: int = 3

var _time_since_grounded: float = 0.0
var _jumps_made: int = 0

func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func enter() -> void:
	if motor:
		motor.enable()
	
	# Reset tracking
	_time_since_grounded = 0.0
	
	# If we entered this state because we JUMPED, 
	# we've already used our 'ground' jump.
	if character.wants_to_jump:
		_jumps_made = 1
	else:
		# We walked off a ledge, so we haven't 'jumped' yet.
		_jumps_made = 0


func physics_update(delta: float) -> void:
	_time_since_grounded += delta
	
	# --- 1. THE JUMP CHECK ---
	if character.wants_to_jump:
		if _can_jump_in_air():
			_execute_jump()

	# --- 2. THE LANDING CHECK ---
	if motor.body.velocity.y <= 0.0 and not character.is_in_air():
		transitioned.emit(self, &"Grounded")
		return

	# --- 3. MOVEMENT ---
	motor.input_direction = character.input_direction
	motor._physics_process(delta)


func _can_jump_in_air() -> bool:
	# Rule 1: Within Coyote Window
	if _jumps_made == 0 and _time_since_grounded <= coyote_duration:
		return true
		
	# Rule 2: Multi-Jump Logic	
	if _jumps_made < max_jumps:
		return true
		
	return false

func _execute_jump() -> void:
	character.wants_to_jump = false
	_jumps_made += 1
	motor.jump()

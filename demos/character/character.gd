class_name GameCharacter
extends CharacterBody3D
## The "Dumb Pawn". Acts as a switchboard between a Controller's intents and the character's modules.

@export_group("Core Components")
@export var motor: FoxAdvancedCharacterMotor3D
@export var state_machine: FoxStateMachine

@export_group("States")
@export var ground_state: FoxGroundState
@export var air_state: FoxAirState
@export var dash_state: FoxDashState

@export_group("Abilities")
@export var jump_ability: FoxJumpAbility
@export var dash_ability: FoxDashAbility
@export var sprint_ability: FoxSprintAbility

@export_group("Locomotion Tuning")
## The standard walking speed.
@export var walk_speed: float = 5.0
## The speed when crouched. (Sprint speed is managed by the SprintAbility).
@export var crouch_speed: float = 2.5
## Documentation needed
@export var crouch_jump_multiplier: float = 1.2


# --- THE INTENT DASHBOARD ---
var intent_movement: Vector2 = Vector2.ZERO
var intent_jump: bool = false
var intent_dash: bool = false
var intent_sprint: bool = false
var intent_crouch: bool = false
var intent_jump_released: bool = false


func _physics_process(_delta: float) -> void:
	_update_reality()
	_process_intents()
	_route_state()
	_push_state_data()
	_reset_one_shots()


# ---------------------------------------------------------
# 1. FEED REALITY
# ---------------------------------------------------------
## Feed the raw physical engine data into the mathematical stopwatches.
func _update_reality() -> void:
	# The setter property inside FoxJumpAbility handles coyote timers automatically!
	jump_ability.is_grounded = is_on_floor()


# ---------------------------------------------------------
# 2. REGISTER INTENTS
# ---------------------------------------------------------
## Pass the controller's button presses to the abilities.
func _process_intents() -> void:
	if intent_jump: jump_ability.request()
	if intent_dash: dash_ability.request()

	if intent_sprint: sprint_ability.request()
	else: sprint_ability.cancel()


# ---------------------------------------------------------
# 3. EVALUATE TRANSITIONS (The Priority Router)
# ---------------------------------------------------------
## Decide which state gets to be in charge this frame.
func _route_state() -> void:
	# 1. Are we ALREADY dashing? Lock the state!
	if dash_ability.is_dashing():
		state_machine.transition_to(&"Dash")
		return

	# 2. Are we STARTING a new dash?
	if dash_ability.has_request() and dash_ability.is_available():
		state_machine.transition_to(&"Dash")
		return

	# Standard gravity routing
	if not is_on_floor():
		state_machine.transition_to(&"Air")
	else:
		state_machine.transition_to(&"Ground")


# ---------------------------------------------------------
# 4. EXECUTE ACTIVE STATE
# ---------------------------------------------------------
## Feed the current active state the math it needs to drive the motor.
func _push_state_data() -> void:
	var active: FoxState = state_machine.current_state

	if active == ground_state:
		_handle_ground_logic()
	elif active == air_state:
		_handle_air_logic()
	elif active == dash_state:
		_handle_dash_logic()

	# Jumping can happen in both Ground and Air (Double Jumps),
	# but we prevent jumping mid-dash!
	if active != dash_state:
		_try_jump()


func _handle_ground_logic() -> void:
	var target_speed: float = walk_speed

	# Priority: Crouch > Sprint > Walk
	if intent_crouch:
		target_speed = crouch_speed
	elif sprint_ability.has_request():
		target_speed = sprint_ability.speed

	ground_state.current_speed = target_speed
	ground_state.input_direction = intent_movement


func _handle_air_logic() -> void:
	var target_speed: float = walk_speed

	# If they are holding the sprint button in the air, let them keep their momentum!
	if sprint_ability.has_request():
		target_speed = sprint_ability.speed

	air_state.current_speed = target_speed
	air_state.input_direction = intent_movement


func _handle_dash_logic() -> void:
	if dash_ability.has_request():
		dash_ability.consume()

		# 1. Get the 2D intent. If no WASD is pressed, default to Forward (-Y)
		var dir_2d = intent_movement if intent_movement != Vector2.ZERO else Vector2(0, -1)

		# 2. Map the 2D input to a flat 3D local vector (X becomes X, Y becomes Z)
		var local_3d = Vector3(dir_2d.x, 0.0, dir_2d.y)

		# 3. Multiply it by the character's global_basis!
		# Godot perfectly calculates that a local Z of -1 means global Forward.
		var dash_dir_3d = (global_basis * local_3d).normalized()

		# 4. Push the global velocity to the state
		dash_state.dash_velocity = dash_dir_3d * dash_ability.speed


## Asks the Jump Ability if a jump is mathematically legal, and tells the motor to execute it.
func _try_jump() -> void:
	if jump_ability.has_request() and jump_ability.is_available(is_on_floor()):
		# The PAWN knows if we are crouched, so the PAWN applies the penalty!
		var penalty = crouch_jump_multiplier if intent_crouch else 1.0

		velocity.y = jump_ability.strength * penalty
		jump_ability.consume()

	if intent_jump_released and velocity.y > 0.0:
		velocity.y *= jump_ability.jump_cut_multiplier


# ---------------------------------------------------------
# 5. CLEANUP
# ---------------------------------------------------------
## Reset triggers so they don't fire twice.
func _reset_one_shots() -> void:
	intent_jump = false
	intent_dash = false
	intent_jump_released = false

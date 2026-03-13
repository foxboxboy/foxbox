## Reads hardware inputs and passes them as intents to a FoxCharacter.
## Intented to be a template.
extends FoxNode

## The puppet we are controlling.
@export var character: FoxCharacter

func _process(delta: float) -> void:
	if not character:
		return
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	character.input_direction = input_dir
	
	# use 'is_action_pressed' for continuous intents (holding crouch)
	character.wants_to_crouch = Input.is_action_pressed("crouch")
	character.wants_to_sprint = Input.is_action_pressed("sprint")
	
	# use 'is_action_just_pressed' for one-shot intents (jumping/dashing)
	# don't set it to false. 
	# FoxCharacterStateMachine will consume the true flag and reset it.
	if Input.is_action_just_pressed("jump"):
		character.wants_to_jump = true
		
	if Input.is_action_just_pressed("dash"):
		character.wants_to_dash = true

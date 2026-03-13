class_name FoxStateMachine
extends FoxNode

@export var initial_state: FoxState
var current_state: FoxState

## [member Dictionary] that maps StringNames to the actual FoxNode nodes
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is FoxState:
			# 1. Register the child in the dictionary!
			# We use its exported state_id if it has one, otherwise we default to its node name.
			var key: StringName = child.state_id if "state_id" in child else StringName(child.name)
			states[key] = child
			
			# 2. Wire the microphone
			child.transitioned.connect(_on_child_transition)
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)



func _on_child_transition(old_state: FoxState, new_state_name: StringName) -> void:
	if old_state != current_state:
		return
	
	transition_to_state(new_state_name)


## Transitions to a FoxState from [member states] if one could be found. 
func transition_to_state(new_state_name: StringName) -> void:
	var new_state: FoxState = states.get(new_state_name)
	
	if not new_state:
		push_warning("FoxStateMachine transition failed: The target state '%s' does not exist in the dictionary." % new_state_name)
		return
		
	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state


## Returns a FoxState from [member states] if one could be found. 
func get_state(state_name: StringName) -> FoxState:
	var state: FoxState = states.get(state_name)
	
	if not state:
		push_warning("FoxStateMachine get_state failed: The target state '%s' does not exist in the dictionary." % state_name)
	
	return state

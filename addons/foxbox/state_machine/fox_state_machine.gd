@icon("uid://cubhr3bg1ga6k")
class_name FoxStateMachine
extends FoxNode
## A node-based State Machine that manages [FoxState] children.

## The state that becomes active as soon as the machine is ready.
@export var initial_state: FoxState

## The currently active state.
var current_state: FoxState

## A dictionary mapping [StringName] identifiers to their respective [FoxState] nodes.
var states: Dictionary = {}

#region Public API

## Transitions to a [FoxState] matching the provided [param new_state_name].
func transition_to_state(new_state_name: StringName) -> void:
	var new_state: FoxState = states.get(new_state_name)
	
	if not new_state:
		push_warning("FoxStateMachine transition failed: The target state '%s' does not exist." % new_state_name)
		return
		
	if current_state:
		current_state.exit()
		
	# Reassign current_state BEFORE calling enter().
	# This prevents bugs if the new state immediately requests another transition inside its enter() method.
	current_state = new_state
	current_state.enter()


## Returns a [FoxState] from the managed dictionary, or [code]null[/code] if missing.
func get_state(state_name: StringName) -> FoxState:
	var state: FoxState = states.get(state_name)
	
	if not state:
		push_warning("FoxStateMachine get_state failed: The target state '%s' does not exist." % state_name)
		
	return state

#endregion

#region Private Logic

func _ready() -> void:
	for child in get_children():
		if child is FoxState:
			# Use the explicit state_id if provided, otherwise fallback to the node's name
			var key: StringName = child.state_id if child.state_id != &"" else StringName(child.name)
			states[key] = child
			
			child.transition_requested.connect(_on_child_transition_requested)
			
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_child_transition_requested(old_state: FoxState, new_state_name: StringName) -> void:
	if old_state != current_state:
		return
		
	transition_to_state(new_state_name)

#endregion

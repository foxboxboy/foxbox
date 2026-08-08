@tool
@icon("uid://cubhr3bg1ga6k")
class_name FoxStateMachine
extends FoxNode
## A node-based State Machine that manages [FoxState] children.
##
## States are direct children of this node. Each one is keyed by its
## [member FoxState.state_id], or by its node name when that is left blank.
## [codeblock]
## # Player
## # └─ StateMachine        (initial_state -> Idle)
## #    ├─ Idle             (idle.gd)
## #    └─ Running          (running.gd)
##
## # idle.gd
## extends FoxState
##
## func enter() -> void:
##     owner.velocity = Vector3.ZERO
##
## func physics_update(_delta: float) -> void:
##     if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
##         transition_requested.emit(self, &"Running")
## [/codeblock]
## A state never switches itself. It emits [signal FoxState.transition_requested] and the
## machine performs the swap, so states stay unaware of each other.

## The state that becomes active as soon as the machine is ready.
@export var initial_state: FoxState

## The currently active state.
var current_state: FoxState

## A dictionary mapping [StringName] identifiers to their respective [FoxState] nodes.
var states: Dictionary[StringName, FoxState] = {}




#region Public API

## Transitions to a [FoxState] matching the provided [param new_state_name].
func transition_to(new_state_name: StringName) -> void:
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




#region Private

func _ready() -> void:
	# @tool runs this in the editor too. Entering a state there would run game logic every time
	# the scene is opened.
	if Engine.is_editor_hint():
		return

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
	if Engine.is_editor_hint():
		return

	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if current_state:
		current_state.physics_update(delta)


func _on_child_transition_requested(old_state: FoxState, new_state_name: StringName) -> void:
	if old_state != current_state:
		return
		
	transition_to(new_state_name)

#endregion




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	var found: Array[FoxState] = []
	for child: Node in get_children():
		if child is FoxState:
			found.append(child)

	if found.is_empty():
		warnings.append("No FoxState children, so this machine has nothing to run.")
		return warnings

	if initial_state == null:
		warnings.append("No Initial State assigned, so no state becomes active on ready.")
	elif not found.has(initial_state):
		warnings.append("Initial State is not a child of this machine, so it can never be "
			+ "transitioned back to.")

	var keys: Array[StringName] = []
	for state: FoxState in found:
		var key: StringName = state.state_id if state.state_id != &"" else StringName(state.name)
		if keys.has(key):
			warnings.append("Two states resolve to the key '%s'. One will overwrite the other."
				% key)
		else:
			keys.append(key)

	return warnings

#endregion

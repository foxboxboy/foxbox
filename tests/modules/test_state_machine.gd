extends FoxTest


class ProbeState extends FoxState:
	var entered: int = 0
	var exited: int = 0
	var updates: int = 0
	var physics: int = 0

	func enter() -> void:
		entered += 1

	func exit() -> void:
		exited += 1

	func update(_delta: float) -> void:
		updates += 1

	func physics_update(_delta: float) -> void:
		physics += 1

	func ask_for(state_name: StringName) -> void:
		transition_requested.emit(self, state_name)


func run() -> void:
	suite = "state_machine"
	_initial_state()
	_transitions()
	_unknown_states_are_refused()
	_state_id_overrides_node_name()
	_states_request_their_own_transitions()
	_inactive_states_cannot_force_a_transition()
	_frame_callbacks_reach_the_active_state_only()


## Builds a machine with named states. Children must exist before the machine enters the tree,
## because FoxStateMachine collects them in _ready.
func _build(state_names: Array, initial_index: int = 0) -> Array:
	var sm: FoxStateMachine = FoxStateMachine.new()
	var states: Array[ProbeState] = []
	for n: String in state_names:
		var s: ProbeState = ProbeState.new()
		s.name = n
		sm.add_child(s)
		states.append(s)
	if initial_index >= 0:
		sm.initial_state = states[initial_index]
	track(sm)
	return [sm, states]


func _initial_state() -> void:
	start_case("initial state")
	var built: Array = _build(["Idle", "Running"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	check_equal(sm.current_state, states[0], "the initial state became current")
	check_equal(states[0].entered, 1, "enter ran on the initial state")
	check_equal(states[1].entered, 0, "the other state was left alone")
	check_equal(sm.states.size(), 2, "both children were registered")

	start_case("no initial state")
	var sm2: FoxStateMachine = FoxStateMachine.new()
	var lone: ProbeState = ProbeState.new()
	lone.name = "Lone"
	sm2.add_child(lone)
	track(sm2)
	check_equal(sm2.current_state, null, "without an initial state nothing is current")
	check_equal(lone.entered, 0, "and nothing was entered")


func _transitions() -> void:
	start_case("transitions")
	var built: Array = _build(["Idle", "Running"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	sm.transition_to(&"Running")
	check_equal(sm.current_state, states[1], "current state moved")
	check_equal(states[0].exited, 1, "the old state exited")
	check_equal(states[1].entered, 1, "the new state entered")

	sm.transition_to(&"Idle")
	check_equal(sm.current_state, states[0], "and back again")
	check_equal(states[1].exited, 1, "the second state exited")
	check_equal(states[0].entered, 2, "the first state entered a second time")


func _unknown_states_are_refused() -> void:
	start_case("unknown state names")
	var built: Array = _build(["Idle"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	# emits a warning by design
	sm.transition_to(&"DoesNotExist")
	check_equal(sm.current_state, states[0], "the current state did not change")
	check_equal(states[0].exited, 0, "the current state was not exited")

	check_equal(sm.get_state(&"DoesNotExist"), null, "get_state returns null for an unknown name")
	check_equal(sm.get_state(&"Idle"), states[0], "and the node for a known one")


func _state_id_overrides_node_name() -> void:
	start_case("state_id")
	var sm: FoxStateMachine = FoxStateMachine.new()
	var s: ProbeState = ProbeState.new()
	s.name = "NodeName"
	s.state_id = &"custom_id"
	sm.add_child(s)
	track(sm)

	check_equal(sm.get_state(&"custom_id"), s, "the explicit state_id is the key")
	check_equal(sm.states.has(&"NodeName"), false, "the node name is not also registered")


func _states_request_their_own_transitions() -> void:
	start_case("transition_requested")
	var built: Array = _build(["Idle", "Running"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	states[0].ask_for(&"Running")
	check_equal(sm.current_state, states[1], "the machine honoured the active state's request")
	check_equal(states[0].exited, 1, "the requesting state exited")


## Guards against a stale state that is no longer active yanking the machine around.
func _inactive_states_cannot_force_a_transition() -> void:
	start_case("requests from inactive states")
	var built: Array = _build(["Idle", "Running", "Jumping"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	sm.transition_to(&"Running")
	check_equal(sm.current_state, states[1], "Running is active")

	# Idle is no longer active, so its request must be ignored
	states[0].ask_for(&"Jumping")
	check_equal(sm.current_state, states[1], "the request from a non-active state was ignored")
	check_equal(states[2].entered, 0, "Jumping was never entered")


func _frame_callbacks_reach_the_active_state_only() -> void:
	start_case("frame callbacks")
	var built: Array = _build(["Idle", "Running"])
	var sm: FoxStateMachine = built[0]
	var states: Array[ProbeState] = built[1]

	sm._process(0.016)
	sm._process(0.016)
	sm._physics_process(0.016)

	check_equal(states[0].updates, 2, "update reached the active state")
	check_equal(states[0].physics, 1, "physics_update reached the active state")
	check_equal(states[1].updates, 0, "the inactive state got nothing")
	check_equal(states[1].physics, 0, "including physics")

	sm.transition_to(&"Running")
	sm._process(0.016)
	check_equal(states[0].updates, 2, "the old state stopped receiving frames")
	check_equal(states[1].updates, 1, "the new state started receiving them")

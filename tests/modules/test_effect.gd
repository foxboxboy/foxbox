extends FoxTest


class ProbeEffect extends FoxEffect:
	var executes: int = 0
	var removes: int = 0
	var reapplies: int = 0
	var ticks: int = 0
	var last_stack: int = 0

	func _on_execute(_target: Object) -> void:
		executes += 1

	func _on_remove(_target: Object) -> void:
		removes += 1

	func _on_reapply(_target: Object, current_stack: int = 1) -> void:
		reapplies += 1
		last_stack = current_stack

	func _on_tick(_target: Object, current_stack: int) -> void:
		ticks += 1
		last_stack = current_stack


func run() -> void:
	suite = "effect"
	_applying()
	_processing_is_idle_when_empty()
	_unique_mode_reuses_the_instance()
	_intensity_mode_stacks()
	_max_stacks_zero_means_unlimited()
	_max_stacks_caps()
	_multiple_instances_mode()
	_duration_modes()
	_expiry()
	_permanent_effects_never_expire()
	_ticking()
	_removal_runs_cleanup()
	_serialisation_round_trip()
	_expiry_sentinel_edge_case()


func _mk(id: StringName, duration: float = -1.0) -> ProbeEffect:
	var e: ProbeEffect = ProbeEffect.new()
	e.id = id
	e.duration = duration
	return e


func _mgr() -> FoxEffectManager:
	return track(FoxEffectManager.new()) as FoxEffectManager


func _applying() -> void:
	start_case("applying")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"poison")

	var inst: FoxEffectInstance = m.add_effect(e, target)
	check(inst != null, "add_effect returns an instance")
	check_equal(e.executes, 1, "_on_execute ran once")
	check(m.has_effect(&"poison"), "the effect is active")
	check_equal(m.effects.size(), 1, "one instance is tracked")
	check_equal(inst.stack, 1, "a fresh instance starts at one stack")

	check_equal(m.add_effect(null, target), null, "adding a null effect is a no-op")
	check_equal(m.effects.size(), 1, "and does not change the tracked list")


## Regression: the manager used to run _process every frame for every entity even with
## nothing to tick.
func _processing_is_idle_when_empty() -> void:
	start_case("idle when empty")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	check(not m.is_processing(), "a manager with no effects does not process")

	m.add_effect(_mk(&"a"), target)
	check(m.is_processing(), "adding an effect starts processing")

	m.add_effect(_mk(&"b"), target)
	m.remove_effect_by_id(&"a")
	check(m.is_processing(), "still processing while one effect remains")

	m.remove_all_effects()
	check(not m.is_processing(), "processing stops once the last effect is gone")


func _unique_mode_reuses_the_instance() -> void:
	start_case("StackMode.UNIQUE")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"poison", 10.0)
	e.stack_mode = FoxEffect.StackMode.UNIQUE
	e.duration_mode = FoxEffect.DurationMode.REFRESH

	var first: FoxEffectInstance = m.add_effect(e, target)
	var second: FoxEffectInstance = m.add_effect(e, target)
	check_equal(second, first, "the same instance comes back")
	check_equal(m.effects.size(), 1, "no second instance was created")
	check_equal(e.executes, 1, "_on_execute did not run again")
	check_equal(first.stack, 1, "UNIQUE does not raise the stack")


func _intensity_mode_stacks() -> void:
	start_case("StackMode.INTENSITY")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"bleed", 10.0)
	e.stack_mode = FoxEffect.StackMode.INTENSITY

	var inst: FoxEffectInstance = m.add_effect(e, target)
	m.add_effect(e, target)
	check_equal(inst.stack, 2, "a second application raises the stack")
	check_equal(e.reapplies, 1, "_on_reapply ran")
	check_equal(e.last_stack, 2, "_on_reapply received the new stack count")
	check_equal(m.effects.size(), 1, "still a single instance")


## FoxEffectInstance.increase_stack said "strictly capped by max_stacks" without noting
## that 0 means unlimited.
func _max_stacks_zero_means_unlimited() -> void:
	start_case("max_stacks of zero")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"infinite", 10.0)
	e.stack_mode = FoxEffect.StackMode.INTENSITY
	e.max_stacks = 0

	var inst: FoxEffectInstance = m.add_effect(e, target)
	for i: int in 30:
		m.add_effect(e, target)
	check_equal(inst.stack, 31, "zero means unlimited, not zero")


func _max_stacks_caps() -> void:
	start_case("max_stacks cap")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"capped", 10.0)
	e.stack_mode = FoxEffect.StackMode.INTENSITY
	e.max_stacks = 3

	var inst: FoxEffectInstance = m.add_effect(e, target)
	for i: int in 10:
		m.add_effect(e, target)
	check_equal(inst.stack, 3, "the stack stops at max_stacks")

	var before: int = e.reapplies
	m.add_effect(e, target)
	check_equal(e.reapplies, before, "_on_reapply is not called when the stack did not move")


func _multiple_instances_mode() -> void:
	start_case("StackMode.MULTIPLE_INSTANCES")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"dot", 10.0)
	e.stack_mode = FoxEffect.StackMode.MULTIPLE_INSTANCES

	m.add_effect(e, target)
	m.add_effect(e, target)
	m.add_effect(e, target)
	check_equal(m.effects.size(), 3, "each application spawns its own instance")
	check_equal(e.executes, 3, "_on_execute ran per instance")


func _duration_modes() -> void:
	start_case("DurationMode.ADD")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"add", 5.0)
	e.duration_mode = FoxEffect.DurationMode.ADD
	var inst: FoxEffectInstance = m.add_effect(e, target)
	m.add_effect(e, target)
	check_almost_equal(inst.time_left, 10.0, "durations sum")

	start_case("DurationMode.REFRESH")
	var m2: FoxEffectManager = _mgr()
	var e2: ProbeEffect = _mk(&"refresh", 5.0)
	e2.duration_mode = FoxEffect.DurationMode.REFRESH
	var inst2: FoxEffectInstance = m2.add_effect(e2, target)
	inst2.process_time(3.0)
	check_almost_equal(inst2.time_left, 2.0, "time ticked down")
	m2.add_effect(e2, target)
	check_almost_equal(inst2.time_left, 5.0, "reapplying resets to the full duration")

	start_case("DurationMode.KEEP_LONGEST")
	var m3: FoxEffectManager = _mgr()
	var e3: ProbeEffect = _mk(&"keep", 5.0)
	e3.duration_mode = FoxEffect.DurationMode.KEEP_LONGEST
	var inst3: FoxEffectInstance = m3.add_effect(e3, target)
	inst3.process_time(1.0)
	check_almost_equal(inst3.time_left, 4.0, "time ticked down")
	m3.add_effect(e3, target)
	check_almost_equal(inst3.time_left, 5.0, "the longer of the two wins")

	inst3.process_time(0.5)
	var e_short: ProbeEffect = _mk(&"keep", 1.0)
	e_short.duration_mode = FoxEffect.DurationMode.KEEP_LONGEST
	m3.add_effect(e_short, target)
	check_almost_equal(inst3.time_left, 4.5, "a shorter incoming duration is ignored")


func _expiry() -> void:
	start_case("expiry")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"short", 1.0)

	m.add_effect(e, target)
	m._process(0.4)
	check_equal(m.effects.size(), 1, "still alive before the duration elapses")

	m._process(0.4)
	check_equal(m.effects.size(), 1, "still alive just under the limit")

	m._process(0.4)
	check_equal(m.effects.size(), 0, "removed once the timer passes zero")
	check_equal(e.removes, 1, "_on_remove ran during cleanup")
	check(not m.has_effect(&"short"), "no longer reported as active")


func _permanent_effects_never_expire() -> void:
	start_case("permanent effects")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"forever", -1.0)

	var inst: FoxEffectInstance = m.add_effect(e, target)
	check(not inst.is_expired, "a permanent effect is not expired")

	for i: int in 100:
		m._process(1.0)
	check_equal(m.effects.size(), 1, "still alive after 100 seconds")
	check_almost_equal(inst.time_left, -1.0, "time_left stays at the permanent sentinel")


func _ticking() -> void:
	start_case("interval ticking")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"tickly", 10.0)
	e.tick_interval = 1.0

	m.add_effect(e, target)
	m._process(0.5)
	check_equal(e.ticks, 0, "no tick before the interval elapses")

	m._process(0.6)
	check_equal(e.ticks, 1, "one tick after the interval")

	m._process(1.0)
	check_equal(e.ticks, 2, "ticks keep coming on schedule")

	start_case("ticking disabled")
	var m2: FoxEffectManager = _mgr()
	var e2: ProbeEffect = _mk(&"silent", 10.0)
	e2.tick_interval = 0.0
	m2.add_effect(e2, target)
	for i: int in 20:
		m2._process(1.0)
	check_equal(e2.ticks, 0, "a zero interval never ticks")


func _removal_runs_cleanup() -> void:
	start_case("removal")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var a: ProbeEffect = _mk(&"a")
	var b: ProbeEffect = _mk(&"b")

	m.add_effect(a, target)
	m.add_effect(b, target)
	check_equal(m.get_all_effect_ids().size(), 2, "both ids reported")

	m.remove_effect_by_id(&"a")
	check_equal(a.removes, 1, "_on_remove ran for the removed effect")
	check_equal(b.removes, 0, "the other effect was untouched")

	m.remove_all_effects()
	check_equal(b.removes, 1, "remove_all cleans up the rest")
	check_equal(m.effects.size(), 0, "nothing left")

	start_case("multiple instances removal")
	var m2: FoxEffectManager = _mgr()
	var c: ProbeEffect = _mk(&"c")
	c.stack_mode = FoxEffect.StackMode.MULTIPLE_INSTANCES
	m2.add_effect(c, target)
	m2.add_effect(c, target)
	m2.add_effect(c, target)

	m2.remove_effect_by_id(&"c", false)
	check_equal(m2.effects.size(), 2, "removing without all_instances drops only one")

	m2.remove_effect_by_id(&"c", true)
	check_equal(m2.effects.size(), 0, "all_instances drops the rest")


func _serialisation_round_trip() -> void:
	start_case("serialisation")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"saved", 10.0)
	e.stack_mode = FoxEffect.StackMode.INTENSITY
	e.tick_interval = 2.0

	var inst: FoxEffectInstance = m.add_effect(e, target)
	m.add_effect(e, target)
	inst.process_time(3.0)

	var data: Array[Dictionary] = m.serialize()
	check_equal(data.size(), 1, "one entry saved")
	check_equal(data[0]["id"], &"saved", "id was saved")
	check_equal(data[0]["stack"], 2, "stack was saved")

	var m2: FoxEffectManager = _mgr()
	m2.load_state(data, target, func(id: StringName) -> FoxEffect:
		return e if id == &"saved" else null)

	check_equal(m2.effects.size(), 1, "state was restored")
	check_equal(m2.effects[0].stack, 2, "stack survived the round trip")
	check_almost_equal(m2.effects[0].time_left, 7.0, "remaining time survived the round trip")
	check_equal(e.executes, 1, "loading did not re-trigger _on_execute")

	start_case("unknown blueprint on load")
	var m3: FoxEffectManager = _mgr()
	m3.load_state(data, target, func(_id: StringName) -> FoxEffect: return null)
	check_equal(m3.effects.size(), 0, "an unresolvable id is skipped rather than crashing")


## time_left uses -1.0 as the "permanent" sentinel. A timed effect whose remaining time lands
## on exactly -1.0 therefore reads as permanent and never expires.
func _expiry_sentinel_edge_case() -> void:
	start_case("sentinel collision")
	var m: FoxEffectManager = _mgr()
	var target: Node = track(Node.new())
	var e: ProbeEffect = _mk(&"unlucky", 1.0)

	# 1.0 - 2.0 is exactly -1.0, which is the permanent sentinel
	var inst: FoxEffectInstance = m.add_effect(e, target)
	inst.process_time(2.0)
	check_almost_equal(inst.time_left, 0.0, "the countdown floors at zero instead of running onto the sentinel")
	check(inst.is_expired, "an elapsed timed effect counts as expired")

	start_case("permanence is still distinguishable")
	var p: ProbeEffect = _mk(&"perm", -1.0)
	var pinst: FoxEffectInstance = m.add_effect(p, target)
	pinst.process_time(5.0)
	check_almost_equal(pinst.time_left, -1.0, "a permanent effect keeps its sentinel")
	check(not pinst.is_expired, "and never expires")

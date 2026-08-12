@icon("uid://dv080jam3jp5e")
class_name FoxEffectInstance
extends FoxRefCounted
## A runtime state container for an active [FoxEffect] applied to a target [Object].
##
## This class manages the active lifecycle of an effect, tracking its remaining
## [member time_left] and current [member stack] count. It is instantiated and
## managed exclusively by a [FoxEffectManager].
## @tutorial(Building a status effect system): https://foxfabric-godot.readthedocs.io/en/latest/guide_status_effects.html




#region Signals

## Emitted when the [member stack] count changes, carrying the [param previous_stack] and the
## [param new_stack].
## [br][br]
## [b]Note:[/b] This is ideal for connecting directly to UI elements to update visual
## counters (e.g., changing a poison icon from "x1" to "x2") without polling.
signal stack_changed(previous_stack: int, new_stack: int)

## Emitted when this [param instance] should be destroyed, either because external logic forced
## it to expire early or because [method decrease_stack] dropped the stack to [code]0[/code].
signal destruction_requested(instance: FoxEffectInstance)

#endregion




#region Variables

## The static data blueprint governing this instance's logic and stacking behavior.
var effect: FoxEffect

## The specific entity in memory currently being modified.
var target: Object

## The remaining duration of the effect in seconds.
## [br][br][b]Note:[/b] This property is Read-Only.
var time_left: float:
	get: return _time_left
	set(_v): push_error("FoxEffectInstance: 'time_left' is read-only.")

## The current intensity level of the effect.
## [br][br][b]Note:[/b] This property is Read-Only. Use [method increase_stack]
## or [method decrease_stack] to modify.
var stack: int:
	get: return _stack
	set(_v): push_error("FoxEffectInstance: 'stack' is read-only. Use increase_stack() or decrease_stack().")

## Returns [code]true[/code] if the timer has reached zero.
## Permanent effects always return [code]false[/code].
## [br][br]
## [member time_left] is floored at zero rather than running negative, so it can never collide
## with the [code]-1.0[/code] sentinel that marks an effect permanent.
var is_expired: bool:
	get: return _time_left != -1.0 and _time_left <= 0.0

## Backs [member time_left], which is read-only.
var _time_left: float

## Backs [member stack], which is read-only.
var _stack: int = 1

## Counts down to the next [method FoxEffect.tick].
var _tick_timer: float = 0.0

#endregion




#region Public API

## Initializes the instance. This should only be called once immediately after creation.
func setup(p_effect: FoxEffect, p_target: Object) -> void:
	effect = p_effect
	target = p_target
	_time_left = p_effect.duration
	_stack = 1
	_tick_timer = p_effect.tick_interval


## Increases the [member stack] count, capped by [member FoxEffect.max_stacks].
## [br][br]
## [b]Note:[/b] A [member FoxEffect.max_stacks] of [code]0[/code] means unlimited, not zero.
## The cap is only applied when it is greater than [code]0[/code].
## [br][br]
## If the stack successfully increases, this automatically triggers the effect's
## [method FoxEffect.reapply] logic and emits [signal stack_changed].
func increase_stack(amount: int = 1) -> void:
	if not effect: return

	var previous_stack = _stack

	if effect.max_stacks > 0:
		_stack = mini(_stack + amount, effect.max_stacks)
	else:
		_stack += amount

	if _stack != previous_stack:
		effect.reapply(target, _stack)
		stack_changed.emit(previous_stack, _stack)


## Decreases the [member stack] count.
## [br][br]
## If the stack reaches [code]0[/code], it immediately emits [signal destruction_requested]
## so the manager can purge it. Otherwise, it triggers [method FoxEffect.reapply]
## to scale down the math.
func decrease_stack(amount: int = 1) -> void:
	var previous_stack = _stack
	_stack -= amount

	if _stack <= 0:
		destruction_requested.emit(self)
	else:
		if effect:
			effect.reapply(target, _stack)
		stack_changed.emit(previous_stack, _stack)


## Ticks down the internal timer.
## [br][br]
## [b]Note:[/b] This does not automatically destroy the instance. The manager
## must check [member is_expired] and handle cleanup.
func process_time(delta: float) -> void:
	if _time_left != -1.0:
		# Floored at zero on purpose. A free-running countdown can land on exactly -1.0, which
		# is the permanent sentinel, and a timed effect that hits it would never expire.
		_time_left = maxf(_time_left - delta, 0.0)

	if effect and effect.tick_interval > 0.0:
		_tick_timer -= delta
		if _tick_timer <= 0.0:
			effect.tick(target, _stack)
			_tick_timer += effect.tick_interval


## Safely delegates the reversal logic to the [member effect] blueprint before
## this instance is destroyed.
func cleanup() -> void:
	if effect and is_instance_valid(target):
		effect.remove(target)


## Safely merges the duration of a new effect into this active instance
## based on the incoming effect's [member FoxEffect.duration_mode].
func merge_duration(incoming_effect: FoxEffect) -> void:
	# If either the current instance or the new effect is permanent, ignore math.
	if _time_left == -1.0 or incoming_effect.duration == -1.0:
		return

	match incoming_effect.duration_mode:
		FoxEffect.DurationMode.ADD:
			_time_left += incoming_effect.duration
		FoxEffect.DurationMode.REFRESH:
			_time_left = incoming_effect.duration
		FoxEffect.DurationMode.KEEP_LONGEST:
			_time_left = maxf(_time_left, incoming_effect.duration)

#endregion




#region Serialization

## Returns a dictionary containing the instance's current state for saving.
func serialize() -> Dictionary:
	return {
		"id": effect.id,
		"stack": _stack,
		"time_left": _time_left,
		"tick_timer": _tick_timer
	}


## Restores the private state from a saved dictionary.
## Must be called immediately after [method setup].
func load_state(data: Dictionary) -> void:
	_stack = data.get("stack", 1)
	_time_left = data.get("time_left", effect.duration)
	_tick_timer = data.get("tick_timer", effect.tick_interval)

#endregion




#region Built-In Virtuals

## Overrides the default print() behavior to show readable, human-friendly data
## instead of a raw memory ID (e.g., [lb]poison x2 (4.5s)]).
func _to_string() -> String:
	if effect:
		var time_str = "Perm" if _time_left == -1.0 else "%.1fs" % _time_left
		return "[%s x%s (%s)]" % [effect.id, _stack, time_str]
	return "[Empty FoxEffectInstance]"

#endregion

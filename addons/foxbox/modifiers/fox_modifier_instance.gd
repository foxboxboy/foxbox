class_name FoxModifierInstance
extends FoxRefCounted
## A runtime instance of a [FoxModifier] currently affecting a target [Node].


#region Signals

## Emitted when the [member stack] count is modified. 
## Connect this to UI elements to update visual counters efficiently.
signal stack_changed(previous_stack: int, new_stack: int)

## Emitted when this instance should be safely removed by the [FoxModifierManager].
## Triggers when [member time_left] reaches [code]0.0[/code], or when [member stack] drops to [code]0[/code].
signal request_destruction(instance: FoxModifierInstance)

#endregion


#region Variables

## The static data blueprint governing this instance's behavior.
var modifier_data: FoxModifier

## The specific entity in the world currently being affected.
var target: Node

## The remaining duration of the effect in seconds. A value of [code]-1.0[/code] denotes a permanent effect.
var time_left: float

## The current intensity level of the modifier.
var stack: int = 1

## A helper property that safely retrieves the [member FoxModifier.modifier_id] from the [member modifier_data].
var modifier_id: StringName:
	get:
		if modifier_data:
			return modifier_data.modifier_id
		return &""

#endregion


#region Public API

## Increases the [member stack] count, capped by the [member FoxModifier.max_stacks] limit.
## Emits [signal stack_changed] if the value was successfully altered.
func increase_stack(amount: int = 1) -> void:
	if not modifier_data: return
	
	var previous_stack = stack
	
	# if max_stacks is 0, it is infinite. Otherwise, clamp the addition.
	if modifier_data.max_stacks > 0:
		stack = mini(stack + amount, modifier_data.max_stacks)
	else:
		stack += amount
		
	if stack != previous_stack:
		modifier_data.reapply(target, stack)
		stack_changed.emit(previous_stack, stack)


## Decreases the [member stack]. Emits [signal request_destruction] if it reaches [code]0[/code].
func decrease_stack(amount: int = 1) -> void:
	var previous_stack = stack
	stack -= amount
	
	if stack <= 0:
		# if the stack is depleted, we don't bother updating the UI, we just destroy it.
		request_destruction.emit(self)
	else:
		if modifier_data:
			modifier_data.reapply(target, stack)
		stack_changed.emit(previous_stack, stack)


## Ticks down the [member time_left] if the effect is not permanent. 
## Returns [code]true[/code] and emits [signal request_destruction] if the timer finishes.
func process_time(delta: float) -> bool:
	if time_left == -1.0: 
		return false
		
	time_left -= delta
	if time_left <= 0:
		request_destruction.emit(self)
		return true
		
	return false


## Safely executes the [method FoxModifier.remove] logic to reverse its effects on the [member target].
func cleanup() -> void:
	if modifier_data and is_instance_valid(target):
		modifier_data.remove(target)

#endregion

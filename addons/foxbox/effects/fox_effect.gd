@abstract
@icon("uid://8lrkomtjy026")
class_name FoxEffect
extends FoxResource
## Base class for custom gameplay effects.
##
## [FoxEffect] is a [Resource] that defines the behavior, duration, and stacking rules for effects like spells, buffs, or environmental hazards. Because resources are shared by default, this class acts purely as a static data container. 
## [br][br]
## When an effect is applied to a target, a separate [FoxEffectInstance] is spawned to track its active lifecycle (such as remaining time and current stacks). 
## [br][br]
## To create a custom effect, extend this class and override [method _on_execute], [method _on_remove], and [method _on_reapply].

enum StackMode { 
	## Prevents duplicate logic. Handles the timer based on [member duration_mode].
	UNIQUE, 
	## Increases the stack count up to [member max_stacks] and calls [method _on_reapply].
	INTENSITY, 
	## Instantiates a completely separate timer. Ignores [member max_stacks] and [member duration_mode].
	MULTIPLE_INSTANCES 
}

enum DurationMode {
	## Adds the new duration to the existing time left.
	ADD,
	## Overwrites the current time left with the new duration (refreshes).
	REFRESH,
	## Keeps whichever duration is longer.
	KEEP_LONGEST
}



#region Variables

## The unique identifier. If left blank, it falls back to the file name or memory ID.
@export var id: StringName:
	get:
		if id != &"": 
			return id
			
		var path_name = resource_path.get_file().trim_suffix('.tres')
		if path_name != "":
			return StringName(path_name)
		
		return StringName(str(get_instance_id()))

## How the effect handles being applied to a target that already has it.
@export var stack_mode: StackMode = StackMode.UNIQUE

## How the timer reacts when the effect stacks 
## Used for [code]StackMode.UNIQUE[/code] and [code]StackMode.INTENSITY[/code].
## While [code]StackMode.MULTIPLE_INSTANCES[/code] ignores this.
@export var duration_mode: DurationMode = DurationMode.REFRESH

## The maximum allowed stacks if using [code]StackMode.INTENSITY[/code] ([code]0[/code] = infinite).
@export var max_stacks: int = 0

## How long this effect will last in seconds. 
## [br][br][b]Note:[/b] Set to [code]-1.0[/code] for permanent effects.
@export_range(-1.0, 9999.0, 0.1, "or_greater", "suffix:s") var duration: float = -1.0

## The frequency in seconds at which [method tick] triggers. Set to 0.0 to disable interval ticking.
@export_range(0.0, 10.0, 0.05, "suffix:s") var tick_interval: float = 0.0

#endregion



#region Public API

## Executes the initial application of this effect on the specified [param target].
## [br][br]
## This method ensures the [param target] is a valid [Object] in memory before 
## calling the virtual [method _on_execute] method. It is called automatically 
## when a new effect instance is spawned.
func execute(target: Object) -> void:
	if is_instance_valid(target):
		_on_execute(target)


## Reverses the impact of this effect from the [param target].
## [br][br]
## This method ensures the [param target] is a valid [Object] 
## before calling the virtual [method _on_remove] method. It is called 
## automatically when the effect's duration expires or it is explicitly purged.
func remove(target: Object) -> void:
	if is_instance_valid(target):
		_on_remove(target)


## Updates the active effect on the [param target] to match the new [param current_stack] count.
## [br][br]
## This method ensures the [param target] is a valid [Object] before calling the virtual 
## [method _on_reapply] method. This is exclusively called when [member stack_mode] is 
## set to [code]StackMode.INTENSITY[/code] and the [member FoxEffectInstance.stack] count changes.
func reapply(target: Object, current_stack: int) -> void:
	if is_instance_valid(target):
		_on_reapply(target, current_stack)


## Triggers the recurring [method _on_tick] logic.
## [br][br]
## This method ensures the [param target] is a valid [Object] before executing.
func tick(target: Object, current_stack: int) -> void:
	if is_instance_valid(target):
		_on_tick(target, current_stack)

#endregion



@abstract
func _on_execute(target: Object) -> void

@abstract
func _on_remove(target: Object) -> void

@abstract
func _on_reapply(target: Object, current_stack: int = 1) -> void

@abstract
func _on_tick(target: Object, current_stack: int) -> void

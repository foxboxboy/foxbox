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
## To create a custom effect, extend this class and override [method _on_execute],
## [method _on_remove], [method _on_reapply], and [method _on_tick]. All four are abstract,
## so every subclass must implement them even if the body is left empty.
## [codeblock]
## # A poison that ticks damage and scales with its stack count.
## extends FoxEffect
##
## @export var damage_per_tick: float = 2.0
##
## func _on_execute(target: Object) -> void:
##     target.play_poison_vfx()
##
## func _on_tick(target: Object, current_stack: int) -> void:
##     target.health -= damage_per_tick * current_stack
##
## func _on_reapply(target: Object, current_stack: int = 1) -> void:
##     pass  # ticking already reads the stack, so nothing to rescale
##
## func _on_remove(target: Object) -> void:
##     target.stop_poison_vfx()
## [/codeblock]
## Set [member stack_mode] to [code]StackMode.INTENSITY[/code] and [member tick_interval] to
## [code]1.0[/code] on the resource to make the example above tick once per second.
## @tutorial(Building a status effect system): https://foxfabric-godot.readthedocs.io/en/latest/guide_status_effects.html

## Determines what happens when this effect is applied to a target that already has it.
enum StackMode {
	## Prevents duplicate logic. Handles the timer based on [member duration_mode].
	UNIQUE, 
	## Increases the stack count up to [member max_stacks] and calls [method _on_reapply].
	INTENSITY, 
	## Instantiates a completely separate timer. Ignores [member max_stacks] and [member duration_mode].
	MULTIPLE_INSTANCES 
}

## Determines how the remaining time is recalculated when an effect stacks.
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




#region Abstract Methods

## Applies this effect's initial impact to [param target]. Called once, when the effect is
## first applied.
## [br][br]
## [param target] is guaranteed to be a valid [Object] by the time this runs.
@abstract
func _on_execute(target: Object) -> void


## Reverses whatever [method _on_execute] and [method _on_reapply] did to [param target].
## Called once, when the effect expires or is purged.
## [br][br]
## [b]Note:[/b] This is skipped when a save file is loaded, so it must not be relied on to
## clean up state that was never applied in this session.
@abstract
func _on_remove(target: Object) -> void


## Rescales this effect on [param target] to match [param current_stack].
## [br][br]
## Only called when [member stack_mode] is [code]StackMode.INTENSITY[/code] and the stack count
## actually changes. Implementations should recalculate from the stack count rather than adding
## to whatever they applied last time.
@abstract
func _on_reapply(target: Object, current_stack: int = 1) -> void


## Runs the recurring behaviour on [param target], scaled by [param current_stack].
## [br][br]
## Fires every [member tick_interval] seconds while the effect is active. Never called when
## [member tick_interval] is [code]0.0[/code].
@abstract
func _on_tick(target: Object, current_stack: int) -> void

#endregion

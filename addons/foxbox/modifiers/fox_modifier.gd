@abstract
class_name FoxModifier
extends FoxResource
## A Strategy-pattern Resource defining a discrete package of logic to be executed on a target.

enum StackMode { 
	## Prevents duplicate logic. Resets/Adds to the duration.
	UNIQUE, 
	## Increases the stack count up to max_stacks.
	INTENSITY, 
	## Allows multiple independent instances to run their own timers.
	MULTIPLE_INSTANCES 
}





#region Variables

@export var modifier_id: StringName:
	get:
		if modifier_id.length() > 0: 
			return modifier_id
		return StringName(_get_resource_name())

## How the modifier handles being applied multiple times.
@export var stack_mode: StackMode = StackMode.UNIQUE

## The maximum allowed stacks if using StackMode.INTENSITY. (0 = infinite).
@export var max_stacks: int = 0

## How long this effect will last in seconds. Leave as -1.0 for permanent.
@export var duration: float = -1.0

#endregion





#region Public API

func execute(target: Node) -> void:
	_on_execute(target)


func remove(target: Node) -> void:
	_on_remove(target)


func reapply(target: Node, stack: int) -> void:
	_on_reapply(target, stack)


func _get_resource_name() -> String:
	return resource_path.get_file().trim_suffix('.tres')

#endregion





@abstract
func _on_execute(_target: Node) -> void


@abstract
func _on_remove(_target: Node) -> void


@abstract
func _on_reapply(_target: Node, _stack: int = 1) -> void

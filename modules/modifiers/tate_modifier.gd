# modules/modifiers/tate_modifier.gd
@abstract
class_name TateModifier
extends TateResource
## A specialized strategy-pattern Resource that defines a discrete package 
## of logic (Stat Changes, Behaviors, or Hardware Swaps) to be executed 
## on a target. It serves as a bridge between high-level game rules 
## (Cards/Upgrades) and low-level entity data.

enum StackMode { UNIQUE, STACKING, ADDITIVE }

## (Optional) the string id associated with this Modifier. 
## Leave blank to use the name of the resource file associated
## with this TateModifier instance.
@export var modifier_id: StringName:
	get:
		if modifier_id.length() > 0: 
			return modifier_id
		else:
			return _get_resource_name()

## How the modifier will be applied.
## StackMode.UNIQUE = Prevents "Log Bloat" and duplicate logic. 
## It ensures only one instance of an ID exists.
## StackMode.STACKING = Allows multiple independent instances 
## of the same modifier to run their own timers.
## StackMode.ADDIDITIVE = Keeps the UI clean by having only one 
## icon, but allows the "Intensity" of the modifier to grow.
@export var stack_mode: StackMode = StackMode.UNIQUE

## How long this effect will last. Leave as -1 for indefinite.
@export var duration: float = -1 # -1 for permanent


## Logic to run when applied
func execute(target: Node) -> void:
	_on_execute(target)

## Logic to run when time runs out or it's removed
func remove(target: Node) -> void:
	_on_remove(target)
 
## Logic to run when the TateModifierInstance's stack is increased.
func reapply(target: Node):
	_on_reapply(target)

# Virtual methods for implementation
## Change this for everything that extends TateModifier
func _on_execute(_target: Node) -> void: pass
## Change this for everything that extends TateModifier
func _on_remove(_target: Node) -> void: pass
## Change this for everything that extends TateModifier
func _on_reapply(_target: Node) -> void: pass

func _get_resource_name():
	return resource_path.get_file().trim_suffix('.tres')

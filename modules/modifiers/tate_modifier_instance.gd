# tates_lib/modifiers/tate_modifier_instance.gd
extends TateNode
class_name TateModifierInstance
## A physical instance of a modifier.

var modifier_id: StringName:
	get:
		return modifier_data.modifier_id
	set(new_id):
		modifier_data.modifier_id = new_id
var modifier_data: TateModifier # The Resource containing the ID/Category
var time_left: float
var target: Node
var stack: int = 1

## Increases stacks by 1 and tells the TateModifier associated with modifier_data 
## to reapply().
func apply_stack() -> void:
	stack += 1 
	# Tell the Strategy (Resource) to update based on the new stack count
	modifier_data.reapply(target)

func _ready() -> void:
	# Set the name so it looks nice in the Remote Scene Tree
	name = modifier_data.modifier_id 
	modifier_data.execute(target)

func _process(delta: float) -> void:
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			queue_free() # Automatic cleanup

func _exit_tree() -> void:
	modifier_data.remove(target)

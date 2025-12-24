# tates_lib/modifiers/tate_modifier_node.gd
extends TateComponent
class_name TateModifierNode
## A physical instance of a modifier.

var modifier_data: TateModifier # The Resource containing the ID/Category
var time_left: float
var target: Node

func _ready() -> void:
	# Set the name so it looks nice in the Remote Scene Tree
	print("NAME: ",modifier_data.resource_name)
	name = modifier_data.modifier_id 
	modifier_data.execute(target)

func _process(delta: float) -> void:
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			queue_free() # Automatic cleanup

func _exit_tree() -> void:
	modifier_data.remove(target)

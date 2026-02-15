# tates_lib/modifiers/tate_modifier_instance.gd
class_name FoxModifierInstance
extends FoxRefCounted
## A physical instance of a modifier.


var modifier_id: StringName:
	get:
		return modifier_data.modifier_id
	set(new_id):
		modifier_data.modifier_id = new_id

var modifier_data: FoxModifier
var target: Node
var time_left: float
var stack: int = 1

## Increases stack and tells the FoxModifier associated with modifier_data 
## to reapply().
func increase_stack(amount := 1) -> void:
	stack += amount 
	if modifier_data:
		modifier_data.reapply(target, stack)


## Decreases stack and tells the FoxModifier associated with modifier_data 
## to reapply().
func decrease_stack(amount := 1) -> void:
	stack -= amount
	if modifier_data:
		modifier_data.reapply(target, stack)



## Logic to run when time runs out or it's removed manually.
func cleanup() -> void:
	if modifier_data and is_instance_valid(target):
		modifier_data.remove(target)

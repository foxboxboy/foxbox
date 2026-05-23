@abstract 
class_name FoxAttributeRule
extends FoxRefCounted
## An abstract base class for defining mathematical or logical modifiers applied to data.
##
## Designed to be extended by custom rule scripts (e.g., a flat addition rule, a percentage multiplier rule). 
## When added to a [FoxAttributeMap], the map automatically routes the correct data to [method apply_to] 
## and [method remove_from] based on the [member target_key].

## The unique identifier used to track and remove this specific rule instance (e.g., [code]&"fire_mage_buff_1"[/code]).
var id: StringName = &""

## The specific dictionary key in the [FoxAttributeMap] that this rule targets (e.g., [code]&"health"[/code], [code]&"move_speed"[/code]).
var target_key: StringName = &""

func _init(p_id: StringName = &"", p_target_key: StringName = &"") -> void:
	id = p_id
	target_key = p_target_key

## Executes the rule's logic on the target [param data]. 
## Must be overridden by subclasses to define exactly how the data is modified.
@abstract func apply_to(data: Variant) -> void

## Reverses the rule's logic, safely restoring the target [param data] to its previous state. 
## Must be overridden by subclasses to define exactly how the modification is undone.
@abstract func remove_from(data: Variant) -> void

@abstract 
class_name FoxAttributeRule
extends FoxRefCounted
## An abstract base class for defining mathematical or logical modifiers applied to data.
##
## Designed to be extended by custom rule scripts (e.g., a flat addition rule, a percentage multiplier rule).
## When added to a [FoxAttributeMap], the map automatically routes the correct data to [method apply_to]
## and [method remove_from] based on the [member target_key].
## [br][br]
## A rule must be reversible. Whatever [method apply_to] does to the data,
## [method remove_from] has to undo exactly, because the map calls it when the rule is removed
## or when a child map stops inheriting.
## [codeblock]
## # flat_bonus.gd
## class_name FlatBonus
## extends FoxAttributeRule
##
## var amount: float = 0.0
##
## func _init(p_id: StringName, p_key: StringName, p_amount: float) -> void:
##     super(p_id, p_key)
##     amount = p_amount
##
## func apply_to(map: FoxAttributeMap) -> void:
##     var current: float = map.get_data(target_key, 0.0)
##     map.set_data(target_key, current + amount)
##
## func remove_from(map: FoxAttributeMap) -> void:
##     var current: float = map.get_data(target_key, 0.0)
##     map.set_data(target_key, current - amount)
## [/codeblock]
## Adding it to a map applies it there and to every child map beneath it, so one rule on a
## vehicle can slow everything riding in it.
## [codeblock]
## var haste := FlatBonus.new(&"haste", &"move_speed", 2.0)
##
## vehicle_map.add_rule(haste)      # applies here and to every child map
## vehicle_map.remove_rule(&"haste")  # reverses it everywhere
## [/codeblock]
## Rules are matched for removal by [member id], not by object identity, so give each one an id
## you can find it by later.

## The unique identifier used to track and remove this specific rule instance (e.g., [code]&"fire_mage_buff_1"[/code]).
var id: StringName = &""

## The specific dictionary key in the [FoxAttributeMap] that this rule targets (e.g., [code]&"health"[/code], [code]&"move_speed"[/code]).
var target_key: StringName = &""

func _init(p_id: StringName = &"", p_target_key: StringName = &"") -> void:
	id = p_id
	target_key = p_target_key

## Executes the rule's logic using the map as a reference. 
## Must be overridden by subclasses to define exactly how the data is modified.
@abstract func apply_to(map: FoxAttributeMap) -> void

## Reverses the rule's logic, safely restoring the target data to its previous state. 
## Must be overridden by subclasses to define exactly how the modification is undone.
@abstract func remove_from(map: FoxAttributeMap) -> void

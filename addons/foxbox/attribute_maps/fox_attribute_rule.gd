@abstract 
class_name FoxAttributeRule
extends FoxRefCounted

## The unique identifier so we can remove it later (e.g., &"fire_mage_buff_1")
var rule_id: StringName = &"null"

## The specific data key this rule is looking for (e.g., &"health", &"move_speed")
var target_key: StringName = &"null"

## Applies the math/logic to the local data. Overridden by subclasses.
@abstract func apply_to(data: Variant) -> void

## Removes the math/logic from the local data. Overridden by subclasses.
@abstract func remove_from(data: Variant) -> void

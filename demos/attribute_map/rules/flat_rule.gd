# Adds a flat modifier to a stat, filed under the rule's own id.
#
# The stat keeps the modifier as its own layer, so removing this rule takes off exactly what it put
# on however much else has happened in between. Nothing here has to remember a number.
class_name DemoFlatRule
extends FoxAttributeRule


## Added to the stat's base. Negative to subtract.
var amount: float = 0.0


func _init(p_id: StringName = &"", p_target_key: StringName = &"", p_amount: float = 0.0) -> void:
	super(p_id, p_target_key)
	amount = p_amount


func apply_to(map: FoxAttributeMap) -> void:
	var stat: FoxModifiableStat = map.get_data(target_key, null)
	if stat != null:
		stat.add_flat_modifier(id, amount)


func remove_from(map: FoxAttributeMap) -> void:
	var stat: FoxModifiableStat = map.get_data(target_key, null)
	if stat != null:
		stat.pop_flat_modifier(id)

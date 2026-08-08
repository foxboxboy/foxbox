# Adds a flat amount to a numeric key, and takes exactly the same amount back off.
extends FoxAttributeRule


## Added to the target key. Negative to subtract.
var amount: float = 0.0


func _init(p_id: StringName = &"", p_target_key: StringName = &"", p_amount: float = 0.0) -> void:
	super(p_id, p_target_key)
	amount = p_amount


func apply_to(map: FoxAttributeMap) -> void:
	var current: float = map.get_data(target_key, 0.0)
	map.set_data(target_key, current + amount)


# Whatever apply_to did, this has to undo exactly, because the map calls it when the rule is
# removed and when a child stops inheriting.
func remove_from(map: FoxAttributeMap) -> void:
	var current: float = map.get_data(target_key, 0.0)
	map.set_data(target_key, current - amount)

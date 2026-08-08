extends FoxAttributeRule
## A basic rule that adds or subtracts a flat number from a numeric data key.

## The amount to add to (or subtract from) the target data.
var amount: float = 0.0

func _init(p_id: StringName = &"", p_target_key: StringName = &"", p_amount: float = 0.0) -> void:
	# Pass the ID and target key up to the base class
	super(p_id, p_target_key)
	amount = p_amount


## Gets the current value from the map, adds the amount, and updates the map.
func apply_to(map: FoxAttributeMap) -> void:
	# We default to 0.0 just in case the key doesn't exist yet
	var current_value: float = map.get_data(target_key, 0.0)

	map.set_data(target_key, current_value + amount)


## Gets the current value from the map, subtracts the amount, and updates the map.
func remove_from(map: FoxAttributeMap) -> void:
	var current_value: float = map.get_data(target_key, 0.0)

	map.set_data(target_key, current_value - amount)

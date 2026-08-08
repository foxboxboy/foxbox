extends Object

func _get_property_list() -> Array[Dictionary]:
	return [{"name": &"runtime_flags", "type": TYPE_DICTIONARY, "usage": PROPERTY_USAGE_EDITOR}]

func _get(property: StringName) -> Variant:
	if property == &"runtime_flags":
		return {&"slowed": 2}
	return null

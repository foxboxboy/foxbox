# Puts a weapon out of action.
#
# It does not zero one key, it zeroes everything filed under the weapon's firepower group. That is
# what a group is for: the rule never has to know which stats a particular weapon happens to carry,
# only which of them count as firepower.
extends FoxAttributeRule


const GROUP: StringName = &"firepower"

## What was taken off each key, so remove_from can put exactly that back. A rule holding state like
## this can only be applied to one map, which is why this one is added straight to the weapon
## rather than to the tank.
var _removed: Dictionary[StringName, float] = {}


func _init(p_id: StringName = &"") -> void:
	super(p_id, &"damage")


func apply_to(map: FoxAttributeMap) -> void:
	_removed.clear()

	for key: StringName in map.get_keys_in_group(GROUP):
		var value: float = map.get_data(key, 0.0)
		_removed[key] = value
		map.set_data(key, 0.0)


## Adds back what was taken rather than restoring the old number, so a boost that arrived while the
## weapon was out of action survives being repaired.
func remove_from(map: FoxAttributeMap) -> void:
	for key: StringName in _removed:
		map.set_data(key, map.get_data(key, 0.0) + _removed[key])

	_removed.clear()

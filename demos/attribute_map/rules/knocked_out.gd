# Puts a weapon out of action.
#
# A multiplier of -1 takes the stat's running multiplier to zero, and a total of zero survives
# anything. A damage boost arriving while the gun is wrecked is still multiplied by zero, so it
# cannot bring the gun back, and it is waiting there the moment the gun is repaired.
# [br][br]
# It works on every stat filed under the weapon's firepower group rather than on one named key.
# That is what a group is for: the rule never has to know which stats a particular weapon carries,
# only which of them count as firepower.
extends FoxAttributeRule


const GROUP: StringName = &"firepower"

## Enough to cancel the 1.0 the multiplier total starts at.
const CANCEL: float = -1.0


func _init(p_id: StringName = &"") -> void:
	super(p_id, &"damage")


func apply_to(map: FoxAttributeMap) -> void:
	for stat: FoxModifiableStat in _firepower(map):
		stat.add_multiplier_modifier(id, CANCEL)


func remove_from(map: FoxAttributeMap) -> void:
	for stat: FoxModifiableStat in _firepower(map):
		stat.pop_multiplier_modifier(id)


## Holding no state means this rule could safely be added higher up and land on every weapon
## underneath, unlike one that has to remember what it took.
func _firepower(map: FoxAttributeMap) -> Array[FoxModifiableStat]:
	var stats: Array[FoxModifiableStat] = []
	for key: StringName in map.get_keys_in_group(GROUP):
		var stat: FoxModifiableStat = map.get_data(key, null)
		if stat != null:
			stats.append(stat)

	return stats

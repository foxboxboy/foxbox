# Bores out a cannon.
#
# Targets calibre, which only a cannon carries. Added to the tank it still travels to every map
# underneath, and the turret and the machine gun track it without a thing happening to them,
# because a rule is only applied where its target key exists.
extends FoxAttributeRule


const EXTRA_CALIBRE: float = 30.0
const EXTRA_DAMAGE: float = 15.0


func _init(p_id: StringName = &"") -> void:
	super(p_id, &"calibre")


func apply_to(map: FoxAttributeMap) -> void:
	_add(map, &"calibre", EXTRA_CALIBRE)
	_add(map, &"damage", EXTRA_DAMAGE)


func remove_from(map: FoxAttributeMap) -> void:
	_pop(map, &"calibre")
	_pop(map, &"damage")


func _add(map: FoxAttributeMap, key: StringName, amount: float) -> void:
	var stat: FoxModifiableStat = map.get_data(key, null)
	if stat != null:
		stat.add_flat_modifier(id, amount)


func _pop(map: FoxAttributeMap, key: StringName) -> void:
	var stat: FoxModifiableStat = map.get_data(key, null)
	if stat != null:
		stat.pop_flat_modifier(id)

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
	map.set_data(&"calibre", map.get_data(&"calibre", 0.0) + EXTRA_CALIBRE)
	map.set_data(&"damage", map.get_data(&"damage", 0.0) + EXTRA_DAMAGE)


func remove_from(map: FoxAttributeMap) -> void:
	map.set_data(&"calibre", map.get_data(&"calibre", 0.0) - EXTRA_CALIBRE)
	map.set_data(&"damage", map.get_data(&"damage", 0.0) - EXTRA_DAMAGE)

# The readout. Every value on it is read back out of the maps each frame, so there is no second
# copy of the state anywhere to drift.
#
# The table is a GridContainer of Labels laid out in the scene, so the columns line themselves up
# and this script only ever writes text into cells that already exist.
class_name DemoTankHud
extends VBoxContainer


#region Variables

## Which cell in a row is which, so filling one does not mean counting columns.
enum Column { NAME, DAMAGE, STATS, GROUP, RULES, FLAGS }

@export var status: Label

## Each row's six cells, in the order the columns sit in the scene: name, damage, other stats,
## group, rules, flags.
@export var tank_cells: Array[Label]
@export var turret_cells: Array[Label]
@export var cannon_cells: Array[Label]
@export var machine_gun_cells: Array[Label]

@export var tank: DemoTankPart
@export var turret: DemoTankPart
@export var cannon: DemoTankPart
@export var machine_gun: DemoTankPart

@export var wall: DemoTankWall

## Asked for the boost level, so the buttons going quiet at the limit has something to point at.
@export var controls: DemoTankControls

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	status.text = "wall %d      damage boost %+d" % [roundi(wall.get_health()), controls.get_boost()]

	# Indents match the tree: the tank owns the turret, the turret owns the cannon, and the machine
	# gun hangs off the tank beside the turret.
	_fill(tank_cells, tank, "")
	_fill(turret_cells, turret, "    ")
	_fill(cannon_cells, cannon, "        ")
	_fill(machine_gun_cells, machine_gun, "    ")

#endregion


#region Private

func _fill(cells: Array[Label], part: DemoTankPart, indent: String) -> void:
	cells[Column.NAME].text = indent + part.label
	cells[Column.DAMAGE].text = _damage(part)
	cells[Column.STATS].text = _other_stats(part)
	cells[Column.GROUP].text = _groups(part.attributes)
	cells[Column.RULES].text = _rules(part.attributes)
	cells[Column.FLAGS].text = _flags(part.attributes)


## A dash rather than a zero for the parts carrying no damage at all, so a part that has none
## reads differently from a weapon knocked down to none.
func _damage(part: DemoTankPart) -> String:
	if not part.attributes.has_data(&"damage"):
		return "-"

	return _number(part.get_stat(&"damage"))


## Everything except damage, which has a column to itself.
func _other_stats(part: DemoTankPart) -> String:
	var cells: PackedStringArray = []
	for key: StringName in part.get_stats():
		if key == &"damage":
			continue

		cells.append("%s %s" % [key, _number(part.get_stat(key))])

	return _joined(cells)


## The groups the map is actually holding, rather than the name the part was told to file under.
## A part with no stats never creates its group, and printing the name regardless would show one
## that is not there.
func _groups(map: FoxAttributeMap) -> String:
	var names: PackedStringArray = []
	for group: StringName in map.get_group_names():
		names.append(String(group))

	return _joined(names)


func _rules(map: FoxAttributeMap) -> String:
	var cells: PackedStringArray = []
	for id: StringName in map.get_rule_summary():
		cells.append(String(id))

	return _joined(cells)


## Anything handed down by a parent map is called out, since a flag cannot say where it came from
## on its own.
func _flags(map: FoxAttributeMap) -> String:
	var handed_down: Dictionary[StringName, int] = {}
	var parent: FoxAttributeMap = map.get_parent_map()
	if parent != null:
		handed_down = parent.get_flags()

	var cells: PackedStringArray = []
	for flag: StringName in map.get_flags():
		if handed_down.has(flag):
			cells.append("%s (inherited)" % flag)
		else:
			cells.append(String(flag))

	return _joined(cells)


## A fire rate of 0.5 is not 1, and an armour of 60 does not need a decimal point.
func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)

	return "%.1f" % value


func _joined(cells: PackedStringArray) -> String:
	return ", ".join(cells) if not cells.is_empty() else "-"

#endregion

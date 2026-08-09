# The readout. Every number on it is read back out of the maps each frame, so there is no second
# copy of the state anywhere to drift.
extends Label


#region Variables

const Part = preload("res://demos/attribute_map/part.gd")
const Wall = preload("res://demos/attribute_map/wall.gd")
const Controls = preload("res://demos/attribute_map/controls.gd")

## One per column, left to right. Adding a column means adding a heading here and a cell to _row.
const HEADINGS: PackedStringArray = [
	"part",
	"damage",
	"its own stats",
	"group",
	"rules it tracks",
	"flags",
]

## Space between columns. Their widths come from what is in them, so this is the only spacing
## decided here.
const GAP: String = "   "

## The four parts, in the order they are drawn.
@export var tank: Part
@export var turret: Part
@export var cannon: Part
@export var machine_gun: Part

@export var wall: Wall

## Asked for the boost level, so the buttons going quiet at the limit has something to point at.
@export var controls: Controls

#endregion


#region Built-In Virtuals

func _process(_delta: float) -> void:
	text = "\n".join([
		"wall %d      damage boost %+d" % [roundi(wall.get_health()), controls.get_boost()],
		"",
		_table(),
		"",
		"Rules travel to every map below where they were added, and land only on the ones",
		"holding the key they target. The hull and turret hold no damage, so they track the",
		"boost without it doing a thing to them.",
	])

#endregion


#region The table

## Indents match the tree: the tank owns the turret, the turret owns the cannon, and the machine
## gun hangs off the tank beside the turret.
func _table() -> String:
	var rows: Array[PackedStringArray] = [
		HEADINGS,
		_row(tank, ""),
		_row(turret, "  "),
		_row(cannon, "    "),
		_row(machine_gun, "  "),
	]

	return _padded(rows)


## One part's cells, in the same order as HEADINGS.
func _row(part: Part, indent: String) -> PackedStringArray:
	return PackedStringArray([
		indent + part.label,
		_damage(part),
		_other_stats(part),
		String(part.group),
		_rules(part.attributes),
		_flags(part.attributes),
	])


## Pads each column to its own widest cell, headings included.
## [br][br]
## No width is written down, so none can go stale, and a column is never left stranded across a
## gap sized for content that is not currently there.
func _padded(rows: Array[PackedStringArray]) -> String:
	var widths: PackedInt32Array = []
	for column: int in HEADINGS.size():
		var widest: int = 0
		for row: PackedStringArray in rows:
			widest = maxi(widest, row[column].length())

		widths.append(widest)

	var lines: PackedStringArray = []
	for row: PackedStringArray in rows:
		var line: String = ""
		for column: int in row.size():
			# The last column has nothing after it to line up with.
			if column == row.size() - 1:
				line += row[column]
			else:
				line += row[column].rpad(widths[column]) + GAP

		lines.append(line)

	return "\n".join(lines)

#endregion


#region Cells

## A dash rather than a zero for the parts carrying no damage at all, so a part that has none
## reads differently from a weapon knocked down to none.
func _damage(part: Part) -> String:
	if not part.attributes.has_data(&"damage"):
		return "-"

	return _number(part.get_stat(&"damage"))


## Everything except damage, which has a column to itself.
func _other_stats(part: Part) -> String:
	var cells: PackedStringArray = []
	for key: StringName in part.get_stats():
		if key == &"damage":
			continue

		cells.append("%s %s" % [key, _number(part.get_stat(key))])

	return _joined(cells)


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

#endregion


#region Formatting

## A fire rate of 0.5 is not 1, and an armour of 60 does not need a decimal point.
func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)

	return "%.1f" % value


func _joined(cells: PackedStringArray) -> String:
	return ", ".join(cells) if not cells.is_empty() else "-"

#endregion

@tool
extends VBoxContainer
## A live read-out of one [FoxAttributeMap]'s data, groups, flags and rules.
##
## A [FoxAttributeMap] publishes its runtime state as [code]runtime_*[/code] properties, and this
## control reads them. That works the same whether the object is a real node in the open scene or
## the stand-in the debugger hands over for a node in a running game. The running game is the
## interesting case: a map is empty until something fills it.


## How often to look for changes. Fast enough to follow a fight, slow enough that the inspector is
## not rebuilding itself every frame.
const REFRESH_SECONDS: float = 0.25

const DATA: StringName = &"runtime_data"
const GROUPS: StringName = &"runtime_groups"
const FLAGS: StringName = &"runtime_flags"
const RULES: StringName = &"runtime_rules"

var _target: Object
var _elapsed: float = 0.0

## The last state rendered, as a string. Rebuilding only when this changes stops the rows being
## torn down and rebuilt four times a second while nothing is happening.
var _rendered: String = ""


func _init(target: Object = null) -> void:
	_target = target
	add_theme_constant_override(&"separation", 2)


func _ready() -> void:
	_refresh()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return

	_elapsed = 0.0
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_target):
		return

	var data: Dictionary = _read(DATA)
	var groups: Dictionary = _read(GROUPS)
	var flags: Dictionary = _read(FLAGS)
	var rules: Dictionary = _read(RULES)

	var signature: String = "%s%s%s%s" % [data, groups, flags, rules]
	if signature == _rendered:
		return

	_rendered = signature

	for child: Node in get_children():
		child.queue_free()

	if data.is_empty() and flags.is_empty() and rules.is_empty():
		_add_note("Empty. A map fills up at runtime, so open this on a node in the remote scene tree while the game is running.")
		return

	_add_section("Data", _data_rows(data, groups))
	_add_section("Flags", _flag_rows(flags))
	_add_section("Rules", _rule_rows(rules))


func _read(property: StringName) -> Dictionary:
	var value: Variant = _target.get(property)
	return value if value is Dictionary else {}


#region Rows

# Static so the formatting can be tested; the editor will not build this control headlessly.

## Each data key, with the groups it belongs to trailing behind it.
static func _data_rows(data: Dictionary, groups: Dictionary) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	for key: Variant in data:
		var label: String = str(key)
		var tags: PackedStringArray = _groups_holding(key, groups)
		if not tags.is_empty():
			label += "   (%s)" % ", ".join(tags)

		rows.append(PackedStringArray([label, str(data[key])]))

	return rows


static func _groups_holding(key: Variant, groups: Dictionary) -> PackedStringArray:
	var holding: PackedStringArray = []
	for group: Variant in groups:
		var members: Variant = groups[group]
		if members is Array and members.has(key):
			holding.append(str(group))

	return holding


## Stacks are the whole point of a flag, so the count is never hidden, not even at one.
static func _flag_rows(flags: Dictionary) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	for flag: Variant in flags:
		rows.append(PackedStringArray([str(flag), "x%s" % flags[flag]]))

	return rows


static func _rule_rows(rules: Dictionary) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	for id: Variant in rules:
		rows.append(PackedStringArray([str(id), "-> %s" % rules[id]]))

	return rows

#endregion


#region Drawing

func _add_section(title: String, rows: Array[PackedStringArray]) -> void:
	if rows.is_empty():
		return

	var heading: Label = Label.new()
	heading.text = title
	heading.add_theme_color_override(&"font_color", get_theme_color(&"accent_color", &"Editor"))
	add_child(heading)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 16)
	add_child(grid)

	for row: PackedStringArray in rows:
		var name_label: Label = Label.new()
		name_label.text = "    %s" % row[0]
		grid.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.text = row[1]
		value_label.add_theme_color_override(&"font_color", get_theme_color(&"font_readonly_color", &"Editor"))
		grid.add_child(value_label)


func _add_note(text: String) -> void:
	var note: Label = Label.new()
	note.text = text
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override(&"font_color", get_theme_color(&"font_readonly_color", &"Editor"))
	add_child(note)

#endregion

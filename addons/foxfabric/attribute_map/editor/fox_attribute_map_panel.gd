@tool
extends Tree
## A live read-out of one [FoxAttributeMap]'s data, groups, flags, rules and place in the map tree.
##
## A [FoxAttributeMap] publishes its runtime state as [code]runtime_*[/code] properties, and this
## control reads them. That works the same whether the object is a real node in the open scene or
## the stand-in the debugger hands over for a node in a running game. The running game is the
## interesting case: a map is empty until something fills it.
## [br][br]
## The heading above it belongs to the inspector, not to this. Sitting inside a group means the
## editor draws the section itself, so it matches Members and Node without imitating them.




#region Variables

## How often to look for changes. Fast enough to follow a fight, slow enough that the inspector is
## not rebuilding itself every frame.
const REFRESH_SECONDS: float = 0.25

## Section headings. Named rather than written out twice, because the help below is keyed by them
## and a rename that reached only one of the two would quietly cost the section its description.
const DATA: String = "Data"
const GROUPS: String = "Groups"
const RULES: String = "Active Rules"
const FLAGS: String = "Flags"
const TREE: String = "Tree"

## What each heading is for, shown on hovering it. The inspector has nothing to say about a control
## it did not build, so the descriptions come from here.
const HEADING_HELP: Dictionary[String, String] = {
	DATA: "Every key this map holds, with its value written out as text.",
	GROUPS: "Data keys filed together, so a rule can reach all of them without naming each one.",
	RULES: "Rules applied here, including any that came down from a map above this one.",
	FLAGS: "Counted states. A flag lifts only once every stack put on it has been taken back off.",
	TREE: "The maps above and below this one. Rules and flags travel down this chain.",
}

var _target: Object
var _elapsed: float = 0.0

# Every row in draw order, so a value that moved can be written straight into its item.
var _items: Array[TreeItem] = []

## The rows last drawn. Values change constantly and names hardly ever, so a value on its own is
## written into the row it belongs to and the tree is left standing.
var _drawn: Array[Row] = []

# Read from the theme rather than written down, so a different editor theme carries them along.
var _heading_color: Color = Color.WHITE
var _name_color: Color = Color.WHITE
var _value_color: Color = Color.WHITE

#endregion




#region Built-In Virtuals

func _init(target: Object = null) -> void:
	_target = target

	columns = 2

	# Both share the width evenly. Turning expand off on the names does not shrink the column to fit
	# its longest row, it collapses to a minimum and clips every one of them.
	set_column_expand(0, true)
	set_column_expand(1, true)

	# The group heading above names this, so a root row would say it twice.
	hide_root = true

	# Nothing here is worth clicking, and a Tree that takes focus draws a highlight behind whatever
	# was last touched. Rows are made unselectable as they are built.
	focus_mode = Control.FOCUS_NONE


func _ready() -> void:
	item_collapsed.connect(_on_item_collapsed)
	_read_theme()
	_refresh()


func _notification(what: int) -> void:
	if what != NOTIFICATION_THEME_CHANGED or not is_node_ready():
		return

	_read_theme()

	# Colours are set on each row as it is built, so the rows have to come back to pick up new ones.
	_drawn.clear()
	_refresh()


func _process(delta: float) -> void:
	# An inspector on another tab still processes. Reading six properties back over the debugger
	# four times a second for a panel nobody is looking at is the work worth skipping.
	if not is_visible_in_tree():
		return

	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return

	_elapsed = 0.0
	_refresh()

#endregion




#region Rows

# Pure formatting, kept static so a row set can be checked without standing a control up.

## One line of the read-out.
class Row extends RefCounted:
	## How far in the row sits. Section headings are zero, under the hidden root.
	var depth: int

	## What the row is called, in the first column.
	var name: String

	## What sits in the second column, if anything.
	var value: String


	func _init(p_depth: int, p_name: String, p_value: String = "") -> void:
		depth = p_depth
		name = p_name
		value = p_value


## Every row of the read-out, in draw order. Each section builds its own heading, so the order of
## the sections is the only thing decided here.
static func _rows(data: Dictionary, groups: Dictionary, rules: Dictionary, inherited: Array,
		flags: Dictionary, hierarchy: Dictionary) -> Array[Row]:
	var rows: Array[Row] = []
	rows.append_array(_data_rows(data))
	rows.append_array(_group_rows(groups))
	rows.append_array(_rule_rows(rules, inherited))
	rows.append_array(_flag_rows(flags))
	rows.append_array(_tree_rows(hierarchy))

	return rows


## Each key with its value, already turned into text by the map that published it.
static func _data_rows(data: Dictionary) -> Array[Row]:
	var rows: Array[Row] = [Row.new(0, DATA, _counted(data.size(), "key", "keys"))]
	for key: Variant in data:
		rows.append(Row.new(1, str(key), str(data[key])))

	return rows


## Each group with the keys filed under it hanging off it.
static func _group_rows(groups: Dictionary) -> Array[Row]:
	var rows: Array[Row] = [Row.new(0, GROUPS, _counted(groups.size(), "group", "groups"))]
	for group: Variant in groups:
		var members: Variant = groups[group]
		var keys: Array = members if members is Array else []

		rows.append(Row.new(1, str(group), _counted(keys.size(), "key", "keys")))
		for key: Variant in keys:
			rows.append(Row.new(2, str(key)))

	return rows


## Each rule with the key it acts on. One that came down from a map above says so, since removing
## it here would not take it off the map it came from.
static func _rule_rows(rules: Dictionary, inherited: Array) -> Array[Row]:
	var rows: Array[Row] = [Row.new(0, RULES, _counted(rules.size(), "rule", "rules"))]
	for id: Variant in rules:
		var label: String = str(id)
		if inherited.has(id):
			label += "   (inherited)"

		rows.append(Row.new(1, label, "-> %s" % rules[id]))

	return rows


## Each flag with the number of stacks on it. Stacks are the whole point of a flag, so the count is
## never hidden, not even at one.
static func _flag_rows(flags: Dictionary) -> Array[Row]:
	var rows: Array[Row] = [Row.new(0, FLAGS, _counted(flags.size(), "flag", "flags"))]
	for flag: Variant in flags:
		rows.append(Row.new(1, str(flag), "x%s" % flags[flag]))

	return rows


## How much a heading is holding. It sits in the value column so a section folded away still says
## what is inside it, which is the reason to fold one in the first place.
static func _counted(total: int, singular: String, plural: String) -> String:
	if total == 0:
		return "none"

	if total == 1:
		return "1 %s" % singular

	return "%d %s" % [total, plural]


## The maps around this one, nested by the depth each reported, with the one being inspected marked.
## A map with nothing above or below it gets the heading and nothing under it.
static func _tree_rows(hierarchy: Dictionary) -> Array[Row]:
	# A map on its own reports itself and nothing else, and a chain of one is not a chain.
	var maps: int = hierarchy.size() if hierarchy.size() > 1 else 0

	var rows: Array[Row] = [Row.new(0, TREE, _counted(maps, "map", "maps"))]
	if maps == 0:
		return rows

	var shallowest: int = 0
	for path: Variant in hierarchy:
		var depth: int = hierarchy[path]
		shallowest = mini(shallowest, depth)

	for path: Variant in hierarchy:
		var depth: int = hierarchy[path]

		# Marked on the name rather than in the value column, where it would be the only thing in
		# this section and read as a stray label.
		var label: String = _path_tail(str(path))
		if depth == 0:
			label += "   (this map)"

		rows.append(Row.new(1 + depth - shallowest, label))

	return rows


## The last two segments of a node path. A map is often a child node carrying the same name on
## every entity, so the name on its own does not say which map is being named.
static func _path_tail(path: String) -> String:
	var parts: PackedStringArray = path.split("/", false)
	if parts.size() < 2:
		return path

	return "%s/%s" % [parts[parts.size() - 2], parts[parts.size() - 1]]


## Whether two row sets have the same names in the same nesting. When they do, the rows standing
## can be written into instead of built again.
## [br][br]
## Compared row by row rather than by flattening each set into one string. Names come from the
## data keys a game chose, so any separator picked for that string is a separator a key is allowed
## to contain, and two unlike sets could then match.
static func _same_shape(before: Array[Row], after: Array[Row]) -> bool:
	if before.size() != after.size():
		return false

	for i: int in before.size():
		if before[i].depth != after[i].depth or before[i].name != after[i].name:
			return false

	return true

#endregion




#region Drawing

# Asked for by name, so switching editor theme carries them along. A name the running editor does
# not have falls back to the tree's own colour, which reads plainly rather than failing.
func _read_theme() -> void:
	var plain: Color = get_theme_color(&"font_color")

	_heading_color = _theme_color(&"highlighted_font_color", &"Editor", plain)
	_name_color = _theme_color(&"property_color", &"EditorProperty", plain)
	_value_color = _theme_color(&"readonly_color", &"EditorProperty", plain)


func _theme_color(entry: StringName, type: StringName, fallback: Color) -> Color:
	if has_theme_color(entry, type):
		return get_theme_color(entry, type)

	return fallback


func _refresh() -> void:
	if not is_instance_valid(_target):
		return

	var data: Dictionary = _read_dictionary(&"runtime_data")
	var groups: Dictionary = _read_dictionary(&"runtime_groups")
	var flags: Dictionary = _read_dictionary(&"runtime_flags")
	var rules: Dictionary = _read_dictionary(&"runtime_rules")
	var hierarchy: Dictionary = _read_dictionary(&"runtime_hierarchy")
	var inherited: Array = _read_array(&"runtime_inherited_rules")

	var rows: Array[Row] = _rows(data, groups, rules, inherited, flags, hierarchy)

	if _same_shape(_drawn, rows):
		_write_values(rows)
		return

	_drawn = rows
	_rebuild(rows)


# Rebuilding throws away whatever the reader had collapsed, so it only happens when a name appears
# or disappears. A value that moved goes through _write_values instead.
func _rebuild(rows: Array[Row]) -> void:
	clear()
	_items.clear()

	# Never drawn. It exists because a Tree needs something for the sections to hang from.
	var root: TreeItem = create_item()

	# The last row seen at each depth, so a row knows which one above it to hang from.
	var parents: Dictionary[int, TreeItem] = {0: root}

	for row: Row in rows:
		var depth: int = row.depth
		var value: String = row.value

		var item: TreeItem = create_item(parents.get(depth, root))
		item.set_text(0, row.name)
		item.set_text(1, value)
		item.set_selectable(0, false)
		item.set_selectable(1, false)
		item.set_custom_color(0, _heading_color if depth == 0 else _name_color)

		# A dock is narrow and both columns run out of room, so every cell carries its own text as
		# a tooltip. A heading has something better to say than its own name.
		item.set_tooltip_text(0, HEADING_HELP.get(row.name, row.name) if depth == 0 else row.name)

		# Colour alone tells a value apart. A box on every cell runs into its neighbours, since a
		# Tree draws its rows edge to edge with nothing between them, and a box on only some of
		# them singles out whichever row happens to be holding one.
		if not value.is_empty():
			item.set_custom_color(1, _value_color)
			item.set_tooltip_text(1, value)

		parents[depth + 1] = item
		_items.append(item)

	_resize_to_fit()


func _write_values(rows: Array[Row]) -> void:
	for i: int in mini(rows.size(), _items.size()):
		var value: String = rows[i].value
		_items[i].set_text(1, value)
		_items[i].set_tooltip_text(1, value)


# Folding a branch away has to give the space back, and the Tree will not do that on its own.
func _on_item_collapsed(_item: TreeItem) -> void:
	_resize_to_fit()


# A Tree does not grow or shrink to fit its rows, so the height is set from the rows on show. Rows
# inside something collapsed are counted out, which is what makes folding worth doing.
func _resize_to_fit() -> void:
	var root: TreeItem = get_root()
	if root == null:
		return

	var row_height: float = 0.0
	var first: TreeItem = root.get_first_child()
	if first != null:
		row_height = get_item_area_rect(first).size.y

	# Before the first layout there is no area to measure, so the font stands in until there is.
	if row_height <= 0.0:
		row_height = float(get_theme_font_size(&"font_size")) + 10.0

	custom_minimum_size.y = _showing_below(root) * row_height + _vertical_padding()


# The theme spaces a Tree off its own edges, and those are content margins, so the rows need that
# room on top of their own height or the last one ends up behind a scrollbar. Read rather than
# written down, so retuning the theme carries this with it.
func _vertical_padding() -> float:
	var box: StyleBox = get_theme_stylebox(&"panel")
	if box == null:
		return 0.0

	return box.get_content_margin(SIDE_TOP) + box.get_content_margin(SIDE_BOTTOM)


# Rows drawn under [param item], skipping anything folded away inside it.
func _showing_below(item: TreeItem) -> int:
	var count: int = 0
	var child: TreeItem = item.get_first_child()

	while child != null:
		count += 1
		if not child.collapsed:
			count += _showing_below(child)

		child = child.get_next()

	return count


func _read_dictionary(property: StringName) -> Dictionary:
	var value: Variant = _target.get(property)
	return value if value is Dictionary else {}


func _read_array(property: StringName) -> Array:
	var value: Variant = _target.get(property)
	return value if value is Array else []

#endregion

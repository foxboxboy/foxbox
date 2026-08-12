@tool
extends EditorInspectorPlugin
## An [EditorInspectorPlugin] that fills a [FoxAttributeMap]'s Runtime group with a live read-out.
##
## The read-out sits inside the group rather than at the top of the inspector, so the editor draws
## the heading above it and it matches the sections around it. The raw dictionaries stay in the same
## group underneath, and a stored object that needs opening up is in the Members list the debugger
## fills in.


## Named ReadOut because Panel is a native class and a const of that name shadows it.
const ReadOut = preload("res://addons/foxfabric/attribute_map/editor/fox_attribute_map_panel.gd")

## The property that marks an object as something this plugin can read.
const MARKER: StringName = &"runtime_flags"

## The group the read-out is dropped into. The editor builds the section for it, which is why the
## read-out carries no heading of its own.
const GROUP: String = "Runtime"

## What each published property holds. A property invented in [method Object._get_property_list] has
## no declaration behind it to document, so the inspector has nothing to say on hovering one and the
## description has to come from here.
const PROPERTY_HELP: Dictionary[String, String] = {
	"runtime_data":
		"Every key the map holds, with its value as text. A value becomes text inside the running"
		+ " game, because an object reaching the inspector is an id with nothing readable on it.",
	"runtime_groups":
		"Group name to the data keys filed under it. Keys rather than values, so overwriting a"
		+ " value leaves its grouping alone.",
	"runtime_flags":
		"Flag name to the number of stacks standing on it. A flag lifts once every stack put on it"
		+ " has been taken back off.",
	"runtime_rules":
		"Every active rule, as the id it is removed by and the data key it acts on.",
	"runtime_inherited_rules":
		"Ids of active rules that arrived from a map above rather than being added here. Removing"
		+ " one here does not take it off the map it came from.",
	"runtime_hierarchy":
		"Node path to depth, counted from this map. Below zero is a map above this one, above zero"
		+ " a map beneath it.",
}


## A read-only row carrying a description. It reports the same size the inspector's own editor would
## and leaves the contents to the read-out above it, which shows them in full.
class Description extends EditorProperty:
	var _label: Label


	func _init() -> void:
		_label = Label.new()

		# The description hangs on this rather than on the row. An EditorProperty reads its own
		# tooltip as a doc id into the editor's help system, which rejects a sentence and logs it,
		# and that path is C++ so a script cannot step in front of it. Hovering the value works;
		# hovering the name to its left is the row, and the row has nothing to say.
		_label.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_label)


	## Hands this row the text it should show on hover.
	func describe(text: String) -> void:
		_label.tooltip_text = text


	func _update_property() -> void:
		var value: Variant = get_edited_object().get(get_edited_property())
		_label.text = summarise(value)


	## The one line form the inspector gives a dictionary or an array it has not been opened.
	static func summarise(value: Variant) -> String:
		if value is Dictionary:
			var entries: Dictionary = value
			return "Dictionary (size %d)" % entries.size()

		if value is Array:
			var entries: Array = value
			return "Array (size %d)" % entries.size()

		return str(value)


func _can_handle(object: Object) -> bool:
	return publishes_runtime_state(object)


## Returns [code]true[/code] if [param object] publishes the runtime state this panel draws.
## [br][br]
## Checked by property rather than by type on purpose. Inspecting a node in a running game hands
## over a debugger stand-in, not the node, so [code]object is FoxAttributeMap[/code] would be false
## in exactly the case this panel exists for.
## [br][br]
## Static so it can be tested. The engine refuses to instantiate an EditorInspectorPlugin outside
## the editor, which puts every instance method out of reach.
static func publishes_runtime_state(object: Object) -> bool:
	if not is_instance_valid(object):
		return false

	for property: Dictionary in object.get_property_list():
		if property.get("name", "") == MARKER:
			return true

	return false


func _parse_group(object: Object, group: String) -> void:
	if group != GROUP:
		return

	add_custom_control(ReadOut.new(object))


## Every parameter is typed int rather than by its enum. The engine matches this by name and arity,
## and an annotation it does not resolve the same way leaves the override silently unused.
func _parse_property(_object: Object, _type: int, name: String, _hint_type: int,
		_hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if not PROPERTY_HELP.has(name):
		return false

	var row: Description = Description.new()
	row.describe(PROPERTY_HELP[name])
	add_property_editor(name, row)

	# Taking the default editor off the row leaves this one standing in its place.
	return true

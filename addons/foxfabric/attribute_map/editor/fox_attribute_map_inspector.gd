@tool
extends EditorInspectorPlugin
## An [EditorInspectorPlugin] that puts a live read-out above a [FoxAttributeMap]'s properties.
##
## The Runtime group carries the same state as text. A stored object that needs opening up is in
## the Members list instead, which the debugger fills in from the map's own variables.


## Named ReadOut because Panel is a native class and a const of that name shadows it.
const ReadOut = preload("res://addons/foxfabric/attribute_map/editor/fox_attribute_map_panel.gd")

## The property that marks an object as something this plugin can read.
const MARKER: StringName = &"runtime_flags"


func _can_handle(object: Object) -> bool:
	return publishes_runtime_state(object)


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


func _parse_begin(object: Object) -> void:
	add_custom_control(ReadOut.new(object))

@tool
class_name FoxFabric
extends EditorPlugin
## A lightweight, general purpose library of modular systems.
##
## Registers the editor extras that individual modules ship. Modules are meant to be deletable,
## so anything listed here is loaded only if it is still on disk.


## Gizmo plugins to register, by path. Each one lives inside the module it draws for.
const GIZMOS: Array[String] = [
	"res://addons/foxfabric/socket/3d/editor/fox_socket_3d_gizmo.gd",
	"res://addons/foxfabric/aim_gimbal/editor/fox_aim_gimbal_3d_gizmo.gd",
]

## Inspector plugins to register, by path. Same rule as the gizmos.
const INSPECTORS: Array[String] = [
	"res://addons/foxfabric/attribute_map/editor/fox_attribute_map_inspector.gd",
]

var _gizmos: Array[EditorNode3DGizmoPlugin] = []
var _inspectors: Array[EditorInspectorPlugin] = []


func _enter_tree() -> void:
	for path: String in GIZMOS:
		var gizmo: EditorNode3DGizmoPlugin = _instantiate(path) as EditorNode3DGizmoPlugin
		if gizmo == null:
			continue

		add_node_3d_gizmo_plugin(gizmo)
		_gizmos.append(gizmo)

	for path: String in INSPECTORS:
		var inspector: EditorInspectorPlugin = _instantiate(path) as EditorInspectorPlugin
		if inspector == null:
			continue

		add_inspector_plugin(inspector)
		_inspectors.append(inspector)


func _exit_tree() -> void:
	for gizmo: EditorNode3DGizmoPlugin in _gizmos:
		remove_node_3d_gizmo_plugin(gizmo)

	for inspector: EditorInspectorPlugin in _inspectors:
		remove_inspector_plugin(inspector)

	_gizmos.clear()
	_inspectors.clear()


## Returns [code]null[/code] when a module has been deleted, so the rest of the plugin still loads.
func _instantiate(path: String) -> Object:
	# Deliberately load rather than preload. preload resolves at parse time, so deleting a module
	# would stop the whole plugin from loading instead of just dropping that module's extras.
	if not ResourceLoader.exists(path):
		return null

	# Not called "script", which is a property every Object already has.
	var source: GDScript = load(path) as GDScript
	if source == null:
		push_warning("FoxFabric: could not load %s" % path)
		return null

	# Only with --verbose. Something that silently fails to register looks identical to something
	# that registered and had nothing to do, and this is the difference.
	print_verbose("FoxFabric: registered %s" % path)
	return source.new()

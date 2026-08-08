@tool
class_name FoxFabric
extends EditorPlugin
## A lightweight, general purpose library of modular systems. By tateorrtot.
##
## Registers the editor extras that individual modules ship. Modules are meant to be deletable,
## so anything listed here is loaded only if it is still on disk.


## Gizmo plugins to register, by path. Each one lives inside the module it draws for.
const GIZMOS: Array[String] = [
	"res://addons/foxfabric/socket/editor/fox_socket_3d_gizmo.gd",
	"res://addons/foxfabric/aim_gimbal/editor/fox_aim_gimbal_3d_gizmo.gd",
]

var _gizmos: Array[EditorNode3DGizmoPlugin] = []


func _enter_tree() -> void:
	for path: String in GIZMOS:
		# Deliberately load rather than preload. preload resolves at parse time, so deleting a
		# module would stop the whole plugin from loading instead of just dropping its gizmo.
		if not ResourceLoader.exists(path):
			continue

		var script: GDScript = load(path) as GDScript
		if script == null:
			push_warning("FoxFabric: could not load the gizmo at %s" % path)
			continue

		var gizmo: EditorNode3DGizmoPlugin = script.new() as EditorNode3DGizmoPlugin
		if gizmo == null:
			push_warning("FoxFabric: %s is not an EditorNode3DGizmoPlugin" % path)
			continue

		add_node_3d_gizmo_plugin(gizmo)
		_gizmos.append(gizmo)

		# Only with --verbose. A gizmo that silently fails to register looks identical to one
		# that draws nothing, and this is the difference.
		print_verbose("FoxFabric: registered gizmo %s" % path)


func _exit_tree() -> void:
	for gizmo: EditorNode3DGizmoPlugin in _gizmos:
		remove_node_3d_gizmo_plugin(gizmo)

	_gizmos.clear()

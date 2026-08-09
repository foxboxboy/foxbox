@tool
extends EditorNode3DGizmoPlugin
## Draws a [FoxSocket3D] in the 3D viewport.
##
## Shows where an attachment lands and which way it will face, and colours the socket by whether
## something is already seated in it. Lives with the socket module so deleting the module takes
## the gizmo with it.


## Half width of the marker diamond, in metres.
const SIZE: float = 0.12

## Length of the facing arrow, in metres.
const ARROW: float = 0.4

const Colors = preload("res://addons/foxfabric/core/editor/fox_gizmo_colors.gd")

const EMPTY: String = "socket_empty"
const OCCUPIED: String = "socket_occupied"

## Blue against orange rather than green against amber. The two most common forms of colour
## blindness collapse green and amber into the same yellow, and occupancy is the whole point of
## the colour. The nested diamond carries the same information without relying on it.
const COLORS: Dictionary[String, Color] = {
	EMPTY: Color(0.35, 0.70, 1.0),
	OCCUPIED: Color(1.0, 0.55, 0.1),
}

## Settings from an earlier layout, removed on load so they do not linger in the editor.
const RETIRED_SETTINGS: Array[String] = [
	"editors/3d_gizmos/gizmo_colors/fox_socket_empty",
	"editors/3d_gizmos/gizmo_colors/fox_socket_occupied",
]


func _init() -> void:
	Colors.install(self, COLORS)
	Colors.retire(RETIRED_SETTINGS)
	Colors.watch(_settings_changed)


## Picks up a recoloured gizmo without an editor restart.
func _settings_changed() -> void:
	Colors.refresh(self, COLORS)


func _get_gizmo_name() -> String:
	return "FoxSocket3D"


func _has_gizmo(node: Node3D) -> bool:
	return handles(node)


## Whether this gizmo draws for [param node].
## [br][br]
## Split out because the engine refuses to instantiate an [EditorNode3DGizmoPlugin] outside the
## editor, so the instance methods cannot be reached from a headless test.
static func handles(node: Node3D) -> bool:
	return node is FoxSocket3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var socket: FoxSocket3D = gizmo.get_node_3d() as FoxSocket3D
	if socket == null:
		return

	var key: String = OCCUPIED if is_occupied(socket) else EMPTY
	gizmo.add_lines(build_lines(socket), get_material(key, gizmo), false)


## Every line segment to draw for [param socket], in the socket's own space.
## [br][br]
## An occupied socket gets a second diamond nested inside the first, so occupancy reads from the
## shape alone. Colour says the same thing twice for anyone who can see the difference.
## [br][br]
## Split out from [code skip-lint]_redraw[/code] so the geometry can be checked without an editor gizmo to
## hand it to. Points come in pairs, one segment per pair.
static func build_lines(socket: FoxSocket3D) -> PackedVector3Array:
	var at: Transform3D = marker_transform(socket)
	var lines: PackedVector3Array = PackedVector3Array()

	for point: Vector3 in _diamond(SIZE):
		lines.append(at * point)
	for point: Vector3 in _arrow():
		lines.append(at * point)

	if is_occupied(socket):
		for point: Vector3 in _diamond(SIZE * 0.45):
			lines.append(at * point)

	return lines


## Where the attachment is placed, in the socket's own space.
## [br][br]
## [member FoxSocket3D.marker] only falls back to the socket itself in [method Node._ready],
## which returns early in the editor, so at edit time it is usually still null. A marker outside
## the socket is reported by the socket's own configuration warning, so it is ignored here rather
## than drawn somewhere misleading.
static func marker_transform(socket: FoxSocket3D) -> Transform3D:
	var marker: Node3D = socket.marker
	if marker == null or marker == socket or not socket.is_ancestor_of(marker):
		return Transform3D.IDENTITY

	return socket.global_transform.affine_inverse() * marker.global_transform


## Whether something is already seated in [param socket].
## [br][br]
## [member FoxSocket3D.attachment] is only filled in at runtime and gizmos draw at edit time, so
## this goes by the children instead. The marker is not an attachment, and neither is whatever
## the marker is nested under.
static func is_occupied(socket: FoxSocket3D) -> bool:
	var marker: Node3D = socket.marker

	for child: Node in socket.get_children():
		if child is not Node3D:
			continue
		if marker != null and (child == marker or child.is_ancestor_of(marker)):
			continue
		return true

	return false


## The twelve edges of an octahedron of half width [param size], as line pairs.
static func _diamond(size: float) -> Array[Vector3]:
	var x: Vector3 = Vector3(size, 0.0, 0.0)
	var y: Vector3 = Vector3(0.0, size, 0.0)
	var z: Vector3 = Vector3(0.0, 0.0, size)
	var points: Array[Vector3] = []

	for a: Vector3 in [x, -x]:
		for b: Vector3 in [y, -y, z, -z]:
			points.append(a)
			points.append(b)

	for b: Vector3 in [y, -y]:
		for c: Vector3 in [z, -z]:
			points.append(b)
			points.append(c)

	return points


## A shaft down local -Z with four barbs, so the facing reads from any angle.
static func _arrow() -> Array[Vector3]:
	var tip: Vector3 = Vector3(0.0, 0.0, -ARROW)
	var barb: float = SIZE * 0.6
	var points: Array[Vector3] = [Vector3.ZERO, tip]

	for offset: Vector3 in [
		Vector3(barb, 0.0, barb),
		Vector3(-barb, 0.0, barb),
		Vector3(0.0, barb, barb),
		Vector3(0.0, -barb, barb),
	]:
		points.append(tip)
		points.append(tip + offset)

	return points

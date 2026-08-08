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

const EMPTY: String = "fox_socket_empty"
const OCCUPIED: String = "fox_socket_occupied"


func _init() -> void:
	create_material(EMPTY, Color(0.35, 0.85, 0.55))
	create_material(OCCUPIED, Color(1.0, 0.65, 0.2))


func _get_gizmo_name() -> String:
	return "FoxSocket3D"


func _has_gizmo(node: Node3D) -> bool:
	return node is FoxSocket3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var socket: FoxSocket3D = gizmo.get_node_3d() as FoxSocket3D
	if socket == null:
		return

	var at: Transform3D = marker_transform(socket)
	var lines: PackedVector3Array = PackedVector3Array()

	for point: Vector3 in _diamond():
		lines.append(at * point)
	for point: Vector3 in _arrow():
		lines.append(at * point)

	var key: String = OCCUPIED if is_occupied(socket) else EMPTY
	gizmo.add_lines(lines, get_material(key, gizmo), false)


## Where the attachment will actually be placed, in the socket's own space.
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


## The twelve edges of an octahedron, as line pairs.
static func _diamond() -> Array[Vector3]:
	var x: Vector3 = Vector3(SIZE, 0.0, 0.0)
	var y: Vector3 = Vector3(0.0, SIZE, 0.0)
	var z: Vector3 = Vector3(0.0, 0.0, SIZE)
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

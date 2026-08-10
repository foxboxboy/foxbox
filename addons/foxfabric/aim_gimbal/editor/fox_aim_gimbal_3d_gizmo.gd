@tool
extends EditorNode3DGizmoPlugin
## A gizmo drawing the clamp range of a [FoxAimGimbal3D] in the 3D viewport.
##
## Pitch and yaw limits are numbers in the inspector with nothing to look at, so an inverted or
## far too narrow range is invisible until something moves wrong at runtime. Each clamped axis
## gets an arc from its minimum to its maximum, with a spoke at each end.
## [br][br]
## An axis that is not clamped wraps freely and has no range to draw, so nothing is drawn for it.
## [br][br]
## The two arcs lie in different planes, one horizontal and one vertical, so they stay
## distinguishable without relying on their colours.


const Colors = preload("res://addons/foxfabric/core/editor/fox_gizmo_colors.gd")

## Radius of the drawn arcs, in metres.
const RADIUS: float = 0.6

## Segments per arc. Enough that a full sweep does not look faceted.
const SEGMENTS: int = 32

const PITCH: String = "aim_gimbal_pitch"
const YAW: String = "aim_gimbal_yaw"

const COLORS: Dictionary[String, Color] = {
	PITCH: Color(0.35, 0.70, 1.0),
	YAW: Color(1.0, 0.55, 0.1),
}


func _init() -> void:
	Colors.install(self, COLORS)
	Colors.watch(_settings_changed)


func _settings_changed() -> void:
	Colors.refresh(self, COLORS)


func _get_gizmo_name() -> String:
	return "FoxAimGimbal3D"


func _has_gizmo(node: Node3D) -> bool:
	return handles(node)


## Whether this gizmo draws for [param node].
## [br][br]
## Split out because the engine refuses to instantiate an [EditorNode3DGizmoPlugin] outside the
## editor, so the instance methods cannot be reached from a headless test.
static func handles(node: Node3D) -> bool:
	return node is FoxAimGimbal3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	var gimbal: FoxAimGimbal3D = gizmo.get_node_3d() as FoxAimGimbal3D
	if gimbal == null:
		return

	if gimbal.clamp_pitch:
		gizmo.add_lines(build_pitch_arc(gimbal), get_material(PITCH, gizmo), false)

	if gimbal.clamp_yaw:
		gizmo.add_lines(build_yaw_arc(gimbal), get_material(YAW, gizmo), false)


## The sweep between the pitch limits, in the vertical plane the gimbal currently faces.
static func build_pitch_arc(gimbal: FoxAimGimbal3D) -> PackedVector3Array:
	var facing: float = gimbal.rotation.y
	var points: Array[Vector3] = []

	for i: int in SEGMENTS + 1:
		var angle: float = lerpf(
			deg_to_rad(gimbal.min_pitch_deg), deg_to_rad(gimbal.max_pitch_deg),
			float(i) / float(SEGMENTS))
		points.append(_pitch_point(angle, facing))

	return _sweep(points, undo_rotation(gimbal))


## The sweep between the yaw limits, in the parent's horizontal plane.
static func build_yaw_arc(gimbal: FoxAimGimbal3D) -> PackedVector3Array:
	var points: Array[Vector3] = []

	for i: int in SEGMENTS + 1:
		var angle: float = lerpf(
			deg_to_rad(gimbal.min_yaw_deg), deg_to_rad(gimbal.max_yaw_deg),
			float(i) / float(SEGMENTS))
		points.append(_yaw_point(angle))

	return _sweep(points, undo_rotation(gimbal))


## The gimbal's own rotation, inverted.
## [br][br]
## A gizmo draws in the node's local space, but a clamp range is measured against the parent.
## Without undoing the rotation the arc would swing around with the aim, which is the one thing
## it must not do: the whole point is a fixed range the aim moves inside.
static func undo_rotation(gimbal: FoxAimGimbal3D) -> Basis:
	return gimbal.transform.basis.orthonormalized().inverse()


## A point on the yaw sweep. Yaw zero faces local -Z, matching [method FoxAimGimbal3D.aim_at_position].
static func _yaw_point(angle: float) -> Vector3:
	return Vector3(-sin(angle), 0.0, -cos(angle)) * RADIUS


## A point on the pitch sweep, lifted out of the horizontal plane at [param facing].
## Positive pitch aims up.
static func _pitch_point(angle: float, facing: float) -> Vector3:
	var flat: Vector3 = Vector3(-sin(facing), 0.0, -cos(facing))
	return (flat * cos(angle) + Vector3.UP * sin(angle)) * RADIUS


## Joins [param points] into line segments and adds a spoke to each end, so the limits read as
## limits rather than as the ends of a stray curve. [param undo] converts into local space.
static func _sweep(points: Array[Vector3], undo: Basis) -> PackedVector3Array:
	var lines: PackedVector3Array = PackedVector3Array()

	for i: int in points.size() - 1:
		lines.append(undo * points[i])
		lines.append(undo * points[i + 1])

	lines.append(Vector3.ZERO)
	lines.append(undo * points[0])
	lines.append(Vector3.ZERO)
	lines.append(undo * points[points.size() - 1])

	return lines

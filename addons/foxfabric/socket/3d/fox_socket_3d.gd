@tool
@icon("uid://b1yqa4yj5tra0")
class_name FoxSocket3D
extends Marker3D
## A physical 3D location that reparents and holds a single attachment.
##
## Attaching reparents the node under the socket and snaps its transform to [member marker], so
## the socket owns whatever is plugged into it.
## [codeblock]
## var hand := $Model/RightHand as FoxSocket3D
## hand.attach(sword)
##
## # detach() unplugs the socket but leaves the node parented here.
## var dropped := hand.detach()
## dropped.reparent(get_tree().current_scene)
## [/codeblock]
## The socket watches its own children, so an attachment freed or reparented by something else
## still clears the slot and emits [signal detached].




#region Signals

## Emitted when this socket gains a new attachment.
signal attached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when the attachment leaves and is no longer a child.
signal detached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when the child order changes, useful for detecting deleted attachments.
signal attachment_changed(attachment: Node3D, socket: FoxSocket3D)

#endregion




#region Variables

## (Optional) The node that will be used for position, rotation, and scale.
## Leave blank to use this [Marker3D]'s transform.
@export var marker: Node3D:
	set(value):
		marker = value
		update_configuration_warnings()
		update_gizmos()

@export_group("Snap Settings")

## If [code]true[/code], the attachment's global position snaps to the socket's marker.
@export var snap_position: bool = true

## If [code]true[/code], the attachment's global rotation snaps to the socket's marker.
@export var snap_rotation: bool = true

## If [code]true[/code], the attachment forcefully scales to match the socket marker's global scale.
@export var snap_scale: bool = false

## The child node currently plugged into this socket.
var attachment: Node3D = null

#endregion




#region Public API

## Returns [code]true[/code] if there is no current attachment.
func is_empty() -> bool:
	return attachment == null


## Returns the current attachment node, or [code]null[/code] if empty.
func get_attachment() -> Node3D:
	return attachment


## Reparents [param new_attachment] to this socket and snaps its transform to [member marker].
func attach(new_attachment: Node3D) -> void:
	if not is_empty():
		push_error("FoxSocket3D: Attempted to attach '%s', but socket '%s' already has an attachment!" % [new_attachment.name, get_path()])
		return

	attachment = new_attachment
	new_attachment.reparent(self)

	if snap_position:
		new_attachment.global_position = marker.global_position

	if snap_rotation:
		new_attachment.global_rotation = marker.global_rotation

	if snap_scale:
		var target_scale = marker.global_transform.basis.get_scale()
		# We orthonormalize first to clear any existing scale/shear, then apply the new scale
		new_attachment.global_transform.basis = new_attachment.global_transform.basis.orthonormalized().scaled(target_scale)

	attached.emit(new_attachment, self)


## Safely unplugs the attachment from the socket and returns it.
## [br][b]Note:[/b] This does not reparent the attachment anywhere else in the scene tree.
func detach() -> Node3D:
	if is_empty():
		return null

	var detached_node = attachment
	attachment = null
	detached.emit(detached_node, self)

	return detached_node

#endregion




#region Private

func _ready() -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		# The gizmo draws occupancy, which is a question about the children, so it has to be
		# redrawn when they change. Without this it stays stale until the socket is reselected.
		child_order_changed.connect(update_gizmos)
		return

	child_order_changed.connect(_attachment_changed)

	if marker == null:
		marker = self


func _attachment_changed() -> void:
	attachment_changed.emit(attachment, self)

	if not is_instance_valid(attachment) or attachment.get_parent() != self:
		if is_instance_valid(attachment):
			detached.emit(attachment, self)
		attachment = null

#endregion




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if marker != null and marker != self and not is_ancestor_of(marker):
		warnings.append("Marker is not this socket or one of its descendants, so attachments "
			+ "will snap to a transform outside this socket.")

	return warnings

#endregion

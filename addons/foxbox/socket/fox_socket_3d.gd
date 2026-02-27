class_name FoxSocket3D
extends Marker3D
## A physical 3D location that reparents and holds a single attachment.





#region Signals

## Emitted when this socket gains a new attachment.
signal attached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when the attachment leaves and is no longer a child.
signal detached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when the child order changes.
signal attachment_changed(attachment: Node3D, socket: FoxSocket3D)

#endregion





#region Variables

## (Optional) The node that will be used for position and rotation. 
## Leave blank to use this [Marker3D]'s transform.
@export var marker: Node3D

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
	
	new_attachment.global_position = marker.global_position
	new_attachment.global_rotation = marker.global_rotation
	
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





#region Private Logic

func _ready() -> void:
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

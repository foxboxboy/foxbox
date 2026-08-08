@icon("uid://dn15lpwie55n8")
class_name FoxSocket2D
extends Marker2D
## A physical 2D location that reparents and holds a single attachment.




#region Signals

## Emitted when this socket gains a new attachment.
signal attached(attachment: Node2D, socket: FoxSocket2D)

## Emitted when the attachment leaves and is no longer a child.
signal detached(attachment: Node2D, socket: FoxSocket2D)

## Emitted when the child order changes, useful for detecting deleted attachments.
signal attachment_changed(attachment: Node2D, socket: FoxSocket2D)

#endregion




#region Variables

## (Optional) The node that will be used for position, rotation, and scale. 
## Leave blank to use this [Marker2D]'s transform.
@export var marker: Node2D

@export_group("Snap Settings")

## If [code]true[/code], the attachment's global position snaps to the socket's marker.
@export var snap_position: bool = true

## If [code]true[/code], the attachment's global rotation snaps to the socket's marker.
@export var snap_rotation: bool = true

## If [code]true[/code], the attachment forcefully scales to match the socket marker's global scale.
@export var snap_scale: bool = false


## The child node currently plugged into this socket.
var attachment: Node2D = null

#endregion




#region Public API

## Returns [code]true[/code] if there is no current attachment.
func is_empty() -> bool:
	return attachment == null


## Returns the current attachment node, or [code]null[/code] if empty.
func get_attachment() -> Node2D:
	return attachment


## Reparents [param new_attachment] to this socket and snaps its transform to [member marker].
func attach(new_attachment: Node2D) -> void:
	if not is_empty():
		push_error("FoxSocket2D: Attempted to attach '%s', but socket '%s' already has an attachment!" % [new_attachment.name, get_path()])
		return
	
	attachment = new_attachment
	new_attachment.reparent(self)
	
	if snap_position:
		new_attachment.global_position = marker.global_position
		
	if snap_rotation:
		new_attachment.global_rotation = marker.global_rotation
		
	if snap_scale:
		new_attachment.global_scale = marker.global_scale
		
	attached.emit(new_attachment, self)


## Safely unplugs the attachment from the socket and returns it.
## [br][b]Note:[/b] This does not reparent the attachment anywhere else in the scene tree.
func detach() -> Node2D:
	if is_empty(): 
		return null
		
	var detached_node = attachment
	attachment = null
	detached.emit(detached_node, self)
	
	return detached_node

#endregion




#region Private

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

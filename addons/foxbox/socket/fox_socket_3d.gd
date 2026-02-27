extends Marker3D
class_name FoxSocket3D
## A physical 3D location that reparents and holds a single attachment.

## Emitted when this FoxSocket3D gains a new attachment.
signal attached(attachment: Node3D, socket: FoxSocket3D)
## Emitted when the attachment leaves and is no longer a child.
signal detached(attachment: Node3D, socket: FoxSocket3D)
## Emitted when the child order changes.
signal attachment_changed(attachment: Node3D, socket: FoxSocket3D)

## (Optional) The node that will be used for position
## and rotation. Leave blank to make this the marker. 
@export var marker: Node3D

## The child node currently plugged into this socket.
var attachment: Node3D = null


func _ready() -> void:
	child_order_changed.connect(_attachment_changed)
	
	if marker == null:
		marker = self


## Returns true if there is no attachment. 
func is_empty() -> bool:
	return attachment == null


## Returns the current attachment.
func get_attachment() -> Node3D:
	return attachment


## Reparents a node to plug into this socket and snaps its transform.
func attach(new_attachment: Node3D) -> void:
	if not is_empty():
		push_error("ERROR: FoxSocket3D already has an attachment! ", new_attachment, " ", get_path())
		return
	
	attachment = new_attachment
	new_attachment.reparent(self)
	
	new_attachment.global_position = marker.global_position
	new_attachment.global_rotation = marker.global_rotation
	
	attached.emit(new_attachment, self)


## Safely unplugs the attachment from the socket. Returns the attachment.
## Note this does not reparent the attachment anywhere.
func detach() -> Node3D:
	if is_empty(): 
		return null
		
	var detached_node = attachment
	attachment = null
	detached.emit(detached_node, self)
	
	return detached_node


func _attachment_changed():
	attachment_changed.emit(attachment, self)
	
	if not is_instance_valid(attachment) or attachment.get_parent() != self:
		if is_instance_valid(attachment):
			detached.emit(attachment, self)
		attachment = null

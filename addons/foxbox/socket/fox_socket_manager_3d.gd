@icon("uid://gn5af2lswkru")
class_name FoxSocketManager3D
extends FoxNode3D
## Manages a collection of [FoxSocket3D] nodes.

#region Signals

## Emitted when a node successfully attaches to any managed socket.
signal node_attached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when a node detaches from any managed socket.
signal node_detached(attachment: Node3D, socket: FoxSocket3D)

#endregion

#region Variables

## A collection of all sockets managed by this component.
var sockets: Array[FoxSocket3D] = []

#endregion

#region Public API

## Returns the total number of managed sockets that currently have no attachment.
func get_available_socket_count() -> int:
	var count: int = 0
	for socket in sockets:
		if socket.is_empty():
			count += 1
	return count


## Attempts to plug [param node] into the first available empty socket.
## Returns [code]true[/code] if successful, or [code]false[/code] if all sockets are full.
func try_attach(node: Node3D) -> bool:
	for socket in sockets:
		if socket.is_empty():
			socket.attach(node)
			return true
			
	return false

#endregion

#region Private Logic

func _ready() -> void:
	# Recursively find all sockets in the tree beneath this manager
	for child in find_children("*", "FoxSocket3D", true, false):
		var socket = child as FoxSocket3D
		if socket:
			sockets.append(socket)
			# Route all socket signals up through the manager
			socket.attached.connect(_on_socket_attached)
			socket.detached.connect(_on_socket_detached)


func _on_socket_attached(attachment: Node3D, socket: FoxSocket3D) -> void:
	node_attached.emit(attachment, socket)


func _on_socket_detached(attachment: Node3D, socket: FoxSocket3D) -> void:
	node_detached.emit(attachment, socket)

#endregion

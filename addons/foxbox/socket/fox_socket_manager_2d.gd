class_name FoxSocketManager2D
extends FoxNode2D
## Manages a collection of [FoxSocket2D] nodes.





#region Signals

## Emitted when a node successfully attaches to any managed socket.
signal node_attached(attachment: Node2D, socket: FoxSocket2D)

## Emitted when a node detaches from any managed socket.
signal node_detached(attachment: Node2D, socket: FoxSocket2D)

#endregion





#region Variables

## A collection of all sockets managed by this component.
var sockets: Array[FoxSocket2D] = []

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
func try_attach(node: Node2D) -> bool:
	for socket in sockets:
		if socket.is_empty():
			socket.attach(node)
			node_attached.emit(node, socket)
			return true
			
	return false

#endregion





#region Private Logic

func _ready() -> void:
	# Recursively find all sockets in the tree beneath this manager
	for child in find_children("*", "FoxSocket2D", true, false):
		sockets.append(child)
		child.detached.connect(_on_socket_detached)


func _on_socket_detached(attachment: Node2D, socket: FoxSocket2D) -> void:
	node_detached.emit(attachment, socket)

#endregion

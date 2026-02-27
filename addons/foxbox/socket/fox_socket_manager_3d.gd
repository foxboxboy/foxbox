extends FoxNode3D
class_name FoxSocketManager3D
## Manages a collection of FoxSocket3D nodes.

signal node_attached(attachment: Node3D, socket: FoxSocket3D)
signal node_detached(attachment: Node3D, socket: FoxSocket3D)

var sockets: Array[FoxSocket3D] = []

	
func _ready() -> void:
	# Recursively find all sockets
	for child in find_children("*", "FoxSocket3D", true, false):
		sockets.append(child)
		child.detached.connect(_on_socket_detached)


## Returns how many sockets are currently empty.
func get_available_socket_count() -> int:
	var count: int = 0
	for socket in sockets:
		if socket.is_empty():
			count += 1
	return count


## Attempts to plug a node into the first available empty socket.
## Returns true if successful, false if all sockets are full.
func try_attach(node: Node3D) -> bool:
	for socket in sockets:
		if socket.is_empty():
			socket.attach(node)
			node_attached.emit(node, socket)
			return true
			
	return false


func _on_socket_detached(attachment: Node3D, socket: FoxSocket3D) -> void:
	node_detached.emit(attachment, socket)

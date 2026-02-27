extends FoxNode2D
class_name FoxSocketManager2D
## Manages a collection of FoxSocket2D nodes.

signal node_attached(attachment: Node2D, socket: FoxSocket2D)
signal node_detached(attachment: Node2D, socket: FoxSocket2D)

var sockets: Array[FoxSocket2D] = []


func _ready() -> void:
	# Recursively find all sockets
	for child in find_children("*", "FoxSocket2D", true, false):
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
func try_attach(node: Node2D) -> bool:
	for socket in sockets:
		if socket.is_empty():
			socket.attach(node)
			node_attached.emit(node, socket)
			return true
			
	return false


func _on_socket_detached(attachment: Node2D, socket: FoxSocket2D) -> void:
	node_detached.emit(attachment, socket)

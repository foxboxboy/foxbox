@icon("uid://gn5af2lswkru")
class_name FoxSocketMap2D
extends FoxNode2D
## Manages a collection of [FoxSocket2D] nodes, mapped by their node names.




#region Signals

## Emitted when a node successfully attaches to any managed socket.
signal node_attached(attachment: Node2D, socket: FoxSocket2D)

## Emitted when a node detaches from any managed socket.
signal node_detached(attachment: Node2D, socket: FoxSocket2D)

#endregion




#region Variables

## A dictionary mapping socket names (StringName) to their [FoxSocket2D] nodes.
var sockets: Dictionary[StringName, FoxSocket2D] = {}

#endregion




#region Public API

## Returns the total number of managed sockets that currently have no attachment.
func get_available_socket_count() -> int:
	var count: int = 0
	for socket: FoxSocket2D in sockets.values():
		if socket.is_empty():
			count += 1
	return count


## Plugs [param node] into a socket. If [param target_socket] is specified, it targets that 
## exact socket. If left empty, it will auto-attach to the first available empty socket.
## Returns [code]true[/code] on success.
func attach(node: Node2D, target_socket: StringName = &"") -> bool:
	# A specific socket was named
	if target_socket != &"":
		var socket: FoxSocket2D = sockets.get(target_socket)
		if socket and socket.is_empty():
			socket.attach(node)
			return true
		return false
	
	# No socket named, take the first empty one
	for socket: FoxSocket2D in sockets.values():
		if socket.is_empty():
			socket.attach(node)
			return true
			
	return false


## Safely retrieves a socket by name, returning null if it doesn't exist.
func get_socket(socket_name: StringName) -> FoxSocket2D:
	return sockets.get(socket_name)

#endregion




#region Private

func _ready() -> void:
	# Recursively find all sockets in the tree beneath this manager
	for child in find_children("*", "FoxSocket2D", true, false):
		var socket = child as FoxSocket2D
		if socket:
			# Update sockets Dictionary
			sockets[StringName(socket.name)] = socket
			
			# Connect signals
			socket.attached.connect(_on_socket_attached)
			socket.detached.connect(_on_socket_detached)


func _on_socket_attached(attachment: Node2D, socket: FoxSocket2D) -> void:
	node_attached.emit(attachment, socket)


func _on_socket_detached(attachment: Node2D, socket: FoxSocket2D) -> void:
	node_detached.emit(attachment, socket)

#endregion

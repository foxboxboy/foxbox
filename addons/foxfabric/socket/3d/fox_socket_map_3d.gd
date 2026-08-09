@tool
@icon("uid://gn5af2lswkru")
class_name FoxSocketMap3D
extends FoxNode3D
## A collection of [FoxSocket3D] nodes, keyed by node name.
##
## Sockets are collected recursively from everything beneath this node when it enters the tree.
## [codeblock]
## var seats: FoxSocketMap3D = $Vehicle/Seats
##
## # Take any free seat, or name one explicitly.
## if seats.attach(player):
##     player.set_physics_process(false)
## seats.attach(player, &"DriverSeat")
##
## # Getting back out. detach() unplugs but does NOT reparent,
## # so the node is left where it is until you move it yourself.
## var rider: Node3D = seats.get_socket(&"DriverSeat").detach()
## rider.reparent(get_tree().current_scene)
## [/codeblock]




#region Signals

## Emitted when a node successfully attaches to any managed socket.
signal node_attached(attachment: Node3D, socket: FoxSocket3D)

## Emitted when a node detaches from any managed socket.
signal node_detached(attachment: Node3D, socket: FoxSocket3D)

#endregion




#region Variables

## A dictionary mapping socket names (StringName) to their [FoxSocket3D] nodes.
var sockets: Dictionary[StringName, FoxSocket3D] = {}

#endregion




#region Public API

## Returns the total number of managed sockets that currently have no attachment.
func get_available_socket_count() -> int:
	var count: int = 0
	for socket: FoxSocket3D in sockets.values():
		if socket.is_empty():
			count += 1
	return count


## Plugs [param node] into a socket. If [param target_socket] is specified, it targets that
## exact socket. If left empty, it will auto-attach to the first available empty socket.
## Returns [code]true[/code] on success.
func attach(node: Node3D, target_socket: StringName = &"") -> bool:
	# A specific socket was named
	if target_socket != &"":
		var socket: FoxSocket3D = sockets.get(target_socket)
		if socket and socket.is_empty():
			socket.attach(node)
			return true
		return false

	# No socket named, take the first empty one
	for socket: FoxSocket3D in sockets.values():
		if socket.is_empty():
			socket.attach(node)
			return true

	return false


## Safely retrieves a socket by name, returning null if it doesn't exist.
func get_socket(socket_name: StringName) -> FoxSocket3D:
	return sockets.get(socket_name)

#endregion




#region Private

func _ready() -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		# The warnings are questions about the sockets underneath, so they go stale when one
		# comes or goes. This only catches direct children. Sockets are collected recursively,
		# so a socket buried deeper still needs the map reselecting to refresh.
		child_order_changed.connect(update_configuration_warnings)
		return

	# Recursively find all sockets in the tree beneath this manager
	for child in find_children("*", "FoxSocket3D", true, false):
		var socket = child as FoxSocket3D
		if socket:
			# Update sockets Dictionary
			sockets[StringName(socket.name)] = socket

			# Connect signals
			socket.attached.connect(_on_socket_attached)
			socket.detached.connect(_on_socket_detached)


func _on_socket_attached(attachment: Node3D, socket: FoxSocket3D) -> void:
	node_attached.emit(attachment, socket)


func _on_socket_detached(attachment: Node3D, socket: FoxSocket3D) -> void:
	node_detached.emit(attachment, socket)

#endregion




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	var found: Array[Node] = find_children("*", "FoxSocket3D", true, false)

	if found.is_empty():
		warnings.append("No FoxSocket3D beneath this node, so this map manages nothing.")
		return warnings

	var names: Array[StringName] = []
	for socket: Node in found:
		var key: StringName = StringName(socket.name)
		if names.has(key):
			warnings.append("Two sockets are named '%s'. One will overwrite the other." % key)
		else:
			names.append(key)

	return warnings

#endregion

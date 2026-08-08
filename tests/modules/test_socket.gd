extends "res://tests/fox_test.gd"


func run() -> void:
	suite = "socket"
	_empty_socket()
	_attaching_reparents()
	_detach_does_not_reparent()
	_occupied_sockets_refuse()
	_snapping()
	_map_attaches_by_name()
	_map_auto_attaches()
	_map_reports_availability()
	_map_forwards_signals()


func _socket(parent: Node) -> FoxSocket3D:
	var s: FoxSocket3D = FoxSocket3D.new()
	parent.add_child(s)
	return s


func _empty_socket() -> void:
	case("empty socket")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var s: FoxSocket3D = _socket(holder)

	check(s.is_empty(), "a new socket is empty")
	eq(s.get_attachment(), null, "and has no attachment")
	eq(s.marker, s, "marker defaults to the socket itself")


func _attaching_reparents() -> void:
	case("attaching")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var s: FoxSocket3D = _socket(holder)
	var item: Node3D = Node3D.new()
	holder.add_child(item)

	var got: Array = []
	s.attached.connect(func(a: Node3D, _sock: FoxSocket3D) -> void: got.append(a))

	s.attach(item)
	check(not s.is_empty(), "the socket is no longer empty")
	eq(s.get_attachment(), item, "the attachment is recorded")
	eq(item.get_parent(), s, "the item was reparented under the socket")
	eq(got.size(), 1, "the attached signal fired")
	eq(got[0], item, "carrying the attachment")


## The docs promise detach() unplugs without moving the node anywhere.
func _detach_does_not_reparent() -> void:
	case("detaching")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var s: FoxSocket3D = _socket(holder)
	var item: Node3D = Node3D.new()
	holder.add_child(item)
	s.attach(item)

	var got: Array = []
	s.detached.connect(func(a: Node3D, _sock: FoxSocket3D) -> void: got.append(a))

	var out: Node3D = s.detach()
	eq(out, item, "detach returns the node it released")
	check(s.is_empty(), "the socket is empty again")
	eq(item.get_parent(), s, "the node is deliberately left parented to the socket")
	eq(got.size(), 1, "the detached signal fired")

	eq(s.detach(), null, "detaching an empty socket returns null")
	eq(got.size(), 1, "and emits nothing")


func _occupied_sockets_refuse() -> void:
	case("occupied socket")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var s: FoxSocket3D = _socket(holder)
	var first: Node3D = Node3D.new()
	var second: Node3D = Node3D.new()
	holder.add_child(first)
	holder.add_child(second)

	s.attach(first)
	# emits an error by design
	s.attach(second)
	eq(s.get_attachment(), first, "the original attachment is kept")
	eq(second.get_parent(), holder, "the rejected node was not reparented")


func _snapping() -> void:
	case("snap settings")
	var holder: Node3D = track(Node3D.new()) as Node3D
	var s: FoxSocket3D = _socket(holder)
	s.global_position = Vector3(10, 5, 0)

	var item: Node3D = Node3D.new()
	holder.add_child(item)
	item.global_position = Vector3(-3, -3, -3)

	s.attach(item)
	check(item.global_position.is_equal_approx(Vector3(10, 5, 0)), "position snapped to the socket")

	case("snapping disabled")
	var s2: FoxSocket3D = _socket(holder)
	s2.global_position = Vector3(20, 0, 0)
	s2.snap_position = false
	var item2: Node3D = Node3D.new()
	holder.add_child(item2)
	item2.global_position = Vector3(1, 1, 1)
	s2.attach(item2)
	check(item2.global_position.is_equal_approx(Vector3(1, 1, 1)), "position left alone when snapping is off")


func _build_map(socket_names: Array) -> Array:
	var map: FoxSocketMap3D = FoxSocketMap3D.new()
	var sockets: Array = []
	for n in socket_names:
		var s: FoxSocket3D = FoxSocket3D.new()
		s.name = n
		map.add_child(s)
		sockets.append(s)
	track(map)
	return [map, sockets]


func _map_attaches_by_name() -> void:
	case("map attach by name")
	var built: Array = _build_map(["DriverSeat", "PassengerSeat"])
	var map: FoxSocketMap3D = built[0]
	var sockets: Array = built[1]

	eq(map.sockets.size(), 2, "both sockets were collected")
	eq(map.get_socket(&"DriverSeat"), sockets[0], "lookup by name works")
	eq(map.get_socket(&"Nope"), null, "unknown name returns null")

	var rider: Node3D = Node3D.new()
	map.add_child(rider)

	check(map.attach(rider, &"DriverSeat"), "attaching to a named socket succeeds")
	eq(sockets[0].get_attachment(), rider, "the named socket holds the rider")
	check(sockets[1].is_empty(), "the other socket is untouched")

	var second: Node3D = Node3D.new()
	map.add_child(second)
	check(not map.attach(second, &"DriverSeat"), "attaching to an occupied named socket fails")
	check(not map.attach(second, &"Nope"), "attaching to an unknown socket fails")


func _map_auto_attaches() -> void:
	case("map auto attach")
	var built: Array = _build_map(["A", "B"])
	var map: FoxSocketMap3D = built[0]
	var sockets: Array = built[1]

	var one: Node3D = Node3D.new()
	var two: Node3D = Node3D.new()
	var three: Node3D = Node3D.new()
	map.add_child(one)
	map.add_child(two)
	map.add_child(three)

	check(map.attach(one), "first auto attach succeeds")
	check(map.attach(two), "second auto attach succeeds")
	check(not map.attach(three), "a third fails once every socket is full")

	check(not sockets[0].is_empty(), "socket A filled")
	check(not sockets[1].is_empty(), "socket B filled")
	eq(three.get_parent(), map, "the rejected node stayed put")


func _map_reports_availability() -> void:
	case("availability")
	var built: Array = _build_map(["A", "B", "C"])
	var map: FoxSocketMap3D = built[0]

	eq(map.get_available_socket_count(), 3, "all sockets start free")

	var item: Node3D = Node3D.new()
	map.add_child(item)
	map.attach(item)
	eq(map.get_available_socket_count(), 2, "attaching consumes one")

	map.get_socket(&"A").detach()
	eq(map.get_available_socket_count(), 3, "detaching frees it again")


func _map_forwards_signals() -> void:
	case("signal forwarding")
	var built: Array = _build_map(["A"])
	var map: FoxSocketMap3D = built[0]

	var attached: Array = []
	var detached: Array = []
	map.node_attached.connect(func(a: Node3D, _s: FoxSocket3D) -> void: attached.append(a))
	map.node_detached.connect(func(a: Node3D, _s: FoxSocket3D) -> void: detached.append(a))

	var item: Node3D = Node3D.new()
	map.add_child(item)
	map.attach(item)
	eq(attached.size(), 1, "the map re-emitted the socket's attached signal")

	map.get_socket(&"A").detach()
	eq(detached.size(), 1, "and the detached signal")

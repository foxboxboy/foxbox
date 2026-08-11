extends FoxTest
## The 2D half of the socket module.
##
## Mirrors test_socket.gd. This code predates the 2D ports and had never been covered at all,
## while its 3D twin had a full suite, so the two had quietly drifted apart in confidence if not
## in behaviour.
## [br][br]
## There is no gizmo section. Only [FoxSocket3D] has one, since the 3D viewport is where a
## marker's orientation is hard to read off the inspector.


func run() -> void:
	suite = "socket_2d"
	_empty_socket()
	_attaching_reparents()
	_detach_does_not_reparent()
	_occupied_sockets_refuse()
	_snapping()
	_map_attaches_by_name()
	_map_auto_attaches()
	_map_reports_availability()
	_map_forwards_signals()


func _socket(parent: Node) -> FoxSocket2D:
	var s: FoxSocket2D = FoxSocket2D.new()
	parent.add_child(s)
	return s


func _empty_socket() -> void:
	start_case("empty socket")
	var holder: Node2D = track(Node2D.new()) as Node2D
	var s: FoxSocket2D = _socket(holder)

	check(s.is_empty(), "a new socket is empty")
	check_equal(s.get_attachment(), null, "and has no attachment")
	check_equal(s.marker, s, "marker defaults to the socket itself")


func _attaching_reparents() -> void:
	start_case("attaching")
	var holder: Node2D = track(Node2D.new()) as Node2D
	var s: FoxSocket2D = _socket(holder)
	var item: Node2D = Node2D.new()
	holder.add_child(item)

	var got: Array = []
	s.attached.connect(func(a: Node2D, _sock: FoxSocket2D) -> void: got.append(a))

	s.attach(item)
	check(not s.is_empty(), "the socket is no longer empty")
	check_equal(s.get_attachment(), item, "the attachment is recorded")
	check_equal(item.get_parent(), s, "the item was reparented under the socket")
	check_equal(got.size(), 1, "the attached signal fired")
	check_equal(got[0], item, "carrying the attachment")


## The docs promise detach() unplugs without moving the node anywhere.
func _detach_does_not_reparent() -> void:
	start_case("detaching")
	var holder: Node2D = track(Node2D.new()) as Node2D
	var s: FoxSocket2D = _socket(holder)
	var item: Node2D = Node2D.new()
	holder.add_child(item)
	s.attach(item)

	var got: Array = []
	s.detached.connect(func(a: Node2D, _sock: FoxSocket2D) -> void: got.append(a))

	var out: Node2D = s.detach()
	check_equal(out, item, "detach returns the node it released")
	check(s.is_empty(), "the socket is empty again")
	check_equal(item.get_parent(), s, "the node is deliberately left parented to the socket")
	check_equal(got.size(), 1, "the detached signal fired")

	check_equal(s.detach(), null, "detaching an empty socket returns null")
	check_equal(got.size(), 1, "and emits nothing")


func _occupied_sockets_refuse() -> void:
	start_case("occupied socket")
	var holder: Node2D = track(Node2D.new()) as Node2D
	var s: FoxSocket2D = _socket(holder)
	var first: Node2D = Node2D.new()
	var second: Node2D = Node2D.new()
	holder.add_child(first)
	holder.add_child(second)

	s.attach(first)
	# emits an error by design
	s.attach(second)
	check_equal(s.get_attachment(), first, "the original attachment is kept")
	check_equal(second.get_parent(), holder, "the rejected node was not reparented")


func _snapping() -> void:
	start_case("snap settings")
	var holder: Node2D = track(Node2D.new()) as Node2D
	var s: FoxSocket2D = _socket(holder)
	s.global_position = Vector2(10, 5)

	var item: Node2D = Node2D.new()
	holder.add_child(item)
	item.global_position = Vector2(-3, -3)

	s.attach(item)
	check(item.global_position.is_equal_approx(Vector2(10, 5)), "position snapped to the socket")

	start_case("snapping disabled")
	var s2: FoxSocket2D = _socket(holder)
	s2.global_position = Vector2(20, 0)
	s2.snap_position = false
	var item2: Node2D = Node2D.new()
	holder.add_child(item2)
	item2.global_position = Vector2(1, 1)
	s2.attach(item2)
	check(item2.global_position.is_equal_approx(Vector2(1, 1)),
		"position left alone when snapping is off")


func _build_map(socket_names: Array) -> Array:
	var map: FoxSocketMap2D = FoxSocketMap2D.new()
	var sockets: Array[FoxSocket2D] = []
	for n: String in socket_names:
		var s: FoxSocket2D = FoxSocket2D.new()
		s.name = n
		map.add_child(s)
		sockets.append(s)
	track(map)
	return [map, sockets]


func _map_attaches_by_name() -> void:
	start_case("map attach by name")
	var built: Array = _build_map(["DriverSeat", "PassengerSeat"])
	var map: FoxSocketMap2D = built[0]
	var sockets: Array[FoxSocket2D] = built[1]

	check_equal(map.sockets.size(), 2, "both sockets were collected")
	check_equal(map.get_socket(&"DriverSeat"), sockets[0], "lookup by name works")
	check_equal(map.get_socket(&"Nope"), null, "unknown name returns null")

	var rider: Node2D = Node2D.new()
	map.add_child(rider)

	check(map.attach(rider, &"DriverSeat"), "attaching to a named socket succeeds")
	check_equal(sockets[0].get_attachment(), rider, "the named socket holds the rider")
	check(sockets[1].is_empty(), "the other socket is untouched")

	var second: Node2D = Node2D.new()
	map.add_child(second)
	check(not map.attach(second, &"DriverSeat"), "attaching to an occupied named socket fails")
	check(not map.attach(second, &"Nope"), "attaching to an unknown socket fails")


func _map_auto_attaches() -> void:
	start_case("map auto attach")
	var built: Array = _build_map(["A", "B"])
	var map: FoxSocketMap2D = built[0]
	var sockets: Array[FoxSocket2D] = built[1]

	var one: Node2D = Node2D.new()
	var two: Node2D = Node2D.new()
	var three: Node2D = Node2D.new()
	map.add_child(one)
	map.add_child(two)
	map.add_child(three)

	check(map.attach(one), "first auto attach succeeds")
	check(map.attach(two), "second auto attach succeeds")
	check(not map.attach(three), "a third fails once every socket is full")

	check(not sockets[0].is_empty(), "socket A filled")
	check(not sockets[1].is_empty(), "socket B filled")
	check_equal(three.get_parent(), map, "the rejected node stayed put")


func _map_reports_availability() -> void:
	start_case("availability")
	var built: Array = _build_map(["A", "B", "C"])
	var map: FoxSocketMap2D = built[0]

	check_equal(map.get_available_socket_count(), 3, "all sockets start free")

	var item: Node2D = Node2D.new()
	map.add_child(item)
	map.attach(item)
	check_equal(map.get_available_socket_count(), 2, "attaching consumes one")

	map.get_socket(&"A").detach()
	check_equal(map.get_available_socket_count(), 3, "detaching frees it again")


func _map_forwards_signals() -> void:
	start_case("signal forwarding")
	var built: Array = _build_map(["A"])
	var map: FoxSocketMap2D = built[0]

	var attached: Array = []
	var detached: Array = []
	map.node_attached.connect(func(a: Node2D, _s: FoxSocket2D) -> void: attached.append(a))
	map.node_detached.connect(func(a: Node2D, _s: FoxSocket2D) -> void: detached.append(a))

	var item: Node2D = Node2D.new()
	map.add_child(item)
	map.attach(item)
	check_equal(attached.size(), 1, "the map re-emitted the socket's attached signal")

	map.get_socket(&"A").detach()
	check_equal(detached.size(), 1, "and the detached signal")

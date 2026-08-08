extends "res://tests/fox_test.gd"

## The editor gizmo, loaded rather than preloaded. It extends an editor only class, so on a
## build without one this stays null and the gizmo cases are skipped instead of failing.
const GIZMO_PATH: String = "res://addons/foxfabric/socket/3d/editor/fox_socket_3d_gizmo.gd"


func run() -> void:
	suite = "socket"
	_gizmo_reads_occupancy()
	_empty_socket()
	_attaching_reparents()
	_detach_does_not_reparent()
	_occupied_sockets_refuse()
	_snapping()
	_map_attaches_by_name()
	_map_auto_attaches()
	_map_reports_availability()
	_map_forwards_signals()


func _gizmo_reads_occupancy() -> void:
	case("gizmo")
	# Only the static side is reachable. The engine refuses to instantiate an
	# EditorNode3DGizmoPlugin outside the editor, so nothing here touches an instance.
	var gizmo: GDScript = load(GIZMO_PATH) as GDScript
	check(gizmo != null, "the gizmo script loads")
	if gizmo == null:
		return

	var holder: Node3D = track(Node3D.new()) as Node3D
	var socket: FoxSocket3D = _socket(holder)
	check(not gizmo.is_occupied(socket), "an empty socket reads as empty")

	var marker: Node3D = Node3D.new()
	socket.add_child(marker)
	socket.marker = marker
	check(not gizmo.is_occupied(socket), "the marker alone is not an attachment")

	var seated: Node3D = Node3D.new()
	socket.add_child(seated)
	check(gizmo.is_occupied(socket), "a second child reads as occupied")

	case("gizmo marker transform")
	var bare: FoxSocket3D = _socket(holder)
	check(gizmo.marker_transform(bare).is_equal_approx(Transform3D.IDENTITY),
		"no marker draws at the socket itself")

	var offset: Node3D = Node3D.new()
	bare.add_child(offset)
	offset.position = Vector3(0.0, 1.5, 0.0)
	bare.marker = offset
	check(gizmo.marker_transform(bare).origin.is_equal_approx(Vector3(0.0, 1.5, 0.0)),
		"a marker draws at its own offset")

	var outsider: Node3D = Node3D.new()
	holder.add_child(outsider)
	bare.marker = outsider
	check(gizmo.marker_transform(bare).is_equal_approx(Transform3D.IDENTITY),
		"a marker outside the socket is ignored, since the warning already covers it")

	_gizmo_registers(gizmo, holder)
	_gizmo_draws(gizmo, holder)


## The plugin finds this by path, so a typo there means the gizmo silently never appears.
## [br][br]
## The plugin cannot be instantiated here. The engine only allows that inside the editor, so
## whether the editor actually renders the result is not something this run can prove.
func _gizmo_registers(gizmo: GDScript, holder: Node3D) -> void:
	case("gizmo registration")
	check(gizmo.handles(_socket(holder)), "it claims FoxSocket3D nodes")
	check(not gizmo.handles(track(Node3D.new()) as Node3D), "and nothing else")

	var listed: String = "res://addons/foxfabric/socket/3d/editor/fox_socket_3d_gizmo.gd"
	check(FoxFabric.GIZMOS.has(listed), "the plugin lists this gizmo")
	check(ResourceLoader.exists(listed), "and the path it lists resolves")


func _gizmo_draws(gizmo: GDScript, holder: Node3D) -> void:
	case("gizmo geometry")
	var socket: FoxSocket3D = _socket(holder)
	var lines: PackedVector3Array = gizmo.build_lines(socket)

	# Twelve octahedron edges plus a shaft and four barbs, two points each.
	eq(lines.size(), 34, "every segment is a pair of points")
	check(lines.size() % 2 == 0, "no dangling half segment")

	case("occupancy reads without colour")
	# Colour alone would exclude anyone who cannot separate the two hues, so an occupied socket
	# has to differ in shape as well.
	var seated: Node3D = Node3D.new()
	socket.add_child(seated)
	var filled: PackedVector3Array = gizmo.build_lines(socket)

	eq(filled.size(), 34 + 24, "an occupied socket nests a second diamond inside")
	check(filled.size() != lines.size(), "so the two states differ in shape, not only colour")
	socket.remove_child(seated)
	seated.free()

	var reach: float = 0.0
	for point: Vector3 in lines:
		reach = maxf(reach, point.length())
	check(reach > 0.0, "the gizmo is not drawn at a single point")
	check(reach < 1.0, "and stays small enough to sit on a socket")

	case("geometry follows the marker")
	var offset: Node3D = Node3D.new()
	socket.add_child(offset)
	offset.position = Vector3(0.0, 2.0, 0.0)
	socket.marker = offset

	var moved: PackedVector3Array = gizmo.build_lines(socket)
	eq(moved.size(), lines.size(), "the same shape is drawn")

	var lifted: int = 0
	for i: int in moved.size():
		if is_equal_approx(moved[i].y - lines[i].y, 2.0):
			lifted += 1
	eq(lifted, moved.size(), "every point moved with the marker")


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
	var sockets: Array[FoxSocket3D] = []
	for n: String in socket_names:
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
	var sockets: Array[FoxSocket3D] = built[1]

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
	var sockets: Array[FoxSocket3D] = built[1]

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

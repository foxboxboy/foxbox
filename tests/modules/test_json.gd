extends FoxTest


## A format that has never changed, for the plain reading and writing cases.
class WorldV1 extends FoxJsonFile:
	func _get_version() -> int:
		return 1


## A format three versions on. Version 1 renamed a key and version 2 added one, so a file saved
## at 1 only arrives intact when both steps run in order.
class WorldV3 extends FoxJsonFile:
	func _get_version() -> int:
		return 3

	func _migrate(contents: Dictionary, from_version: int) -> Dictionary:
		if from_version == 1:
			contents["props"] = contents["objects"]
			contents.erase("objects")
		if from_version == 2:
			contents["era"] = "modern"
		return contents


const DIR: String = "user://foxfabric_test_json"


func run() -> void:
	suite = "json"
	_wipe(DIR)
	DirAccess.make_dir_recursive_absolute(DIR)

	_every_type_survives_the_file()
	_the_file_holds_what_the_class_doc_says()
	_floats_round_on_the_way_out()
	_decoding_falls_back_on_anything_it_cannot_read()
	_colour_alpha_is_optional()
	_unsupported_values_are_named_by_path()
	_writing_then_reading()
	_migration_runs_once_per_step()
	_reading_says_why_it_failed()
	_writing_refuses_before_touching_the_file()
	_a_broken_file_falls_back_to_the_backup()
	_a_broken_file_never_becomes_the_backup()


func _every_type_survives_the_file() -> void:
	start_case("every type comes back out of real JSON text unchanged")

	# rotated and scaled unevenly, so a swapped or transposed axis cannot pass unnoticed
	var basis: Basis = Basis.from_euler(Vector3(0.3, -1.1, 0.7)).scaled(Vector3(2.0, 0.5, 1.5))

	_survives("Vector2", FoxJson.vector2_to_array(Vector2(1.5, -2.5)),
		FoxJson.array_to_vector2, FoxJson.vector2_to_array)
	_survives("Vector3", FoxJson.vector3_to_array(Vector3(1.23456, 2.0, -3.0)),
		FoxJson.array_to_vector3, FoxJson.vector3_to_array)
	_survives("Color", FoxJson.color_to_array(Color(0.8, 0.7, 0.5, 0.25)),
		FoxJson.array_to_color, FoxJson.color_to_array)
	_survives("Quaternion", FoxJson.quaternion_to_array(Quaternion(basis.orthonormalized())),
		FoxJson.array_to_quaternion, FoxJson.quaternion_to_array)
	_survives("Plane", FoxJson.plane_to_array(Plane(Vector3(1, 2, 3).normalized(), 5.0)),
		FoxJson.array_to_plane, FoxJson.plane_to_array)
	_survives("Rect2", FoxJson.rect2_to_array(Rect2(1, 2, 64, 32)),
		FoxJson.array_to_rect2, FoxJson.rect2_to_array)
	_survives("AABB", FoxJson.aabb_to_array(AABB(Vector3(0, 1, 2), Vector3(2, 1, 2))),
		FoxJson.array_to_aabb, FoxJson.aabb_to_array)
	_survives("Basis", FoxJson.basis_to_array(basis),
		FoxJson.array_to_basis, FoxJson.basis_to_array)
	_survives("Transform2D",
		FoxJson.transform_2d_to_array(Transform2D(0.7, Vector2(1.5, 2.5), 0.3, Vector2(4, -2))),
		FoxJson.array_to_transform_2d, FoxJson.transform_2d_to_array)
	_survives("Transform3D", FoxJson.transform_3d_to_array(Transform3D(basis, Vector3(2, -1, -3))),
		FoxJson.array_to_transform_3d, FoxJson.transform_3d_to_array)


func _the_file_holds_what_the_class_doc_says() -> void:
	# A round trip only proves the two halves agree with each other. Transposing a Basis on both
	# sides survives every check above, while the file quietly stops matching its own reference,
	# so the shape is pinned here against the table in the FoxJson class comment.
	start_case("the encoding matches the table in the class reference")

	_encodes(FoxJson.vector2_to_array(Vector2(1, 2)), "[1.0,2.0]", "Vector2(x, y)")
	_encodes(FoxJson.vector3_to_array(Vector3(1, 2, 3)), "[1.0,2.0,3.0]", "Vector3(x, y, z)")
	_encodes(FoxJson.color_to_array(Color(0.8, 0.7, 0.5, 1)), "[0.8,0.7,0.5,1.0]",
		"Color(r, g, b, a)")
	_encodes(FoxJson.quaternion_to_array(Quaternion(0, 0.38, 0, 0.92)), "[0.0,0.38,0.0,0.92]",
		"Quaternion(x, y, z, w)")
	_encodes(FoxJson.plane_to_array(Plane(0, 1, 0, 5)), "[0.0,1.0,0.0,5.0]", "Plane(a, b, c, d)")
	_encodes(FoxJson.rect2_to_array(Rect2(0, 0, 64, 32)), "[0.0,0.0,64.0,32.0]",
		"Rect2(x, y, width, height)")
	_encodes(FoxJson.aabb_to_array(AABB(Vector3(0, 0, 0), Vector3(2, 1, 2))),
		"[[0.0,0.0,0.0],[2.0,1.0,2.0]]", "AABB(position, size)")
	_encodes(FoxJson.basis_to_array(Basis.IDENTITY), "[[1.0,0.0,0.0],[0.0,1.0,0.0],[0.0,0.0,1.0]]",
		"Basis(x_axis, y_axis, z_axis)")
	_encodes(FoxJson.transform_2d_to_array(Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(4, 2))),
		"[[1.0,0.0],[0.0,1.0],[4.0,2.0]]", "Transform2D(x_axis, y_axis, origin)")
	_encodes(FoxJson.transform_3d_to_array(Transform3D(Basis.IDENTITY, Vector3(2, 0, -3))),
		"[[1.0,0.0,0.0],[0.0,1.0,0.0],[0.0,0.0,1.0],[2.0,0.0,-3.0]]",
		"Transform3D(x_axis, y_axis, z_axis, origin)")

	start_case("a matrix is written as its axes rather than its rows")

	# every row of the doc table above is its own transpose, so none of them can catch this
	_encodes(FoxJson.basis_to_array(Basis(Vector3(1, 2, 3), Vector3(4, 5, 6), Vector3(7, 8, 9))),
		"[[1.0,2.0,3.0],[4.0,5.0,6.0],[7.0,8.0,9.0]]", "Basis keeps x, then y, then z")
	_encodes(FoxJson.transform_2d_to_array(Transform2D(Vector2(1, 2), Vector2(3, 4), Vector2(5, 6))),
		"[[1.0,2.0],[3.0,4.0],[5.0,6.0]]", "Transform2D keeps x, then y, then origin")
	_encodes(FoxJson.transform_3d_to_array(
			Transform3D(Basis(Vector3(1, 2, 3), Vector3(4, 5, 6), Vector3(7, 8, 9)),
			Vector3(10, 11, 12))),
		"[[1.0,2.0,3.0],[4.0,5.0,6.0],[7.0,8.0,9.0],[10.0,11.0,12.0]]",
		"Transform3D keeps its three axes, then the origin")


func _floats_round_on_the_way_out() -> void:
	start_case("floats round to PRECISION so the file stays readable")

	# a Vector3 holds float32, so 0.1 + 0.2 reaches the file as 0.300000011920929 unrounded
	check_equal(JSON.stringify(FoxJson.vector3_to_array(Vector3(0.1 + 0.2, 1.0 / 3.0, 2.0))),
		"[0.3,0.333,2.0]", "components land on three places")

	var moved: float = 0.0
	for i: int in 200:
		var before: Vector3 = Vector3(
			rng.randf_range(-1000.0, 1000.0),
			rng.randf_range(-1000.0, 1000.0),
			rng.randf_range(-1000.0, 1000.0),
		)
		var after: Vector3 = FoxJson.array_to_vector3(FoxJson.vector3_to_array(before))
		moved = maxf(moved, (before - after).abs()[(before - after).abs().max_axis_index()])
	check(moved <= FoxJson.PRECISION, "no component moves further than PRECISION, worst was %f"
		% moved)


func _decoding_falls_back_on_anything_it_cannot_read() -> void:
	start_case("a malformed value costs a field rather than the file")

	var fallback: Vector3 = Vector3(9, 9, 9)
	check_equal(FoxJson.array_to_vector3(null, fallback), fallback, "a missing field")
	check_equal(FoxJson.array_to_vector3([1, 2], fallback), fallback, "too few numbers")
	check_equal(FoxJson.array_to_vector3([1, 2, 3, 4], fallback), fallback, "too many numbers")
	check_equal(FoxJson.array_to_vector3("(1, 2, 3)", fallback), fallback,
		"the debug string Godot writes")
	check_equal(FoxJson.array_to_vector3(["a", "b", "c"], fallback), fallback,
		"strings where numbers go")
	check_equal(FoxJson.array_to_vector3([[1, 0, 0], [0, 1, 0], [0, 0, 1]], fallback), fallback,
		"nested where flat was expected")
	check_equal(FoxJson.array_to_basis([1, 2, 3], Basis.IDENTITY), Basis.IDENTITY,
		"flat where nested was expected")

	start_case("an infinity in the file never reaches a value")

	# 1e99999 is what Godot writes for INF, and it parses back without complaint
	var parsed: Dictionary = JSON.parse_string('{"pos": [1e99999, 0, 0]}')
	check(is_inf(parsed["pos"][0]), "the file really does parse to an infinity")
	check_equal(FoxJson.array_to_vector3(parsed["pos"], fallback), fallback,
		"array_to_vector3 refuses it")
	check_equal(FoxJson.array_to_basis([[1e99999, 0, 0], [0, 1, 0], [0, 0, 1]], Basis.IDENTITY),
		Basis.IDENTITY, "and it cannot arrive one axis at a time either")


func _colour_alpha_is_optional() -> void:
	start_case("a colour written by hand may leave the alpha off")

	check_equal(FoxJson.array_to_color([1, 0, 0], Color.BLACK), Color(1, 0, 0, 1), "three components")
	check_equal(FoxJson.array_to_color([1, 0, 0, 0.5], Color.BLACK), Color(1, 0, 0, 0.5),
		"four components")
	check_equal(FoxJson.array_to_color([1, 0], Color.BLACK), Color.BLACK, "two is still a fallback")


func _unsupported_values_are_named_by_path() -> void:
	start_case("find_unsupported names what JSON would mangle")

	check_equal(FoxJson.find_unsupported({"a": 1, "b": "two", "c": [1, 2], "d": null}), "",
		"a dictionary JSON can hold reports nothing")
	check_equal(FoxJson.find_unsupported({"k": &"crate", "p": NodePath("Player")}), "",
		"StringName and NodePath pass, and come back as strings")
	check_equal(FoxJson.find_unsupported({"ids": PackedInt32Array([1, 2])}), "",
		"a packed int array really does become a JSON array")

	check(FoxJson.find_unsupported({"pos": Vector3.ONE}).begins_with("pos"),
		"a Vector3 is named by its key")
	check(FoxJson.find_unsupported({"props": [{"t": Transform3D.IDENTITY}]})
		.begins_with("props/0/t"), "a nested one is named by its path")
	check(not FoxJson.find_unsupported({"m": NAN}).is_empty(), "NaN, which JSON writes as null")
	check(not FoxJson.find_unsupported({"m": INF}).is_empty(), "INF, which JSON has no number for")
	check(not FoxJson.find_unsupported({"bytes": PackedByteArray([1])}).is_empty(),
		"a PackedByteArray, which becomes a string")
	check(not FoxJson.find_unsupported({"a": {1: "x"}}).is_empty(),
		"an int key, which collides with the string of the same name")
	check(not FoxJson.find_unsupported({"n": FoxJson.MAX_EXACT_INT + 1}).is_empty(),
		"an int past MAX_EXACT_INT, which comes back off by one")


func _writing_then_reading() -> void:
	start_case("a file written by one instance reads back in another")

	var path: String = DIR + "/plain.json"
	var writer: WorldV1 = WorldV1.new()
	check_equal(writer.write(path, {"objects": [{"kind": "crate"}], "name": "yard"}), OK,
		"write succeeds")
	check(FileAccess.file_exists(path), "the file is there")

	var text: String = FileAccess.get_file_as_string(path)
	check(text.contains('"version"'), "the version is stamped into the file")

	var reader: WorldV1 = WorldV1.new()
	check_equal(reader.read(path), OK, "read succeeds")
	check_equal(reader.data["name"], "yard", "the contents survive")
	check(not reader.data.has("version"), "the version is taken back out of data")
	check_equal(reader.get_error_message(), "", "a successful read leaves no error behind")
	check_equal(reader.get_error_line(), 0, "and no line")

	start_case("the backup only appears once there is something to keep")
	var backup: String = FoxJsonFile.get_backup_path(path)
	check_equal(backup, DIR + "/backups/plain.json", "it sits in a folder beside the file")
	writer.write(path, {"objects": [], "name": "yard two"})
	check(FileAccess.file_exists(backup), "the second write keeps the first")

	var kept: WorldV1 = WorldV1.new()
	check_equal(kept.read(backup), OK, "and what it keeps is whole")
	check_equal(kept.data["name"], "yard", "holding the save before this one")


func _migration_runs_once_per_step() -> void:
	start_case("an older file is carried forward a version at a time")

	var path: String = DIR + "/old.json"
	var old: WorldV1 = WorldV1.new()
	old.write(path, {"objects": [{"kind": "crate"}]})

	var current: WorldV3 = WorldV3.new()
	var announced: Array[int] = []
	current.migrated.connect(func(from: int) -> void: announced.append(from))

	check_equal(current.read(path), OK, "the older file still opens")
	check(current.data.has("props"), "step 1 renamed objects to props")
	check(not current.data.has("objects"), "and took the old key away")
	check_equal(current.data.get("era"), "modern", "step 2 ran as well, so it was not one jump")
	check_equal(announced, [1] as Array[int], "migrated reported the version it started from")

	start_case("a file already at the current version is left alone")
	var same: WorldV3 = WorldV3.new()
	same.write(DIR + "/new.json", {"props": []})
	var seen: Array[int] = []
	var reader: WorldV3 = WorldV3.new()
	reader.migrated.connect(func(from: int) -> void: seen.append(from))
	check_equal(reader.read(DIR + "/new.json"), OK, "it opens")
	check_equal(seen.size(), 0, "and nothing was migrated")

	start_case("a file from a newer build is refused rather than guessed at")
	var behind: WorldV1 = WorldV1.new()
	check_equal(behind.read(DIR + "/new.json"), ERR_FILE_UNRECOGNIZED, "reading it fails")
	check(behind.get_error_message().contains("version 3"), "and says which version it was")


func _reading_says_why_it_failed() -> void:
	start_case("a read that fails says what went wrong")

	var missing: WorldV1 = WorldV1.new()
	check_equal(missing.read(DIR + "/nothing.json"), ERR_FILE_NOT_FOUND, "a file that is not there")

	_write_text(DIR + "/broken.json", "{\n\t\"a\": 1,\n\t\"b\": 2,\n\t\"c\" 3\n}")
	var broken: WorldV1 = WorldV1.new()
	check_equal(broken.read(DIR + "/broken.json"), ERR_PARSE_ERROR, "text that is not JSON")
	check_equal(broken.get_error_line(), 4, "the line counts from 1, unlike JSON.get_error_line")
	check(not broken.get_error_message().is_empty(), "and there is a message with it")

	_write_text(DIR + "/list.json", "[1, 2, 3]")
	var list: WorldV1 = WorldV1.new()
	check_equal(list.read(DIR + "/list.json"), ERR_INVALID_DATA, "an array at the top level")

	_write_text(DIR + "/unstamped.json", '{"a": 1}')
	var unstamped: WorldV1 = WorldV1.new()
	check_equal(unstamped.read(DIR + "/unstamped.json"), ERR_INVALID_DATA, "no version at all")
	check(unstamped.get_error_message().contains("version"), "and it says so")


func _writing_refuses_before_touching_the_file() -> void:
	start_case("a write that cannot succeed leaves the previous file alone")

	var path: String = DIR + "/guarded.json"
	var writer: WorldV1 = WorldV1.new()
	writer.write(path, {"keep": "me"})

	check_equal(writer.write(path, {"pos": Vector3.ONE}), ERR_INVALID_DATA, "a Vector3 is refused")
	check(writer.get_error_message().begins_with("pos"), "and the key is named")
	check_equal(writer.write(path, {"version": 2}), ERR_INVALID_DATA, "so is the reserved version key")
	check_equal(writer.write(path, {"m": NAN}), ERR_INVALID_DATA, "so is NaN")

	var after: WorldV1 = WorldV1.new()
	check_equal(after.read(path), OK, "the file that was already there still opens")
	check_equal(after.data["keep"], "me", "holding what it held before the refusals")
	check(not FileAccess.file_exists(path + FoxJsonFile.TEMP_SUFFIX), "and no half-written file")


func _a_broken_file_falls_back_to_the_backup() -> void:
	start_case("a broken file is reported rather than quietly swapped for the backup")

	var path: String = DIR + "/crash.json"
	var writer: WorldV1 = WorldV1.new()
	writer.write(path, {"take": 1})
	writer.write(path, {"take": 2})
	_write_text(path, '{"take": 3, "props": [')

	var reader: WorldV1 = WorldV1.new()
	check_equal(reader.read(path), ERR_PARSE_ERROR, "the read fails, so the game can ask first")
	check(reader.get_error_message().contains("crash.json"), "naming the file that was asked for")
	check(reader.get_error_line() > 0, "and the line to look at")

	start_case("the backup is there for the game to reach for")

	# the backup holds the previous file, so taking it costs the save the crash interrupted
	check_equal(reader.read(FoxJsonFile.get_backup_path(path)), OK, "it opens")
	check_equal(reader.data["take"], 1, "holding the save before the one that was lost")
	check_equal(reader.get_error_message(), "", "and the earlier failure is not still reported")
	check_equal(reader.get_error_line(), 0, "nor its line")

	start_case("data keeps the last successful read when a later one fails")

	check_equal(reader.read(DIR + "/gone.json"), ERR_FILE_NOT_FOUND, "a read that cannot work")
	check_equal(reader.data["take"], 1, "leaves what was already loaded alone")


func _a_broken_file_never_becomes_the_backup() -> void:
	start_case("saving over a broken file puts it aside instead of over the good copy")

	var path: String = DIR + "/rotate.json"
	var writer: WorldV1 = WorldV1.new()
	writer.write(path, {"take": 1})
	writer.write(path, {"take": 2})
	_write_text(path, '{"take": 3, "MY EDIT": [')

	# a fresh instance that never read the broken file, which is the case remembering it would miss
	var session: WorldV1 = WorldV1.new()
	session.write(path, {"take": 4})

	var backup: WorldV1 = WorldV1.new()
	check_equal(backup.read(FoxJsonFile.get_backup_path(path)), OK, "the backup is still whole")
	check_equal(backup.data["take"], 1, "still holding the good save rather than the broken file")

	start_case("and the broken text is kept, not thrown away")

	var aside: String = FoxJsonFile.get_backup_path(path) + FoxJsonFile.BROKEN_SUFFIX
	check(FileAccess.file_exists(aside), "it is put aside under BROKEN_SUFFIX")
	check(FileAccess.get_file_as_string(aside).contains("MY EDIT"),
		"with whatever was hand written into it still there")


func _encodes(encoded: Array, expected: String, label: String) -> void:
	check_equal(JSON.stringify(encoded), expected, label)


func _survives(label: String, encoded: Array, decode: Callable, encode: Callable) -> void:
	# Through real JSON text, then back out and encoded again. Both encodings are already rounded,
	# so any difference between them is a mapping error rather than lost precision.
	var parsed: Dictionary = JSON.parse_string(JSON.stringify({"v": encoded}))
	var again: Array = encode.call(decode.call(parsed["v"]))
	check_equal(JSON.stringify(again), JSON.stringify(encoded), label)


func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _wipe(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for name: String in dir.get_files():
		DirAccess.remove_absolute(path.path_join(name))
	for name: String in dir.get_directories():
		_wipe(path.path_join(name))
	DirAccess.remove_absolute(path)

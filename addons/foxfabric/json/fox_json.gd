@abstract
class_name FoxJson
extends FoxRefCounted
## A converter between Godot values and the six types JSON can hold.
##
## [FoxJson] writes a value as the arguments its constructor takes, so the array in the file
## matches the call that rebuilds it and a reader who knows Godot can follow the format without
## being told it.
## [codeblock]
## Vector2(x, y)                                 [1.0, 2.0]
## Vector3(x, y, z)                              [1.0, 2.0, 3.0]
## Color(r, g, b, a)                             [0.8, 0.7, 0.5, 1.0]
## Quaternion(x, y, z, w)                        [0.0, 0.38, 0.0, 0.92]
## Plane(a, b, c, d)                             [0.0, 1.0, 0.0, 5.0]
## Rect2(x, y, width, height)                    [0.0, 0.0, 64.0, 32.0]
## AABB(position, size)                          [[0.0, 0.0, 0.0], [2.0, 1.0, 2.0]]
## Basis(x_axis, y_axis, z_axis)                 [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
## Transform2D(x_axis, y_axis, origin)           [[1.0, 0.0], [0.0, 1.0], [4.0, 2.0]]
## Transform3D(x_axis, y_axis, z_axis, origin)   [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0], [2.0, 0.0, -3.0]]
## [/codeblock]
## Every component is a float, so a whole number carries its [code].0[/code] into the file.
## Transforms keep their axes rather than a position, rotation, and scale. Decomposing reads
## better in a file, and it does not survive the trip: a body that is both rotated and scaled
## unevenly comes back wrong, and a mirrored one comes back with the wrong axis flipped.
## [br][br]
## Floats round to [constant PRECISION] on the way out, which is what keeps a file worth opening.
## [br][br]
## There is no [code]decode[/code]. Once a value is [code][2, 0, -3][/code] nothing can say
## whether it was a [Vector3] or three numbers, so decoding happens a field at a time through the
## [code]array_to_[/code] methods, and the code asking for the field is what records its type.
## [br][br]
## Every [code]array_to_[/code] method takes a default and returns it when the value is missing
## or the wrong shape. These files come from elsewhere, so a malformed one should cost a prop
## rather than the world holding it.




#region Variables

## Rounding applied by every [code]_to_array[/code] method.
const PRECISION: float = 0.001

## The largest whole number a JSON reader gives back unchanged. Above this, 9007199254740993
## returns as 9007199254740992.
const MAX_EXACT_INT: int = 9007199254740992

# Types JSON stores without losing anything worth keeping. The packed float arrays are absent
# because their entries still need checking for NaN.
const _SAFE_TYPES: Array[int] = [
	TYPE_NIL,
	TYPE_BOOL,
	TYPE_STRING,
	TYPE_STRING_NAME,
	TYPE_NODE_PATH,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
]

#endregion




#region Encoding

## Returns [param value] as [code][x, y][/code].
static func vector2_to_array(value: Vector2) -> Array:
	return [_snap(value.x), _snap(value.y)]


## Returns [param value] as [code][x, y, z][/code].
static func vector3_to_array(value: Vector3) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z)]


## Returns [param value] as [code][r, g, b, a][/code].
static func color_to_array(value: Color) -> Array:
	return [_snap(value.r), _snap(value.g), _snap(value.b), _snap(value.a)]


## Returns [param value] as [code][x, y, z, w][/code].
static func quaternion_to_array(value: Quaternion) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z), _snap(value.w)]


## Returns [param value] as [code][a, b, c, d][/code].
static func plane_to_array(value: Plane) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z), _snap(value.d)]


## Returns [param value] as [code][x, y, width, height][/code].
static func rect2_to_array(value: Rect2) -> Array:
	return [
		_snap(value.position.x),
		_snap(value.position.y),
		_snap(value.size.x),
		_snap(value.size.y),
	]


## Returns [param value] as [code][position, size][/code].
static func aabb_to_array(value: AABB) -> Array:
	return [vector3_to_array(value.position), vector3_to_array(value.size)]


## Returns [param value] as its three axes.
static func basis_to_array(value: Basis) -> Array:
	return [vector3_to_array(value.x), vector3_to_array(value.y), vector3_to_array(value.z)]


## Returns [param value] as its two axes and its origin.
static func transform_2d_to_array(value: Transform2D) -> Array:
	return [vector2_to_array(value.x), vector2_to_array(value.y), vector2_to_array(value.origin)]


## Returns [param value] as its three axes and its origin.
static func transform_3d_to_array(value: Transform3D) -> Array:
	return [
		vector3_to_array(value.basis.x),
		vector3_to_array(value.basis.y),
		vector3_to_array(value.basis.z),
		vector3_to_array(value.origin),
	]

#endregion




#region Decoding

## Returns the [Vector2] in [param value], or [param default].
static func array_to_vector2(value: Variant, default: Vector2 = Vector2.ZERO) -> Vector2:
	if not _is_number_array(value, 2):
		return default
	var numbers: Array = value
	return Vector2(numbers[0], numbers[1])


## Returns the [Vector3] in [param value], or [param default].
static func array_to_vector3(value: Variant, default: Vector3 = Vector3.ZERO) -> Vector3:
	if not _is_number_array(value, 3):
		return default
	var numbers: Array = value
	return Vector3(numbers[0], numbers[1], numbers[2])


## Returns the [Color] in [param value], or [param default].
## [br][br]
## Takes three components as well as four, so a colour written by hand without an alpha comes back
## opaque instead of falling back.
static func array_to_color(value: Variant, default: Color = Color.WHITE) -> Color:
	if _is_number_array(value, 3):
		var rgb: Array = value
		return Color(rgb[0], rgb[1], rgb[2])
	if not _is_number_array(value, 4):
		return default
	var rgba: Array = value
	return Color(rgba[0], rgba[1], rgba[2], rgba[3])


## Returns the [Quaternion] in [param value], or [param default].
static func array_to_quaternion(value: Variant, default: Quaternion = Quaternion.IDENTITY) -> Quaternion:
	if not _is_number_array(value, 4):
		return default
	var numbers: Array = value
	return Quaternion(numbers[0], numbers[1], numbers[2], numbers[3])


## Returns the [Plane] in [param value], or [param default].
static func array_to_plane(value: Variant, default: Plane = Plane()) -> Plane:
	if not _is_number_array(value, 4):
		return default
	var numbers: Array = value
	return Plane(numbers[0], numbers[1], numbers[2], numbers[3])


## Returns the [Rect2] in [param value], or [param default].
static func array_to_rect2(value: Variant, default: Rect2 = Rect2()) -> Rect2:
	if not _is_number_array(value, 4):
		return default
	var numbers: Array = value
	return Rect2(numbers[0], numbers[1], numbers[2], numbers[3])


## Returns the [AABB] in [param value], or [param default].
static func array_to_aabb(value: Variant, default: AABB = AABB()) -> AABB:
	if not _is_vector_array(value, 2, 3):
		return default
	var parts: Array = value
	return AABB(array_to_vector3(parts[0]), array_to_vector3(parts[1]))


## Returns the [Basis] in [param value], or [param default].
static func array_to_basis(value: Variant, default: Basis = Basis.IDENTITY) -> Basis:
	if not _is_vector_array(value, 3, 3):
		return default
	var axes: Array = value
	return Basis(
		array_to_vector3(axes[0]),
		array_to_vector3(axes[1]),
		array_to_vector3(axes[2]),
	)


## Returns the [Transform2D] in [param value], or [param default].
static func array_to_transform_2d(value: Variant, default: Transform2D = Transform2D.IDENTITY) -> Transform2D:
	if not _is_vector_array(value, 3, 2):
		return default
	var axes: Array = value
	return Transform2D(
		array_to_vector2(axes[0]),
		array_to_vector2(axes[1]),
		array_to_vector2(axes[2]),
	)


## Returns the [Transform3D] in [param value], or [param default].
static func array_to_transform_3d(value: Variant, default: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	if not _is_vector_array(value, 4, 3):
		return default
	var axes: Array = value
	return Transform3D(
		array_to_vector3(axes[0]),
		array_to_vector3(axes[1]),
		array_to_vector3(axes[2]),
		array_to_vector3(axes[3]),
	)

#endregion




#region Checking

## Returns a description of the first value in [param value] that JSON cannot store, or an empty
## string when all of them can be.
## [br][br]
## Godot writes an unsupported value as the text it prints in the debugger, so a [Vector3] saves as
## [code]"(1.0, 2.0, 3.0)"[/code] and loads back a [String]. Nothing reports this, which is what
## this exists to catch.
## [codeblock]
## var problem: String = FoxJson.find_unsupported(contents)
## if not problem.is_empty():
##     push_error(problem)
## # props/0/transform holds a Transform3D, which JSON cannot store
## [/codeblock]
## [StringName] and [NodePath] pass, and come back as a [String].
static func find_unsupported(value: Variant) -> String:
	return _find_unsupported(value, "")

#endregion




#region Private

# Walks depth first and stops at the first problem. Returning one is enough to refuse the write,
# and listing every one of them buries the first.
static func _find_unsupported(value: Variant, path: String) -> String:
	var type: int = typeof(value)

	if type == TYPE_ARRAY:
		var entries: Array = value
		for i: int in entries.size():
			var problem: String = _find_unsupported(entries[i], _join(path, str(i)))
			if not problem.is_empty():
				return problem
		return ""

	if type == TYPE_PACKED_FLOAT32_ARRAY:
		var floats: PackedFloat32Array = value
		for i: int in floats.size():
			var problem: String = _find_unsupported(floats[i], _join(path, str(i)))
			if not problem.is_empty():
				return problem
		return ""

	if type == TYPE_PACKED_FLOAT64_ARRAY:
		var floats: PackedFloat64Array = value
		for i: int in floats.size():
			var problem: String = _find_unsupported(floats[i], _join(path, str(i)))
			if not problem.is_empty():
				return problem
		return ""

	if type == TYPE_DICTIONARY:
		var entries: Dictionary = value
		for key: Variant in entries:
			if typeof(key) != TYPE_STRING and typeof(key) != TYPE_STRING_NAME:
				# Two keys that print the same collide into one entry, and the file keeps whichever
				# was written last.
				return "%s is keyed by a %s, and JSON keys are strings" % [
					_where(path), type_string(typeof(key)),
				]
			var problem: String = _find_unsupported(entries[key], _join(path, str(key)))
			if not problem.is_empty():
				return problem
		return ""

	if type == TYPE_INT:
		var whole: int = value
		if absi(whole) > MAX_EXACT_INT:
			return "%s is past %d, which JSON cannot hold exactly" % [_where(path), MAX_EXACT_INT]
		return ""

	if type == TYPE_FLOAT:
		var number: float = value
		if is_nan(number):
			return "%s is NaN, which JSON writes as null" % _where(path)
		if is_inf(number):
			return "%s is INF, which JSON has no number for" % _where(path)
		return ""

	if type in _SAFE_TYPES:
		return ""

	return "%s holds a %s, which JSON cannot store" % [_where(path), type_string(type)]


# Names the offending spot. The top level has no path of its own.
static func _where(path: String) -> String:
	return "the value" if path.is_empty() else path


static func _join(path: String, key: String) -> String:
	return key if path.is_empty() else "%s/%s" % [path, key]


# Rounds one component. A Vector3 holds float32, so an unrounded component reaches the file as
# 0.300000011920929 rather than 0.3.
static func _snap(value: float) -> float:
	return snappedf(value, PRECISION)


# JSON parses every number as a float, so TYPE_INT only turns up in a dictionary built in code and
# never written out. INF is rejected here as well as on the way in: a file holding 1e99999 parses
# without complaint and would otherwise put an infinity inside a transform.
static func _is_number_array(value: Variant, size: int) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var array: Array = value
	if array.size() != size:
		return false
	for entry: Variant in array:
		var type: int = typeof(entry)
		if type != TYPE_FLOAT and type != TYPE_INT:
			return false
		if type == TYPE_FLOAT:
			var number: float = entry
			if not is_finite(number):
				return false
	return true


# The nested shape the transforms and AABB use: count arrays, each of width numbers.
static func _is_vector_array(value: Variant, count: int, width: int) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var array: Array = value
	if array.size() != count:
		return false
	for entry: Variant in array:
		if not _is_number_array(entry, width):
			return false
	return true

#endregion

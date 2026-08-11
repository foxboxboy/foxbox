@abstract
class_name FoxJson
extends FoxRefCounted
## A converter between Godot values and the six types JSON can hold.
##
## [FoxJson] writes a value as the arguments its constructor takes, so the array in the file
## matches the call that rebuilds it and a reader who knows Godot can follow the format without
## being told it.
## [codeblock]
## Vector2(x, y)                                 [1, 2]
## Vector3(x, y, z)                              [1, 2, 3]
## Color(r, g, b, a)                             [0.8, 0.7, 0.5, 1]
## Quaternion(x, y, z, w)                        [0, 0.38, 0, 0.92]
## Plane(a, b, c, d)                             [0, 1, 0, 5]
## Rect2(x, y, width, height)                    [0, 0, 64, 32]
## AABB(position, size)                          [[0, 0, 0], [2, 1, 2]]
## Basis(x_axis, y_axis, z_axis)                 [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
## Transform2D(x_axis, y_axis, origin)           [[1, 0], [0, 1], [4, 2]]
## Transform3D(x_axis, y_axis, z_axis, origin)   [[1, 0, 0], [0, 1, 0], [0, 0, 1], [2, 0, -3]]
## [/codeblock]
## Transforms keep their axes rather than a position, rotation and scale. Decomposing reads
## better in a file, and it does not survive the trip: a body that is both rotated and scaled
## unevenly comes back wrong, and a mirrored one comes back with the wrong axis flipped.
## [br][br]
## Floats round to [constant PRECISION] on the way out, which is what keeps a file worth opening.
## [br][br]
## There is no [code]decode[/code]. Once a value is [code][2, 0, -3][/code] nothing can say
## whether it was a [Vector3] or three numbers, so decoding happens a field at a time through the
## [code]to_[/code] methods, and the code asking for the field is what records its type.
## [br][br]
## Every [code]to_[/code] method takes a default and returns it when the value is missing or the
## wrong shape. These files come from elsewhere, so a malformed one should cost a prop rather
## than the world holding it.


## Rounding applied by every [code]from_[/code] method.
const PRECISION: float = 0.001


#region Encoding

## Returns [param value] as [code][x, y][/code].
static func from_vector2(value: Vector2) -> Array:
	return [_snap(value.x), _snap(value.y)]


## Returns [param value] as [code][x, y, z][/code].
static func from_vector3(value: Vector3) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z)]


## Returns [param value] as [code][r, g, b, a][/code].
static func from_color(value: Color) -> Array:
	return [_snap(value.r), _snap(value.g), _snap(value.b), _snap(value.a)]


## Returns [param value] as [code][x, y, z, w][/code].
static func from_quaternion(value: Quaternion) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z), _snap(value.w)]


## Returns [param value] as [code][a, b, c, d][/code].
static func from_plane(value: Plane) -> Array:
	return [_snap(value.x), _snap(value.y), _snap(value.z), _snap(value.d)]


## Returns [param value] as [code][x, y, width, height][/code].
static func from_rect2(value: Rect2) -> Array:
	return [
		_snap(value.position.x),
		_snap(value.position.y),
		_snap(value.size.x),
		_snap(value.size.y),
	]


## Returns [param value] as [code][position, size][/code].
static func from_aabb(value: AABB) -> Array:
	return [from_vector3(value.position), from_vector3(value.size)]


## Returns [param value] as its three axes.
static func from_basis(value: Basis) -> Array:
	return [from_vector3(value.x), from_vector3(value.y), from_vector3(value.z)]


## Returns [param value] as its two axes and its origin.
static func from_transform_2d(value: Transform2D) -> Array:
	return [from_vector2(value.x), from_vector2(value.y), from_vector2(value.origin)]


## Returns [param value] as its three axes and its origin.
static func from_transform_3d(value: Transform3D) -> Array:
	return [
		from_vector3(value.basis.x),
		from_vector3(value.basis.y),
		from_vector3(value.basis.z),
		from_vector3(value.origin),
	]

#endregion


#region Decoding

## Returns the [Vector2] in [param value], or [param default].
static func to_vector2(value: Variant, default: Vector2 = Vector2.ZERO) -> Vector2:
	if not _is_number_array(value, 2):
		return default
	return Vector2(value[0], value[1])


## Returns the [Vector3] in [param value], or [param default].
static func to_vector3(value: Variant, default: Vector3 = Vector3.ZERO) -> Vector3:
	if not _is_number_array(value, 3):
		return default
	return Vector3(value[0], value[1], value[2])


## Returns the [Color] in [param value], or [param default].
static func to_color(value: Variant, default: Color = Color.WHITE) -> Color:
	if not _is_number_array(value, 4):
		return default
	return Color(value[0], value[1], value[2], value[3])


## Returns the [Quaternion] in [param value], or [param default].
static func to_quaternion(value: Variant, default: Quaternion = Quaternion.IDENTITY) -> Quaternion:
	if not _is_number_array(value, 4):
		return default
	return Quaternion(value[0], value[1], value[2], value[3])


## Returns the [Plane] in [param value], or [param default].
static func to_plane(value: Variant, default: Plane = Plane()) -> Plane:
	if not _is_number_array(value, 4):
		return default
	return Plane(value[0], value[1], value[2], value[3])


## Returns the [Rect2] in [param value], or [param default].
static func to_rect2(value: Variant, default: Rect2 = Rect2()) -> Rect2:
	if not _is_number_array(value, 4):
		return default
	return Rect2(value[0], value[1], value[2], value[3])


## Returns the [AABB] in [param value], or [param default].
static func to_aabb(value: Variant, default: AABB = AABB()) -> AABB:
	if not _is_vector_array(value, 2, 3):
		return default
	return AABB(to_vector3(value[0]), to_vector3(value[1]))


## Returns the [Basis] in [param value], or [param default].
static func to_basis(value: Variant, default: Basis = Basis.IDENTITY) -> Basis:
	if not _is_vector_array(value, 3, 3):
		return default
	return Basis(to_vector3(value[0]), to_vector3(value[1]), to_vector3(value[2]))


## Returns the [Transform2D] in [param value], or [param default].
static func to_transform_2d(value: Variant, default: Transform2D = Transform2D.IDENTITY) -> Transform2D:
	if not _is_vector_array(value, 3, 2):
		return default
	return Transform2D(to_vector2(value[0]), to_vector2(value[1]), to_vector2(value[2]))


## Returns the [Transform3D] in [param value], or [param default].
static func to_transform_3d(value: Variant, default: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	if not _is_vector_array(value, 4, 3):
		return default
	return Transform3D(
		to_vector3(value[0]),
		to_vector3(value[1]),
		to_vector3(value[2]),
		to_vector3(value[3]),
	)

#endregion


# Rounds one component. A Vector3 holds float32, so an unrounded component reaches the file as
# 0.300000011920929 rather than 0.3.
static func _snap(value: float) -> float:
	return snappedf(value, PRECISION)


# JSON parses every number as a float, so TYPE_INT only turns up in a dictionary built in code and
# never written out.
static func _is_number_array(value: Variant, size: int) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var array: Array = value
	if array.size() != size:
		return false
	for entry: Variant in array:
		if typeof(entry) != TYPE_FLOAT and typeof(entry) != TYPE_INT:
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

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

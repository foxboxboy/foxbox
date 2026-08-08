@icon("uid://cus3vopn7ucer")
class_name FoxPhysicsDragProfile
extends FoxResource
## A configuration profile defining the physics characteristics of a grab action.
##
## Swappable settings for [method FoxPhysicsDragger3D.grab] and
## [method FoxPhysicsDragger2D.grab]. Passing one overrides the dragger's own defaults for as
## long as that grab lasts.
## [br][br]
## Shared by both dimensions rather than duplicated, because stiffness, damping and staying
## upright mean the same thing in each. It sits at the module root for that reason, next to the
## [code]2d[/code] and [code]3d[/code] folders rather than inside one of them.
## [br][br]
## Note the stiffness and damping defaults. A fresh profile starts at 200 and 1, while both
## draggers fall back to 800 and 25 when no profile is given, so an untouched profile drags far
## more loosely than passing nothing at all.




## The "strength" of the pull. High values make it snappy, low values make it feel heavy.
@export var stiffness: float = 200.0:
	set(v):
		if v < 0.0:
			push_warning("FoxPhysicsDragProfile: 'stiffness' was set to a negative number. This will push objects away instead of pulling them.")
		stiffness = v

## The "control" of the pull. High values slow it down, low values make it bouncy.
@export var damping: float = 1.0:
	set(v):
		if v < 0.0:
			push_warning("FoxPhysicsDragProfile: 'damping' was set to a negative number. This will cause explosive physics instability.")
		damping = v

## If [code]true[/code], the held object is kept level instead of copying the dragger's tilt.
## [br][br]
## In 3D it still yaws to follow the dragger and only the tipping is removed. In 2D there is no
## facing to keep, so the object is simply held at zero rotation.
## [br][br]
## Off by default, which is free rotation: the object copies the dragger's orientation exactly
## and can be rolled over in the air. Turn it on and a dragger parented to a camera stops
## pitching whatever it is carrying every time you look up or down.
@export var keep_upright: bool = false

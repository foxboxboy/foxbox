@icon("uid://cus3vopn7ucer")
class_name FoxPhysicsDragProfile
extends FoxResource
## A configuration profile defining the physics characteristics of a grab action.
##
## Swappable settings for [method FoxPhysicsDragger3D.grab]. Passing one overrides the dragger's
## own defaults for as long as that grab lasts.
## [br][br]
## The two sets of defaults differ by a lot. A fresh profile starts at a stiffness of 200 and a
## damping of 1, while [FoxPhysicsDragger3D] falls back to 800 and 25 when no profile is given,
## so an untouched profile drags far more loosely than passing nothing at all.




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

## If [code]true[/code], forces the object to try and maintain an upright orientation.
@export var keep_upright: bool = true


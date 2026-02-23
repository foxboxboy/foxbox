class_name FoxPhysicsDragProfile
extends FoxResource

## The "strength" of the pull. High = snappy, low = heavy.
@export var stiffness: float = 200.0  # Stiffness
## The "control" of the pull. High = slow, low = bouncy
@export var damping: float = 1.0     # Damping
@export var keep_upright: bool = true

class_name FoxDraggable3D
extends Node3D

## The Rigidbody this component exposes.
@export var physics_body: RigidBody3D

## The "strength" of the pull. High = snappy, low = heavy.
@export var stiffness: float = 200.0  # Stiffness
## The "control" of the pull. High = slow, low = bouncy
@export var damping: float = 1.0     # Damping
@export var keep_upright: bool = true

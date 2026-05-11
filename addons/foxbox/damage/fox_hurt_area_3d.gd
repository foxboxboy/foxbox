class_name FoxHurtArea3D
extends Area3D
## Receives payloads from damage-dealing sources and routes them.
##
## Acts as a standardized data relay. It exists to be found by collision 
## queries and routes the delivered [Variant] payload via a signal.


## Emitted immediately when a payload is delivered via [method receive_hit]. 
signal hit_received(payload: Variant)


## If false, incoming payloads are silently ignored without emitting a signal.
@export var is_active: bool = true


## Accepts a [param payload] from an external source and emits [signal hit_received].
func receive_hit(payload: Variant) -> void:
	if is_active:
		hit_received.emit(payload)

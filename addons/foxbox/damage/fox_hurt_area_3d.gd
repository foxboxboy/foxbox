@icon("uid://bihwfrg2mota4")
class_name FoxHurtArea3D
extends Area3D
## Receives [Variant] payloads from physical interactions and routes them.
##
## Acts as the receiving end of the Foxbox interaction pipeline. It listens
## for overlapping [FoxHitArea3D] nodes and broadcasts their payload.


## Emitted immediately when a [param payload] is successfully delivered to this area.
signal hit_received(payload: Variant)

## If [code]false[/code], incoming payloads are silently ignored and no signals are emitted.
@export var is_active: bool = true


## Accepts a [Variant] [param payload] from an external source and emits [signal hit_received].
func receive_hit(payload: Variant) -> void:
	if is_active:
		hit_received.emit(payload)

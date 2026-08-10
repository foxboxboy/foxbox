@icon("uid://6gyoake65nbq")
class_name FoxHurtArea2D
extends Area2D
## A 2D area that receives [Variant] payloads from hit sources and routes them.
##
## [FoxHurtArea2D] acts as the receiving end of the FoxFabric damage pipeline. It listens
## for overlapping [FoxHitArea2D] nodes and broadcasts their payload.
## [codeblock]
## func _ready() -> void:
##     $HurtArea.hit_received.connect(_on_hit_received)
##
## func _on_hit_received(payload: Variant) -> void:
##     health -= payload["amount"]
##
## func start_invulnerability() -> void:
##     $HurtArea.is_active = false   # receive_hit returns false while this is off
## [/codeblock]


## Emitted immediately when a [param payload] is successfully delivered to this area.
signal hit_received(payload: Variant)

## If [code]false[/code], incoming payloads are silently ignored and no signals are emitted.
@export var is_active: bool = true


## Accepts a [Variant] [param payload] from an external source and emits [signal hit_received].
## [br][br]
## Returns [code]true[/code] if the payload was accepted, or [code]false[/code] when
## [member is_active] is off and the payload was ignored. Deliverers check this so they do not
## report a hit that never landed.
func receive_hit(payload: Variant) -> bool:
	if not is_active:
		return false

	hit_received.emit(payload)
	return true

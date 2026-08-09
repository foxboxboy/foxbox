@icon("uid://d1oovharegnuq")
class_name FoxHitArea2D
extends Area2D
## A 2D area that delivers a [Variant] payload to overlapping [FoxHurtArea2D] nodes.
##
## [FoxHitArea2D] can act passively via physics overlaps, or instantly via the [method fire] method.
## [br][br]
## The payload is whatever your project needs it to be. Nothing in this module reads it, so the
## same hitbox can carry a number, a dictionary, or a custom resource.
## [codeblock]
## # Attacker: describe the hit in whatever shape the game needs.
## func _ready() -> void:
##     $HitArea.payload = {"amount": 12, "source": self, "type": &"slash"}
##
## # Defender: a FoxHurtArea2D re-emits it, and you decide what it means.
## func _on_hit_received(payload: Variant) -> void:
##     health -= payload["amount"]
##     if payload["type"] == &"slash":
##         play_bleed_effect()
## [/codeblock]


## Emitted when this hitbox successfully delivers its [param payload] to a [param target].
signal hit_delivered(payload: Variant, target: FoxHurtArea2D)


## The arbitrary data this hitbox will deliver upon intersection.
@export var payload: Variant


## Instantly delivers the payload to all [FoxHurtArea2D] nodes currently inside this area.
## Useful for immediate Area-of-Effect interactions like explosions.
func fire() -> void:
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		_try_deliver_payload(area)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	_try_deliver_payload(area)


func _try_deliver_payload(area: Area2D) -> void:
	var hurtbox := area as FoxHurtArea2D
	if not hurtbox:
		return

	# only report a delivery the hurtbox actually accepted
	if hurtbox.receive_hit(payload):
		hit_delivered.emit(payload, hurtbox)

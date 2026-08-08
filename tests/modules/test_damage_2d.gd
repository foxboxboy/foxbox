extends "res://tests/fox_test.gd"
## The 2D half of the damage pipeline.
##
## Mirrors test_damage.gd. Kept as its own suite so the report shows at a glance whether 2D is
## covered, rather than hiding it inside the 3D one.


func run() -> void:
	suite = "damage_2d"
	_hurtbox_accepts_when_active()
	_hurtbox_refuses_when_inactive()
	_delivery_is_not_reported_when_ignored()
	_payload_passes_through_untouched()
	_non_hurtbox_areas_are_skipped()


func _hurt() -> FoxHurtArea2D:
	return track(FoxHurtArea2D.new()) as FoxHurtArea2D


func _hit() -> FoxHitArea2D:
	return track(FoxHitArea2D.new()) as FoxHitArea2D


func _hurtbox_accepts_when_active() -> void:
	case("active hurtbox")
	var h: FoxHurtArea2D = _hurt()
	var received: Array = []
	h.hit_received.connect(func(p: Variant) -> void: received.append(p))

	var accepted: bool = h.receive_hit(42)
	check(accepted, "an active hurtbox reports acceptance")
	eq(received.size(), 1, "hit_received fired once")
	eq(received[0], 42, "the payload arrived intact")


func _hurtbox_refuses_when_inactive() -> void:
	case("inactive hurtbox")
	var h: FoxHurtArea2D = _hurt()
	h.is_active = false
	var received: Array = []
	h.hit_received.connect(func(p: Variant) -> void: received.append(p))

	var accepted: bool = h.receive_hit(42)
	check(not accepted, "an inactive hurtbox reports refusal")
	eq(received.size(), 0, "hit_received never fired")

	h.is_active = true
	check(h.receive_hit(7), "re-enabling makes it accept again")
	eq(received.size(), 1, "and the signal fires")


func _delivery_is_not_reported_when_ignored() -> void:
	case("hit_delivered honesty")
	var hit: FoxHitArea2D = _hit()
	hit.payload = {"amount": 5}

	var live: FoxHurtArea2D = _hurt()
	var dead: FoxHurtArea2D = _hurt()
	dead.is_active = false

	var delivered: Array = []
	hit.hit_delivered.connect(func(_p: Variant, t: FoxHurtArea2D) -> void: delivered.append(t))

	hit._try_deliver_payload(live)
	eq(delivered.size(), 1, "delivery to an active hurtbox is reported")
	eq(delivered[0], live, "and names the right target")

	hit._try_deliver_payload(dead)
	eq(delivered.size(), 1, "delivery to an inactive hurtbox is not reported")


func _payload_passes_through_untouched() -> void:
	case("arbitrary payloads")
	var hit: FoxHitArea2D = _hit()
	var h: FoxHurtArea2D = _hurt()

	var got: Array = []
	h.hit_received.connect(func(p: Variant) -> void: got.append(p))

	# the module must not care what a payload is
	var cases: Array = [
		12,
		3.5,
		"a string",
		&"a stringname",
		{"amount": 9, "type": &"slash"},
		[1, 2, 3],
		null,
		Vector2(1, 2),
	]

	for c: Variant in cases:
		hit.payload = c
		hit._try_deliver_payload(h)

	eq(got.size(), cases.size(), "every payload shape was delivered")
	eq(got[4], {"amount": 9, "type": &"slash"}, "a dictionary payload survived intact")
	eq(got[6], null, "a null payload is still delivered rather than dropped")
	eq(got[7], Vector2(1, 2), "a struct payload survived intact")


func _non_hurtbox_areas_are_skipped() -> void:
	case("unrelated areas")
	var hit: FoxHitArea2D = _hit()
	hit.payload = 1
	var delivered: Array = []
	hit.hit_delivered.connect(func(_p: Variant, _t: FoxHurtArea2D) -> void: delivered.append(1))

	var plain: Area2D = track(Area2D.new()) as Area2D
	hit._try_deliver_payload(plain)
	eq(delivered.size(), 0, "a plain Area2D is ignored without erroring")

	# There is deliberately no test that a 2D hitbox refuses a 3D hurtbox. _try_deliver_payload
	# takes an Area2D, so an Area3D cannot reach it: the type is the guarantee, and a test would
	# only be able to assert that a call it cannot make did not happen.

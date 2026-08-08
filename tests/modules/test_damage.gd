extends "res://tests/fox_test.gd"


func run() -> void:
	suite = "damage"
	_hurtbox_accepts_when_active()
	_hurtbox_refuses_when_inactive()
	_delivery_is_not_reported_when_ignored()
	_payload_passes_through_untouched()
	_non_hurtbox_areas_are_skipped()


func _hurt() -> FoxHurtArea3D:
	return track(FoxHurtArea3D.new()) as FoxHurtArea3D


func _hit() -> FoxHitArea3D:
	return track(FoxHitArea3D.new()) as FoxHitArea3D


func _hurtbox_accepts_when_active() -> void:
	case("active hurtbox")
	var h := _hurt()
	var received := []
	h.hit_received.connect(func(p: Variant) -> void: received.append(p))

	var accepted := h.receive_hit(42)
	check(accepted, "an active hurtbox reports acceptance")
	eq(received.size(), 1, "hit_received fired once")
	eq(received[0], 42, "the payload arrived intact")


## Regression: receive_hit returned void, so a deliverer could not tell whether an inactive
## hurtbox had ignored the payload.
func _hurtbox_refuses_when_inactive() -> void:
	case("inactive hurtbox")
	var h := _hurt()
	h.is_active = false
	var received := []
	h.hit_received.connect(func(p: Variant) -> void: received.append(p))

	var accepted := h.receive_hit(42)
	check(not accepted, "an inactive hurtbox reports refusal")
	eq(received.size(), 0, "hit_received never fired")

	h.is_active = true
	check(h.receive_hit(7), "re-enabling makes it accept again")
	eq(received.size(), 1, "and the signal fires")


## Regression: hit_delivered used to fire unconditionally, announcing a "successful delivery"
## to a hurtbox that had silently dropped the payload.
func _delivery_is_not_reported_when_ignored() -> void:
	case("hit_delivered honesty")
	var hit := _hit()
	hit.payload = {"amount": 5}

	var live := _hurt()
	var dead := _hurt()
	dead.is_active = false

	var delivered := []
	hit.hit_delivered.connect(func(_p: Variant, t: FoxHurtArea3D) -> void: delivered.append(t))

	hit._try_deliver_payload(live)
	eq(delivered.size(), 1, "delivery to an active hurtbox is reported")
	eq(delivered[0], live, "and names the right target")

	hit._try_deliver_payload(dead)
	eq(delivered.size(), 1, "delivery to an inactive hurtbox is not reported")


func _payload_passes_through_untouched() -> void:
	case("arbitrary payloads")
	var hit := _hit()
	var h := _hurt()

	var got := []
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
		Vector3(1, 2, 3),
	]

	for c in cases:
		hit.payload = c
		hit._try_deliver_payload(h)

	eq(got.size(), cases.size(), "every payload shape was delivered")
	eq(got[4], {"amount": 9, "type": &"slash"}, "a dictionary payload survived intact")
	eq(got[6], null, "a null payload is still delivered rather than dropped")
	eq(got[7], Vector3(1, 2, 3), "a struct payload survived intact")


func _non_hurtbox_areas_are_skipped() -> void:
	case("unrelated areas")
	var hit := _hit()
	hit.payload = 1
	var delivered := []
	hit.hit_delivered.connect(func(_p: Variant, _t: FoxHurtArea3D) -> void: delivered.append(1))

	var plain := track(Area3D.new()) as Area3D
	hit._try_deliver_payload(plain)
	eq(delivered.size(), 0, "a plain Area3D is ignored without erroring")

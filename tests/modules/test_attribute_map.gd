extends "res://tests/fox_test.gd"


## FoxAttributeRule is abstract, so tests need a concrete one.
class FlatRule extends FoxAttributeRule:
	var amount: float = 0.0

	func _init(p_id: StringName = &"", p_key: StringName = &"", p_amount: float = 0.0) -> void:
		super(p_id, p_key)
		amount = p_amount

	func apply_to(map: FoxAttributeMap) -> void:
		var current: float = map.get_data(target_key, 0.0)
		map.set_data(target_key, current + amount)

	func remove_from(map: FoxAttributeMap) -> void:
		var current: float = map.get_data(target_key, 0.0)
		map.set_data(target_key, current - amount)


func run() -> void:
	suite = "attribute_map"
	_data_storage()
	_groups()
	_flags_stack()
	_rules_apply_and_reverse()
	_local_add_rule_ignores_can_receive_rules()
	_inheritance_respects_can_receive_rules()
	_can_send_rules_stops_propagation()
	_late_joining_children_catch_up()
	_flags_propagate_while_attached()
	_duplicate_rule_ids_are_refused()
	_read_accessors_do_not_expose_internals()


## Reads a float out of the map through a typed local, so callers never pass a Variant into
## a typed parameter.
func _speed(m: FoxAttributeMap) -> float:
	var value: float = m.get_data(&"speed", 0.0)
	return value


func _new_map() -> FoxAttributeMap:
	return track(FoxAttributeMap.new()) as FoxAttributeMap


func _data_storage() -> void:
	case("data")
	var m: FoxAttributeMap = _new_map()
	var added: Array[int] = [0]
	var replaced: Array[int] = [0]
	var removed: Array[int] = [0]
	m.data_added.connect(func(_k: StringName, _v: Variant) -> void: added[0] += 1)
	m.data_replaced.connect(func(_k: StringName, _v: Variant) -> void: replaced[0] += 1)
	m.data_removed.connect(func(_k: StringName, _v: Variant) -> void: removed[0] += 1)

	check(not m.has_data(&"hp"), "unknown key is absent")
	eq(m.get_data(&"hp", 99), 99, "get_data falls back to the default")

	m.set_data(&"hp", 50)
	eq(m.get_data(&"hp"), 50, "stored value comes back")
	eq(added[0], 1, "a new key emits data_added")
	eq(replaced[0], 0, "a new key does not emit data_replaced")

	m.set_data(&"hp", 75)
	eq(m.get_data(&"hp"), 75, "value was overwritten")
	eq(added[0], 1, "overwriting does not emit data_added again")
	eq(replaced[0], 1, "overwriting emits data_replaced")

	m.erase_data(&"hp")
	check(not m.has_data(&"hp"), "erased key is gone")
	eq(removed[0], 1, "erasing emits data_removed")

	m.erase_data(&"hp")
	eq(removed[0], 1, "erasing a missing key is silent")


func _groups() -> void:
	case("groups")
	var m: FoxAttributeMap = _new_map()
	m.set_data(&"speed", 5.0)
	m.set_data(&"accel", 2.0)

	m.add_data_to_group(&"speed", &"movement")
	m.add_data_to_group(&"accel", &"movement")
	check(m.has_group(&"movement"), "group was created implicitly")
	eq(m.get_data_in_group(&"movement").size(), 2, "group returns both values")

	m.add_data_to_group(&"speed", &"movement")
	eq(m.get_data_in_group(&"movement").size(), 2, "adding the same key twice does not duplicate")

	m.erase_data_from_group(&"speed", &"movement")
	eq(m.get_data_in_group(&"movement").size(), 1, "removing from a group shrinks it")

	eq(m.get_data_in_group(&"nope").size(), 0, "unknown group returns an empty array")

	# erasing the data itself should also purge it from every group
	m.add_data_to_group(&"speed", &"movement")
	m.erase_data(&"speed")
	eq(m.get_data_in_group(&"movement").size(), 1, "erasing data removes it from its groups")

	check(m.erase_group(&"movement"), "erasing an existing group reports success")
	check(not m.erase_group(&"movement"), "erasing it twice reports failure")


func _flags_stack() -> void:
	case("flags are stacked, not boolean")
	var m: FoxAttributeMap = _new_map()
	var added: Array[int] = [0]
	var removed: Array[int] = [0]
	m.flag_added.connect(func(_f: StringName) -> void: added[0] += 1)
	m.flag_removed.connect(func(_f: StringName) -> void: removed[0] += 1)

	check(not m.has_flag(&"slowed"), "unknown flag is absent")
	eq(m.get_flag_stacks(&"slowed"), 0, "unknown flag has zero stacks")

	m.increment_flag(&"slowed")
	check(m.has_flag(&"slowed"), "flag present after one increment")
	eq(added[0], 1, "flag_added fires on the first stack only")

	m.increment_flag(&"slowed")
	eq(m.get_flag_stacks(&"slowed"), 2, "second increment stacks")
	eq(added[0], 1, "flag_added does not fire again")

	m.decrement_flag(&"slowed")
	check(m.has_flag(&"slowed"), "one decrement of two leaves the flag set")
	eq(removed[0], 0, "flag_removed has not fired yet")

	m.decrement_flag(&"slowed")
	check(not m.has_flag(&"slowed"), "the last decrement clears it")
	eq(removed[0], 1, "flag_removed fires once")

	m.decrement_flag(&"slowed")
	eq(removed[0], 1, "decrementing below zero is silent")

	m.increment_flag(&"a")
	m.increment_flag(&"a")
	m.erase_flag(&"a")
	check(not m.has_flag(&"a"), "erase_flag drops every stack at once")

	m.increment_flag(&"x")
	m.increment_flag(&"y")
	m.clear_all_flags()
	check(not m.has_flag(&"x") and not m.has_flag(&"y"), "clear_all_flags empties everything")


func _rules_apply_and_reverse() -> void:
	case("rules")
	var m: FoxAttributeMap = _new_map()
	m.set_data(&"speed", 10.0)

	var rule: FlatRule = FlatRule.new(&"haste", &"speed", 5.0)
	m.add_rule(rule)
	almost(_speed(m), 15.0, "adding a rule applies it")
	eq(m.get_active_rules().size(), 1, "rule is tracked")

	m.add_rule(rule)
	eq(m.get_active_rules().size(), 1, "the same rule instance is not added twice")
	almost(_speed(m), 15.0, "and is not applied twice")

	m.remove_rule(&"haste")
	almost(_speed(m), 10.0, "removing a rule reverses it")
	eq(m.get_active_rules().size(), 0, "rule is untracked")

	m.remove_rule(&"nonexistent")
	almost(_speed(m), 10.0, "removing an unknown rule changes nothing")


## Regression: the can_receive_rules guard sat at the top of add_rule and fired for every
## caller, so a direct local call silently did nothing. The flag is only about inheritance.
func _local_add_rule_ignores_can_receive_rules() -> void:
	case("can_receive_rules does not block local calls")
	var m: FoxAttributeMap = _new_map()
	m.can_receive_rules = false
	m.set_data(&"speed", 10.0)

	m.add_rule(FlatRule.new(&"local", &"speed", 5.0))
	almost(_speed(m), 15.0, "a rule added directly still applies")
	eq(m.get_active_rules().size(), 1, "and is still tracked")


func _inheritance_respects_can_receive_rules() -> void:
	case("can_receive_rules blocks inherited rules")

	# entity -> [parent map, sub -> [child map]]
	var entity: Node = track(Node.new())
	var parent_map: FoxAttributeMap = FoxAttributeMap.new()
	entity.add_child(parent_map)
	var sub: Node = Node.new()
	entity.add_child(sub)
	var child_map: FoxAttributeMap = FoxAttributeMap.new()
	child_map.can_receive_rules = false
	sub.add_child(child_map)

	parent_map.set_data(&"speed", 10.0)
	child_map.set_data(&"speed", 10.0)

	parent_map.add_rule(FlatRule.new(&"aura", &"speed", 5.0))

	almost(_speed(parent_map), 15.0, "the parent applies its own rule")
	almost(_speed(child_map), 10.0, "the opted-out child ignores the inherited rule")
	eq(child_map.get_active_rules().size(), 0, "and does not track it")

	case("an opted-in child does inherit")
	var entity2: Node = track(Node.new())
	var pm: FoxAttributeMap = FoxAttributeMap.new()
	entity2.add_child(pm)
	var sub2: Node = Node.new()
	entity2.add_child(sub2)
	var cm: FoxAttributeMap = FoxAttributeMap.new()
	sub2.add_child(cm)

	pm.set_data(&"speed", 10.0)
	cm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"aura2", &"speed", 5.0))

	almost(_speed(cm), 15.0, "the child receives the parent's rule")
	eq(cm.get_active_rules().size(), 1, "and tracks it")

	pm.remove_rule(&"aura2")
	almost(_speed(cm), 10.0, "removing on the parent reverses it on the child")


func _can_send_rules_stops_propagation() -> void:
	case("can_send_rules")
	var entity: Node = track(Node.new())
	var pm: FoxAttributeMap = FoxAttributeMap.new()
	pm.can_send_rules = false
	entity.add_child(pm)
	var sub: Node = Node.new()
	entity.add_child(sub)
	var cm: FoxAttributeMap = FoxAttributeMap.new()
	sub.add_child(cm)

	pm.set_data(&"speed", 10.0)
	cm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"selfish", &"speed", 5.0))

	almost(_speed(pm), 15.0, "the parent still applies it locally")
	almost(_speed(cm), 10.0, "nothing propagated down")


func _late_joining_children_catch_up() -> void:
	case("late joining children")
	var entity: Node = track(Node.new())
	var pm: FoxAttributeMap = FoxAttributeMap.new()
	entity.add_child(pm)

	pm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"early", &"speed", 5.0))
	pm.increment_flag(&"blessed")
	pm.increment_flag(&"blessed")

	# child arrives after the rule and flags already exist
	var sub: Node = Node.new()
	entity.add_child(sub)
	var cm: FoxAttributeMap = FoxAttributeMap.new()
	cm.set_data(&"speed", 100.0)
	sub.add_child(cm)

	almost(_speed(cm), 105.0, "the existing rule was applied on join")
	eq(cm.get_flag_stacks(&"blessed"), 2, "existing flag stacks were copied across")


## A flag raised on the parent after a child has joined used to stop at the parent, but detaching
## still decremented the child, so the child lost a stack it had applied to itself.
func _flags_propagate_while_attached() -> void:
	case("flags reach children that are already attached")
	var entity: Node = track(Node.new())
	var pm: FoxAttributeMap = FoxAttributeMap.new()
	entity.add_child(pm)
	var sub: Node = Node.new()
	entity.add_child(sub)
	var cm: FoxAttributeMap = FoxAttributeMap.new()
	sub.add_child(cm)

	pm.increment_flag(&"burning")
	eq(cm.get_flag_stacks(&"burning"), 1, "the stack travelled down")

	pm.decrement_flag(&"burning")
	eq(cm.get_flag_stacks(&"burning"), 0, "and came back off")

	case("detaching only takes back what the parent gave")
	cm.increment_flag(&"burning")
	pm.increment_flag(&"burning")
	eq(cm.get_flag_stacks(&"burning"), 2, "the child holds its own stack plus the parent's")

	entity.remove_child(sub)
	eq(cm.get_flag_stacks(&"burning"), 1, "the child keeps the stack it applied to itself")
	sub.free()

	case("erase_flag takes every stack off the children too")
	var entity2: Node = track(Node.new())
	var pm2: FoxAttributeMap = FoxAttributeMap.new()
	entity2.add_child(pm2)
	var sub2: Node = Node.new()
	entity2.add_child(sub2)
	var cm2: FoxAttributeMap = FoxAttributeMap.new()
	sub2.add_child(cm2)

	pm2.increment_flag(&"cursed")
	pm2.increment_flag(&"cursed")
	eq(cm2.get_flag_stacks(&"cursed"), 2, "both stacks travelled down")

	pm2.erase_flag(&"cursed")
	eq(cm2.get_flag_stacks(&"cursed"), 0, "erasing on the parent clears the child")

	case("can_send_rules also holds flags back")
	var entity3: Node = track(Node.new())
	var pm3: FoxAttributeMap = FoxAttributeMap.new()
	pm3.can_send_rules = false
	entity3.add_child(pm3)
	var sub3: Node = Node.new()
	entity3.add_child(sub3)
	var cm3: FoxAttributeMap = FoxAttributeMap.new()
	sub3.add_child(cm3)

	pm3.increment_flag(&"quiet")
	eq(cm3.get_flag_stacks(&"quiet"), 0, "nothing propagated down")


## remove_rule matches on id, so a second rule under a used id could never be taken off by itself.
func _duplicate_rule_ids_are_refused() -> void:
	case("a second rule under a used id is refused")
	var m: FoxAttributeMap = _new_map()
	m.set_data(&"speed", 10.0)

	m.add_rule(FlatRule.new(&"haste", &"speed", 5.0))
	m.add_rule(FlatRule.new(&"haste", &"speed", 5.0))

	eq(m.get_active_rules().size(), 1, "only the first rule is tracked")
	almost(_speed(m), 15.0, "and only the first was applied")

	m.remove_rule(&"haste")
	almost(_speed(m), 10.0, "one removal puts the data all the way back")
	eq(m.get_active_rules().size(), 0, "and clears the list")

	case("a different id is still allowed")
	m.add_rule(FlatRule.new(&"haste", &"speed", 5.0))
	m.add_rule(FlatRule.new(&"blessing", &"speed", 5.0))
	eq(m.get_active_rules().size(), 2, "distinct ids both apply")
	almost(_speed(m), 20.0, "and both reach the data")


func _read_accessors_do_not_expose_internals() -> void:
	case("read accessors hand back copies")
	var m: FoxAttributeMap = _new_map()
	m.set_data(&"speed", 10.0)
	m.set_data(&"health", 5.0)
	m.add_data_to_group(&"speed", &"movement")
	m.increment_flag(&"slowed")
	m.add_rule(FlatRule.new(&"aura", &"speed", 1.0))

	eq(m.get_data_keys().size(), 2, "both keys are listed")
	check(m.get_data_keys().has(&"speed"), "and named")

	eq(m.get_group_names(), [&"movement"] as Array[StringName], "the group is listed")
	eq(m.get_keys_in_group(&"movement"), [&"speed"] as Array[StringName], "with its members")
	eq(m.get_keys_in_group(&"nope").size(), 0, "an unknown group is empty, not an error")

	m.get_flags().clear()
	eq(m.get_flag_stacks(&"slowed"), 1, "clearing the returned flags leaves the map alone")

	m.get_active_rules().clear()
	eq(m.get_active_rules().size(), 1, "clearing the returned rules leaves the map alone")

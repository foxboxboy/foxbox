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
	_runtime_state_reaches_the_inspector()
	_hierarchy_and_inherited_rules_are_published()
	_inspector_claims_remote_objects_too()
	_the_read_out_refills_rather_than_rebuilds()


## Reads a float out of the map through a typed local, so callers never pass a Variant into
## a typed parameter.
func _speed(m: FoxAttributeMap) -> float:
	var value: float = m.get_data(&"speed", 0.0)
	return value


func _new_map() -> FoxAttributeMap:
	return track(FoxAttributeMap.new()) as FoxAttributeMap


## A read-out row, checked field by field. Comparing the four at once reports all of them on a
## failure rather than stopping at the first.
func _row_is(row: Variant, depth: int, name: String, value: String, label: String) -> void:
	eq([row.depth, row.name, row.value], [depth, name, value], label)


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


## Stands in for the object the debugger hands the inspector for a node in a running game. It is
## not a FoxAttributeMap and never will be, which is the whole reason the plugin checks properties.
class RemoteStandIn extends Object:
	func _get_property_list() -> Array[Dictionary]:
		return [{
			"name": &"runtime_flags",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY,
		}]

	func _get(property: StringName) -> Variant:
		if property == &"runtime_flags":
			return {&"slowed": 2}

		return null


func _runtime_state_reaches_the_inspector() -> void:
	case("runtime state is published as read-only properties")
	var m: FoxAttributeMap = _new_map()
	m.set_data(&"health", 75)
	m.add_data_to_group(&"health", &"vitals")
	m.increment_flag(&"slowed")
	m.increment_flag(&"slowed")
	m.add_rule(FlatRule.new(&"swamp", &"health", 0.0))

	var published: Dictionary[StringName, Dictionary] = {}
	for property: Dictionary in m.get_property_list():
		var name: StringName = property["name"]
		if String(name).begins_with("runtime_"):
			published[name] = property

	eq(published.size(), 6, "data, groups, flags, rules, inherited rules and the tree are all published")

	for name: StringName in published:
		var usage: int = published[name]["usage"]
		check(usage & PROPERTY_USAGE_READ_ONLY != 0, "%s is read-only" % name)
		check(usage & PROPERTY_USAGE_STORAGE == 0, "%s is never written into a .tscn" % name)

	eq(m.get(&"runtime_flags"), {&"slowed": 2} as Dictionary, "flags come through with their stacks")
	eq(m.get(&"runtime_rules"), {&"swamp": &"health"} as Dictionary, "rules come through as id to target")
	eq(m.get(&"runtime_groups"), {&"vitals": [&"health"]} as Dictionary, "groups come through with members")
	# "75.0" rather than "75": the rule above read health as a float and wrote it back as one.
	eq(m.get(&"runtime_data"), {&"health": "75.0"} as Dictionary, "data comes through as text")

	case("a stored object is turned into text before it can reach the debugger")
	m.set_data(&"power", FoxModifiableStat.new(10.0))

	var data: Dictionary = m.get(&"runtime_data")
	var power: Variant = data[&"power"]
	check(power is String, "an object value is published as a String")
	eq(power, str(FoxModifiableStat.new(10.0)), "carrying whatever its _to_string gives it")

	case("unknown properties are left to the engine")
	eq(m.get(&"not_a_real_property"), null, "_get falls through")


## Publishes every property the read-out reads, so the panel can be built against something that is
## not a map. RemoteStandIn covers the claim check and answers only one property.
class FullStandIn extends Object:
	var data: Dictionary = {}
	var groups: Dictionary = {}

	func _get(property: StringName) -> Variant:
		match property:
			&"runtime_data":
				return data
			&"runtime_groups":
				return groups
			&"runtime_inherited_rules":
				return []

		return {}


func _the_read_out_refills_rather_than_rebuilds() -> void:
	case("the read-out fills its sections instead of rebuilding them")
	var source: GDScript = load("res://addons/foxfabric/attribute_map/editor/fox_attribute_map_panel.gd") as GDScript
	check(source != null, "the panel script loads")
	if source == null:
		return

	var stand_in: FullStandIn = FullStandIn.new()
	stand_in.data = {&"a": "1", &"b": "2", &"c": "3"}
	stand_in.groups = {&"firepower": [&"a", &"b"]}

	# The read-out is the Tree itself. It carries no heading, because the inspector group it goes
	# inside supplies one.
	var tree: Tree = track(source.new(stand_in)) as Tree
	check(tree != null, "the read-out is a Tree")
	if tree == null:
		return

	check(tree.hide_root, "whose root is never drawn, since the group heading already names it")

	var root: TreeItem = tree.get_root()
	var data_section: TreeItem = root.get_first_child()
	eq(data_section.get_text(0), "Data", "Data is the first section under it")
	eq(data_section.get_text(1), "3 keys", "counting what it holds, so folding it away loses nothing")
	eq(data_section.get_child_count(), 3, "holding one row per key")
	eq(data_section.get_first_child().get_text(1), "1", "with the value in the second column")

	# Deliberate, and asserted so it is not put back by accident. A box on the values alone singles
	# out whichever row happens to hold one; a box on every cell runs into its neighbours, because a
	# Tree draws its rows edge to edge and has no separation to give between them.
	check(data_section.get_first_child().get_custom_stylebox(1) == null, "a value carries no box, only its colour")
	check(data_section.get_custom_stylebox(1) == null, "and neither does a heading count")

	# A group sits at the same depth as a data key but counts what is under it rather than holding
	# a value, which is why the row says so instead of the drawing guessing from depth.
	var group_row: TreeItem = root.get_first_child().get_next().get_first_child()
	eq(group_row.get_text(0), "firepower", "a group is named under the Groups heading")
	eq(group_row.get_text(1), "2 keys", "counting the keys filed under it")
	check(group_row.get_custom_stylebox(1) == null, "and nor does a group count")

	case("a value that moved leaves the rows standing")
	var first: TreeItem = data_section.get_first_child()
	stand_in.data = {&"a": "99", &"b": "2", &"c": "3"}
	tree._refresh()
	eq(data_section.get_first_child(), first, "the row itself is the one that was already there")
	eq(first.get_text(1), "99", "and the new value was written into it")

	case("a row carries its text where the dock runs out of room")
	eq(first.get_tooltip_text(0), "a", "a key hands back its own name")
	eq(first.get_tooltip_text(1), "99", "and the value beside it")
	eq(data_section.get_tooltip_text(0), source.HEADING_HELP["Data"], "a heading explains itself instead")

	case("a key appearing rebuilds the tree")
	stand_in.data = {&"a": "99", &"b": "2", &"c": "3", &"d": "4"}
	tree._refresh()
	eq(tree.get_root().get_first_child().get_child_count(), 4, "the extra key gets a row of its own")

	case("folding a branch away gives its space back")
	var open_height: float = tree.custom_minimum_size.y
	check(open_height > 0.0, "the tree is given a height to begin with")

	tree.get_root().get_first_child().collapsed = true
	check(tree.custom_minimum_size.y < open_height, "and a collapsed section leaves it shorter")

	stand_in.free()


func _hierarchy_and_inherited_rules_are_published() -> void:
	case("the tree is reported from whichever map is asked")
	var entity: Node = track(Node.new())
	var top: FoxAttributeMap = FoxAttributeMap.new()
	entity.add_child(top)

	var mid_holder: Node = Node.new()
	entity.add_child(mid_holder)
	var mid: FoxAttributeMap = FoxAttributeMap.new()
	mid_holder.add_child(mid)

	var low_holder: Node = Node.new()
	mid_holder.add_child(low_holder)
	var low: FoxAttributeMap = FoxAttributeMap.new()
	low_holder.add_child(low)

	eq(mid.get_parent_map(), top, "the middle map registered under the top one")
	eq(low.get_parent_map(), mid, "and the bottom map under the middle one")

	var top_path: String = String(top.get_path())
	var mid_path: String = String(mid.get_path())
	var low_path: String = String(low.get_path())

	# Depths are checked one at a time rather than against a whole dictionary. Every tracked node in
	# the suite is a sibling under /root, and _find_parent_map reads siblings, so maps left behind by
	# earlier tests turn up above this one.
	var from_low: Dictionary = low.get_hierarchy_summary()
	eq(from_low[low_path], 0, "the map asked reports itself as zero")
	eq(from_low[mid_path], -1, "the map above it as minus one")
	eq(from_low[top_path], -2, "and the one above that as minus two")

	var order: Array = from_low.keys()
	check(order.find(top_path) < order.find(mid_path), "the higher map is listed first")
	check(order.find(mid_path) < order.find(low_path), "and the chain reads downwards")

	var from_top: Dictionary = top.get_hierarchy_summary()
	eq(from_top[top_path], 0, "asking the top map puts it at zero")
	eq(from_top[mid_path], 1, "the map below it at one")
	eq(from_top[low_path], 2, "and the one below that at two")

	# Not through _new_map, which would put it in the tree and give it a path.
	var loose: FoxAttributeMap = FoxAttributeMap.new()
	eq(loose.get_hierarchy_summary().size(), 0, "a map outside the tree reports nothing")
	loose.free()

	case("an inherited rule is told apart from one added here")
	top.add_rule(FlatRule.new(&"aura", &"speed", 5.0))
	eq(top.get_inherited_rule_ids().size(), 0, "the map it was added to owns it")
	eq(mid.get_inherited_rule_ids(), [&"aura"] as Array[StringName], "the map below inherited it")
	eq(low.get_inherited_rule_ids(), [&"aura"] as Array[StringName], "and so did the one under that")

	low.add_rule(FlatRule.new(&"local", &"speed", 1.0))
	eq(low.get_inherited_rule_ids(), [&"aura"] as Array[StringName], "a rule added on the spot is left out")

	# The case object matching exists for. Adding the id below first makes the parent's copy of it
	# refused on the way down, so the two maps hold different rules under one id.
	case("an id already held here is not mistaken for the parent's")
	low.add_rule(FlatRule.new(&"dupe", &"speed", 1.0))
	top.add_rule(FlatRule.new(&"dupe", &"speed", 2.0))
	check(mid.get_inherited_rule_ids().has(&"dupe"), "the map that accepted it reports it as inherited")
	check(not low.get_inherited_rule_ids().has(&"dupe"), "the map that refused it keeps its own")


func _inspector_claims_remote_objects_too() -> void:
	case("the inspector plugin")
	var path: String = "res://addons/foxfabric/attribute_map/editor/fox_attribute_map_inspector.gd"
	var plugin: GDScript = load(path) as GDScript
	check(plugin != null, "the inspector script loads")
	if plugin == null:
		return

	check(FoxFabric.INSPECTORS.has(path), "the plugin lists it")

	var m: FoxAttributeMap = _new_map()
	check(plugin.publishes_runtime_state(m), "it claims a FoxAttributeMap")
	check(not plugin.publishes_runtime_state(track(Node.new())), "and not a plain node")
	check(not plugin.publishes_runtime_state(null), "and survives a null")

	# The case the property check exists for.
	var remote: Object = RemoteStandIn.new()
	check(plugin.publishes_runtime_state(remote), "and claims a debugger stand-in that is not a map")
	remote.free()

	# A property invented in _get_property_list has nothing for the inspector to document, so the
	# descriptions are written here instead. This fails the day one is published without one.
	case("every published property carries a description")
	var described: Dictionary = plugin.PROPERTY_HELP
	var published: Array[String] = []
	for property: Dictionary in m.get_property_list():
		var published_name: String = property["name"]
		if published_name.begins_with("runtime_"):
			published.append(published_name)

	for published_name: String in published:
		check(described.has(published_name), "%s has one" % published_name)

	eq(described.size(), published.size(), "and nothing is described that is not published")

	eq(plugin.Description.summarise({&"a": 1}), "Dictionary (size 1)", "a dictionary reports its size")
	eq(plugin.Description.summarise([1, 2] as Array), "Array (size 2)", "and an array reports its own")

	case("the read-out formats what it is given")
	var panel: GDScript = load("res://addons/foxfabric/attribute_map/editor/fox_attribute_map_panel.gd") as GDScript
	check(panel != null, "the panel script loads")
	if panel == null:
		return

	# Rows are [depth, name, value]. Depth zero is a section heading, sitting under the root.
	var rows: Array = panel._rows({&"damage": "3.0"}, {&"firepower": [&"damage"]},
			{&"swamp": &"speed"}, [&"swamp"], {&"slowed": 2}, {})

	_row_is(rows[0], 0, "Data", "1 key", "Data heads the list, saying how much is under it")
	_row_is(rows[1], 1, "damage", "3.0", "with its keys beneath and no group trailing behind them")
	_row_is(rows[2], 0, "Groups", "1 group", "then Groups")
	_row_is(rows[3], 1, "firepower", "1 key", "naming the group and counting it")
	_row_is(rows[4], 2, "damage", "", "with the keys filed under it hanging off that")
	_row_is(rows[5], 0, "Active Rules", "1 rule", "then Active Rules")
	_row_is(rows[6], 1, "swamp   (inherited)", "-> speed", "marking a rule that came from above")
	_row_is(rows[7], 0, "Flags", "1 flag", "then Flags")
	_row_is(rows[8], 1, "slowed", "x2", "with its stack count")
	_row_is(rows[9], 0, "Tree", "none", "and Tree last, empty when the map stands alone")
	eq(rows.size(), 10, "a map with no relatives adds nothing under it")

	case("a heading counts what it is holding")
	eq(panel._counted(0, "key", "keys"), "none", "nothing reads as none rather than zero")
	eq(panel._counted(1, "key", "keys"), "1 key", "one is singular")
	eq(panel._counted(4, "map", "maps"), "4 maps", "and more than one is not")

	case("the tree nests by the depths the map reports")
	var tree_rows: Array = panel._tree_rows({"/root/Tank/Attributes": -1, "/root/Tank/Turret/Attributes": 0})
	eq(tree_rows.size(), 3, "the heading and both maps")
	_row_is(tree_rows[0], 0, "Tree", "2 maps", "the section heads its own rows and counts them")
	_row_is(tree_rows[1], 1, "Tank/Attributes", "", "the map above sits under it")
	_row_is(tree_rows[2], 2, "Turret/Attributes   (this map)", "", "and this one hangs off that, marked on the name")

	eq(panel._tree_rows({"/root/Tank/Attributes": 0}).size(), 1, "a map with no relatives gets the heading and nothing under it")

	case("a value moving is not a change of shape")
	var before: Array = panel._rows({&"damage": "3.0"}, {}, {}, [], {}, {})
	check(panel._same_shape(before, panel._rows({&"damage": "9.0"}, {}, {}, [], {}, {})), "the same keys keep their shape whatever the values read")
	check(not panel._same_shape(before, panel._rows({&"armour": "3.0"}, {}, {}, [], {}, {})), "a different key does not")

	# Why the shape is compared row by row instead of through one flattened string. A key is
	# whatever the game called it, so it can carry the separators such a string needs: joining
	# "depth:name" with "|" turns one key named "a|1:b" into the same text as two keys "a" and "b".
	var one_key: Array = panel._rows({&"a|1:b": "x"}, {}, {}, [], {}, {})
	var two_keys: Array = panel._rows({&"a": "x", &"b": "y"}, {}, {}, [], {}, {})
	check(not panel._same_shape(one_key, two_keys), "a key carrying the separators is not taken for two rows")

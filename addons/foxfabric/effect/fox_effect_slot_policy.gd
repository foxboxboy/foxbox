@tool
@icon("uid://cb025en3etr6r")
class_name FoxEffectSlotPolicy
extends FoxNode
## A cap on how many distinct [FoxEffectInstance] objects a [FoxEffectManager] holds at once.
##
## [FoxEffectSlotPolicy] sits as a child of the manager it gates. Route calls through the policy rather than the
## manager and the limit applies.
## [codeblock]
## # Fighter
## # └─ Effects           (FoxEffectManager)
## #    └─ SlotPolicy     (max_slots -> 3)
##
## @onready var slots: FoxEffectSlotPolicy = $Effects/SlotPolicy
##
## slots.add_effect(haste, self)
## slots.slots_updated.connect(_refresh_buff_bar)
## [/codeblock]
## Adding to a full policy pushes the oldest instance out rather than refusing the new one.
## [br][br]
## Effects added straight through the manager are not tracked here and do not count against
## [member max_slots], so pick one route and stay on it.




#region Signals

## Emitted whenever the tracked slots change (added, removed, or refreshed).
signal slots_updated(current_slots: Array[FoxEffectInstance])

#endregion




#region Variables

## The maximum number of distinct effect instances this policy will allow.
@export var max_slots: int = 3:
	set(value):
		max_slots = value
		update_configuration_warnings()

## The internal array tracking the currently managed instances.
var slots: Array[FoxEffectInstance] = []

## Returns [code]true[/code] if the policy has reached its maximum slot capacity.
var is_full: bool:
	get: return slots.size() >= max_slots

## Returns the number of slots currently occupied.
var filled_slots: int:
	get: return slots.size()

## Returns the number of empty slots remaining.
var available_slots: int:
	get: return clampi(max_slots - slots.size(), 0, max_slots)

## The manager this policy gates. Defaults to the parent node, so a policy normally just sits
## as a child of the [FoxEffectManager] it governs.
## [br][br]
## Resolves to [code]null[/code] rather than erroring when the parent is something else. The
## cast matters: assigning an unrelated parent straight into a typed variable throws, and
## because this is an [code]@onready[/code] it throws before [method Node._ready] can guard it.
@onready var manager: FoxEffectManager = get_parent() as FoxEffectManager

#endregion




#region Built-In Virtuals

func _ready() -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		return

	if manager:
		manager.effect_removed.connect(_on_manager_effect_removed)

#endregion




#region Public API

## Attempts to add an effect via the Manager, enforcing the slot limit.
## Returns [code]true[/code] if successful.
func add_effect(effect: FoxEffect, target: Object) -> bool:
	if not manager:
		push_error("FoxEffectSlotPolicy: No FoxEffectManager parent found.")
		return false

	var instance = manager.add_effect(effect, target)
	if not instance:
		return false

	if slots.has(instance):
		slots_updated.emit(slots)
		return true

	if slots.size() >= max_slots:
		_push_out_oldest()

	slots.push_front(instance)
	slots_updated.emit(slots)

	return true


## Manually removes a tracked slot by its effect ID.
func remove_effect(effect_id: StringName) -> void:
	if not manager: return

	manager.remove_effect_by_id(effect_id)


## Clears all tracked slots and forces the Manager to purge them.
func clear_slots() -> void:
	if not manager:
		return

	# Temporarily disconnect so we don't emit a UI update for every single effect
	manager.effect_removed.disconnect(_on_manager_effect_removed)

	for i in range(slots.size() - 1, -1, -1):
		manager.remove_instance(slots[i])

	slots.clear()

	manager.effect_removed.connect(_on_manager_effect_removed)
	slots_updated.emit(slots)

#endregion




#region Private

func _on_manager_effect_removed(instance: FoxEffectInstance) -> void:
	var index = slots.find(instance)
	if index != -1:
		slots.remove_at(index)
		slots_updated.emit(slots)


func _push_out_oldest() -> void:
	var oldest = slots.pop_back()
	if oldest:
		manager.remove_instance(oldest)

#endregion




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not (get_parent() is FoxEffectManager):
		warnings.append("Parent is not a FoxEffectManager. The manager property defaults to the "
			+ "parent, so this policy will gate nothing.")

	if max_slots <= 0:
		warnings.append("Max Slots is %d, so no effect can ever be admitted." % max_slots)

	return warnings

#endregion

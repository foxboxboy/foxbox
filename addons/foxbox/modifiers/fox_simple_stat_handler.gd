# tates_lib/modules/modifiers/tate_modifier_manager.gd
extends FoxNode
#class_name FoxModifierManager

# Inner class for type-safe tracking
class ModifierInstance:
	var modifier: FoxModifier
	var time_left: float
	
	func _init(mod: FoxModifier):
		modifier = mod
		time_left = mod.duration

# Key: String (modifier_id), Value: ModifierInstance
var active_modifiers: Dictionary = {}


func _process(delta: float) -> void:
	_tick_modifiers(delta)


## The generic entry point for adding logic to a target
func add_modifier(mod: FoxModifier, target: Node) -> void:
	# 1. UNIQUE: Refresh timer, don't re-run code
	if mod.stack_mode == FoxModifier.StackMode.UNIQUE and active_modifiers.has(mod.modifier_id):
		active_modifiers[mod.modifier_id].time_left = mod.duration
		return

	# 2. ADDITIVE: Call a special function on the existing mod
	if mod.stack_mode == FoxModifier.StackMode.ADDITIVE and active_modifiers.has(mod.modifier_id):
		var inst = active_modifiers[mod.modifier_id]
		inst.time_left = mod.duration # Reset timer
		inst.modifier.on_reapply(target) # Custom project logic for 'powering up'
		return


	# 3. STACKING: Just add it as a new unique instance
	var instance = ModifierInstance.new(mod)
	# Use a unique key so we don't overwrite the dictionary entry
	var key = mod.modifier_id if mod.stack_mode == FoxModifier.StackMode.UNIQUE else str(mod.modifier_id, "_", Time.get_ticks_msec())

	active_modifiers[key] = instance
	mod.execute(target)


func _tick_modifiers(delta: float) -> void:
	var expired_keys: Array[String] = []
	for key in active_modifiers:
		var inst = active_modifiers[key]
		if inst.modifier.duration > 0: # -1 is permanent
			inst.time_left -= delta
			if inst.time_left <= 0:
				expired_keys.append(key)
	
	for key in expired_keys:
		remove_modifier(key)


func remove_modifier(key: String) -> void:
	if active_modifiers.has(key):
		# We pass a null or the target? Usually, the Modifier needs the target to undo.
		# For simplicity, we'll assume the Modifier handles its own cleanup via target ref.
		active_modifiers.erase(key)

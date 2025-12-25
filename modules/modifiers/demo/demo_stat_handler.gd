extends Node
class_name UnitStatHandler

signal speed_stat_value_changed(new_value)
signal damage_stat_changed(new_value)

@export var health_component : Node

# --- 1. Library Math Resources ---
# These would ideally be exported or initialized via a UnitProfile resource
var damage_stat: TateModifiableStat
var speed_stat: TateModifiableStat

# --- 2. Effect Management Logic ---
# Inner class for type-safe tracking of active effects
class EffectInstance:
	var effect: TateModifier
	var time_left: float
	
	func _init(e: TateModifier):
		effect = e
		time_left = e.duration

# Dictionary to store active instances. Key: String ID, Value: EffectInstance
var active_effects: Dictionary[String, EffectInstance] = {}

func _init() -> void:
	# Initialize our Atomic stats
	speed_stat = TateModifiableStat.new(5.0)
	damage_stat = TateModifiableStat.new(9.0)


func _ready() -> void:
	speed_stat.value_changed.connect(_on_speed_stat_value_changed)


func _process(delta: float) -> void:
	_tick_effects(delta)

# --- 3. The Effect Policy API ---

func apply_effect(effect_res: TateModifier) -> void:
	print("Applying effect: ",effect_res.effect_id)
	match effect_res.stack_mode:
		TateModifier.StackMode.UNIQUE:
			_handle_unique(effect_res)
		TateModifier.StackMode.STACKING:
			_handle_stacking(effect_res)
		TateModifier.StackMode.ADDITIVE:
			_handle_additive(effect_res)


func clear_all_effects() -> void:
	active_effects.clear()
	
	speed_stat.clear_all_modifiers()
	damage_stat.clear_all_modifiers()


func _handle_unique(e: TateModifier) -> void:
	# If it exists, reset the timer. If not, create and execute.
	if active_effects.has(e.effect_id):
		active_effects[e.effect_id].time_left = e.duration
	else:
		_add_new_instance(e.effect_id, e)

func _handle_stacking(e: TateModifier) -> void:
	# Create a key for this specific stack
	var stack_id = e.effect_id + "_" + str(Time.get_ticks_msec())
	_add_new_instance(stack_id, e)

func _handle_additive(e: TateModifier) -> void:
	# Add the duration to the existing effect timer
	if active_effects.has(e.effect_id):
		active_effects[e.effect_id].time_left += e.duration
	else:
		_add_new_instance(e.effect_id, e)

func _add_new_instance(key: String, e: TateModifier) -> void:
	active_effects[key] = EffectInstance.new(e)
	
	#var effect_instance : EffectInstance = active_effects[key]
	
	e.execute(self.owner) # Pass the character body to the effect

# --- 4. Cleanup Logic ---

func _tick_effects(delta: float) -> void:
	var expired_keys: Array[String] = []
	
	for id in active_effects:
		var instance = active_effects[id]
		# -1 indicates a permanent effect that doesn't tick down
		if instance.effect.duration > 0:
			instance.time_left -= delta
			if instance.time_left <= 0:
				expired_keys.append(id)
	
	for id in expired_keys:
		var instance = active_effects[id]
		instance.effect.remove(self.owner) # Undo modifiers/logic
		active_effects.erase(id)


func _on_speed_stat_value_changed(new_value : float):
	speed_stat_value_changed.emit(new_value)

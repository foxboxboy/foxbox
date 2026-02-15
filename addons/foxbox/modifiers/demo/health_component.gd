# demo/traits/demo/health_component.gd
extends Node

# --- 1. The Resources ---
var max_health: FoxModifiableStat
var current_health: FoxBoundedValue

# --- 2. Setup ---
func _init() -> void:
	# We define the 'Math' layer
	max_health = FoxModifiableStat.new(100.0)
	
	# We define the 'State' layer
	current_health = FoxBoundedValue.new(max_health.value)
	
	# --- 3. The Bridge logic ---
	# Whenever a trait or upgrade changes the 'Stat' value...
	max_health.value_changed.connect(func(new_max):
		# ...update the 'Resource' limit to match.
		current_health.max_limit = new_max
	)

# --- 4. The API ---
func damage(amount: float) -> void:
	current_health.subtract(amount)

func heal(amount: float) -> void:
	current_health.add(amount)

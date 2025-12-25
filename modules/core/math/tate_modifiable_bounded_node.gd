# modules/core/math/tate_modifiable_bounded_node.gd
extends TateComponent
class_name TateModifiableBoundedNode

signal updated(current: float, max_val: float)
signal depleted(underflow: float)

## The starting point for Max Health/Fuel/etc. Set this in the Inspector.
@export var base_max: float = 1.0:
	set(v):
		base_max = v
		if max_stat: # Update the engine if it already exists
			max_stat.base_value = v

## Math Engines (Internal Resources)
var max_stat: TateModifiableStat
var pool: TateBoundedValue

## API: Shortcut to get/set current level (e.g., health_node.current = 50)
var current: float:
	get: return pool.value
	set(v): pool.value = v

## API: Shortcut to get/set base max (useful for permanent logic)
var base: float:
	get: return max_stat.base_value
	set(v): max_stat.base_value = v

func _ready() -> void:
	# Initialize engines here so base_max from the Inspector is ready
	max_stat = TateModifiableStat.new(base_max)
	pool = TateBoundedValue.new(base_max, base_max, 0.0)
	
	# Connect internal engines to the Node signals
	max_stat.value_changed.connect(_on_max_stat_changed)
	pool.value_changed.connect(_on_pool_changed)
	pool.depleted.connect(func(u): depleted.emit(u))
	
	# Initial sync
	updated.emit(pool.value, max_stat.value)

func _on_max_stat_changed(new_max: float) -> void:
	pool.max_value = new_max
	# If current health was at 100/100 and max becomes 105, 
	# usually you want to heal the difference too:
	pool.value = clamp(pool.value, 0, new_max)
	#updated.emit(pool.value, new_max)

func _on_pool_changed(curr: float, _min: float, _max: float) -> void:
	updated.emit(curr, max_stat.value)
	
# --- Public API ---
func subtract(amt: float) -> void: pool.subtract(amt)
func add(amt: float) -> void:      pool.add(amt)
func get_percent() -> float:       return pool.value / max_stat.value

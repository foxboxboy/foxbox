class_name FoxStatPool
extends Node
## Glues a FoxModifiableStat and a FoxBoundedValue together.

signal updated(current: float, max_value: float)
signal depleted(underflow: float)
signal saturated(overflow: float)

## The starting point for Max Health/Fuel/etc. Set this in the Inspector.
@export var base_max: float = 100.0:
	set(v):
		base_max = v
		if _max_stat: 
			_max_stat.base_value = v

# Internal Math Engines
var _max_stat: FoxModifiableStat
var _pool: FoxBoundedValue





#region Public API

## Exposes the max_stat engine so external scripts can apply buffs/debuffs to it.
var max_stat: FoxModifiableStat:
	get: return _max_stat

## Shortcut to get/set current level (e.g., health_node.current = 50)
var current: float:
	get: return _pool.value
	set(v): _pool.value = v

func subtract(amount: float) -> void: 
	_pool.subtract(amount)

func add(amount: float) -> void:      
	_pool.add(amount)

func get_percent() -> float:
	if _max_stat.value == 0: return 0.0
	return _pool.value / _max_stat.value

#endregion





#region Internal Logic

func _ready() -> void:
	# Initialize engines
	_max_stat = FoxModifiableStat.new(base_max)
	_pool = FoxBoundedValue.new(base_max, base_max, 0.0)
	
	# Connect internal engines to the Node signals
	_max_stat.value_changed.connect(_on_max_stat_changed)
	_pool.value_changed.connect(_on_pool_changed)
	
	# Bubble up the overflow/underflow signals
	_pool.depleted.connect(func(u): depleted.emit(u))
	_pool.saturated.connect(func(o): saturated.emit(o))
	
	# Initial sync for UI
	updated.emit(_pool.value, _max_stat.value)

func _on_max_stat_changed(new_max: float) -> void:
	_pool.max_value = new_max
	# Note: If max health drops from 100 to 50, FoxBoundedValue will automatically 
	# clamp the current health down to 50 and fire the updated signal for us

func _on_pool_changed(curr: float, _min: float, _max: float) -> void:
	updated.emit(curr, _max_stat.value)

#endregion

# tates_lib/logic/tate_modifiable_bounded_node.gd
extends TateComponent
class_name TateModifiableBoundedNode
## The physical "address" for a value that is both modifiable and depletable.

signal updated(current: float, max_val: float)
signal depleted

@export var base_max: float = 1.0

## The "Math Engines" (Resources)
var max_stat: TateModifiableStat
var pool: TateBoundedValue

var value: float:
	get: return pool.value
	set(v): pool.value = v

var max_value: float:
	get: return max_stat.value

func _init() -> void:
	# 1. Create the engines
	max_stat = TateModifiableStat.new(base_max)
	pool = TateBoundedValue.new(0, base_max, base_max)
	
	# 2. Bind the engines to each other
	max_stat.value_changed.connect(_on_max_changed)
	pool.value_changed.connect(func(c, m): updated.emit(c, m))
	pool.depleted.connect(func(): depleted.emit())

func _on_max_changed(new_max: float) -> void:
	# Update the limit of the pool
	pool.max_value = new_max
	# Keep current value from 'overflowing' the new max
	pool.value = clamp(pool.value, 0, new_max)
	updated.emit(pool.value, new_max)

## Public API (The 'Address' for damage and upgrades)
func subtract(amt: float): pool.subtract(amt)
func add(amt: float):      pool.add(amt)
func get_current() -> float: return pool.value
func get_max() -> float:     return max_stat.value

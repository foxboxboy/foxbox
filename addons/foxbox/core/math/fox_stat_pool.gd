@icon("uid://c8ciwhnmnalem")
class_name FoxStatPool
extends FoxResource
## A resource that manages a dynamic value bounded by a modifiable maximum capacity.
##
## Combines a [FoxModifiableStat] for the maximum bound and a [FoxBoundedValue] for the current pool.
## [br][b]Note:[/b] Ensure [member Resource.resource_local_to_scene] is enabled when assigning to multiple instances to prevent shared state.





#region Signals

## Emitted when [member current] or the maximum capacity changes.
signal updated(current: float, max_value: float)

## Emitted when [member current] falls below 0.0. 
## [param underflow] contains the absolute value of the excess.
signal depleted(underflow: float)

## Emitted when [member current] exceeds the maximum capacity.
## [param overflow] contains the excess amount.
signal saturated(overflow: float)

#endregion





#region Variables

## The initial, unmodified maximum capacity.
@export var base_max: float = 100.0:
	set(v):
		if v < 0.0:
			push_warning("FoxStatPool: base_max was set to a negative number (%s). Did you mean to do this?" % v)
		base_max = v
		if _max_stat: 
			_max_stat.base_value = v

var _max_stat: FoxModifiableStat
var _pool: FoxBoundedValue

#endregion





#region Public API

## The current calculated maximum capacity, including all active modifiers.
var max_value: float:
	get: return _max_stat.value


## The current value of the pool. Automatically clamped by the minimum and maximum bounds.
var current: float:
	get: return _pool.value
	set(v): _pool.value = v


## Decreases [member current] by [param amount].
func subtract(amount: float) -> void: 
	_pool.subtract(amount)


## Increases [member current] by [param amount].
func add(amount: float) -> void:      
	_pool.add(amount)


## Returns the ratio of [member current] to [member max_value] as a value between 0.0 and 1.0.
func get_percent() -> float:
	if _max_stat.value == 0: return 0.0
	return _pool.value / _max_stat.value


## Adds a modifier to the maximum capacity.
func add_max_modifier(id: StringName, type: FoxModifiableStat.ModifierType, amount: float) -> void:
	_max_stat.add_modifier(id, type, amount)


## Removes the most recent modifier from the maximum capacity stack.
func pop_max_modifier(id: StringName, type: FoxModifiableStat.ModifierType) -> bool:
	return _max_stat.pop_modifier(id, type)


## Instantly removes all modifiers matching the given [param id] and [param type] from the maximum capacity.
func clear_max_modifier(id: StringName, type: FoxModifiableStat.ModifierType) -> void:
	_max_stat.clear_modifier(id, type)


## Removes all modifiers, returning the maximum capacity to [member base_max].
func clear_all_max_modifiers() -> void:
	_max_stat.clear_all_modifiers()

#endregion





#region Private Logic

func _init() -> void:
	_max_stat = FoxModifiableStat.new(base_max)
	_pool = FoxBoundedValue.new(base_max, base_max, 0.0)
	
	_max_stat.value_changed.connect(_on_max_stat_changed)
	_pool.value_changed.connect(_on_pool_changed)
	
	_pool.depleted.connect(func(u): depleted.emit(u))
	_pool.saturated.connect(func(o): saturated.emit(o))
	
	updated.emit(_pool.value, _max_stat.value)


func _on_max_stat_changed(new_max: float) -> void:
	_pool.max_value = new_max


func _on_pool_changed(curr: float, _min: float, _max: float) -> void:
	updated.emit(curr, _max_stat.value)

#endregion

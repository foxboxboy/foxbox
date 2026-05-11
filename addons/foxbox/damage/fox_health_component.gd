class_name FoxHealthComponent
extends Node
## Manages health math using a [FoxBoundedValue] resource.
##
## Acts as a scene-tree wrapper for pure mathematical health data.
## It isolates the logic of taking damage and healing from the physical 
## representation of the character, translating mathematical bounds 
## into semantic gameplay signals.



#region Signals

## Emitted whenever the health value changes.
signal health_changed(current: float, maximum: float)

## Emitted when the health pool falls below its minimum value. 
## [param overkill_amount] provides the absolute difference.
signal died(overkill_amount: float)

## Emitted when healing exceeds the maximum bounds. 
## [param amount] provides the absolute difference.
signal overhealed(amount: float)

#endregion



#region Variables

## The underlying math resource. If null, a new [FoxBoundedValue] 
## is created automatically during [method _ready].
@export var health_pool: FoxBoundedValue

#endregion



#region Virtual Methods

func _ready() -> void:
	if health_pool == null:
		health_pool = FoxBoundedValue.new()
	
	health_pool.value_changed.connect(_on_pool_value_changed)
	health_pool.depleted.connect(_on_pool_depleted)
	health_pool.saturated.connect(_on_pool_saturated)

#endregion



#region Public API

## Decreases the current health by [param amount], clamped by the minimum value.
func take_damage(amount: float) -> void:
	health_pool.subtract(amount)

## Increases the current health by [param amount], clamped by the maximum value.
func heal(amount: float) -> void:
	health_pool.add(amount)

## Returns the current value of the underlying [member health_pool].
func get_current() -> float:
	return health_pool.value

## Returns the maximum capacity of the underlying [member health_pool].
func get_max() -> float:
	return health_pool.max_value

#endregion



#region Private Signal Handlers

func _on_pool_value_changed(current: float, max_val: float, _min_val: float) -> void:
	health_changed.emit(current, max_val)

func _on_pool_depleted(underflow: float) -> void:
	died.emit(underflow)

func _on_pool_saturated(overflow: float) -> void:
	overhealed.emit(overflow)

#endregion

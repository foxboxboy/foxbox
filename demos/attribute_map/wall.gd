# The wall being shot at. It holds no attribute map; it only takes what it is handed, which is how
# the damage numbers turn into something you can watch.
extends Node2D


#region Variables

@export var starting_health: float = 600.0

## Drawn from full down to nothing as the health goes.
@export var bar: Polygon2D
@export var bar_size: Vector2 = Vector2(240.0, 220.0)

## A FoxBoundedValue rather than a float, so the wall cannot be shot past dead and this does not
## have to remember to clamp on every hit.
var _health: FoxBoundedValue

#endregion


#region Built-In Virtuals

func _ready() -> void:
	_health = FoxBoundedValue.new(starting_health, starting_health, 0.0)
	_health.value_changed.connect(_on_health_changed)
	_redraw()

#endregion


#region Public API

func take_damage(amount: float) -> void:
	_health.subtract(amount)


func reset() -> void:
	_health.value = starting_health


func get_health() -> float:
	return _health.value

#endregion


#region Private

func _on_health_changed(_current: float, _min: float, _max: float) -> void:
	_redraw()


## Drains from the top down, so the bar reads as a wall being chewed away.
func _redraw() -> void:
	var height: float = bar_size.y * (_health.value / starting_health)
	var top: float = bar_size.y - height
	bar.polygon = PackedVector2Array([
		Vector2(0.0, top),
		Vector2(bar_size.x, top),
		Vector2(bar_size.x, bar_size.y),
		Vector2(0.0, bar_size.y),
	])

#endregion

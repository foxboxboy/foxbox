# The wall being shot at. It holds no attribute map; it only takes what it is handed, which is how
# the damage numbers turn into something you can watch.
extends Node2D


#region Variables

@export var max_health: float = 600.0

## Drawn from full width down to nothing as the health goes.
@export var bar: Polygon2D
@export var bar_size: Vector2 = Vector2(240.0, 220.0)

var health: float = 0.0

#endregion


#region Built-In Virtuals

func _ready() -> void:
	reset()

#endregion


#region Public API

func take_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	_redraw()


func reset() -> void:
	health = max_health
	_redraw()

#endregion


#region Private

## Drains from the top down, so the bar reads as a wall being chewed away.
func _redraw() -> void:
	var height: float = bar_size.y * (health / max_health)
	var top: float = bar_size.y - height
	bar.polygon = PackedVector2Array([
		Vector2(0.0, top),
		Vector2(bar_size.x, top),
		Vector2(bar_size.x, bar_size.y),
		Vector2(0.0, bar_size.y),
	])

#endregion

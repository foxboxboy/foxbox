# tates_lib/modules/occupancy/tate_occupancy_component.gd
extends TateComponent
class_name TateOccupancyComponent

## Emitted when someone enters a seat.
signal occupant_entered(unit: Node, role: String)
## Emitted when a seat is vacated.
signal occupant_exited(unit: Node, role: String)


var seats: Array[TateSeat] = []


func _ready() -> void:
	for child in get_children():
		if child is TateSeat:
			seats.append(child)
			child.occupant_left.connect(_on_seat_occupant_left)

func get_available_seat_count() -> int:
	return seats.filter(func(s): return s.occupant == null).size()

func try_sit(node: Node) -> bool:
	for seat in seats:
		if seat.occupant == null:
			seat.sit(node)
			occupant_entered.emit(node, seat.role_id)
			return true
	return false

func _on_seat_occupant_left(occupant : Node, seat : TateSeat):
	occupant_exited.emit(occupant, seat.role_id)

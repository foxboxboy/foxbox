# tates_lib/modules/occupancy/tate_occupancy_component.gd
extends TateNode
class_name TateOccupancyComponent

## Emitted when someone enters a seat.
signal occupant_entered(occupant: Node, seat: TateSeat)
## Emitted when a seat is vacated.
signal occupant_exited(occupant: Node, seat: TateSeat)


var seats: Array[TateSeat] = []


func _ready() -> void:
	for child in get_children():
		if child is TateSeat:
			seats.append(child)
			child.occupant_left.connect(_on_seat_occupant_left)


## Returns how many seats are available.
func get_available_seat_count() -> int:
	return seats.filter(func(s): return s.occupant == null).size()


## Returns true if a node could be sat.
## Returns false if an empty seat couldn't be found. 
## Tries make a node sit to the first available seat it can find.
func try_sit(node: Node) -> bool:
	for seat in seats:
		if seat.occupant == null:
			seat.sit(node)
			occupant_entered.emit(node, seat.role_id)
			return true
	return false


func _on_seat_occupant_left(occupant : Node, seat : TateSeat):
	occupant_exited.emit(occupant, seat)

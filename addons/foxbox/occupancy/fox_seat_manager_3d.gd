extends FoxNode3D
class_name FoxSeatManager3D
## Manages a collection of FoxSeat3D nodes.

signal occupant_entered(occupant: Node3D, seat: FoxSeat3D)
signal occupant_exited(occupant: Node3D, seat: FoxSeat3D)

var seats: Array[FoxSeat3D] = []


func _ready() -> void:
	# Recursively find all seats
	for child in find_children("*", "FoxSeat3D", true, false):
		seats.append(child)
		child.occupant_left.connect(_on_seat_occupant_left)


## Returns how many seats are currently empty.
func get_available_seat_count() -> int:
	var count: int = 0
	for seat in seats:
		if seat.is_empty():
			count += 1
	return count


## Attempts to assign a node to the first available empty seat.
## Returns true if successful, false if all seats are full.
func try_sit(node: Node3D) -> bool:
	for seat in seats:
		if seat.is_empty():
			seat.sit(node)
			occupant_entered.emit(node, seat)
			return true
			
	return false


func _on_seat_occupant_left(occupant: Node3D, seat: FoxSeat3D) -> void:
	occupant_exited.emit(occupant, seat)

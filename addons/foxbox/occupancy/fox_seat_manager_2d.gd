extends FoxNode2D
class_name FoxSeatManager2D
## Manages a collection of FoxSeat2D nodes.

signal occupant_entered(occupant: Node2D, seat: FoxSeat2D)
signal occupant_exited(occupant: Node2D, seat: FoxSeat2D)

var seats: Array[FoxSeat2D] = []


func _ready() -> void:
	# Recursively find all seats
	for child in find_children("*", "FoxSeat2D", true, false):
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
func try_sit(node: Node2D) -> bool:
	for seat in seats:
		if seat.is_empty():
			seat.sit(node)
			occupant_entered.emit(node, seat)
			return true
			
	return false


func _on_seat_occupant_left(occupant: Node2D, seat: FoxSeat2D) -> void:
	occupant_exited.emit(occupant, seat)

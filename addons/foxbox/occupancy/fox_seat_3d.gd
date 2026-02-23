extends Marker3D
class_name FoxSeat3D
## A physical 3D location that reparents and holds a single occupant.

## Emitted when this FoxSeat3D gains a new occupant.
signal occupant_sat(occupant : Node3D, seat : FoxSeat3D)
## Emitted when the occupant leaves and is no longer a child.
signal occupant_left(occupant : Node3D, seat : FoxSeat3D)
## Emitted when the child order changes.
signal occupant_changed(occupant : Node3D, seat : FoxSeat3D)

## (Optional) The node that will be used for position
## and rotation. Leave blank to make this the marker. 
@export var marker : Node3D

## The child occupant currently sitting in this seat.
var occupant: Node3D = null


func _ready() -> void:
	child_order_changed.connect(_occupant_changed)
	
	if marker == null:
		marker = self


## Returns true if there is no occupant. 
func is_empty() -> bool:
	return occupant == null


## Returns the current occupant.
func get_occupant() -> Node3D:
	return occupant


## Reparents a node to become this seat's occupant and snaps its transform.
func sit(new_occupant: Node3D) -> void:
	if not is_empty():
		push_error("ERROR: FoxSeat3D already has an occupant! ", new_occupant, " ", get_path())
		return
	
	occupant = new_occupant
	new_occupant.reparent(self)
	
	new_occupant.global_position = marker.global_position
	new_occupant.global_rotation = marker.global_rotation
	
	occupant_sat.emit(new_occupant, self)


## Safely removes the occupant from the seat. Returns the occupant.
## Note this does not reparent the occupant anywhere.
func eject() -> Node3D:
	if is_empty(): 
		return null
		
	var ejected_occupant = occupant
	occupant = null
	occupant_left.emit(ejected_occupant, self)
	
	return ejected_occupant


func _occupant_changed():
	occupant_changed.emit(occupant, self)
	
	if not is_instance_valid(occupant) or occupant.get_parent() != self:
		if is_instance_valid(occupant):
			occupant_left.emit(occupant, self)
		occupant = null

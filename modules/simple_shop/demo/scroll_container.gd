extends ScrollContainer
## This is just for the shop demo. 
## It lets a mouse ignore a scroll container if the
## description isn't long enough to be scrolled.

@export var label : Label

func _ready():
	await get_tree().process_frame
	update_mouse_filter()

func update_mouse_filter():
	if label.size.y <= self.size.y:
		self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		self.mouse_filter = Control.MOUSE_FILTER_STOP

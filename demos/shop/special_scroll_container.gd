extends ScrollContainer

@export var label : Label

func _ready():
	await get_tree().process_frame
	update_mouse_filter()

func update_mouse_filter():
	if label.size.y <= self.size.y:
		self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		self.mouse_filter = Control.MOUSE_FILTER_STOP

extends SubViewportContainer

@onready var sub_viewport: SubViewport = $SubViewport


func _ready() -> void:
	get_viewport().size_changed.connect(_viewport_size_changed)


func _viewport_size_changed() -> void:
	
	sub_viewport.size = get_viewport_rect().size

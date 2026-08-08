extends SubViewportContainer
## Keeps a [SubViewport] matched to the size of the main viewport.
##
## Used to render first person view models in a layer separate from the world, so held items
## never clip into nearby geometry. Put a camera and the view model inside the [SubViewport]
## child, and keep its field of view in sync with the world camera yourself.

## The child viewport that gets resized. Expected to be a direct child named [code]SubViewport[/code].
@onready var sub_viewport: SubViewport = $SubViewport


func _ready() -> void:
	get_viewport().size_changed.connect(_viewport_size_changed)


func _viewport_size_changed() -> void:

	sub_viewport.size = get_viewport_rect().size

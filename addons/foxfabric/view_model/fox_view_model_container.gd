class_name FoxViewModelContainer
extends SubViewportContainer
## A [SubViewport] container kept matched to the size of the main viewport.
##
## [FoxViewModelContainer] renders first person view models in a layer separate from the world, so held items
## never clip into nearby geometry. Put a camera and the view model inside the [SubViewport]
## child, and keep its field of view in sync with the world camera yourself.
##
## @experimental: Shelved. It works, but it is not being developed and nothing else in the
## library uses it. Expect it to change or move to deprecated.

## The child viewport that gets resized. Expected to be a direct child named [SubViewport].
@onready var sub_viewport: SubViewport = $SubViewport


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:

	sub_viewport.size = get_viewport_rect().size

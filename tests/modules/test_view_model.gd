extends "res://tests/fox_test.gd"
## Checks that the container keeps its viewport matched to the main one.
##
## The module is shelved and marked experimental. It has one behaviour, so this covers that one
## and nothing more, mostly so a change to it does not go unnoticed.


func run() -> void:
	suite = "view_model"
	_matches_the_main_viewport()


func _matches_the_main_viewport() -> void:
	case("resizing")
	var container: FoxViewModelContainer = FoxViewModelContainer.new()
	var inner: SubViewport = SubViewport.new()

	# The @onready in the container looks for this exact name, so the child has to exist and be
	# named before the container enters the tree.
	inner.name = "SubViewport"
	container.add_child(inner)
	track(container)

	check(container.sub_viewport == inner, "the expected child is picked up")

	inner.size = Vector2i(1, 1)
	container._on_viewport_size_changed()

	var expected: Vector2i = Vector2i(container.get_viewport_rect().size)
	eq(inner.size, expected, "the sub viewport takes the main viewport's size")
	check(expected.x > 1 and expected.y > 1, "and that size is a real one, not the stub")

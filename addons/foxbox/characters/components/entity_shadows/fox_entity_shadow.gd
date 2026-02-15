extends FoxNode3D
class_name FoxEntityShadow


@export var shadow_type := ShadowQuality.DISABLED:
	set = _set_shadow_quality

@export_group("Settings")

@export var shadow_advanced_scene: PackedScene
@export var shadow_simple_scene: PackedScene

@export var shadow_simple_y_offset : float = 0.025
@export var shadow_decal_y_offset : float = -0.975

enum ShadowQuality{
	## No shadow will be shown under this character.
	DISABLED,
	## A simple mesh instance with a black circle will
	## be shown. 
	SIMPLE,
	## A more advanced decal will be used to draw the
	## shadow.
	DECAL,
}

var shadow: Node


func _set_shadow_quality(new_shadow_quality : ShadowQuality) -> void:
	if not is_inside_tree():
		_set_shadow_quality.call_deferred(new_shadow_quality)
		return

	shadow_type = new_shadow_quality
	
	if shadow:
		shadow.queue_free()
	
	if shadow_type == ShadowQuality.SIMPLE:
		assert(shadow_simple_scene != null, "ERROR: No shadow_simple_scene assigned")
		
		shadow = shadow_simple_scene.instantiate()
		shadow.position.y = shadow_simple_y_offset
		add_child(shadow)
	
	if shadow_type == ShadowQuality.DECAL:
		assert(shadow_advanced_scene != null, "ERROR: No shadow_advanced_scene assigned")
		
		shadow = shadow_advanced_scene.instantiate()
		shadow.position.y = shadow_decal_y_offset
		add_child(shadow)

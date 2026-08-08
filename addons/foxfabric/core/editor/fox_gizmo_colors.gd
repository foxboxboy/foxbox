@tool
extends RefCounted
## Editor Settings plumbing shared by the FoxFabric gizmos.
##
## Registers one colour per gizmo material under [code]foxfabric/gizmo_colors/[/code], builds the
## materials from whatever the user has chosen, and keeps them in step afterwards.
## [br][br]
## Two limits here are not worth fighting. A custom editor setting cannot carry a description,
## and it only appears with Advanced turned on. Both follow from
## [method EditorSettings.add_property_info] taking a name, a type and a hint and nothing else,
## and "basic" being a usage flag it refuses.
## [br][br]
## Deliberately has no [code]class_name[/code]. It is editor only plumbing and does not belong
## in the class reference.


## Where these settings sit. Under the library's own category rather than the engine's
## [code]editors/3d_gizmos/[/code], so they stay together as more gizmos arrive.
const PREFIX: String = "foxfabric/gizmo_colors/"


## Registers [param colors] as editor settings and creates the matching materials on
## [param plugin]. Keys are material names, values are the default colour.
static func install(plugin: EditorNode3DGizmoPlugin, colors: Dictionary) -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()

	for key: String in colors:
		var fallback: Color = colors[key]

		if settings == null:
			plugin.create_material(key, fallback)
			continue

		var path: String = PREFIX + key
		if not settings.has_setting(path):
			settings.set_setting(path, fallback)

		settings.set_initial_value(path, fallback, false)
		settings.add_property_info({"name": path, "type": TYPE_COLOR})
		plugin.create_material(key, settings.get_setting(path))


## Pushes the current setting values back into the materials, so recolouring a gizmo takes
## effect without an editor restart. Connect this to [signal EditorSettings.settings_changed].
static func refresh(plugin: EditorNode3DGizmoPlugin, colors: Dictionary) -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings == null:
		return

	for key: String in colors:
		var material: StandardMaterial3D = plugin.get_material(key) as StandardMaterial3D
		if material != null:
			material.albedo_color = settings.get_setting(PREFIX + key)


## Connects [param handler] to the settings changing, once.
static func watch(handler: Callable) -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings != null and not settings.settings_changed.is_connected(handler):
		settings.settings_changed.connect(handler)


## Removes settings from an earlier layout so they do not linger in the editor forever.
static func retire(paths: Array[String]) -> void:
	var settings: EditorSettings = EditorInterface.get_editor_settings()
	if settings == null:
		return

	for path: String in paths:
		if settings.has_setting(path):
			settings.erase(path)

class_name FoxShopItem
extends FoxResource

@export_group("Display")
@export var display_name: StringName
@export var icon: Texture2D
@export_multiline var description: String

@export_group("Transaction")
@export var price: FoxPrice
@export var product: Resource

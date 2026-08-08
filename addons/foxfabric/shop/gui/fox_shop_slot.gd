@icon("uid://besavad4akvy")
class_name FoxShopSlot
extends FoxControl
## A UI component representing a single purchasable item.
##
## Connects internal UI nodes to an item resource and visually updates based on affordability.

@export_group("Components")

## The core interactable [Button] the user presses to initiate a purchase.
@export var buy_button: Button

## The [TextureRect] used to display the item's icon.
@export var icon_rect: TextureRect

## The [Label] used to display the item's name.
@export var name_label: Label

## The [Label] used to display the item's formatted cost string.
@export var cost_label: Label

## The [Label] used to display the item's description.
@export var description_label: Label

@export_group("Visual Settings")

## The [Color] applied when the item can be afforded.
@export var affordable_color: Color = Color.WHITE

## The [Color] applied when the item cannot be afforded.
@export var unaffordable_color: Color = Color(0.5, 0.5, 0.5, 1.0)

## The [Color] applied to the [member cost_label] when the item can be afforded.
@export var cost_positive_color: Color = Color.GREEN

## The [Color] applied to the [member cost_label] when the item cannot be afforded.
@export var cost_negative_color: Color = Color.RED

## The data resource currently driving this slot's display.
var data: FoxShopItem


#region Signals

## Emitted when the user presses the buy button.
signal buy_button_pressed(item: FoxShopItem)

## Emitted when the user hovers or focuses the buy button.
signal buy_button_focused(item: FoxShopItem)

## Emitted when the user unhovers or unfocuses the buy button.
signal buy_button_unfocused(item: FoxShopItem)

#endregion


#region Public API

## Populates the internal UI nodes with data from the provided [param item_data].
func setup(item_data: FoxShopItem) -> void:
	data = item_data
	
	if name_label: name_label.text = str(data.display_name)
	if icon_rect: icon_rect.texture = data.icon
	if description_label: description_label.text = data.description
	
	if cost_label:
		cost_label.text = data.price.get_display_string() if data.price else "Free"


## Visually updates the slot based on the [param can_afford] state.
func set_affordability(can_afford: bool) -> void:
	if buy_button:
		buy_button.disabled = not can_afford
		
	modulate = affordable_color if can_afford else unaffordable_color
	
	if cost_label:
		cost_label.modulate = cost_positive_color if can_afford else cost_negative_color

#endregion


#region Private

func _ready() -> void:
	if buy_button:
		buy_button.pressed.connect(func(): buy_button_pressed.emit(data))
		buy_button.focus_entered.connect(_on_buy_button_focus_entered)
		buy_button.focus_exited.connect(_on_buy_button_focus_exited)
		buy_button.mouse_entered.connect(_on_buy_button_focus_entered)
		buy_button.mouse_exited.connect(_on_buy_button_focus_exited)


func _on_buy_button_focus_entered() -> void:
	buy_button_focused.emit(data)


func _on_buy_button_focus_exited() -> void:
	buy_button_unfocused.emit(data)

#endregion

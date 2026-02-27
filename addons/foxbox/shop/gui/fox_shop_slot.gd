class_name FoxShopSlot
extends FoxControl
## A single visual UI card representing a [FoxShopItem].


#region Signals

## Emitted when the [member buy_button] is pressed.
signal buy_button_pressed(item: FoxShopItem)

## Emitted when the [member buy_button] gains focus or the mouse enters the slot.
signal buy_button_focused(item: FoxShopItem)

## Emitted when the [member buy_button] loses focus or the mouse leaves the slot.
signal buy_button_unfocused(item: FoxShopItem)

#endregion


#region Variables

@export_group("Components")

## The interactable [Button] that triggers the purchase logic and handles UI focus.
@export var buy_button: Button
## The [TextureRect] that displays the [member FoxShopItem.icon].
@export var icon_rect: TextureRect
## The [Label] that displays the [member FoxShopItem.display_name].
@export var name_label: Label
## The [Label] that displays the formatted cost string from the item's [FoxPrice].
@export var cost_label: Label
## The [Label] that displays the [member FoxShopItem.description].
@export var description_label: Label


@export_group("Visual Settings")
## The modulation color applied when the item is affordable.
@export var affordable_color: Color = Color.WHITE
## The modulation color applied when the item is too expensive.
@export var unaffordable_color: Color = Color(0.5, 0.5, 0.5, 1.0)
## The color of the [member cost_label] when the player has enough funds.
@export var cost_positive_color: Color = Color.GREEN
## The color of the [member cost_label] when the player lacks funds.
@export var cost_negative_color: Color = Color.RED

## The data resource currently bound to this UI slot.
var data: FoxShopItem

#endregion


#region Public API

## Initializes the slot with data from a [FoxShopItem].
func setup(item_data: FoxShopItem) -> void:
	data = item_data
	
	if name_label: name_label.text = str(data.display_name)
	if icon_rect: icon_rect.texture = data.icon
	if description_label: description_label.text = data.description
	
	if cost_label:
		cost_label.text = data.price.get_display_string() if data.price else "Free"


## Adjusts the visual state of the slot based on player funds.
func set_affordability(can_afford: bool) -> void:
	if buy_button:
		buy_button.disabled = not can_afford
		
	modulate = affordable_color if can_afford else unaffordable_color
	
	if cost_label:
		cost_label.modulate = cost_positive_color if can_afford else cost_negative_color

#endregion





#region Private Logic

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

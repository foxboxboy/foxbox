class_name FoxShopSlot
extends FoxControl

@export_group("Components")
@export var buy_button: Button
@export var icon_rect: TextureRect
@export var name_label: Label
@export var cost_label: Label
@export var description_label: Label

@export_group("Visual Settings")
@export var affordable_color: Color = Color.WHITE
@export var unaffordable_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var cost_positive_color: Color = Color.GREEN
@export var cost_negative_color: Color = Color.RED

var data: FoxShopItem

signal buy_button_pressed(item: FoxShopItem)
signal buy_button_focused(item: FoxShopItem)
signal buy_button_unfocused(item: FoxShopItem)

func setup(item_data: FoxShopItem) -> void:
	data = item_data
	
	if name_label: name_label.text = str(data.display_name)
	if icon_rect: icon_rect.texture = data.icon
	if description_label: description_label.text = data.description
	
	if cost_label:
		cost_label.text = data.price.get_display_string() if data.price else "Free"

func set_affordability(can_afford: bool) -> void:
	if buy_button:
		buy_button.disabled = not can_afford
		
	modulate = affordable_color if can_afford else unaffordable_color
	
	if cost_label:
		cost_label.modulate = cost_positive_color if can_afford else cost_negative_color

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

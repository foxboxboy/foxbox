#tate_lib/modules/simple_shop/tate_purchase_option_slot.gd
extends FoxControl
class_name FoxPurchaseOptionSlot
## A single visual card representing a purchase option.

signal pressed(option: FoxPurchaseOption)

@export var icon_rect: TextureRect
@export var name_label: Label
@export var cost_label: Label
@export var buy_button: Button
@export var description_label: Label

var data: FoxPurchaseOption


func _ready() -> void:
	if buy_button:
		buy_button.pressed.connect(_on_buy_button_pressed)


## Makes the purchase option white with a green
## cost label if you can afford it.
## Otherwise, makes it gray with a red cost label.
## This can be overridden.
func set_affordability(can_afford: bool) -> void:
	if can_afford:
		buy_button.disabled = false
		make_white()
		make_cost_label_green()
	else:
		buy_button.disabled = true
		make_gray()
		make_cost_label_red()


func make_white():
	modulate = Color(1, 1, 1, 1)


func make_gray():
	modulate = Color(0.5, 0.5, 0.5, 1)


func make_buy_button_green():
	buy_button.modulate = Color.GREEN


func make_buy_button_red():
	buy_button.modulate = Color.RED


func make_cost_label_green():
	cost_label.modulate = Color.GREEN


func make_cost_label_red():
	cost_label.modulate = Color.RED


func setup(option_data: FoxPurchaseOption, override_cost: float = NAN) -> void:
	data = option_data
	
	var warning_prefix : String = "FoxChoiceSlot has no "
	var warning_suffix : String
	
	if is_inside_tree():
		warning_suffix = str(get_path())
	
	if name_label:
		name_label.text = str(data.display_name)
	else:
		push_warning(warning_prefix+"name_label. "+warning_suffix)
		
	if icon_rect:
		icon_rect.texture = data.icon
	else:
		push_warning(warning_prefix+"icon_rect. "+warning_suffix)
		
	if cost_label:
		if is_nan(override_cost):
			cost_label.text = "$"+str(data.cost)
		else:
			cost_label.text = str(override_cost)
	else:
		push_warning(warning_prefix+"cost_label. "+warning_suffix)
	
	if description_label:
		description_label.text = data.description
	else:
		push_warning(warning_prefix+"description_label. "+warning_suffix)


func _on_buy_button_pressed() -> void:
	pressed.emit(data)

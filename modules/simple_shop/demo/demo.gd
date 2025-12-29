extends Control

@onready var purchase_option_menu: TatePurchaseOptionMenu = $Shop/MarginContainer/ScrollContainer/PurchaseOptionMenu
@onready var money_label : Label = $MoneyLabel
@onready var console_label: Label = $ConsoleLabel


var money := 0:
	set(value):
		money_label.text = "$"+str(value)
		money = value
		purchase_option_menu.current_funds = money
		

const COOL_SWORD : TatePurchaseOption = preload("uid://cc0d142wmdcwv")
const HOUSE = preload("uid://drk6fo7icv652")
const APPLE = preload("uid://pmmjkptyseek")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	purchase_option_menu.add_option(COOL_SWORD)
	purchase_option_menu.add_option(HOUSE)
	purchase_option_menu.add_option(APPLE)


func _on_purchase_option_menu_slot_pressed(option: TatePurchaseOption) -> void:
	var string_to_print := "The "+option.display_name+" purhcase option was selected\
	. It's payload is: "
	
	if (option.payload):
		string_to_print += str(option.payload.get_script().resource_path)
	
	print(string_to_print)
	
	console_label.text = string_to_print
	
	money -= option.cost


func _on_timer_timeout() -> void:
	money += 2

class_name FoxSimplePrice
extends FoxPrice

@export var cost: int = 0
@export var currency_symbol: String = "$"

func can_be_paid_by(wallet: FoxWallet) -> bool:
	var simple_wallet = wallet as FoxSimpleWallet
	if simple_wallet:
		return simple_wallet.funds >= cost
		
	push_error("FoxSimplePrice: Expected a FoxSimpleWallet, but got something else.")
	return false

func pay(wallet: FoxWallet) -> void:
	var simple_wallet = wallet as FoxSimpleWallet
	if simple_wallet:
		simple_wallet.funds -= cost
	else:
		push_error("FoxSimplePrice: Expected a FoxSimpleWallet, but got something else.")

func get_display_string() -> String:
	return currency_symbol + str(cost)

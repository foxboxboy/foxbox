class_name FoxPrice
extends FoxResource
## The abstract base class for evaluating and executing transaction costs.



## Returns [code]true[/code] if the provided [FoxWallet] meets the cost requirements.
func can_be_paid_by(_wallet: FoxWallet) -> bool:
	return false


## Deducts the cost from the provided [FoxWallet].
func pay(_wallet: FoxWallet) -> void:
	pass


## Returns a formatted string for UI display (e.g., "$150" or "50 Wood").
func get_display_string() -> String:
	return "Free"

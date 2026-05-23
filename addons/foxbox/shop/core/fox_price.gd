@icon("uid://cjf8prmuxwnac")
@abstract class_name FoxPrice
extends FoxResource

func can_be_paid_by(_wallet: FoxWallet) -> bool:
	return false

@abstract func pay(_wallet: FoxWallet) -> void

@abstract func get_display_string() -> String

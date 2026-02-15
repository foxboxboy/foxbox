#tate_lib/modules/simple_shop/tate_shop_service.gd
extends TateResource
class_name TateShopService
## A headless service that validates and executes purchases.

## Emitted when a purchase is valid.
#signal purchase_succeeded(purchase_option: TatePurchaseOption)
## Emitted when the the funds passed in is lower than the purchase cost of a purchase_option.
#signal purchase_failed(purchase_option: TatePurchaseOption, reason: String)

## Returns true if the funds passed in is greater than or
## equal to what the purchase option passed in requires. 
static func can_purchase(purchase_option: TatePurchaseOption, funds: int) -> bool:
	if funds >= purchase_option.cost:
		#purchase_succeeded.emit(purchase_option)
		return true
	
	#purchase_failed.emit(purchase_option, "Insufficient funds")
	return false

class_name ShopEntry
extends Resource

@export var item: ItemDefinition
@export_range(-1, 9999) var stock: int = -1  ## -1 = infinite
@export_range(0, 9999) var price_override: int = 0  ## 0 = use item base_value
var _sold: int = 0

func available() -> int:
	if stock < 0:
		return 999
	return maxi(0, stock - _sold)

func effective_price() -> int:
	return price_override if price_override > 0 else item.base_value

func consume_stock(qty: int = 1) -> void:
	if stock >= 0:
		_sold += qty

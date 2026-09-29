class_name ShopInventory
extends Resource

@export var entries: Array[ShopEntry] = []
@export_range(0.01, 1.0) var sell_ratio: float = 0.5

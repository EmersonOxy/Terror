class_name ShopComponent
extends Node

signal transaction_completed(message: String)

@export var shop_data: ShopInventory
var _player_inventory: InventoryComponent
var _player_wallet: WalletComponent
var _player_equipment: EquipmentComponent

func setup(inventory: InventoryComponent, wallet: WalletComponent, equipment: EquipmentComponent) -> void:
	_player_inventory = inventory
	_player_wallet = wallet
	_player_equipment = equipment

func get_entries() -> Array[ShopEntry]:
	return shop_data.entries if shop_data else []

func buy(entry_index: int) -> bool:
	if shop_data == null or entry_index < 0 or entry_index >= shop_data.entries.size():
		transaction_completed.emit("Item inválido.")
		return false
	var entry := shop_data.entries[entry_index]
	if entry.available() <= 0:
		transaction_completed.emit("Esgotado.")
		return false
	var price := entry.effective_price()
	if not _player_wallet.can_afford(price):
		transaction_completed.emit("Saldo insuficiente.")
		return false
	var test_instance := entry.item.create_instance(1)
	if not _player_inventory.has_space(test_instance):
		transaction_completed.emit("Inventário cheio.")
		return false
	# Transaction is safe: deduct money, add item, consume stock
	_player_wallet.spend(price)
	_player_inventory.add_item(entry.item.create_instance(1))
	entry.consume_stock()
	transaction_completed.emit("Comprou: " + entry.item.display_name)
	return true

func sell_value(item: ItemInstance) -> int:
	if item == null or shop_data == null:
		return 0
	return maxi(1, int(item.definition.base_value * shop_data.sell_ratio))

func sell(inventory_index: int) -> bool:
	if _player_inventory == null or _player_wallet == null:
		return false
	var item := _player_inventory.get_slot(inventory_index)
	if item == null:
		transaction_completed.emit("Slot vazio.")
		return false
	# Don't allow selling equipped items — they must be in the backpack
	if _player_equipment != null:
		for slot in EquipmentComponent.SLOTS:
			if _player_equipment.get_equipped(slot) == item:
				transaction_completed.emit("Desequipe antes de vender.")
				return false
	var value := sell_value(item)
	_player_inventory.take(inventory_index)
	_player_wallet.add_currency(value * item.quantity if item.quantity > 0 else value)
	transaction_completed.emit("Vendeu: %s (+%d)" % [item.definition.display_name, value * item.quantity])
	return true

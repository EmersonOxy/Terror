class_name EquipmentComponent
extends Node

signal equipment_changed
signal item_equipped(slot: ItemDefinition.EquipSlot, item: ItemInstance)
signal item_unequipped(slot: ItemDefinition.EquipSlot, item: ItemInstance)

const SLOTS: Array[ItemDefinition.EquipSlot] = [ItemDefinition.EquipSlot.HEAD, ItemDefinition.EquipSlot.BODY, ItemDefinition.EquipSlot.WEAPON]
var _equipped: Dictionary[ItemDefinition.EquipSlot, ItemInstance] = {}

func get_equipped(slot: ItemDefinition.EquipSlot) -> ItemInstance:
	return _equipped.get(slot)

func can_equip(item: ItemInstance, slot: ItemDefinition.EquipSlot) -> bool:
	return SLOTS.has(slot) and item != null and item.is_valid() and item.quantity == 1 and item.definition.max_stack == 1 and item.definition.equip_slot == slot

func replace(slot: ItemDefinition.EquipSlot, item: ItemInstance, notify: bool = true) -> bool:
	if not SLOTS.has(slot) or (item != null and not can_equip(item, slot)):
		return false
	var previous := get_equipped(slot)
	_equipped[slot] = item
	if notify:
		announce(slot, previous, item)
	return true

func announce(slot: ItemDefinition.EquipSlot, previous: ItemInstance, item: ItemInstance) -> void:
	if previous != null:
		item_unequipped.emit(slot, previous)
	if item != null:
		item_equipped.emit(slot, item)
	equipment_changed.emit()

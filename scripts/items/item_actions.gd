class_name ItemActions
extends Node

signal feedback(message: String)
signal item_used(definition: ItemDefinition)
@export var inventory: InventoryComponent
@export var equipment: EquipmentComponent
@export var status: StatusComponent
@export var actor: CharacterBody3D
var drop_parent: Node3D
var drop_direction: Vector3 = Vector3.FORWARD
const PICKUP := preload("res://scenes/items/item_pickup.tscn")

func collect(item: ItemInstance) -> int:
	if status.dead:
		return 0
	var count := inventory.add_item(item)
	feedback.emit("Coletado: %d. Restante: %d" % [count, item.quantity] if count > 0 else "Inventário cheio")
	return count

func can_use(index: int) -> bool:
	var item := inventory.get_slot(index)
	return not status.dead and item != null and item.definition.use_effect != null and item.definition.use_effect.can_use(status)

func use(index: int) -> bool:
	if not can_use(index):
		feedback.emit("Não é possível usar agora (vida cheia ou jogador morto).")
		return false
	var item := inventory.get_slot(index)
	if not item.definition.use_effect.apply(status):
		return false
	inventory.consume(index)
	item_used.emit(item.definition)
	feedback.emit("Usado: " + item.definition.display_name)
	return true

func equip(index: int, slot: ItemDefinition.EquipSlot) -> bool:
	var item := inventory.get_slot(index)
	if status.dead or not equipment.can_equip(item, slot):
		feedback.emit("Item incompatível com este slot.")
		return false
	var previous := equipment.get_equipped(slot)
	# Reuse the vacated inventory slot: a full backpack never blocks a swap.
	if not inventory.replace_slot(index, previous, false):
		return false
	equipment.replace(slot, item, false)
	inventory.inventory_changed.emit()
	equipment.announce(slot, previous, item)
	feedback.emit("Equipado: " + item.definition.display_name)
	return true

func unequip(slot: ItemDefinition.EquipSlot) -> bool:
	var item := equipment.get_equipped(slot)
	if status.dead or item == null:
		return false
	if not inventory.has_space(item):
		feedback.emit("Inventário cheio")
		return false
	# Preserve the equipped instance itself, rather than merging/copying it.
	for index in inventory.capacity():
		if inventory.get_slot(index) == null:
			inventory.replace_slot(index, item, false)
			equipment.replace(slot, null, false)
			inventory.inventory_changed.emit()
			equipment.announce(slot, item, null)
			feedback.emit("Desequipado: " + item.definition.display_name)
			return true
	return false

func drop(index: int) -> ItemPickup:
	if status.dead or inventory.get_slot(index) == null or not is_instance_valid(drop_parent):
		return null
	var position: Variant = DropPlacement.find_position(actor, drop_direction)
	if position == null:
		feedback.emit("Sem espaço seguro para largar aqui.")
		return null
	var pickup := PICKUP.instantiate() as ItemPickup
	pickup.set_item(inventory.take(index))
	drop_parent.add_child(pickup)
	pickup.global_position = position
	feedback.emit("Item largado.")
	return pickup

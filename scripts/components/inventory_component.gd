class_name InventoryComponent
extends Node

signal inventory_changed
signal item_added(definition: ItemDefinition, quantity: int)
signal item_removed(definition: ItemDefinition, quantity: int)

@export_range(1, 128) var initial_capacity: int = 6
var _slots: Array[ItemInstance] = []

func _ready() -> void:
	_slots.resize(initial_capacity)

func capacity() -> int:
	return _slots.size()

func set_capacity(value: int) -> bool:
	if value < 1:
		return false
	if value < _slots.size():
		for i in range(value, _slots.size()):
			if _slots[i] != null:
				return false
	_slots.resize(value)
	inventory_changed.emit()
	return true

func get_slot(index: int) -> ItemInstance:
	return _slots[index] if index >= 0 and index < _slots.size() else null

func occupied_slots() -> int:
	var count := 0
	for item in _slots:
		if item != null:
			count += 1
	return count

func get_quantity(id: StringName) -> int:
	var count := 0
	for item in _slots:
		if item != null and item.definition.id == id:
			count += item.quantity
	return count

func compatible_slots(item: ItemInstance) -> Array[int]:
	var result: Array[int] = []
	if item == null or not item.is_valid():
		return result
	for i in _slots.size():
		if _slots[i] != null and _slots[i].can_stack_with(item) and _slots[i].quantity < item.definition.max_stack:
			result.append(i)
	return result

func available_space(item: ItemInstance) -> int:
	if item == null or not item.is_valid():
		return 0
	var count := 0
	for slot in _slots:
		if slot == null:
			count += item.definition.max_stack
		elif slot.can_stack_with(item):
			count += maxi(0, item.definition.max_stack - slot.quantity)
	return count

func has_space(item: ItemInstance) -> bool:
	return item != null and item.is_valid() and available_space(item) >= item.quantity

# Consumes the incoming quantity; any remainder stays with the caller (pickup).
# Stored stacks own copies, preserving specialized Resource fields, never Definition state.
func add_item(item: ItemInstance, notify: bool = true) -> int:
	if item == null or not item.is_valid() or _slots.has(item):
		return 0
	var before := item.quantity
	for index in compatible_slots(item):
		var moved := mini(item.quantity, item.definition.max_stack - _slots[index].quantity)
		_slots[index].quantity += moved
		item.quantity -= moved
		if item.quantity == 0:
			break
	for i in _slots.size():
		if item.quantity == 0:
			break
		if _slots[i] == null:
			var moved := mini(item.quantity, item.definition.max_stack)
			_slots[i] = item.copy_with_quantity(moved)
			item.quantity -= moved
	var added := before - item.quantity
	if added > 0 and notify:
		item_added.emit(item.definition, added)
		inventory_changed.emit()
	return added

func add_quantity(definition: ItemDefinition, count: int) -> int:
	return add_item(ItemInstance.create(definition, count))

func take(index: int, count: int = -1, notify: bool = true) -> ItemInstance:
	var item := get_slot(index)
	if item == null or count == 0 or count < -1:
		return null
	var removed := item
	if count > 0 and count < item.quantity:
		removed = item.copy_with_quantity(count)
		item.quantity -= count
	else:
		_slots[index] = null
	if notify:
		item_removed.emit(removed.definition, removed.quantity)
		inventory_changed.emit()
	return removed

func consume(index: int, count: int = 1) -> bool:
	var item := get_slot(index)
	if item == null or count <= 0 or item.quantity < count:
		return false
	take(index, count)
	return true

# Transaction primitive used by ItemActions. Notifications are deferred until both stores agree.
func replace_slot(index: int, item: ItemInstance, notify: bool = true) -> bool:
	if index < 0 or index >= capacity():
		return false
	if item != null and (not item.is_valid() or item.quantity > item.definition.max_stack or _slots.has(item)):
		return false
	_slots[index] = item
	if notify:
		inventory_changed.emit()
	return true

extends "res://tests/player_milestone.gd"

var definitions: Dictionary = {}
var inv: InventoryComponent
var equipment: EquipmentComponent
var actions: ItemActions

func clear_inventory() -> void:
	for i in inv.capacity():
		inv.take(i)

func insert(id: String, quantity: int = 1) -> int:
	return inv.add_quantity(definitions[id], quantity)

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	inv = player.inventory
	equipment = player.equipment
	actions = player.items
	for id in ["bandage", "scrap", "key", "helmet", "vest", "melee", "ranged"]:
		definitions[id] = load("res://resources/items/" + id + ".tres")
	await frames(5)
	check(inv.capacity() == 6, "initial inventory has six slots")
	check(insert("bandage", 2) == 2, "add first stack")
	check(insert("bandage", 3) == 3, "complete stack and create remainder stack")
	check(inv.get_slot(0).quantity == 3 and inv.get_slot(1).quantity == 2, "stacks split 3 + 2")
	check(inv.get_slot(0) != inv.get_slot(1), "stacks have independent instances")
	check(inv.get_slot(0).definition == definitions.bandage, "definitions remain shared")
	check(insert("key", 4) == 4 and inv.occupied_slots() == 6, "fill all six slots")
	var remainder := ItemInstance.create(definitions.bandage, 3)
	check(inv.add_item(remainder) == 1 and remainder.quantity == 2, "partial addition preserves unaccepted quantity")
	check(insert("scrap", 10) == 0, "full inventory rejects incompatible item")
	check(inv.get_quantity(&"bandage") == 6, "quantity query counts all stacks")
	var removed := inv.take(0, 2)
	check(removed.quantity == 2 and inv.get_slot(0).quantity == 1, "partial removal preserves remainder")
	check(inv.add_item(removed) == 2 and removed.quantity == 0, "removed quantity can be returned")
	check(not inv.set_capacity(5), "capacity reduction never deletes occupied slots")
	check(inv.set_capacity(8), "capacity increase supported")
	check(world.get_node("InventoryUI").panel.slot_buttons.size() == 8, "UI follows increased capacity")
	check(insert("scrap", 25) == 20, "large quantity fills only available slots")
	clear_inventory()
	check(inv.set_capacity(6), "empty inventory can shrink safely")
	insert("bandage", 3)
	check(not actions.use(0) and inv.get_quantity(&"bandage") == 3, "full health does not consume bandage")
	player.status.damage(80)
	check(actions.use(0) and player.status.health == 50, "bandage applies HealEffect")
	check(actions.use(0) and player.status.health == 80, "multiple uses consume units")
	check(actions.use(0) and player.status.health == 100 and inv.get_slot(0) == null, "last unit consumed and health capped")
	insert("helmet")
	var helmet := inv.get_slot(0)
	check(not actions.equip(0, ItemDefinition.EquipSlot.BODY), "wrong equipment slot rejected")
	check(inv.get_slot(0) == helmet, "failed equip retains inventory item")
	check(actions.equip(0, ItemDefinition.EquipSlot.HEAD), "equip HEAD")
	check(inv.get_slot(0) == null and equipment.get_equipped(ItemDefinition.EquipSlot.HEAD) == helmet, "equipped instance leaves backpack")
	insert("vest")
	check(actions.equip(0, ItemDefinition.EquipSlot.BODY), "equip BODY")
	insert("melee")
	check(actions.equip(0, ItemDefinition.EquipSlot.WEAPON), "equip WEAPON")
	var melee := equipment.get_equipped(ItemDefinition.EquipSlot.WEAPON)
	insert("ranged")
	insert("key", 5)
	check(inv.occupied_slots() == 6, "backpack full before equipment swap")
	check(actions.equip(0, ItemDefinition.EquipSlot.WEAPON), "swap weapon despite full inventory")
	check(inv.get_slot(0) == melee and equipment.get_equipped(ItemDefinition.EquipSlot.WEAPON).definition == definitions.ranged, "old weapon returned without duplication")
	check(actions.equip(0, ItemDefinition.EquipSlot.WEAPON), "swap back to melee")
	check(not actions.unequip(ItemDefinition.EquipSlot.HEAD), "full inventory blocks unequip")
	check(equipment.get_equipped(ItemDefinition.EquipSlot.HEAD) == helmet, "failed unequip retains original instance")
	inv.take(1)
	check(actions.unequip(ItemDefinition.EquipSlot.HEAD) and inv.get_slot(1) == helmet, "unequip returns same instance")
	check(equipment.get_equipped(ItemDefinition.EquipSlot.BODY).definition.weight_class == ItemDefinition.WeightClass.HEAVY, "weight class remains queryable metadata")
	clear_inventory()
	insert("bandage", 2)
	player.status.damage(1000)
	check(not actions.use(0) and inv.get_slot(0).quantity == 2, "dead player cannot use or consume bandage")
	check(actions.collect(ItemInstance.create(definitions.key)) == 0, "dead player cannot collect")
	check(actions.drop(0) == null, "dead player cannot drop")
	check(not inv.consume(0, -1) and not inv.consume(0, 3), "invalid consumption rejected")
	print("RESULT items core failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

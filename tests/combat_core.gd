extends "res://tests/player_milestone.gd"

var dummy: DamageReceiver
var combat: CombatComponent
var received: Array[DamageData] = []

func aim_at(target: Node3D) -> AimSample:
	return AimSample.new(player.damage_point(), target.damage_point(), true)

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	combat = player.combat
	dummy = load("res://scenes/combat/combat_dummy.tscn").instantiate()
	world.add_child(dummy)
	dummy.global_position = Vector3(0, 0, -8)
	var extra := dummy.get_node("Collision").duplicate() as CollisionShape3D
	dummy.add_child(extra)
	dummy.damaged.connect(func(data: DamageData): received.append(data))
	await place(Vector3(0, 0.02, -6.6))
	var melee := ItemInstance.create(load("res://resources/items/melee.tres"))
	var ranged := ItemInstance.create(load("res://resources/items/ranged.tres")) as WeaponInstance
	var other := ItemInstance.create(ranged.definition) as WeaponInstance
	var inv := player.inventory
	inv.add_item(melee)
	inv.add_item(ranged)
	player.items.equip(0, ItemDefinition.EquipSlot.WEAPON)
	check(combat.weapon() is WeaponInstance, "definition factory creates weapon specialization")
	var stamina := player.status.stamina
	check(combat.attack(aim_at(dummy)), "melee accepted")
	check(dummy.health == 75 and received.size() == 1, "melee hits once per target")
	check(player.status.stamina == stamina - 18, "melee uses existing stamina")
	check(received[0].source == player and received[0].direction.z < 0 and received[0].hit_position.z < -7, "damage carries source, direction and hit position")
	check(not combat.attack(aim_at(dummy)) and dummy.health == 75, "cooldown prevents duplicate hits")
	combat.tick(1, true)
	player.status.consume_stamina(1000)
	check(not combat.attack(aim_at(dummy)) and dummy.health == 75, "insufficient stamina prevents melee")
	player.status.tick(2, false)
	player.status.tick(5, false)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 0.15)
	collision.shape = box
	wall.add_child(collision)
	world.add_child(wall)
	wall.global_position = Vector3(0, 1, -7.3)
	await frames(3)
	check(combat.attack(aim_at(dummy)) and dummy.health == 75, "wall blocks melee even inside query shape")
	wall.queue_free()
	await frames(3)
	player.items.equip(1, ItemDefinition.EquipSlot.WEAPON)
	ranged = combat.weapon()
	combat.tick(1, true)
	check(combat.attack(aim_at(dummy)) and dummy.health == 55 and ranged.ammo_in_magazine == 5, "equipped ranged hitscan consumes magazine")
	check(other.ammo_in_magazine == 6, "identical weapons have independent magazines")
	var saved := ranged.copy_with_quantity(1) as WeaponInstance
	check(saved.ammo_in_magazine == 5 and saved.definition == ranged.definition, "instance copy preserves magazine and shared definition")
	combat.tick(1, true)
	var distant := AimSample.new(player.damage_point(), player.damage_point() + Vector3.RIGHT * 100, true)
	check(combat.attack(distant) and dummy.health == 55 and ranged.ammo_in_magazine == 4, "miss consumes ammo without unrelated damage")
	check(not combat.reload(), "reload without reserve refused")
	inv.add_quantity(load("res://resources/items/ammo.tres"), 10)
	check(combat.reload(), "reload uses inventory reserve")
	check(not combat.attack(aim_at(dummy)), "reload blocks shooting")
	combat.tick(2, true)
	check(ranged.ammo_in_magazine == 6 and combat.reserve() == 8, "reload transfers only magazine deficit")
	ranged.ammo_in_magazine = 0
	check(not combat.attack(aim_at(dummy)), "empty magazine cannot shoot")
	combat.reload()
	world.get_node("InventoryUI").set_open(true)
	check(combat.reload_remaining == 0 and ranged.ammo_in_magazine == 0 and combat.reserve() == 8, "inventory cancels reload without loss")
	check(not combat.attack(aim_at(dummy)) and not combat.reload(), "inventory blocks all combat requests")
	world.get_node("InventoryUI").set_open(false)
	combat.tick(1, true)
	combat.reload()
	player.items.equip(1, ItemDefinition.EquipSlot.WEAPON)
	check(combat.reload_remaining == 0 and ranged.ammo_in_magazine == 0, "weapon swap cancels pending reload")
	player.items.equip(1, ItemDefinition.EquipSlot.WEAPON)
	for i in inv.capacity():
		var stack := inv.get_slot(i)
		if stack != null and stack.definition.id == &"ammo_test":
			inv.take(i)
	inv.add_quantity(load("res://resources/items/ammo.tres"), 2)
	combat.reload()
	combat.tick(2, true)
	check(ranged.ammo_in_magazine == 2 and combat.reserve() == 0, "partial reload consumes only available reserve")
	player.items.unequip(ItemDefinition.EquipSlot.WEAPON)
	var index := -1
	for i in inv.capacity():
		if inv.get_slot(i) == ranged:
			index = i
	player.items.drop_direction = Vector3.RIGHT
	var pickup := player.items.drop(index)
	check(pickup != null and pickup.item == ranged and ranged.ammo_in_magazine == 2, "drop preserves exact weapon magazine")
	check(pickup.has_node("PickupIndicator"), "dropped weapon gets shared pickup indicator")
	pickup.interact(player)
	await frames(2)
	for i in inv.capacity():
		if inv.get_slot(i) is WeaponInstance and inv.get_slot(i).definition.id == &"ranged":
			player.items.equip(i, ItemDefinition.EquipSlot.WEAPON)
	check(combat.weapon().ammo_in_magazine == 2, "recollect and equip retain magazine")
	# Range is enforced from actor, independent of the supplied target point.
	dummy.global_position = Vector3(0, 0, -50)
	await frames(2)
	combat.tick(1, true)
	combat.attack(aim_at(dummy))
	check(dummy.health == 55, "ranged maximum distance respected")
	dummy.global_position = Vector3(0, 0, -8)
	await frames(2)
	dummy.health = 20
	combat.tick(1, true)
	check(combat.attack(aim_at(dummy)), "weapon delivers lethal hit")
	check(dummy.dead and dummy.health == 0 and not dummy.take_damage(DamageData.new(10, player)), "dummy death deactivates damage reception")
	player.receive_damage(1000)
	combat.tick(1, true)
	check(not combat.attack(aim_at(dummy)) and not combat.reload(), "death blocks attacks and reload")
	other = null
	saved = null
	print("RESULT combat core failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

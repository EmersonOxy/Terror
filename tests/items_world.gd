extends "res://tests/player_milestone.gd"

var inv: InventoryComponent
var bandage: ItemDefinition = load("res://resources/items/bandage.tres")
var key: ItemDefinition = load("res://resources/items/key.tres")

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	inv = player.inventory
	await frames(5)
	await place(Vector3(2, 0.02, 21.5))
	player.movement.facing = Vector3.FORWARD
	await frames(2)
	var pickup := world.get_node("ItemTestSector/Pickup0") as ItemPickup
	check(player.interaction.current == pickup, "existing interaction detects generic pickup")
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	await frames(1)
	check(inv.get_quantity(&"bandage") == 2 and not is_instance_valid(pickup), "E collects item and removes empty pickup")
	inv.add_quantity(key, 5)
	await place(Vector3(4, 0.02, 21.5))
	player.movement.facing = Vector3.FORWARD
	await frames(2)
	pickup = world.get_node("ItemTestSector/Pickup1")
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(inv.get_quantity(&"bandage") == 3 and pickup.item.quantity == 2, "partial pickup leaves two units in world")
	await frames(1)
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(pickup.item.quantity == 2, "full pickup retry loses nothing")
	inv.take(1)
	pickup.interact(player)
	await frames(1)
	check(inv.get_quantity(&"bandage") == 5, "remaining pickup collected after freeing slot")
	# A translated parent catches local/global coordinate mistakes.
	var container := Node3D.new()
	world.add_child(container)
	container.position = Vector3(35, 4, -20)
	player.items.drop_parent = container
	await place(Vector3(0, 0.02, 8))
	var source := inv.get_slot(0)
	var dropped := player.items.drop(0)
	check(dropped != null and dropped.item == source and dropped.item.quantity == 3, "drop retains instance and stack")
	check(dropped.global_position.distance_to(player.global_position) < 1.5, "translated drop parent still places near player")
	check(absf(dropped.global_position.y - 0.185) < 0.02, "drop rests above floor without floating")
	dropped.interact(player)
	await frames(2)
	check(inv.get_quantity(&"bandage") == 5, "drop and pickup conserve quantity")
	await place(Vector3(9.1, 0.02, 4))
	player.items.drop_direction = Vector3.LEFT
	dropped = player.items.drop(0)
	check(dropped != null, "drop near corridor wall finds safe alternative")
	if dropped:
		check(dropped.global_position.x > 8.3, "drop never crosses corridor wall")
		dropped.interact(player)
		await frames(2)
	player.set_physics_process(false)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(5, 5, 5)
	wall.add_child(collision)
	world.add_child(wall)
	wall.global_position = player.global_position
	await frames(2)
	var quantity := inv.get_quantity(&"bandage")
	check(player.items.drop(0) == null and inv.get_quantity(&"bandage") == quantity, "unsafe drop fails without removing item")
	wall.queue_free()
	await frames(2)
	print("RESULT items world failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

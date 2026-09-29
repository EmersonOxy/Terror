extends "res://tests/items_ui.gd"

func drain(narrative: NarrativeSystem) -> void:
	while narrative.current_line() != null:
		narrative.advance()

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	ui = world.get_node("InventoryUI")
	var director: NarrativeDirector = world.get_node("NarrativeTestArea")
	var narrative := director.narrative
	for enemy in world.get_node("EnemyTestArea").enemies:
		enemy.set_physics_process(false)
	await frames(10)
	await place(Vector3(9.5, 0.02, 6))
	check(narrative.current_event() == &"test_area_enter", "real Area3D entry routes corridor event")
	var position := player.global_position
	Input.action_press("move_forward")
	await frames(12)
	Input.action_release("move_forward")
	check(player.global_position.distance_to(position) > 0.1 and not player.controls_locked, "automatic comment does not block movement")
	player.inventory.add_quantity(load("res://resources/items/ranged.tres"), 1)
	player.items.equip(0, ItemDefinition.EquipSlot.WEAPON)
	Input.action_press("aim")
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	Input.action_release("aim")
	check(player.combat.weapon().ammo_in_magazine == 5, "automatic comment does not block combat")
	var count := narrative.queue_size()
	director.triggers[0]._entered(player)
	check(narrative.queue_size() == count, "reentering active trigger does not duplicate speech")
	drain(narrative)
	await place(Vector3(0, 0.02, -16))
	check(narrative.current_event() == &"test_enemy_first_encounter", "temporary encounter area triggers first encounter comment")
	drain(narrative)
	check(not narrative.request_event(&"test_enemy_first_encounter"), "first encounter is once per session")
	var enemies: Array = world.get_node("EnemyTestArea").enemies
	enemies[0].take_damage(DamageData.new(100, player))
	check(narrative.current_event() == &"test_enemy_killed", "enemy death signal routes narrative event")
	enemies[1].take_damage(DamageData.new(100, player))
	check(narrative.queue_size() == 0, "multiple enemy deaths respect event cooldown")
	player.receive_damage(12)
	check(narrative.current_event() == &"test_player_damaged", "significant damage preempts lower priority comment")
	player.receive_damage(12)
	check(narrative.queue_size() == 1, "repeated damage cannot spam comments")
	drain(narrative)
	var pickup := load("res://scenes/items/item_pickup.tscn").instantiate() as ItemPickup
	pickup.set_item(ItemInstance.create(load("res://resources/items/ranged.tres")))
	world.add_child(pickup)
	pickup.interact(player)
	check(narrative.current_event() == &"test_weapon_pickup", "successful pickup signal routes item event")
	drain(narrative)
	check(not narrative.request_event(&"test_weapon_pickup"), "weapon comment cannot repeat indefinitely")

	for iso_mode in [false, true]:
		await place(Vector3(6, 0.02, 11.5))
		world.cameras.set_mode(iso_mode)
		await frames(4)
		await key_event(KEY_I)
		check(not director.dummy.can_interact(player), "inventory prevents starting dialogue")
		await key_event(KEY_I)
		player.movement.facing = Vector3.FORWARD
		await key_event(KEY_E)
		check(narrative.interactive_active and narrative.current_line().speaker_id == &"survivor", "E starts first NPC line through existing interaction")
		check(player.controls_locked, "interactive dialogue locks gameplay")
		var ammo := player.combat.weapon().ammo_in_magazine
		var before := player.global_position
		Input.action_press("move_forward")
		Input.action_press("attack")
		Input.action_press("interact")
		await frames(8)
		for action in ["move_forward", "attack", "interact"]:
			Input.action_release(action)
		check(player.global_position.distance_to(before) < 0.02 and player.combat.weapon().ammo_in_magazine == ammo, "dialogue blocks movement/combat and repeated interaction")
		check(narrative.current_line().speaker_id == &"survivor" and narrative.queue_size() == 0, "E does not skip or duplicate NPC conversation")
		await key_event(KEY_SPACE)
		check(narrative.current_line().speaker_id == &"player_default", "dialogue_continue advances to Player response")
		await key_event(KEY_I)
		await key_event(KEY_SPACE)
		check(narrative.current_line().speaker_id == &"player_default", "inventory prevents accidental continuation behind UI")
		await key_event(KEY_I)
		check(player.controls_locked, "closing inventory retains dialogue lock")
		await key_event(KEY_SPACE)
		check(narrative.current_line().speaker_id == &"survivor", "third NPC line in order")
		await key_event(KEY_SPACE)
		check(not narrative.interactive_active and not player.controls_locked, "completion returns gameplay controls")
		if DisplayServer.get_name() != "headless":
			check(Input.mouse_mode == (Input.MOUSE_MODE_VISIBLE if iso_mode else Input.MOUSE_MODE_CAPTURED), "dialogue preserves camera mouse mode")
		# Scripted end during inventory must preserve the other lock owner.
		director.start_dialogue(director.dummy.sequence, player)
		await key_event(KEY_I)
		drain(narrative)
		check(player.controls_locked and ui.is_open, "dialogue ending never releases inventory lock")
		await key_event(KEY_I)
		check(not player.controls_locked, "last lock release restores gameplay")

	director.start_dialogue(director.dummy.sequence, player)
	narrative.request_event(&"test_area_enter")
	player.receive_damage(1000)
	check(player.status.dead and narrative.current_line() == null and narrative.queue_size() == 0, "Player death clears active dialogue and pending comments")
	check(not narrative.request_event(&"test_area_enter"), "no trivial speech starts after death")
	print("RESULT narrative gameplay failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

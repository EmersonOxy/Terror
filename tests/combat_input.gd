extends "res://tests/items_ui.gd"

func hold(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)

func mouse_button(button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = root.get_mouse_position()
	event.global_position = event.position
	Input.parse_input_event(event)
	await frames(2)

func point_at(dummy: DamageReceiver, iso_mode: bool) -> void:
	if iso_mode:
		var event := InputEventMouseMotion.new()
		event.position = world.cameras.iso.unproject_position(dummy.damage_point())
		event.global_position = event.position
		if DisplayServer.get_name() != "headless":
			Input.warp_mouse(event.position)
		root.push_input(event, true)
		await frames(3)
	else:
		# Align the actual orbit to put the dummy under the central reticle.
		for i in 6:
			var direction: Vector3 = dummy.damage_point() - world.cameras.third.global_position
			world.cameras.yaw = atan2(-direction.x, -direction.z)
			world.cameras.pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())
			await frames(10)
		await mouse_button(MOUSE_BUTTON_RIGHT, true)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP native cursor combat input: run tools/check.ps1 -Visual")
		quit(0)
		return
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	inv = player.inventory
	ui = world.get_node("InventoryUI")
	panel = ui.panel
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await frames(12)
	inv.add_quantity(load("res://resources/items/melee.tres"), 1)
	inv.add_quantity(load("res://resources/items/ranged.tres"), 1)
	inv.add_quantity(load("res://resources/items/ammo.tres"), 18)
	var dummy := world.get_node("CombatTestSector/ShortDummy") as DamageReceiver
	for iso_mode in [false, true]:
		await place(Vector3(4, 0.02, -6.6))
		world.cameras.set_mode(iso_mode)
		await frames(30)
		await hold(KEY_TAB, true)
		check(ui.is_open and ui.held_by_tab and not ui.pinned_by_i, "TAB opens temporarily")
		await hold(KEY_TAB, false)
		check(not ui.is_open, "TAB release closes")
		await key_event(KEY_I)
		await hold(KEY_TAB, true)
		await hold(KEY_TAB, false)
		check(ui.is_open and ui.pinned_by_i, "TAB release preserves I pin")
		await key_event(KEY_I)
		check(not ui.is_open, "second I unpins")
		await hold(KEY_TAB, true)
		await key_event(KEY_I)
		await hold(KEY_TAB, false)
		check(ui.is_open and ui.pinned_by_i, "I during TAB survives TAB release")
		await hold(KEY_TAB, true)
		await key_event(KEY_I)
		check(ui.is_open and not ui.pinned_by_i, "unpin while TAB held remains open")
		await hold(KEY_TAB, false)
		check(not ui.is_open and not player.controls_locked and not world.cameras.controls_locked, "last source release restores controls")
		if DisplayServer.get_name() != "headless":
			check(Input.mouse_mode == (Input.MOUSE_MODE_VISIBLE if iso_mode else Input.MOUSE_MODE_CAPTURED), "TAB/I restore correct camera cursor")
		player.items.equip(0, ItemDefinition.EquipSlot.WEAPON)
		dummy.health = 100
		dummy.dead = false
		player.status.stamina = 100
		player.combat.tick(1, true)
		await point_at(dummy, iso_mode)
		await mouse_button(MOUSE_BUTTON_LEFT, true)
		await mouse_button(MOUSE_BUTTON_LEFT, false)
		check(dummy.health == 75 and player.status.stamina < 100, "input melee hits with camera aim and stamina")
		player.items.equip(1, ItemDefinition.EquipSlot.WEAPON)
		var weapon := player.combat.weapon()
		weapon.ammo_in_magazine = 6
		player.combat.tick(1, true)
		await mouse_button(MOUSE_BUTTON_LEFT, true)
		await mouse_button(MOUSE_BUTTON_LEFT, false)
		check(dummy.health == 55 and weapon.ammo_in_magazine == 5, "input ranged hits nearby target")
		await key_event(KEY_R)
		check(player.combat.reload_remaining > 0, "R starts reload")
		await key_event(KEY_I)
		check(player.combat.reload_remaining == 0, "opening inventory cancels active reload")
		var before := weapon.ammo_in_magazine
		await mouse_button(MOUSE_BUTTON_LEFT, true)
		await mouse_button(MOUSE_BUTTON_LEFT, false)
		await key_event(KEY_R)
		check(weapon.ammo_in_magazine == before and player.combat.reload_remaining == 0, "inventory blocks attack and reload inputs")
		check(panel.position.x >= 1280 * 0.65 or panel.get_global_rect().position.x >= 1280 * 0.65, "inventory anchored on right")
		check(panel.size.x <= 1280 * 0.35, "inventory occupies at most 35 percent width")
		var equipment_y: float = panel.equip_buttons[ItemDefinition.EquipSlot.HEAD].global_position.y
		for slot in EquipmentComponent.SLOTS:
			check(is_equal_approx(panel.equip_buttons[slot].global_position.y, equipment_y), "equipment slots share horizontal row")
		panel.select_inventory(1)
		await frames(4)
		await shot("combat_iso" if iso_mode else "combat_third")
		check(panel.details.get_global_rect().end.y <= 720 and panel.get_global_rect().end.y <= 720, "details and panel remain within viewport")
		await key_event(KEY_I)
		await key_event(KEY_R)
		await frames(95)
		check(weapon.ammo_in_magazine == 6, "reload completes through input")
		# Move away while retaining same dummy and aim via camera/cursor.
		player.global_position = Vector3(-1, 0.02, -8)
		await frames(35)
		await point_at(dummy, iso_mode)
		var target: Vector3 = player.combat_aim.target
		check(target.distance_to(dummy.damage_point()) < 1.0, "camera provider aims at distant dummy")
		await mouse_button(MOUSE_BUTTON_LEFT, true)
		await mouse_button(MOUSE_BUTTON_LEFT, false)
		check(dummy.health == 35, "input ranged hits medium distance")
		# Cover intercepts actor ray even when camera aim can see past it.
		var wall := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.2, 1.5, 1.8)
		collision.shape = shape
		wall.add_child(collision)
		world.add_child(wall)
		wall.global_position = Vector3(0, 0.75, -8)
		await frames(3)
		player.combat.tick(1, true)
		player.combat.attack(AimSample.new(player.damage_point(), dummy.damage_point(), true))
		check(dummy.health == 35, "actor-origin shot cannot bypass cover with camera target")
		wall.queue_free()
		await frames(3)
		await mouse_button(MOUSE_BUTTON_RIGHT, false)
		player.items.unequip(ItemDefinition.EquipSlot.WEAPON)
		# Restore stable slot arrangement for second camera.
		for i in inv.capacity():
			var item := inv.get_slot(i)
			if item != null and item.definition.id == &"melee" and i != 0:
				var previous := inv.take(0)
				inv.replace_slot(0, inv.take(i))
				inv.replace_slot(i, previous)
		for i in inv.capacity():
			var item := inv.get_slot(i)
			if item != null and item.definition.id == &"ranged" and i != 1:
				var previous := inv.take(1)
				inv.replace_slot(1, inv.take(i))
				inv.replace_slot(i, previous)
	await place(Vector3(-8, 0.02, 7))
	for iso_mode in [false, true]:
		world.cameras.set_mode(iso_mode)
		if not iso_mode:
			world.cameras.yaw = PI
		await frames(45)
		await shot("indicators_iso" if iso_mode else "indicators_third")
	var pickup := world.get_node("ItemTestSector/Pickup0") as ItemPickup
	var indicator := pickup.get_node("PickupIndicator/Line") as MeshInstance3D
	check(indicator.mesh.material == load("res://resources/items/pickup_indicator.tres"), "pickups share centrally configured indicator material")
	# Close view makes both procedural fade ends inspectable without item labels.
	world.get_node("DebugHUD").hide()
	world.get_node("CombatHUD").hide()
	world.get_node("InventoryUI").hide()
	pickup.label.hide()
	var close_camera := Camera3D.new()
	world.add_child(close_camera)
	close_camera.global_position = pickup.global_position + Vector3(0.7, 0.9, 2.0)
	close_camera.look_at(pickup.global_position + Vector3.UP * 0.7)
	close_camera.current = true
	await frames(5)
	await shot("indicator_close")
	print("RESULT combat input failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

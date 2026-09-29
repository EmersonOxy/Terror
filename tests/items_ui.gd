extends "res://tests/player_milestone.gd"

var ui: CanvasLayer
var panel: InventoryPanel
var inv: InventoryComponent

func key_event(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event.pressed = false
	Input.parse_input_event(event)
	await frames(1)

func click(button: Button) -> void:
	await process_frame
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func shot(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/inventory_" + label + ".png")

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	inv = player.inventory
	ui = world.get_node("InventoryUI")
	panel = ui.panel
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await frames(12)
	for id in ["bandage", "helmet", "vest", "melee", "ranged", "key"]:
		inv.add_quantity(load("res://resources/items/" + id + ".tres"), 1)
	player.status.damage(60)
	for iso_mode in [false, true]:
		world.cameras.set_mode(iso_mode)
		await key_event(KEY_I)
		check(ui.is_open and player.controls_locked and world.cameras.controls_locked, "I opens and locks gameplay")
		if DisplayServer.get_name() != "headless":
			check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "inventory cursor visible")
		var position := player.global_position
		var yaw: float = world.cameras.yaw
		Input.action_press("move_forward")
		Input.action_press("sprint")
		Input.action_press("interact")
		await frames(12)
		check(player.global_position.distance_to(position) < 0.01 and not player.movement.sprinting, "movement/sprint blocked while inventory open")
		check(player.interaction.current == null, "world interaction blocked while open")
		var mouse := InputEventMouseMotion.new()
		mouse.relative = Vector2(200, 50)
		world.cameras._unhandled_input(mouse)
		check(world.cameras.yaw == yaw, "camera mouse input blocked")
		for action in ["move_forward", "sprint", "interact"]:
			Input.action_release(action)
		await click(panel.slot_buttons[1])
		check(panel.selected_index == 1 and panel.equip_button.visible, "mouse selects inventory slot")
		await shot("isometric" if iso_mode else "third_person")
		await key_event(KEY_I)
		check(not ui.is_open and not player.controls_locked, "I closes and restores gameplay")
		if DisplayServer.get_name() != "headless":
			check(Input.mouse_mode == (Input.MOUSE_MODE_VISIBLE if iso_mode else Input.MOUSE_MODE_CAPTURED), "correct mouse mode restored")
	await key_event(KEY_I)
	await click(panel.slot_buttons[0])
	check(panel.use_button.visible and not panel.use_button.disabled, "bandage action available while wounded")
	await click(panel.use_button)
	check(player.status.health == 70 and inv.get_slot(0) == null, "click Use heals and consumes")
	await click(panel.slot_buttons[1])
	await click(panel.equip_button)
	check(player.equipment.get_equipped(ItemDefinition.EquipSlot.HEAD) != null and inv.get_slot(1) == null, "click Equip transfers HEAD")
	await click(panel.slot_buttons[2])
	await click(panel.equip_button)
	check(player.equipment.get_equipped(ItemDefinition.EquipSlot.BODY) != null, "click Equip transfers BODY")
	await click(panel.slot_buttons[3])
	await click(panel.equip_button)
	await click(panel.slot_buttons[4])
	await click(panel.equip_button)
	check(player.equipment.get_equipped(ItemDefinition.EquipSlot.WEAPON).definition.id == &"ranged" and inv.get_slot(4).definition.id == &"melee", "click Equip swaps weapons")
	await click(panel.equip_buttons[ItemDefinition.EquipSlot.HEAD])
	check(panel.unequip_button.visible and not panel.drop_button.visible, "equipment selection offers only unequip")
	await click(panel.unequip_button)
	check(player.equipment.get_equipped(ItemDefinition.EquipSlot.HEAD) == null, "click Unequip returns item")
	await click(panel.slot_buttons[5])
	await click(panel.drop_button)
	check(inv.get_slot(5) == null, "click Drop removes item from backpack")
	inv.set_capacity(12)
	await frames(4)
	check(panel.slot_buttons.size() == 12, "dynamic twelve-slot UI")
	await shot("twelve_slots")
	check(panel.get_global_rect().end.x <= 1280 and panel.get_global_rect().end.y <= 720, "panel fits viewport")
	await key_event(KEY_ESCAPE)
	check(not ui.is_open, "Escape closes inventory")
	await place(Vector3(10, 0.02, 28))
	world.cameras.set_mode(true)
	await frames(30)
	await shot("test_sector")
	print("RESULT items UI failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

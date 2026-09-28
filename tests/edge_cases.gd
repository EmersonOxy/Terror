extends "res://tests/player_milestone.gd"

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	await frames(12)
	await place(Vector3(-6, 0.02, 8.5))
	Input.action_press("move_forward")
	await frames(70)
	check(player.global_position.z > 7.25 and player.global_position.y < 0.02, "tall obstacle cannot be stepped")
	await place(Vector3(-2, 1.22, -4.3))
	Input.action_press("move_backward")
	await frames(100)
	check(player.global_position.y < 0.03 and player.is_on_floor(), "descends stairs to floor")
	await place(Vector3(-7, 1.32, -5.8))
	Input.action_press("move_backward")
	await frames(130)
	check(player.global_position.y < 0.03 and player.is_on_floor(), "descends ramp to floor")
	await place(Vector3(0, 0.02, 1.8))
	player.movement.facing = Vector3.BACK
	await frames(3)
	check(player.interaction.current == null, "object behind player rejected")
	player.movement.facing = Vector3.FORWARD
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 2, 0.1)
	collision.shape = shape
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.global_position = Vector3(0, 1, 0.9)
	await frames(5)
	check(player.interaction.current == null, "wall blocks interaction line of sight")
	blocker.queue_free()
	await frames(5)
	check(player.interaction.current == world.get_node("DamageTest"), "line of sight restored")
	var preferred := Interactable.new()
	var area_shape := CollisionShape3D.new()
	area_shape.shape = SphereShape3D.new()
	preferred.collision_layer = 4
	preferred.collision_mask = 0
	preferred.interaction_priority = 2.0
	preferred.add_child(area_shape)
	world.add_child(preferred)
	preferred.global_position = Vector3(0.4, 0.75, 0)
	await frames(4)
	check(player.interaction.current == preferred, "interaction priority selects candidate")
	preferred.queue_free()
	await frames(3)
	check(player.interaction.current == world.get_node("DamageTest"), "freed candidate safely replaced")
	await place(Vector3(4, 0.02, 1))
	Input.action_press("crouch")
	Input.action_press("move_forward")
	await frames(120)
	check(world.cameras.orbit.global_position.y < 1.1, "third person pivot fits below roof")
	await place(Vector3(0, 0.02, 10))
	player.visual.queue_free()
	await frames(2)
	Input.action_press("move_forward")
	await frames(30)
	check(player.global_position.z < 9.0, "player works without visual")
	Input.action_release("move_forward")
	if DisplayServer.get_name() != "headless":
		check_mouse_orbit()
	else:
		print("SKIP mouse capture/orbit: run without --headless")
	var key := InputEventAction.new()
	key.pressed = true
	key.action = "camera_isometric"
	key.pressed = true
	world.cameras._unhandled_input(key)
	check(world.cameras.iso.current, "camera action switches to isometric")
	key.action = "camera_third_person"
	world.cameras._unhandled_input(key)
	check(world.cameras.third.current, "camera action switches back")
	if DisplayServer.get_name() != "headless":
		check_mouse_capture(key)
	print("RESULT edge failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

func check_mouse_orbit() -> void:
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(100, 10000)
	world.cameras._unhandled_input(mouse)
	check(is_equal_approx(world.cameras.pitch, deg_to_rad(world.cameras.config.min_pitch)), "mouse pitch clamps")
	check(world.cameras.yaw < -0.2, "mouse changes orbit yaw")

func check_mouse_capture(key: InputEventAction) -> void:
	key.action = "release_mouse"
	world.cameras._unhandled_input(key)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape releases mouse")
	world.cameras._unhandled_input(key)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Escape captures mouse")

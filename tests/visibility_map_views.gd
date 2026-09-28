extends "res://tests/player_milestone.gd"

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/map_" + label + ".png")

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await place(Vector3(4, 0.02, 1))
	Input.action_press("crouch")
	await frames(3)
	player.global_position = Vector3(4, 0.02, -3)
	world.cameras.set_mode(true)
	await frames(45)
	check(world.cameras.occlusion.obstruction_count >= 1, "existing low roof detected")
	await capture("roof")
	await place(Vector3(9.5, 0.02, 4))
	world.cameras.set_mode(true)
	await frames(45)
	check(world.cameras.occlusion.obstruction_count >= 1, "existing corridor wall detected")
	await capture("corridor")
	await place(Vector3(-7, 0.02, 5))
	world.cameras.set_mode(true)
	await frames(45)
	check(world.cameras.occlusion.obstruction_count >= 1, "existing obstacle detected")
	await capture("obstacle")
	for i in 4:
		world.cameras.set_mode(false)
		await frames(1)
		check(world.cameras.occlusion.obstruction_count == 0, "rapid F1 restores immediately")
		world.cameras.set_mode(true)
		await frames(12)
	await capture("reentry")
	# Exercise real input/rendering in both modes; stop/start, reverse, diagonal, crouch.
	for iso_mode in [false, true]:
		await place(Vector3(0, 0.02, 10))
		world.cameras.set_mode(iso_mode)
		for actions in [["move_forward"], [], ["sprint", "move_forward"], [], ["move_backward"], ["move_forward", "move_left"], ["crouch", "move_backward"]]:
			for action in ["move_forward", "move_backward", "move_left", "sprint", "crouch"]:
				Input.action_release(action)
			for action in actions:
				Input.action_press(action)
			await frames(20)
		await capture("movement_iso" if iso_mode else "movement_third")
	print("RESULT map visibility failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

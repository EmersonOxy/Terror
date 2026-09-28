extends "res://tests/player_milestone.gd"

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	await frames(12)
	for isometric in [false, true]:
		await place(Vector3(0, 0.02, 10))
		world.cameras.set_mode(isometric)
		Input.action_press("move_forward")
		await frames(1)
		check(player.velocity.length() < 1.0, "brief acceleration remains")
		await frames(8)
		check(horizontal_speed() > 3.19, "walk reaches target within 150ms")
		Input.action_release("move_forward")
		await frames(7)
		check(horizontal_speed() < 0.01, "walk stops within 117ms")
		Input.action_press("sprint")
		Input.action_press("move_forward")
		await frames(15)
		check(absf(horizontal_speed() - 5.8) < 0.01, "run reaches unchanged maximum in 250ms")
		Input.action_release("move_forward")
		await frames(12)
		check(horizontal_speed() < 0.01, "run stops within 200ms")
		Input.action_release("sprint")
		Input.action_press("move_forward")
		await frames(10)
		var previous := player.velocity
		Input.action_release("move_forward")
		Input.action_press("move_backward")
		await frames(7)
		check(player.velocity.dot(previous) < 0.0, "direction reverses within 117ms")
		await frames(8)
		check(horizontal_speed() > 3.19, "reverse reaches walking target within 250ms")
		Input.action_press("move_left")
		await frames(15)
		check(absf(horizontal_speed() - 3.2) < 0.01, "diagonal maximum preserved")
		Input.action_press("crouch")
		await frames(10)
		check(absf(horizontal_speed() - 1.6) < 0.01, "crouch maximum preserved")
	print("RESULT responsiveness failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

func horizontal_speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()

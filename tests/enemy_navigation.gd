extends "res://tests/player_milestone.gd"

var enemy: Enemy

func route(from: Vector3, destination: Vector3, description: String) -> void:
	enemy.set_physics_process(false)
	enemy.global_position = from
	enemy.velocity = Vector3.ZERO
	enemy.motor.stop()
	enemy.patrol_points.clear()
	var marker := Marker3D.new()
	world.add_child(marker)
	marker.global_position = destination
	enemy.patrol_points.append(marker)
	enemy.set_physics_process(true)
	var highest := from.y
	var crossed_wall := false
	var reached := false
	for i in 1100:
		await frames(1)
		highest = maxf(highest, enemy.global_position.y)
		if absf(enemy.global_position.x) < 0.19 and enemy.global_position.z < -20.5 and enemy.global_position.z > -25.5:
			crossed_wall = true
		if enemy.global_position.distance_to(destination) < 0.48:
			reached = true
			break
	print("ROUTE ", description, " position=", enemy.global_position, " highest=", highest, " queries=", enemy.motor.path_updates)
	check(reached, description)
	check(not crossed_wall, "route does not cross solid central wall")
	enemy.set_physics_process(false)
	enemy.patrol_points.clear()
	marker.queue_free()

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	for node in world.get_node("EnemyTestArea").enemies:
		node.set_candidate(null)
		node.set_physics_process(false)
		if node.name != "Sentry":
			node.queue_free()
	enemy = world.get_node("EnemyTestArea/Sentry")
	enemy.patrol_points.clear()
	enemy.set_physics_process(true)
	await frames(30)
	check(enemy.state == Enemy.State.IDLE and enemy.motor.path_updates == 0, "idle performs no path queries")
	check(enemy.is_on_floor(), "enemy capsule rests on floor")
	await route(Vector3(-6, 0.02, -18), Vector3(-6, 0.72, -22.4), "navigation climbs three 24cm steps")
	await route(Vector3(-6, 0.72, -22.4), Vector3(-6, 0.02, -28), "navigation descends ramp")
	await route(Vector3(-6, 0.02, -28), Vector3(-6, 0.72, -22.4), "navigation climbs ramp")
	await route(Vector3(7.5, 0.02, -28), Vector3(7.5, 0.02, -20), "navigation crosses corridor")
	await route(Vector3(-2, 0.02, -23), Vector3(2, 0.02, -23), "navigation routes around central wall")
	enemy.global_position = Vector3(3, 0.02, -22)
	enemy.facing = Vector3.BACK
	enemy.set_candidate(player)
	player.global_position = Vector3(3, 0.02, -18)
	player.velocity = Vector3.ZERO
	enemy.set_physics_process(true)
	var updates := enemy.motor.path_updates
	await frames(180)
	check(enemy.state == Enemy.State.ATTACK or enemy.state == Enemy.State.CHASE, "detected player pursued into attack range")
	check(enemy.global_position.distance_to(player.global_position) < 1.6, "chase reaches player")
	check(enemy.motor.path_updates - updates < 15, "chase path refresh throttled")
	enemy.take_damage(DamageData.new(1, player))
	var position := enemy.global_position
	await frames(10)
	check(enemy.state == Enemy.State.HIT_REACTION and enemy.global_position.distance_to(position) < 0.03, "stagger pauses pursuit")
	await frames(25)
	check(enemy.state != Enemy.State.HIT_REACTION, "stagger expires")
	print("RESULT enemy navigation failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

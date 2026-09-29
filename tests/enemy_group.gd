extends "res://tests/player_milestone.gd"

var starts: Dictionary = {}
var detected: Dictionary = {}

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	player.global_position = Vector3(3, 0.02, -20)
	var enemies: Array = world.get_node("EnemyTestArea").enemies
	for i in enemies.size():
		var enemy: Enemy = enemies[i]
		enemy.patrol_points.clear()
		enemy.global_position = Vector3(1.6 + i * 1.4, 0.02, -26)
		enemy.facing = Vector3.BACK
		enemy.definition = enemy.definition.duplicate()
		enemy.definition.attack_damage = 2
		enemy.combat.config = enemy.definition
		starts[enemy] = 0
		detected[enemy] = 0
		enemy.combat.attack_started.connect(func(): starts[enemy] += 1)
		enemy.player_detected.connect(func(_target: Node3D): detected[enemy] += 1)
	var overlap := false
	for frame in 480:
		await frames(1)
		for a in enemies.size():
			for b in range(a + 1, enemies.size()):
				if enemies[a].global_position.distance_to(enemies[b].global_position) < 0.5:
					overlap = true
	for enemy in enemies:
		print("GROUP ", enemy.name, " detected=", detected[enemy], " attacks=", starts[enemy], " position=", enemy.global_position)
		check(detected[enemy] > 0 and starts[enemy] > 0, "independent instance detects, chases and attacks")
	check(not overlap, "enemy collisions prevent stacked overlapping capsules")
	var victim: Enemy = enemies[0]
	victim.take_damage(DamageData.new(100, player))
	await frames(3)
	check(victim.state == Enemy.State.DEAD and not enemies[1].health.dead and not enemies[2].health.dead, "one death does not stop other enemies")
	var previous: int = starts[enemies[1]] + starts[enemies[2]]
	await frames(120)
	check(starts[enemies[1]] + starts[enemies[2]] > previous, "remaining instances continue combat")
	print("RESULT enemy group failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

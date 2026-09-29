extends "res://tests/player_milestone.gd"

func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/enemy_" + name + ".png")

func aim_at(enemy: Enemy, iso_mode: bool) -> void:
	if iso_mode:
		var screen: Vector2 = world.cameras.iso.unproject_position(enemy.damage_point())
		Input.warp_mouse(screen)
		var event := InputEventMouseMotion.new()
		event.position = screen
		event.global_position = screen
		Input.parse_input_event(event)
		await frames(2)
	else:
		Input.action_press("aim")
		for i in 5:
			var direction: Vector3 = enemy.damage_point() - world.cameras.third.global_position
			world.cameras.yaw = atan2(-direction.x, -direction.z)
			world.cameras.pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())
			await frames(5)

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for iso_mode in [false, true]:
		world = load("res://scenes/world/test_world.tscn").instantiate()
		root.add_child(world)
		player = world.player
		var enemy: Enemy = world.get_node("EnemyTestArea/Sentry")
		for other in world.get_node("EnemyTestArea").enemies:
			if other != enemy:
				other.queue_free()
		player.global_position = Vector3(3, 0.02, -18)
		enemy.global_position = Vector3(3, 0.02, -25)
		enemy.facing = Vector3.BACK
		world.cameras.set_mode(iso_mode)
		player.inventory.add_quantity(load("res://resources/items/ranged.tres"), 1)
		player.items.equip(0, ItemDefinition.EquipSlot.WEAPON)
		await frames(50)
		check(enemy.perception.target == player and enemy.state == Enemy.State.CHASE, "camera-independent detection and chase")
		await aim_at(enemy, iso_mode)
		Input.action_press("attack")
		await frames(1)
		Input.action_release("attack")
		await frames(2)
		check(enemy.health.current == 60 and enemy.state == Enemy.State.HIT_REACTION, "aim and existing ranged input hit moving enemy")
		await shot("hit_iso" if iso_mode else "hit_third")
		var before := player.status.health
		var windup_seen := false
		for i in 240:
			await frames(1)
			if enemy.state == Enemy.State.ATTACK and not windup_seen:
				windup_seen = true
				await shot("windup_iso" if iso_mode else "windup_third")
			if player.status.health < before:
				break
		check(windup_seen and player.status.health < before, "enemy resumes approach and attacks Player")
		check(enemy.is_on_floor() and absf(enemy.global_position.y) < 0.03, "visual actor grounded with capsule")
		enemy.take_damage(DamageData.new(100, player))
		await frames(3)
		await shot("dead_iso" if iso_mode else "dead_third")
		check(enemy.collision_layer == 0 and is_equal_approx(enemy.visual.mesh.position.y, enemy.definition.radius), "corpse visual lowered and physical obstruction removed")
		Input.action_release("aim")
		world.queue_free()
		await process_frame
	print("RESULT enemy visual failures=", failures)
	quit(1 if failures else 0)

extends "res://tests/player_milestone.gd"

var enemy: Enemy
var detections: int = 0
var losses: int = 0
var deaths: int = 0

func position_pair(enemy_at: Vector3, player_at: Vector3, facing: Vector3) -> void:
	enemy.global_position = enemy_at
	enemy.velocity = Vector3.ZERO
	enemy.facing = facing
	player.global_position = player_at
	player.velocity = Vector3.ZERO
	await frames(3)

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	enemy = world.get_node("EnemyTestArea/Sentry")
	for node in world.get_node("EnemyTestArea").enemies:
		node.set_physics_process(false)
	enemy.player_detected.connect(func(_target: Node3D): detections += 1)
	enemy.player_lost.connect(func(_target: Node3D): losses += 1)
	enemy.died.connect(func(_actor: Enemy): deaths += 1)
	await frames(4)
	await position_pair(Vector3(3, 0, -22), Vector3(3, 0.02, -25), Vector3.FORWARD)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.target == player and detections == 1, "front target detected through distance/FOV/LOS")
	enemy.perception.clear()
	await position_pair(Vector3(3, 0, -22), Vector3(3, 0.02, -19), Vector3.FORWARD)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.target == null, "nearby player behind enemy is not detected")
	player.global_position = Vector3(3, 0.02, -40)
	await frames(2)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.target == null, "distant player outside detection radius ignored")
	await position_pair(Vector3(-2, 0, -23), Vector3(2, 0.02, -23), Vector3.RIGHT)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.target == null, "solid wall blocks visual perception")
	player.global_position = Vector3(-2, 0.02, -19)
	enemy.facing = Vector3.BACK
	await frames(2)
	enemy.perception.tick(0.2, enemy.facing)
	var known := enemy.perception.last_known_position
	player.global_position = Vector3(2, 0.02, -23)
	enemy.facing = Vector3.RIGHT
	await frames(2)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.target == player and not enemy.perception.visible_target and enemy.perception.last_known_position == known, "loss retains only last known position")
	enemy.perception.tick(1.0, enemy.facing)
	check(enemy.perception.target == player, "short occlusion preserves memory")
	player.global_position = Vector3(-2, 0.02, -19)
	enemy.facing = Vector3.BACK
	await frames(2)
	enemy.perception.tick(0.2, enemy.facing)
	check(enemy.perception.visible_target and enemy.perception.memory_remaining == enemy.definition.lose_target_delay, "sight recovery refreshes memory")
	player.global_position = Vector3(2, 0.02, -23)
	enemy.facing = Vector3.RIGHT
	await frames(2)
	enemy.perception.tick(0.2, enemy.facing)
	enemy.perception.tick(3.2, enemy.facing)
	check(enemy.perception.target == null and losses >= 2, "expired memory forgets target and emits loss")

	await position_pair(Vector3(3, 0, -22), Vector3(3, 0.02, -20.9), Vector3.BACK)
	check(enemy.combat.begin(player), "valid melee starts windup")
	var before := player.status.health
	enemy.combat.tick(0.2)
	check(player.status.health == before, "windup does not apply immediate damage")
	player.global_position.z = -18
	await frames(2)
	enemy.combat.tick(0.6)
	check(player.status.health == before, "escaping during windup avoids damage")
	enemy.combat.tick(2)
	await position_pair(Vector3(-0.65, 0, -23), Vector3(-0.65, 0.02, -21.9), Vector3.BACK)
	check(enemy.combat.begin(player), "attack starts before obstruction")
	player.global_position = Vector3(0.65, 0.02, -23)
	await frames(2)
	enemy.combat.tick(0.8)
	check(player.status.health == before, "wall appearing in line of attack prevents damage")
	enemy.combat.tick(2)
	await position_pair(Vector3(3, 0, -22), Vector3(3, 0.02, -20.9), Vector3.BACK)
	enemy.combat.begin(player)
	enemy.combat.tick(0.8)
	check(player.status.health == before - enemy.definition.attack_damage, "enemy DamageData reaches existing Player Status")
	check(not enemy.combat.begin(player), "enemy attack cooldown enforced")
	enemy.combat.tick(2)
	enemy.combat.begin(player)
	enemy.take_damage(DamageData.new(10, player))
	check(enemy.state == Enemy.State.HIT_REACTION and not enemy.combat.winding_up, "damage interrupts attack and enters hit reaction")

	player.inventory.add_quantity(load("res://resources/items/melee.tres"), 1)
	player.inventory.add_quantity(load("res://resources/items/ranged.tres"), 1)
	player.inventory.add_quantity(load("res://resources/items/ammo.tres"), 12)
	player.items.equip(0, ItemDefinition.EquipSlot.WEAPON)
	var aim := AimSample.new(player.damage_point(), enemy.damage_point(), true)
	player.combat.tick(1, true)
	check(player.combat.attack(aim) and enemy.health.current == 45, "existing melee damages enemy through generic contract")
	check(not player.combat.attack(aim), "player cooldown remains enforced against enemy")
	player.combat.tick(1, true)
	player.status.consume_stamina(1000)
	check(not player.combat.attack(aim), "insufficient stamina still blocks melee")
	player.status.tick(2, false)
	player.status.tick(5, false)
	player.global_position.z = -17
	await frames(2)
	player.combat.attack(AimSample.new(player.damage_point(), enemy.damage_point(), true))
	check(enemy.health.current == 45, "melee cannot reach distant enemy")
	await position_pair(Vector3(-0.65, 0, -23), Vector3(0.65, 0.02, -23), Vector3.RIGHT)
	player.combat.tick(1, true)
	player.combat.attack(AimSample.new(player.damage_point(), enemy.damage_point(), true))
	check(enemy.health.current == 45, "wall blocks player melee against enemy")
	player.items.equip(1, ItemDefinition.EquipSlot.WEAPON)
	player.combat.tick(1, true)
	player.combat.attack(AimSample.new(player.damage_point(), enemy.damage_point(), true))
	check(enemy.health.current == 45 and player.combat.weapon().ammo_in_magazine == 5, "wall blocks ranged damage while spending ammo")
	await position_pair(Vector3(3, 0, -26), Vector3(3, 0.02, -18), Vector3.BACK)
	for i in 2:
		player.combat.tick(1, true)
		player.combat.attack(AimSample.new(player.damage_point(), enemy.damage_point(), true))
	check(enemy.health.current == 5 and player.combat.weapon().ammo_in_magazine == 3, "multiple ranged hits and magazine independent of enemy class")
	player.combat.reload()
	player.combat.tick(2, true)
	check(player.combat.weapon().ammo_in_magazine == 6 and player.combat.reserve() == 9, "existing reload remains functional during enemy encounter")
	player.combat.attack(AimSample.new(player.damage_point(), enemy.damage_point(), true))
	await frames(2)
	check(enemy.state == Enemy.State.DEAD and deaths == 1 and enemy.health.dead, "lethal weapon damage emits one enemy death")
	check(enemy.collision_layer == 0 and enemy.collider.disabled and not enemy.is_physics_processing(), "corpse stops AI and removes blocking collider")
	check(not enemy.take_damage(DamageData.new(20, player)) and deaths == 1, "dead enemy never receives damage or dies twice")
	var another: Enemy = world.get_node("EnemyTestArea/PatrollerB")
	check(not another.health.dead and another.health.current == another.definition.max_health, "other instances retain independent health")
	another.global_position = player.global_position + Vector3(0, 0, -1)
	await frames(2)
	player.receive_damage(99)
	another.combat.begin(player)
	another.combat.tick(1)
	check(player.status.dead and another.perception.candidate == null and not another.combat.winding_up, "Player death clears targets and pending attacks via explicit binding")
	print("RESULT enemy core failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

extends SceneTree

var world: Node3D
var player: Player
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func place(at: Vector3) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint", "crouch", "interact"]:
		Input.action_release(action)
	player.global_position = at
	player.velocity = Vector3.ZERO
	world.cameras.yaw = 0.0
	world.cameras.set_mode(false)
	await frames(8)

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	await frames(12)
	check(player.is_on_floor(), "spawn grounded")
	check(InputMap.action_get_events("camera_third_person")[0].physical_keycode == KEY_F1, "F1 input mapping")
	check(InputMap.action_get_events("camera_isometric")[0].physical_keycode == KEY_F2, "F2 input mapping")
	await place(Vector3(0, 0.02, 10))
	Input.action_press("move_forward")
	await frames(60)
	check(player.global_position.z < 7.2, "WASD walk displacement")
	check(absf(player.velocity.z) > 3.0, "walk speed reached")
	Input.action_release("move_forward")
	await frames(20)
	check(player.velocity.length() < 0.05, "deceleration stops")
	await place(Vector3(0, 0.02, 10))
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await frames(35)
	check(player.movement.sprinting and player.status.stamina < 90.0, "sprint consumes stamina")
	player.status.consume_stamina(1000.0)
	await frames(2)
	check(not player.movement.sprinting and player.velocity.length() > 0.0, "exhaustion falls back to walk")
	Input.action_release("sprint")
	Input.action_release("move_forward")
	await frames(30)
	check(player.status.stamina == 0.0, "regeneration delay")
	await frames(150)
	check(player.status.stamina > 25.0 and not player.status.exhausted, "stamina recovery")
	await place(Vector3(4, 0.02, 1))
	Input.action_press("crouch")
	Input.action_press("move_forward")
	await frames(130)
	check(player.global_position.z < -2.0 and player.movement.crouched, "crouch enters low passage")
	Input.action_release("move_forward")
	Input.action_release("crouch")
	await frames(15)
	check(player.movement.crouched and not player.movement.can_stand(), "roof blocks standing")
	Input.action_press("move_backward")
	await frames(150)
	Input.action_release("move_backward")
	await frames(15)
	check(not player.movement.crouched, "stands after leaving roof")
	await place(Vector3(-2, 0.02, 1))
	Input.action_press("move_forward")
	await frames(100)
	check(player.global_position.y > 1.1 and player.global_position.z < -3.7, "climbs five 24cm steps")
	print("STEP position ", player.global_position)
	await place(Vector3(-7, 0.02, 0.5))
	Input.action_press("move_forward")
	await frames(125)
	check(player.global_position.y > 1.1 and player.global_position.z < -5.0, "climbs 15 degree ramp")
	print("RAMP position ", player.global_position)
	Input.action_release("move_forward")
	await frames(20)
	check(player.is_on_floor(), "floor snap on ramp/landing")
	await place(Vector3(-3, 0.02, 3.8))
	player.movement.facing = Vector3.FORWARD
	await frames(3)
	check(player.interaction.current == world.get_node("InteractionTest"), "proximity/facing detection")
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(world.get_node("InteractionTest").active, "E activates object")
	await frames(2)
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(not world.get_node("InteractionTest").active, "E deactivates object")
	await place(Vector3(0, 0.02, 1.8))
	player.movement.facing = Vector3.FORWARD
	await frames(3)
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(player.status.health == 70.0, "damage through interaction")
	await place(Vector3(3, 0.02, 3.8))
	player.movement.facing = Vector3.FORWARD
	await frames(3)
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	check(player.status.health == 100.0, "healing through interaction")
	world.cameras.set_mode(true)
	await frames(2)
	check(world.cameras.iso.current and not world.cameras.third.current, "isometric activation")
	check(player.interaction.current == world.get_node("HealTest"), "interaction independent of camera")
	await place(Vector3(0, 0.02, 10))
	world.cameras.set_mode(true)
	var start := player.global_position
	Input.action_press("move_forward")
	await frames(35)
	var displacement := player.global_position - start
	check(displacement.x < -0.5 and displacement.z < -0.5, "isometric relative movement")
	world.cameras.set_mode(false)
	await frames(2)
	check(world.cameras.third.current and is_zero_approx(player.movement_basis.get_euler().y), "switch back keeps same player")
	await place(Vector3(-6, 0.02, 3.9))
	await frames(70)
	check(world.cameras.arm.get_hit_length() < world.cameras.config.distance - 0.5, "spring arm retracts at obstacle")
	print("CAMERA hit length ", world.cameras.arm.get_hit_length())
	await place(Vector3(0, 0.02, 10))
	player.status.damage(1000.0)
	var death_position := player.global_position
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await frames(20)
	check(player.status.dead and player.global_position.distance_to(death_position) < 0.02, "death blocks movement")
	check(not player.movement.sprinting and player.interaction.current == null, "death blocks sprint/interaction")
	player.status.heal(100.0)
	check(player.status.health == 0.0, "heal does not resurrect")
	print("RESULT failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

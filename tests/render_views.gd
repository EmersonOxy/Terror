extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Node3D = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	root.size = Vector2i(1280, 720)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for mode in [false, true]:
		world.cameras.set_mode(mode)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		for i in 30:
			await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/%s.png" % ("isometric" if mode else "third_person"))
	quit()

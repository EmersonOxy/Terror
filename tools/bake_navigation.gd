extends SceneTree

func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	var world := load("res://scenes/world/test_world.tscn").instantiate() as Node3D
	world.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(world)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.3
	mesh.cell_height = 0.05
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.filter_walkable_low_height_spans = true
	var geometry := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, geometry, world)
	NavigationServer3D.bake_from_source_geometry_data(mesh, geometry)
	var error := ResourceSaver.save(mesh, "res://resources/navigation/test_world.tres")
	print("NAV BAKE polygons=", mesh.get_polygon_count(), " result=", error)
	world.queue_free()
	await process_frame
	quit(0 if error == OK and mesh.get_polygon_count() > 0 else 1)

extends "res://tests/player_milestone.gd"

var blocks: Array[StaticBody3D] = []
var shared := StandardMaterial3D.new()
var effect: IsometricOcclusion

func block(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.add_to_group("camera_occluder")
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.material_override = shared
	body.add_child(shape)
	body.add_child(mesh)
	world.add_child(body)
	body.global_position = at
	blocks.append(body)
	return body

func opacity(body: StaticBody3D) -> float:
	return body.get_node("Mesh").get_active_material(0).albedo_color.a

func snapshot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/visibility_" + label + ".png")

func run() -> void:
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	effect = world.cameras.occlusion
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await place(Vector3(0, 0.02, 10))
	world.cameras.set_mode(true)
	await frames(45)
	check(effect.obstruction_count == 0, "clear view ignores floor/player/unrelated objects")
	var line: Vector3 = world.cameras.iso.global_basis.z
	var aim := player.global_position + Vector3.UP * 0.9
	shared.albedo_color = Color(0.45, 0.48, 0.5)
	var box := block(aim + line * 2.0, Vector3(1.5, 1.8, 1.5))
	var untouched := block(aim + Vector3(-3, 0, 0), Vector3.ONE)
	await frames(3)
	var first_alpha := opacity(box)
	check(first_alpha > 0.28 and first_alpha <= 1.0, "fade begins gradually")
	await snapshot("fade_start")
	await frames(18)
	check(is_equal_approx(opacity(box), 0.28), "box fades to configured opacity")
	check(is_equal_approx(opacity(untouched), 1.0) and shared.albedo_color.a == 1.0, "shared material and nearby object unchanged")
	check(player.visual.obstruction_highlight.strength > 0.2, "subtle visual-layer highlight active")
	await snapshot("box")
	var wall := block(aim + line * 4.0, Vector3(2.5, 2.5, 0.25))
	await frames(20)
	check(effect.obstruction_count == 2 and opacity(wall) < 0.3, "two simultaneous blockers fade")
	await snapshot("two_blockers")
	world.cameras.set_mode(false)
	check(opacity(box) == 1.0 and opacity(wall) == 1.0, "F1 immediately restores all materials")
	check(player.visual.obstruction_highlight.strength == 0.0, "F1 removes highlight")
	await frames(4)
	check(effect.obstruction_count == 0, "third person never fades structures")
	world.cameras.set_mode(true)
	await frames(20)
	check(opacity(box) < 0.3, "F2 resumes obstruction handling")
	box.global_position += Vector3.LEFT * 5.0
	wall.global_position += Vector3.LEFT * 5.0
	await frames(3)
	check(opacity(box) < 0.5, "short loss held to avoid flicker")
	box.global_position -= Vector3.LEFT * 5.0
	await frames(6)
	check(opacity(box) < 0.3, "rapid reentry does not flash opaque")
	box.global_position += Vector3.LEFT * 5.0
	await frames(30)
	check(opacity(box) == 1.0 and box.get_node("Mesh").material_override == shared, "leaving view restores exact original material")
	check(player.visual.obstruction_highlight.strength == 0.0, "clear view removes highlight")
	# A narrow pillar grazing the silhouette, outside the central ray.
	var corner := block(aim + line * 2.0 + world.cameras.iso.global_basis.x * 0.28, Vector3(0.15, 1.8, 0.15))
	await frames(20)
	check(opacity(corner) < 0.3, "volume detects partial pillar/edge occlusion")
	await snapshot("partial_pillar")
	corner.get_node("Mesh").hide()
	await frames(30)
	check(effect.obstruction_count == 0, "invisible mesh cannot trigger obstruction")
	corner.get_node("Mesh").show()
	await frames(20)
	world.cameras.config.occlusion_enabled = false
	await frames(25)
	check(opacity(corner) == 1.0, "transparency toggle restores obstacle")
	check(player.visual.obstruction_highlight.strength > 0.2, "highlight independently enabled")
	world.cameras.config.highlight_enabled = false
	await frames(2)
	check(player.visual.obstruction_highlight.strength == 0.0, "both toggles off restores visual")
	world.cameras.config.occlusion_enabled = true
	world.cameras.config.highlight_enabled = true
	await frames(20)
	world.remove_child(corner)
	check(opacity(corner) == 1.0, "removing obstacle from tree restores it")
	corner.free()
	box.global_position = aim + line * 2.0
	await frames(20)
	world.cameras.iso.clear_current()
	await frames(2)
	check(opacity(box) == 1.0, "external camera deactivation restores materials")
	world.cameras.set_mode(true)
	await frames(20)
	effect.process_mode = Node.PROCESS_MODE_DISABLED
	check(opacity(box) == 1.0, "disabled component restores immediately")
	effect.process_mode = Node.PROCESS_MODE_INHERIT
	await frames(20)
	root.remove_child(world)
	check(opacity(box) == 1.0, "scene exit restores material")
	print("RESULT visibility failures=", failures)
	world.free()
	await process_frame
	quit(1 if failures else 0)

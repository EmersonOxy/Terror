extends "res://tests/items_ui.gd"

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/narrative_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	world = load("res://scenes/world/test_world.tscn").instantiate()
	root.add_child(world)
	player = world.player
	ui = world.get_node("InventoryUI")
	var director: NarrativeDirector = world.get_node("NarrativeTestArea")
	var narrative := director.narrative
	var subtitle := director.subtitles
	await place(Vector3(6, 0.02, 11.5))
	var sequence := DialogueSequence.new()
	sequence.sequence_id = &"long_text_test"
	var line := DialogueLine.new()
	line.speaker_id = &"player_default"
	line.speaker_name = "ÉMERSON"
	line.text = "Este texto é apenas um teste de quebra automática de linha. Mesmo durante uma fala mais longa, ainda preciso enxergar o cenário, consultar a mochila e continuar jogando. O nome, a legenda e os controles devem permanecer legíveis, sem sair do painel ou cobrir o inventário."
	line.duration = 100
	sequence.lines.append(line)
	narrative.play_sequence(sequence)
	for resolution in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1024, 576)]:
		root.size = resolution
		for iso_mode in [false, true]:
			world.cameras.set_mode(iso_mode)
			for open_inventory in [false, true]:
				ui.set_open(open_inventory)
				await frames(12)
				var viewport := root.get_visible_rect().size
				var rect := subtitle.panel.get_global_rect()
				check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= viewport.x and rect.end.y <= viewport.y, "subtitle stays within viewport")
				check(subtitle.text.get_line_count() > 1, "long subtitle wraps automatically")
				check(subtitle.text.get_global_rect().end.y <= rect.end.y, "wrapped text stays inside panel")
				if open_inventory:
					check(rect.end.x < ui.panel.get_global_rect().position.x, "subtitle avoids inventory side panel")
				for control in subtitle.avoided_controls:
					if control.is_visible_in_tree() and not control.text.is_empty():
						check(not rect.intersects(control.get_global_rect()), "subtitle avoids existing debug/prompt/toast")
				check(not player.controls_locked or ui.is_open, "automatic subtitle adds no gameplay lock")
				await capture("%dx%d_%s_%s" % [resolution.x, resolution.y, "iso" if iso_mode else "third", "inventory" if open_inventory else "game"])
	ui.set_open(false)
	narrative.advance()
	root.size = Vector2i(1280, 720)
	for iso_mode in [false, true]:
		world.cameras.set_mode(iso_mode)
		player.movement.facing = Vector3.FORWARD
		await key_event(KEY_E)
		check(narrative.interactive_active, "NPC dialogue begins in each camera")
		await frames(4)
		await capture("dialogue_iso" if iso_mode else "dialogue_third")
		await key_event(KEY_SPACE)
		await key_event(KEY_SPACE)
		await key_event(KEY_SPACE)
		check(not narrative.interactive_active and not player.controls_locked, "dialogue releases controls in each camera")
	print("RESULT narrative visual failures=", failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

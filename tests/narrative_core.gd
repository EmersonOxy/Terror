extends "res://tests/player_milestone.gd"

func sequence(id: StringName, priority: DialogueSequence.Priority, interruptible: bool = true, interactive: bool = false) -> DialogueSequence:
	var value := DialogueSequence.new()
	value.sequence_id = id
	value.priority = priority
	value.interruptible = interruptible
	value.interactive = interactive
	for index in 2:
		var line := DialogueLine.new()
		line.speaker_id = &"test"
		line.text = "%s %d" % [id, index]
		line.duration = 1.0
		value.lines.append(line)
	return value

func run() -> void:
	var narrative := NarrativeSystem.new()
	narrative.profile = load("res://resources/dialogue/events/default_profile.tres")
	root.add_child(narrative)
	narrative.set_process(false)
	check(not narrative.request_event(&"unknown"), "unknown event rejected safely")
	check(not narrative.play_sequence(DialogueSequence.new()), "empty sequence rejected")
	check(narrative.request_event(&"test_area_enter"), "event ID resolves resource content")
	check(narrative.current_line().text == "Não gosto daqui.", "content remains outside gameplay")
	narrative._process(0.5)
	check(narrative.request_event(&"test_player_damaged"), "high-priority damage accepted")
	check(narrative.current_event() == &"test_player_damaged" and narrative.queue_size() == 1, "high priority interrupts permitted low priority")
	narrative.advance()
	check(narrative.current_event() == &"test_area_enter", "interrupted comment resumes")
	narrative._process(2.6)
	check(narrative.current_line() == null, "resumed comment retains remaining duration")
	check(not narrative.request_event(&"test_player_damaged"), "once-per-session event cannot repeat")
	check(not narrative.request_event(&"test_area_enter"), "event cooldown blocks repeat")
	narrative._process(1.0)
	check(narrative.request_event(&"test_area_enter"), "cooldown expires")
	check(not narrative.request_event(&"test_area_enter") and narrative.queue_size() == 0, "duplicate active event never stacks")
	narrative.advance()

	var first := sequence(&"first", DialogueSequence.Priority.NORMAL)
	var second := sequence(&"second", DialogueSequence.Priority.NORMAL)
	narrative.play_sequence(first)
	narrative.play_sequence(second)
	check(narrative.current_event() == &"first" and narrative.queue_size() == 1, "equal priority preserves FIFO without overlap")
	narrative._process(1.1)
	check(narrative.current_line().text == "first 1", "automatic sequence advances in order")
	narrative._process(1.1)
	check(narrative.current_event() == &"second", "next queued sequence begins")
	narrative.advance()
	narrative.advance()

	var protected := sequence(&"protected", DialogueSequence.Priority.LOW, false)
	var urgent := sequence(&"urgent", DialogueSequence.Priority.HIGH)
	var normal := sequence(&"normal", DialogueSequence.Priority.NORMAL)
	narrative.play_sequence(protected)
	narrative.play_sequence(normal)
	narrative.play_sequence(urgent)
	check(narrative.current_event() == &"protected", "noninterruptible sequence resists higher priority")
	narrative.advance()
	narrative.advance()
	check(narrative.current_event() == &"urgent", "queue chooses highest priority after protected sequence")
	narrative.advance()
	narrative.advance()
	check(narrative.current_event() == &"normal", "lower priority remains queued without loss")
	narrative.advance()
	narrative.advance()

	var dialogue := sequence(&"conversation", DialogueSequence.Priority.HIGH, false, true)
	narrative.play_sequence(dialogue)
	narrative._process(100)
	check(narrative.interactive_active and narrative.current_line().text == "conversation 0", "interactive line never auto-advances")
	check(not narrative.play_sequence(dialogue), "repeated interactive request rejected")
	narrative.request_event(&"test_weapon_pickup")
	check(narrative.current_event() == &"conversation" and narrative.queue_size() == 1, "comments wait behind protected conversation")
	narrative.advance()
	check(narrative.current_line().text == "conversation 1", "manual continuation advances one line")
	narrative.advance()
	check(not narrative.interactive_active and narrative.current_event() == &"test_weapon_pickup", "dialogue completion restores automatic playback")
	narrative.stop()
	check(narrative.current_line() == null and narrative.queue_size() == 0 and not narrative.interactive_active, "stop atomically clears queue and interactive state")
	check(not narrative.request_event(&"test_enemy_killed") and not narrative.play_sequence(first), "death/disabled director accepts no new lines")
	var calculated := DialogueLine.new()
	calculated.text = "Uma fala com tempo calculado."
	check(calculated.display_duration() >= 2.0, "zero duration computes bounded reading time")
	narrative.queue_free()
	await process_frame
	print("RESULT narrative core failures=", failures)
	quit(1 if failures else 0)

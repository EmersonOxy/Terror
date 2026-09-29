class_name NarrativeSystem
extends Node

signal line_changed(line: DialogueLine, event_id: StringName, interactive: bool)
signal interactive_changed(active: bool)
signal sequence_finished(event_id: StringName, cancelled: bool)
@export var profile: NarrativeProfile
@export var max_queued: int = 16
var accepting: bool = true
var interactive_active: bool = false
var _clock: float = 0.0
var _serial: int = 0
var _events: Dictionary = {}
var _accepted_at: Dictionary = {}
var _queue: Array[Playback] = []
var _current: Playback

class Playback extends RefCounted:
	var sequence: DialogueSequence
	var event_id: StringName
	var index: int = 0
	var remaining: float
	var order: int

func _ready() -> void:
	if profile != null:
		for event in profile.events:
			if event != null and not event.event_id.is_empty():
				_events[event.event_id] = event

func _process(delta: float) -> void:
	_clock += delta
	if _current == null or interactive_active:
		return
	_current.remaining -= delta
	if _current.remaining <= 0.0:
		advance()

func current_event() -> StringName:
	return _current.event_id if _current != null else &""

func current_line() -> DialogueLine:
	return _current.sequence.lines[_current.index] if _current != null else null

func queue_size() -> int:
	return _queue.size()

func request_event(id: StringName) -> bool:
	var event := _events.get(id) as NarrativeEvent
	if event == null or not accepting:
		return false
	if _accepted_at.has(id) and (event.once_per_session or _clock - float(_accepted_at[id]) < event.cooldown):
		return false
	if not play_sequence(event.sequence, id):
		return false
	_accepted_at[id] = _clock
	return true

func can_start_interactive() -> bool:
	return accepting and not interactive_active and (_current == null or _current.sequence.interruptible)

func play_sequence(sequence: DialogueSequence, id: StringName = &"") -> bool:
	if not accepting or sequence == null or not sequence.is_valid() or _queue.size() >= max_queued:
		return false
	if id.is_empty():
		id = sequence.sequence_id
	if current_event() == id:
		return false
	for pending in _queue:
		if pending.event_id == id:
			return false
	if sequence.interactive and not can_start_interactive():
		return false
	var playback := Playback.new()
	playback.sequence = sequence
	playback.event_id = id
	playback.remaining = sequence.lines[0].display_duration()
	playback.order = _serial
	_serial += 1
	if _current == null:
		_activate(playback)
	elif _current.sequence.interruptible and (sequence.interactive or sequence.priority > _current.sequence.priority):
		_queue.append(_current)
		_activate(playback)
	else:
		_queue.append(playback)
	return true

func _activate(playback: Playback) -> void:
	_current = playback
	_set_interactive(playback.sequence.interactive)
	line_changed.emit(current_line(), current_event(), interactive_active)

func _set_interactive(value: bool) -> void:
	if interactive_active != value:
		interactive_active = value
		interactive_changed.emit(value)

func advance() -> void:
	if _current == null:
		return
	_current.index += 1
	if _current.index < _current.sequence.lines.size():
		_current.remaining = current_line().display_duration()
		line_changed.emit(current_line(), current_event(), interactive_active)
		return
	var finished := _current.event_id
	_current = null
	sequence_finished.emit(finished, false)
	if not _queue.is_empty():
		_queue.sort_custom(func(a: Playback, b: Playback): return a.sequence.priority > b.sequence.priority if a.sequence.priority != b.sequence.priority else a.order < b.order)
		_activate(_queue.pop_front())
	else:
		_set_interactive(false)
		line_changed.emit(null, &"", false)

func stop() -> void:
	# Death/teardown drops pending lines atomically and never resumes an old comment.
	accepting = false
	var cancelled: Array[StringName] = []
	if _current != null:
		cancelled.append(_current.event_id)
	for playback in _queue:
		cancelled.append(playback.event_id)
	_current = null
	_queue.clear()
	_set_interactive(false)
	line_changed.emit(null, &"", false)
	for id in cancelled:
		sequence_finished.emit(id, true)

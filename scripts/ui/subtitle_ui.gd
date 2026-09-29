class_name SubtitleUI
extends CanvasLayer

@export var narrative: NarrativeSystem
@export var max_width: float = 620.0
@export var margin: float = 24.0
@export var show_debug: bool = false
var avoid_panel: Control
var avoided_controls: Array[Control] = []
var panel: PanelContainer
var speaker: Label
var text: Label
var hint: Label
var debug: Label

func _ready() -> void:
	process_priority = 20
	layer = 6
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.035, 0.83)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	speaker = _label(column, 16)
	speaker.modulate = Color(0.78, 0.86, 0.83)
	text = _label(column, 21)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint = _label(column, 14)
	debug = _label(column, 12)
	panel.hide()
	narrative.line_changed.connect(_show_line)

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _show_line(line: DialogueLine, _event_id: StringName, interactive: bool) -> void:
	panel.visible = line != null
	if line == null:
		return
	speaker.text = line.speaker_name if not line.speaker_name.is_empty() else String(line.speaker_id)
	speaker.visible = not speaker.text.is_empty()
	text.text = line.text
	hint.text = "Espaço · continuar" if interactive else ""
	hint.visible = interactive
	_layout()

func _process(_delta: float) -> void:
	if not panel.visible:
		return
	debug.visible = show_debug
	debug.text = "%s · fila %d" % [narrative.current_event(), narrative.queue_size()] if show_debug else ""
	if narrative.interactive_active:
		hint.text = "Feche o inventário · Espaço continua" if is_instance_valid(avoid_panel) and avoid_panel.is_visible_in_tree() else "Espaço · continuar"
	_layout()

func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var available := viewport.x
	if is_instance_valid(avoid_panel) and avoid_panel.is_visible_in_tree():
		available = minf(available, avoid_panel.get_global_rect().position.x)
	panel.custom_minimum_size.x = minf(max_width, available - margin * 2.0)
	panel.size.x = panel.custom_minimum_size.x
	panel.reset_size()
	var position := Vector2((available - panel.size.x) * 0.5, viewport.y - margin - panel.size.y)
	# Presentation-only collision avoidance for existing prompt/toast/debug labels.
	for control in avoided_controls:
		if not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		if control is Label and control.text.is_empty():
			continue
		var other := control.get_global_rect()
		if Rect2(position, panel.size).intersects(other):
			position.y = minf(position.y, other.position.y - panel.size.y - 10.0)
	panel.position = position

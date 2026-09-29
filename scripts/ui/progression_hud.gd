extends CanvasLayer

## Small, non-intrusive XP/level-up feedback. Horror-appropriate: brief text, no
## flashy animations or sounds.
@export var progression: ProgressionComponent
var xp_label: Label
var level_label: Label
var hud_label: Label
var _xp_time: float = 0.0
var _level_time: float = 0.0

func _ready() -> void:
	layer = 7
	# XP gain toast — bottom-left, small
	xp_label = Label.new()
	xp_label.position = Vector2(16, 0)
	xp_label.add_theme_font_size_override("font_size", 18)
	xp_label.modulate = Color(0.6, 0.85, 0.65)
	xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_label)
	# Level up notice — center, slightly larger
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.modulate = Color(0.8, 0.9, 0.7)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_label)
	# Persistent HUD — top-right corner
	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_label.add_theme_font_size_override("font_size", 15)
	hud_label.modulate = Color(0.55, 0.6, 0.55)
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_label)
	progression.xp_gained.connect(_on_xp_gained)
	progression.level_up.connect(_on_level_up)

func _on_xp_gained(amount: int, _source: StringName) -> void:
	xp_label.text = "+%d XP" % amount
	_xp_time = 2.2

func _on_level_up(new_level: int, points: int) -> void:
	level_label.text = "NÍVEL %d\n+%d ponto de progressão" % [new_level, points]
	_level_time = 3.5

func _process(delta: float) -> void:
	var viewport := get_viewport().get_visible_rect().size
	# XP toast
	_xp_time = maxf(0.0, _xp_time - delta)
	xp_label.visible = _xp_time > 0.0
	xp_label.position.y = viewport.y - 140
	# Level up notice
	_level_time = maxf(0.0, _level_time - delta)
	level_label.visible = _level_time > 0.0
	level_label.position = Vector2(viewport.x * 0.5 - 120, viewport.y * 0.3)
	level_label.custom_minimum_size.x = 240
	# Persistent HUD
	var required := progression.xp_to_next_level()
	if required > 0:
		hud_label.text = "Lv.%d  XP %d/%d" % [progression.level, progression.current_xp, required]
	else:
		hud_label.text = "Lv.%d  MAX" % progression.level
	hud_label.position = Vector2(viewport.x - 200, 16)
	hud_label.custom_minimum_size.x = 180

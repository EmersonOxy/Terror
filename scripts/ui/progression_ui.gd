extends CanvasLayer

signal open_changed(is_open: bool)

@export var player: Player
@export var cameras: CameraSystem
@export var progression: ProgressionComponent
var is_open: bool = false
var _previous_mouse: Input.MouseMode
var panel: PanelContainer
var level_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var points_label: Label
var upgrade_rows: Dictionary = {}

func _ready() -> void:
	layer = 5
	_build_ui()
	progression.xp_changed.connect(_update_xp)
	progression.level_changed.connect(func(_l: int): _refresh())
	progression.progression_points_changed.connect(func(_p: int): _refresh())
	progression.upgrade_rank_changed.connect(func(_id: StringName, _r: int): _refresh())
	panel.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("progression_menu"):
		set_open(not is_open)
		get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	panel.visible = value
	player.controls_locked = value
	cameras.controls_locked = value
	if value:
		player.combat.tick(0.0, false)
		_previous_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		player.interaction.tick(player.movement.facing, false)
		_refresh()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if cameras.mode == "Isometrica" else _previous_mouse
	open_changed.emit(is_open)

func _refresh() -> void:
	level_label.text = "NÍVEL %d" % progression.level
	var required := progression.xp_to_next_level()
	if required > 0:
		xp_label.text = "XP  %d / %d" % [progression.current_xp, required]
		xp_bar.max_value = required
		xp_bar.value = progression.current_xp
	else:
		xp_label.text = "XP  MÁXIMO"
		xp_bar.max_value = 1
		xp_bar.value = 1
	points_label.text = "Pontos: %d" % progression.progression_points
	for upgrade in progression.upgrades:
		if upgrade == null:
			continue
		var row: Dictionary = upgrade_rows.get(upgrade.id, {})
		if row.is_empty():
			continue
		var rank := progression.get_rank(upgrade.id)
		(row["label"] as Label).text = "%s   %d / %d" % [upgrade.display_name, rank, upgrade.max_rank]
		(row["button"] as Button).disabled = not progression.can_purchase(upgrade.id)

func _update_xp(_current: int, _required: int) -> void:
	if is_open:
		_refresh()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.anchor_left = 0.02
	panel.anchor_top = 0.08
	panel.anchor_right = 0.35
	panel.anchor_bottom = 0.72
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.075, 0.085, 0.96)
	style.set_border_width_all(1)
	style.border_color = Color(0.28, 0.31, 0.34)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.text = "PROGRESSÃO"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 18)
	column.add_child(level_label)
	xp_label = Label.new()
	xp_label.add_theme_font_size_override("font_size", 15)
	column.add_child(xp_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 14)
	xp_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.14, 0.16)
	bar_bg.set_corner_radius_all(3)
	xp_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.35, 0.65, 0.5)
	bar_fill.set_corner_radius_all(3)
	xp_bar.add_theme_stylebox_override("fill", bar_fill)
	column.add_child(xp_bar)
	points_label = Label.new()
	points_label.add_theme_font_size_override("font_size", 16)
	points_label.modulate = Color(0.85, 0.9, 0.75)
	column.add_child(points_label)
	var separator := HSeparator.new()
	column.add_child(separator)
	var upgrades_title := Label.new()
	upgrades_title.text = "MELHORIAS"
	upgrades_title.add_theme_font_size_override("font_size", 17)
	column.add_child(upgrades_title)
	for upgrade in progression.upgrades:
		if upgrade == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		column.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 15)
		row.add_child(label)
		var button := Button.new()
		button.text = " + "
		button.custom_minimum_size = Vector2(40, 28)
		button.pressed.connect(_purchase.bind(upgrade.id))
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.14, 0.17, 0.19)
		btn_style.set_border_width_all(1)
		btn_style.border_color = Color(0.3, 0.35, 0.32)
		button.add_theme_stylebox_override("normal", btn_style)
		row.add_child(button)
		var desc := Label.new()
		desc.text = upgrade.description
		desc.add_theme_font_size_override("font_size", 12)
		desc.modulate = Color(0.6, 0.65, 0.62)
		column.add_child(desc)
		upgrade_rows[upgrade.id] = {"label": label, "button": button}

func _purchase(upgrade_id: StringName) -> void:
	var def := progression._find_upgrade(upgrade_id)
	if def != null and progression.purchase(upgrade_id):
		ProgressionEffects.apply(upgrade_id, def.value_per_rank, player.status, player.inventory)
	_refresh()

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.controls_locked = false
	if is_instance_valid(cameras):
		cameras.controls_locked = false

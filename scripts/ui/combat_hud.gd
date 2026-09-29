extends CanvasLayer

@export var player: Player
var label: Label
var reticle: Label
var _hit_markers: Array[Label] = []
var _message: String = ""
var _remaining: float = 0.0
var _hit_time: float = 0.0
const HIT_SEGMENTS := [
	Vector2(-8, -8), Vector2(-4, -4),
	Vector2(8, -8), Vector2(4, -4),
	Vector2(-8, 8), Vector2(-4, 4),
	Vector2(8, 8), Vector2(4, 4),
]

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(16, 610)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	reticle = Label.new()
	reticle.text = "+"
	reticle.add_theme_font_size_override("font_size", 22)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reticle)
	# Create four hit marker segments (drawn as small lines around crosshair)
	for i in 4:
		var marker := Label.new()
		marker.text = "—" if i < 2 else "|"
		marker.add_theme_font_size_override("font_size", 14)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.modulate = Color(1.0, 0.3, 0.3, 0.0)
		marker.visible = false
		add_child(marker)
		_hit_markers.append(marker)
	player.combat.feedback.connect(func(text: String): _message = text; _remaining = 1.8)
	player.combat.hit_confirmed.connect(func(): _hit_time = 0.22)

func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	var weapon := player.combat.weapon()
	label.text = "Combate: equipe uma arma na mochila"
	if weapon != null:
		var data := weapon.definition as WeaponDefinition
		label.text = data.display_name + "
"
		if data.weapon_type == WeaponDefinition.WeaponType.RANGED:
			label.text += "Munição: %d / %d reserva" % [weapon.ammo_in_magazine, player.combat.reserve()]
		else:
			label.text += "Custo: %.0f stamina" % data.stamina_cost
		if player.combat.reload_remaining > 0.0:
			label.text += "  · recarga %.1fs" % player.combat.reload_remaining
	if _remaining > 0.0:
		label.text += "
" + _message
	label.position.y = get_viewport().get_visible_rect().size.y - 100
	reticle.visible = weapon != null and not player.controls_locked and not player.status.dead and player.combat_aim != null and player.combat_aim.active
	reticle.text = "+"
	var center := get_viewport().get_visible_rect().size * 0.5
	reticle.position = center - Vector2(7, 14)
	if reticle.visible:
		var camera := get_viewport().get_camera_3d()
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			reticle.position = camera.unproject_position(player.combat_aim.target) - Vector2(7, 14)
			center = reticle.position + Vector2(7, 14)
	# Hit marker: four diagonal marks around the reticle
	var show_hit := _hit_time > 0.0 and reticle.visible
	var alpha := _hit_time / 0.22 if show_hit else 0.0
	for i in _hit_markers.size():
		_hit_markers[i].visible = show_hit
		_hit_markers[i].modulate = Color(1.0, 0.3, 0.3, alpha)
	if show_hit:
		# Position the four marks around crosshair center
		var offsets := [Vector2(-12, -10), Vector2(8, -10), Vector2(-12, 6), Vector2(8, 6)]
		for i in _hit_markers.size():
			_hit_markers[i].position = center + offsets[i]

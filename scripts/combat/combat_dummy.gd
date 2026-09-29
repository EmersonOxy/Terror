extends DamageReceiver

@export var mesh: MeshInstance3D
@export var label: Label3D
var _material: StandardMaterial3D
var _flash: float = 0.0
var _respawn_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_material = StandardMaterial3D.new()
	mesh.material_override = _material
	damaged.connect(_on_damage)
	died.connect(_on_died)
	_present()

func _on_damage(data: DamageData) -> void:
	_flash = 0.16
	label.text = "TEST ENEMY  %.0f / %.0f  (-%.0f)" % [health, max_health, data.amount]
	_present()
	set_process(true)

func _on_died() -> void:
	label.text = "TEST ENEMY / morto (respawning)"
	_respawn_timer = 2.5
	set_process(true)
	_present()

func _process(delta: float) -> void:
	if dead:
		if _respawn_timer > 0.0:
			_respawn_timer -= delta
			if _respawn_timer <= 0.0:
				health_component.setup(max_health)
				_present()
				set_process(false)
		return

	_flash = maxf(0.0, _flash - delta)
	if _flash == 0.0:
		_present()
		set_process(false)

func _present() -> void:
	_material.albedo_color = Color(1.0, 0.65, 0.45) if _flash > 0.0 else (Color(0.2, 0.22, 0.23) if dead else Color(0.55, 0.37, 0.3))
	if label.text.is_empty() or label.text.begins_with("TEST ENEMY / morto") or _flash == 0.0:
		label.text = "TEST ENEMY  %.0f / %.0f" % [health, max_health]

extends Interactable

@export_enum("Toggle", "Damage", "Heal") var effect: int = 0
@export var amount: float = 30.0
@export var indicator: MeshInstance3D
var active: bool = false

func interact(actor: Node3D) -> void:
	match effect:
		0:
			active = not active
			_update_indicator()
		1:
			if actor.has_method("receive_damage"):
				actor.receive_damage(amount)
		2:
			if actor.has_method("recover_health"):
				actor.recover_health(amount)
	print("INTERACTION %s: active=%s" % [name, active])

func get_interaction_text(_actor: Node3D) -> String:
	if effect == 0:
		return "Desativar terminal" if active else "Ativar terminal"
	return prompt

func _update_indicator() -> void:
	if indicator:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.9, 0.7) if active else Color(0.35, 0.4, 0.45)
		indicator.material_override = material

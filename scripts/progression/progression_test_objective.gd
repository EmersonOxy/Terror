extends Interactable

## Simple test objective that awards XP once when the player interacts.
## Proves that XP can come from non-combat sources.
@export var objective_id: StringName = &"test_objective"
@export var xp_reward: int = 80
@export var indicator: MeshInstance3D
var completed: bool = false
@export var reward: ProgressionReward

func interact(actor: Node3D) -> void:
	if completed or not is_instance_valid(reward):
		return
	reward.on_objective_completed(objective_id, xp_reward)
	completed = true
	_update_indicator()
	print("OBJECTIVE %s completed (+%d XP)" % [objective_id, xp_reward])

func can_interact(_actor: Node3D) -> bool:
	return not completed

func get_interaction_text(_actor: Node3D) -> String:
	return "Concluído" if completed else prompt

func _update_indicator() -> void:
	if indicator:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.7, 0.4) if completed else Color(0.55, 0.42, 0.2)
		indicator.material_override = material

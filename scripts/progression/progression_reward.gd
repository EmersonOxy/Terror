class_name ProgressionReward
extends Node

## Bridges gameplay events → ProgressionComponent without the sources knowing
## about progression. Set up by the composition root.
@export var progression: ProgressionComponent

func on_enemy_died(enemy: Enemy) -> void:
	if not is_instance_valid(progression):
		return
	var key := StringName(str(enemy.get_instance_id()))
	if progression.was_rewarded(key):
		return
	progression.mark_rewarded(key)
	var reward := enemy.definition.xp_reward
	if reward > 0:
		progression.add_xp(reward, &"enemy_kill")

func on_objective_completed(objective_id: StringName, xp: int) -> void:
	if not is_instance_valid(progression):
		return
	if progression.was_rewarded(objective_id):
		return
	progression.mark_rewarded(objective_id)
	if xp > 0:
		progression.add_xp(xp, &"objective")

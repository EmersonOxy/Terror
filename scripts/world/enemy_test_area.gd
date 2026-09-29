extends Node3D

@export var player: Player
@export var enemies: Array[Enemy] = []
@export var progression_reward: ProgressionReward

func _ready() -> void:
	# Composition root injects one candidate and its lifetime; AI never searches for Player.
	for enemy in enemies:
		enemy.set_candidate(player)
		player.status.died.connect(enemy.set_candidate.bind(null))
		if is_instance_valid(progression_reward):
			enemy.died.connect(progression_reward.on_enemy_died)
		# Wire loot drops for enemies that grant rewards
		if enemy.definition.grant_rewards and enemy.definition.loot_table != null:
			var dropper := LootDropper.new()
			enemy.add_child(dropper)
			var spawn_root := self
			enemy.died.connect(func(e: Enemy):
				if e.definition.grant_rewards:
					dropper.drop(e.definition.loot_table, e.global_position, spawn_root)
			)

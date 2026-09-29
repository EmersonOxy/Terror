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

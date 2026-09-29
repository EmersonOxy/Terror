extends Node3D

@export var player: Player
@export var enemies: Array[Enemy] = []

func _ready() -> void:
	# Composition root injects one candidate and its lifetime; AI never searches for Player.
	for enemy in enemies:
		enemy.set_candidate(player)
		player.status.died.connect(enemy.set_candidate.bind(null))

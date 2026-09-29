class_name NarrativeDirector
extends Node3D

@export var narrative: NarrativeSystem
@export var player: Player
@export var inventory_ui: CanvasLayer
@export var enemies: Array[Enemy] = []
@export var triggers: Array[NarrativeAreaTrigger] = []
@export var dummy: DialogueDummy
@export var subtitles: SubtitleUI
@export var prompt: Label
@export var combat_hud: CanvasLayer
@export var pickup_item_id: StringName = &"ranged"
@export var significant_damage: float = 10.0
@export var damage_event: StringName = &"test_player_damaged"
@export var pickup_event: StringName = &"test_weapon_pickup"
@export var enemy_death_event: StringName = &"test_enemy_killed"

func _ready() -> void:
	for trigger in triggers:
		trigger.actor = player
		trigger.narrative = narrative
	dummy.director = self
	player.status.damaged.connect(_player_damaged)
	player.status.died.connect(narrative.stop)
	player.items.item_collected.connect(_item_collected)
	for enemy in enemies:
		enemy.died.connect(_enemy_died)
	narrative.interactive_changed.connect(_sync_controls)
	inventory_ui.open_changed.connect(_sync_controls)
	subtitles.avoid_panel = inventory_ui.backdrop
	subtitles.avoided_controls = [prompt, inventory_ui.toast, combat_hud.label]

func can_converse(actor: Node3D) -> bool:
	return actor == player and not player.status.dead and not player.controls_locked and not inventory_ui.is_open and narrative.can_start_interactive()

func start_dialogue(sequence: DialogueSequence, actor: Node3D) -> bool:
	return can_converse(actor) and sequence.interactive and narrative.play_sequence(sequence)

func _unhandled_input(event: InputEvent) -> void:
	if narrative.interactive_active and not inventory_ui.is_open and event.is_action_pressed("dialogue_continue"):
		narrative.advance()
		get_viewport().set_input_as_handled()

func _sync_controls(_value: bool) -> void:
	player.controls_locked = inventory_ui.is_open or narrative.interactive_active
	if player.controls_locked:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		player.combat.tick(0.0, false)
		player.interaction.tick(player.movement.facing, false)

func _player_damaged(amount: float) -> void:
	if amount >= significant_damage:
		narrative.request_event(damage_event)

func _item_collected(item: ItemDefinition, _quantity: int) -> void:
	if item.id == pickup_item_id:
		narrative.request_event(pickup_event)

func _enemy_died(_enemy: Enemy) -> void:
	narrative.request_event(enemy_death_event)

func _exit_tree() -> void:
	if is_instance_valid(player) and is_instance_valid(inventory_ui):
		player.controls_locked = inventory_ui.is_open

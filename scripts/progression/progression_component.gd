class_name ProgressionComponent
extends Node

signal xp_gained(amount: int, source: StringName)
signal xp_changed(current: int, required: int)
signal level_changed(level: int)
signal level_up(new_level: int, points_awarded: int)
signal progression_points_changed(points: int)
signal upgrade_rank_changed(upgrade_id: StringName, rank: int)

@export var config: ProgressionConfig
@export var upgrades: Array[UpgradeDefinition] = []

var level: int = 1
var current_xp: int = 0
var progression_points: int = 0
## Tracks current rank for each upgrade id.
var _ranks: Dictionary = {}
## Prevents awarding XP twice for the same source key.
var _rewarded: Dictionary = {}

func _ready() -> void:
	for upgrade in upgrades:
		if upgrade != null and not upgrade.id.is_empty():
			_ranks[upgrade.id] = 0

# ----- XP curve -----

func xp_to_next_level() -> int:
	if level >= config.max_level:
		return 0
	return int(config.base_xp * pow(config.growth_factor, level - 1))

# ----- XP -----

func add_xp(amount: int, source: StringName = &"") -> void:
	if amount <= 0 or level >= config.max_level:
		return
	current_xp += amount
	xp_gained.emit(amount, source)
	xp_changed.emit(current_xp, xp_to_next_level())
	_check_level_up()

## Returns true when source was already rewarded. Call this before add_xp to
## guarantee one-time rewards.
func was_rewarded(source_key: StringName) -> bool:
	return _rewarded.has(source_key)

## Marks a source key so subsequent calls to was_rewarded return true.
func mark_rewarded(source_key: StringName) -> void:
	_rewarded[source_key] = true

# ----- Level up -----

func _check_level_up() -> void:
	var required := xp_to_next_level()
	while required > 0 and current_xp >= required:
		current_xp -= required
		level += 1
		var points := config.points_per_level
		progression_points += points
		level_changed.emit(level)
		level_up.emit(level, points)
		progression_points_changed.emit(progression_points)
		required = xp_to_next_level()
	xp_changed.emit(current_xp, xp_to_next_level())

# ----- Upgrades -----

func get_rank(upgrade_id: StringName) -> int:
	return _ranks.get(upgrade_id, 0)

func can_purchase(upgrade_id: StringName) -> bool:
	if progression_points <= 0:
		return false
	var def := _find_upgrade(upgrade_id)
	return def != null and get_rank(upgrade_id) < def.max_rank

func purchase(upgrade_id: StringName) -> bool:
	if not can_purchase(upgrade_id):
		return false
	progression_points -= 1
	_ranks[upgrade_id] = get_rank(upgrade_id) + 1
	progression_points_changed.emit(progression_points)
	upgrade_rank_changed.emit(upgrade_id, _ranks[upgrade_id])
	return true

func _find_upgrade(upgrade_id: StringName) -> UpgradeDefinition:
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null

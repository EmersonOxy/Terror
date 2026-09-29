class_name ModifierDefinition
extends Resource

enum Stat {
	NONE,
	MAX_HEALTH_ADD,
	MAX_STAMINA_ADD,
	MOVE_SPEED_MULT,
	MELEE_DAMAGE_MULT,
	RANGED_DAMAGE_MULT,
	SPRINT_STAMINA_COST_MULT
}

@export var stat: Stat = Stat.NONE
@export var value: float = 0.0

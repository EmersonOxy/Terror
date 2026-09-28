class_name PlayerConfig
extends Resource

@export_group("Movement")
@export var walk_speed: float = 3.2
@export var sprint_speed: float = 5.8
@export var crouch_speed: float = 1.6
@export var acceleration: float = 24.0
@export var deceleration: float = 32.0
@export var gravity: float = 24.0
@export var step_height: float = 0.3
@export var floor_snap: float = 0.35
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.05
@export var radius: float = 0.3
@export var turn_speed: float = 12.0
@export_group("Status")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var sprint_cost: float = 24.0
@export var stamina_regen: float = 20.0
@export var regen_delay: float = 1.2
@export var exhaustion_recovery: float = 25.0
@export_group("Interaction")
@export var interaction_range: float = 2.2
@export_range(-1.0, 1.0) var interaction_dot: float = 0.15

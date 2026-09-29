class_name EnemyDefinition
extends Resource

@export var enemy_id: StringName = &"enemy_test"
@export var display_name: String = "Inimigo de teste"
@export var max_health: float = 80.0
@export_group("Movement")
@export var walk_speed: float = 1.4
@export var chase_speed: float = 2.8
@export var turn_speed: float = 9.0
@export var acceleration: float = 18.0
@export var deceleration: float = 28.0
@export var gravity: float = 24.0
@export var radius: float = 0.3
@export var height: float = 1.8
@export var step_height: float = 0.3
@export var floor_snap: float = 0.35
@export var path_update_interval: float = 0.35
@export var destination_threshold: float = 0.4
@export var waypoint_distance: float = 0.35
@export var patrol_wait: float = 0.8
@export_group("Sight")
@export var detection_range: float = 9.0
@export_range(1.0, 360.0) var field_of_view: float = 110.0
@export var perception_interval: float = 0.15
@export var lose_target_delay: float = 3.0
@export_group("Combat")
@export var attack_range: float = 1.4
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.6
@export var attack_windup: float = 0.65
@export var stagger_duration: float = 0.35
@export var corpse_lifetime: float = 6.0
@export_group("Debug")
@export var show_label: bool = true

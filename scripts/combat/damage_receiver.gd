class_name DamageReceiver
extends StaticBody3D

signal health_changed(current: float, maximum: float)
signal damaged(data: DamageData)
signal died
@export var max_health: float = 100.0
@export var hit_offset: Vector3 = Vector3(0, 0.9, 0)
@export var health_component: HealthComponent
# Preserve the dummy's existing interface while sharing health with moving actors.
var health: float:
	get: return health_component.current
	set(value): health_component.current = value
var dead: bool:
	get: return health_component.dead
	set(value): health_component.dead = value

func _ready() -> void:
	health_component.health_changed.connect(func(value: float, maximum: float): health_changed.emit(value, maximum))
	health_component.damaged.connect(func(data: DamageData): damaged.emit(data))
	health_component.died.connect(func(): died.emit())
	health_component.setup(max_health)

func damage_point() -> Vector3:
	return to_global(hit_offset)

func take_damage(data: DamageData) -> bool:
	return health_component.take_damage(data)

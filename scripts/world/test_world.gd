extends Node3D

@export var player: Player
@export var cameras: CameraSystem

func _ready() -> void:
	process_physics_priority = -10
	player.items.drop_parent = self
	cameras.occlusion.visual = player.visual
	player.status.damaged.connect(func(amount: float): print("DAMAGE %.1f | health %.1f" % [amount, player.status.health]))
	player.status.died.connect(func(): print("PLAYER DIED: movement/sprint/interaction disabled"))
	cameras.mode_changed.connect(func(mode: String): print("CAMERA " + mode))

func _physics_process(_delta: float) -> void:
	cameras.occlusion.target_height = player.collider.shape.height
	player.movement_basis = cameras.movement_orientation()
	cameras.focus_height = minf(cameras.config.height, player.collider.shape.height * 0.75)
	if not player.controls_locked and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

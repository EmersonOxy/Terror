extends Node3D

@export var player: Player
@export var cameras: CameraSystem
@export var aim: CameraAimProvider
@export var inventory_ui: CanvasLayer
@export var progression_ui: CanvasLayer
@export var shop_ui: ShopUI

func _ready() -> void:
	process_physics_priority = -10
	player.aim_provider = aim
	player.items.drop_parent = self
	cameras.occlusion.visual = player.visual
	player.status.damaged.connect(func(amount: float): print("DAMAGE %.1f | health %.1f" % [amount, player.status.health]))
	player.status.died.connect(func(): print("PLAYER DIED: movement/sprint/interaction disabled"))
	cameras.mode_changed.connect(func(mode: String): print("CAMERA " + mode))
	
	# UI mutex: only one panel open at a time
	if is_instance_valid(inventory_ui) and is_instance_valid(progression_ui):
		inventory_ui.open_changed.connect(func(is_open: bool):
			if is_open:
				progression_ui.set_open(false)
				if shop_ui: shop_ui.set_open(false)
		)
		progression_ui.open_changed.connect(func(is_open: bool):
			if is_open:
				inventory_ui.set_open(false)
				if shop_ui: shop_ui.set_open(false)
		)
	if is_instance_valid(shop_ui):
		shop_ui.open_changed.connect(func(is_open: bool):
			if is_open:
				inventory_ui.set_open(false)
				progression_ui.set_open(false)
		)

	# Setup NPC merchant
	var merchant = get_node_or_null("NPCMerchant")
	if merchant:
		merchant.setup(null) # no narrative system needed for simple shop
		merchant.shop_requested.connect(func():
			if shop_ui:
				merchant.shop.setup(player.inventory, player.get_node("WalletComponent"), player.equipment)
				shop_ui.open_shop(merchant.shop)
		)

func _physics_process(_delta: float) -> void:
	aim.camera = get_viewport().get_camera_3d()
	aim.use_cursor = cameras.mode == "Isometrica"
	cameras.occlusion.target_height = player.collider.shape.height
	player.movement_basis = cameras.movement_orientation()
	cameras.focus_height = minf(cameras.config.height, player.collider.shape.height * 0.75)
	if not player.controls_locked and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("debug_add_xp"):
		player.progression.add_xp(50, &"debug")
	# Cursor management: hide system cursor during isometric ranged aiming
	_update_cursor()

func _update_cursor() -> void:
	# If any UI is open, cursor must be visible
	if player.controls_locked:
		return
	var iso_ranged := cameras.mode == "Isometrica" and player.combat_aim != null and player.combat_aim.active and player.combat.weapon() != null
	var weapon := player.combat.weapon()
	var is_ranged := weapon != null and (weapon.definition as WeaponDefinition).weapon_type == WeaponDefinition.WeaponType.RANGED if weapon != null else false
	if iso_ranged and is_ranged:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif cameras.mode == "Isometrica":
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

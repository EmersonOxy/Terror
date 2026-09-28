class_name CombatComponent
extends Node

signal feedback(text: String)
signal hit_confirmed
@export var actor: CollisionObject3D
@export var equipment: EquipmentComponent
@export var inventory: InventoryComponent
@export var status: StatusComponent
var cooldown: float = 0.0
var reload_remaining: float = 0.0
var _reloading: WeaponInstance
var enabled: bool = true

func _ready() -> void:
	equipment.equipment_changed.connect(cancel_reload)

func weapon() -> WeaponInstance:
	return equipment.get_equipped(ItemDefinition.EquipSlot.WEAPON) as WeaponInstance

func reserve() -> int:
	var item := weapon()
	if item == null:
		return 0
	var data := item.definition as WeaponDefinition
	return inventory.get_quantity(data.ammunition.id) if data.ammunition != null else 0

func tick(delta: float, allowed: bool) -> void:
	enabled = allowed and not status.dead
	cooldown = maxf(0.0, cooldown - delta)
	if not enabled or (_reloading != null and _reloading != weapon()):
		cancel_reload()
	if _reloading == null:
		return
	reload_remaining = maxf(0.0, reload_remaining - delta)
	if reload_remaining == 0.0:
		_finish_reload()

func cancel_reload() -> void:
	_reloading = null
	reload_remaining = 0.0

func reload() -> bool:
	var item := weapon()
	if not enabled or status.dead or item == null or _reloading != null:
		return false
	var data := item.definition as WeaponDefinition
	if data.weapon_type != WeaponDefinition.WeaponType.RANGED or item.ammo_in_magazine >= data.magazine_capacity or reserve() == 0:
		feedback.emit("Sem reserva ou carregador cheio")
		return false
	_reloading = item
	reload_remaining = data.reload_duration
	feedback.emit("Recarregando...")
	return true

func _finish_reload() -> void:
	var item := _reloading
	var data := item.definition as WeaponDefinition
	var needed := data.magazine_capacity - item.ammo_in_magazine
	# Consume only on completion, allowing inventory changes without borrowed ammo.
	for index in inventory.capacity():
		var stack := inventory.get_slot(index)
		if stack != null and data.ammunition != null and stack.definition.id == data.ammunition.id:
			var count := mini(needed, stack.quantity)
			inventory.consume(index, count)
			item.ammo_in_magazine += count
			needed -= count
			if needed == 0:
				break
	cancel_reload()
	feedback.emit("Recarga concluída")

func attack(aim: AimSample) -> bool:
	var item := weapon()
	if not enabled or status.dead or item == null or cooldown > 0.0 or _reloading != null or aim.direction.is_zero_approx():
		return false
	var data := item.definition as WeaponDefinition
	if status.stamina < data.stamina_cost:
		feedback.emit("Stamina insuficiente")
		return false
	if data.weapon_type == WeaponDefinition.WeaponType.RANGED:
		if not aim.active:
			feedback.emit("Segure RMB para mirar")
			return false
		if item.ammo_in_magazine <= 0:
			feedback.emit("Carregador vazio — R para recarregar")
			return false
		item.ammo_in_magazine -= 1
	status.consume_stamina(data.stamina_cost)
	cooldown = data.attack_interval
	feedback.emit("Ataque melee" if data.weapon_type == WeaponDefinition.WeaponType.MELEE else "Disparo")
	if data.weapon_type == WeaponDefinition.WeaponType.MELEE:
		_melee(data, aim)
	else:
		var result := _ray(aim.origin, aim.origin + aim.direction * data.range)
		if not result.is_empty():
			_damage(result.collider, data, result.position, aim.direction)
	return true

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 11, [actor.get_rid()]))

func _melee(data: WeaponDefinition, aim: AimSample) -> void:
	var forward := Vector3(aim.direction.x, 0, aim.direction.z).normalized()
	if forward.is_zero_approx():
		return
	var shape := SphereShape3D.new()
	shape.radius = data.range * 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = aim.origin + forward * shape.radius
	query.collision_mask = 10
	query.exclude = [actor.get_rid()]
	var seen: Dictionary = {}
	for hit in actor.get_world_3d().direct_space_state.intersect_shape(query, 64):
		var target: Node3D = hit.collider
		if seen.has(target.get_instance_id()) or not target.has_method("take_damage"):
			continue
		seen[target.get_instance_id()] = true
		var point: Vector3 = target.damage_point() if target.has_method("damage_point") else target.global_position
		if (point - aim.origin).dot(forward) <= 0.0:
			continue
		var line := _ray(aim.origin, point)
		if not line.is_empty() and line.collider == target:
			_damage(target, data, line.position, forward)

func _damage(target: Object, data: WeaponDefinition, position: Vector3, direction: Vector3) -> void:
	if target.has_method("take_damage") and target.take_damage(DamageData.new(data.damage, actor, position, direction)):
		hit_confirmed.emit()
		feedback.emit("Acerto: %.0f" % data.damage)

class_name HealEffect
extends ItemUseEffect

@export var amount: float = 30.0

func can_use(target: Node) -> bool:
	var status := target as StatusComponent
	return status != null and not status.dead and amount > 0.0 and status.health < status.config.max_health

func apply(target: Node) -> bool:
	if not can_use(target):
		return false
	(target as StatusComponent).heal(amount)
	return true

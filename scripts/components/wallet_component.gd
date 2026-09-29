class_name WalletComponent
extends Node

signal balance_changed(current: int)

@export_range(0, 99999) var initial_balance: int = 100
var _balance: int = 0

func _ready() -> void:
	_balance = initial_balance

func balance() -> int:
	return _balance

func can_afford(cost: int) -> bool:
	return cost >= 0 and _balance >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	_balance -= cost
	balance_changed.emit(_balance)
	return true

func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	_balance += amount
	balance_changed.emit(_balance)

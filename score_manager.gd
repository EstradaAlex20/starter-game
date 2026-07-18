extends Node

signal coins_changed(total: int)

var coins: int = 0

func add_coin(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)

extends Node2D


@export var max_health: int = 100
@export var health: int = max_health: set = set_health

signal health_changed(new_health)
signal healed(amount)

func set_health(new_health: int):
	health = clamp(new_health, 0, max_health)
	health_changed.emit(health)

func heal(amount: int):
	var new_health = health + amount
	set_health(new_health)
	healed.emit(amount)

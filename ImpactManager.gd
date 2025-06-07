extends Node2D


const BULLET_IMPACT = preload("res://weapons/BulletImpact.tscn")


func _ready() -> void:
	GlobalSignals.connect("bullet_impacted", Callable(self, "handle_bullet_impacted"))


func handle_bullet_impacted(impact_position: Vector2, direction: Vector2):
	var impact = BULLET_IMPACT.instantiate()
	add_child(impact)
	impact.global_position = impact_position
	impact.global_rotation = direction.angle()
	impact.start_emitting()

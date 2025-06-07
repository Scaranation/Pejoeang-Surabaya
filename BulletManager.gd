extends Node2D


func handle_bullet_spawned(bullet: Bullet, team: int, spawn_position: Vector2, direction: Vector2):
	bullet.team = team
	bullet.global_position = spawn_position
	bullet.set_direction(direction)

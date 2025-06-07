extends Node2D


const PlayerScene = preload("res://actors/Player.tscn")
const EnemyScene = preload("res://actors/Enemy.tscn")
const GameOverScreen = preload("res://UI/GameOverScreen.tscn")
const PauseScreen = preload("res://UI/PauseScreen.tscn")


@onready var bullet_manager = $BulletManager
@onready var camera = $Camera2D
@onready var gui = $GUI
@onready var map = $Map
@onready var player = null

func _ready() -> void:
	randomize()
	GlobalSignals.connect("bullet_fired", Callable(bullet_manager, "handle_bullet_spawned"))
	spawn_player()
	spawn_enemy()


func spawn_player():
	player = PlayerScene.instantiate()
	add_child(player)
	player.set_camera_transform(camera.get_path())
	player.connect("died", Callable(self, "spawn_player"))
	gui.set_player(player)

func spawn_enemy():
	var enemy = EnemyScene.instantiate()
	add_child(enemy)

	# Get camera boundaries
	var camera_pos = camera.global_position
	var screen_size = get_viewport_rect().size * camera.zoom  # Adjust for zoom
	var spawn_margin = 200  # How far outside the screen enemies should spawn

	# Determine spawn location outside camera view
	#var side = randi() % 4
	#var spawn_position = Vector2.ZERO
#
	#match side:
		#0:  # Top
			#spawn_position = Vector2(randf_range(camera_pos.x - screen_size.x / 2, camera_pos.x + screen_size.x / 2), camera_pos.y - screen_size.y / 2 - spawn_margin)
		#1:  # Bottom
			#spawn_position = Vector2(randf_range(camera_pos.x - screen_size.x / 2, camera_pos.x + screen_size.x / 2), camera_pos.y + screen_size.y / 2 + spawn_margin)
		#2:  # Left
			#spawn_position = Vector2(camera_pos.x - screen_size.x / 2 - spawn_margin, randf_range(camera_pos.y - screen_size.y / 2, camera_pos.y + screen_size.y / 2))
		#3:  # Right
			#spawn_position = Vector2(camera_pos.x + screen_size.x / 2 + spawn_margin, randf_range(camera_pos.y - screen_size.y / 2, camera_pos.y + screen_size.y / 2))
#
	#enemy.global_position = spawn_position
	
	enemy.global_position = Vector2.ZERO 


func handle_player_win():
	var game_over = GameOverScreen.instantiate()
	add_child(game_over)
	game_over.set_title(true)
	get_tree().paused = true


func handle_player_lost():
	var game_over = GameOverScreen.instantiate()
	add_child(game_over)
	game_over.set_title(false)
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause_menu = PauseScreen.instantiate()
		add_child(pause_menu)

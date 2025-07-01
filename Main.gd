extends Node2D


const PlayerScene = preload("res://actors/Player.tscn")
const EnemyScene = preload("res://actors/Enemy.tscn")
const GameOverScreen = preload("res://UI/GameOverScreen.tscn")
const PauseScreen = preload("res://UI/PauseScreen.tscn")

const MAP_SCENE_PATH = "res://map/%s.tscn"

@onready var bullet_manager = $BulletManager
@onready var camera = $Camera2D
@onready var gui = $GUI
@onready var map = null
@onready var player = null

func _ready() -> void:
	randomize()
	GlobalSignals.connect("bullet_fired", Callable(bullet_manager, "handle_bullet_spawned"))
	render_map()  # Initialize the default map
	spawn_player()
	spawn_enemy()

func render_map(map_name: String = "Map1"):
	# Remove the existing map if there is one
	if map != null:
		map.queue_free()
	
	# Load and instantiate the requested map
	var map_scene = load(MAP_SCENE_PATH % map_name)
	if map_scene == null:
		push_error("Failed to load map: %s" % map_name)
		return
	
	map = map_scene.instantiate()
	add_child(map)
	
	# Make sure the map is behind other game elements
	move_child(map, 0)

func spawn_player():
	player = PlayerScene.instantiate()
	add_child(player)
	player.set_camera_transform(camera.get_path())
	player.connect("died", Callable(self, "spawn_player"))
	gui.set_player(player)

func spawn_enemy():
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	
	# Get reference to navigation system
	var nav_map = get_world_2d().get_navigation_map()
	
	# Get random navigable position
	var nav_points = NavigationServer2D.map_get_path(
		nav_map,
		Vector2.ZERO,
		Vector2(1000, 1000),
		true
	)
	
	if nav_points.size() > 0:
		# Place enemy at first navigable point found
		enemy.global_position = nav_points[0]
		
		# Set navigation map for enemy's AI
		var ai = enemy.get_node("AI")
		if ai and ai.has_node("NavigationAgent2D"):
			ai.get_node("NavigationAgent2D").set_navigation_map(nav_map)
	else:
		# Fallback position if no navigation points found
		enemy.global_position = Vector2(100, 100)

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

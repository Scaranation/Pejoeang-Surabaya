extends TileMap

# Noise generators for procedural terrain
var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

# TileMap dimensions per chunk
var width = 64
var height = 64

# Tile type references
const TILE_GRASS = Vector2i(0, 0)
const TILE_DIRT = Vector2i(1, 0)
const TILE_RIVER = Vector2i(2, 0)
const TILE_BUILDING = Vector2i(3, 0)
const TILE_BRIDGE = Vector2i(4, 0)

var main_scene = null
var player = null

var loaded_chunks = []  # Track loaded chunks
var generated_tiles = {}  # Dictionary to store already set tiles
var last_position;

func _ready():
	main_scene = get_tree().current_scene  # Get the main scene
	if main_scene.has_method("spawn_player"):
		player = main_scene.player  # Access the player reference

	if player:
		print("Player found:", player)

	# Set noise randomness
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()

	altitude.frequency = 0.02
	moisture.frequency = 0.05
	temperature.frequency = 0.03

func _process(_delta):
	if not player:
		# Try getting the player from the main scene
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("spawn_player"):
			player = main_scene.player

		# Try finding the player in the scene if it's still null
		if not player:
			player = get_tree().get_first_node_in_group("Player")

		# If still null, return early
		if not player:
			return

	var player_tile_pos = local_to_map(to_local(player.global_position))
	if last_position != player_tile_pos:
		generate_chunk(player_tile_pos)
		unload_distant_chunks(player_tile_pos)
		print("Player position:", player.position)
		print("Player tile position:", player_tile_pos)
		print("Loaded chunks:", loaded_chunks.size())


func generate_chunk(pos):
	if pos in loaded_chunks:
		return  # Prevent redundant chunk generation

	print("Generating chunk at:", pos)
	loaded_chunks.append(pos)  # Mark chunk as generated
	
	for x in range(width):
		for y in range(height):
			var world_x = pos.x - int(width / 2) + x
			var world_y = pos.y - int(height / 2) + y
			var tile_pos = Vector2i(world_x, world_y)

			# Check if this tile was already set before
			if tile_pos in generated_tiles:
				continue  # Skip if already set

			# Generate noise values
			var alt = altitude.get_noise_2d(world_x, world_y) * 10
			var moist = moisture.get_noise_2d(world_x, world_y) * 10

			# Determine tile type
			var tile_type = TILE_GRASS  # Default grass
			if alt < -2:
				tile_type = TILE_RIVER
			elif alt < 1 and moist > 2:
				tile_type = Vector2i(randi_range(4, 5), 0)  # Dirt variant
			elif alt > 1:
				tile_type = Vector2i(randi_range(0, 3), 0)  # Grass variant

			# Add stone patches randomly
			if alt > 2 and randi() % 20 == 0:
				tile_type = Vector2i(randi_range(20, 22), 8)  # Stone variant

			## Add buildings randomly
			#if alt > 1 and randi() % 15 == 0:
				#tile_type = TILE_BUILDING

			## Add bridges
			#if alt < -2 and (world_x % 20 == 0 or world_y % 20 == 0):
				#tile_type = TILE_BRIDGE

			# Set tile only if it was never assigned before
			set_cell(0, tile_pos, 0, tile_type)
			generated_tiles[tile_pos] = tile_type  # Store it to prevent changing later


func unload_distant_chunks(player_pos):
	var unload_distance = (width * 2) + 1

	for chunk in loaded_chunks:
		if get_dist(chunk, player_pos) > unload_distance:
			clear_chunk(chunk)
			loaded_chunks.erase(chunk)

func clear_chunk(pos):
	for x in range(width):
		for y in range(height):
			set_cell(0, Vector2i(pos.x - int(width / 2.0) + x, pos.y - int(height / 2.0) + y), -1, Vector2(-1, -1), -1)

func get_dist(p1, p2):
	var diff = p1 - p2
	return sqrt(diff.x ** 2 + diff.y ** 2)

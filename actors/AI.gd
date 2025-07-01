extends Node2D
class_name AI

signal state_changed(new_state)

enum State {
	ENGAGE,
	CHASE
}

@export var should_draw_path_line: bool = true
@export var repath_rate: float = 0.5

@onready var path_line: Line2D = $PathLine
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var raycast: RayCast2D = $RayCast2D

var current_state: int = State.CHASE : set = set_state
var actor: CharacterBody2D = null
var target: CharacterBody2D = null
var weapon: Weapon = null
var team: int = -1

var time_since_last_path_update: float = 0.0

func _ready() -> void:
	path_line.visible = should_draw_path_line
	set_state(State.CHASE)

func _physics_process(delta: float) -> void:
	if not navigation_agent or not actor:
		return

	if target:
		time_since_last_path_update += delta
		if time_since_last_path_update >= repath_rate:
			if navigation_agent:  # Prevent null assignment error
				print("Setting target position: ", target.global_position)
				navigation_agent.target_position = target.global_position
				print("Navigation map: ", navigation_agent.get_navigation_map())
			time_since_last_path_update = 0.0

		if not navigation_agent.is_navigation_finished():
			print("Current path points: ", navigation_agent.get_current_navigation_path())
			print("Next position: ", navigation_agent.get_next_path_position())
			var next_position = navigation_agent.get_next_path_position()
			var direction = (next_position - actor.global_position).normalized()
			
			# Check if path is blocked
			if raycast:
				raycast.target_position = target.global_position - global_position
				raycast.force_raycast_update()
				
				if raycast.is_colliding():
					# Path is blocked, force repath
					time_since_last_path_update = repath_rate
					# Try to move around obstacle
					direction = direction.rotated(randf_range(-0.5, 0.5))
			
			actor.velocity = direction * actor.speed
			actor.move_and_slide()
			
			# Update raycast before checking
			if raycast:
				raycast.target_position = target.global_position - global_position
				raycast.force_raycast_update()
				
				# Only shoot if has clear line of sight and not blocked by navigation
				if not raycast.is_colliding() and navigation_agent.is_target_reachable():
					actor.rotate_toward(target.global_position)
					
					# Calculate angle between weapon direction and player direction
					var weapon_direction = Vector2.RIGHT.rotated(weapon.global_rotation)
					var to_player = (target.global_position - weapon.global_position).normalized()
					var angle = abs(rad_to_deg(weapon_direction.angle_to(to_player)))
					
					# Calculate distance to player
					var distance = weapon.global_position.distance_to(target.global_position)
					
					# Dynamic angle threshold based on distance (smaller when close, larger when far)
					var max_angle = clamp(remap(distance, 100, 500, 15, 45), 15, 45)
					
					# Only shoot if within allowed angle
					if angle <= max_angle:
						weapon.shoot()
				else:
					actor.rotate_toward(next_position)


func initialize(new_actor: CharacterBody2D, new_weapon: Weapon, new_team: int) -> void:
	actor = new_actor
	weapon = new_weapon
	team = new_team
	if weapon:
		weapon.connect("weapon_out_of_ammo", Callable(self, "handle_reload"))
	
	# Configure navigation agent
	if navigation_agent:
		# Wait for navigation map to be ready
		await get_tree().process_frame
		var nav_map = get_world_2d().get_navigation_map()
		print("Navigation map ID: ", nav_map)
		navigation_agent.set_navigation_map(nav_map)
		navigation_agent.path_desired_distance = 10.0
		navigation_agent.target_desired_distance = 10.0
		navigation_agent.radius = 16.0
		navigation_agent.avoidance_enabled = true
		navigation_agent.path_max_distance = 50.0
		navigation_agent.avoidance_layers = 1
		navigation_agent.avoidance_mask = 1

func set_path_line(points: Array) -> void:
	if not should_draw_path_line:
		return

	var local_points: Array[Vector2] = []
	for point in points:
		local_points.append(point - global_position if point != points[0] else Vector2.ZERO)
	path_line.points = local_points

func set_state(new_state: int) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	emit_signal("state_changed", current_state)

func handle_reload() -> void:
	if weapon:
		weapon.start_reload()

func _on_DetectionZone_body_entered(body: Node) -> void:
	if body.has_method("get_team") and body.get_team() != team:
		target = body as CharacterBody2D
		set_state(State.ENGAGE)

func _on_DetectionZone_body_exited(body: Node) -> void:
	if target == body:
		target = null
		set_state(State.CHASE)

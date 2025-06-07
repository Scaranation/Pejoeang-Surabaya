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
				navigation_agent.target_position = target.global_position
			time_since_last_path_update = 0.0

		if not navigation_agent.is_navigation_finished():
			var next_position = navigation_agent.get_next_path_position()
			var direction = (next_position - actor.global_position).normalized()
			actor.velocity = direction * actor.speed
			actor.move_and_slide()

			if raycast:
				raycast.target_position = target.global_position - global_position
				raycast.force_raycast_update()

				if raycast.is_colliding():
					actor.rotate_toward(next_position)
				else:
					actor.rotate_toward(target.global_position)
					weapon.shoot()


func initialize(new_actor: CharacterBody2D, new_weapon: Weapon, new_team: int) -> void:
	actor = new_actor
	weapon = new_weapon
	team = new_team
	if weapon:
		weapon.connect("weapon_out_of_ammo", Callable(self, "handle_reload"))

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

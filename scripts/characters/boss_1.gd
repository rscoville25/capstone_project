extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var dancer_mesh : Node3D = $dancer
@onready var _anim_tree : AnimationTree = $dancer/AnimationTree
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var live_box : CollisionShape3D = $LiveBox

var death_timer : int
var attack_timer : int
@export var health = 5000
var max_health = health

var attacking = false
var rnd_delay = 0
var is_hit = false

func _ready():
	death_timer = 0
	attack_timer = 0

func _physics_process(delta):	
	var cur_location = global_transform.origin
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - cur_location
	var direction = local_destination.normalized()
	
	_anim_tree["parameters/playback"].travel("capoeira")
	
	if Global.pause:
		velocity.x = 0
		velocity.y = 0
	else:
		if health >= 0:
			if is_hit:
				attack_timer = 0
				death_timer += 1
				velocity.z = -1
				if death_timer >= 30:
					death_timer = 0
					velocity.z = 0
					is_hit = false
		else:
			death()
			death_timer += 1
			if death_timer >= 65:
				Global.enemies_defeated += 1
				queue_free()
				
		if not is_on_floor():
			velocity += get_gravity() * delta
	
	move_and_slide()
	
	
func hit(dmg):
	death_timer = 0
	is_hit = true
	health -= dmg
	
func death():
	live_box.disabled = true
	
func update_target_pos(target):
	nav_agent.set_target_position(target)

func _on_navigation_agent_3d_target_reached() -> void:
	pass # Replace with function body.

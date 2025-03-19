extends CharacterBody3D

@onready var player_mesh : Node3D = $chara
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var death_box : CollisionShape3D = $DeathHit
@onready var live_box : CollisionShape3D = $LiveBox
@onready var ui_hp : TextureProgressBar = $HealthBar

var death_timer : int
@export var health = 1000
var max_health = health

var is_hit = false

func _ready():
	death_box.disabled = true
	live_box.disabled = false
	death_timer = 0





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	ui_hp.value = health
	ui_hp.max_value = max_health
	
	if health >= 0:
		if is_hit:
			death_timer += 1
			_anim_tree["parameters/playback"].travel("Idle")
			velocity.z = -1
			if death_timer >= 30:
				death_timer = 0
				velocity.z = 0
				is_hit = false
		else:
			_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
	else:
		death()
		death_timer += 1
		if death_timer >= 65:
			Global.enemies_spawned -= 1
			queue_free()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	
		
	move_and_slide()
		
		
func hit(dmg):
	death_timer = 0
	is_hit = true
	health -= dmg
	
func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true
	
	
	
	

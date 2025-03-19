extends CharacterBody3D

@onready var player_mesh : Node3D = $chara
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var death_box : CollisionShape3D = $DeathHit
@onready var live_box : CollisionShape3D = $LiveBox

func _ready():
	death_box.disabled = true
	live_box.disabled = false


var health = 100
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if health >= 0:
		_anim_tree["parameters/playback"].travel("Idle")
	else:
		death()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	
		
		
func hit(dmg):
	health -= dmg
	
func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true
	
	
	

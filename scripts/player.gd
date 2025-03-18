extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var player_mesh : Node3D = $chara
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var ui_hp : TextureProgressBar = $HealthBar
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var hitbox : Area3D = $chara/Hitbox

# three speeds for walking, running, and taking a stance
const WALK = 10.0
const RUN = 25.0
const STANCE = 7.0
var speed = WALK

# attacking state and a list of what attacks are available
var attacking = false
var attacks = ["none", "light", "medium", "heavy"]
var cur_attack = attacks[0]

# all stats (hp, attack, level, etc)
var health = 100
var att = 100
var lvl = 1

func _physics_process(delta):
	
	ui_hp.value = health
	attacking = false
	cur_attack = attacks[0]

	
	if Input.is_action_pressed("run"):
		speed = RUN
	elif Input.is_action_pressed("fight_stance") && !Input.is_action_pressed("run"):
		_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")	
		speed = STANCE
	else:
		speed = WALK
	
	if Input.is_action_pressed("light_attack"):
		attacking = true
		cur_attack = attacks[1]
		health -= 1
		
	if Input.is_action_pressed("heavy_attack"):
		attacking = true
		cur_attack = attacks[3]
	
	# get direction of movement
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	move_direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if speed == WALK:
			_anim_tree["parameters/playback"].travel("Walking")
		elif speed == RUN:
			_anim_tree["parameters/playback"].travel("Running")
		elif speed == STANCE:
			_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		_anim_tree["parameters/playback"].travel("Idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


		
	if !attacking:	
		if move_direction:
			player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
			
		move_and_slide()
	else:
		if cur_attack == attacks[1]:
			_anim_tree["parameters/playback"].travel("Punching")
		elif cur_attack == attacks[3]:
			_anim_tree["parameters/playback"].travel("Roundhouse Kick")	
			
func attack(strength, power):
	var enemies_hit = hitbox.get_overlapping_bodies()
	var damage = 0
	if strength == "light":
		damage = (power / 4)
	elif strength == "medium":
		damage = (power / 3)
	else:
		damage = (power / 2)
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit()
	

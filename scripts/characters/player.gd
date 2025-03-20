extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var player_mesh : Node3D = $chara
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var ui_hp : TextureProgressBar = $HealthBar
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var hitbox_light : Area3D = $chara/HitboxLight
@onready var hitbox_medium : Area3D = $chara/HitboxMedium
@onready var hitbox_heavy : Area3D = $chara/HitboxHeavy
@onready var kick_fx : GPUParticles3D = $chara/GPUParticles3D
@onready var heat_fx : GPUParticles3D = $chara/HeatParticles
@onready var dodge_fx : GPUParticles3D = $chara/DodgeHaze
@onready var live_box : CollisionShape3D = $LiveBox
@onready var death_box : CollisionShape3D = $DeathHit

# three speeds for walking, running, and taking a stance
const WALK = 10.0
const RUN = 25.0
const STANCE = 7.0
const DODGE = 50.0
var speed = WALK

# attacking state and a list of what attacks are available
var attacking = false
var attacks = ["none", "light", "medium", "heavy"]
var cur_attack = attacks[0]

# all stats (hp, attack, level, etc)
var health = 1000
var max_health = health
var att = 100
var lvl = 1
var heat = 0

# timer for stuff, as well as stun value and dodge count
var timer = 0
var stun = 0
var dge_count = 0

var is_hurt = false

func _ready():
	kick_fx.emitting = false
	kick_fx.one_shot = true
	heat_fx.emitting = true
	heat_fx.speed_scale = 0
	
func _physics_process(delta):
	
	if heat_fx.speed_scale != heat * 0.3:
		heat_fx.speed_scale += 0.1
	
	_anim_tree["parameters/playback"].travel("Idle")
	dodge_fx.emitting = false
	
	# UI business
	ui_hp.value = health
	ui_hp.max_value = max_health
	
	# tells you when you're attacking and what attack is being used
	attacking = false
	cur_attack = attacks[0]
	
	if health <= 0:
		death()
	
	else:
		if is_hurt:
			if !Input.is_action_pressed("fight_stance"):
				stun -= 1
				_anim_tree["parameters/playback"].travel("Hit To Body")
				if stun <= 0:
					is_hurt = false
			else:
				stun = 0
				is_hurt = false
		else:

			# Change speeds and makes sure you can't run when stanced
			if Input.is_action_pressed("run"):
				speed = RUN
			elif Input.is_action_pressed("fight_stance") && !Input.is_action_pressed("run"):
				_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")	
				speed = STANCE
			else:
				speed = WALK
			if speed != STANCE:
				# Inputs for the three attacks. Cannot do two attacks at once. Not elegant but it works
				if Input.is_action_pressed("light_attack") && !Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack"):
					timer += 1
					attacking = true
					cur_attack = attacks[1]
					if (timer % 33) == 17 || (timer % 33) == 18:
						heat += 25
						if heat > 100:
							heat = 100
						light_attack(att)
						
				if Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack"):
					timer += 1
					attacking = true
					cur_attack = attacks[2]
					if (timer % 62) == 34 || (timer % 62) == 35:
						heat += 33
						if heat > 100:
							heat = 100
						medium_attack(att)
						
				if Input.is_action_pressed("heavy_attack"):
					timer += 1
					attacking = true
					cur_attack = attacks[3]
					if (timer % 77) == 30 || (timer % 77) == 31:
						heat += 50
						if heat > 100:
							heat = 100
						heavy_attack(att)
					if (timer % 77) >= 30 && (timer % 77) <= 38:
						kick_fx.emitting = true

			
			# set timer to 0 when attack buttons are pressed
			if Input.is_action_just_pressed("heavy_attack"):
				timer = 0
			if Input.is_action_just_pressed("medium_attack"):
				timer = 0
			if Input.is_action_just_pressed("light_attack"):
				timer = 0
			if Input.is_action_just_pressed("dodge"):
				timer = 0

			
			# get direction of movement
			var direction : Vector3 = Vector3.ZERO
			direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
			direction.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
			direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
			
			if Input.is_action_pressed("dodge"):
				timer += 1
				if timer % 60 >= 0 && timer % 60 <= 10:
					if dge_count != 3:
						if Input.is_action_pressed("fight_stance"):
							dodge_fx.emitting = true
							dge_count += .1
						velocity.x = direction.x * DODGE
						velocity.z = direction.z * DODGE
					else:
						if timer % 120 == 0:
							dge_count = 0
				else:
					velocity.x = move_toward(velocity.x, 0, speed)
					velocity.z = move_toward(velocity.z, 0, speed)	
				
			# Add the gravity.
			if not is_on_floor():
				velocity += get_gravity() * delta

			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			if direction:
				if speed == WALK:
					_anim_tree["parameters/playback"].travel("Walking")
				elif speed == RUN:
					_anim_tree["parameters/playback"].travel("Running")
				elif speed == STANCE:
					_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
				if speed != STANCE:
					velocity.x = direction.x * speed
					velocity.z = direction.z * speed
			else:
				if speed == STANCE:
					_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
				else:
					_anim_tree["parameters/playback"].travel("Idle")
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
				
			if attacking:	
				if cur_attack == attacks[1]:
					_anim_tree["parameters/playback"].travel("Punching")
				elif cur_attack == attacks[2]:
					_anim_tree["parameters/playback"].travel("Cross Punch")
				elif cur_attack == attacks[3]:
					_anim_tree["parameters/playback"].travel("Roundhouse Kick")	
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)

			else:
				if direction && !Input.is_action_pressed("fight_stance"):
					player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)

				
	move_and_slide()
			
func light_attack(power):
	var enemies_hit = hitbox_light.get_overlapping_bodies()
	var damage = power / 4
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)
			
func medium_attack(power):
	var enemies_hit = hitbox_medium.get_overlapping_bodies()
	var damage = power / 3
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)
			
func heavy_attack(power):
	var enemies_hit = hitbox_heavy.get_overlapping_bodies()
	var damage = power / 2
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)
	
func hurt(dmg, stn):
	is_hurt = true
	if !Input.is_action_pressed("fight_stance"):
		health -= dmg
		stun = stn
	else:
		health -= 1

func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true

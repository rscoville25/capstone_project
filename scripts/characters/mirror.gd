extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var mirror_mesh : Node3D = $chara
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var healthbar : TextureProgressBar = $Healthbar
@onready var hitbox_light : Area3D = $chara/HitboxLight
@onready var hitbox_medium : Area3D = $chara/HitboxMedium
@onready var hitbox_heavy : Area3D = $chara/HitboxHeavy
@onready var kick_fx : GPUParticles3D = $chara/GPUParticles3D
@onready var heat_fx : GPUParticles3D = $chara/HeatParticles
@onready var dodge_fx : GPUParticles3D = $chara/DodgeHaze
@onready var live_box : CollisionShape3D = $LiveBox
@onready var death_box : CollisionShape3D = $DeathBox

const WALK = 15.0
const RUN = 30.0
const STANCE = 7.0
const DODGE = 50.0
var speed = WALK

var attacking = false
var attacks = ["none", "light", "medium", "heavy"]
var cur_attack = attacks[0]

var timer = 0
var death_timer = 0
var dge_count = 0

var is_hurt = false
var stun = 0

@export var health = 1000 * Global.stage + (Global.wave * 50)
var attack = Global.stage
var max_health = health

func _ready():
	healthbar.max_value = max_health
	kick_fx.emitting = false
	heat_fx.emitting = false
	kick_fx.one_shot = true
	death_box.disabled = true
	live_box.disabled = false
	
func _physics_process(delta: float) -> void:
	healthbar.value = health
	
	_anim_tree["parameters/playback"].travel("Idle")
	dodge_fx.emitting = false

	attacking = false
	cur_attack = attacks[0]
	if Global.pause || Global.buying || Global.tutorial_splash:
		dodge_fx.speed_scale = 0
		kick_fx.speed_scale = 0
		velocity.x = 0
		velocity.z = 0
	else:
		dodge_fx.speed_scale = 1
		kick_fx.speed_scale = 1
		
		if health <= 0:
			death()
			death_timer += 1
			if death_timer >= 65:
				Global.enemies_defeated += 1
				queue_free()
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
					if Input.is_action_pressed("light_attack") && !Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack") && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[1]
						if (timer % 33) == 17 || (timer % 33) == 18:
							light_attack(attack)
							
					if Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack")  && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[2]
						if (timer % 62) == 34 || (timer % 62) == 35:
							medium_attack(attack)
							
					if Input.is_action_pressed("heavy_attack")  && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[3]
						if (timer % 77) == 30 || (timer % 77) == 31:
							heavy_attack(attack)
						if (timer % 77) >= 30 && (timer % 77) <= 38:
							kick_fx.emitting = true

				
				# set timer to 0 when attack buttons are pressed
				if Input.is_action_just_released("heavy_attack"):
					timer = 0
				if Input.is_action_just_released("medium_attack"):
					timer = 0
				if Input.is_action_just_released("light_attack"):
					timer = 0


				var direction : Vector3 = Vector3.ZERO
				direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
				direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
				
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

				var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

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
						mirror_mesh.rotation.y = lerp_angle(mirror_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)

					
		move_and_slide()

func hit(dmg):
	is_hurt = true
	if !Input.is_action_pressed("fight_stance"):
		health -= dmg
		stun += 15
		
func light_attack(power):
	var enemies_hit = hitbox_light.get_overlapping_bodies()
	var damage = power * 25
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, 15)
			
func medium_attack(power):
	var enemies_hit = hitbox_medium.get_overlapping_bodies()
	var damage = power * 33
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, 15)
			
func heavy_attack(power):
	var enemies_hit = hitbox_heavy.get_overlapping_bodies()
	var damage = power * 50
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, 15)

func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true

extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var giant_mesh : Node3D = $giant
@onready var _anim_tree : AnimationTree = $giant/AnimationTree
@onready var healthbar : TextureProgressBar = $BossHealth
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var live_box : CollisionShape3D = $LiveBox
@onready var death_box : CollisionShape3D = $DeathHit
@onready var hitbox_light : Area3D = $giant/HitboxLight
@onready var hitbox_heavy : Area3D = $giant/HitboxHeavy
@onready var hit_sound : AudioStreamPlayer3D = $HitSound
@onready var poison_fx : GPUParticles3D = $PoisonFX
@onready var poison_snd : AudioStreamPlayer3D = $PoisonSound

var poisoned = false
var poison_tic = 0

var death_timer : int
var attack_timer : int
@export var health = Global.stage * 6000
var max_health = health
var is_hit = false

var attacking = false
var att_type = 0

func _ready():
	death_box.disabled = true
	death_timer = 0
	attack_timer = 0
	healthbar.value = health
	healthbar.max_value = max_health
	poison_fx.emitting = false
	
func _physics_process(delta):
	healthbar.value = health
	
	attacking = false	
	var cur_location = global_transform.origin
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - cur_location
	var direction = local_destination.normalized()
	
	if Global.pause:
		velocity.x = 0
		velocity.z = 0
	else:
		if health >= 0:
			if is_hit:
				death_timer += 1
				velocity.z = -10
				if death_timer >= 30:
					death_timer = 0
					velocity.z = 0
					is_hit = false
			else:
				if !attacking:
					attack_timer = 0
					_anim_tree["parameters/playback"].travel("Running")
					velocity = direction * 18.5
				rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
		else:
			death()
			death_timer += 1
			if death_timer >= 65:
				Global.boss_alive = false
				Global.enemies_defeated += 1
				Global.stage += 1
				queue_free()
				
		if poisoned:
			poison_fx.emitting = true
			poison_tic += 1
			if poison_tic % 60 == 0:
				poison_snd.play()
				health -= 50
		
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		move_and_slide()

func light_attack(power, stun):
	var enemies_hit = hitbox_light.get_overlapping_bodies()
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(power, stun)

func heavy_attack(power, stun):
	var enemies_hit = hitbox_heavy.get_overlapping_bodies()
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(power, stun)

func hit(dmg):
	hit_sound.play()
	death_timer = 0
	is_hit = true
	health -= dmg

func poison():
	poisoned = true

func death():
	live_box.disabled = true
	death_box.disabled = false

func update_target_pos(target):
	nav_agent.set_target_position(target)

func _on_navigation_agent_3d_target_reached() -> void:
	attacking = true
	attack_timer += 1
	if attack_timer == 1:
		att_type = randi_range(0, 1)
	match att_type:
		0:
			_anim_tree["parameters/playback"].travel("Mutant Punch")
			if attack_timer == 18 || attack_timer == 19:
				light_attack(100, 15)
			if attack_timer > 67:
				attack_timer = 0

		1:
			_anim_tree["parameters/playback"].travel("Mutant Swiping")
			if attack_timer == 80 || attack_timer == 81:
				heavy_attack(200, 25)
			if attack_timer > 161:
				attack_timer = 0

extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var hit_sound : AudioStreamPlayer3D = $HitSound
@onready var live_box : CollisionShape3D = $LiveBox
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox : Area3D = $runnner/Headbutt
@onready var _anim_tree : AnimationTree = $runnner/AnimationTree
@onready var healthbar : TextureProgressBar = $BossHealth
@onready var name_label : Label = $Label
@onready var poison_fx : GPUParticles3D = $PoisonFX
@onready var poison_snd : AudioStreamPlayer3D = $PoisonSound

var death_timer = 0
var is_hit : bool
var health = 5000 * Global.stage
var dmg_mod = 0
var dmg_inc_threshold = 1000

var running : bool
var attacking : bool

var poisoned = false
var poison_tic = 0

var attack_timer : int
var run_timer = 0

func _ready() -> void:
	healthbar.value = health
	healthbar.max_value = health
	death_timer = 0
	attack_timer = 0
	name_label.text = "Runner"
	running = true
	is_hit = false
	attacking = false
	poison_fx.emitting = false

func _physics_process(delta: float) -> void:
	attacking = false
	run_timer += 1
	
	healthbar.value = health
	if run_timer % 600 > 400:
		running = true
	else:
		running = false
	
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
				attack_timer = 0
				death_timer += 1
				velocity.z = -10
				if death_timer >= 30:
					death_timer = 0
					velocity.z = 0
					is_hit = false
			else:
				if !attacking:
					attack_timer = 0
					_anim_tree["parameters/playback"].travel("Fast Run")
					rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
					velocity = direction * 30.0
					
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

func enemy_attack(power, stn):
	var enemies_hit = hitbox.get_overlapping_bodies()
	var damage = power * (dmg_mod + 1)
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)

func hit(dmg):
	hit_sound.play()
	death_timer = 0
	is_hit = true
	health -= dmg
	if 5000 - health >= dmg_inc_threshold:
		dmg_mod += 1
		dmg_inc_threshold += 1000

func poison():
	poisoned = true

func death():
	live_box.disabled = true

func update_target_pos(target):
	if !running:
		nav_agent.set_target_position(target)
	else:
		nav_agent.set_target_position(-global_position)

func _on_navigation_agent_3d_target_reached() -> void:
	if running:
		_anim_tree["parameters/playback"].travel("Standing Idle")
	else:
		attacking = true
		attack_timer += 1
		_anim_tree["parameters/playback"].travel("Headbutt")
		if attack_timer % 93 == 30 || attack_timer % 93 == 31:
			enemy_attack(50, 15)

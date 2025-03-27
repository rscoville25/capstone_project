extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var dancer_mesh : Node3D = $dancer
@onready var _anim_tree : AnimationTree = $dancer/AnimationTree
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var live_box : CollisionShape3D = $LiveBox
@onready var hitbox_pontera : Area3D = $dancer/HitboxPontera
@onready var hitbox_martelo : Area3D = $dancer/HitboxMartelo
@onready var hitbox_meialua : Area3D = $dancer/HitboxMeiaLua
@onready var heatlhbar : TextureProgressBar = $BossHealth
@onready var name_label : Label = $Label
@onready var particle_pivot : Marker3D = $dancer/ParticleMarker
@onready var meialua_particles : GPUParticles3D = $dancer/ParticleMarker/MeiaLuaParticles
@onready var hit_sound : AudioStreamPlayer3D = $HitSound

var death_timer : int
var attack_timer : int
@export var health = Global.wave * 1000
var max_health = health

var attacking = false
var rnd_delay = 0
var is_hit = false

var att_type = 0

var particle_rotate = 12

func _ready():
	death_timer = 0
	attack_timer = 0
	name_label.text = "Dancer"
	heatlhbar.value = health
	heatlhbar.max_value = max_health
	meialua_particles.emitting = false

func _physics_process(delta):
	heatlhbar.value = health
	
	attacking = false	
	var cur_location = global_transform.origin
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - cur_location
	var direction = local_destination.normalized()
	

	
	if Global.pause:
		velocity.x = 0
		velocity.y = 0
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
					_anim_tree["parameters/playback"].travel("capoeira")
					rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
					velocity = direction * 7.0
				else:
					if att_type == 2:
						if attack_timer > 104 && attack_timer < 133:
							meialua_particles.emitting = true
							particle_pivot.rotate_y(delta * particle_rotate)
					else:
						meialua_particles.emitting = false
		else:
			death()
			death_timer += 1
			if death_timer >= 65:
				Global.boss_alive = false
				Global.enemies_defeated += 1
				queue_free()
				
		if not is_on_floor():
			velocity += get_gravity() * delta
	
		move_and_slide()
	
	
func hit(dmg):
	hit_sound.play()
	death_timer = 0
	is_hit = true
	health -= dmg
	
func death():
	live_box.disabled = true
	
func pontera_attack(power, stn):
	var enemies_hit = hitbox_pontera.get_overlapping_bodies()
	var damage = power
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)
			
func martelo_attack(power, stn):
	var enemies_hit = hitbox_martelo.get_overlapping_bodies()
	var damage = power
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)

func meialua_attack(power, stn):
	var enemies_hit = hitbox_meialua.get_overlapping_bodies()
	var damage = power
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)
	
func update_target_pos(target):
	nav_agent.set_target_position(target)

func _on_navigation_agent_3d_target_reached() -> void:
	if !is_hit:
		attacking = true
		attack_timer += 1
		if attack_timer == 1:
			att_type = randi_range(0, 2)
		match att_type:
			0: # pontera
				_anim_tree["parameters/playback"].travel("pontera")
				if (attack_timer % 99) == 35 || (attack_timer % 99) == 36:
					pontera_attack(100, 15)
				if attack_timer > 99:
					attack_timer = 0
			1: # martelo
				_anim_tree["parameters/playback"].travel("martelo")
				if (attack_timer % 79) == 28 || (attack_timer % 79) == 29:
					martelo_attack(75, 15)
				if attack_timer > 79:
					attack_timer = 0
			2: # meia lua
				_anim_tree["parameters/playback"].travel("meia lua")
				if (attack_timer % 133) == 104 || (attack_timer % 133) == 105:
					meialua_attack(200, 30)
				if attack_timer > 133:
					attack_timer = 0

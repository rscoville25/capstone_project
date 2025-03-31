extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var player_mesh : Node3D = $shooter
@onready var _anim_tree : AnimationTree = $shooter/AnimationTree
@onready var death_box : CollisionShape3D = $DeathHit
@onready var live_box : CollisionShape3D = $LiveBox
@onready var hit_sound : AudioStreamPlayer3D = $HitSound
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox : Area3D = $shooter/HitboxShoot
@onready var gun_fx : GPUParticles3D = $shooter/Gunshot

var death_timer : int
var attack_timer : int
@export var health = 500
var max_health = health

var attacking = false
var is_hit = false

func _ready():
	death_box.disabled = true
	live_box.disabled = false
	death_timer = 0
	attack_timer = 0
	gun_fx.emitting = false

func _physics_process(delta):	
	if !nav_agent.target_reached:
		attack_timer = 0
		
	attacking = false
	var cur_location = global_transform.origin
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - cur_location
	var direction = local_destination.normalized()
	
	nav_agent.set_velocity(direction)
	
	if Global.pause:
		velocity.x = 0
		velocity.y = 0
	else:
		if health >= 0:
			if is_hit:
				attack_timer = 0
				death_timer += 1
				_anim_tree["parameters/playback"].travel("Hit To Body")
				velocity.z = -1
				if death_timer >= 30:
					death_timer = 0
					velocity.z = 0
					is_hit = false
			else:
				if !attacking:
					attack_timer = 0
					_anim_tree["parameters/playback"].travel("Walk")
					velocity = direction * 7.0
					rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
		else:
			death()
			death_timer += 1
			if death_timer >= 65:
				Global.enemies_defeated += 1
				queue_free()
		
		if not is_on_floor():
			velocity += get_gravity() * delta

func hit(dmg):
	hit_sound.play()
	death_timer = 0
	is_hit = true
	health -= dmg
	
func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true
	
func enemy_attack(power, stn):
	var enemies_hit = hitbox.get_overlapping_bodies()
	var damage = power
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)

func update_target_pos(target):
	nav_agent.set_target_position(target)

func _on_navigation_agent_3d_target_reached() -> void:
	attacking = true
	attack_timer += 1
	_anim_tree["parameters/playback"].travel("Idle")
	if !is_hit:
		if attack_timer % 300 >= 220 && attack_timer % 300 <= 290:
			_anim_tree["parameters/playback"].travel("Shooting")
			if attack_timer % 300 == 281 || attack_timer % 300 == 282:
				rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
				gun_fx.emitting = true
				enemy_attack(250, 15)


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

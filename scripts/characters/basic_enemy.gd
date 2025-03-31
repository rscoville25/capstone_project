extends CharacterBody3D

const LERP_VALUE : float = 0.15

@onready var player_mesh : Node3D = $chara
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var death_box : CollisionShape3D = $DeathHit
@onready var live_box : CollisionShape3D = $LiveBox
@onready var hit_sound : AudioStreamPlayer3D = $HitSound
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
@onready var hitbox : Area3D = $chara/HitboxLight
@onready var heat_fx : GPUParticles3D = $chara/HeatParticles
@onready var anim_player: AnimationPlayer = $chara/AnimationPlayer

var death_timer : int
var attack_timer : int
@export var health = 1000
var max_health = health

var attacking = false
var rnd_delay = 0
var is_hit = false


func _ready():
	death_box.disabled = true
	live_box.disabled = false
	death_timer = 0
	attack_timer = 0
	heat_fx.emitting = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):	
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
					_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
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
	
func update_target_pos(target):
	nav_agent.set_target_position(target)
	
func enemy_attack(power, stn):
	var enemies_hit = hitbox.get_overlapping_bodies()
	var damage = power
	var stun = stn
	
	for e in enemies_hit:
		if e.has_method("hurt"):
			e.hurt(damage, stn)

func _on_navigation_agent_3d_target_reached() -> void:
	if !is_hit:
		attacking = true
		attack_timer += 1
		if attack_timer == 1:
			rnd_delay = randi_range(60, 180)
		if attack_timer % rnd_delay <= 33:
			_anim_tree["parameters/playback"].travel("Punching")
		else:
			_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")		
		if (attack_timer % rnd_delay) == 17 || (attack_timer % rnd_delay) == 18:
			enemy_attack(25, 15)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

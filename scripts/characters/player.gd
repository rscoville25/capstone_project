extends CharacterBody3D

@onready var player_mesh : Node3D = $chara
@onready var anim_player : AnimationPlayer = $chara/AnimationPlayer
@onready var spring_arm_pivot : Node3D = $SpringArmPivot
@onready var ui_hp : TextureProgressBar = $HealthBar
@onready var ui_saved : Label = $GameSaved
@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var hitbox_light : Area3D = $chara/HitboxLight
@onready var hitbox_medium : Area3D = $chara/HitboxMedium
@onready var hitbox_heavy : Area3D = $chara/HitboxHeavy
@onready var kick_fx : GPUParticles3D = $chara/GPUParticles3D
@onready var heat_fx : GPUParticles3D = $chara/HeatParticles
@onready var dodge_fx : GPUParticles3D = $chara/DodgeHaze
@onready var live_box : CollisionShape3D = $LiveBox
@onready var death_box : CollisionShape3D = $DeathBox
@onready var ui_money : Label = $Money
@onready var ui_exp : Label = $Experience
@onready var ui_stage : Label = $Stage/Number
@onready var ui_wave : Label = $Wave/Number
@onready var heatbar : TextureProgressBar = $MomentumBar
@onready var activebar : TextureProgressBar = $ActiveCooldown
@onready var active_box : Area3D = $ActiveBox
@onready var active_particles : GPUParticles3D = $ActiveParticles
@onready var poison_fx : GPUParticles3D = $PoisonFX
@onready var active_sfx : AudioStreamPlayer3D = $AbilityExplosion

var config = ConfigFile.new()

const LERP_VALUE : float = 0.15

# three speeds for walking, running, and taking a stance
const WALK = 15.0
const RUN = 30.0
const STANCE = 7.0
const DODGE = 50.0
var speed = WALK

# attacking state and a list of what attacks are available
var attacking = false
var attacks = ["none", "light", "medium", "heavy"]
var cur_attack = attacks[0]

@export var has_active = false
var actives = ["None", "Burst", "Poison Cloud", "Touch of Death"]
var tod_len = 600
var tod_active = false
@export var cur_active = 0

@export var inventory_size = 9
@export var inventory_filled = 0
@export var inventory = [null, null, null, null, null, null, null, null, null, null]
# all stats (hp, attack, level, etc)
@export var health = 1000
@export var max_health = 1000
@export var att = 1
@export var def = 1
@export var heat = 0
@export var money = 100
@export var experience = 0

# timer for stuff, as well as stun value and dodge count
var timer = 0
var stun = 0
@export var downtime = 3600
@export var cooldown = 0
@export var poisoned = false
var poison_tic = 0

var dge_count = 0

var is_hurt = false
@export var is_in_arena = true
@export var at_item_shop = false
@export var at_actives_shop = false
var move_target : Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready():
	if Global.new_game:
		Global.wave = 0
		health = 1000
		max_health = 1000
		att = 1
		def = 1
		money = 100
		experience = 0
		death_box.disabled = true
		live_box.disabled = false
	else:
		load_data()
		
	kick_fx.emitting = false
	kick_fx.one_shot = true
	heat_fx.emitting = true
	heat_fx.speed_scale = 3
	heat_fx.amount_ratio = 0
	poison_fx.emitting = false
	at_item_shop = false
	at_actives_shop = false
	active_particles.emitting = false
	
func _physics_process(delta):
	ui_stage.text = str(Global.stage)
	ui_wave.text = str(Global.wave)
	if Global.dead:
		if Input.is_action_just_pressed("start"):
			Global.wave = 1
			health = 1000
			max_health = 1000
			att = 1
			def = 1
			money = 100
			experience = 0
			save()
			
	
	# display momentum amount
	heatbar.value = heat
	ui_money.text = "$%s" % [str(money)]
	ui_exp.text = "%sxp" % [str(experience)]
	
	# default to being in the arena as false
	is_in_arena = false
	
	# bounds to be considered in the arena
	if global_transform.origin.x <= 100:
		is_in_arena = true
	
	heat_fx.amount_ratio = heat * 0.01
	
	if Global.buying:
		save()
		ui_saved.visible = true
		ui_hp.visible = false
		heatbar.visible = false

	else:
		ui_saved.visible = false
		ui_hp.visible = true
		heatbar.visible = true
	
	_anim_tree["parameters/playback"].travel("Idle")
	dodge_fx.emitting = false
	
	if !has_active:
		activebar.visible = false
	else:
		activebar.visible = true
		activebar.value = cooldown
		activebar.max_value = downtime
		if cooldown < downtime && !Global.shop_time:
			cooldown += 1
		if cooldown >= downtime:
			if Input.is_action_just_pressed("interact") && !Global.shop_time:
				active_sfx.play()
				use_ability(cur_active)
	
	# UI business
	ui_hp.value = health
	ui_hp.max_value = max_health
	
	# tells you when you're attacking and what attack is being used
	attacking = false
	cur_attack = attacks[0]
	if Global.pause || Global.buying || Global.tutorial_splash:
		anim_player.speed_scale = 0
		heat_fx.speed_scale = 0
		dodge_fx.speed_scale = 0
		kick_fx.speed_scale = 0
		velocity.x = 0
		velocity.z = 0
	else:
		if tod_active:
			tod_len -= 1
			if tod_len <= 0:
				tod_active = false
		
		heat_fx.speed_scale = 2.8
		dodge_fx.speed_scale = 1
		kick_fx.speed_scale = 1
		
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
					if Input.is_action_pressed("light_attack") && !Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack") && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[1]
						if (timer % 33) == 17 || (timer % 33) == 18:
							heat += 1
							if heat > 100:
								heat = 100
							if !tod_active:
								light_attack(att, heat)
							else:
								light_attack(100, heat)
							
					if Input.is_action_pressed("medium_attack") && !Input.is_action_pressed("heavy_attack")  && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[2]
						if (timer % 62) == 34 || (timer % 62) == 35:
							heat += 2
							if heat > 100:
								heat = 100
							if !tod_active:
								medium_attack(att, heat)
							else:
								medium_attack(100, heat)
							
					if Input.is_action_pressed("heavy_attack")  && !Input.is_action_pressed("dodge"):
						timer += 1
						attacking = true
						cur_attack = attacks[3]
						if (timer % 77) == 30 || (timer % 77) == 31:
							heat += 3					
							if heat > 100:
								heat = 100
							if !tod_active:
								heavy_attack(att, heat)
							else:
								heavy_attack(100, heat)
						if (timer % 77) >= 30 && (timer % 77) <= 38:
							kick_fx.emitting = true

				
				# set timer to 0 when attack buttons are pressed
				if Input.is_action_just_released("heavy_attack"):
					timer = 0
				if Input.is_action_just_released("medium_attack"):
					timer = 0
				if Input.is_action_just_released("light_attack"):
					timer = 0

				
				# get direction of movement
				var direction : Vector3 = Vector3.ZERO
				direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
				direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
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
				var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
				
				# A lot of what comes next could be a match statement, but this works for now (even if it is very ugly)
				if direction:
					if speed == WALK:
						_anim_tree["parameters/playback"].travel("Walking")
						spring_arm_pivot.change_fov_on_run = false
					elif speed == RUN:
						_anim_tree["parameters/playback"].travel("Running")
						spring_arm_pivot.change_fov_on_run = true
					elif speed == STANCE:
						_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
						spring_arm_pivot.change_fov_on_run = false
					if speed != STANCE:
						velocity.x = direction.x * speed
						velocity.z = direction.z * speed
				else:
					spring_arm_pivot.change_fov_on_run = false
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
		if poisoned:
			poison_fx.emitting = true
			poison_tic += 1
			if poison_tic % 60 == 0:
				health -= 10
		else:
			poison_fx.emitting = false
					
		move_and_slide()
			
func light_attack(power, bonus):
	var enemies_hit = hitbox_light.get_overlapping_bodies()
	var damage = power * 25 + (bonus * 0.5)
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)
			
func medium_attack(power, bonus):
	var enemies_hit = hitbox_medium.get_overlapping_bodies()
	var damage = power * 33 + (bonus * 0.5)
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)
			
func heavy_attack(power, bonus):
	var enemies_hit = hitbox_heavy.get_overlapping_bodies()
	var damage = power * 50 + (bonus * 0.5)
	
	for e in enemies_hit:
		if e.has_method("hit"):
			e.hit(damage)

func use_ability(current: int):
	match current:
		1:
			var enemies_hit = active_box.get_overlapping_bodies()
			var damage = 1000
			active_particles.emitting = true
			for e in enemies_hit:
				if e.has_method("hit"):
					e.hit(damage)
		2:
			var enemies_hit = active_box.get_overlapping_bodies()
			active_particles.emitting = true
			for e in enemies_hit:
				if e.has_method("poison"):
					e.poison()
		3:
			tod_active = true
			tod_len = 600
			
	cooldown = 0

func hurt(dmg, stn):
	is_hurt = true
	if !Input.is_action_pressed("fight_stance"):
		health -= dmg - ((def - 1) * 1.5)
		if heat <= 0:
			heat = 0
		else:
			heat -= 20
		stun = stn
	else:
		health -= 1
		if heat <= 0:
			heat = 0
		else:	
			heat -= 1
			
func poisoning():
	if !Input.is_action_pressed("fight_stance"):
		poisoned = true

func death():
	_anim_tree["parameters/playback"].travel("Stunned")
	death_box.disabled = false
	live_box.disabled = true
	Global.dead = true

func save():
	config.set_value("Inventory", "inventory", inventory)
	config.set_value("Inventory", "inventory_filled", inventory_filled)
	config.set_value("Inventory", "cur_active", cur_active)
	config.get_value("Inventory", "has_active", has_active)
	config.set_value("Stats", "hp", health)
	config.set_value("Stats", "max_hp", max_health)
	config.set_value("Stats", "attack", att)
	config.set_value("Stats", "defense", def)
	config.set_value("Stats", "money", money)
	config.set_value("Stats", "exp", experience)

	config.save("user://player.cfg")
	
func load_data():
	var load = config.load("user://player.cfg")
	if load != OK:
		return
	inventory = config.get_value("Inventory", "inventory")
	inventory_filled = config.get_value("Inventory", "inventory_filled", 0)
	cur_active = config.get_value("Inventory", "cur_active", 0)
	has_active = config.get_value("Inventory", "has_active", false)
	health = config.get_value("Stats", "hp", 1000)
	max_health = config.get_value("Stats", "max_hp", 1000)
	att = config.get_value("Stats", "attack", 1)
	def = config.get_value("Stats", "defense", 1)
	money = config.get_value("Stats", "money", 1)
	experience = config.get_value("Stats", "exp", 0)

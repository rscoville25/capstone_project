extends Node3D

var config = ConfigFile.new()

@export var enemy : PackedScene
@export var boss_dancer : PackedScene
@export var gun_enemy : PackedScene
@export var boss_mirror : PackedScene
@export var boss_runner : PackedScene

@onready var player : CharacterBody3D = $Player
@onready var input_prompt : TextureRect = $Player/InputPrompt
@onready var player_camera : Camera3D = $Player/SpringArmPivot/SpringArm3D/Camera3D
@onready var spawner : Marker3D = $Spawner
@onready var boss_spawner : Marker3D = $BossSpawner
@onready var door_sensor : CollisionShape3D = $ShopDoor/CollisionShape3D
@onready var door : MeshInstance3D = $PhysicalDoor
@onready var ui_text : Label = $Label
@onready var nav_region : NavigationRegion3D = $NavigationRegion3D
@onready var arena_area : Area3D = $Arena
@onready var shopkeeper : AnimationTree = $Shopkeeper/AnimationTree
@onready var shopkeeper_main : GPUParticles3D = $Shopkeeper/HeatParticles
@onready var pause_text : Label = $PauseText
@onready var shop_camera : Camera3D = $Shopkeeper/Camera3D
@onready var shop_area : Area3D = $ShopArea
@onready var shop_window : ColorRect = $ShopWindow
@onready var shop_select : Label = $ShopWindow/ShopSelect
@onready var shop_item1 : Label = $ShopWindow/ShopItem1
@onready var shop_item2 : Label = $ShopWindow/ShopItem2
@onready var shop_item3 : Label = $ShopWindow/ShopItem3
@onready var shop_item4 : Label = $ShopWindow/ShopItem4
@onready var shop_item5 : Label = $ShopWindow/ShopItem5
@onready var pause_menu_inv : ColorRect = $PauseMenuInv
@onready var item1 : Label = $PauseMenuInv/VBoxContainer/Item1
@onready var item2 : Label = $PauseMenuInv/VBoxContainer/Item2
@onready var item3 : Label = $PauseMenuInv/VBoxContainer/Item3
@onready var item4 : Label = $PauseMenuInv/VBoxContainer/Item4
@onready var item5 : Label = $PauseMenuInv/VBoxContainer/Item5
@onready var item6 : Label = $PauseMenuInv/VBoxContainer/Item6
@onready var item7 : Label = $PauseMenuInv/VBoxContainer/Item7
@onready var item8 : Label = $PauseMenuInv/VBoxContainer/Item8
@onready var item9 : Label = $PauseMenuInv/VBoxContainer/Item9
@onready var item10 : Label = $PauseMenuInv/VBoxContainer/Item10
@onready var controller : ColorRect = $TutorialWindow
@onready var inv_pointer : Label = $PauseMenuInv/Pointer
@onready var pause_menu_stat : ColorRect = $PauseMenuStat
@onready var ui_health : Label = $PauseMenuStat/VBoxContainer/Health
@onready var ui_health_max : Label = $PauseMenuStat/VBoxContainer/HealthMax
@onready var ui_attack : Label = $PauseMenuStat/VBoxContainer/Attack
@onready var ui_defense : Label = $PauseMenuStat/VBoxContainer/Defense
@onready var death_text : Label = $DeathText

# import all of the sounds used for music
@onready var theme_drums1 : AudioStreamPlayer = $DrumBreak
@onready var theme_drums2 : AudioStreamPlayer = $DrumProgram
@onready var theme_bass : AudioStreamPlayer = $Bass
@onready var theme_ambience : AudioStreamPlayer = $Ambience
@onready var theme_main : AudioStreamPlayer = $Melody
@onready var theme_guitar : AudioStreamPlayer = $Guitar
@onready var theme_arp : AudioStreamPlayer = $Arp

var spawn_time = 0
var shop_item = 0
var inv_select = 0

var items_in_shop = ["Health Restore", "Momentum Boost", "HP Up", "Attack Up", "Defense Up" ]
var hp_cost = 1
var att_cost = 1
var def_cost = 1

func _ready():
	Global.pause = false
	if !Global.new_game:
		load_data()
		Global.tutorial_splash = false
	else:
		Global.tutorial_splash = true
		Global.enemies_defeated = 0
		Global.enemies_spawned = 0
	Global.shop_time = true
	controller.visible = true
	ui_text.visible = true
	shopkeeper_main.emitting = false
	input_prompt.visible = false
	pause_text.visible = false
	pause_menu_inv.visible = false
	pause_menu_stat.visible = false
	death_text.visible = false
	
	# the initial volume for each instrument, based on how it should sound during shop time
	theme_drums1.volume_db = -60
	theme_ambience.volume_db = -60
	theme_drums2.volume_db = 0
	theme_bass.volume_db = 0
	theme_main.volume_db = -60
	theme_guitar.volume_db = -60
	theme_arp.volume_db = 0
	
	
func _process(delta):
	if Global.dead:
		death_text.visible = true
		Global.wave = 1
		Global.enemies_defeated = 0
		Global.enemies_spawned = 0
		hp_cost = 1
		att_cost = 1
		def_cost = 1
		if Input.is_action_just_pressed("start"):
			save()
			get_tree().change_scene_to_file("res://scenes/rooms/title.tscn")
	
	# reactive musics
	if !theme_drums1.playing:
		theme_drums1.play()
		theme_drums2.play()
		theme_bass.play()
		theme_ambience.play()
		theme_main.play()
		theme_guitar.play()
		theme_arp.play()
	if !Global.shop_time:
		if Global.pause:
			theme_drums1.volume_db = -60
			theme_drums2.volume_db = -60
			theme_ambience.volume_db = 0
			theme_main.volume_db = -60
			theme_guitar.volume_db = -60
			theme_arp.volume_db = -60
		else:
			theme_guitar.volume_db = (player.heat * 0.6) - 69
			theme_arp.volume_db = 0
			if theme_drums1.volume_db <= -60 && theme_drums2.volume_db <= -60:
				theme_drums1.volume_db = 0
				theme_ambience.volume_db = -60
				theme_main.volume_db = 0
			else:
				if theme_drums2.volume_db > -60:
					theme_guitar.volume_db -= 1
					theme_drums2.volume_db -= 1
				if theme_drums1.volume_db < 0:
					theme_main.volume_db += 1
					theme_drums1.volume_db += 1
	else:
		theme_arp.volume_db = 0
		theme_guitar.volume_db = (player.heat * 0.6) - 66
		if theme_drums2.volume_db < 0:
			theme_main.volume_db -= 1
			theme_drums1.volume_db -= 1
			theme_drums2.volume_db += 1
	

	if player.inventory[0] != null:
		item1.text = player.inventory[0]
	else:
		item1.text = ""
	if player.inventory[1] != null:	
		item2.text = player.inventory[1]
	else:
		item2.text = ""
	if player.inventory[2] != null:
		item3.text = player.inventory[2]
	else:
		item3.text = ""
	if player.inventory[3] != null:
		item4.text = player.inventory[3]
	else:
		item4.text = ""
	if player.inventory[4] != null:
		item5.text = player.inventory[4]
	else:
		item5.text = ""
	if player.inventory[5] != null:
		item6.text = player.inventory[5]
	else:
		item6.text = ""
	if player.inventory[6] != null:
		item7.text = player.inventory[6]
	else:
		item7.text = ""
	if player.inventory[7] != null:
		item8.text = player.inventory[7]
	else:
		item8.text = ""
	if player.inventory[8] != null:
		item9.text = player.inventory[8]
	else:
		item9.text = ""
	if player.inventory[9] != null:
		item10.text = player.inventory[9]
	else:
		item10.text = ""
		
	if Input.is_action_just_pressed("start") && !Global.dead:
		if Global.pause:
			Global.pause = false
			pause_menu_inv.visible = false
			pause_menu_stat.visible = false
		elif !Global.pause && !Global.shop_time:
			Global.pause = true
			pause_menu_inv.visible = true
			pause_menu_stat.visible = true
	if !Global.dead:
		if Global.pause:
			ui_health.text = "Current HP: %s" % [str(player.health)]
			ui_health_max.text = "Max HP: %s" % [str(player.max_health)]
			ui_attack.text = "Attack: %s" % [str(player.att)]
			ui_defense.text = "Defense: %s" % [str(player.def)]
			pause_text.visible = true
			inv_pointer.global_position.y = 24 * inv_select + 98
			
			if Input.is_action_just_pressed("ui_up"):
				if inv_select <= 0:
					inv_select = player.inventory_filled - 1
				else:
					inv_select -= 1
			
			if Input.is_action_just_pressed("ui_down"):
				if inv_select >= player.inventory_filled - 1:
					inv_select = 0
				else:
					inv_select += 1
			if Input.is_action_just_pressed("dodge"):
				if player.inventory[inv_select] == "Health Restore":
					if player.health <= player.max_health - 500:
						player.health += 500
					else:
						player.health = player.max_health
					player.inventory[inv_select] = null
					player.inventory_filled -= 1
				elif player.inventory[inv_select] == "Momentum Boost":
					player.heat = 100
					player.inventory[inv_select] = null
					player.inventory_filled -= 1
				player.inventory.remove_at(inv_select)
				player.inventory.append(null)
					
		else:			
			pause_text.visible = false
			# enemy pathfinding
			get_tree().call_group("enemies_g", "update_target_pos", player.global_transform.origin)
		
	if Global.buying:
		save()
		shop_item3.text = "HP Up: %sxp" % [str(hp_cost)]
		shop_item4.text = "Attack Up: %sxp" % [str(att_cost)]
		shop_item5.text = "Defense Up: %sxp" % [str(def_cost)]
		shop_camera.current = true
		ui_text.visible = false
		input_prompt.visible = false
		shop_window.visible = true
		shop_select.global_position.y = shop_item * 60 + 121
		if Input.is_action_just_pressed("ui_down"):
			if shop_item != 4:
				shop_item += 1
			else:
				shop_item = 0
		if Input.is_action_just_pressed("ui_up"):
			if shop_item != 0:
				shop_item -= 1
			else:
				shop_item = 4
		
		if Input.is_action_just_pressed("dodge"):
			match shop_item:
				0:
					if player.inventory_filled <= player.inventory_size:
						if player.money >= 100:
							player.money -= 100
							player.inventory[player.inventory.find(null)] = items_in_shop[0]
							player.inventory_filled += 1
				1:
					if player.inventory_filled <= player.inventory_size:
						if player.money >= 75:
							player.money -= 75
							player.inventory[player.inventory.find(null)] = items_in_shop[1]
							player.inventory_filled += 1
				2:
					if player.experience >= hp_cost:
						player.max_health += 100
						player.health = player.max_health
						player.experience -= hp_cost
						hp_cost *= 2

				3:
					if player.experience >= att_cost:
						player.att += 1
						player.health = player.max_health
						player.experience -= att_cost
						att_cost *= 2

				4:
					if player.experience >= def_cost:
						player.def += 1
						player.health = player.max_health
						player.experience -= def_cost
						def_cost *= 2

	else:
		player_camera.current = true
		shop_window.visible = false
	
	# shop animation
	shopkeeper["parameters/playback"].travel("Idle")
	
	if Global.tutorial_splash:
		if Input.is_action_just_pressed("dodge"):
			controller.visible = false
			Global.tutorial_splash = false
	else:
		controller.visible = false
	# detects if player is inside the arena. If true, press start to begin the wave
		if Global.shop_time == true:
			if !Global.buying:
				ui_text.visible = true
			ui_text.text = "Go To Arena"
			if player.is_in_arena:
				ui_text.text = "Press Start to Begin"
				if Input.is_action_just_pressed("start"):
					spawn_time = 0
					Global.wave += 1
					Global.shop_time = false
			# shop door open during shop time
			door.global_transform.origin.y = -25
			if player.at_shop:
				input_prompt.visible = true
				if Input.is_action_just_pressed("interact"):
					if !Global.buying:
						Global.buying = true
					else:
						Global.buying = false
			else:
				input_prompt.visible = false
			
		else:
			# shop door closed during fight time
			door.global_transform.origin.y = 25
			ui_text.visible = false
			
			# spawn a certain amount of enemies depending on the wave
			if !Global.pause:
				spawn_time += 1
				if Global.wave % 4 == 0 && !Global.boss_alive:
					if spawn_time % 60 == 1:
						boss_spawn(Global.wave)
						Global.enemies_spawned += 1
						Global.boss_alive = true
				if Global.enemies_spawned < Global.wave:
					if Global.wave % 4 != 0:
						if spawn_time % 60 == 1:
							spawn(Global.wave, Global.stage)
							Global.enemies_spawned += 1

						
				if Global.enemies_spawned <= Global.enemies_defeated && spawn_time % 60 > 10:
					player.money += 100 * Global.wave
					player.experience += Global.wave
					Global.enemies_spawned = 0
					Global.enemies_defeated = 0
					Global.shop_time = true

# function that spawns the enemies
func spawn(wave, stage):
	var rng_spawn = randi_range(0, 100)
	if wave >= 1 && stage <= 1:
		match stage:
			1:
				var enemy1 = enemy.instantiate()
				enemy1.global_position = spawner.global_position
				add_child(enemy1)
			2:
				if rng_spawn <= 90:
					var enemy1 = enemy.instantiate()
					enemy1.global_position = spawner.global_position
					add_child(enemy1)
				else:
					var gun = gun_enemy.instantiate()
					gun.global_position = spawner.global_position
					add_child(gun)

func boss_spawn(wave):
	if wave % 4 == 0:
		var rng_boss = randi_range(0, 2)
		match rng_boss:
			0:
				var boss = boss_mirror.instantiate()
				add_child(boss)
			1:
				var boss = boss_dancer.instantiate()
				add_child(boss)
			2:
				var boss = boss_runner.instantiate()
				add_child(boss)

func _on_shop_area_area_entered(area: Area3D) -> void:
	player.at_shop = true

func _on_shop_area_area_exited(area: Area3D) -> void:
	player.at_shop = false
	
func save():
	config.set_value("Shop", "health_cost", hp_cost)
	config.set_value("Shop", "attack_cost", att_cost)
	config.set_value("Shop", "defense_cost", def_cost)
	
	config.save("user://main.cfg")
	
func load_data():
	Global.load_data()	
	var load_main = config.load("user://main.cfg")
	if load_main != OK:
		return
	
	hp_cost = config.get_value("Shop", "health_cost")
	att_cost = config.get_value("Shop", "attack_cost")
	def_cost = config.get_value("Shop", "defense_cost")

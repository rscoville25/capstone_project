extends Node3D

@export var enemy : PackedScene

@onready var player : CharacterBody3D = $Player
@onready var input_prompt : TextureRect = $Player/InputPrompt
@onready var player_camera : Camera3D = $Player/SpringArmPivot/SpringArm3D/Camera3D
@onready var spawner : Marker3D = $Spawner
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
@onready var shop_inventory : RichTextLabel = $ShopList
@onready var shop_select : Label = $ShopSelect

var spawn_time = 0
var shop_item = 0

var items_in_shop = ["Health Restore", "Momentum Boost", "HP Up", "Attack Up", "Defense Up" ]
var hp_cost = 1
var att_cost = 1
var def_cost = 1

func _ready():
	Global.wave = 0
	Global.enemies_spawned = 0
	Global.shop_time = true
	ui_text.visible = true
	shopkeeper_main.emitting = false
	input_prompt.visible = false
	pause_text.visible = false
	
	
func _process(delta):
	if Input.is_action_just_pressed("start"):
		if Global.pause:
			Global.pause = false
		elif !Global.pause && !Global.shop_time:
			Global.pause = true
	
	if Global.pause:
		pause_text.visible = true	
	# enemy pathfinding
	else:			
		pause_text.visible = false
		get_tree().call_group("enemies_g", "update_target_pos", player.global_transform.origin)
		
	if Global.buying:
		shop_camera.current = true
		ui_text.visible = false
		input_prompt.visible = false
		shop_window.visible = true
		shop_inventory.visible = true
		shop_select.visible = true
		shop_select.global_position.y = shop_item * 23 + 29
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
					if player.money >= 100:
						player.money -= 100
				1:
					if player.money >= 75:
						player.money -= 75
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
		shop_inventory.visible = false
		shop_select.visible = false
	
	# shop animation
	shopkeeper["parameters/playback"].travel("Idle")
	
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
			if Global.enemies_spawned < Global.wave:
				if spawn_time % 60 == 1:
					spawn(Global.wave)
					Global.enemies_spawned += 1
			if Global.enemies_spawned <= Global.enemies_defeated && spawn_time % 60 > 10:
				player.money += 100 * Global.wave
				player.experience += Global.wave
				Global.enemies_spawned = 0
				Global.enemies_defeated = 0
				Global.shop_time = true

# function that spawns the enemies
func spawn(wave):
	if wave >= 1:
		var enemy1 = enemy.instantiate()
		enemy1.global_position = spawner.global_position
		add_child(enemy1)
		
func _on_shop_area_area_entered(area: Area3D) -> void:
	player.at_shop = true

func _on_shop_area_area_exited(area: Area3D) -> void:
	player.at_shop = false

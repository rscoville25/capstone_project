extends Node3D

@export var enemy : PackedScene

@onready var player : CharacterBody3D = $Player
@onready var spawner : Marker3D = $Spawner
@onready var door_sensor : CollisionShape3D = $ShopDoor/CollisionShape3D
@onready var door : MeshInstance3D = $PhysicalDoor
@onready var ui_text : Label = $Label
@onready var nav_region : NavigationRegion3D = $NavigationRegion3D
@onready var arena_area : Area3D = $Arena

var spawn_time = 0

func _ready():
	Global.wave = 0
	Global.enemies_spawned = 0
	Global.shop_time = true
	ui_text.visible = true
	
	
func _process(delta):
	get_tree().call_group("enemies_g", "update_target_pos", player.global_transform.origin)
	
	if Global.shop_time == true:
		ui_text.visible = true
		ui_text.text = "Go To Arena"
		if player.is_in_arena:
			ui_text.text = "Press Start to Begin"
			if Input.is_action_just_pressed("start"):
				
				Global.shop_time = false
				Global.wave += 1
		door.global_transform.origin.y = -25
	else:
		door.global_transform.origin.y = 25
		ui_text.visible = false
		if Global.enemies_spawned < Global.wave:
			spawn_time += 1
			if spawn_time % 60 == 2:
				spawn(Global.wave)
				Global.enemies_spawned += 1

func spawn(wave):
	if wave >= 1:
		var enemy1 = enemy.instantiate()
		enemy1.global_position = spawner.global_position
		add_child(enemy1)
		

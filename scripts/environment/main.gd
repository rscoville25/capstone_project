extends Node3D

@export var enemy : PackedScene

@onready var player : CharacterBody3D = $Player
@onready var spawner : Marker3D = $Spawner
@onready var music : AudioStreamPlayer = $Music

func _ready():
	Global.wave = 0
	Global.enemies_spawned = 0
	music.play()

	
	
func _process(delta):
	get_tree().call_group("enemies_g", "update_target_pos", player.global_transform.origin)
	
	if Global.enemies_spawned <= 0 :
		Global.wave += 1
		spawn(Global.wave)
		Global.enemies_spawned += 1

func spawn(wave):
	if wave >= 1:
		var enemy1 = enemy.instantiate()
		enemy1.global_position = spawner.global_position
		add_child(enemy1)
		

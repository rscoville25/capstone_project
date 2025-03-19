extends Node3D

var cur_wave : int

@export var enemy : PackedScene

var enemy_amt : int
var spawn_on

func _ready():
	cur_wave = 0

	
	
func _process(delta):
	if enemy_amt <= 1:
		cur_wave += 1
		spawn(cur_wave)
	

func spawn(wave):
	var spawner = $Spawner
	if wave >= 1:
		var enemy1 = enemy.instantiate()
		enemy1.global_position = spawner.global_position
		add_child(enemy1)
		
	enemy_amt += 1

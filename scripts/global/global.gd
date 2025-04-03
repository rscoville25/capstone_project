extends Node


var stage = 1 # increases after boss is defeated. Unlocks new enemy types
var wave = 0 # how many waves have occured
var enemies_spawned = 0 # total number of enemies spawned
var enemies_defeated = 0 # total enemies defeated
var boss_alive : bool = false # is the boss currently alive

var character_position : Vector3 # the location of the character in a 3d space

var shop_time : bool = false # is the shop open

var new_game : bool = true # is this a new game

var tutorial_splash : bool = false # do we show the controls before the game starts
var pause : bool = false # is the game paused
var buying : bool = false # is the player buying from the shop

var dead: bool = false # is the player dead

var config = ConfigFile.new()

func _process(delta: float) -> void:
	if buying:
		save()
	
	if dead:
		stage = 1 
		wave = 0
		enemies_spawned = 0 
		enemies_defeated = 0
		save()

func save():
	config.set_value("Global", "stage", stage)
	config.set_value("Global", "wave", wave)
	config.set_value("Global", "enemies_spawned", enemies_spawned)
	config.set_value("Global", "enemies_defeated", enemies_defeated)
	
	config.save("user://global.cfg")

func load_data():
	var load = config.load("user://global.cfg")
	if load != OK:
		return
	stage = config.get_value("Global", "stage", 1)
	wave = config.get_value("Global", "wave", 0)
	enemies_defeated = config.get_value("Global", "enemies_defeated", 0)
	enemies_spawned = config.get_value("Global", "enemies_spawned", 0)

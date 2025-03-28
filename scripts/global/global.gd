extends Node


var stage : int = 1 # currently unused
var wave : int = 1 # how many waves have occured
var enemies_spawned : int = 0 # total number of enemies spawned
var enemies_defeated : int = 0 # total enemies defeated
var boss_alive : bool = false # is the boss currently alive

var character_position : Vector3 # the location of the character in a 3d space

var shop_time : bool = false # is the shop open

var new_game : bool = true # is this a new game

var tutorial_splash : bool = false # do we show the controls before the game starts
var pause : bool = false # is the game paused
var buying : bool = false # is the player buying from the shop

var dead: bool = false # is the player dead

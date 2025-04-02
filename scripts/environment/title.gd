extends Node3D

var save_path = "res://src/save/player.save"


@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var music : AudioStreamPlayer = $Music
@onready var loading : Label = $Loading
@onready var start_text = $Label
@onready var game_menu = $GameMenu
@onready var pointer = $GameMenu/Pointer
@onready var load : Label = $GameMenu/LoadGame

var select_timer = 0
var start_timer = false

var game_picked = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music.play()
	loading.visible = false
	game_menu.visible = false
	start_text.visible = true
	Global.dead = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(Global.new_game)
	_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
	
	if Input.is_action_just_pressed("start"):
		start_text.visible = false
		game_menu.visible = true
		
	if game_menu.visible:
		pointer.global_position.y = 30 * game_picked
		
		if FileAccess.file_exists("user://player.cfg") || FileAccess.file_exists("user://main.cfg"):
			if Input.is_action_just_pressed("ui_up"):
				if game_picked <= 0:
					game_picked = 3
				else:
					game_picked -= 1
			if Input.is_action_just_pressed("ui_down"):
				if game_picked >= 3:
					game_picked = 0
					Global.new_game = true
				else:
					game_picked += 1
		else:
			Global.new_game = true
			load.visible = false
				
		if Input.is_action_just_pressed("dodge"):
			match game_picked:
				0:
					Global.new_game = true
					start_timer = true
				1:
					Global.new_game = false
					start_timer = true
				2:
					get_tree().change_scene_to_file("res://scenes/rooms/music.tscn")
	
	if start_timer:
		select_timer += 1
		_anim_tree["parameters/playback"].travel("Roundhouse Kick")
		if select_timer >= 37:
			loading.visible = true
		if select_timer >= 38:
			get_tree().change_scene_to_file("res://scenes/rooms/main.tscn")
	

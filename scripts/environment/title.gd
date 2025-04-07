extends Node3D


@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var music : AudioStreamPlayer = $Music
@onready var loading : Label = $Loading
@onready var start_text = $Label
@onready var game_menu = $GameMenu
@onready var pointer = $GameMenu/Pointer
@onready var load : Label = $GameMenu/LoadGame
@onready var option_menu : ColorRect = $Options
@onready var option_pointer : Label = $Options/Pointer
@onready var fullscreen_opt : Label = $Options/HBoxContainer/OnOff/Fullscreen

var select_timer = 0
var start_timer = false
var option_select = false
var option = 0

var game_picked = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.load_data()
	music.play()
	loading.visible = false
	game_menu.visible = false
	start_text.visible = true
	Global.dead = false
	option_select = false
	option_menu.visible = false
	
	if Global.fullscreen:
		fullscreen_opt.text = "On"
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		fullscreen_opt.text = "Off"
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")

	
	if Input.is_action_just_pressed("start"):
		start_text.visible = false
		game_menu.visible = true
		
	if game_menu.visible && !option_select:
		option_menu.visible = false
		pointer.global_position.y = 30 * game_picked
		
		if Input.is_action_just_pressed("ui_up"):
			if game_picked <= 0:
				game_picked = 3
			else:
				game_picked -= 1
		if Input.is_action_just_pressed("ui_down"):
			if game_picked >= 3:
				game_picked = 0
			else:
				game_picked += 1
				
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
				3:
					option_select = true

	if option_select:
		if Global.fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		option_menu.visible = true
		if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("ui_left"):
			if Global.fullscreen:
				Global.fullscreen = false
				fullscreen_opt.text = "Off"
			else:
				Global.fullscreen = true
				fullscreen_opt.text = "On"
			if Global.fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		if Input.is_action_just_pressed("start"):
			option_select = false
		
	
	if start_timer:
		select_timer += 1
		_anim_tree["parameters/playback"].travel("Roundhouse Kick")
		if select_timer >= 37:
			loading.visible = true
		if select_timer >= 38:
			get_tree().change_scene_to_file("res://scenes/rooms/main.tscn")
	

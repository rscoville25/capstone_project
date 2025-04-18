extends Node3D

var tracklist = ["<- Title Screen ->", "<- Arena ->", "<- Shop ->", "<- Pause ->"]

@onready var track_name : Label = $VBoxContainer/TrackName
@onready var menu_theme : AudioStreamPlayer = $CMenu
@onready var main_fight : AudioStreamPlayer = $MainFight
@onready var main_shop : AudioStreamPlayer = $MainShop
@onready var main_pause : AudioStreamPlayer = $MainPause

var track_select = 0

func _ready():
	track_name.text = tracklist[track_select]
	
func _process(delta: float) -> void:
	track_name.text = tracklist[track_select % 4]
	if Input.is_action_just_pressed("ui_left"):
		track_select -= 1
	if Input.is_action_just_pressed("ui_right"):
		track_select += 1
	
	if Input.is_action_just_pressed("start"):
		match track_select % 4:
			0:
				if main_fight.playing:
					main_fight.stop()
				if !menu_theme.playing:
					menu_theme.play()
				if main_shop.playing:
					main_shop.stop()
				if main_pause.playing:
					main_pause.stop()
			1:
				if menu_theme.playing:
					menu_theme.stop()
				if !main_fight.playing:
					main_fight.play()
				if main_shop.playing:
					main_shop.stop()
				if main_pause.playing:
					main_pause.stop()
			2:
				if menu_theme.playing:
					menu_theme.stop()
				if main_fight.playing:
					main_fight.stop()
				if !main_shop.playing:
					main_shop.play()
				if main_pause.playing:
					main_pause.stop()
			3:
				if menu_theme.playing:
					menu_theme.stop()
				if main_fight.playing:
					main_fight.stop()
				if main_shop.playing:
					main_shop.stop()
				if !main_pause.playing:
					main_pause.play()
				
	if Input.is_action_just_pressed("heavy_attack"):
		get_tree().change_scene_to_file("res://scenes/rooms/title.tscn")

extends Node3D

var tracklist = ["<- Title Screen ->", "<- Arena ->", "<- Shop ->", "<- Pause ->"]

@onready var track_name : Label = $VBoxContainer/TrackName
@onready var menu_theme : AudioStreamPlayer = $CMenu
@onready var theme_ambience : AudioStreamPlayer = $ThemeAmbience
@onready var theme_arp : AudioStreamPlayer = $ThemeArp
@onready var theme_bass : AudioStreamPlayer = $ThemeBass
@onready var theme_drums1 : AudioStreamPlayer = $ThemeDrums1
@onready var theme_drums2 : AudioStreamPlayer = $ThemeDrums2
@onready var theme_guitar : AudioStreamPlayer = $ThemeGuitar
@onready var theme_main : AudioStreamPlayer = $ThemeMain
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
				theme_drums2.stop()
				theme_ambience.stop()
				theme_arp.stop()
				theme_bass.stop()
				theme_drums1.stop()
				theme_main.stop()
				menu_theme.play()
			1:
				theme_ambience.stop()
				menu_theme.stop()
				theme_drums2.stop()
				theme_arp.play()
				theme_bass.play()
				theme_drums1.play()
				theme_main.play()
			2:
				if menu_theme.playing:
					menu_theme.stop()
				if theme_ambience.playing:
					theme_ambience.stop()
				if theme_drums1.playing:
					theme_drums1.stop()
					theme_main.stop()
				theme_drums2.play()
				theme_arp.play()
				theme_bass.play()

			3:
				if menu_theme.playing:
					menu_theme.stop()
				theme_ambience.play()
				menu_theme.stop()
				theme_drums2.stop()
				theme_guitar.stop()
				theme_arp.stop()
				theme_bass.play()
				theme_drums1.stop()
				theme_main.stop()
				
	if Input.is_action_just_pressed("heavy_attack"):
		get_tree().change_scene_to_file("res://scenes/rooms/title.tscn")

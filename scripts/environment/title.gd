extends Node3D

@onready var _anim_tree : AnimationTree = $chara/AnimationTree
@onready var music : AudioStreamPlayer = $Music

var select_timer = 0
var start_timer = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
	
	if Input.is_action_pressed("start"):
		start_timer = true
	
	if start_timer:
		select_timer += 1
		_anim_tree["parameters/playback"].travel("Roundhouse Kick")
		if select_timer >= 38:
			get_tree().change_scene_to_file("res://scenes/rooms/main.tscn")
	

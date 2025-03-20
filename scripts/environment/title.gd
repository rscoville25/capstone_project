extends Node3D

@onready var _anim_tree : AnimationTree = $chara/AnimationTree

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_anim_tree["parameters/playback"].travel("Bouncing Fight Idle")
	
	if Input.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://scenes/rooms/main.tscn")
	

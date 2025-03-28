extends Node3D

@export_group("FOV")
@export var change_fov_on_run : bool
@export var normal_fov : float = 75.0
@export var run_fov : float = 90.0

const CAMERA_BLEND : float = 0.05

@onready var spring_arm : SpringArm3D = $SpringArm3D
@onready var camera : Camera3D = $SpringArm3D/Camera3D

func _ready():
	camera.fov = normal_fov
	change_fov_on_run = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * 0.005)
			spring_arm.rotate_x(-event.relative.y * 0.005)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
	
func _physics_process(delta):
	var look_dir: Vector3 = Vector3.ZERO
	look_dir.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	look_dir.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	rotate_y(-look_dir.x * 0.05)
	spring_arm.rotate_x(-look_dir.y * 0.05)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

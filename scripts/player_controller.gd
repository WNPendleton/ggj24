class_name Player
extends CharacterBody3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var LOOK_SPEED = 0.01
@export var max_rot_y = PI/2

@onready var camera = get_node("Camera")

var rot_x = 0
var rot_y = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var input_dir = Input.get_vector("strafe-left", "strafe-right", "forward", "backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		rot_x += event.relative.x * LOOK_SPEED
		rot_y += event.relative.y * LOOK_SPEED
		
		if rot_y > max_rot_y:
			rot_y = max_rot_y
		if rot_y < -max_rot_y:
			rot_y = -max_rot_y
		transform.basis = Basis()
		camera.transform.basis = Basis()
		rotate_object_local(Vector3(0,1,0), -rot_x)
		camera.rotate_object_local(Vector3(1,0,0), -rot_y)

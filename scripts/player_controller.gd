class_name Player
extends CharacterBody3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

@onready var camera = get_node("Camera")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)

@onready var input = $PlayerInput

func _ready():
	if player == multiplayer.get_unique_id():
		camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if input.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
	input.jumping = false
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		#screech.rpc()
	var direction = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if Input.is_action_just_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
	#var input_dir = Input.get_vector("strafe-left", "strafe-right", "forward", "backward")
	#
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = 0
		#velocity.z = 0
	transform.basis = Basis()
	camera.transform.basis = Basis()
	rotate_object_local(Vector3(0,1,0), -input.rot_x)
	camera.rotate_object_local(Vector3(1,0,0), -input.rot_y)
	move_and_slide()
		
@rpc("any_peer", "call_local", "reliable")
func screech():
	print("testing testing 123")

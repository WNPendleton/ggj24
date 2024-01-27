extends MultiplayerSynchronizer

@export var jumping := false
@export var direction := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	
@rpc("call_local")
func jump():
	jumping = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Input.get_vector("strafe-left", "strafe_right", "forward", "backward")
	if Input.is_action_just_pressed("jump"):
		jump.rpc()

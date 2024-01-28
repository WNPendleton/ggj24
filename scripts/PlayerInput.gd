extends MultiplayerSynchronizer

@export var jumping := false
@export var direction := Vector2()

@export var rot_x = 0
@export var rot_y = 0

const max_rot_y = PI/2
const LOOK_SPEED = 0.01

var effect
var recording

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)
	effect.set_recording_active(true)
	
func _on_send_recording_timer_timeout():
	recording = effect.get_recording()
	effect.set_recording_active(false)
	rpc("send_rec_data", recording.data)
	effect.set_recording_active(true)

@rpc("any_peer", "call_local", "reliable")	
func send_rec_data(rec_data):
	var sample = AudioStreamWAV.new()
	sample.data = rec_data
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = AudioServer.get_mix_rate() * 2
	$AudioStreamPlayer3D.stream = sample
	$AudioStreamPlayer3D.play()
	
@rpc("call_local")
func jump():
	jumping = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Input.get_vector("strafe-left", "strafe-right", "forward", "backward")
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
		
func _input(event):
	if event is InputEventMouseMotion:
		rot_x += event.relative.x * LOOK_SPEED
		rot_y += event.relative.y * LOOK_SPEED
		
		if rot_y > max_rot_y:
			rot_y = max_rot_y
		if rot_y < -max_rot_y:
			rot_y = -max_rot_y

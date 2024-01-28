extends MultiplayerSynchronizer

@export var jumping := false
@export var direction := Vector2()
#@onready var audioPlayer = get_parent().get_node("AudioStreamPlayer3D")

@export var rot_x = 0
@export var rot_y = 0

const max_rot_y = PI/2
const LOOK_SPEED = 0.01

#var effect
#var recording

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	#var idx = AudioServer.get_bus_index("Record")
	#effect = AudioServer.get_bus_effect(idx, 0)
	#effect.set_recording_active(true)

#@rpc("any_peer", "call_local", "reliable")
#func send_rec_data(rec):
	#var sample = AudioStream.new()
	#sample.data = rec_data
	#sample.format = AudioStreamWAV.FORMAT_16_BITS
	#sample.mix_rate = AudioServer.get_mix_rate() * 2
	#if audioPlayer:
		#audioPlayer.stream = rec
		#audioPlayer.play()
	
@rpc("call_local")
func jump():
	jumping = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Input.get_vector("strafe-left", "strafe-right", "forward", "backward")
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
	#ar rec = effect.get_recording()
	#if rec:
		#recording = rec
		#effect.set_recording_active(false)
		#rpc("send_rec_data", recording)
		#effect.set_recording_active(true)
		
func _input(event):
	if event is InputEventMouseMotion:
		rot_x += event.relative.x * LOOK_SPEED
		rot_y += event.relative.y * LOOK_SPEED
		
		if rot_y > max_rot_y:
			rot_y = max_rot_y
		if rot_y < -max_rot_y:
			rot_y = -max_rot_y
			
@rpc("any_peer", "call_local", "reliable")
func administer_test(hyena, testTimer):
	#if multiplayer.get_unique_id() == id:
	print("Administering test for " + str(testTimer) + " seconds")
	get_parent().get_node("ProcessPlayerLaugh")._ready()
	if Input.is_action_pressed("debug_fail"):
		hyena.complete_test.rpc(false)
	elif Input.is_action_pressed("debug_pass"):
		hyena.complete_test.rpc(true)

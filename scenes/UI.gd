extends Control
const PORT = 6968
const MAX_CLIENTS = 4

signal player_connected(peer_id)
signal player_disconnected(peer_id)

@export var IpAddrTextEdit : TextEdit
@export var StartGameButton : Button
@export var PlayerConnectedLabel : Label

var playersLoaded = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(onPlayerConnect)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(multiplayer.is_server) :
		pass
	pass
	
func beginHosting():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer
	
func connectClient():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(IpAddrTextEdit.text, PORT)
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer

func startGame():
	pass

func onPlayerConnect():
	playerConnected.rpc()
	
@rpc("any_peer", "call_local", "reliable")
func playerConnected():
	if(multiplayer.is_server):
		playersLoaded += 1
		PlayerConnectedLabel.text = "Players connected: " + str(playersLoaded)
	print("New player connected")
	

extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	if(ConnectionInfo.Host):
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(ConnectionInfo.PORT, ConnectionInfo.MAX_CLIENTS)
		if error:
			print(error)
		multiplayer.multiplayer_peer = peer
	else:
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_client(ConnectionInfo.IpAddress, ConnectionInfo.PORT)
		if error:
			print(error)
		multiplayer.multiplayer_peer = peer



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

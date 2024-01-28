extends Node

const SPAWN_RANDOM := 5.0
@export var CharacterPath : String
var readyCounter = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		signal_player_connected.rpc()
		return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_player(id: int):
	print("adding player" + str(id))
	var character = preload("res://prefabs/player_character.tscn").instantiate()
	character.player = id
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	character.name = str(id)
	$PlayerNode.add_child(character, true)

@rpc("any_peer")
func signal_player_connected():
	if multiplayer.is_server():
		readyCounter += 1
		if readyCounter == multiplayer.get_peers().size():
			for id in multiplayer.get_peers():
				add_player(id)

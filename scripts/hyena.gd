extends CharacterBody3D

const WALK_SPEED = 1.0
const WALK_ANIM_SPEED = 0.66
const APPROACH_SPEED = 3.0
const APPROACH_ANIM_SPEED = 1.0
const CHASE_SPEED = 9.0
const CHASE_ANIM_SPEED = 1.5
const CHASE_KILL_DIST = 2.0
const PLAYER_NOTICE_RANGE = 10.0
const PLAYER_TEST_RANGE = 3.0
const APPROACH_PATIENCE_TIME = 4.8
const TEST_RANGE_ALLOWED = 10.0

enum state {WANDER, SEEK_NOISE, APPROACH_PLAYER, TEST_PLAYER, LEAVE_PLAYER, KILL_PLAYER}
enum result {PENDING, PASS, FAIL}

var my_state = state.WANDER
var player_target: Player
var location_target: Vector3
var idle_time = 0.0
var time_in_approach = 0.0
var test_result
var test_timer = 5

@onready var anim: AnimationPlayer = $AnimationPlayer
@export var player_list: Array[Player]


func _ready():
	choose_wander_location()
	anim.play("run")


func _physics_process(delta):
	
	if Input.is_action_just_pressed("debug_pass"):
		pass_test()
	if Input.is_action_just_pressed("debug_fail"):
		fail_test()
	
	if my_state == state.KILL_PLAYER:
		var player_location = player_target.global_transform.origin
		var dir = global_transform.origin.direction_to(Vector3(player_location.x, global_transform.origin.y, player_location.z))
		velocity = dir * CHASE_SPEED
		look_at(player_target.global_transform.origin)
		var dist_to_player_target = global_transform.origin.distance_to(player_target.global_transform.origin)
		if dist_to_player_target <= CHASE_KILL_DIST:
			kill_player(player_target)
	elif my_state == state.TEST_PLAYER:
		var dist_to_player_target = global_transform.origin.distance_to(player_target.global_transform.origin)
		if dist_to_player_target > TEST_RANGE_ALLOWED:
			go_to_kill_state()
			print("no run from test. you die")
		if test_result == result.PASS:
			my_state = state.LEAVE_PLAYER
			var dir = player_target.global_transform.origin.direction_to(global_transform.origin)
			dir.y = 0
			dir = dir.rotated(Vector3(0,1,0), randf_range(-PI/4, PI/4))
			location_target = global_transform.origin + dir * 20
			print("you hyena. I leave you alone")
		if test_result == result.FAIL:
			go_to_kill_state()
			print("you not hyena. you die.")
	elif my_state == state.LEAVE_PLAYER:
		anim.play("run")
		anim.speed_scale = WALK_ANIM_SPEED
		var dir = global_transform.origin.direction_to(location_target)
		velocity = dir * WALK_SPEED
		anim.speed_scale = WALK_ANIM_SPEED
		var dist_to_target = global_transform.origin.distance_to(location_target)
		look_at(location_target)
		if dist_to_target <= 3.0:
			my_state = state.WANDER
	elif my_state == state.APPROACH_PLAYER:
		time_in_approach += delta
		anim.speed_scale = APPROACH_ANIM_SPEED
		var player_location = player_target.global_transform.origin
		var dir = global_transform.origin.direction_to(Vector3(player_location.x, global_transform.origin.y, player_location.z))
		velocity = dir * APPROACH_SPEED
		look_at(player_target.global_transform.origin)
		var dist_to_player_target = global_transform.origin.distance_to(player_target.global_transform.origin)
		if dist_to_player_target <= PLAYER_TEST_RANGE:
			velocity = Vector3.ZERO
			anim.stop()
			my_state = state.TEST_PLAYER
			test_player(player_target)
		if time_in_approach > APPROACH_PATIENCE_TIME:
			go_to_kill_state()
			print("impatient. you die now.")
	elif my_state == state.SEEK_NOISE:
		#move toward location that noise originated from
		#if dist_to_player < some_value:
		#my_state = state.APPROACH_PLAYER
		pass
	elif my_state == state.WANDER:
		anim.speed_scale = WALK_ANIM_SPEED
		idle_time -= delta
		if idle_time <= 0:
			anim.play("run")
			var dir = global_transform.origin.direction_to(location_target)
			velocity = dir * WALK_SPEED
			look_at(location_target)
		if global_transform.origin.distance_to(location_target) < 1.0:
			choose_wander_location()
			velocity = Vector3.ZERO
		for player in player_list:
			if global_transform.origin.distance_to(player.global_transform.origin) < PLAYER_NOTICE_RANGE:
				print("you stinky")
				player_target = player
				my_state = state.APPROACH_PLAYER
				time_in_approach = 0
	move_and_slide()

func choose_wander_location():
	var dir = Vector2.from_angle(randf_range(0, 2*PI)).normalized()
	var dist = randf_range(5, 20)
	location_target = global_transform.origin + Vector3(dir.x, 0, dir.y) * dist
	idle_time = randf_range(1, 10)
	anim.stop()

func go_to_kill_state():
	my_state = state.KILL_PLAYER
	anim.play("run")
	anim.speed_scale = CHASE_ANIM_SPEED

func kill_player(player):
	print("you dead")
	player.global_transform.origin = Vector3(randf_range(-45, 45), 2, randf_range(-45, 45))
	my_state = state.WANDER

func test_player(player):
	test_result = result.PENDING
	player.get_node("PlayerInput").administer_test.rpc_id(player.multiplayer.get_unique_id(), self, test_timer)

func fail_test():
	test_result = result.FAIL

func pass_test():
	test_result = result.PASS
	
@rpc("any_peer", "call_local", "reliable")
func complete_test(result):
	if multiplayer.is_server():
		if result:
			test_result = result.PASS
		else:
			test_result = result.FAIL

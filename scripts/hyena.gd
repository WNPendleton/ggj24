extends CharacterBody3D

const WALK_SPEED = 1.0
const APPROACH_SPEED = 2.0
const CHASE_SPEED = 4.0
const PLAYER_NOTICE_RANGE = 10.0
const PLAYER_TEST_RANGE = 5.0
const APPROACH_PATIENCE_TIME = 4.8

enum state {WANDER, SEEK_NOISE, APPROACH_PLAYER, TEST_PLAYER, LEAVE_PLAYER, KILL_PLAYER}

var my_state = state.WANDER
var player_target: Player
var location_target: Vector3
var idle_time = 0.0
var time_in_approach = 0.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@export var player_list: Array[Player]


func _ready():
	choose_wander_location()
	anim.play("run")


func _physics_process(delta):
	
	if my_state == state.KILL_PLAYER:
		#if player is not yet dead
		my_state = state.KILL_PLAYER
		#else my_state = state.WANDER
	elif my_state == state.TEST_PLAYER:
		#wait for test results
		#if test_passed:
		#my_state = state.LEAVE_PLAYER
		#else:
		#my_state = state.KILL_PLAYER
		pass
	elif my_state == state.LEAVE_PLAYER:
		#move away from the location of the last test
		#if time_since_test > some_value:
		#my_state = state.WANDER
		pass
	elif my_state == state.APPROACH_PLAYER:
		var dist_to_player_target = global_transform.origin.distance_to(player_target.global_transform.origin)
		if dist_to_player_target <= PLAYER_TEST_RANGE:
			my_state = state.TEST_PLAYER
		if time_in_approach > APPROACH_PATIENCE_TIME:
			my_state = state.KILL_PLAYER
	elif my_state == state.SEEK_NOISE:
		#move toward location that noise originated from
		#if dist_to_player < some_value:
		#my_state = state.APPROACH_PLAYER
		pass
	elif my_state == state.WANDER:
		anim.speed_scale = 0.66
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

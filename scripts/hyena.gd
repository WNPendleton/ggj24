extends Node3D

enum state {WANDER, SEEK_NOISE, APPROACH_PLAYER, TEST_PLAYER, LEAVE_PLAYER, KILL_PLAYER}

var my_state = state.WANDER
var target: Player

@onready var anim: AnimationPlayer = $AnimationPlayer


func _process(delta):
	
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
		#move toward player
		#if dist_to_player < some_dist:
		#my_state = state.TEST_PLAYER
		#if time_in_approach > some_value:
		#my_state = state.KILL_PLAYER
		pass
	elif my_state == state.SEEK_NOISE:
		#move toward location that noise originated from
		#if dist_to_player < some_value:
		#my_state = state.APPROACH_PLAYER
		pass
	elif my_state == state.WANDER:
		anim.play("run")

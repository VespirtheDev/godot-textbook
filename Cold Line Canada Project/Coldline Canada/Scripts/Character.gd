extends KinematicBody2D

enum {IDLE, RUN, ATTACK, ROLL, HURT, DEAD}
var state = IDLE

var immortal = false

export (float) var movespeed
var velocity = Vector2()

export (int) var max_health = 100
var health = max_health

var direction = "down"
var attack_ready = true
var next_anim = "Idle"

func anim_process():
	if $CharAnim.has_animation(next_anim):
		if $CharAnim.current_animation != next_anim:
			$CharAnim.play(next_anim)
			next_anim = ""

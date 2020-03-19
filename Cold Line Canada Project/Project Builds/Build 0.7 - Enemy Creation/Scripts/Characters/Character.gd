extends KinematicBody2D

#These are the state ENUMS so we'll teach the reader about two ways to hold states in this book
enum {IDLE, RUN, ATTACK, ROLL, HURT, DEAD}

var state = IDLE #The current state of the character
var next_anim = "Idle" #The next animation the character will play

export (float) var move_speed #How fast the character can move
var velocity = Vector2() #The velocity of the character

export (int) var health_max = 100 #This is the max amount of character health
onready var health = health_max #This is the character's current health

#This function handles updating the animations
func animation_update():
	if $CharAnim.has_animation(next_anim):
		if $CharAnim.current_animation != next_anim:
			$CharAnim.play(next_anim)
			next_anim = ""



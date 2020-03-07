extends Area2D

var target_tags = []
var speed = 400
var damage
var velocity = Vector2()
var direction

export (Dictionary) var textures = {"rifle": Texture, "assault_rifle": Texture, "shotgun": Texture}

func setup(_damage, _speed, _direction, _targets, _type):
	#The process is turned off because the projectile
	#isn't ready to move yet
	set_process(false)
	
	#Set the stats to the parameters sent in
	damage = _damage
	speed = _speed
	direction = _direction
	target_tags = _targets
	$Sprite.texture = textures[_type]
	
	#Turn on process now that the projectile
	#is ready to move
	set_process(true)

func _process(delta):
	#The velocity is initialized
	var velocity = Vector2(speed, 0) * delta
	
	#The position of the projectile is increased
	#By the velocity that's being rotated
	#by the direction variable
	rotation = direction
	position += velocity.rotated(direction) 

#This will run when a body is hit
func body_hit(body):
	var can_hit = false #This will determine if the body gets damaged
	
	#The code runs through each group in target_tags
	for group in target_tags:
		if body.is_in_group(group): #If the body is in the group
			can_hit = true #Then it can be hit
			break #Then we break since we already have our answer
	
	#If the body can't be hit then leave then function
	if not can_hit:
		return
	
	#If the code gets this far then the body can be hit
	#So we use the take_damage function and give it 
	#the damage parameter
	body.take_damage(damage)



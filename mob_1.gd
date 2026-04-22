extends CharacterBody2D

var health = 100
var knockback_velocity = Vector2.ZERO
const MOVE_SPEED = 300.0
const KNOCKBACK_DECAY = 1800.0

#var player

#func _ready():
	#player = get_node("/root/Game/Player")
	
@onready var player = get_node("/root/Game/Player") 
	# ^ shorthand of above, AKA wait til everything done then do this.
	
func _ready():
	%Slime.play_walk()

func _physics_process(delta):
	var direction  = global_position.direction_to(player.global_position)
	var chase_velocity = direction * MOVE_SPEED
	velocity = chase_velocity + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()

func take_damage(hit_direction: Vector2 = Vector2.ZERO, force: float = 500.0):
	health = health-30
	%Slime.play_hurt()
	if hit_direction != Vector2.ZERO:
		knockback_velocity += hit_direction.normalized() * force
	
	if health < 0:
		queue_free()
		
		const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke) #just adding child would make it delete whenmob is killed, but this
		#makes a sibling rather than child and spawns the smoke right on death
		smoke.global_position = global_position
		

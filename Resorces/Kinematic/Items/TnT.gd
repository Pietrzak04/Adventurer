extends RigidBody2D

onready var sprite = $Sprite
onready var exposion = $Sprite2
onready var kill = $KillTimer
onready var particles = $Particles2D

var force_vector = Vector2(60,-100)

func _ready():
	sprite.visible = true
	exposion.visible = false
	particles.visible = true
	var throw_vector = calculate_throw(force_vector, get_node("../Player").get_floor_velocity(), get_node("../Player/AnimatedSprite").scale.x)
	apply_impulse(Vector2.ZERO, throw_vector)

func _physics_process(_delta: float):
	particles.rotation = linear_velocity.angle() + 20 

## Documentation for a method.
#  @param input Example input.
func calculate_throw(force: Vector2, player: Vector2, scale: float):
	var out = force
	
	out.y = force.y + player.y
	
	if (scale > 0 and player.x > 0) or (scale < 0 and player.x < 0):
		out.x = force.x * scale + player.x
	else:
		out.x = force.x * scale
		
	return out

func _on_OnFloor_body_entered(_body: Node):
	particles.visible = false
	sprite.visible = false
	exposion.visible = true
	sleeping = true
	kill.start(0.3)

func _on_KillTimer_timeout():
	queue_free()

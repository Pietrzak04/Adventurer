extends RigidBody2D

onready var sprite = $Sprite
onready var exposion = $Sprite2
onready var kill = $KillTimer
onready var particles = $Particles2D

var force_vector = Vector2(40,-100)

func _ready():
	sprite.visible = true
	exposion.visible = false
	particles.visible = true
	var throw_vector = calculate_throw(force_vector, get_node("../Player").get_floor_velocity())
	print("throw_vector", throw_vector)
	apply_impulse(Vector2.ZERO, throw_vector)

func _physics_process(_delta: float):
	particles.rotation = linear_velocity.angle() + 20 

func calculate_throw(force: Vector2, player: Vector2):
	var out: Vector2
	
	var scale = get_node("../Player/AnimatedSprite").scale.x
	
	print(force," ", player)
	out.y = force.y + player.y
	out.x = force.x
	return out

func _on_OnFloor_body_entered(_body: Node):
	particles.visible = false
	sprite.visible = false
	exposion.visible = true
	sleeping = true
	kill.start(0.3)

func _on_KillTimer_timeout():
	queue_free()

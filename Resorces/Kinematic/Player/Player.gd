extends Kinematic

class_name Player

onready var ground = $Ground
onready var sprite = $AnimatedSprite
onready var state_machine = $AnimationTree.get("parameters/playback")
onready var animation_tree = $AnimationTree
onready var animation_player = $AnimationPlayer
onready var head_cast = $HeadCast
onready var body_cast = $BodyCast

const FLOOR_DETECT_DISTANCE = 5.0

export (Vector2) var anim_pos = Vector2.ZERO
var move_on = true
var current_anim = ""

var on_ground = true
var jump_count = 0
export var double_jump = false
var is_climbing = false

func animation(var animation_name):
	move_on = false
	current_anim = animation_name

func stop_animation():
	move_on = true

func _ready() -> void:
	pass

func _physics_process(_delta):
	var direction = get_direction()
	set_direction(direction)
	set_animation(direction)
	
	if move_on:
		var is_jump_interrupted = Input.is_action_just_released("Jump") and _velocity.y < 0.0
		var is_on_platform = ground.is_colliding()
		
		if Input.is_action_pressed("test_button"):
			animation_player.play("corner_climb_0")
		
		var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y > 0.0 else Vector2.ZERO
		
		_velocity = calculate_move_velocity(_velocity, speed, direction, is_jump_interrupted)
		_velocity = move_and_slide_with_snap(_velocity, snap_vector, FLOOR_NORMAL, !is_on_platform, 4, 0.9)
	else:
		match current_anim:
			"climb":
				self.global_position += anim_pos * Vector2(sprite.scale.x, 1.0)

func get_direction():
	return Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		-1 if Input.is_action_just_pressed("Jump") else 0
	)

func calculate_move_velocity(linear_velocity: Vector2, speed: Vector2, direction: Vector2, is_jump_interrupted: bool):
	var out: = linear_velocity
	
	if direction.x != 0:
		out.x = lerp(out.x, direction.x * speed.x, acceleration)
	else:
		out.x = lerp(out.x, 0, friction)
	
	head_cast.force_raycast_update()
	body_cast.force_raycast_update()
	if body_cast.is_colliding() and !head_cast.is_colliding():
		is_climbing = true
		jump_count = 1
		out.y = 0
	else:
		is_climbing = false
		out.y += gravity * get_physics_process_delta_time()
	
	if direction.y == -1.0 and !is_climbing:
		if jump_count < 2:
			jump_count += 1
			on_ground = false
			out.y = speed.y * direction.y
	
	if is_jump_interrupted:
		out.y *= 0.6
	
	if is_on_floor():
		if on_ground == false:
			double_jump = false
			on_ground = true
			jump_count = 0
	else:
		if on_ground == true:
			on_ground = false
			jump_count = 1
	
	if is_on_ceiling():
		jump_count = 1
	
	return out

func set_animation(direction: Vector2):
	animation_tree.set("parameters/conditions/is_on_ground", is_on_floor())
	animation_tree.set("parameters/conditions/second_jump", jump_count == 2 && !double_jump)
	animation_tree.set("parameters/corner_climb_0/TimeScale/scale", 2.0)
	if is_on_floor():
		if direction.x == 0:
			state_machine.travel("idle_0")
		else:
			state_machine.travel("run_0")
	else:
		if !is_climbing:
			if direction.y == -1:
				state_machine.travel("jump_loop_0")
			else:
				state_machine.travel("fall_0")
		else:
			state_machine.travel("corner_grab_0")
			if direction.y == -1:
				state_machine.travel("corner_climb_0")

func set_direction(direction: Vector2):
	if direction.x != 0:
		sprite.scale.x = 1 if direction.x > 0 else -1
		head_cast.scale.x = 1 if direction.x > 0 else -1
		body_cast.scale.x = 1 if direction.x > 0 else -1
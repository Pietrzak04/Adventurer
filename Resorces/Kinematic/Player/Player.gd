extends Kinematic

class_name Player

onready var ground = $Ground
onready var sprite = $AnimatedSprite
onready var state_machine = $AnimationTree.get("parameters/playback")
onready var animation_tree = $AnimationTree
onready var animation_player = $AnimationPlayer
onready var head_cast = $HeadCast
onready var body_cast = $BodyCast
onready var camera = $Camera2D
onready var sword_hide = $SwordHide
onready var attack_reset = $AttackReset
onready var attack_next = $AttackNext
onready var attack_area = $AttackArea

const FLOOR_DETECT_DISTANCE = 5.0

export (Vector2) var anim_pos = Vector2.ZERO
var move_on = true

var armed = false
var attack_points = 3

var on_wall = false

var on_ground = true
var jump_count = 0
export var double_jump = false
var is_climbing = false

func animation(var animation_name):
	move_on = false
	match animation_name:
		"sword_up":
			sword_hide.start(4)

func stop_animation():
	move_on = true
	
func _ready() -> void:
	pass

func input():
	if Input.is_action_just_pressed("Attack"):
		armed = true

func _physics_process(_delta):
	var direction = get_direction()
	set_direction(direction)
	set_animation(direction)
	input()
	
	if move_on:
		var is_jump_interrupted = Input.is_action_just_released("Jump") and _velocity.y < 0.0
		var is_on_platform = ground.is_colliding()
		
		var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y > 0.0 else Vector2.ZERO
		
		_velocity = calculate_move_velocity(_velocity, speed, direction, is_jump_interrupted)
		_velocity = move_and_slide_with_snap(_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4,  0.9, false)
	else:
		_velocity = anim_pos * Vector2(sprite.scale.x, 1.0)
		_velocity = move_and_slide_with_snap(_velocity,Vector2.DOWN * FLOOR_DETECT_DISTANCE, FLOOR_NORMAL)

func get_direction():
	return Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		-1 if Input.is_action_just_pressed("Jump") else 0)

func calculate_move_velocity(linear_velocity: Vector2, speed: Vector2, direction: Vector2, is_jump_interrupted: bool):
	var out: = linear_velocity
	
	if direction.x != 0:
		out.x = lerp(out.x, direction.x * speed.x, acceleration)
	else:
		out.x = lerp(out.x, 0, friction)
	
	if head_cast.enabled or body_cast.enabled:
		head_cast.force_raycast_update()
		body_cast.force_raycast_update()
	
	is_climbing = body_cast.is_colliding() and !head_cast.is_colliding()
	if is_climbing:
		if Input.is_action_pressed("Crouch"):
			head_cast.enabled = false
			body_cast.enabled = false
		jump_count = 1
		out.y = 0
	else:
		out.y += gravity * get_physics_process_delta_time()
	
	if direction.y == -1.0 and !is_climbing:
		if jump_count < 2:
			jump_count += 1
			on_ground = false
			out.y = speed.y * direction.y
	
	if is_jump_interrupted:
		out.y *= 0.6
	
	if is_on_floor():
		head_cast.enabled = true
		body_cast.enabled = true
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
		if armed:
			if Input.is_action_just_pressed("Attack") and state_machine.get_current_node() != "sword_up_0":
				match attack_points:
					1:
						if attack_next.is_stopped() and state_machine.get_current_node() == "attack_1":
							sword_hide.start(4)
							attack_reset.start(0.8)
							attack_points -= 1
							attack_next.start(0.4)
							state_machine.travel("attack_2")
					2:
						if attack_next.is_stopped() and state_machine.get_current_node() == "attack_0":
							sword_hide.start(4)
							attack_reset.start(0.8)
							attack_points -= 1
							attack_next.start(0.4)
							state_machine.travel("attack_1")
					3:
						sword_hide.start(4)
						attack_reset.start(0.8)
						attack_next.start(0.4)
						attack_points = attack_points - 1
						state_machine.travel("attack_0")
			
			elif direction.x == 0 or is_on_wall():
				state_machine.travel("idle_1")
			else:
				sword_hide.start(4)
				state_machine.travel("run_1")
		else:
			if direction.x == 0 or is_on_wall():
				state_machine.travel("idle_0")
			else:
				state_machine.travel("run_0")
	else:
		armed = false
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
		camera.position.x = 35 if direction.x > 0 else -35
		attack_area.scale.x = 1 if direction.x  > 0 else -1

func _on_SwordHide_timeout() -> void:
	if armed:
		state_machine.travel("idle_0")
		armed = false

func _on_AttackReset_timeout() -> void:
	if state_machine.get_current_node() != "attack_0" or state_machine.get_current_node() != "attack_1" or state_machine.get_current_node() != "attack_2":
		attack_points = 3

func _on_AttackArea_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.hurt()

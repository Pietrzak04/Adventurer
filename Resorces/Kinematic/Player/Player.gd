extends Kinematic

class_name Player

onready var ground = $Ground
onready var ground2 = $Ground2
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
onready var cooldown = $ItemCooldown

onready var item_position = $ItemPosition

signal health_changed(value)
signal in_hand_changed(value)
signal score_changed(value)
signal life_changed(value)

var pre_item_array = [preload("res://Resorces/Kinematic/Items/TnT.tscn"),preload("res://Resorces/Kinematic/Items/FireBall.tscn"),null,null,null,null,null,null]
var item_array = [10,10,10,10,10,10,10,10]
var item_animation_name = ["throw_0", "spell_1"]

const FLOOR_DETECT_DISTANCE = 10.0

export (Vector2) var anim_pos = Vector2.ZERO
var move_on = true

var armed = false
var attack_points = 3

# czy gracz ma coś w ręce (łuk lub czar)
var in_hand = true #ręka false łuk
var CurrentArrow = 0
var CurrentHand = 0

var max_health = 100
var health = max_health
var lifes = 5
var score = 0

var celling = false;
var crouch_speed = 50
var on_ground = true
var jump_count = 0
var double_jump = false
var is_climbing = false

func _ready():
	emit_signal("health_changed", health)
	emit_signal("in_hand_changed", in_hand)
	emit_signal("score_changed", score)
	emit_signal("life_changed", lifes)

func animation(var animation_name):
	move_on = false
	match animation_name:
		"sword_up":
			sword_hide.start(4)

func make_item_instant(var item_number):
	var item_instance = pre_item_array[item_number].instance()
	item_instance.position = item_position.global_position
	get_parent().add_child(item_instance)

func new_instance():
	if in_hand:
		item_position.position = set_item_position(item_animation_name[CurrentHand])
		make_item_instant(CurrentHand)
		item_array[CurrentHand] -= 1
		cooldown.start(0.5)
	else:
		state_machine.travel(item_animation_name[CurrentArrow + 4])
		item_position.position = set_item_position(item_animation_name[CurrentArrow])
		make_item_instant(CurrentArrow + 4)
		item_array[CurrentArrow + 4] -= 1
		cooldown.start(0.5)

func set_item_position(var anim_name):
	var new_position = item_position.position
	
	match anim_name:
		"throw_0":
			new_position = Vector2(10 * sprite.scale.x,-11)
		"spell_1":
			new_position = Vector2(15 * sprite.scale.x,-15)
	
	return new_position

func stop_animation():
	move_on = true

func input():
	if Input.is_action_pressed("test_button"):
		score += 100000
		emit_signal("score_changed", score)
	if Input.is_action_just_pressed("Attack") and !celling:
		armed = true
	if Input.is_action_just_pressed("Crouch"):
		armed = false
	if in_hand:
		if Input.is_action_just_pressed("slot1"):
			CurrentHand = 0
		elif Input.is_action_just_pressed("slot2"):
			CurrentHand = 1
		elif Input.is_action_just_pressed("slot3"):
			CurrentHand = 2
		elif Input.is_action_just_pressed("slot4"):
			CurrentHand = 3
	else:
		if Input.is_action_just_pressed("slot1"):
			CurrentArrow = 0
		elif Input.is_action_just_pressed("slot2"):
			CurrentArrow = 1
		elif Input.is_action_just_pressed("slot3"):
			CurrentArrow = 2
		elif Input.is_action_just_pressed("slot4"):
			CurrentArrow = 3
	if Input.is_action_just_pressed("In_hand"):
		in_hand = !in_hand
		emit_signal("in_hand_changed", in_hand)

func _physics_process(_delta):
	var direction = get_direction()
	set_animation(direction, _velocity)
	set_direction(direction)
	input()
	if move_on:
		var is_jump_interrupted = Input.is_action_just_released("Jump") and _velocity.y < 0.0
		var is_on_platform = ground.is_colliding() or ground2.is_colliding()
		
		var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y == 0.0 else Vector2.ZERO
		if is_climbing:
			snap_vector = Vector2.ZERO
		
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
		if Input.is_action_pressed("Crouch") or celling:
			out.x = lerp(out.x, direction.x * crouch_speed, acceleration)
		else:
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
		if (Input.is_action_pressed("Crouch") or celling):
			head_cast.enabled = false
			body_cast.enabled = false
		else:
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
		jump_count = 2
	
	return out

func set_animation(direction: Vector2, vel: Vector2):
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
						attack_points -= 1
						sword_hide.start(4)
						attack_reset.start(0.8)
						attack_next.start(0.4)
						state_machine.travel("attack_0")
			
			elif direction.x == 0 or is_on_wall():
				state_machine.travel("idle_1")
			else:
				sword_hide.start(4)
				state_machine.travel("run_1")
		else:
			if Input.is_action_pressed("Crouch") or celling:
				if direction.x == 0 or is_on_wall():
					state_machine.travel("crouch_idle_0")
				else:
					state_machine.travel("crouch_walk_0")
			else:
				if direction.x == 0 or is_on_wall():
					state_machine.travel("idle_0")
				else:
					state_machine.travel("run_0")
			if Input.is_action_just_pressed("Attack_range") and cooldown.is_stopped():
				if in_hand:
					if item_array[CurrentHand] > 0:
						state_machine.travel(item_animation_name[CurrentHand])
				else:
					if item_array[CurrentArrow + 4] > 0:
						state_machine.travel(item_animation_name[CurrentArrow + 4])
	else:
		armed = false
		if !is_climbing:
			if vel.y < 0 and jump_count < 2:
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
		head_cast.position.x = -2 if direction.x > 0 else 2
		body_cast.position.x = -2 if direction.x > 0 else 2
		camera.position.x = 35 if direction.x > 0 else -35
		attack_area.scale.x = 1 if direction.x  > 0 else -1

func hit(damage: int):
	pass

func kill():
	
	pass

func add_score(var new_score):
	score += new_score
	emit_signal("score_changed", score)

func _on_SwordHide_timeout():
	if armed:
		state_machine.travel("idle_0")
		armed = false

func _on_AttackReset_timeout():
	if state_machine.get_current_node() != "attack_0" or state_machine.get_current_node() != "attack_1" or state_machine.get_current_node() != "attack_2":
		attack_points = 3

func _on_AttackArea_body_entered(body: Node):
	if body.is_in_group("enemies"):
		body.hurt()

func _on_CellingArea_body_entered(body: Node):
	if body is TileMap:
		celling = true

func _on_CellingArea_body_exited(body: Node):
	if body is TileMap:
		celling = false

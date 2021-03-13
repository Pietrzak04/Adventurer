extends Node2D

onready var sprite = $Sprite
onready var colect_area = $ColectArea
onready var animation = $AnimationPlayer
onready var spawn_pos = $ParticlesSpawn

export var score = 100

var pre_particles_array = [preload("res://Resorces/Static/Items/Gems/Particles/ParticlesYellow.tscn"),preload("res://Resorces/Static/Items/Gems/Particles/ParticlesRed.tscn"),preload("res://Resorces/Static/Items/Gems/Particles/ParticlesGreen.tscn"),preload("res://Resorces/Static/Items/Gems/Particles/ParticlesBlue.tscn")]
export(int, "Yellow", "Red", "Green", "Blue") var color

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	animation.seek(rng.randf_range(0.0, 1.4))

func collected():
	
	var item_instance = pre_particles_array[color].instance()
	item_instance.get_node("Node2D").position = self.get_global_transform_with_canvas().origin
	item_instance.get_node("Node2D/Sprite").region_rect = sprite.region_rect
	get_parent().add_child(item_instance)
	queue_free()

func _on_ColectArea_body_entered(body: Node):
	if body is Player:
		body.add_score(score)
		collected()

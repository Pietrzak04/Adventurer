extends Control

onready var texture_hand = $HPBar/TextureHand
onready var texture_bow = $HPBar/TextureBow
onready var health_bar = $HPBar/TextureProgress

func _ready():
	var player_max_health = $"../..".max_health
	health_bar.max_value = player_max_health


func _on_Player_health_changed(value):
	health_bar.value = value


func _on_Player_in_hand_changed(value) -> void:
	texture_bow.visible = value
	texture_hand.visible = !value

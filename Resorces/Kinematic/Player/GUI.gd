extends Control

onready var texture_hand = $HPBar/TextureHand
onready var texture_bow = $HPBar/TextureBow
onready var health_bar = $HPBar/TextureProgress
onready var score_bar = $ScoreBar/TextureRect/ScoreLabel

func _ready():
	var player_max_health = $"../..".max_health
	health_bar.max_value = player_max_health

func _on_Player_health_changed(value):
	health_bar.value = value

func _on_Player_in_hand_changed(value):
	texture_bow.visible = !value
	texture_hand.visible = value

func _on_Player_life_changed(value):
	pass # Replace with function body.

func _on_Player_score_changed(value):
	score_bar.set_text(text_score(String(value), 8))

func text_score(var in_score, var max_value):
	var zeros_to_add = max_value - in_score.length()
	
	for i in zeros_to_add:
		in_score = in_score.insert(0, "0")
	
	return in_score

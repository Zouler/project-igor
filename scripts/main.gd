extends Node

func _ready() -> void:
	print("Proyecto I.G.O.R. iniciado")
	call_deferred("_go_to_workshop")

func _go_to_workshop() -> void:
	get_tree().change_scene_to_file("res://scenes/workshop.tscn")
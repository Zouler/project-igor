extends Node

const DEBUG_LOGS := false

func _ready() -> void:
	if DEBUG_LOGS:
		print("Proyecto I.G.O.R. iniciado")
	call_deferred("_go_to_start_screen")

func _go_to_start_screen() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
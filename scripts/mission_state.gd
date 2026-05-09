extends Node

## Estado global de la misión actual (MVP 0.9; sin guardado ni progresión compleja).

var current_mission_id: String = "clear_first_path"
var current_mission_title: String = "Despejar el primer camino"
var current_mission_description: String = "Construí una máquina con pala para mover las piedras."

var mission_started: bool = false
var machine_built: bool = false
var test_completed: bool = false
var community_unlocked: bool = false


func start_first_mission() -> void:
	current_mission_id = "clear_first_path"
	current_mission_title = "Despejar el primer camino"
	current_mission_description = "Construí una máquina con pala para mover las piedras."
	mission_started = true
	print("Mission started")


func mark_machine_built() -> void:
	machine_built = true


func mark_test_completed() -> void:
	test_completed = true


func mark_community_unlocked() -> void:
	community_unlocked = true


func reset_mission() -> void:
	mission_started = false
	machine_built = false
	test_completed = false
	community_unlocked = false


func get_progress_text() -> String:
	if mission_started and not machine_built:
		return "Paso 1: Construí una máquina."
	if machine_built and not test_completed:
		return "Paso 2: Probá la máquina."
	if test_completed and not community_unlocked:
		return "Paso 3: Mirá cómo mejora el planeta."
	if community_unlocked:
		return "Primera misión completada."
	return ""


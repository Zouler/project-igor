extends Node

## Estado global de la misión actual (MVP 0.9; sin guardado ni progresión compleja).

const DEBUG_LOGS := false

const LocalizationScript := preload("res://scripts/localization.gd")

var current_mission_id: String = "clear_first_path"
var current_mission_title_key: String = "MISSION_1_TITLE"
var current_mission_description_key: String = "MISSION_1_DESCRIPTION"
var current_mission_title: String = ""
var current_mission_description: String = ""

var mission_started: bool = false
var machine_built: bool = false
var test_completed: bool = false
var community_unlocked: bool = false


func _t(key: String) -> String:
	var loc := get_node_or_null("/root/Localization") as LocalizationScript
	if loc == null:
		return key
	return loc.t(key)


func start_first_mission() -> void:
	current_mission_id = "clear_first_path"
	current_mission_title_key = "MISSION_1_TITLE"
	current_mission_description_key = "MISSION_1_DESCRIPTION"
	current_mission_title = _t(current_mission_title_key)
	current_mission_description = _t(current_mission_description_key)
	mission_started = true
	if DEBUG_LOGS:
		print("Mission started")


func select_first_mission() -> void:
	if not mission_started:
		start_first_mission()
	else:
		current_mission_id = "clear_first_path"
		current_mission_title_key = "MISSION_1_TITLE"
		current_mission_description_key = "MISSION_1_DESCRIPTION"
		current_mission_title = _t(current_mission_title_key)
		current_mission_description = _t(current_mission_description_key)
	_save_progress()


func mark_machine_built() -> void:
	machine_built = true
	_save_progress()


func mark_test_completed() -> void:
	test_completed = true
	_save_progress()


func mark_community_unlocked() -> void:
	community_unlocked = true
	_save_progress()


func _save_progress() -> void:
	if Engine.has_singleton("SaveManager"):
		var sm := Engine.get_singleton("SaveManager")
		if sm != null and sm.has_method("save_game"):
			sm.call("save_game")


func reset_mission() -> void:
	mission_started = false
	machine_built = false
	test_completed = false
	community_unlocked = false


func is_second_mission_unlocked() -> bool:
	return community_unlocked


func get_progress_text() -> String:
	if mission_started and not machine_built:
		return _t("MISSION_STEP_BUILD")
	if machine_built and not test_completed:
		return _t("MISSION_STEP_TEST")
	if test_completed and not community_unlocked:
		return _t("MISSION_STEP_COMMUNITY")
	if community_unlocked:
		return _t("MISSION_COMPLETED_FIRST")
	return ""


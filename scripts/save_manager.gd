extends Node

## Guardado local simple (MVP 1.8).
## No hay slots ni cuentas; solo un config en user://.

const DEBUG_LOGS := false
const SAVE_PATH := "user://igor_demo_save.cfg"

var _is_loading: bool = false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	if _is_loading:
		return

	var cfg := ConfigFile.new()
	# Locale
	var locale := "en"
	var loc := get_node_or_null("/root/Localization") as Node
	if loc != null and loc.has_method("get_locale"):
		locale = str(loc.call("get_locale"))
	cfg.set_value("settings", "locale", locale)

	# Mission progress
	var ms := get_node_or_null("/root/MissionState") as Node
	if ms != null:
		cfg.set_value("mission", "mission_started", bool(ms.get("mission_started")))
		cfg.set_value("mission", "machine_built", bool(ms.get("machine_built")))
		cfg.set_value("mission", "test_completed", bool(ms.get("test_completed")))
		cfg.set_value("mission", "community_unlocked", bool(ms.get("community_unlocked")))
		cfg.set_value("mission", "mission_2_completed", bool(ms.get("mission_2_completed")))
		cfg.set_value("mission", "current_mission_id", str(ms.get("current_mission_id")))

	var err := cfg.save(SAVE_PATH)
	if DEBUG_LOGS:
		print("SaveManager save: ", SAVE_PATH, " err=", err)


func load_game() -> void:
	if not has_save():
		return
	_is_loading = true
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_is_loading = false
		return

	# Apply locale
	var locale: String = str(cfg.get_value("settings", "locale", "en"))
	var loc := get_node_or_null("/root/Localization") as Node
	if loc != null and loc.has_method("set_locale"):
		loc.call("set_locale", locale)

	# Apply mission state fields
	var ms := get_node_or_null("/root/MissionState") as Node
	if ms != null:
		ms.set("mission_started", bool(cfg.get_value("mission", "mission_started", false)))
		ms.set("machine_built", bool(cfg.get_value("mission", "machine_built", false)))
		ms.set("test_completed", bool(cfg.get_value("mission", "test_completed", false)))
		ms.set("community_unlocked", bool(cfg.get_value("mission", "community_unlocked", false)))
		ms.set("mission_2_completed", bool(cfg.get_value("mission", "mission_2_completed", false)))
		var mid: String = str(cfg.get_value("mission", "current_mission_id", "clear_first_path"))
		if mid == "carry_first_blocks" or mid == "clear_first_path":
			ms.set("current_mission_id", mid)
		if ms.has_method("refresh_localized_titles"):
			ms.call("refresh_localized_titles")

	_is_loading = false

	if DEBUG_LOGS:
		print("SaveManager loaded: locale=", locale)


func reset_save() -> void:
	# Borra el archivo; no toca el locale actual por defecto.
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if DEBUG_LOGS:
		print("SaveManager reset_save")


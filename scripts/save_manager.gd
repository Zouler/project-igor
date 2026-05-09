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
	if Engine.has_singleton("Localization"):
		var loc := Engine.get_singleton("Localization")
		if loc != null and loc.has_method("get_locale"):
			locale = str(loc.call("get_locale"))
	cfg.set_value("settings", "locale", locale)

	# Mission progress
	if Engine.has_singleton("MissionState"):
		var ms := Engine.get_singleton("MissionState")
		if ms != null:
			cfg.set_value("mission", "mission_started", bool(ms.get("mission_started")))
			cfg.set_value("mission", "machine_built", bool(ms.get("machine_built")))
			cfg.set_value("mission", "test_completed", bool(ms.get("test_completed")))
			cfg.set_value("mission", "community_unlocked", bool(ms.get("community_unlocked")))

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
	if Engine.has_singleton("Localization"):
		var loc := Engine.get_singleton("Localization")
		if loc != null and loc.has_method("set_locale"):
			loc.call("set_locale", locale)

	# Apply mission state fields
	if Engine.has_singleton("MissionState"):
		var ms := Engine.get_singleton("MissionState")
		if ms != null:
			ms.set("mission_started", bool(cfg.get_value("mission", "mission_started", false)))
			ms.set("machine_built", bool(cfg.get_value("mission", "machine_built", false)))
			ms.set("test_completed", bool(cfg.get_value("mission", "test_completed", false)))
			ms.set("community_unlocked", bool(cfg.get_value("mission", "community_unlocked", false)))

	_is_loading = false

	if DEBUG_LOGS:
		print("SaveManager loaded: locale=", locale)


func reset_save() -> void:
	# Borra el archivo; no toca el locale actual por defecto.
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if DEBUG_LOGS:
		print("SaveManager reset_save")


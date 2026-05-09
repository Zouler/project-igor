extends Node3D

## Pantalla de inicio (MVP 1.0): título + botones + preview simple.

const BuildStateScript := preload("res://scripts/build_state.gd")
const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")
const SaveManagerScript := preload("res://scripts/save_manager.gd")
const UIStyle := preload("res://scripts/ui_style_helper.gd")

const DEBUG_LOGS := false

@onready var _title_label: Label = $CanvasLayer/UI/TitleLabel
@onready var _subtitle_label: Label = $CanvasLayer/UI/SubtitleLabel
@onready var _footer_label: Label = %SmallFooterLabel
@onready var _start_button: Button = %StartButton
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _language_label: Label = %LanguageLabel
@onready var _lang_en_button: Button = %LanguageEnglishButton
@onready var _lang_es_button: Button = %LanguageSpanishButton
@onready var _reset_button: Button = %ResetDemoButton
@onready var _close_settings_button: Button = %CloseSettingsButton
@onready var _settings_panel: Panel = $CanvasLayer/UI/SettingsPanel
@onready var _settings_title_label: Label = %SettingsTitleLabel

var _build_state: BuildStateScript
var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var _save_manager: SaveManagerScript
var demo_was_reset: bool = false


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_save_manager = get_node("/root/SaveManager") as SaveManagerScript
	_setup_camera()
	_save_manager.load_game()
	_loc.locale_changed.connect(_update_texts)
	_lang_en_button.pressed.connect(func() -> void: _loc.set_locale("en"))
	_lang_es_button.pressed.connect(func() -> void: _loc.set_locale("es"))
	_update_texts()
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_close_settings_button.pressed.connect(_on_close_settings_pressed)
	_reset_button.pressed.connect(_on_reset_demo_pressed)
	_apply_button_feedback(_start_button)
	_apply_button_feedback(_continue_button)
	_apply_button_feedback(_settings_button)
	_apply_button_feedback(_reset_button)
	_apply_button_feedback(_lang_en_button)
	_apply_button_feedback(_lang_es_button)
	_apply_button_feedback(_close_settings_button)
	_apply_ui_button_sizes()
	_play_idle_preview()


func _apply_ui_button_sizes() -> void:
	UIStyle.apply_wide_button(_start_button)
	UIStyle.apply_wide_button(_continue_button)
	UIStyle.apply_wide_button(_settings_button)
	UIStyle.apply_wide_button(_reset_button)
	UIStyle.apply_wide_button(_close_settings_button)
	UIStyle.apply_language_button(_lang_en_button)
	UIStyle.apply_language_button(_lang_es_button)


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 52.0
	cam.position = Vector3(4.6, 3.2, 6.2)
	cam.look_at(Vector3(0.0, 0.65, 0.0), Vector3.UP)


func _play_idle_preview() -> void:
	var motorling := $MotorlingPreview as Node3D
	var base_y := motorling.position.y
	var tw := create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(motorling, "position:y", base_y + 0.09, 1.1)
	tw.tween_property(motorling, "position:y", base_y, 1.1)


func _go_to_workshop() -> void:
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)


func _update_texts() -> void:
	_title_label.text = _loc.t("START_TITLE")
	_subtitle_label.text = _loc.t("START_SUBTITLE")
	_start_button.text = _loc.t("START_BUTTON_NEW")
	_continue_button.text = _loc.t("START_BUTTON_CONTINUE")
	_settings_button.text = _loc.t("START_BUTTON_SETTINGS")
	_settings_title_label.text = _loc.t("SETTINGS_TITLE")
	_reset_button.text = _loc.t("START_BUTTON_RESET")
	_close_settings_button.text = _loc.t("SETTINGS_CLOSE")
	_language_label.text = _loc.t("LANGUAGE_LABEL")
	_lang_en_button.text = _loc.t("LANGUAGE_ENGLISH")
	_lang_es_button.text = _loc.t("LANGUAGE_SPANISH")

	_update_continue_state()
	if demo_was_reset:
		_footer_label.text = _loc.t("START_DEMO_RESET")
	elif _continue_button.disabled:
		_footer_label.text = _loc.t("START_NO_PROGRESS")
	else:
		_footer_label.text = _loc.t("START_FOOTER")
	_update_language_button_state()


func _update_continue_state() -> void:
	var has_progress := (
		_mission_state.mission_started
		or _mission_state.machine_built
		or _mission_state.test_completed
		or _mission_state.community_unlocked
		or _mission_state.mission_2_completed
	)
	_continue_button.disabled = not has_progress


func _update_language_button_state() -> void:
	var is_en: bool = _loc.get_locale() == "en"
	_lang_en_button.disabled = is_en
	_lang_es_button.disabled = not is_en
	_lang_en_button.modulate = Color(1, 1, 1, 1) if is_en else Color(0.9, 0.9, 0.95, 1)
	_lang_es_button.modulate = Color(1, 1, 1, 1) if not is_en else Color(0.9, 0.9, 0.95, 1)


func _on_start_pressed() -> void:
	_build_state.reset()
	_mission_state.reset_mission()
	_mission_state.start_first_mission()
	_save_manager.save_game()
	_scene_transition.fade_to_scene("res://scenes/story_intro.tscn")


func _on_continue_pressed() -> void:
	if _continue_button.disabled:
		return
	# Ir a la escena más relevante según progreso.
	if _mission_state.current_mission_id == "carry_first_blocks":
		if _mission_state.machine_built and not _mission_state.test_completed:
			_scene_transition.fade_to_scene("res://scenes/test_zone_blocks.tscn")
		elif not _mission_state.machine_built:
			_go_to_workshop()
		else:
			_scene_transition.fade_to_scene("res://scenes/community.tscn")
	elif _mission_state.community_unlocked or _mission_state.test_completed:
		_scene_transition.fade_to_scene("res://scenes/community.tscn")
	elif _mission_state.machine_built:
		_scene_transition.fade_to_scene("res://scenes/test_zone.tscn")
	else:
		_go_to_workshop()


func _on_reset_demo_pressed() -> void:
	_build_state.reset()
	_mission_state.reset_mission()
	_save_manager.reset_save()
	_save_manager.save_game() # re-graba locale actual + progreso vacío
	demo_was_reset = true
	_update_texts()
	if DEBUG_LOGS:
		print("Demo reset")


func _on_settings_pressed() -> void:
	_settings_panel.visible = true


func _on_close_settings_pressed() -> void:
	_settings_panel.visible = false


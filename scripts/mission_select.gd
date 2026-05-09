extends Node3D

## Selección de misiones (MVP 2.0–2.1): misión 2 se desbloquea al completar la 1 (sin gameplay aún).

const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")

const DEBUG_LOGS := false

@onready var _title_label: Label = %TitleLabel
@onready var _igor_label: Label = %IgorMessageLabel
@onready var _m1_title: Label = %Mission1TitleLabel
@onready var _m1_desc: Label = %Mission1DescriptionLabel
@onready var _m1_status: Label = %Mission1StatusLabel
@onready var _play_button: Button = %PlayMissionButton
@onready var _m2_title: Label = %Mission2TitleLabel
@onready var _m2_desc: Label = %Mission2DescriptionLabel
@onready var _m2_status: Label = %Mission2StatusLabel
@onready var _locked_button: Button = %LockedButton
@onready var _back_button: Button = %BackButton
@onready var _card_first: PanelContainer = %MissionCardFirst
@onready var _card_second: PanelContainer = %MissionCardSecond

@onready var _marker_first: Node3D = $MissionMarkers/MissionMarkerFirstPath
@onready var _marker_second: Node3D = $MissionMarkers/MissionMarkerSecondComingSoon

var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var _marker_first_idle: Tween = null
var _marker_second_idle: Tween = null

var _style_m2_panel_locked: StyleBoxFlat
var _style_m2_panel_available: StyleBoxFlat


func _ready() -> void:
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_setup_camera()
	var panel_sb := _card_second.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_sb != null:
		_style_m2_panel_locked = panel_sb.duplicate() as StyleBoxFlat
	else:
		_style_m2_panel_locked = StyleBoxFlat.new()
	_style_m2_panel_available = _build_m2_available_panel_style()
	_loc.locale_changed.connect(_apply_localized_text)
	_apply_localized_text()
	_play_button.pressed.connect(_on_play_pressed)
	_locked_button.pressed.connect(_on_mission2_button_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_apply_button_feedback(_play_button)
	_apply_button_feedback(_locked_button)
	_apply_button_feedback(_back_button)
	_play_marker_idles()
	if DEBUG_LOGS:
		print("MissionSelect ready")


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 52.0
	cam.position = Vector3(4.9, 3.35, 6.1)
	cam.look_at(Vector3(0.0, 0.2, 0.0), Vector3.UP)


func _apply_localized_text() -> void:
	_title_label.text = _loc.t("MISSION_SELECT_TITLE")
	_igor_label.text = _loc.t("MISSION_SELECT_MESSAGE")
	_m1_title.text = _loc.t("MISSION_1_TITLE")
	_m1_desc.text = _loc.t("MISSION_1_DESCRIPTION")
	if _mission_state.community_unlocked:
		_m1_status.text = _loc.t("MISSION_1_STATUS_COMPLETED")
	else:
		_m1_status.text = _loc.t("MISSION_1_STATUS_AVAILABLE")
	_play_button.text = _loc.t("MISSION_1_BUTTON")
	_m2_title.text = _loc.t("MISSION_2_TITLE")
	_m2_desc.text = _loc.t("MISSION_2_DESCRIPTION")
	var m2_unlocked := _mission_state.is_second_mission_unlocked()
	if m2_unlocked:
		_m2_status.text = _loc.t("MISSION_2_STATUS_AVAILABLE")
		_locked_button.text = _loc.t("MISSION_2_BUTTON_AVAILABLE")
	else:
		_m2_status.text = _loc.t("MISSION_2_STATUS_LOCKED")
		_locked_button.text = _loc.t("MISSION_2_BUTTON_LOCKED")
	_back_button.text = _loc.t("MISSION_SELECT_BACK")
	_refresh_card_visuals()


func _build_m2_available_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.15, 0.26, 0.88)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.82, 0.62, 0.35, 0.52)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	return sb


func _refresh_card_visuals() -> void:
	_card_first.modulate = Color.WHITE
	_play_button.disabled = false
	_play_button.modulate = Color.WHITE

	var m2_unlocked := _mission_state.is_second_mission_unlocked()
	if m2_unlocked:
		_card_second.add_theme_stylebox_override("panel", _style_m2_panel_available)
		_card_second.modulate = Color(0.96, 0.96, 1.0, 1.0)
		_m2_title.add_theme_color_override("font_color", Color(0.98, 0.9, 0.76, 1.0))
		_m2_desc.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0, 1.0))
		_m2_status.add_theme_color_override("font_color", Color(0.62, 0.98, 0.86, 1.0))
		_locked_button.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0, 1.0))
		_locked_button.modulate = Color.WHITE
	else:
		_card_second.add_theme_stylebox_override("panel", _style_m2_panel_locked)
		_card_second.modulate = Color(0.86, 0.86, 0.91, 1.0)
		_m2_title.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82, 1.0))
		_m2_desc.add_theme_color_override("font_color", Color(0.65, 0.68, 0.76, 1.0))
		_m2_status.add_theme_color_override("font_color", Color(0.62, 0.64, 0.74, 1.0))
		_locked_button.add_theme_color_override("font_color", Color(0.72, 0.74, 0.82, 1.0))
		_locked_button.modulate = Color(0.92, 0.92, 0.96, 1.0)


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)


func _play_marker_idles() -> void:
	var y1 := _marker_first.position.y
	if _marker_first_idle != null and _marker_first_idle.is_valid():
		_marker_first_idle.kill()
	_marker_first_idle = create_tween()
	_marker_first_idle.set_loops()
	_marker_first_idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_marker_first_idle.tween_property(_marker_first, "position:y", y1 + 0.07, 0.95)
	_marker_first_idle.tween_property(_marker_first, "position:y", y1, 0.95)

	# Segundo marcador: pulso muy suave (bloqueado pero vivo).
	var y2 := _marker_second.position.y
	if _marker_second_idle != null and _marker_second_idle.is_valid():
		_marker_second_idle.kill()
	_marker_second_idle = create_tween()
	_marker_second_idle.set_loops()
	_marker_second_idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_marker_second_idle.tween_property(_marker_second, "position:y", y2 + 0.035, 1.25)
	_marker_second_idle.tween_property(_marker_second, "position:y", y2, 1.25)


func _on_play_pressed() -> void:
	_mission_state.select_first_mission()
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _on_mission2_button_pressed() -> void:
	if _mission_state.is_second_mission_unlocked():
		_igor_label.text = _loc.t("MISSION_2_NOT_READY_MESSAGE")
	else:
		_igor_label.text = _loc.t("MISSION_LOCKED_MESSAGE")


func _on_back_pressed() -> void:
	_scene_transition.fade_to_scene("res://scenes/start_screen.tscn")

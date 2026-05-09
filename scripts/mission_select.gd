extends Node3D

## Selección de misiones (MVP 2.0–2.5): mapa de progreso simple; misión 3 solo placeholder.

const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")
const UIStyle := preload("res://scripts/ui_style_helper.gd")

const DEBUG_LOGS := false

@onready var _title_label: Label = %TitleLabel
@onready var _igor_label: Label = %IgorMessageLabel
@onready var _progress_label: Label = %PlanetProgressLabel
@onready var _m1_title: Label = %Mission1TitleLabel
@onready var _m1_desc: Label = %Mission1DescriptionLabel
@onready var _m1_status: Label = %Mission1StatusLabel
@onready var _play_button: Button = %PlayMissionButton
@onready var _m2_title: Label = %Mission2TitleLabel
@onready var _m2_desc: Label = %Mission2DescriptionLabel
@onready var _m2_status: Label = %Mission2StatusLabel
@onready var _locked_button: Button = %LockedButton
@onready var _m3_title: Label = %Mission3TitleLabel
@onready var _m3_desc: Label = %Mission3DescriptionLabel
@onready var _m3_status: Label = %Mission3StatusLabel
@onready var _m3_button: Button = %Mission3LockedButton
@onready var _back_button: Button = %BackButton
@onready var _card_first: PanelContainer = %MissionCardFirst
@onready var _card_second: PanelContainer = %MissionCardSecond
@onready var _card_third: PanelContainer = %MissionCardThird

@onready var _marker_first: Node3D = $MissionMarkers/MissionMarkerFirstPath
@onready var _marker_second: Node3D = $MissionMarkers/MissionMarkerSecondComingSoon
@onready var _marker_third: Node3D = $MissionMarkers/MissionMarkerThird
@onready var _m3_sleep_orb: MeshInstance3D = $MissionMarkers/MissionMarkerThird/SleepingLightOrb
@onready var _m3_zzz_label: Label3D = $MissionMarkers/MissionMarkerThird/ZzzLabel
@onready var _m1_check: Node3D = $MissionMarkers/MissionMarkerFirstPath/CompletedCheck
@onready var _m1_pin_top: MeshInstance3D = $MissionMarkers/MissionMarkerFirstPath/PinTop
@onready var _m2_pin_base: MeshInstance3D = $MissionMarkers/MissionMarkerSecondComingSoon/PinBase2
@onready var _m2_pin_stem: MeshInstance3D = $MissionMarkers/MissionMarkerSecondComingSoon/PinStem2
@onready var _m2_lock_body: MeshInstance3D = $MissionMarkers/MissionMarkerSecondComingSoon/LockBody
@onready var _m2_lock_shackle: MeshInstance3D = $MissionMarkers/MissionMarkerSecondComingSoon/LockShackle
@onready var _m2_orb: MeshInstance3D = $MissionMarkers/MissionMarkerSecondComingSoon/PinOrb
@onready var _m2_check: Node3D = $MissionMarkers/MissionMarkerSecondComingSoon/CompletedCheck

var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var _marker_first_idle: Tween = null
var _marker_second_idle: Tween = null
var _marker_third_idle: Tween = null
var _m3_orb_tween: Tween = null
var _m3_zzz_tween: Tween = null

var _style_m1_panel_active: StyleBoxFlat
var _style_m1_panel_completed: StyleBoxFlat
var _style_m2_panel_locked: StyleBoxFlat
var _style_m2_panel_available: StyleBoxFlat
var _style_m2_panel_completed: StyleBoxFlat

var _m1_top_idle_mat: StandardMaterial3D
var _m1_top_done_mat: StandardMaterial3D
var _m2_base_locked_mat: StandardMaterial3D
var _m2_base_unlocked_mat: StandardMaterial3D
var _m2_stem_locked_mat: StandardMaterial3D
var _m2_stem_unlocked_mat: StandardMaterial3D
var _m2_orb_idle_mat: StandardMaterial3D
var _m2_orb_done_mat: StandardMaterial3D


func _ready() -> void:
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_setup_camera()
	_init_card_styles()
	_cache_marker_materials()
	_loc.locale_changed.connect(_apply_localized_text)
	_apply_localized_text()
	_play_button.pressed.connect(_on_play_pressed)
	_locked_button.pressed.connect(_on_mission2_button_pressed)
	_m3_button.pressed.connect(_on_mission3_button_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_apply_button_feedback(_play_button)
	_apply_button_feedback(_locked_button)
	_apply_button_feedback(_m3_button)
	_apply_button_feedback(_back_button)
	_apply_standard_buttons()
	_refresh_marker_visuals()
	_start_mission3_sleep_animations()
	if DEBUG_LOGS:
		print("MissionSelect ready")


func _exit_tree() -> void:
	if _loc != null and _loc.locale_changed.is_connected(_apply_localized_text):
		_loc.locale_changed.disconnect(_apply_localized_text)
	_kill_all_mission_select_tweens()


func _kill_all_mission_select_tweens() -> void:
	if _marker_first_idle != null and _marker_first_idle.is_valid():
		_marker_first_idle.kill()
	_marker_first_idle = null
	if _marker_second_idle != null and _marker_second_idle.is_valid():
		_marker_second_idle.kill()
	_marker_second_idle = null
	if _marker_third_idle != null and _marker_third_idle.is_valid():
		_marker_third_idle.kill()
	_marker_third_idle = null
	if _m3_orb_tween != null and _m3_orb_tween.is_valid():
		_m3_orb_tween.kill()
	_m3_orb_tween = null
	if _m3_zzz_tween != null and _m3_zzz_tween.is_valid():
		_m3_zzz_tween.kill()
	_m3_zzz_tween = null


func _init_card_styles() -> void:
	var p1 := _card_first.get_theme_stylebox("panel") as StyleBoxFlat
	if p1 != null:
		_style_m1_panel_active = p1.duplicate() as StyleBoxFlat
		_style_m1_panel_completed = p1.duplicate() as StyleBoxFlat
		_style_m1_panel_completed.border_color = Color(0.9, 0.72, 0.42, 0.72)
	else:
		_style_m1_panel_active = StyleBoxFlat.new()
		_style_m1_panel_completed = StyleBoxFlat.new()

	var panel_sb := _card_second.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_sb != null:
		_style_m2_panel_locked = panel_sb.duplicate() as StyleBoxFlat
	else:
		_style_m2_panel_locked = StyleBoxFlat.new()
	_style_m2_panel_available = _build_m2_available_panel_style()
	_style_m2_panel_completed = _build_m2_available_panel_style()
	_style_m2_panel_completed.border_color = Color(0.94, 0.76, 0.36, 0.82)


func _cache_marker_materials() -> void:
	if _m1_pin_top != null:
		var m1_base := _m1_pin_top.get_active_material(0)
		if m1_base is StandardMaterial3D:
			_m1_top_idle_mat = (m1_base as StandardMaterial3D).duplicate() as StandardMaterial3D
			_m1_top_done_mat = _m1_top_idle_mat.duplicate() as StandardMaterial3D
			_m1_top_done_mat.emission_energy_multiplier = 2.12
			_m1_top_done_mat.emission = Color(1, 0.68, 0.32)

	_cache_m2_pin_materials()

	if _m2_orb != null:
		var o_base := _m2_orb.get_active_material(0)
		if o_base is StandardMaterial3D:
			_m2_orb_idle_mat = (o_base as StandardMaterial3D).duplicate() as StandardMaterial3D
			_m2_orb_done_mat = _m2_orb_idle_mat.duplicate() as StandardMaterial3D
			_m2_orb_done_mat.emission_energy_multiplier = 2.0
			_m2_orb_done_mat.emission = Color(1, 0.72, 0.28)


func _cache_m2_pin_materials() -> void:
	if _m2_pin_base == null or _m2_pin_stem == null:
		return
	var mb := _m2_pin_base.get_active_material(0)
	if mb is StandardMaterial3D:
		var src_b := mb as StandardMaterial3D
		_m2_base_locked_mat = src_b.duplicate() as StandardMaterial3D
		_m2_base_locked_mat.albedo_color *= Color(0.62, 0.62, 0.66)
		_m2_base_unlocked_mat = src_b.duplicate() as StandardMaterial3D
		_m2_base_unlocked_mat.albedo_color = Color(0.36, 0.64, 0.54)
		_m2_base_unlocked_mat.emission_enabled = true
		_m2_base_unlocked_mat.emission = Color(0.22, 0.48, 0.38)
		_m2_base_unlocked_mat.emission_energy_multiplier = 0.24
	var ms := _m2_pin_stem.get_active_material(0)
	if ms is StandardMaterial3D:
		var src_s := ms as StandardMaterial3D
		_m2_stem_locked_mat = src_s.duplicate() as StandardMaterial3D
		_m2_stem_locked_mat.albedo_color *= Color(0.62, 0.62, 0.66)
		_m2_stem_unlocked_mat = src_s.duplicate() as StandardMaterial3D
		_m2_stem_unlocked_mat.albedo_color = Color(0.44, 0.68, 0.58)
		_m2_stem_unlocked_mat.emission_enabled = true
		_m2_stem_unlocked_mat.emission = Color(0.25, 0.52, 0.42)
		_m2_stem_unlocked_mat.emission_energy_multiplier = 0.2


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 52.0
	cam.position = Vector3(4.82, 3.4, 6.58)
	cam.look_at(Vector3(0.0, 0.15, 0.0), Vector3.UP)


func _apply_standard_buttons() -> void:
	UIStyle.apply_primary_button(_play_button)
	UIStyle.apply_primary_button(_locked_button)
	UIStyle.apply_primary_button(_m3_button)
	UIStyle.apply_primary_button(_back_button)


func _planet_progress_key() -> String:
	if _mission_state.mission_2_completed:
		return "MISSION_SELECT_PROGRESS_2"
	if _mission_state.community_unlocked:
		return "MISSION_SELECT_PROGRESS_1"
	return "MISSION_SELECT_PROGRESS_0"


func _igor_message_key() -> String:
	if _mission_state.mission_2_completed:
		return "MISSION_SELECT_MESSAGE_LIGHT_TOWER_NEXT"
	if _mission_state.community_unlocked:
		return "MISSION_SELECT_MESSAGE_M2_READY"
	return "MISSION_SELECT_MESSAGE_START"


func _apply_localized_text() -> void:
	_title_label.text = _loc.t("MISSION_SELECT_TITLE")
	_progress_label.text = _loc.t(_planet_progress_key())
	_igor_label.text = _loc.t(_igor_message_key())
	_m1_title.text = _loc.t("MISSION_1_TITLE")
	_m1_desc.text = _loc.t("MISSION_1_DESCRIPTION")
	if _mission_state.community_unlocked:
		_m1_status.text = _loc.t("MISSION_1_STATUS_COMPLETED")
		_play_button.text = _loc.t("MISSION_REPLAY_BUTTON")
	else:
		_m1_status.text = _loc.t("MISSION_1_STATUS_AVAILABLE")
		_play_button.text = _loc.t("MISSION_1_BUTTON")
	_m2_title.text = _loc.t("MISSION_2_TITLE")
	_m2_desc.text = _loc.t("MISSION_2_DESCRIPTION")
	var m2_unlocked := _mission_state.is_second_mission_unlocked()
	if m2_unlocked:
		if _mission_state.mission_2_completed:
			_m2_status.text = _loc.t("MISSION_2_STATUS_COMPLETED")
			_locked_button.text = _loc.t("MISSION_REPLAY_BUTTON")
		else:
			_m2_status.text = _loc.t("MISSION_2_STATUS_AVAILABLE")
			_locked_button.text = _loc.t("MISSION_2_BUTTON_AVAILABLE")
	else:
		_m2_status.text = _loc.t("MISSION_2_STATUS_LOCKED")
		_locked_button.text = _loc.t("MISSION_2_BUTTON_LOCKED")
	_m3_title.text = _loc.t("MISSION_3_TITLE")
	_m3_desc.text = _loc.t("MISSION_3_DESCRIPTION")
	_m3_status.text = _loc.t("MISSION_3_STATUS_LOCKED")
	_m3_button.text = _loc.t("MISSION_3_BUTTON_LOCKED")
	_back_button.text = _loc.t("MISSION_SELECT_BACK")
	_refresh_card_visuals()
	_refresh_marker_visuals()


func _build_m2_available_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.15, 0.26, 0.88)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.82, 0.62, 0.35, 0.52)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	return sb


func _refresh_card_visuals() -> void:
	if _style_m1_panel_active != null:
		if _mission_state.community_unlocked:
			_card_first.add_theme_stylebox_override("panel", _style_m1_panel_completed)
		else:
			_card_first.add_theme_stylebox_override("panel", _style_m1_panel_active)
	_card_first.modulate = Color.WHITE
	_play_button.disabled = false
	_play_button.modulate = Color.WHITE

	var m2_unlocked := _mission_state.is_second_mission_unlocked()
	if m2_unlocked:
		if _mission_state.mission_2_completed:
			_card_second.add_theme_stylebox_override("panel", _style_m2_panel_completed)
		else:
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

	_card_third.modulate = Color(0.88, 0.88, 0.92, 1.0)
	_m3_button.disabled = false


func _refresh_marker_visuals() -> void:
	var m1_done := _mission_state.community_unlocked
	if is_instance_valid(_m1_check):
		_m1_check.visible = m1_done
	if is_instance_valid(_m1_pin_top) and _m1_top_idle_mat != null and _m1_top_done_mat != null:
		_m1_pin_top.set_surface_override_material(0, _m1_top_done_mat if m1_done else _m1_top_idle_mat)

	var m2_locked := not _mission_state.is_second_mission_unlocked()
	var m2_done := _mission_state.mission_2_completed
	if is_instance_valid(_m2_lock_body):
		_m2_lock_body.visible = m2_locked
	if is_instance_valid(_m2_lock_shackle):
		_m2_lock_shackle.visible = m2_locked
	if is_instance_valid(_m2_orb):
		_m2_orb.visible = not m2_locked
	if is_instance_valid(_m2_check):
		_m2_check.visible = m2_done and not m2_locked
	if is_instance_valid(_m2_pin_base):
		if m2_locked and _m2_base_locked_mat != null:
			_m2_pin_base.set_surface_override_material(0, _m2_base_locked_mat)
		elif not m2_locked and _m2_base_unlocked_mat != null:
			_m2_pin_base.set_surface_override_material(0, _m2_base_unlocked_mat)
	if is_instance_valid(_m2_pin_stem):
		if m2_locked and _m2_stem_locked_mat != null:
			_m2_pin_stem.set_surface_override_material(0, _m2_stem_locked_mat)
		elif not m2_locked and _m2_stem_unlocked_mat != null:
			_m2_pin_stem.set_surface_override_material(0, _m2_stem_unlocked_mat)
	if is_instance_valid(_m2_orb) and _m2_orb.visible and _m2_orb_idle_mat != null and _m2_orb_done_mat != null:
		_m2_orb.set_surface_override_material(0, _m2_orb_done_mat if m2_done else _m2_orb_idle_mat)

	_play_marker_idles()


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2.ONE
	)


func _play_marker_idles() -> void:
	if is_instance_valid(_marker_first):
		var y1 := _marker_first.position.y
		if _marker_first_idle != null and _marker_first_idle.is_valid():
			_marker_first_idle.kill()
		_marker_first_idle = create_tween()
		_marker_first_idle.set_loops()
		_marker_first_idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var amp1 := 0.045 if _mission_state.community_unlocked else 0.075
		_marker_first_idle.tween_property(_marker_first, "position:y", y1 + amp1, 0.95)
		_marker_first_idle.tween_property(_marker_first, "position:y", y1, 0.95)

	if is_instance_valid(_marker_second):
		var y2 := _marker_second.position.y
		if _marker_second_idle != null and _marker_second_idle.is_valid():
			_marker_second_idle.kill()
		_marker_second_idle = create_tween()
		_marker_second_idle.set_loops()
		_marker_second_idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var m2_u := _mission_state.is_second_mission_unlocked()
		var m2_d := _mission_state.mission_2_completed
		var amp2 := 0.032
		if m2_u and not m2_d:
			amp2 = 0.064
		elif m2_d:
			amp2 = 0.042
		var dur2 := 1.15 if m2_u else 1.28
		_marker_second_idle.tween_property(_marker_second, "position:y", y2 + amp2, dur2)
		_marker_second_idle.tween_property(_marker_second, "position:y", y2, dur2)

	if is_instance_valid(_marker_third):
		var y3 := _marker_third.position.y
		if _marker_third_idle != null and _marker_third_idle.is_valid():
			_marker_third_idle.kill()
		_marker_third_idle = create_tween()
		_marker_third_idle.set_loops()
		_marker_third_idle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_marker_third_idle.tween_property(_marker_third, "position:y", y3 + 0.028, 1.22)
		_marker_third_idle.tween_property(_marker_third, "position:y", y3, 1.22)


func _on_play_pressed() -> void:
	_kill_all_mission_select_tweens()
	_mission_state.select_first_mission()
	if is_instance_valid(_scene_transition):
		_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _on_mission2_button_pressed() -> void:
	if _mission_state.is_second_mission_unlocked():
		_kill_all_mission_select_tweens()
		_mission_state.select_second_mission()
		if is_instance_valid(_scene_transition):
			_scene_transition.fade_to_scene("res://scenes/workshop.tscn")
	else:
		_igor_label.text = _loc.t("MISSION_LOCKED_MESSAGE")


func _on_mission3_button_pressed() -> void:
	_igor_label.text = _loc.t("MISSION_3_LOCKED_MESSAGE")


func _start_mission3_sleep_animations() -> void:
	if _m3_orb_tween != null and _m3_orb_tween.is_valid():
		_m3_orb_tween.kill()
	_m3_orb_tween = null
	if _m3_zzz_tween != null and _m3_zzz_tween.is_valid():
		_m3_zzz_tween.kill()
	_m3_zzz_tween = null

	if is_instance_valid(_m3_sleep_orb):
		var base_mat := _m3_sleep_orb.get_active_material(0)
		if base_mat is StandardMaterial3D:
			var mat := (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			_m3_sleep_orb.set_surface_override_material(0, mat)
			_m3_orb_tween = create_tween()
			_m3_orb_tween.set_loops()
			_m3_orb_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			var e_lo := mat.emission_energy_multiplier * 0.72
			var e_hi := mat.emission_energy_multiplier * 1.18
			_m3_orb_tween.tween_property(mat, "emission_energy_multiplier", e_hi, 2.6)
			_m3_orb_tween.tween_property(mat, "emission_energy_multiplier", e_lo, 2.6)
	if is_instance_valid(_m3_zzz_label):
		var y0 := _m3_zzz_label.position.y
		_m3_zzz_tween = create_tween()
		_m3_zzz_tween.set_loops()
		_m3_zzz_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_m3_zzz_tween.tween_property(_m3_zzz_label, "position:y", y0 + 0.032, 1.35)
		_m3_zzz_tween.tween_property(_m3_zzz_label, "position:y", y0, 1.35)


func _on_back_pressed() -> void:
	_kill_all_mission_select_tweens()
	if is_instance_valid(_scene_transition):
		_scene_transition.fade_to_scene("res://scenes/start_screen.tscn")

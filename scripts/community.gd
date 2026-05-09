extends Node3D

## Primer vistazo al planeta que mejora tras ayudar en la zona de prueba (MVP 0.8).

const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")
const UIStyle := preload("res://scripts/ui_style_helper.gd")

const DEBUG_LOGS := false

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _mission_status_label: Label = %MissionStatusLabel
@onready var _back_button: Button = %BackToWorkshopButton
@onready var _next_button: Button = %NextButton
@onready var _m2_delivered_blocks: Node3D = %Mission2DeliveredBlocks

var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var _celebration_house_tween: Tween = null
var _celebration_light_tween: Tween = null


func _ready() -> void:
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_setup_camera()
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_apply_button_feedback(_back_button)
	_apply_button_feedback(_next_button)
	UIStyle.apply_primary_button(_back_button)
	UIStyle.apply_primary_button(_next_button)
	_play_intro_celebration()

	_mission_state.mark_community_unlocked()
	if _mission_state.current_mission_id == "carry_first_blocks":
		_mission_state.mark_mission_2_completed()
	if DEBUG_LOGS:
		print("MissionState: community unlocked")

	_apply_localized_text()
	_loc.locale_changed.connect(_apply_localized_text)

	_mission_status_label.visible = _mission_state.community_unlocked or _mission_state.mission_2_completed
	if is_instance_valid(_m2_delivered_blocks):
		_m2_delivered_blocks.visible = _mission_state.mission_2_completed


func _exit_tree() -> void:
	if _loc != null and _loc.locale_changed.is_connected(_apply_localized_text):
		_loc.locale_changed.disconnect(_apply_localized_text)
	if _celebration_house_tween != null and _celebration_house_tween.is_valid():
		_celebration_house_tween.kill()
	_celebration_house_tween = null
	if _celebration_light_tween != null and _celebration_light_tween.is_valid():
		_celebration_light_tween.kill()
	_celebration_light_tween = null


func _apply_localized_text() -> void:
	var title := get_node_or_null("CanvasLayer/UI/TitleLabel") as Label
	if title != null:
		title.text = _loc.t("COMMUNITY_TITLE")
	if _mission_state.mission_2_completed:
		_igor_label.text = _loc.t("MISSION_2_COMMUNITY_MESSAGE")
		_progress_label.text = _loc.t("MISSION_2_COMMUNITY_PROGRESS")
		_mission_status_label.text = _loc.t("MISSION_2_COMPLETED")
	else:
		_igor_label.text = _loc.t("COMMUNITY_MESSAGE")
		_progress_label.text = _loc.t("COMMUNITY_PROGRESS")
		_mission_status_label.text = _loc.t("COMMUNITY_MISSION_COMPLETED")
	_back_button.text = _loc.t("COMMUNITY_BUTTON_BACK")
	_next_button.text = _loc.t("COMMUNITY_BUTTON_NEXT")
	var hint := get_node_or_null("CanvasLayer/UI/HintPanel/HintLabel") as Label
	if hint != null:
		hint.text = _loc.t("COMMUNITY_HINT")


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 52.0
	cam.position = Vector3(5.65, 3.76, 6.95)
	cam.look_at(Vector3(0.05, 0.32, -0.05), Vector3.UP)


func _play_intro_celebration() -> void:
	var house := get_node_or_null("SmallWorkshopOrHouse") as Node3D
	if not is_instance_valid(house):
		return
	if _celebration_house_tween != null and _celebration_house_tween.is_valid():
		_celebration_house_tween.kill()
	if _celebration_light_tween != null and _celebration_light_tween.is_valid():
		_celebration_light_tween.kill()
	house.scale = Vector3(0.8, 0.8, 0.8)
	_celebration_house_tween = create_tween()
	_celebration_house_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_celebration_house_tween.tween_property(house, "scale", Vector3.ONE, 0.7)

	var omni := get_node_or_null("PlanetCoreLight/CoreLight") as OmniLight3D
	if not is_instance_valid(omni):
		return
	var e0 := omni.light_energy
	_celebration_light_tween = create_tween()
	_celebration_light_tween.set_loops()
	_celebration_light_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_celebration_light_tween.tween_property(omni, "light_energy", e0 * 1.38, 1.05)
	_celebration_light_tween.tween_property(omni, "light_energy", e0, 1.05)


func _go_to_workshop() -> void:
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		if is_instance_valid(b):
			b.scale = Vector2.ONE
	)


func _on_back_pressed() -> void:
	_go_to_workshop()


func _on_next_pressed() -> void:
	if _next_button.disabled:
		return
	_next_button.disabled = true
	_igor_label.text = _loc.t("COMMUNITY_NEXT_MESSAGE")
	await get_tree().create_timer(1.05).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if not is_instance_valid(_scene_transition):
		return
	_scene_transition.fade_to_scene("res://scenes/mission_select.tscn")

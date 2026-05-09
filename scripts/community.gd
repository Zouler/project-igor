extends Node3D

## Primer vistazo al planeta que mejora tras ayudar en la zona de prueba (MVP 0.8).

const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")

const DEBUG_LOGS := false

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _mission_status_label: Label = %MissionStatusLabel
@onready var _back_button: Button = %BackToWorkshopButton
@onready var _next_button: Button = %NextButton

var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript


func _ready() -> void:
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	_setup_camera()
	_apply_localized_text()
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_apply_button_feedback(_back_button)
	_apply_button_feedback(_next_button)
	_play_intro_celebration()

	_mission_state.mark_community_unlocked()
	if DEBUG_LOGS:
		print("MissionState: community unlocked")

	_mission_status_label.visible = _mission_state.community_unlocked


func _apply_localized_text() -> void:
	var title := get_node_or_null("CanvasLayer/UI/TitleLabel") as Label
	if title != null:
		title.text = _loc.t("COMMUNITY_TITLE")
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
	cam.position = Vector3(5.8, 3.85, 7.2)
	cam.look_at(Vector3(0.0, 0.35, 0.0), Vector3.UP)


func _play_intro_celebration() -> void:
	var house := $SmallWorkshopOrHouse as Node3D
	house.scale = Vector3(0.8, 0.8, 0.8)
	var tw_h := create_tween()
	tw_h.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_h.tween_property(house, "scale", Vector3.ONE, 0.7)

	var omni := $PlanetCoreLight/CoreLight as OmniLight3D
	var e0 := omni.light_energy
	var tw_l := create_tween()
	tw_l.set_loops()
	tw_l.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_l.tween_property(omni, "light_energy", e0 * 1.38, 1.05)
	tw_l.tween_property(omni, "light_energy", e0, 1.05)


func _go_to_workshop() -> void:
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
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
	_go_to_workshop()

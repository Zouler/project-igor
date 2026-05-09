extends Node3D

## Primer vistazo al planeta que mejora tras ayudar en la zona de prueba (MVP 0.8).

const MissionStateScript := preload("res://scripts/mission_state.gd")

@onready var _igor_label: Label = %IgorMessageLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _mission_status_label: Label = %MissionStatusLabel
@onready var _back_button: Button = %BackToWorkshopButton
@onready var _next_button: Button = %NextButton

var _mission_state: MissionStateScript


func _ready() -> void:
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_setup_camera()
	_igor_label.text = "Una parte del planeta volvió a moverse."
	_progress_label.text = "Progreso del planeta: 1%"
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_play_intro_celebration()

	_mission_state.mark_community_unlocked()
	print("MissionState: community unlocked")

	_mission_status_label.visible = _mission_state.community_unlocked


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
	get_tree().change_scene_to_file("res://scenes/workshop.tscn")


func _on_back_pressed() -> void:
	_go_to_workshop()


func _on_next_pressed() -> void:
	if _next_button.disabled:
		return
	_next_button.disabled = true
	_igor_label.text = "Pronto construiremos algo nuevo."
	await get_tree().create_timer(1.05).timeout
	_go_to_workshop()

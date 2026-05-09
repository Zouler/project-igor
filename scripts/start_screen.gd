extends Node3D

## Pantalla de inicio (MVP 1.0): título + botones + preview simple.

const BuildStateScript := preload("res://scripts/build_state.gd")
const MissionStateScript := preload("res://scripts/mission_state.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")

const DEBUG_LOGS := false

@onready var _footer_label: Label = %SmallFooterLabel
@onready var _start_button: Button = %StartButton
@onready var _continue_button: Button = %ContinueButton
@onready var _reset_button: Button = %ResetDemoButton

var _build_state: BuildStateScript
var _mission_state: MissionStateScript
var _scene_transition: SceneTransitionScript


func _ready() -> void:
	_build_state = get_node("/root/BuildState") as BuildStateScript
	_mission_state = get_node("/root/MissionState") as MissionStateScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_setup_camera()
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_reset_button.pressed.connect(_on_reset_demo_pressed)
	_apply_button_feedback(_start_button)
	_apply_button_feedback(_continue_button)
	_apply_button_feedback(_reset_button)
	_play_idle_preview()


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


func _on_start_pressed() -> void:
	_build_state.reset()
	_mission_state.reset_mission()
	_mission_state.start_first_mission()
	_go_to_workshop()


func _on_continue_pressed() -> void:
	_go_to_workshop()


func _on_reset_demo_pressed() -> void:
	_build_state.reset()
	_mission_state.reset_mission()
	_footer_label.text = "Demo reiniciada."
	if DEBUG_LOGS:
		print("Demo reset")


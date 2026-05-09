extends Node3D

## Story Intro (MVP 1.4): pasos simples, texto localizado, sin cutscenes complejas.

const LocalizationScript := preload("res://scripts/localization.gd")
const SceneTransitionScript := preload("res://scripts/scene_transition.gd")

const DEBUG_LOGS := false

const TOTAL_STEPS := 9

@onready var _story_text: Label = %StoryTextLabel
@onready var _counter: Label = %StepCounterLabel
@onready var _next_button: Button = %NextButton
@onready var _skip_button: Button = %SkipButton

@onready var _ship: Node3D = $StoryStage/SpaceshipPlaceholder
@onready var _planet: Node3D = $StoryStage/SmallPlanetPlaceholder
@onready var _buried: Node3D = $StoryStage/BuriedIgorPlaceholder
@onready var _igor: Node3D = $StoryStage/IgorPlaceholder
@onready var _motorling_hint: Node3D = $StoryStage/MotorlingHint

var _loc: LocalizationScript
var _scene_transition: SceneTransitionScript
var _step: int = 1
var _ship_bob: Tween = null
var _planet_spin: Tween = null


func _ready() -> void:
	_loc = get_node("/root/Localization") as LocalizationScript
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_setup_camera()
	_apply_button_feedback(_next_button)
	_apply_button_feedback(_skip_button)
	_next_button.pressed.connect(_on_next_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	_play_idle_anims()
	_set_step(1)


func _setup_camera() -> void:
	var cam := $Camera3D as Camera3D
	cam.current = true
	cam.fov = 52.0
	cam.position = Vector3(5.4, 3.2, 6.4)
	cam.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)


func _apply_button_feedback(b: Button) -> void:
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)


func _play_idle_anims() -> void:
	# Nave: bob suave
	var base_y := _ship.position.y
	_ship_bob = create_tween()
	_ship_bob.set_loops()
	_ship_bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ship_bob.tween_property(_ship, "position:y", base_y + 0.08, 1.1)
	_ship_bob.tween_property(_ship, "position:y", base_y, 1.1)

	# Planeta: rotación lenta
	_planet_spin = create_tween()
	_planet_spin.set_loops()
	_planet_spin.set_trans(Tween.TRANS_LINEAR)
	_planet_spin.tween_property(_planet, "rotation:y", _planet.rotation.y + TAU, 9.0)


func _set_step(step: int) -> void:
	_step = clampi(step, 1, TOTAL_STEPS)
	_story_text.text = _loc.t("STORY_STEP_%d" % _step)
	_counter.text = "%d / %d" % [_step, TOTAL_STEPS]

	var is_last := _step >= TOTAL_STEPS
	_next_button.text = _loc.t("STORY_START_MISSION") if is_last else _loc.t("STORY_NEXT")
	_skip_button.text = _loc.t("STORY_SKIP")

	_update_visuals_for_step(_step)

	if DEBUG_LOGS:
		print("StoryIntro step: ", _step)


func _update_visuals_for_step(step: int) -> void:
	# Defaults
	_ship.visible = true
	_planet.visible = false
	_buried.visible = false
	_igor.visible = false
	_motorling_hint.visible = false

	# 1-3: nave protagonista
	if step <= 3:
		_ship.visible = true
	# 4: planeta
	elif step == 4:
		_planet.visible = true
	# 5-6: algo enterrado + pala
	elif step <= 6:
		_planet.visible = true
		_buried.visible = true
	# 7: revelar I.G.O.R.
	elif step == 7:
		_planet.visible = true
		_igor.visible = true
		_wakeup_pulse(_igor)
	# 8-9: planeta + igor + motorling hint
	else:
		_planet.visible = true
		_igor.visible = true
		_motorling_hint.visible = true


func _wakeup_pulse(n: Node3D) -> void:
	var base := n.scale
	n.scale = base * 0.9
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", base, 0.35)


func _go_to_workshop() -> void:
	_scene_transition.fade_to_scene("res://scenes/workshop.tscn")


func _on_skip_pressed() -> void:
	_go_to_workshop()


func _on_next_pressed() -> void:
	if _step >= TOTAL_STEPS:
		_go_to_workshop()
		return
	_set_step(_step + 1)


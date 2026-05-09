extends Node3D

## “Play with I.G.O.R.” — bonding mode: large I.G.O.R., taps + playful UI (no missions).

const SceneTransitionScript := preload("res://scripts/scene_transition.gd")
const LocalizationScript := preload("res://scripts/localization.gd")

const UI_STYLE_PATH := "res://scripts/ui/ui_style.gd"
const IDLE_MIN_SEC := 8.0
const IDLE_MAX_SEC := 12.0
const IDLE_REQUIRED_SILENCE_SEC := 6.0

@onready var _cam: Camera3D = $Camera3D
@onready var _igor: Node3D = $IgorSpot/IgorCharacter

@onready var _title: Label = $CanvasLayer/UI/Top/TitleLabel
@onready var _hint: Label = $CanvasLayer/UI/Top/HintLabel
@onready var _fun_label: Label = $CanvasLayer/UI/RightColumn/FunPanel/Margin/VBox/FunLabel
@onready var _feelings_label: Label = $CanvasLayer/UI/RightColumn/FeelingsPanel/Margin/VBox/FeelingsLabel
@onready var _back: Button = %BackButton
@onready var _joke: Button = %JokeButton
@onready var _song: Button = %SongButton
@onready var _happy: Button = %HappyButton
@onready var _encourage: Button = %EncourageButton
@onready var _toggle_debug: Button = %ToggleDebugButton

var _scene_transition: SceneTransitionScript
var _loc: LocalizationScript
var _ui_style: Script = null

var _last_interaction_sec: float = 0.0
var _idle_timer: Timer = null

var _last_pick: Dictionary = {}
var _debug_zones_on: bool = false


func _ready() -> void:
	randomize()
	_scene_transition = get_node("/root/SceneTransition") as SceneTransitionScript
	_loc = get_node("/root/Localization") as LocalizationScript
	set_process_unhandled_input(true)
	var vp := get_viewport()
	if vp != null:
		vp.physics_object_picking = true
	if _cam != null:
		_cam.current = true
		_cam.look_at(Vector3(-0.25, 0.95, 0), Vector3.UP)
	_loc.locale_changed.connect(_refresh_ui)
	_back.pressed.connect(_on_back)
	_joke.pressed.connect(_on_joke)
	_song.pressed.connect(_on_song)
	_happy.pressed.connect(_on_happy)
	_encourage.pressed.connect(_on_encourage)
	_toggle_debug.pressed.connect(_on_toggle_debug)

	_setup_ui_style()
	_apply_button_feedback(_back)
	_apply_button_feedback(_joke)
	_apply_button_feedback(_song)
	_apply_button_feedback(_happy)
	_apply_button_feedback(_encourage)
	_apply_button_feedback(_toggle_debug)

	_setup_igor_defaults()
	_touch_interaction_happened()
	_setup_idle_timer()
	_refresh_ui()


func _exit_tree() -> void:
	if _loc != null and _loc.locale_changed.is_connected(_refresh_ui):
		_loc.locale_changed.disconnect(_refresh_ui)
	if _idle_timer != null and is_instance_valid(_idle_timer):
		_idle_timer.stop()
		if _idle_timer.timeout.is_connected(_on_idle_timer_timeout):
			_idle_timer.timeout.disconnect(_on_idle_timer_timeout)


func _setup_ui_style() -> void:
	if ResourceLoader.exists(UI_STYLE_PATH):
		_ui_style = load(UI_STYLE_PATH) as Script

	if _ui_style == null:
		return
	# These methods exist on UIStyle (class_name) script; call via `call` to stay resilient.
	if _ui_style.has_method("style_primary_button"):
		_ui_style.call("style_primary_button", _joke)
		_ui_style.call("style_primary_button", _song)
	if _ui_style.has_method("style_secondary_button"):
		_ui_style.call("style_secondary_button", _happy)
		_ui_style.call("style_secondary_button", _encourage)
		_ui_style.call("style_secondary_button", _toggle_debug)
	if _ui_style.has_method("style_settings_button"):
		_ui_style.call("style_settings_button", _back)
	if _ui_style.has_method("apply_button_feedback"):
		_ui_style.call("apply_button_feedback", _back)
		_ui_style.call("apply_button_feedback", _joke)
		_ui_style.call("apply_button_feedback", _song)
		_ui_style.call("apply_button_feedback", _happy)
		_ui_style.call("apply_button_feedback", _encourage)
		_ui_style.call("apply_button_feedback", _toggle_debug)

	# Panels and labels (only add overrides if missing).
	if _ui_style.has_method("style_panel"):
		_ui_style.call("style_panel", $CanvasLayer/UI/RightColumn/FunPanel as Control)
		_ui_style.call("style_panel", $CanvasLayer/UI/RightColumn/FeelingsPanel as Control)
		_ui_style.call("style_panel", $CanvasLayer/UI/RightColumn/DebugPanel as Control)
	if _ui_style.has_method("style_title_label"):
		_ui_style.call("style_title_label", _title)
	if _ui_style.has_method("style_body_label"):
		_ui_style.call("style_body_label", _hint)
		_ui_style.call("style_body_label", _fun_label)
		_ui_style.call("style_body_label", _feelings_label)


func _setup_igor_defaults() -> void:
	if _igor == null:
		return
	if _igor.has_method("set_touch_debug_visuals_visible"):
		_igor.set_touch_debug_visuals_visible(false)
	if _igor.has_method("set_debug_touch_zones_visible"):
		_igor.set_debug_touch_zones_visible(false)
	if _igor.has_method("enable_touch_interactions"):
		_igor.enable_touch_interactions(true)
	var speech_anchor := _igor.get_node_or_null("SpeechAnchor") as Node3D
	if speech_anchor != null:
		speech_anchor.position = Vector3(0.85, 1.15, 0.0)


func _setup_idle_timer() -> void:
	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	add_child(_idle_timer)
	_idle_timer.timeout.connect(_on_idle_timer_timeout)
	_schedule_next_idle()


func _schedule_next_idle() -> void:
	if _idle_timer == null or not is_instance_valid(_idle_timer):
		return
	_idle_timer.wait_time = randf_range(IDLE_MIN_SEC, IDLE_MAX_SEC)
	_idle_timer.start()


func _touch_interaction_happened() -> void:
	_last_interaction_sec = Time.get_ticks_msec() / 1000.0


func _on_idle_timer_timeout() -> void:
	if not is_inside_tree():
		return
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec - _last_interaction_sec < IDLE_REQUIRED_SILENCE_SEC:
		_schedule_next_idle()
		return
	if _igor != null and is_instance_valid(_igor):
		if _igor.has_method("play_joke_motion"):
			_igor.play_joke_motion()
		if _igor.has_method("say"):
			_igor.say("IGOR_REACT_IDLE")
	_touch_interaction_happened()
	_schedule_next_idle()


func _pick_nonrepeat(category: String, keys: PackedStringArray) -> String:
	if keys.size() == 0:
		return ""
	if keys.size() == 1:
		_last_pick[category] = keys[0]
		return keys[0]
	var last := str(_last_pick.get(category, ""))
	var pick := keys[randi() % keys.size()]
	if pick == last:
		pick = keys[(randi() + 1) % keys.size()]
	_last_pick[category] = pick
	return pick


func _on_joke() -> void:
	_touch_interaction_happened()
	if _igor == null:
		return
	var k := _pick_nonrepeat("joke", PackedStringArray(["IGOR_PLAY_JOKE_1", "IGOR_PLAY_JOKE_2", "IGOR_PLAY_JOKE_3"]))
	if _igor.has_method("play_joke_motion"):
		_igor.play_joke_motion()
	if _igor.has_method("say"):
		_igor.say(k)


func _on_song() -> void:
	_touch_interaction_happened()
	if _igor == null:
		return
	var k := _pick_nonrepeat("song", PackedStringArray(["IGOR_PLAY_SONG_1", "IGOR_PLAY_SONG_2", "IGOR_PLAY_SONG_3"]))
	if _igor.has_method("play_song_bounce"):
		_igor.play_song_bounce()
	if _igor.has_method("say"):
		_igor.say(k)


func _on_happy() -> void:
	_touch_interaction_happened()
	if _igor == null:
		return
	var k := _pick_nonrepeat("happy", PackedStringArray(["IGOR_PLAY_HAPPY_1", "IGOR_PLAY_HAPPY_2", "IGOR_PLAY_HAPPY_3"]))
	if _igor.has_method("react_success"):
		_igor.react_success()
	if _igor.has_method("say"):
		_igor.say(k)


func _on_encourage() -> void:
	_touch_interaction_happened()
	if _igor == null:
		return
	var k := _pick_nonrepeat("encourage", PackedStringArray(["IGOR_PLAY_ENCOURAGE_1", "IGOR_PLAY_ENCOURAGE_2", "IGOR_PLAY_ENCOURAGE_3"]))
	if _igor.has_method("react_failure"):
		_igor.react_failure()
	if _igor.has_method("say"):
		_igor.say(k)


func _on_toggle_debug() -> void:
	_touch_interaction_happened()
	if _igor == null:
		return
	if _igor.has_method("toggle_debug_touch_zones"):
		_igor.toggle_debug_touch_zones()
	_debug_zones_on = not _debug_zones_on
	_toggle_debug.modulate = Color(1, 1, 1, 1) if not _debug_zones_on else Color(0.86, 1.0, 0.86, 1)


func _on_back() -> void:
	_touch_interaction_happened()
	if _idle_timer != null and is_instance_valid(_idle_timer):
		_idle_timer.stop()
	if _scene_transition != null:
		_scene_transition.fade_to_scene("res://scenes/start_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if _igor != null and _igor.has_method("handle_viewport_pick"):
		_igor.handle_viewport_pick(event)
		# Any tap on I.G.O.R. counts as interaction for idle timing.
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			_touch_interaction_happened()


func _refresh_ui() -> void:
	_title.text = _loc.t("PLAY_IGOR_TITLE")
	_hint.text = _loc.t("PLAY_IGOR_HINT")
	_fun_label.text = _loc.t("PLAY_IGOR_FUN_LABEL")
	_feelings_label.text = _loc.t("PLAY_IGOR_FEELINGS_LABEL")
	_back.text = _loc.t("PLAY_IGOR_BACK")
	_joke.text = _loc.t("PLAY_IGOR_JOKE")
	_song.text = _loc.t("PLAY_IGOR_SONG")
	_happy.text = _loc.t("PLAY_IGOR_HAPPY")
	_encourage.text = _loc.t("PLAY_IGOR_ENCOURAGE")
	_toggle_debug.text = _loc.t("PLAY_IGOR_TOGGLE_DEBUG")


func _apply_button_feedback(b: Button) -> void:
	if b == null:
		return
	# Prefer shared style helper if present.
	if _ui_style != null and _ui_style.has_method("apply_button_feedback"):
		_ui_style.call("apply_button_feedback", b)
		return
	b.button_down.connect(func() -> void:
		b.scale = Vector2(0.98, 0.98)
	)
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE
	)

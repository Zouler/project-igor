extends Node3D

## Sandbox: run this scene only. Forwards unhandled pointer events to I.G.O.R. raycast pick.

var _igor: Node = null
var _debug_zones_on: bool = false


func _ready() -> void:
	set_process_unhandled_input(true)
	var vp := get_viewport()
	if vp != null:
		vp.physics_object_picking = true
	var cam := get_node_or_null("Camera3D") as Camera3D
	if cam != null:
		cam.current = true
		cam.look_at(Vector3(0, 0.72, 0), Vector3.UP)
	var lbl := get_node_or_null("CanvasLayer/HintLabel") as Label
	var loc := get_node_or_null("/root/Localization")
	if lbl != null and loc != null and loc.has_method("t"):
		lbl.text = str(loc.call("t", "IGOR_PROTOTYPE_TEST_HINT"))

	_igor = get_node_or_null("IgorCharacter")
	_debug_zones_on = false
	_connect_test_buttons()
	_refresh_debug_button_label()


func _connect_test_buttons() -> void:
	_connect_btn("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnSuccess", _on_success_pressed)
	_connect_btn("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnFailure", _on_failure_pressed)
	_connect_btn("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnDisableTouch", _on_disable_touch_pressed)
	_connect_btn("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnEnableTouch", _on_enable_touch_pressed)
	_connect_btn("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnToggleDebugZones", _on_toggle_debug_pressed)


func _connect_btn(node_path: String, cb: Callable) -> void:
	var b := get_node_or_null(node_path) as Button
	if b != null:
		b.pressed.connect(cb)


func _refresh_debug_button_label() -> void:
	var b := get_node_or_null("CanvasLayer/TestPanel/MarginContainer/VBoxContainer/BtnToggleDebugZones") as Button
	if b != null:
		b.text = "Hide debug zones" if _debug_zones_on else "Show debug zones"


func _on_success_pressed() -> void:
	if _igor != null and _igor.has_method("react_success"):
		_igor.react_success()


func _on_failure_pressed() -> void:
	if _igor != null and _igor.has_method("react_failure"):
		_igor.react_failure()


func _on_disable_touch_pressed() -> void:
	if _igor != null and _igor.has_method("enable_touch_interactions"):
		_igor.enable_touch_interactions(false)


func _on_enable_touch_pressed() -> void:
	if _igor != null and _igor.has_method("enable_touch_interactions"):
		_igor.enable_touch_interactions(true)


func _on_toggle_debug_pressed() -> void:
	if _igor == null or not _igor.has_method("set_touch_debug_visuals_visible"):
		return
	_debug_zones_on = not _debug_zones_on
	_igor.set_touch_debug_visuals_visible(_debug_zones_on)
	_refresh_debug_button_label()


func _unhandled_input(event: InputEvent) -> void:
	var igor := get_node_or_null("IgorCharacter")
	if igor != null and igor.has_method("handle_viewport_pick"):
		igor.handle_viewport_pick(event)

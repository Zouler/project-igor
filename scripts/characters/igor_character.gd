extends Node3D

## Prototype I.G.O.R.: primitive meshes + **explicit camera raycast** picking (not engine pick events).

signal igor_reaction_requested(reaction_type: String, message_key: String)

## Verbose Output for pick debugging — keep `false` in normal prototype use.
const DEBUG_LOGS := false
## New instances hide collision debug meshes; use `set_touch_debug_visuals_visible(true)` or the test scene toggle.
const SHOW_TOUCH_DEBUG_VISUALS := false

const REACTION_COOLDOWN_SEC := 0.25

const TOUCH_GROUP := "igor_touch_area"

const KEY_SUCCESS := "IGOR_REACT_SUCCESS"
const KEY_FAIL := "IGOR_REACT_FAIL"
const TYPE_SUCCESS := "react_success"
const TYPE_FAIL := "react_failure"

## meta "reaction" short id → [tap_*, localization key]
const META_TO_REACTION: Dictionary = {
	"head": ["tap_head", "IGOR_REACT_HEAD"],
	"antenna": ["tap_antenna", "IGOR_REACT_ANTENNA"],
	"chest": ["tap_chest", "IGOR_REACT_CHEST"],
	"belly": ["tap_belly", "IGOR_REACT_BELLY"],
	"feet": ["tap_feet", "IGOR_REACT_FEET"],
}

@onready var _visual_root: Node3D = $VisualRoot
@onready var _head: MeshInstance3D = $VisualRoot/Head
@onready var _antenna: MeshInstance3D = $VisualRoot/Antenna
@onready var _chest_tag: MeshInstance3D = $VisualRoot/ChestTag
@onready var _chest_label: Label3D = $VisualRoot/ChestTag/ChestLabel
@onready var _body: MeshInstance3D = $VisualRoot/Body
@onready var _foot_left: MeshInstance3D = $VisualRoot/FootLeft
@onready var _foot_right: MeshInstance3D = $VisualRoot/FootRight
@onready var _eye_left: MeshInstance3D = $VisualRoot/EyeLeft
@onready var _eye_right: MeshInstance3D = $VisualRoot/EyeRight

@onready var _speech_anchor: Node3D = $SpeechAnchor
@onready var _reaction_timer: Timer = $ReactionTimer
@onready var _touch_root: Node3D = $TouchAreas

var _loc: Node = null
var _speech_label: Label3D = null
var _speech_bubble_root: Node3D = null
var _touch_enabled: bool = true
var _speech_visible: bool = false
var _touch_cooldown_until_sec: float = -1.0
var _debug_touch_zones_visible: bool = false

var _idle_bob_tween: Tween = null
var _antenna_idle_tween: Tween = null
var _blink_idle_tween: Tween = null
var _reaction_tween: Tween = null

var _head_base_rot: Vector3 = Vector3.ZERO
var _antenna_base_rot: Vector3 = Vector3.ZERO
var _antenna_base_pos: Vector3 = Vector3.ZERO
var _body_base_rot: Vector3 = Vector3.ZERO
var _body_base_pos: Vector3 = Vector3.ZERO
var _chest_base_scale: Vector3 = Vector3.ONE
var _foot_left_base_rot: Vector3 = Vector3.ZERO
var _foot_right_base_rot: Vector3 = Vector3.ZERO
var _visual_base_y: float = 0.0


func _ready() -> void:
	_loc = get_node_or_null("/root/Localization")
	_visual_base_y = _visual_root.position.y
	_head_base_rot = _head.rotation
	_antenna_base_rot = _antenna.rotation
	_antenna_base_pos = _antenna.position
	_body_base_rot = _body.rotation
	_body_base_pos = _body.position
	_chest_base_scale = _chest_tag.scale
	_foot_left_base_rot = _foot_left.rotation
	_foot_right_base_rot = _foot_right.rotation

	if is_instance_valid(_chest_label):
		_chest_label.text = _t("IGOR_NAMEPLATE")

	_setup_speech_bubble()
	_setup_touch_zones()
	_setup_touch_debug_visuals()
	_debug_touch_zones_visible = SHOW_TOUCH_DEBUG_VISUALS
	_apply_debug_visual_visibility(SHOW_TOUCH_DEBUG_VISUALS)
	_reaction_timer.one_shot = true
	_reaction_timer.timeout.connect(_on_reaction_timer_timeout)

	if _loc != null and _loc.has_signal("locale_changed"):
		_loc.locale_changed.connect(_on_locale_changed)

	_start_idle_animations()
	set_process(false)


func _exit_tree() -> void:
	_kill_all_tweens()
	set_process(false)
	if _loc != null and _loc.has_signal("locale_changed") and _loc.locale_changed.is_connected(_on_locale_changed):
		_loc.locale_changed.disconnect(_on_locale_changed)
	if _reaction_timer != null and _reaction_timer.timeout.is_connected(_on_reaction_timer_timeout):
		_reaction_timer.timeout.disconnect(_on_reaction_timer_timeout)


func _process(_delta: float) -> void:
	if not _speech_visible:
		return
	_face_speech_to_camera()


## Orients the speech label toward the active camera (used when billboard is off).
func _face_speech_to_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _speech_label == null or not is_instance_valid(_speech_label):
		return
	if _speech_label.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		return
	_speech_label.look_at(camera.global_position, Vector3.UP)
	_speech_label.rotate_y(PI)


## Show or hide semi-transparent touch zone meshes (safe if nodes missing).
func set_touch_debug_visuals_visible(show_debug: bool) -> void:
	_debug_touch_zones_visible = show_debug
	_apply_debug_visual_visibility(show_debug)


## Alias for tooling / UI (e.g. Play with I.G.O.R.).
func set_debug_touch_zones_visible(show_zones: bool) -> void:
	set_touch_debug_visuals_visible(show_zones)


func toggle_debug_touch_zones() -> void:
	set_touch_debug_visuals_visible(not _debug_touch_zones_visible)


## Light motion for “Play with I.G.O.R.” joke button (does not emit tap signals).
func play_joke_motion() -> void:
	if _reaction_tween != null and _reaction_tween.is_valid():
		_reaction_tween.kill()
	_anim_head_tap()


## Gentle bounce for song button (does not emit tap signals).
func play_song_bounce() -> void:
	if _reaction_tween != null and _reaction_tween.is_valid():
		_reaction_tween.kill()
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var y0 := _visual_base_y
	_reaction_tween.tween_property(_visual_root, "position:y", y0 + 0.055, 0.22)
	_reaction_tween.tween_property(_visual_root, "position:y", y0, 0.32)


func _apply_debug_visual_visibility(show_debug: bool) -> void:
	for area_name: String in ["HeadArea", "AntennaArea", "ChestArea", "BellyArea", "FeetArea"]:
		var body := _touch_root.get_node_or_null(area_name)
		if body == null:
			continue
		for c: Node in body.get_children():
			if c is MeshInstance3D and str(c.name).begins_with("Debug"):
				(c as MeshInstance3D).visible = show_debug


## Call from parent scene `_unhandled_input` **or** use `set_process_unhandled_input(true)` on this node.
func handle_viewport_pick(event: InputEvent) -> void:
	if not _touch_enabled:
		return
	var pressed := false
	var screen_pos := Vector2.ZERO
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pressed = true
			screen_pos = mb.position
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			pressed = true
			screen_pos = st.position
	if not pressed:
		return

	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec < _touch_cooldown_until_sec:
		return

	if DEBUG_LOGS:
		print("I.G.O.R. input received (ray pick path)")
		print("Mouse / touch at: ", screen_pos)

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		if DEBUG_LOGS:
			print("I.G.O.R.: no active Camera3D on viewport")
		return
	if DEBUG_LOGS:
		print("Using camera: ", camera.name)

	var world := get_world_3d()
	if world == null:
		if DEBUG_LOGS:
			print("I.G.O.R.: no World3D")
		return
	var space := world.direct_space_state
	if space == null:
		if DEBUG_LOGS:
			print("I.G.O.R.: no direct_space_state")
		return

	var ray_o := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var ray_end := ray_o + ray_dir * 2000.0

	var query := PhysicsRayQueryParameters3D.create(ray_o, ray_end)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_from_inside = true

	var hit := space.intersect_ray(query)
	if hit.is_empty():
		if DEBUG_LOGS:
			print("Ray hit nothing")
		return

	var collider: Variant = hit.get("collider")
	if collider == null:
		if DEBUG_LOGS:
			print("Ray hit dict without collider")
		return

	var node: Node = collider as Node
	if node == null:
		return
	if node is CollisionShape3D:
		var cs := node as CollisionShape3D
		var par := cs.get_parent()
		node = par as Node

	var touch_body: Node = _find_igor_touch_body(node)
	if touch_body == null:
		if DEBUG_LOGS:
			var cn := "(null)"
			if node != null:
				cn = node.name
			print("Ray hit non-I.G.O.R. collider: ", cn)
		return

	var reaction_short := str(touch_body.get_meta("reaction", ""))
	if reaction_short == "" or not META_TO_REACTION.has(reaction_short):
		if DEBUG_LOGS:
			print("Touch body missing meta reaction: ", touch_body.name)
		return

	var pair: Array = META_TO_REACTION[reaction_short]
	var reaction_type: String = pair[0]
	var message_key: String = pair[1]
	if DEBUG_LOGS:
		print("Ray hit: ", touch_body.name, " | reaction: ", reaction_short, " → ", reaction_type)
		print("Speech key: ", message_key)

	_touch_cooldown_until_sec = now_sec + REACTION_COOLDOWN_SEC
	_trigger_touch_reaction(reaction_type, message_key)
	get_viewport().set_input_as_handled()


func _find_igor_touch_body(start: Node) -> Node:
	var n: Node = start
	while n != null:
		if n.is_in_group(TOUCH_GROUP):
			return n
		n = n.get_parent()
	return null


func _setup_touch_zones() -> void:
	var specs: Array = [
		["HeadArea", "head"],
		["AntennaArea", "antenna"],
		["ChestArea", "chest"],
		["BellyArea", "belly"],
		["FeetArea", "feet"],
	]
	for spec: Array in specs:
		var node_name: String = spec[0]
		var reaction_short: String = spec[1]
		var body := _touch_root.get_node_or_null(node_name) as StaticBody3D
		if body == null:
			push_warning("IgorCharacter: missing touch body: %s" % node_name)
			continue
		body.collision_layer = 1
		body.collision_mask = 0
		body.input_ray_pickable = false
		body.add_to_group(TOUCH_GROUP)
		body.set_meta("reaction", reaction_short)


func _setup_touch_debug_visuals() -> void:
	var colors: Dictionary = {
		"HeadArea": Color(1, 0.2, 0.2, 0.38),
		"AntennaArea": Color(0.2, 0.85, 1, 0.38),
		"ChestArea": Color(1, 0.85, 0.2, 0.38),
		"BellyArea": Color(0.35, 1, 0.35, 0.38),
		"FeetArea": Color(0.75, 0.35, 1, 0.38),
	}
	var visual_names: Dictionary = {
		"HeadArea": "DebugHeadTouchVisual",
		"AntennaArea": "DebugAntennaTouchVisual",
		"ChestArea": "DebugChestTouchVisual",
		"BellyArea": "DebugBellyTouchVisual",
		"FeetArea": "DebugFeetTouchVisual",
	}
	for area_name: String in colors:
		var parent := _touch_root.get_node_or_null(area_name) as StaticBody3D
		if parent == null:
			continue
		var existing := parent.get_node_or_null(str(visual_names.get(area_name, "DebugTouchVisual")))
		if existing != null:
			continue
		var cs := parent.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = str(visual_names.get(area_name, "DebugTouchVisual"))
		var mat := StandardMaterial3D.new()
		var c: Color = colors[area_name]
		mat.albedo_color = c
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var sh: Shape3D = cs.shape
		if sh is SphereShape3D:
			var sm := SphereMesh.new()
			var sp := sh as SphereShape3D
			sm.radius = sp.radius
			sm.height = sp.radius * 2.0
			sm.radial_segments = 16
			mi.mesh = sm
		elif sh is BoxShape3D:
			var bm := BoxMesh.new()
			bm.size = (sh as BoxShape3D).size
			mi.mesh = bm
		else:
			mi.queue_free()
			continue
		mi.material_override = mat
		parent.add_child(mi)


func _kill_all_tweens() -> void:
	for tw: Tween in [_idle_bob_tween, _antenna_idle_tween, _blink_idle_tween, _reaction_tween]:
		if tw != null and tw.is_valid():
			tw.kill()
	_idle_bob_tween = null
	_antenna_idle_tween = null
	_blink_idle_tween = null
	_reaction_tween = null


func _setup_speech_bubble() -> void:
	_speech_bubble_root = Node3D.new()
	_speech_bubble_root.name = "SpeechBubbleRoot"
	_speech_bubble_root.position = Vector3.ZERO
	_speech_anchor.add_child(_speech_bubble_root)

	_speech_label = Label3D.new()
	_speech_label.name = "SpeechLabel"
	_speech_label.text = ""
	_speech_label.font_size = 28
	_speech_label.pixel_size = 0.0044
	_speech_label.scale = Vector3.ONE
	_speech_label.width = 320.0
	_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.shaded = false
	_speech_label.double_sided = false
	_speech_label.outline_size = 5
	_speech_label.outline_modulate = Color(0.04, 0.04, 0.08, 0.92)
	_speech_label.modulate = Color(0.06, 0.06, 0.09, 1)
	_speech_label.visible = false
	_speech_label.position = Vector3.ZERO
	_speech_bubble_root.add_child(_speech_label)


func _start_idle_animations() -> void:
	if not is_instance_valid(_visual_root):
		return
	_idle_bob_tween = create_tween()
	_idle_bob_tween.set_loops()
	_idle_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var y0 := _visual_base_y
	_idle_bob_tween.tween_property(_visual_root, "position:y", y0 + 0.028, 1.35)
	_idle_bob_tween.tween_property(_visual_root, "position:y", y0, 1.35)

	_antenna_idle_tween = create_tween()
	_antenna_idle_tween.set_loops()
	_antenna_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_antenna_idle_tween.tween_property(_antenna, "rotation:z", _antenna_base_rot.z + 0.12, 2.1)
	_antenna_idle_tween.tween_property(_antenna, "rotation:z", _antenna_base_rot.z - 0.06, 2.1)

	_blink_idle_tween = create_tween()
	_blink_idle_tween.set_loops()
	_blink_idle_tween.tween_interval(3.2)
	_blink_idle_tween.tween_callback(_play_blink)


func _play_blink() -> void:
	if not is_instance_valid(_eye_left) or not is_instance_valid(_eye_right):
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_eye_left, "scale:y", 0.12, 0.06)
	tw.tween_property(_eye_right, "scale:y", 0.12, 0.06)
	tw.chain().set_parallel(true)
	tw.tween_property(_eye_left, "scale:y", 1.0, 0.07)
	tw.tween_property(_eye_right, "scale:y", 1.0, 0.07)


func _on_locale_changed() -> void:
	if is_instance_valid(_chest_label):
		_chest_label.text = _t("IGOR_NAMEPLATE")
	if _speech_visible and _speech_label != null and is_instance_valid(_speech_label):
		var key: String = str(_speech_label.get_meta("speech_key", ""))
		if key != "":
			_speech_label.text = _t(key)


func _t(key: String) -> String:
	if _loc != null and _loc.has_method("t"):
		return str(_loc.call("t", key))
	return key


func _trigger_touch_reaction(reaction_type: String, message_key: String) -> void:
	if _reaction_tween != null and _reaction_tween.is_valid():
		_reaction_tween.kill()
	_reaction_tween = null

	match reaction_type:
		"tap_head":
			_anim_head_tap()
		"tap_antenna":
			_anim_antenna_tap()
		"tap_chest":
			_anim_chest_tap()
		"tap_belly":
			_anim_belly_tap()
		"tap_feet":
			_anim_feet_tap()

	igor_reaction_requested.emit(reaction_type, message_key)
	say(message_key)


func _anim_head_tap() -> void:
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_reaction_tween.tween_property(_head, "rotation:z", _head_base_rot.z + 0.06, 0.1)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x - 0.14, 0.12)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x + 0.04, 0.1)
	_reaction_tween.tween_property(_head, "rotation:z", _head_base_rot.z, 0.14)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x, 0.12)


func _anim_antenna_tap() -> void:
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(_antenna, "position:y", _antenna_base_pos.y + 0.1, 0.1)
	_reaction_tween.parallel().tween_property(_antenna, "rotation:z", _antenna_base_rot.z + 0.62, 0.12)
	_reaction_tween.chain()
	_reaction_tween.set_parallel(true)
	_reaction_tween.tween_property(_antenna, "position:y", _antenna_base_pos.y, 0.35)
	_reaction_tween.tween_property(_antenna, "rotation:z", _antenna_base_rot.z, 0.35)


func _anim_chest_tap() -> void:
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale * 1.22, 0.1)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale * 0.96, 0.1)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale * 1.08, 0.1)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale, 0.2)


func _anim_belly_tap() -> void:
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_reaction_tween.tween_property(_body, "rotation:z", _body_base_rot.z + 0.07, 0.11)
	_reaction_tween.tween_property(_body, "rotation:x", _body_base_rot.x + 0.05, 0.1)
	_reaction_tween.tween_property(_body, "rotation:z", _body_base_rot.z - 0.06, 0.12)
	_reaction_tween.tween_property(_body, "rotation:x", _body_base_rot.x - 0.04, 0.1)
	_reaction_tween.tween_property(_body, "rotation:z", _body_base_rot.z, 0.12)
	_reaction_tween.tween_property(_body, "rotation:x", _body_base_rot.x, 0.12)


func _anim_feet_tap() -> void:
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_reaction_tween.set_parallel(true)
	_reaction_tween.tween_property(_foot_left, "rotation:x", _foot_left_base_rot.x + 0.2, 0.12)
	_reaction_tween.tween_property(_foot_right, "rotation:x", _foot_right_base_rot.x + 0.2, 0.12)
	_reaction_tween.tween_property(_body, "position:y", _body_base_pos.y + 0.038, 0.1)
	_reaction_tween.chain().set_parallel(true)
	_reaction_tween.tween_property(_foot_left, "rotation:x", _foot_left_base_rot.x, 0.18)
	_reaction_tween.tween_property(_foot_right, "rotation:x", _foot_right_base_rot.x, 0.18)
	_reaction_tween.tween_property(_body, "position:y", _body_base_pos.y, 0.18)


func _anim_react_success() -> void:
	if _reaction_tween != null and _reaction_tween.is_valid():
		_reaction_tween.kill()
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_reaction_tween.set_parallel(true)
	_reaction_tween.tween_property(_visual_root, "scale", Vector3(1.08, 1.08, 1.08), 0.14)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale * 1.12, 0.14)
	_reaction_tween.chain().set_parallel(true)
	_reaction_tween.tween_property(_visual_root, "scale", Vector3.ONE, 0.35)
	_reaction_tween.tween_property(_chest_tag, "scale", _chest_base_scale, 0.35)


func _anim_react_failure() -> void:
	if _reaction_tween != null and _reaction_tween.is_valid():
		_reaction_tween.kill()
	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_reaction_tween.set_parallel(true)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x - 0.08, 0.2)
	_reaction_tween.tween_property(_body, "rotation:z", _body_base_rot.z - 0.04, 0.2)
	_reaction_tween.tween_property(_antenna, "rotation:z", _antenna_base_rot.z - 0.08, 0.2)
	_reaction_tween.chain().set_parallel(true)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x + 0.03, 0.26)
	_reaction_tween.tween_property(_body, "rotation:z", _body_base_rot.z, 0.26)
	_reaction_tween.tween_property(_antenna, "rotation:z", _antenna_base_rot.z, 0.26)
	_reaction_tween.chain().set_parallel(true)
	_reaction_tween.tween_property(_head, "rotation:x", _head_base_rot.x, 0.22)


func react_success() -> void:
	_anim_react_success()
	igor_reaction_requested.emit(TYPE_SUCCESS, KEY_SUCCESS)
	say(KEY_SUCCESS)


func react_failure() -> void:
	_anim_react_failure()
	igor_reaction_requested.emit(TYPE_FAIL, KEY_FAIL)
	say(KEY_FAIL)


func say(message_key: String) -> void:
	if _speech_label == null or not is_instance_valid(_speech_label):
		return
	var txt := _t(message_key)
	_speech_label.text = txt
	_speech_label.set_meta("speech_key", message_key)
	_speech_label.visible = true
	_speech_visible = true
	if _speech_label.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
		_face_speech_to_camera()
		set_process(true)
	else:
		set_process(false)
	if DEBUG_LOGS:
		print("I.G.O.R. speech show: ", message_key, " → ", txt)
	if not _reaction_timer.is_stopped():
		_reaction_timer.stop()
	_reaction_timer.wait_time = 2.0
	_reaction_timer.start()


func _on_reaction_timer_timeout() -> void:
	if _speech_label != null and is_instance_valid(_speech_label):
		_speech_label.visible = false
	_speech_visible = false
	set_process(false)


func enable_touch_interactions(enabled: bool) -> void:
	_touch_enabled = enabled

extends CanvasLayer

## Fade simple para cambios de escena (MVP 1.3).
## Autoload recomendado como "SceneTransition".

const DEBUG_LOGS := false

var _rect: ColorRect
var _is_fading: bool = false
var _duration: float = 0.42


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.name = "FadeRect"
	_rect.color = Color(0.05, 0.04, 0.06, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.anchor_left = 0.0
	_rect.anchor_top = 0.0
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	add_child(_rect)

	# Cada vez que cambia la escena, hacemos fade-in automáticamente.
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("fade_in")


func _on_scene_changed() -> void:
	fade_in()


func fade_in() -> void:
	if _rect == null or not is_instance_valid(_rect):
		return
	_rect.visible = true
	_is_fading = true
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_rect, "color:a", 0.0, _duration)
	await tw.finished
	if _rect == null or not is_instance_valid(_rect):
		_is_fading = false
		return
	_is_fading = false
	_rect.visible = false


func fade_to_scene(scene_path: String) -> void:
	if _rect == null or not is_instance_valid(_rect):
		return
	if _is_fading:
		return
	if DEBUG_LOGS:
		print("SceneTransition fade_to_scene: ", scene_path)

	_is_fading = true
	_rect.visible = true

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_rect, "color:a", 1.0, _duration)
	await tw.finished

	if not is_inside_tree():
		_is_fading = false
		return
	var tree := get_tree()
	if tree == null:
		_is_fading = false
		return
	if _rect == null or not is_instance_valid(_rect):
		_is_fading = false
		return

	# Cambiamos escena y el fade_in lo hace el handler de current_scene_changed.
	tree.change_scene_to_file(scene_path)
	_is_fading = false


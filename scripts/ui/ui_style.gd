extends Object
class_name UIStyle

## UI Style Foundation v1
## Lightweight helper that applies theme overrides only when missing.
## Safe to call from scripts without rewriting scene layout or behavior.

const COLOR_TEXT_LIGHT := Color(0.98, 0.98, 0.97, 1)
const COLOR_TEXT_DARK := Color(0.18, 0.12, 0.1, 1)

const COLOR_GREEN := Color(0.32, 0.66, 0.4, 1)
const COLOR_GREEN_P := Color(0.24, 0.52, 0.3, 1)
const COLOR_BLUE := Color(0.36, 0.52, 0.82, 1)
const COLOR_BLUE_P := Color(0.28, 0.4, 0.68, 1)
const COLOR_ORANGE := Color(0.92, 0.58, 0.22, 1)
const COLOR_ORANGE_P := Color(0.76, 0.46, 0.16, 1)
const COLOR_PURPLE := Color(0.52, 0.4, 0.72, 1)
const COLOR_PURPLE_P := Color(0.4, 0.3, 0.58, 1)
const COLOR_DISABLED := Color(0.52, 0.5, 0.54, 1)

const COLOR_PANEL := Color(0.22, 0.18, 0.22, 0.86)
const COLOR_PANEL_BORDER := Color(0.12, 0.1, 0.14, 1)

const RADIUS := 14
const BORDER := 3


static func apply_button_feedback(button: Button) -> void:
	if button == null:
		return
	if button.button_down.is_connected(_on_button_down.bind(button)):
		return
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


static func _on_button_down(button: Button) -> void:
	if button == null:
		return
	button.scale = Vector2(0.97, 0.97)


static func _on_button_up(button: Button) -> void:
	if button == null:
		return
	button.scale = Vector2.ONE


static func style_primary_button(button: Button) -> void:
	_style_button_if_missing(button, COLOR_GREEN, COLOR_GREEN_P, COLOR_TEXT_LIGHT)


static func style_secondary_button(button: Button) -> void:
	_style_button_if_missing(button, COLOR_BLUE, COLOR_BLUE_P, COLOR_TEXT_LIGHT)


static func style_settings_button(button: Button) -> void:
	_style_button_if_missing(button, COLOR_PURPLE, COLOR_PURPLE_P, COLOR_TEXT_LIGHT)


static func style_disabled_button(button: Button) -> void:
	if button == null:
		return
	if not button.has_theme_stylebox_override("disabled"):
		var sb := _make_stylebox(COLOR_DISABLED, COLOR_PANEL_BORDER, RADIUS, BORDER)
		button.add_theme_stylebox_override("disabled", sb)
	if not button.has_theme_color_override("font_disabled_color"):
		button.add_theme_color_override("font_disabled_color", Color(0.92, 0.92, 0.92, 1))


static func style_panel(panel: Control) -> void:
	if panel == null:
		return
	if panel.has_theme_stylebox_override("panel"):
		return
	panel.add_theme_stylebox_override("panel", _make_stylebox(COLOR_PANEL, COLOR_PANEL_BORDER, 16, 4))


static func style_title_label(label: Label) -> void:
	if label == null:
		return
	if not label.has_theme_color_override("font_color"):
		label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1))
	if not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 40)


static func style_body_label(label: Label) -> void:
	if label == null:
		return
	if not label.has_theme_color_override("font_color"):
		label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 1))
	if not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 20)


static func _style_button_if_missing(button: Button, normal_color: Color, pressed_color: Color, font_color: Color) -> void:
	if button == null:
		return
	if not button.has_theme_color_override("font_color"):
		button.add_theme_color_override("font_color", font_color)
	if not button.has_theme_font_size_override("font_size"):
		button.add_theme_font_size_override("font_size", 20)
	if not button.has_theme_stylebox_override("normal"):
		button.add_theme_stylebox_override("normal", _make_stylebox(normal_color, _darken(normal_color), RADIUS, BORDER))
	if not button.has_theme_stylebox_override("pressed"):
		button.add_theme_stylebox_override("pressed", _make_stylebox(pressed_color, _darken(pressed_color), RADIUS, BORDER))
	if not button.has_theme_stylebox_override("hover"):
		button.add_theme_stylebox_override("hover", _make_stylebox(normal_color, _darken(normal_color), RADIUS, BORDER))


static func _make_stylebox(fill: Color, border: Color, radius: int, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	return sb


static func _darken(c: Color) -> Color:
	return Color(max(c.r - 0.18, 0), max(c.g - 0.18, 0), max(c.b - 0.18, 0), 1)


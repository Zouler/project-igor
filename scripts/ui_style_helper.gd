extends Object
class_name UIStyleHelper

## MVP 2.6 — shared sizes for child-friendly UI. Scenes mirror these values in .tscn where noted.

const FONT_HERO := 40
const FONT_TITLE := 34
const FONT_SCREEN_TITLE := 32
const FONT_SECTION := 28
const FONT_SUBTITLE := 22
const FONT_BODY := 21
const FONT_META := 20
const FONT_CARD_TITLE := 23
const FONT_CARD_DESC := 18
const FONT_STATUS := 19
const FONT_HINT := 17
const FONT_FOOTER := 18
const FONT_STEP := 17

const BTN_PRIMARY := Vector2(228, 54)
const BTN_WIDE := Vector2(240, 54)
const BTN_ROW := Vector2(200, 54)

const PANEL_PAD := 16
const UI_SEP := 12
const UI_MARGIN := 24


static func apply_primary_button(b: Button) -> void:
	if b == null:
		return
	b.custom_minimum_size = Vector2(BTN_PRIMARY.x, BTN_PRIMARY.y)
	b.add_theme_font_size_override("font_size", 20)


static func apply_wide_button(b: Button) -> void:
	if b == null:
		return
	b.custom_minimum_size = Vector2(BTN_WIDE.x, BTN_WIDE.y)
	b.add_theme_font_size_override("font_size", 20)


static func apply_compact_button(b: Button, font_size: int = 18) -> void:
	if b == null:
		return
	b.custom_minimum_size = Vector2(BTN_ROW.x, BTN_ROW.y)
	b.add_theme_font_size_override("font_size", font_size)


static func apply_language_button(b: Button) -> void:
	if b == null:
		return
	b.custom_minimum_size = Vector2(124, 42)
	b.add_theme_font_size_override("font_size", 17)

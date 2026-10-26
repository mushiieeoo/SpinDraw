class_name SlotCard
extends Control
## A player slot (P1 / P2): shows the locked-in top as a little pixel icon.
## Tap it to select the slot (a filled slot loads its drawing back for editing).

signal picked(index: int)

var index := 0
var font: Font
var design: TopDesign:
	set(value):
		design = value
		queue_redraw()
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(index)


func _draw() -> void:
	var f: Font = font if font != null else ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Pal.DARK_BLUE)
	var border := Pal.YELLOW if selected else Pal.LAVENDER
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), border, false, 4.0)
	draw_string(f, Vector2(14, 30), "P%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.WHITE)

	if design == null:
		draw_string(f, Vector2(0, size.y * 0.5 + 24), "EMPTY", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Pal.DARK_GRAY)
		return

	# Pixel icon: integer pixel size so it stays crisp
	var mn := Vector2i(9999, 9999)
	var mx := Vector2i(-9999, -9999)
	for c in design.cells:
		mn = mn.min(c)
		mx = mx.max(c)
	var w := mx.x - mn.x + 1
	var h := mx.y - mn.y + 1
	var box := Vector2(96, 96)
	var px := clampi(int(minf(box.x / w, box.y / h)), 1, 8)
	var box_pos := Vector2(14, 42)
	draw_rect(Rect2(box_pos, box), Pal.BLACK.lerp(Pal.DARK_BLUE, 0.4))
	var origin := box_pos + (box - Vector2(w, h) * px) * 0.5
	for c in design.cells:
		draw_rect(Rect2(origin + Vector2(c - mn) * px, Vector2(px, px)), design.color)

	# Info
	var a := design.archetype
	draw_string(f, Vector2(126, 62), GameConst.ARCH_NAMES[a], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GameConst.ARCH_COLORS[a])
	draw_string(f, Vector2(126, 92), "HP %d" % int(design.stats.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.WHITE)
	draw_string(f, Vector2(126, 120), "SPD %d" % int(design.stats.speed), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.WHITE)

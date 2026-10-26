class_name DrawCanvas
extends Control
## The fixed green drawing box. You paint on a 40x40 grid, so every stroke is
## chunky pixel art. Strokes are stored as lists of grid cells.

signal strokes_changed

var font: Font

var _strokes: Array = []                 # Array of Array[Vector2i]
var _current: Array[Vector2i] = []
var _drawing := false
var _hover := Vector2i(-1, -1)


func _ready() -> void:
	size = Vector2(GameConst.MAX_SIZE, GameConst.MAX_SIZE)
	custom_minimum_size = size
	mouse_default_cursor_shape = Control.CURSOR_CROSS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drawing = true
			_current.clear()
			_add_cell(_to_cell(event.position))
		else:
			_end_stroke()
	elif event is InputEventMouseMotion:
		_hover = _to_cell(event.position)
		if _drawing:
			_add_cell(_hover)
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = Vector2i(-1, -1)
		queue_redraw()


func _to_cell(pos: Vector2) -> Vector2i:
	var c := Vector2i((pos / GameConst.GRID).floor())
	return c.clamp(Vector2i.ZERO, Vector2i(GameConst.GRID_N - 1, GameConst.GRID_N - 1))


func _add_cell(c: Vector2i) -> void:
	if _current.is_empty():
		_current.append(c)
	else:
		if _current[-1] == c:
			return
		for cell in ShapeUtils.line_cells(_current[-1], c):
			if not _current.has(cell):
				_current.append(cell)
	strokes_changed.emit()
	queue_redraw()


func _end_stroke() -> void:
	if not _drawing:
		return
	_drawing = false
	if not _current.is_empty():
		_strokes.append(_current.duplicate())
		_current.clear()
	strokes_changed.emit()
	queue_redraw()


func undo() -> void:
	if not _strokes.is_empty():
		_strokes.pop_back()
		strokes_changed.emit()
		queue_redraw()


func clear() -> void:
	_strokes.clear()
	_current.clear()
	_drawing = false
	strokes_changed.emit()
	queue_redraw()


## All painted cells (no duplicates), including the stroke being drawn right now.
func get_cells() -> Array[Vector2i]:
	var seen := {}
	var out: Array[Vector2i] = []
	for stroke in _strokes:
		for c in stroke:
			if not seen.has(c):
				seen[c] = true
				out.append(c)
	for c in _current:
		if not seen.has(c):
			seen[c] = true
			out.append(c)
	return out


func _draw() -> void:
	var g := GameConst.GRID
	var n := GameConst.GRID_N

	# Checkerboard floor
	draw_rect(Rect2(Vector2.ZERO, size), Pal.DARK_GREEN)
	var alt := Pal.DARK_GREEN.lerp(Pal.BLACK, 0.18)
	for y in n:
		for x in n:
			if (x + y) % 2 == 1:
				draw_rect(Rect2(x * g, y * g, g, g), alt)

	# Painted cells: orange base + yellow top-left bevel = tiny 3D pixel block
	var cells := get_cells()
	for c in cells:
		var o := Vector2(c) * g
		draw_rect(Rect2(o, Vector2(g, g)), Pal.ORANGE)
		draw_rect(Rect2(o, Vector2(g - 4, g - 4)), Pal.YELLOW)

	# Hover cursor
	if _hover.x >= 0:
		draw_rect(Rect2(Vector2(_hover) * g, Vector2(g, g)), Pal.WHITE, false, 2.0)

	# Hint text while empty
	if cells.is_empty() and font != null:
		draw_string(font, Vector2(0, size.y * 0.5), "DRAW HERE!",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 32, Pal.GREEN)

	# Frame (inset so it stays inside the box)
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Pal.GREEN, false, 8.0)
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Pal.BLACK, false, 2.0)

extends Node
## Phase 1 screen, built entirely in code:
##   layer 0  world   (background, drawing box, stage, tops)
##   layer 1  pixel   (full-screen pixelate shader over the world)
##   layer 2  ui      (title, buttons, stats) -> stays crisp, above the shader

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"
const PIXEL_SIZE := 4.0
const HINT := "R: CLEAR STAGE   P: PIXEL FX"
const TOP_COLORS := [Pal.RED, Pal.BLUE, Pal.GREEN, Pal.ORANGE, Pal.PINK, Pal.LAVENDER]

var _font: Font
var _canvas: DrawCanvas
var _stage: Stage
var _pixel_rect: ColorRect
var _msg: Label
var _msg_id := 0
var _area_label: Label
var _bars := {}    # stat name -> StatBar
var _vals := {}    # stat name -> Label
var _tops: Array[Top] = []
var _color_i := 0


func _ready() -> void:
	_font = _load_font()
	_build_world()
	_build_pixel_layer()
	_build_ui()
	_canvas.strokes_changed.connect(_refresh_stats)
	get_window().size_changed.connect(_update_pixel_size)
	_update_pixel_size()
	_refresh_stats()


# ---------------------------------------------------------------- building

func _load_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		var f := load(FONT_PATH) as FontFile
		if f != null:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			return f
	push_warning("Pixel font not found at %s - using the default font." % FONT_PATH)
	return ThemeDB.fallback_font


func _build_world() -> void:
	var world := CanvasLayer.new()
	world.layer = 0
	add_child(world)

	var bg := PixelBG.new()
	bg.size = Vector2(1280, 720)
	world.add_child(bg)

	_canvas = DrawCanvas.new()
	_canvas.position = Vector2(20, 60)
	_canvas.font = _font
	world.add_child(_canvas)

	_stage = Stage.new()
	_stage.position = Vector2(680, 60)
	world.add_child(_stage)


func _build_pixel_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_pixel_rect = ColorRect.new()
	_pixel_rect.size = Vector2(1280, 720)
	_pixel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/pixelate.gdshader")
	_pixel_rect.material = mat
	layer.add_child(_pixel_rect)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var ui := Control.new()
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	ui.add_child(_label("TOP CLASH", 32, Pal.YELLOW, Vector2(20, 12), true))
	ui.add_child(_label("DRAW YOUR SPINNING TOP!", 16, Pal.PEACH, Vector2(340, 24), true))

	_msg = _label(HINT, 16, Pal.LIGHT_GRAY, Vector2(680, 410), false)
	ui.add_child(_msg)

	var spawn := _button("SPAWN", Pal.GREEN, Pal.BLACK, Vector2(680, 436))
	spawn.pressed.connect(_on_spawn)
	ui.add_child(spawn)
	var undo := _button("UNDO", Pal.ORANGE, Pal.BLACK, Vector2(880, 436))
	undo.pressed.connect(func(): _canvas.undo())
	ui.add_child(undo)
	var clear := _button("CLEAR", Pal.RED, Pal.WHITE, Vector2(1080, 436))
	clear.pressed.connect(func(): _canvas.clear())
	ui.add_child(clear)

	# Stats panel
	var panel := Panel.new()
	panel.position = Vector2(680, 508)
	panel.size = Vector2(580, 192)
	panel.add_theme_stylebox_override("panel", _box(Pal.DARK_BLUE, Pal.LAVENDER, 4, 4))
	ui.add_child(panel)
	panel.add_child(_label("STATS", 16, Pal.YELLOW, Vector2(16, 14), false))
	_area_label = _label("", 16, Pal.LIGHT_GRAY, Vector2(200, 14), false)
	_area_label.size = Vector2(364, 20)
	_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_area_label)

	var rows := [["HP", Pal.RED], ["MASS", Pal.BLUE], ["SPEED", Pal.GREEN], ["RPM", Pal.ORANGE]]
	for i in rows.size():
		var row: Array = rows[i]
		var key: String = row[0]
		var col: Color = row[1]
		var y := 44.0 + i * 36.0
		panel.add_child(_label(key, 16, Pal.WHITE, Vector2(16, y + 2), false))
		var bar := StatBar.new()
		bar.color = col
		bar.position = Vector2(150, y)
		bar.size = Vector2(276, 20)
		panel.add_child(bar)
		_bars[key] = bar
		var val := _label("-", 16, Pal.WHITE, Vector2(440, y + 2), false)
		panel.add_child(val)
		_vals[key] = val


func _label(text: String, font_size: int, color: Color, pos: Vector2, shadow: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if shadow:
		var off := maxi(2, int(font_size / 8.0))
		l.add_theme_color_override("font_shadow_color", Pal.BLACK)
		l.add_theme_constant_override("shadow_offset_x", off)
		l.add_theme_constant_override("shadow_offset_y", off)
	return l


func _box(fill: Color, border: Color, width: int, bottom: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.border_width_bottom = bottom
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	return sb


func _button(text: String, color: Color, text_color: Color, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(180, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 16)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, text_color)
	b.add_theme_stylebox_override("normal", _box(color, Pal.BLACK, 4, 10))
	b.add_theme_stylebox_override("hover", _box(color.lerp(Pal.WHITE, 0.3), Pal.BLACK, 4, 10))
	var pressed := _box(color.darkened(0.2), Pal.BLACK, 4, 4)
	pressed.content_margin_top = 6
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


# ---------------------------------------------------------------- pixel fx

func _update_pixel_size() -> void:
	# Keep the pixels the same size relative to the game when the window is resized.
	var win := Vector2(get_window().size)
	var s := minf(win.x / 1280.0, win.y / 720.0)
	var mat := _pixel_rect.material as ShaderMaterial
	mat.set_shader_parameter("pixel_size", PIXEL_SIZE * s)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_R:
			_clear_stage()
		KEY_P:
			_pixel_rect.visible = not _pixel_rect.visible


# ---------------------------------------------------------------- gameplay

func _analyze(cells: Array[Vector2i]) -> Dictionary:
	var hull := ShapeUtils.convex_hull(ShapeUtils.cells_to_points(cells, GameConst.GRID))
	if hull.size() < 3:
		return {}
	var ac := ShapeUtils.area_and_centroid(hull)
	ac["hull"] = hull
	return ac


func _on_spawn() -> void:
	var cells := _canvas.get_cells()
	if cells.is_empty():
		_say("DRAW SOMETHING FIRST!", Pal.ORANGE)
		return
	var data := _analyze(cells)
	if data.is_empty() or float(data["area"]) < GameConst.MIN_AREA:
		_say("TOO SMALL! DRAW MORE", Pal.ORANGE)
		return

	var area: float = data["area"]
	var centroid: Vector2 = data["centroid"]
	var hull: PackedVector2Array = data["hull"]
	var stats := TopStats.from_area(area)

	while _tops.size() >= GameConst.MAX_TOPS:
		var old: Top = _tops.pop_front()
		if is_instance_valid(old):
			old.queue_free()

	var top := Top.new()
	top.position = _stage.size / 2.0 + Vector2(randf_range(-80, 80), randf_range(-60, 60))
	var color: Color = TOP_COLORS[_color_i % TOP_COLORS.size()]
	_color_i += 1
	top.setup(cells, hull, centroid, stats, color)
	_stage.add_child(top)
	top.linear_velocity = Vector2.from_angle(randf() * TAU) * stats.speed * 0.6
	_tops.append(top)
	_say("SPAWNED!", Pal.GREEN)


func _clear_stage() -> void:
	for t in _tops:
		if is_instance_valid(t):
			t.queue_free()
	_tops.clear()


func _refresh_stats() -> void:
	var cells := _canvas.get_cells()
	var data: Dictionary = {}
	if not cells.is_empty():
		data = _analyze(cells)
	if data.is_empty():
		_area_label.text = "AREA -"
		for key in _bars:
			_bars[key].value = 0.0
			_vals[key].text = "-"
		return
	var area: float = data["area"]
	var s := TopStats.from_area(area)
	_area_label.text = "AREA %d" % int(area)
	_set_stat("HP", s.size_t, "%d" % int(s.hp))
	_set_stat("MASS", s.size_t, "%.1f" % s.mass)
	_set_stat("SPEED", 1.0 - s.size_t, "%d" % int(s.speed))
	_set_stat("RPM", 1.0 - s.size_t, "%d" % int(s.rpm))


func _set_stat(key: String, norm: float, text: String) -> void:
	_bars[key].value = norm
	_vals[key].text = text


func _say(text: String, color: Color = Pal.PEACH) -> void:
	_msg_id += 1
	var id := _msg_id
	_msg.text = text
	_msg.add_theme_color_override("font_color", color)
	await get_tree().create_timer(2.0).timeout
	if id == _msg_id:
		_msg.text = HINT
		_msg.add_theme_color_override("font_color", Pal.LIGHT_GRAY)

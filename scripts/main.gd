extends Node
## SpinDraw, built entirely in code. Two screens:
##   DRAW   - draw a top, pick an archetype, lock it into slot P1 / P2
##   BATTLE - the hexagon arena, tops move with their MovementAI
## Canvas layers:
##   0 world (background, drawing box, arena)  ->  1 pixelate shader  ->  2 UI (stays crisp)

enum Mode { DRAW, BATTLE }

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"
const PIXEL_SIZE := 4.0
const SCREEN_CENTER := Vector2(640, 360)
const START_POS := [Vector2(-250, 40), Vector2(250, -40)]   # arena-local

var _font: Font
var _mode := Mode.DRAW
var _canvas: DrawCanvas
var _arena: Arena
var _pixel_rect: ColorRect
var _draw_ui: Control
var _battle_ui: Control
var _msg: Label
var _msg_id := 0
var _area_label: Label
var _bars := {}    # stat name -> StatBar
var _vals := {}    # stat name -> Label
var _slots: Array[SlotCard] = []
var _designs: Array[TopDesign] = []
var _arch_buttons: Array[Button] = []
var _p_labels: Array[Label] = []
var _fighters: Array[TopDesign] = []
var _tops: Array[Top] = []
var _slot := 0
var _arch := 0


func _ready() -> void:
	_designs.resize(2)
	_font = _load_font()
	_build_world()
	_build_pixel_layer()
	_build_ui()
	_canvas.strokes_changed.connect(_refresh_stats)
	get_window().size_changed.connect(_update_pixel_size)
	_update_pixel_size()
	_set_mode(Mode.DRAW)
	_select_slot(0)
	_set_arch(0)
	_refresh_stats()


# ================================================================ building

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

	_arena = Arena.new()
	_arena.position = SCREEN_CENTER
	world.add_child(_arena)


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
	_draw_ui = _screen_root(layer)
	_battle_ui = _screen_root(layer)
	_build_draw_ui()
	_build_battle_ui()


func _screen_root(parent: Node) -> Control:
	var c := Control.new()
	c.size = Vector2(1280, 720)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _build_draw_ui() -> void:
	var ui := _draw_ui
	ui.add_child(_label("SPINDRAW", 32, Pal.YELLOW, Vector2(20, 12), true))
	ui.add_child(_label("DRAW YOUR SPINNING TOP!", 16, Pal.PEACH, Vector2(310, 24), true))

	# Slot cards (P1 / P2)
	for i in 2:
		var card := SlotCard.new()
		card.index = i
		card.font = _font
		card.position = Vector2(680 + i * 300, 60)
		card.size = Vector2(280, 148)
		card.picked.connect(_select_slot)
		ui.add_child(card)
		_slots.append(card)

	# Archetype toggle buttons
	var group := ButtonGroup.new()
	for i in 3:
		var b := _button(GameConst.ARCH_NAMES[i], GameConst.ARCH_COLORS[i], Pal.BLACK,
			Vector2(680 + i * 200, 224), Vector2(180, 48), 16, true)
		b.button_group = group
		b.pressed.connect(_set_arch.bind(i))
		ui.add_child(b)
		_arch_buttons.append(b)

	# Message / hint line
	_msg = _label("", 16, Pal.LIGHT_GRAY, Vector2(680, 284), false)
	ui.add_child(_msg)

	# Action buttons
	var lock := _button("LOCK IN", Pal.GREEN, Pal.BLACK, Vector2(680, 316))
	lock.pressed.connect(_on_lock_in)
	ui.add_child(lock)
	var undo := _button("UNDO", Pal.ORANGE, Pal.BLACK, Vector2(880, 316))
	undo.pressed.connect(func(): _canvas.undo())
	ui.add_child(undo)
	var clear := _button("CLEAR", Pal.RED, Pal.WHITE, Vector2(1080, 316))
	clear.pressed.connect(func(): _canvas.clear())
	ui.add_child(clear)

	# Stats panel
	var panel := Panel.new()
	panel.position = Vector2(680, 392)
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

	# FIGHT!
	var fight := _button("FIGHT!", Pal.PINK, Pal.BLACK, Vector2(680, 612), Vector2(580, 88), 32)
	fight.pressed.connect(_start_battle)
	ui.add_child(fight)


func _build_battle_ui() -> void:
	var ui := _battle_ui
	var back := _button("BACK", Pal.ORANGE, Pal.BLACK, Vector2(20, 20), Vector2(160, 56))
	back.pressed.connect(_leave_battle)
	ui.add_child(back)
	var again := _button("REMATCH", Pal.GREEN, Pal.BLACK, Vector2(20, 96), Vector2(160, 56))
	again.pressed.connect(_spawn_fighters)
	ui.add_child(again)

	var l1 := _label("", 16, Pal.WHITE, Vector2(20, 180), true)
	l1.size = Vector2(200, 100)
	ui.add_child(l1)
	var l2 := _label("", 16, Pal.WHITE, Vector2(1060, 180), true)
	l2.size = Vector2(200, 100)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(l2)
	_p_labels = [l1, l2]


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


func _button(text: String, color: Color, text_color: Color, pos: Vector2,
		sz := Vector2(180, 56), font_size := 16, toggle := false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, text_color)
	b.add_theme_stylebox_override("normal", _box(color, Pal.BLACK, 4, 10))
	b.add_theme_stylebox_override("hover", _box(color.lerp(Pal.WHITE, 0.3), Pal.BLACK, 4, 10))
	var pressed := _box(color.darkened(0.25), Pal.BLACK, 4, 4)
	pressed.content_margin_top = 6
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


# ================================================================ pixel fx + keys

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
			if _mode == Mode.BATTLE:
				_spawn_fighters()
		KEY_ESCAPE:
			if _mode == Mode.BATTLE:
				_leave_battle()
		KEY_P:
			_pixel_rect.visible = not _pixel_rect.visible


# ================================================================ screens

func _set_mode(m: Mode) -> void:
	_mode = m
	var battle := m == Mode.BATTLE
	_canvas.visible = not battle
	_draw_ui.visible = not battle
	_arena.visible = battle
	_battle_ui.visible = battle


func _start_battle() -> void:
	if _designs[0] == null and _designs[1] == null:
		_say("LOCK IN A TOP FIRST!", Pal.ORANGE)
		return
	_fighters.clear()
	for i in 2:
		var d: TopDesign = _designs[i]
		if d == null:
			# empty slot -> random CPU opponent
			d = TopDesign.random_cpu(randi() % 3, GameConst.SLOT_COLORS[i])
		_fighters.append(d)
	_set_mode(Mode.BATTLE)
	_spawn_fighters()


func _leave_battle() -> void:
	_clear_tops()
	_set_mode(Mode.DRAW)


func _clear_tops() -> void:
	for t in _tops:
		if is_instance_valid(t):
			t.queue_free()
	_tops.clear()


func _spawn_fighters() -> void:
	_clear_tops()
	for i in 2:
		var d := _fighters[i]
		var top := Top.new()
		top.position = START_POS[i]
		top.setup(d)
		_arena.add_child(top)
		top.ai.center = _arena.global_position
		_tops.append(top)
		_p_labels[i].text = "P%d%s\n%s\nHP %d" % [i + 1, " CPU" if d.is_cpu else "",
			GameConst.ARCH_NAMES[d.archetype], int(d.stats.hp)]
		_p_labels[i].add_theme_color_override("font_color", d.color)
	_tops[0].ai.target = _tops[1]
	_tops[1].ai.target = _tops[0]


# ================================================================ drawing screen logic

func _select_slot(i: int) -> void:
	_slot = i
	for s in _slots:
		s.selected = (s.index == i)
	var d: TopDesign = _designs[i]
	if d != null:
		_canvas.load_cells(d.cells)
		_set_arch(d.archetype)


func _set_arch(a: int) -> void:
	_arch = a
	_arch_buttons[a].button_pressed = true
	_show_hint()


func _on_lock_in() -> void:
	var cells := _canvas.get_cells()
	if cells.is_empty():
		_say("DRAW SOMETHING FIRST!", Pal.ORANGE)
		return
	var col: Color = GameConst.SLOT_COLORS[_slot]
	var d := TopDesign.from_cells(cells, _arch, col)
	if d == null:
		_say("TOO SMALL! DRAW MORE", Pal.ORANGE)
		return
	_designs[_slot] = d
	_slots[_slot].design = d
	_canvas.clear()
	_say("P%d LOCKED IN!" % (_slot + 1), Pal.GREEN)
	var other := 1 - _slot
	if _designs[other] == null:
		_select_slot(other)


func _refresh_stats() -> void:
	var d := TopDesign.from_cells(_canvas.get_cells(), _arch, Pal.WHITE)
	if d == null:
		_area_label.text = "AREA -"
		for key in _bars:
			_bars[key].value = 0.0
			_vals[key].text = "-"
		return
	var s := d.stats
	_area_label.text = "AREA %d" % int(s.area)
	_set_stat("HP", s.size_t, "%d" % int(s.hp))
	_set_stat("MASS", s.size_t, "%.1f" % s.mass)
	_set_stat("SPEED", 1.0 - s.size_t, "%d" % int(s.speed))
	_set_stat("RPM", 1.0 - s.size_t, "%d" % int(s.rpm))


func _set_stat(key: String, norm: float, text: String) -> void:
	_bars[key].value = norm
	_vals[key].text = text


func _show_hint() -> void:
	_msg.text = GameConst.ARCH_DESC[_arch]
	_msg.add_theme_color_override("font_color", Pal.LIGHT_GRAY)


func _say(text: String, color: Color = Pal.PEACH) -> void:
	_msg_id += 1
	var id := _msg_id
	_msg.text = text
	_msg.add_theme_color_override("font_color", color)
	await get_tree().create_timer(2.0).timeout
	if id == _msg_id:
		_show_hint()

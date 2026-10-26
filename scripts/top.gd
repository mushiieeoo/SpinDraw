class_name Top
extends RigidBody2D
## One spinning top. The drawn cells are only the LOOK; the hidden collider is
## the convex hull of the drawing. The area centroid sits at (0,0), so the
## body spins around its own center.

var stats: TopStats
var hp := 0.0
var body_color := Pal.RED

var _cells: Array[Vector2i] = []
var _cell_set := {}
var _centroid := Vector2.ZERO   # in drawing-space pixels
var _spin_dir := 1.0


func setup(p_cells: Array[Vector2i], p_hull: PackedVector2Array, p_centroid: Vector2,
		p_stats: TopStats, p_color: Color) -> void:
	stats = p_stats
	hp = stats.hp
	body_color = p_color
	_cells = p_cells
	_centroid = p_centroid
	for c in _cells:
		_cell_set[c] = true

	# Hidden collider: hull shrunk by BATTLE_SCALE and re-centered on the centroid.
	var pts := PackedVector2Array()
	for p in p_hull:
		pts.append((p - p_centroid) * GameConst.BATTLE_SCALE)
	var shape := ConvexPolygonShape2D.new()
	shape.set_point_cloud(pts)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	# Physics setup
	mass = stats.mass
	gravity_scale = 0.0
	linear_damp = 0.2
	angular_damp = 0.0
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2.ZERO
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.85
	mat.friction = 0.15
	physics_material_override = mat
	collision_layer = GameConst.LAYER_TOPS
	collision_mask = GameConst.LAYER_WALLS | GameConst.LAYER_TOPS

	_spin_dir = 1.0 if randf() < 0.5 else -1.0
	angular_velocity = stats.spin_speed() * _spin_dir
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if stats == null:
		return
	# Tops never stop in this game: ease the spin back and keep a minimum speed.
	angular_velocity = lerpf(angular_velocity, stats.spin_speed() * _spin_dir, 0.03)
	var v := linear_velocity.length()
	var min_v := stats.speed * 0.3
	if v < min_v:
		var dir := linear_velocity.normalized() if v > 1.0 else Vector2.from_angle(randf() * TAU)
		linear_velocity = dir * min_v
	elif v > stats.speed:
		linear_velocity = linear_velocity.normalized() * stats.speed


func _draw() -> void:
	var s := GameConst.GRID * GameConst.BATTLE_SCALE
	var edge := maxf(1.5, s * 0.3)
	var dark := body_color.lerp(Pal.BLACK, 0.55)

	# Pass 1: fill every drawn cell (slightly oversized so there are no seams)
	for c in _cells:
		var o := (Vector2(c) * GameConst.GRID - _centroid) * GameConst.BATTLE_SCALE
		draw_rect(Rect2(o, Vector2(s + 0.6, s + 0.6)), body_color)

	# Pass 2: dark pixel outline on every cell edge that has no neighbour
	for c in _cells:
		var o := (Vector2(c) * GameConst.GRID - _centroid) * GameConst.BATTLE_SCALE
		if not _cell_set.has(c + Vector2i.UP):
			draw_rect(Rect2(o, Vector2(s, edge)), dark)
		if not _cell_set.has(c + Vector2i.DOWN):
			draw_rect(Rect2(o + Vector2(0, s - edge), Vector2(s, edge)), dark)
		if not _cell_set.has(c + Vector2i.LEFT):
			draw_rect(Rect2(o, Vector2(edge, s)), dark)
		if not _cell_set.has(c + Vector2i.RIGHT):
			draw_rect(Rect2(o + Vector2(s - edge, 0), Vector2(edge, s)), dark)

	# Spin marker so you can SEE it rotate: a white core and a nub pointing along +X
	draw_rect(Rect2(Vector2(-s * 0.5, -s * 0.5), Vector2(s, s)), Pal.WHITE)
	draw_rect(Rect2(Vector2(s * 0.5, -s * 0.25), Vector2(s * 1.2, s * 0.5)), Pal.WHITE)

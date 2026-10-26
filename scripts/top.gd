class_name Top
extends RigidBody2D
## One spinning top. The drawn cells are only the LOOK; the hidden collider is
## the convex hull of the drawing. The area centroid sits at (0,0), so the
## body spins around its own center. A MovementAI child decides where it goes.

var design: TopDesign
var stats: TopStats
var hp := 0.0
var max_speed := 0.0
var ai: MovementAI

var _cell_set := {}
var _spin_dir := 1.0


func setup(p_design: TopDesign) -> void:
	design = p_design
	stats = design.stats
	hp = stats.hp
	for c in design.cells:
		_cell_set[c] = true

	# Hidden collider: hull shrunk by BATTLE_SCALE and re-centered on the centroid.
	var pts := PackedVector2Array()
	for p in design.hull:
		pts.append((p - design.centroid) * GameConst.BATTLE_SCALE)
	var shape := ConvexPolygonShape2D.new()
	shape.set_point_cloud(pts)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	# Archetype tweaks (table lives in GameConst)
	var a := design.archetype
	mass = stats.mass * float(GameConst.ARCH_MASS_MULT[a])
	linear_damp = float(GameConst.ARCH_DAMP[a])
	max_speed = stats.speed * float(GameConst.ARCH_SPEED_MULT[a])

	# Physics setup
	gravity_scale = 0.0
	angular_damp = 0.0
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2.ZERO
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.3
	mat.friction = 0.15
	physics_material_override = mat
	collision_layer = GameConst.LAYER_TOPS
	collision_mask = GameConst.MASK_TOP

	_spin_dir = 1.0 if randf() < 0.5 else -1.0
	angular_velocity = stats.spin_speed() * _spin_dir

	# Movement brain
	ai = MovementAI.new()
	ai.archetype = a
	add_child(ai)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if stats == null:
		return
	# Tops never stop spinning: ease the spin back after hits.
	angular_velocity = lerpf(angular_velocity, stats.spin_speed() * _spin_dir, 0.03)
	# Speed cap
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


func _draw() -> void:
	if design == null:
		return
	var s := GameConst.GRID * GameConst.BATTLE_SCALE
	var edge := maxf(1.5, s * 0.3)
	var body_color := design.color
	var dark := body_color.lerp(Pal.BLACK, 0.55)

	# Pass 1: fill every drawn cell (slightly oversized so there are no seams)
	for c in design.cells:
		var o := (Vector2(c) * GameConst.GRID - design.centroid) * GameConst.BATTLE_SCALE
		draw_rect(Rect2(o, Vector2(s + 0.6, s + 0.6)), body_color)

	# Pass 2: dark pixel outline on every cell edge that has no neighbour
	for c in design.cells:
		var o := (Vector2(c) * GameConst.GRID - design.centroid) * GameConst.BATTLE_SCALE
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

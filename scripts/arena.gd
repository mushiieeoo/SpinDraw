class_name Arena
extends Node2D
## Regular hexagon arena centered on this node's origin (0,0).
##  - 6 thick, bouncy StaticBody2D walls whose ends overlap at the corners
##    (nothing can tunnel through a corner)
##  - walls sit OUTSIDE the floor edge, so the floor is the full playing area
##  - no ring-outs: tops can never leave

const WALL_T := 48.0

@export var radius := GameConst.ARENA_RADIUS


func corners() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(Vector2.from_angle(deg_to_rad(60.0 * i)) * radius)
	return pts


func _ready() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = GameConst.LAYER_WALLS
	body.collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.8
	mat.friction = 0.0
	body.physics_material_override = mat
	add_child(body)

	var v := corners()
	for i in 6:
		var a := v[i]
		var b := v[(i + 1) % 6]
		var mid := (a + b) * 0.5
		var shape := RectangleShape2D.new()
		shape.size = Vector2(a.distance_to(b) + WALL_T, WALL_T)   # longer than the edge = overlap
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = mid + mid.normalized() * (WALL_T * 0.5)      # inner face sits on the edge
		cs.rotation = (b - a).angle()
		body.add_child(cs)
	queue_redraw()


func _draw() -> void:
	var v := corners()
	var line_col := Pal.BLUE.lerp(Pal.DARK_BLUE, 0.65)

	# Floor + rings + spokes
	draw_colored_polygon(v, Pal.DARK_BLUE)
	for k in [0.75, 0.5, 0.25]:
		var ring := PackedVector2Array()
		for p in v:
			ring.append(p * k)
		ring.append(ring[0])
		draw_polyline(ring, line_col, 4.0)
	for p in v:
		draw_line(Vector2.ZERO, p, line_col, 4.0)

	# Center pad (the Defense archetype's home)
	var pad := PackedVector2Array()
	for p in v:
		pad.append(p * 0.12)
	draw_colored_polygon(pad, Pal.DARK_PURPLE)

	# Chunky frame just outside the floor edge
	var k_out := (radius + 8.0) / radius
	var frame := PackedVector2Array()
	for p in v:
		frame.append(p * k_out)
	frame.append(frame[0])
	var shadow := PackedVector2Array()
	for p in v:
		shadow.append(p * ((radius + 10.0) / radius))
	shadow.append(shadow[0])
	draw_polyline(shadow, Pal.BLACK, 24.0)
	draw_polyline(frame, Pal.LAVENDER, 16.0)

	# Corner bumpers
	for p in v:
		var q := p * k_out
		draw_rect(Rect2(q - Vector2(16, 16), Vector2(32, 32)), Pal.BLACK)
		draw_rect(Rect2(q - Vector2(12, 12), Vector2(24, 24)), Pal.RED)
		draw_rect(Rect2(q - Vector2(12, 12), Vector2(10, 10)), Pal.PINK)

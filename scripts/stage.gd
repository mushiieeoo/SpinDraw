class_name Stage
extends Node2D
## TEMPORARY rectangular stage so Phase 1 tops have somewhere to bounce.
## Phase 2 replaces this with the hexagon arena.
## The origin (0,0) is the top-left of the playing floor.

@export var size := Vector2(580, 340)

const WALL_T := 40.0


func _ready() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = GameConst.LAYER_WALLS
	body.collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.9
	mat.friction = 0.0
	body.physics_material_override = mat
	add_child(body)

	# 4 thick walls that overlap at the corners so nothing can tunnel out
	_add_wall(body, Vector2(size.x / 2.0, -WALL_T / 2.0), Vector2(size.x + WALL_T * 2.0, WALL_T))
	_add_wall(body, Vector2(size.x / 2.0, size.y + WALL_T / 2.0), Vector2(size.x + WALL_T * 2.0, WALL_T))
	_add_wall(body, Vector2(-WALL_T / 2.0, size.y / 2.0), Vector2(WALL_T, size.y + WALL_T * 2.0))
	_add_wall(body, Vector2(size.x + WALL_T / 2.0, size.y / 2.0), Vector2(WALL_T, size.y + WALL_T * 2.0))


func _add_wall(body: StaticBody2D, center: Vector2, wall_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = center
	body.add_child(cs)


func _draw() -> void:
	var t := 20.0
	draw_rect(Rect2(Vector2.ZERO, size), Pal.DARK_BLUE)
	var alt := Pal.DARK_BLUE.lerp(Pal.BLACK, 0.3)
	for y in int(size.y / t):
		for x in int(size.x / t):
			if (x + y) % 2 == 1:
				draw_rect(Rect2(x * t, y * t, t, t), alt)
	# Chunky frame
	draw_rect(Rect2(Vector2(-4, -4), size + Vector2(8, 8)), Pal.LAVENDER, false, 8.0)
	draw_rect(Rect2(Vector2(-9, -9), size + Vector2(18, 18)), Pal.BLACK, false, 2.0)

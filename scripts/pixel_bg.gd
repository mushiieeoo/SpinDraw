class_name PixelBG
extends Control
## Night-sky checkerboard background with a few twinkly star pixels.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var t := 40.0
	draw_rect(Rect2(Vector2.ZERO, size), Pal.DARK_BLUE.lerp(Pal.BLACK, 0.35))
	var alt := Pal.DARK_BLUE.lerp(Pal.BLACK, 0.5)
	for y in int(size.y / t) + 1:
		for x in int(size.x / t) + 1:
			if (x + y) % 2 == 1:
				draw_rect(Rect2(x * t, y * t, t, t), alt)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var p := Vector2(rng.randi_range(0, int(size.x / 4.0) - 1), rng.randi_range(0, int(size.y / 4.0) - 1)) * 4.0
		var col := Pal.LAVENDER if rng.randf() < 0.7 else Pal.WHITE
		draw_rect(Rect2(p, Vector2(4, 4)), col)

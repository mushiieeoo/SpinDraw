class_name StatBar
extends Control
## A 10-segment pixel stat bar.

const SEGMENTS := 10

var color := Pal.GREEN
var value := 0.0: set = set_value


func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var gap := 4.0
	var w := (size.x - gap * (SEGMENTS - 1)) / SEGMENTS
	var lit := roundi(value * SEGMENTS)
	for i in SEGMENTS:
		var r := Rect2(i * (w + gap), 0, w, size.y)
		draw_rect(r, color if i < lit else Pal.DARK_GRAY)
		draw_rect(r, Pal.BLACK, false, 2.0)

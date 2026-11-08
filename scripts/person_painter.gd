extends Control
## Художник для запекания пешехода сверху: тень, плечи-рубашка, голова (см. baker.gd).

var shirt: Color = Color.WHITE
var skin: Color = Color("e0b48f")


func _draw() -> void:
	var r: float = size.x * 0.3
	var c: Vector2 = size / 2.0
	draw_circle(c + Vector2(r * 0.3, r * 0.45), r * 1.05, Color(0, 0, 0, 0.18))
	draw_circle(c, r, shirt)
	draw_circle(c + Vector2(-r * 0.1, -r * 0.1), r * 0.6, skin)

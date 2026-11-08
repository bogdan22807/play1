extends Control
## Художник для запекания одной машины в текстуру (см. baker.gd и CarArt.texture).

const CarArt := preload("res://scripts/car_art.gd")

var model: String = "old_sedan"
var unit: float = 128.0
var body_override: Color = Color(0, 0, 0, 0)
var dirt: float = 0.0
var broken: bool = false


func _draw() -> void:
	CarArt.draw_car(self, size / 2.0, 0.0, model, unit, body_override, dirt, broken)

extends Control
## Иконка машины для списков: та же машина, что ездит по городу.

const CarArt := preload("res://scripts/car_art.gd")

var model: String = "old_sedan":
	set(value):
		model = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(150, 90)


func _draw() -> void:
	# Каждая модель вписывается в иконку целиком: лимузин мельче, рикша крупнее.
	var info: Dictionary = CarArt.style(model)
	var unit: float = minf(size.x * 0.92 / float(info.get("length", 1.0)), size.y * 0.9 / float(info.get("width", 0.5)))
	CarArt.draw_car(self, size / 2.0 + Vector2(0, -2), 0.0, model, unit)

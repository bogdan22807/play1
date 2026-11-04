# Тесты

Логика игры без экрана. Запуск из папки проекта:

```
godot --headless -s res://tests/test_cars.gd
godot --headless -s res://tests/test_drivers.gd
godot --headless -s res://tests/test_wear.gd
godot --headless -s res://tests/test_shifts.gd
godot --headless -s res://tests/test_helpers.gd
```

В конце печатается `RESULT PASS` или `RESULT FAIL`. Тест стирает сохранение.

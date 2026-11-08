extends RefCounted
## «Запекание» картинок: то, что рисуется сотней фигур, один раз рисуем в текстуру
## (SubViewport с UPDATE_ONCE), а дальше показываем одной картинкой.
##
## Зачем: Godot каждый кадр заново отправляет на видеокарту все фигуры всех видимых
## элементов. Иконка из 40 фигур — это 40 команд каждый кадр, даже если она не меняется.
## Запечённая иконка — одна команда. На слабых телефонах и в браузере это главный тормоз.

static var _cache: Dictionary = {}


## Текстура по ключу. painter — Control, который сам умеет себя нарисовать в _draw();
## он живёт внутри SubViewport. Если такая текстура уже есть — painter не нужен (освобождаем).
static func texture(tree: SceneTree, key: String, pixel_size: Vector2i, painter: Control) -> Texture2D:
	if _cache.has(key):
		painter.free()
		return _cache[key]
	var viewport := SubViewport.new()
	viewport.size = Vector2i(maxi(1, pixel_size.x), maxi(1, pixel_size.y))
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	painter.size = Vector2(viewport.size)
	painter.position = Vector2.ZERO
	viewport.add_child(painter)
	tree.root.add_child.call_deferred(viewport)
	var result: Texture2D = viewport.get_texture()
	_cache[key] = result
	return result


static func has(key: String) -> bool:
	return _cache.has(key)


static func get_cached(key: String) -> Texture2D:
	return _cache.get(key)

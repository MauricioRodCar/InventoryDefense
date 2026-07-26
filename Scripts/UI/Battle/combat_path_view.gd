class_name CombatPathView
extends RefCounted
## Traduce el progreso lógico de un Enemy (path_progress, en el rango
## [0, path.length]) a una posición de mundo, mediante una línea recta entre
## dos puntos. Es la única clase que conoce geometría de escena para el
## camino: CombatPath (dominio) sigue sin saber nada de posiciones.

var _start: Vector2
var _end: Vector2
var _path_length: float

func _init(p_start: Vector2, p_end: Vector2, p_path_length: float) -> void:
	_start = p_start
	_end = p_end
	_path_length = p_path_length

## progress se espera en el mismo rango que Enemy.path_progress. Sin longitud
## de camino (0 o negativa) no hay proporción posible: se ancla al inicio.
func position_for(progress: float) -> Vector2:
	if _path_length <= 0.0:
		return _start
	var ratio := clampf(progress / _path_length, 0.0, 1.0)
	return _start.lerp(_end, ratio)

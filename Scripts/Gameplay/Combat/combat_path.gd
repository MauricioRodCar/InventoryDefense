class_name CombatPath
extends Resource
## Representación puramente lógica del camino fijo que recorren los
## enemigos: solo una longitud total, sin posiciones de mundo. La
## traducción de progreso a posiciones de escena es responsabilidad
## exclusiva de la representación visual (futura).

@export var length: float = 0.0

func _init(p_length: float = 0.0) -> void:
	length = p_length

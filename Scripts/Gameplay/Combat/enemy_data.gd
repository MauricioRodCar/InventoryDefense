class_name EnemyData
extends Resource
## Definición pura de un tipo de enemigo: vida máxima, velocidad y
## resistencia a efectos de estado. No lleva estado de ejecución (eso vive
## en Enemy), así que puede compartirse entre varias entradas del calendario
## de una Wave sin duplicar sus estadísticas.

@export var id: StringName = &""
@export var max_health: int = 0
@export var speed: float = 0.0
@export var status_effect_resistance: float = 0.0

func _init(p_id: StringName = &"", p_max_health: int = 0, p_speed: float = 0.0, p_status_effect_resistance: float = 0.0) -> void:
	id = p_id
	max_health = p_max_health
	speed = p_speed
	status_effect_resistance = p_status_effect_resistance

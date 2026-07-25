class_name WeaponData
extends Resource
## Definición pura de la capacidad ofensiva de un arma: cuánto daño hace y
## cada cuánto puede disparar. No lleva estado de ejecución (eso vive en
## WeaponInstance), así que puede compartirse con seguridad entre varias
## instancias.

@export var id: StringName = &""
@export var damage: int = 0
@export var attack_interval: float = 1.0

func _init(p_id: StringName = &"", p_damage: int = 0, p_attack_interval: float = 1.0) -> void:
	id = p_id
	damage = p_damage
	attack_interval = p_attack_interval

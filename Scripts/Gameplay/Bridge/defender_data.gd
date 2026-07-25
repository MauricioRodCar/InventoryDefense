class_name DefenderData
extends Resource
## Definición pura de un tipo de defensor: qué WeaponData usa. No lleva
## estado de ejecución (eso vive en WeaponInstance/Defender), así que puede
## compartirse entre varias entradas de un DefenderCatalog sin duplicar sus
## estadísticas. Mismo rol que WeaponData/EnemyData en el dominio de Combat.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")

@export var id: StringName = &""
@export var weapon_data: WeaponData

func _init(p_id: StringName = &"", p_weapon_data: WeaponData = null) -> void:
	id = p_id
	weapon_data = p_weapon_data

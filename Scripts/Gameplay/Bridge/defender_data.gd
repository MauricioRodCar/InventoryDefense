class_name DefenderData
extends Resource
## Definición pura de un tipo de defensor: qué WeaponData usa y, opcionalmente,
## qué TargetingPolicy debería componer el Defender que produzca. No lleva
## estado de ejecución (eso vive en WeaponInstance/Defender), así que puede
## compartirse entre varias entradas de un DefenderCatalog sin duplicar sus
## estadísticas. Mismo rol que WeaponData/EnemyData en el dominio de Combat.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const TargetingPolicy = preload("res://Scripts/Gameplay/Combat/targeting_policy.gd")

@export var id: StringName = &""
@export var weapon_data: WeaponData
var targeting_policy: TargetingPolicy

func _init(p_id: StringName = &"", p_weapon_data: WeaponData = null, p_targeting_policy: TargetingPolicy = null) -> void:
	id = p_id
	weapon_data = p_weapon_data
	targeting_policy = p_targeting_policy

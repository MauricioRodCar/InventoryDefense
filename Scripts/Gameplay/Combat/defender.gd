class_name Defender
extends RefCounted
## Instancia de una unidad defensiva colocada en combate. Su capacidad
## ofensiva no le pertenece directamente: la compone a través de una
## WeaponInstance, para no embeber daño ni cadencia de ataque en Defender.
## Su regla de selección de objetivo tampoco le pertenece: la compone a
## través de una TargetingPolicy, para que distintos arquetipos de defensor
## puedan apuntar de forma distinta sin convertir a Defender en una clase
## por tipo de unidad.
##
## Si no se indica targeting_policy, usa HighestProgressTargetingPolicy: la
## misma regla que antes vivía hardcodeada en AttackPhase. Esto mantiene sin
## cambios el comportamiento de cualquier Defender ya construido con solo
## id y weapon_instance (p. ej. DefenderTranslator, en Bridge).

const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const TargetingPolicy = preload("res://Scripts/Gameplay/Combat/targeting_policy.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")

var id: StringName
var weapon_instance: WeaponInstance
var targeting_policy: TargetingPolicy

func _init(p_id: StringName, p_weapon_instance: WeaponInstance, p_targeting_policy: TargetingPolicy = null) -> void:
	id = p_id
	weapon_instance = p_weapon_instance
	targeting_policy = p_targeting_policy if p_targeting_policy != null else HighestProgressTargetingPolicy.new()

class_name WeaponData
extends Resource
## Definición pura de la capacidad ofensiva de un arma: cuánto daño hace,
## cada cuánto puede disparar y qué patrón de impactos produce al atacar
## (weapon_behavior). No lleva estado de ejecución (eso vive en
## WeaponInstance), así que puede compartirse con seguridad entre varias
## instancias. weapon_behavior debe ser stateless por la misma razón: si no
## se indica explícitamente, usa SingleShotWeaponBehavior (el ataque de un
## único impacto que ya existía), igual que Defender defaultea
## targeting_policy a HighestProgressTargetingPolicy cuando no se indica.

const WeaponBehavior = preload("res://Scripts/Gameplay/Combat/weapon_behavior.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")

@export var id: StringName = &""
@export var damage: int = 0
@export var attack_interval: float = 1.0
var weapon_behavior: WeaponBehavior

func _init(p_id: StringName = &"", p_damage: int = 0, p_attack_interval: float = 1.0, p_weapon_behavior: WeaponBehavior = null) -> void:
	id = p_id
	damage = p_damage
	attack_interval = p_attack_interval
	weapon_behavior = p_weapon_behavior if p_weapon_behavior != null else SingleShotWeaponBehavior.new()

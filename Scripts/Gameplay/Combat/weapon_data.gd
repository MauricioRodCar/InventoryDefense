class_name WeaponData
extends Resource
## Definición pura de la capacidad ofensiva de un arma: cuánto daño hace,
## cada cuánto puede disparar, qué patrón de impactos produce al atacar
## (weapon_behavior), su probabilidad/multiplicador de golpe crítico
## (crit_chance/crit_multiplier) y, opcionalmente, qué efecto de estado
## aplica al impactar (status_effect). No lleva estado de ejecución (eso
## vive en WeaponInstance), así que puede compartirse con seguridad entre
## varias instancias. weapon_behavior debe ser stateless por la misma razón:
## si no se indica explícitamente, usa SingleShotWeaponBehavior (el ataque
## de un único impacto que ya existía), igual que Defender defaultea
## targeting_policy a HighestProgressTargetingPolicy cuando no se indica.

const WeaponBehavior = preload("res://Scripts/Gameplay/Combat/weapon_behavior.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")
const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

@export var id: StringName = &""
@export var damage: int = 0
@export var attack_interval: float = 1.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 2.0
var weapon_behavior: WeaponBehavior
var status_effect: StatusEffectData

func _init(p_id: StringName = &"", p_damage: int = 0, p_attack_interval: float = 1.0, p_weapon_behavior: WeaponBehavior = null, p_crit_chance: float = 0.0, p_crit_multiplier: float = 2.0, p_status_effect: StatusEffectData = null) -> void:
	id = p_id
	damage = p_damage
	attack_interval = p_attack_interval
	weapon_behavior = p_weapon_behavior if p_weapon_behavior != null else SingleShotWeaponBehavior.new()
	crit_chance = p_crit_chance
	crit_multiplier = p_crit_multiplier
	status_effect = p_status_effect

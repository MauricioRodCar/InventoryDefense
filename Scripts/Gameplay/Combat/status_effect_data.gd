class_name StatusEffectData
extends Resource
## Definición pura de un efecto de estado (quemadura, veneno, ...): daño por
## tick, cada cuánto tickea y cuánto dura. No lleva estado de ejecución (eso
## vive en StatusEffectInstance), así que puede compartirse entre múltiples
## WeaponData sin duplicar sus valores. Quemadura y veneno no son subclases
## distintas: son dos instancias de esta misma clase con distintos valores,
## mismo criterio que dos tipos de enemigo son dos EnemyData, no dos clases.

@export var id: StringName = &""
@export var damage_per_tick: int = 0
@export var tick_interval: float = 1.0
@export var duration: float = 0.0

func _init(p_id: StringName = &"", p_damage_per_tick: int = 0, p_tick_interval: float = 1.0, p_duration: float = 0.0) -> void:
	id = p_id
	damage_per_tick = p_damage_per_tick
	tick_interval = p_tick_interval
	duration = p_duration

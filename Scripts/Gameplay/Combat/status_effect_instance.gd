class_name StatusEffectInstance
extends RefCounted
## Instancia en ejecución de un StatusEffectData aplicado a un Enemy
## concreto. Mismo patrón Definition -> Runtime Instance que
## WeaponData/WeaponInstance. damage_per_tick ya viene ajustado por
## resistencia al aplicarse (ver Enemy._apply_status_effect), no se
## recalcula en cada tick porque la resistencia de un enemigo no cambia
## durante la batalla.

const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

var status_effect_data: StatusEffectData
var damage_per_tick: int
var time_until_next_tick: float
var remaining_duration: float

func _init(p_status_effect_data: StatusEffectData, p_damage_per_tick: int) -> void:
	status_effect_data = p_status_effect_data
	damage_per_tick = p_damage_per_tick
	time_until_next_tick = p_status_effect_data.tick_interval
	remaining_duration = p_status_effect_data.duration

## Uso interno de Enemy: avanza delta, devuelve el daño de este tick (0 si
## todavía no tocaba tickear).
func _tick(delta: float) -> int:
	remaining_duration -= delta
	time_until_next_tick -= delta
	if time_until_next_tick > 0.0:
		return 0
	time_until_next_tick += status_effect_data.tick_interval
	return damage_per_tick

func is_expired() -> bool:
	return remaining_duration <= 0.0

class_name WeaponInstance
extends RefCounted
## Instancia concreta de un WeaponData en uso durante la simulación: lleva
## el cooldown restante hasta el próximo ataque posible. No decide cuándo
## atacar ni contra quién: eso es responsabilidad de AttackPhase (futuro).
## Al no compartir estado con WeaponData, varias WeaponInstance pueden
## referenciar el mismo WeaponData sin interferir entre sí.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")

var weapon_data: WeaponData
var cooldown_remaining: float = 0.0

func _init(p_weapon_data: WeaponData) -> void:
	weapon_data = p_weapon_data

func is_ready() -> bool:
	return cooldown_remaining <= 0.0

## Uso interno de AttackPhase: avanza el cooldown, nunca por debajo de cero.
func _tick(delta: float) -> void:
	cooldown_remaining = max(0.0, cooldown_remaining - delta)

## Uso interno de AttackPhase: se llama tras disparar, reinicia el cooldown.
func _reset_cooldown() -> void:
	cooldown_remaining = weapon_data.attack_interval

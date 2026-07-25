class_name Defender
extends RefCounted
## Instancia de una unidad defensiva colocada en combate. Su capacidad
## ofensiva no le pertenece directamente: la compone a través de una
## WeaponInstance, para no embeber daño ni cadencia de ataque en Defender.

const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")

var id: StringName
var weapon_instance: WeaponInstance

func _init(p_id: StringName, p_weapon_instance: WeaponInstance) -> void:
	id = p_id
	weapon_instance = p_weapon_instance

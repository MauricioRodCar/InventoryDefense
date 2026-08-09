class_name DefenderTranslator
extends RefCounted
## Algoritmo sin estado ni propiedad del dominio: traduce una InventoryPiece
## en un Defender listo para combate, consultando un DefenderCatalog. No
## conoce InventoryGrid ni CombatSimulation, y no es dueño del Defender que
## crea: quien lo llama decide qué hacer con el resultado. Mismo estilo que
## MovementPhase/AttackPhase: recibe datos, devuelve un resultado, no muta
## nada fuera de lo que crea.
##
## Usa piece.id como clave de tipo en el catálogo. InventoryPiece.id mezcla
## hoy identidad de instancia e identidad de tipo (deuda técnica documentada
## en el README); esta clase asume temporalmente que cada tipo de pieza
## ofrecida es único por id, igual que InventoryPieceSourceSandbox.

const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")

## Devuelve un Defender nuevo con su propia WeaponInstance, o null si
## piece.id no tiene ningún DefenderData asociado en el catálogo.
func translate(piece: InventoryPiece, catalog: DefenderCatalog) -> Defender:
	var defender_data := catalog.get_defender_data(piece.id)
	if defender_data == null:
		return null
	var weapon_instance := WeaponInstance.new(defender_data.weapon_data)
	return Defender.new(defender_data.id, weapon_instance, defender_data.targeting_policy)

class_name DefenderCatalog
extends Resource
## Mapeo puro entre una clave de tipo de InventoryPiece y el DefenderData que
## debería producir en combate. No conoce InventoryPiece, InventoryGrid,
## Defender ni CombatSimulation: solo asocia claves con definiciones, igual
## que WaveData asocia tiempos con EnemyData sin conocer Wave ni Enemy.

const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")

## Una entrada del catálogo: qué DefenderData corresponde a una clave de tipo.
class Entry:
	extends RefCounted
	var piece_type_id: StringName
	var defender_data: DefenderData

	func _init(p_piece_type_id: StringName, p_defender_data: DefenderData) -> void:
		piece_type_id = p_piece_type_id
		defender_data = p_defender_data

var _entries: Dictionary = {} # StringName -> DefenderData

func _init(p_entries: Array[Entry] = []) -> void:
	for entry in p_entries:
		_entries[entry.piece_type_id] = entry.defender_data

## Devuelve el DefenderData asociado a piece_type_id, o null si no hay ninguna entrada para esa clave.
func get_defender_data(piece_type_id: StringName) -> DefenderData:
	return _entries.get(piece_type_id)

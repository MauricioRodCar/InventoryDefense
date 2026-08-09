class_name DefenderCatalog
extends Resource
## Mapeo puro entre una clave (tipo de InventoryPiece, rank) y el DefenderData
## que debería producir en combate. No conoce InventoryPiece, InventoryGrid,
## Defender ni CombatSimulation: solo asocia claves con definiciones, igual
## que WaveData asocia tiempos con EnemyData sin conocer Wave ni Enemy.

const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")

## Una entrada del catálogo: qué DefenderData corresponde a una clave de tipo + rank.
class Entry:
	extends RefCounted
	var piece_type_id: StringName
	var defender_data: DefenderData
	var rank: int

	func _init(p_piece_type_id: StringName, p_defender_data: DefenderData, p_rank: int) -> void:
		piece_type_id = p_piece_type_id
		defender_data = p_defender_data
		rank = p_rank

var _entries: Dictionary = {} # StringName -> Dictionary[int, DefenderData]

func _init(p_entries: Array[Entry] = []) -> void:
	for entry in p_entries:
		if not _entries.has(entry.piece_type_id):
			_entries[entry.piece_type_id] = {} as Dictionary[int, DefenderData]
		_entries[entry.piece_type_id][entry.rank] = entry.defender_data

## Devuelve el DefenderData asociado a (piece_type_id, rank), o null si falta cualquiera de los dos niveles.
func get_defender_data(piece_type_id: StringName, rank: int) -> DefenderData:
	if not _entries.has(piece_type_id):
		return null
	var by_rank: Dictionary = _entries[piece_type_id]
	return by_rank.get(rank)

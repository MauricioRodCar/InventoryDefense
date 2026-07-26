class_name EnemyRewardCatalog
extends Resource
## Mapeo puro entre EnemyData.id y el oro que debería otorgar al derrotarlo.
## No conoce Enemy, CombatSimulation ni PlayerEconomy: solo asocia claves con
## recompensas, igual que DefenderCatalog asocia claves de InventoryPiece con
## DefenderData sin conocer InventoryPiece ni Defender.

## Una entrada del catálogo: qué recompensa en oro corresponde a un id de EnemyData.
class Entry:
	extends RefCounted
	var enemy_id: StringName
	var gold_reward: int

	func _init(p_enemy_id: StringName, p_gold_reward: int) -> void:
		enemy_id = p_enemy_id
		gold_reward = p_gold_reward

var _rewards: Dictionary = {} # StringName -> int

func _init(p_entries: Array[Entry] = []) -> void:
	for entry in p_entries:
		_rewards[entry.enemy_id] = entry.gold_reward

## Devuelve el oro asociado a enemy_id, o 0 si no hay ninguna entrada para esa clave.
func get_gold_reward(enemy_id: StringName) -> int:
	return _rewards.get(enemy_id, 0)

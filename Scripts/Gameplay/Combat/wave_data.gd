class_name WaveData
extends Resource
## Definición pura del calendario de aparición de una oleada: una lista de
## instantes de spawn, cada uno referenciando un EnemyData (sin duplicar sus
## estadísticas). No lleva estado de ejecución (eso vive en Wave), así que
## puede compartirse/reutilizarse entre varias instancias de Wave.

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")

## Una entrada del calendario: en qué instante (offset en segundos desde el
## inicio de la oleada) debería aparecer qué tipo de enemigo.
class SpawnEntry:
	extends RefCounted
	var time: float
	var enemy_data: EnemyData

	func _init(p_time: float, p_enemy_data: EnemyData) -> void:
		time = p_time
		enemy_data = p_enemy_data

var spawn_entries: Array[SpawnEntry] = []

## Las entradas se ordenan por tiempo ascendente al construir: Wave asume
## esa invariante para poder consumirlas con un único cursor, sin tener que
## reordenar ni reescanear el calendario completo en cada advance().
func _init(p_spawn_entries: Array[SpawnEntry] = []) -> void:
	spawn_entries = p_spawn_entries.duplicate()
	spawn_entries.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)

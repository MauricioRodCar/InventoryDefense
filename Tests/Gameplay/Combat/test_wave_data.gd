extends RefCounted
## Tests básicos de WaveData: calendario de spawn ordenado, sin duplicar
## estadísticas de enemigos (esas viven en EnemyData).

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")

func test_ordena_las_entradas_por_tiempo_ascendente(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var orc := EnemyData.new(&"orc", 20, 0.5)
	var wave_data := WaveData.new([
		WaveData.SpawnEntry.new(2.0, orc),
		WaveData.SpawnEntry.new(0.5, goblin),
	])

	t.assert_eq(wave_data.spawn_entries[0].enemy_data, goblin, "la entrada con menor tiempo debe quedar primero")
	t.assert_eq(wave_data.spawn_entries[1].enemy_data, orc, "la entrada con mayor tiempo debe quedar después")

func test_una_entrada_referencia_su_enemy_data_sin_duplicar_estadisticas(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var entry := WaveData.SpawnEntry.new(1.0, goblin)

	t.assert_eq(entry.time, 1.0, "SpawnEntry debe guardar el tiempo indicado")
	t.assert_eq(entry.enemy_data, goblin, "SpawnEntry debe referenciar el EnemyData indicado, no copiar sus valores")

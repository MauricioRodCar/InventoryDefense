extends RefCounted
## Tests básicos de Wave: libera EnemyData según su calendario sin crear
## Enemy ni depender de CombatSimulation.

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const Wave = preload("res://Scripts/Gameplay/Combat/wave.gd")

func test_una_wave_sin_entradas_termina_en_el_primer_advance(t) -> void:
	var wave := Wave.new(WaveData.new([]))

	var result := wave.advance(1.0)

	t.assert_eq(result.spawned_entries.size(), 0, "una Wave sin entradas no debe liberar ningún EnemyData")
	t.assert_true(result.finished, "una Wave sin entradas debe quedar finalizada desde el primer advance")

func test_advance_no_libera_una_entrada_antes_de_su_tiempo(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(2.0, goblin)]))

	var result := wave.advance(1.0)

	t.assert_eq(result.spawned_entries.size(), 0, "una entrada no debe liberarse antes de que elapsed_time alcance su tiempo")
	t.assert_true(not result.finished, "la Wave no debe estar finalizada mientras queden entradas pendientes")

func test_advance_libera_una_entrada_al_alcanzar_su_tiempo(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(1.0, goblin)]))

	wave.advance(0.6)
	var result := wave.advance(0.4)

	t.assert_eq(result.spawned_entries, [goblin], "la entrada debe liberarse en el advance donde elapsed_time alcanza su tiempo")
	t.assert_true(result.finished, "la Wave debe quedar finalizada tras liberar su última entrada")

func test_advance_libera_varias_entradas_alcanzadas_en_un_unico_delta(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var orc := EnemyData.new(&"orc", 20, 0.5)
	var wave := Wave.new(WaveData.new([
		WaveData.SpawnEntry.new(0.5, goblin),
		WaveData.SpawnEntry.new(1.0, orc),
	]))

	var result := wave.advance(5.0)

	t.assert_eq(result.spawned_entries, [goblin, orc], "un delta grande debe liberar, en orden, todas las entradas alcanzadas")
	t.assert_true(result.finished, "la Wave debe quedar finalizada cuando el delta agota todo el calendario")

func test_advance_no_vuelve_a_liberar_una_entrada_ya_consumida(t) -> void:
	var goblin := EnemyData.new(&"goblin", 10, 1.0)
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(0.5, goblin)]))

	wave.advance(1.0)
	var result := wave.advance(1.0)

	t.assert_eq(result.spawned_entries.size(), 0, "una entrada ya liberada no debe volver a aparecer en un advance posterior")
	t.assert_true(result.finished, "la Wave debe seguir finalizada una vez agotado el calendario")

extends RefCounted
## Tests básicos de EnemyData: definición pura de vida máxima, velocidad y
## resistencia a efectos de estado.

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")

func test_guarda_los_valores_indicados(t) -> void:
	var enemy_data := EnemyData.new(&"goblin", 10, 2.5)
	t.assert_eq(enemy_data.id, &"goblin", "EnemyData debe guardar el id indicado")
	t.assert_eq(enemy_data.max_health, 10, "EnemyData debe guardar la vida máxima indicada")
	t.assert_eq(enemy_data.speed, 2.5, "EnemyData debe guardar la velocidad indicada")

func test_sin_indicar_status_effect_resistance_queda_en_cero(t) -> void:
	var enemy_data := EnemyData.new(&"goblin", 10, 2.5)
	t.assert_eq(enemy_data.status_effect_resistance, 0.0, "sin indicar status_effect_resistance, EnemyData debe defaultear a 0.0")

func test_guarda_status_effect_resistance_indicado_explicitamente(t) -> void:
	var enemy_data := EnemyData.new(&"goblin", 10, 2.5, 0.3)
	t.assert_eq(enemy_data.status_effect_resistance, 0.3, "EnemyData debe guardar el status_effect_resistance indicado")

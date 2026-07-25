extends RefCounted
## Tests básicos de EnemyData: definición pura de vida máxima y velocidad.

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")

func test_guarda_los_valores_indicados(t) -> void:
	var enemy_data := EnemyData.new(&"goblin", 10, 2.5)
	t.assert_eq(enemy_data.id, &"goblin", "EnemyData debe guardar el id indicado")
	t.assert_eq(enemy_data.max_health, 10, "EnemyData debe guardar la vida máxima indicada")
	t.assert_eq(enemy_data.speed, 2.5, "EnemyData debe guardar la velocidad indicada")

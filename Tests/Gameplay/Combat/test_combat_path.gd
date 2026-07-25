extends RefCounted
## Tests básicos de CombatPath: almacena la longitud lógica del camino.

const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")

func test_guarda_la_longitud_indicada(t) -> void:
	var path := CombatPath.new(10.0)
	t.assert_eq(path.length, 10.0, "CombatPath debe guardar la longitud pasada al construirse")

func test_longitud_por_defecto_es_cero(t) -> void:
	var path := CombatPath.new()
	t.assert_eq(path.length, 0.0, "sin longitud indicada, CombatPath debe quedar en 0.0")

extends RefCounted
## Tests básicos de PlayerEconomy: acumulación de oro y señal gold_changed.

const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")

func test_empieza_con_cero_oro(t) -> void:
	var economy := PlayerEconomy.new()

	t.assert_eq(economy.get_gold(), 0, "el oro inicial debe ser 0")

func test_add_gold_acumula_el_oro(t) -> void:
	var economy := PlayerEconomy.new()

	economy.add_gold(10)
	economy.add_gold(5)

	t.assert_eq(economy.get_gold(), 15, "el oro debe acumularse entre llamadas")

func test_add_gold_emite_gold_changed_con_el_nuevo_total(t) -> void:
	var economy := PlayerEconomy.new()
	var emitted_amounts: Array = []
	economy.gold_changed.connect(func(new_amount): emitted_amounts.append(new_amount))

	economy.add_gold(10)
	economy.add_gold(5)

	t.assert_eq(emitted_amounts, [10, 15], "gold_changed debe emitirse una vez por llamada con el total acumulado")

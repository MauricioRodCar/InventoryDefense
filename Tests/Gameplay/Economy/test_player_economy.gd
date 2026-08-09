extends RefCounted
## Tests básicos de PlayerEconomy: acumulación y gasto de oro, señal gold_changed.

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

func test_spend_gold_descuenta_cuando_alcanza(t) -> void:
	var economy := PlayerEconomy.new()
	economy.add_gold(10)

	var result := economy.spend_gold(4)

	t.assert_eq(result, true, "spend_gold debe devolver true cuando el oro alcanza")
	t.assert_eq(economy.get_gold(), 6, "spend_gold debe descontar el monto gastado")

func test_spend_gold_falla_sin_mutar_cuando_no_alcanza(t) -> void:
	var economy := PlayerEconomy.new()
	economy.add_gold(5)

	var result := economy.spend_gold(10)

	t.assert_eq(result, false, "spend_gold debe devolver false cuando el oro no alcanza")
	t.assert_eq(economy.get_gold(), 5, "spend_gold no debe mutar el oro cuando falla")

func test_spend_gold_emite_gold_changed_solo_cuando_tiene_exito(t) -> void:
	var economy := PlayerEconomy.new()
	economy.add_gold(5)
	var emitted_amounts: Array = []
	economy.gold_changed.connect(func(new_amount): emitted_amounts.append(new_amount))

	economy.spend_gold(3)
	economy.spend_gold(10)

	t.assert_eq(emitted_amounts, [2], "gold_changed solo debe emitirse en el gasto exitoso")

func test_can_afford_refleja_el_oro_disponible(t) -> void:
	var economy := PlayerEconomy.new()
	economy.add_gold(10)

	t.assert_eq(economy.can_afford(10), true, "can_afford debe ser true cuando el monto es igual al oro disponible")
	t.assert_eq(economy.can_afford(11), false, "can_afford debe ser false cuando el monto supera el oro disponible")

extends RefCounted
## Tests básicos de DraftPool: sorteo con reemplazo por ruleta ponderada vía
## draw_options.

const DraftOption = preload("res://Scripts/Gameplay/Draft/draft_option.gd")
const DraftPool = preload("res://Scripts/Gameplay/Draft/draft_pool.gd")

func test_draw_options_devuelve_exactamente_count_elementos(t) -> void:
	var option_a := DraftOption.new()
	var option_b := DraftOption.new()
	var pool := DraftPool.new([DraftPool.Entry.new(option_a, 1.0), DraftPool.Entry.new(option_b, 1.0)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	var result := pool.draw_options(5, rng)

	t.assert_eq(result.size(), 5, "draw_options debe devolver exactamente count elementos")

func test_draw_options_nunca_devuelve_una_entry_de_peso_cero(t) -> void:
	var zero_weight_option := DraftOption.new()
	var other_option := DraftOption.new()
	var pool := DraftPool.new([
		DraftPool.Entry.new(zero_weight_option, 0.0),
		DraftPool.Entry.new(other_option, 1.0),
	])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var saw_zero_weight_option := false

	for i in 200:
		var result := pool.draw_options(1, rng)
		if result[0] == zero_weight_option:
			saw_zero_weight_option = true

	t.assert_true(not saw_zero_weight_option, "una entry de peso 0.0 nunca debe aparecer entre los resultados")

func test_draw_options_con_una_unica_entry_siempre_la_devuelve(t) -> void:
	var only_option := DraftOption.new()
	var pool := DraftPool.new([DraftPool.Entry.new(only_option, 3.0)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var all_matched := true

	for i in 20:
		var result := pool.draw_options(1, rng)
		if result[0] != only_option:
			all_matched = false

	t.assert_true(all_matched, "un pool de una única entry siempre debe devolver esa opción")

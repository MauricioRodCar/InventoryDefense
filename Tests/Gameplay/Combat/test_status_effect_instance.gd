extends RefCounted
## Tests básicos de StatusEffectInstance: instancia en ejecución de un
## StatusEffectData, tickea daño repetido y expira tras su duración.

const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")
const StatusEffectInstance = preload("res://Scripts/Gameplay/Combat/status_effect_instance.gd")

func test_tick_devuelve_cero_antes_de_cumplirse_el_intervalo(t) -> void:
	var data := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var instance := StatusEffectInstance.new(data, 3)

	var damage := instance._tick(0.5)

	t.assert_eq(damage, 0, "antes de que pase tick_interval, _tick no debe producir daño")

func test_tick_devuelve_damage_per_tick_al_cumplirse_el_intervalo(t) -> void:
	var data := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var instance := StatusEffectInstance.new(data, 3)

	var damage := instance._tick(1.0)

	t.assert_eq(damage, 3, "al cumplirse tick_interval, _tick debe devolver damage_per_tick")

func test_is_expired_es_falso_mientras_quede_duracion(t) -> void:
	var data := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var instance := StatusEffectInstance.new(data, 3)

	instance._tick(2.0)

	t.assert_true(not instance.is_expired(), "mientras remaining_duration sea mayor a 0, el efecto no debe estar expirado")

func test_is_expired_es_verdadero_cuando_se_agota_la_duracion(t) -> void:
	var data := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var instance := StatusEffectInstance.new(data, 3)

	instance._tick(4.0)

	t.assert_true(instance.is_expired(), "al agotarse remaining_duration, el efecto debe estar expirado")

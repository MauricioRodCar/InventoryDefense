class_name Wave
extends RefCounted
## Instancia en ejecución de un WaveData: lleva su propio reloj interno
## (elapsed_time) y un cursor de qué entradas del calendario ya se
## consumieron. Responde una única pregunta vía advance(delta): qué
## EnemyData deberían aparecer ahora. No crea Enemy, no conoce
## CombatSimulation ni Defender, no mueve enemigos, no aplica daño y no
## emite señales: solo devuelve un resultado como dato para que
## CombatSimulation decida qué hacer con él.

const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")

## Resultado de un advance: qué EnemyData deberían aparecer ahora
## (spawned_entries) y si la oleada ya agotó todo su calendario (finished).
## finished permite que CombatSimulation sepa que la oleada terminó sin
## tener que preguntar continuamente is_finished(); deja preparado el
## camino para una futura señal wave_completed sin necesitar polling.
class AdvanceResult:
	extends RefCounted
	var spawned_entries: Array[EnemyData]
	var finished: bool

	func _init(p_spawned_entries: Array[EnemyData], p_finished: bool) -> void:
		spawned_entries = p_spawned_entries
		finished = p_finished

var wave_data: WaveData
var elapsed_time: float = 0.0

var _next_index: int = 0

func _init(p_wave_data: WaveData) -> void:
	wave_data = p_wave_data

## Acumula delta en el reloj interno y libera, en orden, todas las entradas
## cuyo tiempo ya se alcanzó desde la última llamada.
func advance(delta: float) -> AdvanceResult:
	elapsed_time += delta
	var spawned_entries: Array[EnemyData] = []
	var entries := wave_data.spawn_entries
	while _next_index < entries.size() and entries[_next_index].time <= elapsed_time:
		spawned_entries.append(entries[_next_index].enemy_data)
		_next_index += 1
	return AdvanceResult.new(spawned_entries, _next_index >= entries.size())

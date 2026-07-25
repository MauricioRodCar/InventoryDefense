class_name CombatSimulation
extends RefCounted
## Única autoridad del dominio de combate: dueña de los enemigos y
## defensores activos y del CombatPath de la ronda, y único punto de la
## simulación que muta entidades de dominio (Enemy, Defender,
## WeaponInstance). MovementPhase y AttackPhase son algoritmos sin estado
## ni propiedad del dominio: reciben colecciones como parámetros y
## devuelven resultados; CombatSimulation decide si los aplica, y es el
## único emisor de señales de combate.
##
## No sabe nada de Wave, spawn de enemigos, InventoryGrid, UI, animaciones,
## proyectiles, efectos de estado, resistencias, alcance ni recompensas:
## esta iteración asume que enemigos y defensores ya existen y se añaden
## desde fuera vía add_enemy/add_defender.

const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const MovementPhase = preload("res://Scripts/Gameplay/Combat/movement_phase.gd")
const AttackPhase = preload("res://Scripts/Gameplay/Combat/attack_phase.gd")

signal enemy_reached_end(enemy: Enemy)
signal enemy_defeated(enemy: Enemy)
signal defender_attacked(defender: Defender, target: Enemy, damage: int)

var _path: CombatPath
var _enemies: Array[Enemy] = []
var _defenders: Array[Defender] = []
var _movement_phase: MovementPhase
var _attack_phase: AttackPhase

func _init(p_path: CombatPath) -> void:
	_path = p_path
	_movement_phase = MovementPhase.new()
	_attack_phase = AttackPhase.new()

func add_enemy(enemy: Enemy) -> void:
	_enemies.append(enemy)

func add_defender(defender: Defender) -> void:
	_defenders.append(defender)

func get_enemies() -> Array[Enemy]:
	return _enemies.duplicate()

func get_defenders() -> Array[Defender]:
	return _defenders.duplicate()

## Avanza la simulación un paso determinista: mueve enemigos, resuelve los
## que llegaron al final del camino, tickea cooldowns, resuelve ataques y
## resuelve enemigos derrotados. Único método de todo el dominio de combate
## que termina aplicando mutaciones sobre Enemy/Defender/WeaponInstance.
func advance(delta: float) -> void:
	_apply_movement(delta)
	_resolve_reached_end()
	_resolve_attacks(delta)
	_resolve_defeated()

func _apply_movement(delta: float) -> void:
	for result in _movement_phase.advance(_enemies, delta):
		result.enemy._advance(result.delta_progress)

func _resolve_reached_end() -> void:
	var reached_end: Array[Enemy] = []
	for enemy in _enemies:
		if enemy.path_progress >= _path.length:
			reached_end.append(enemy)
	for enemy in reached_end:
		_enemies.erase(enemy)
		enemy_reached_end.emit(enemy)

## El cooldown de cada WeaponInstance avanza aquí, antes de que AttackPhase
## decida quién ataca: es tiempo pasando, no una decisión de combate.
func _resolve_attacks(delta: float) -> void:
	for defender in _defenders:
		defender.weapon_instance._tick(delta)
	for result in _attack_phase.advance(_defenders, _enemies):
		result.target._take_damage(result.damage)
		result.defender.weapon_instance._reset_cooldown()
		defender_attacked.emit(result.defender, result.target, result.damage)

func _resolve_defeated() -> void:
	var defeated: Array[Enemy] = []
	for enemy in _enemies:
		if not enemy.is_alive():
			defeated.append(enemy)
	for enemy in defeated:
		_enemies.erase(enemy)
		enemy_defeated.emit(enemy)

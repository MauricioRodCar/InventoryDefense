# Roadmap: efectos de estado (quemadura/veneno) y resistencias

**Estado: branch 1 completa, mergeada a `main` (308 tests en verde). Branch 2
(visualización) pendiente.** El dominio ya resuelve headless todo el ciclo de
vida de un efecto (aplicar, refrescar, tickear, expirar, resistencia), pero
todavía no hay ningún botón, color ni contenido de sandbox que lo dispare —
eso es exactamente lo que agrega la branch 2.

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
(una por branch, sin memoria de las demás) pueda ejecutar cada paso sin
tener que re-derivar el diseño. Antes de implementar: leer `CLAUDE.md` y las
secciones relevantes de `README.md`. Seguir la regla del proyecto:
**explicar el plan antes de programar** — si algo de esta spec no cierra con
el código real, parar y preguntar antes de improvisar.

Tercera pieza de la serie de "profundidad de combate" (después de críticos y
daño de área, ambas ya mergeadas). Resistencias se resuelve en la misma
branch que efectos de estado (no tiene sentido por separado: resistir algo
que no existe).

## Objetivo de producto

Un arma puede aplicar un efecto de estado al impactar: daño repetido a lo
largo del tiempo (quemadura, veneno), sin necesidad de que el arma vuelva a
atacar. Un enemigo puede tener resistencia a efectos de estado, que reduce
el daño por tick que recibe (hasta anularlo por completo con resistencia
100%). Decisiones de producto ya confirmadas con el usuario:

- Reaplicar el mismo efecto (mismo `id`) sobre un enemigo que ya lo tiene
  activo **reinicia su duración**, no acumula una segunda instancia. Efectos
  *distintos* sí pueden coexistir en el mismo enemigo (quemado y envenenado
  a la vez).
- La resistencia es una **reducción de daño por tick**, no una probabilidad
  de resistir — sin tirada de dado extra aparte de la que ya existe para
  crítico.
- Demo de sandbox: Vanguardia (`square`) aplica **quemadura**, Rematador
  (`bar`) aplica **veneno**, Artillero (`corner`) se queda sin efecto de
  estado por ahora (ya tiene daño de área — combinar dos mecánicas nuevas
  sobre el mismo arquetipo dificultaría distinguir visualmente cuál está
  pasando). Mismo criterio que crítico y daño de área: constante en los
  tres rangos de cada arquetipo, solo el daño base escala por rango.

## Por qué 2 branches y en este orden

Regla del proyecto: no modificar varios sistemas en una sola tarea. Esta es
la pieza más grande de la serie de combate — toca `Enemy`, `EnemyData`,
`WeaponData`, `AttackPhase` y `CombatSimulation` a la vez (mucho más
superficie que críticos o área, que tocaron uno o dos archivos). Mismo
criterio que ya se usó para partir el draft de fin de wave en dominio + UI:
cada mitad la ejecuta una instancia sin contexto y sin checkpoints
intermedios, así que conviene poder revisar la parte con más superficie de
bugs (el ciclo de vida de un efecto: aplicar, refrescar, tickear, expirar)
antes de que la visualización se construya encima.

| # | Branch | Qué agrega | Depende de |
|---|--------|------------|------------|
| 1 | `feature/status-effects-domain` | `StatusEffectData`/`StatusEffectInstance`, `Enemy` trackea efectos activos, `WeaponData` los aplica, `CombatSimulation` los tickea. 100% headless, sin UI, sin contenido de sandbox. | — |
| 2 | `feature/status-effects-visualization` | `EnemyView` se tiñe mientras un efecto está activo; Vanguardia/Rematador de sandbox ganan quemadura/veneno. | 1 |

Ambas branches están **completamente especificadas y listas para
implementar**, cada una autocontenida.

---

## Branch 1 — `feature/status-effects-domain` (lista para implementar)

### Diseño

**`StatusEffectData`** (nuevo, `Scripts/Gameplay/Combat/status_effect_data.gd`)
— definición pura, mismo rol que `WeaponData`/`EnemyData`: sin estado de
ejecución, compartible entre múltiples `WeaponData`. Quemadura y veneno
**no son subclases distintas**: son dos instancias de esta misma clase con
distintos valores, mismo criterio que dos tipos de enemigo son dos
`EnemyData`, no dos clases — no hay ninguna diferencia de *comportamiento*
entre ellas, solo de números.

```
class_name StatusEffectData
extends Resource

@export var id: StringName = &""
@export var damage_per_tick: int = 0
@export var tick_interval: float = 1.0
@export var duration: float = 0.0

func _init(p_id: StringName = &"", p_damage_per_tick: int = 0, p_tick_interval: float = 1.0, p_duration: float = 0.0) -> void:
	id = p_id
	damage_per_tick = p_damage_per_tick
	tick_interval = p_tick_interval
	duration = p_duration
```

**`StatusEffectInstance`** (nuevo,
`Scripts/Gameplay/Combat/status_effect_instance.gd`) — instancia en
ejecución de un `StatusEffectData` aplicado a un `Enemy` concreto. Mismo
patrón Definition → Runtime Instance que `WeaponData`/`WeaponInstance`.
`damage_per_tick` ya viene ajustado por resistencia **al aplicarse**, no se
recalcula en cada tick (la resistencia de un enemigo no cambia durante la
batalla).

```
class_name StatusEffectInstance
extends RefCounted

const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

var status_effect_data: StatusEffectData
var damage_per_tick: int
var time_until_next_tick: float
var remaining_duration: float

func _init(p_status_effect_data: StatusEffectData, p_damage_per_tick: int) -> void:
	status_effect_data = p_status_effect_data
	damage_per_tick = p_damage_per_tick
	time_until_next_tick = p_status_effect_data.tick_interval
	remaining_duration = p_status_effect_data.duration

## Uso interno de Enemy: avanza delta, devuelve el daño de este tick (0 si
## todavía no tocaba tickear).
func _tick(delta: float) -> int:
	remaining_duration -= delta
	time_until_next_tick -= delta
	if time_until_next_tick > 0.0:
		return 0
	time_until_next_tick += status_effect_data.tick_interval
	return damage_per_tick

func is_expired() -> bool:
	return remaining_duration <= 0.0
```

**`Enemy`** gana:
- `var status_effect_resistance: float = 0.0` — campo plano copiado de
  `EnemyData` al construirse, mismo criterio que `max_health`/`speed` ya se
  copian planos en vez de retener una referencia a `EnemyData` (`Enemy` no
  guarda ninguna referencia a `EnemyData` hoy; no empezar a hacerlo ahora,
  solo copiar el valor nuevo igual que los existentes).
- `_init` gana `p_status_effect_resistance: float = 0.0` al final de la
  lista de parámetros (no rompe ningún call site existente).
- `var _active_status_effects: Array[StatusEffectInstance] = []` (privado).
- Clase anidada `StatusEffectTick` (mismo patrón que `WeaponBehavior.Hit`
  anidada en su clase: un resultado pequeño, no una entidad de dominio):

  ```
  class StatusEffectTick:
  	extends RefCounted
  	var status_effect_id: StringName
  	var damage: int
  	func _init(p_status_effect_id: StringName, p_damage: int) -> void:
  		status_effect_id = p_status_effect_id
  		damage = p_damage
  ```
- `get_active_status_effects() -> Array[StatusEffectInstance]`: devuelve una
  copia (mismo patrón que `InventoryGrid.get_pieces()`), para uso futuro de
  la branch de visualización y de tests.
- `_apply_status_effect(data: StatusEffectData) -> void` (uso interno de
  `CombatSimulation`, vía `AttackPhase.Result.status_effect`): si
  `status_effect_resistance >= 1.0`, no hace nada (inmunidad total, ni se
  trackea). Si ya hay una instancia activa con el mismo
  `status_effect_data.id`, se remueve (refrescar, no acumular) antes de
  agregar la nueva. Calcula `damage_per_tick` ajustado por resistencia
  (`roundi(data.damage_per_tick * (1.0 - status_effect_resistance))`) y
  agrega una `StatusEffectInstance` nueva a `_active_status_effects`.
- `_tick_status_effects(delta: float) -> Array[StatusEffectTick]` (uso
  interno de `CombatSimulation`): tickea cada instancia activa vía
  `instance._tick(delta)`; por cada una que devuelva daño > 0, agrega un
  `StatusEffectTick` al resultado. Remueve del array cualquier instancia
  para la que `is_expired()` sea `true` (después de tickearla, no antes —
  el último tick antes de expirar sigue contando).

**`EnemyData`** gana `@export var status_effect_resistance: float = 0.0` y
el parámetro correspondiente en `_init` (al final, no rompe call sites).

**`WeaponData`** gana `var status_effect: StatusEffectData` (sin `@export`,
mismo criterio que `weapon_behavior` — nullable, sin efecto por defecto) y
el parámetro `p_status_effect: StatusEffectData = null` al final de `_init`
(después de `p_crit_multiplier`, no rompe ningún call site existente).

**`AttackPhase.Result`** gana `var status_effect: StatusEffectData`
(nullable), copiado de `weapon_data.status_effect` en el mismo lugar donde
ya se resuelve el crítico dentro de `advance()`. `AttackPhase` no aplica
nada: solo transporta el dato, igual que ya transporta `damage`/
`is_critical`.

**`CombatSimulation`** gana:
- Nueva señal `signal status_effect_ticked(enemy: Enemy, status_effect_id:
  StringName, damage: int)`.
- `_resolve_attacks()`: después de `result.target._take_damage(result.damage)`
  y antes de emitir `defender_attacked`, si `result.status_effect != null`,
  llamar `result.target._apply_status_effect(result.status_effect)`.
- Nuevo paso `_resolve_status_effects(delta: float) -> void`: para cada
  enemigo vivo, llama `enemy._tick_status_effects(delta)` y por cada
  `StatusEffectTick` devuelto, `enemy._take_damage(tick.damage)` y emite
  `status_effect_ticked(enemy, tick.status_effect_id, tick.damage)`.
- `advance(delta)` gana este paso nuevo **entre** `_resolve_attacks(delta)`
  y `_resolve_defeated()`: el daño directo se resuelve primero (puede matar
  a alguien), después tickean los efectos (también pueden matar a alguien),
  y recién al final `_resolve_defeated()` limpia a quien haya muerto por
  cualquiera de las dos causas en el mismo `advance()`.
- `_resolve_spawns()`: al construir cada `Enemy` desde su `EnemyData`, pasar
  también `enemy_data.status_effect_resistance` como cuarto argumento de
  `Enemy.new(...)`.

### Cambios exactos por archivo

- **Nuevo** `Scripts/Gameplay/Combat/status_effect_data.gd` (código exacto
  arriba).
- **Nuevo** `Scripts/Gameplay/Combat/status_effect_instance.gd` (código
  exacto arriba).
- **`Scripts/Gameplay/Combat/enemy.gd`**: campo/parámetro
  `status_effect_resistance`, campo `_active_status_effects`, clase anidada
  `StatusEffectTick`, métodos `get_active_status_effects()`,
  `_apply_status_effect()`, `_tick_status_effects()` — todo descrito arriba.
- **`Scripts/Gameplay/Combat/enemy_data.gd`**: campo/parámetro
  `status_effect_resistance`.
- **`Scripts/Gameplay/Combat/weapon_data.gd`**: campo/parámetro
  `status_effect`.
- **`Scripts/Gameplay/Combat/attack_phase.gd`**: campo `status_effect` en
  `Result`, copiado desde `weapon_data.status_effect` en `advance()`.
- **`Scripts/Gameplay/Combat/combat_simulation.gd`**: señal
  `status_effect_ticked`, aplicar `status_effect` en `_resolve_attacks()`,
  nuevo `_resolve_status_effects()`, llamada nueva en `advance()`, pasar
  `status_effect_resistance` en `_resolve_spawns()`.

### Call sites verificados

Antes de implementar, correr grep de `Enemy.new(` en todo el repo (no
asumir que ya está completo en esta spec — confirmar el conteo real, mismo
motivo por el que una spec anterior de este roadmap tuvo un error de
verificación) y confirmar que todos siguen compilando porque el nuevo
parámetro es opcional con default `0.0`. Mismo chequeo para
`WeaponData.new(...)` (nuevo parámetro al final, opcional) y para cualquier
construcción directa de `AttackPhase.Result` (ya se confirmó en la spec de
críticos que solo `attack_phase.gd` lo construye — validar que sigue siendo
así).

### Tests nuevos a agregar

1. **`Tests/Gameplay/Combat/test_status_effect_instance.gd`** (nuevo):
   - Antes de que pase `tick_interval`, `_tick(delta)` devuelve `0`.
   - Al cumplirse `tick_interval`, `_tick(delta)` devuelve `damage_per_tick`.
   - `is_expired()` es `false` mientras `remaining_duration > 0`, `true`
     cuando se agota.
2. **`Tests/Gameplay/Combat/test_enemy.gd`** (extender el existente):
   - `_apply_status_effect` con resistencia `0.0` guarda el
     `damage_per_tick` sin modificar.
   - `_apply_status_effect` con resistencia `0.5` guarda la mitad (redondeado).
   - `_apply_status_effect` con resistencia `1.0` no agrega nada a
     `get_active_status_effects()`.
   - Reaplicar el mismo `status_effect_data.id` reemplaza la instancia
     anterior (sigue habiendo solo una activa con ese `id`, no dos).
   - Dos `status_effect_data` con `id` distinto coexisten (dos instancias
     activas al mismo tiempo).
   - `_tick_status_effects(delta)` devuelve un `StatusEffectTick` por cada
     efecto que tocaba tickear en ese `delta`, y remueve del array los que
     expiraron.
3. **`Tests/Gameplay/Combat/test_enemy_data.gd`** (extender): sin indicar
   `status_effect_resistance`, queda en `0.0`; indicado explícitamente, se
   guarda tal cual.
4. **`Tests/Gameplay/Combat/test_weapon_data.gd`** (extender): sin indicar
   `status_effect`, queda en `null`; indicado explícitamente, se guarda tal
   cual.
5. **`Tests/Gameplay/Combat/test_combat_simulation.gd`** (extender):
   - Un `Defender` con `WeaponData.status_effect` configurado aplica el
     efecto al enemigo objetivo tras impactar.
   - `advance(delta)` sucesivos tickean el efecto y emiten
     `status_effect_ticked` con el daño correcto en el momento esperado.
   - El daño de un tick de efecto puede derrotar a un enemigo (emite
     `enemy_defeated` igual que el daño directo).

### Documentación a actualizar

- `README.md`: sección nueva o notas dentro de Combate explicando
  `StatusEffectData`/`StatusEffectInstance` (mismo patrón Definition →
  Runtime que el resto), por qué quemadura/veneno son instancias y no
  subclases, por qué reaplicar refresca en vez de acumular, por qué la
  resistencia se aplica una sola vez al aplicarse el efecto (no en cada
  tick), y el nuevo paso de `CombatSimulation.advance()`.
- `TODO.md`: marcar `[x] Efectos de estado` y `[x] Resistencias` bajo
  `## Combate` — **recién en la branch 2**, cuando el sistema sea visible de
  punta a punta (mismo criterio que se usó para "Fusión de piezas" en el
  roadmap de fusión: no marcar en la mitad de dominio sola).

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (excepto los
  archivos donde esta spec pide agregar/extender tests).
- Los tests nuevos pasan.
- `README.md` actualizado (`TODO.md` no, ver arriba).
- Commit único.

---

## Branch 2 — `feature/status-effects-visualization` (lista para implementar una vez la branch 1 esté mergeada)

### Diseño

**Color por efecto, resuelto en la UI, no en el dominio** — mismo criterio
que ya usa el proyecto para `InventoryPiece.type_id` (el dominio expone un
`id`, la vista mapea ese `id` a un color localmente; `ShapeData`/
`StatusEffectData` no llevan ningún campo de color). `EnemyView` gana un
diccionario local `const _COLOR_BY_STATUS_EFFECT_ID := {&"burn":
Color.ORANGE, &"poison": Color.PURPLE}` (nombres de `id` a definir junto con
el contenido de sandbox, ver abajo).

**`EnemyView.update_state()`** gana un tercer parámetro:
`active_status_effect_ids: Array[StringName] = []`. Si el array no está
vacío, `_draw()` mezcla el color base (rojo/negro según vida, como hoy) con
el color del primer id de la lista que tenga una entrada en
`_COLOR_BY_STATUS_EFFECT_ID` (placeholder simple: si hay varios efectos
activos a la vez, se muestra el primero encontrado, no una combinación —
suficiente para esta iteración, ver Contexto del roadmap de por qué
Artillero se dejó sin efecto de estado para no tener que resolver esto con
más de un efecto a la vez en el mismo enemigo todavía).

**`BattleView.sync()`** ya empuja posición y vida a cada `EnemyView` en cada
`advance(delta)` (es el único lugar donde se sincroniza estado continuo, ver
notas de diseño de Battle en el README). Extenderlo para que también arme
`Array[StringName]` a partir de `enemy.get_active_status_effects()` (mapear
cada `StatusEffectInstance` a su `status_effect_data.id`) y lo pase como
tercer argumento a `update_state()`.

**Contenido de sandbox** (`main.gd`, `_build_sandbox_defender_catalog()`):
- Vanguardia (`square`): agregar `StatusEffectData.new(&"burn", 3, 1.0,
  4.0)` (3 de daño por tick, cada 1s, dura 4s) como `status_effect` en sus
  tres `WeaponData`, sin cambiar nada más de lo que ya tiene.
- Rematador (`bar`): agregar `StatusEffectData.new(&"poison", 2, 1.0, 6.0)`
  (2 de daño por tick, cada 1s, dura 6s — más débil por tick, dura más) como
  `status_effect` en sus tres `WeaponData`.
- Artillero (`corner`): sin cambios, se queda sin efecto de estado.

Ambos son valores de sandbox ajustables, no una curva de balance final —
mismo criterio que el resto del contenido de `main.gd`.

### Cambios exactos por archivo

- **`Scripts/UI/Battle/enemy_view.gd`**: tercer parámetro en
  `update_state()`, diccionario `_COLOR_BY_STATUS_EFFECT_ID`, lógica de
  mezcla de color en `_draw()`.
- **`Scripts/UI/Battle/battle_view.gd`**: `sync()` arma la lista de ids
  activos por enemigo y la pasa a `update_state()`.
- **`Scripts/Main/main.gd`**: agregar `status_effect` a los `WeaponData` de
  Vanguardia y Rematador (los tres ranks de cada uno), según los valores de
  arriba.

### Call sites verificados

`update_state()` hoy la llama únicamente `BattleView` (en `_add_enemy_view`
y en `sync()`) — confirmar por grep antes de asumirlo, no repetir el error
de verificación de una spec anterior.

### Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto al resto de la capa
`UI/Battle/`. La verificación es manual, en el editor de Godot.

### Documentación a actualizar

- `README.md`: nota de diseño nueva en Battle explicando la mezcla de color
  de `EnemyView` y por qué el mapeo `id → color` vive ahí y no en el
  dominio (mismo criterio ya documentado para `InventoryPiece.type_id`).
  Actualizar la nota de arquetipos de sandbox en Bridge mencionando que
  Vanguardia/Rematador ahora aplican quemadura/veneno.
- `TODO.md`: marcar `[x] Efectos de estado` y `[x] Resistencias` bajo
  `## Combate` — esta branch es la que completa el sistema de punta a punta
  (se puede ver un efecto de estado ocurriendo, no solo confirmarlo por
  test).

### Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse.
- `README.md`/`TODO.md` actualizados.
- Commit único.
- Verificación manual en el editor de Godot: colocar piezas `square` y
  `bar`, iniciar una wave, y confirmar que un enemigo golpeado por
  Vanguardia se tiñe de naranja durante unos segundos (quemadura) y uno
  golpeado por Rematador se tiñe de violeta durante más tiempo (veneno), y
  que el tinte desaparece cuando el efecto expira.

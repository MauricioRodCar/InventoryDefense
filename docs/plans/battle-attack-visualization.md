# Spec: visualización de ataques en batalla

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
pueda implementarlo sin tener que re-derivar el diseño. Antes de programar:
leer `CLAUDE.md` y las secciones relevantes de `README.md` (en particular
"Battle" y sus notas de diseño). Seguir la regla del proyecto: **explicar el
plan antes de programar** — si algo de esta spec no cierra con el código
real, parar y preguntar antes de improvisar.

A diferencia de los roadmaps anteriores (fuente real de piezas, fusión de
piezas), esto es **una sola branch**, no una secuencia: todo el cambio vive
en una sola capa (`Scripts/UI/Battle/`), sin tocar ningún dominio.

## Objetivo de producto

Hoy el combate es invisible: los defensores son cuadrados estáticos, los
enemigos son círculos que se mueven en línea recta, y `CombatSimulation`
emite `defender_attacked` pero nada lo dibuja — si el daño es alto, un
enemigo puede morir en el mismo frame en que aparece, sin que se vea ningún
ataque. El objetivo es un **placeholder deliberadamente tosco** (no arte
final) que deje ver con claridad qué defensor le pega a qué enemigo y dónde
empieza/termina el camino, para poder evaluar visualmente la próxima ronda
de trabajo (efectos de estado, daño de área, críticos, resistencias de
enemigo) a medida que se implemente.

Alcance de esta branch, explícitamente:
- Un proyectil simple viaja del defensor atacante al enemigo objetivo en
  cada `defender_attacked`.
- Un marcador visual fijo en el punto de spawn y otro en el punto de llegada
  del camino.

Fuera de alcance a propósito (no pedirlo ni anticiparlo):
- Número de daño flotante, distintos proyectiles por tipo de arma, curvas de
  trayectoria, partículas, sonido. Nada de esto se pidió; agregarlo ahora
  sería adelantarse a un problema que no existe todavía.
- Cualquier cambio de dominio (`CombatSimulation`, `AttackPhase`, etc.): ya
  emite todo lo necesario (`defender_attacked(defender, target, damage)`),
  confirmado leyendo `Scripts/Gameplay/Combat/combat_simulation.gd`.

## Diseño

### Por qué esto no rompe el patrón "vistas puramente reactivas, sin `_process` propio"

`EnemyView` no tiene `_process` propio a propósito: su posición/vida
reflejan estado real de la simulación, y debe mantenerse en lockstep con
`advance(delta)` — por eso `BattleView.sync()` le empuja el estado
explícitamente, nunca `EnemyView` lo calcula por su cuenta. Un proyectil es
distinto: `CombatSimulation` resuelve los ataques de forma instantánea (no
existe ningún concepto de "proyectil en vuelo" en el dominio, ni falta —
ver README, sección Battle: "sprites, animaciones, proyectiles... fuera de
alcance" para `CombatSimulation`). El proyectil es pura ambientación de la
capa de presentación, sin ningún estado de dominio al que deba mantenerse
sincronizado. Por eso `ProjectileView` sí puede manejar su propia animación
con un `Tween` interno — no viola el principio, lo respeta: no hay ningún
dato de dominio que esté re-derivando ni desincronizando.

### `ProjectileView` (nuevo)

`Scripts/UI/Battle/projectile_view.gd`, `extends Node2D`, sin `.tscn` propio
(mismo criterio que `EnemyView`/`DefenderView`: instanciada por código desde
`BattleView`, agregada como hijo).

- `const _RADIUS: float = 4.0`, `const _DURATION: float = 0.2` (segundos;
  placeholder, ajustable).
- `func setup(from: Vector2, to: Vector2) -> void`: fija `position = from`,
  dibuja un punto simple (`_draw()`: `draw_circle(Vector2.ZERO, _RADIUS,
  Color.WHITE)` — placeholder, sin distinción por tipo de arma), y arranca
  un `create_tween()` que anima `position` de `from` a `to` en `_DURATION`
  segundos. Al terminar el tween, `queue_free()` (conectar
  `tween.finished` o encadenar `tween_callback(queue_free)`).
- No conoce `Defender`, `Enemy` ni ningún tipo del dominio: solo dos
  `Vector2`. Quien la crea (`BattleView`) ya resolvió esas posiciones.

### `CombatPathMarkersView` (nuevo)

`Scripts/UI/Battle/combat_path_markers_view.gd`, `extends Node2D`, sin
`.tscn` propio.

- `func setup(spawn_position: Vector2, goal_position: Vector2) -> void`:
  guarda ambas posiciones, `queue_redraw()`.
- `_draw()`: un círculo verde en `spawn_position` (p. ej.
  `draw_circle(spawn_position, 8.0, Color.GREEN)`) y un círculo rojo en
  `goal_position` (`draw_circle(goal_position, 8.0, Color.RED)`) —
  placeholder, colores claramente distinguibles, sin pretender ser arte
  final.
- No conoce `CombatPath` ni `CombatPathView`: recibe las dos posiciones de
  mundo ya resueltas (`BattleView` ya tiene `path_start`/`path_end`
  exportados, no hace falta volver a calcular nada).

### Cambios en `BattleView`

- **Trackear defensores por identidad**, no solo por índice: hoy
  `_render_initial_state()` hace `for index in
  _simulation.get_defenders().size(): _add_defender_view(index)` y
  `_add_defender_view` no guarda ninguna relación `Defender -> DefenderView`
  en ningún lado (a diferencia de `_enemy_views`, que si existe). Sin esto,
  no hay forma de encontrar qué `DefenderView` le corresponde a un
  `Defender` cuando llega `defender_attacked`. Cambiar a: `var defenders :=
  _simulation.get_defenders(); for index in defenders.size():
  _add_defender_view(defenders[index], index)`, y que
  `_add_defender_view(defender, index)` guarde `_defender_views[defender] =
  view` en un nuevo diccionario `var _defender_views: Dictionary = {} #
  Defender -> DefenderView`, mismo patrón que `_enemy_views`.
- En `set_combat_simulation()`: conectar
  `_simulation.defender_attacked.connect(_on_defender_attacked)`, y crear
  el marcador de camino una vez: `var markers := CombatPathMarkersView.new();
  add_child(markers); markers.setup(path_start, path_end)` (usando los
  `@export` ya existentes de `BattleView`, sin parámetros nuevos). Guardar
  la referencia en un campo si hace falta limpiarla en `_clear_views()`
  (sí hace falta: recrear la simulación no debería duplicar marcadores).
- Nuevo handler: `func _on_defender_attacked(defender: Defender, target:
  Enemy, _damage: int) -> void`: busca `_defender_views.get(defender)` y
  `_enemy_views.get(target)`; si ambos existen, crea un `ProjectileView`,
  lo agrega como hijo, y llama `setup(defender_view.position,
  enemy_view.position)`. Si falta cualquiera de los dos (no debería pasar
  dado el orden de señales de `CombatSimulation.advance()`, pero es una
  guarda barata), no hacer nada — no vale la pena que un proyectil roto
  rompa el resto de la batalla.
- `_disconnect_simulation()`: desconectar también `defender_attacked`,
  mismo patrón que las otras tres señales que ya desconecta.
- `_clear_views()`: limpiar también `_defender_views` (además de
  `_enemy_views` y los `DefenderView` sueltos que ya limpia) y el marcador
  de camino si existe.

## Cambios exactos por archivo

- **Nuevo** `Scripts/UI/Battle/projectile_view.gd`.
- **Nuevo** `Scripts/UI/Battle/combat_path_markers_view.gd`.
- **`Scripts/UI/Battle/battle_view.gd`**: los cambios descritos arriba
  (trackear `_defender_views`, conectar/desconectar `defender_attacked`,
  nuevo handler, crear/limpiar el marcador de camino).

## Call sites verificados que NO requieren cambios

`CombatSimulation`, `AttackPhase`, `Defender`, `Enemy`: cero cambios — ya
emiten y exponen todo lo necesario. `BattleRunner`: cero cambios, sigue
llamando `battle_view.sync()` igual que hoy; el nuevo comportamiento es
puramente reactivo a una señal que `BattleView` ya podía escuchar.
`CombatPathView`: cero cambios (sigue siendo el único traductor de
`path_progress` a posición para `EnemyView`; los marcadores usan
directamente `path_start`/`path_end`, no pasan por `CombatPathView`).

## Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto al resto de la capa
`UI/Battle/` (`EnemyView`, `DefenderView`, `BattleView` no llevan tests
headless hoy tampoco, según el propio README). La verificación es visual,
en el editor de Godot.

## Documentación a actualizar

- `README.md`: agregar una nota de diseño nueva en la sección Battle
  explicando `ProjectileView`/`CombatPathMarkersView`, por qué está bien
  que `ProjectileView` maneje su propio `Tween` (ver razonamiento de
  Diseño), y que `BattleView` ahora trackea `Defender -> DefenderView`.
  Dejar explícito que es un placeholder deliberado, sin pretensión de ser
  la representación visual final (mismo espíritu que ya usa el documento
  para otras piezas de sandbox).
- `TODO.md`: no tiene una sección de Battle; no requiere cambios.

## Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse —
  esta branch no debería romper ningún test automatizado, ya que no toca
  ningún archivo con tests.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: colocar varias piezas de
  distinto arquetipo, iniciar una wave, y confirmar que (a) se ve un
  círculo verde en el punto de spawn y uno rojo en el punto de llegada,
  (b) cada vez que un defensor ataca, se ve un punto viajar desde su
  posición hasta el enemigo objetivo, y (c) un defensor con
  `DoubleShotWeaponBehavior` (Artillero, en el sandbox) dispara dos
  proyectiles visibles por cada vez que ataca, no uno — confirma que la
  granularidad de `defender_attacked` (un evento por impacto, no por
  volea) ya alcanza para esto sin ningún caso especial.

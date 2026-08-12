# Roadmap: overworld y progresión

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
(una por branch, sin memoria de las demás) pueda ejecutar cada paso sin
tener que re-derivar el diseño. Antes de implementar: leer `CLAUDE.md` y las
secciones relevantes de `README.md`. Seguir la regla del proyecto:
**explicar el plan antes de programar** — si algo de esta spec no cierra con
el código real, parar y preguntar antes de improvisar.

Este es el área más grande del proyecto hasta ahora — más grande que
cualquier roadmap anterior (draft, fusión, profundidad de combate). Por eso
se divide en fases secuenciales, cada una su propia branch, y **solo la
primera fase está especificada en detalle**: las siguientes se diseñan
recién cuando le toque el turno, para no fijar decisiones sobre un sistema
que todavía no existe.

## Objetivo de producto (visión completa, no de esta branch)

Un overworld con varios niveles hacia un nivel final. Completar un nivel
otorga una moneda de mejora permanente (distinta de `PlayerEconomy`, la
moneda de escenario), que se gasta para mejorar unidades de forma
persistente entre partidas — así, niveles antes imposibles se vuelven
superables con grindeo. Todo esto tiene que sobrevivir a cerrar el juego
(persistencia real en disco).

## Fases

| # | Fase | Qué agrega | Persistencia |
|---|------|------------|---------------|
| 1 | Esqueleto de navegación | Pantalla de overworld con varios nodos de nivel; todos llevan al mismo gameplay de sandbox actual, sin diferenciar contenido todavía. | No |
| 2 | Contenido por nivel | Cada nodo carga una configuración de ronda distinta (waves/enemigos propios) en vez del único sandbox hardcodeado. | No |
| 3 | Moneda permanente | Segunda moneda, otorgada al completar un nivel. | En memoria |
| 4 | Mejoras permanentes | Gastar esa moneda para subir stats base de una unidad de forma persistente entre partidas (dentro de la misma sesión). | En memoria |
| 5 | Persistencia real | Guardar/cargar en disco todo lo anterior (progreso, moneda, mejoras) — recién acá, sobre un modelo ya probado en memoria, en vez de diseñar el formato de guardado a ciegas. | Disco |

Decisión de producto ya confirmada: empezar por la fase 1, y no meter
persistencia real hasta la fase 5 (construir el modelo en memoria primero,
sobre algo que ya funciona, en vez de diseñar el guardado sin saber todavía
qué forma va a tener el progreso).

**Fase 1: completa.** Mergeada a `main` (308 tests en verde). Menú → Overworld
→ Batalla → volver (Escape) funcionando, confirmado visualmente por el
usuario. Los tres nodos de nivel siguen siendo idénticos — eso es
exactamente lo que resuelve la fase 2.

---

## Fase 1 — `feature/overworld-navigation` (lista para implementar)

### Objetivo de esta fase

Reemplazar el salto directo de `MainMenu` al gameplay por un paso
intermedio: una pantalla de overworld con varios nodos de nivel. Por ahora
**todos los nodos llevan a la misma escena de gameplay de sandbox que ya
existe** (`scenes/main/main.tscn`, sin ningún cambio en su contenido) — esta
fase prueba únicamente el flujo de escenas (Menú → Overworld → Batalla →
volver al Overworld), no construye contenido real por nivel. Eso es la fase
2, deliberadamente fuera de alcance acá.

### Diseño

**Nueva escena** `scenes/overworld/Overworld.tscn` + script
`Scripts/Overworld/overworld.gd` — nueva carpeta de nivel superior en
`Scripts/`, mismo criterio que `Scripts/Menu/`: es el composition root de su
propia escena, no una vista reactiva a un dominio.

`Overworld` (`extends Control`, raíz de la escena):
- Fondo placeholder (mismo estilo tosco que `MainMenu`: `ColorRect` liso,
  sin arte final).
- Tres `Button` de nivel (`Level1Button`/`Level2Button`/`Level3Button`,
  texto "Nivel 1"/"Nivel 2"/"Nivel 3"), agrupados en un contenedor centrado.
  Tres es un número arbitrario para esta fase — suficiente para probar que
  "varios nodos" funciona, sin significar nada todavía (los tres hacen
  exactamente lo mismo).
- Un `Button` de volver (`BackButton`, texto "Volver"), fuera del grupo de
  niveles.
- `overworld.gd`: en `_ready()`, conecta los tres botones de nivel al mismo
  handler (`_on_level_pressed`, sin distinguir cuál se apretó — no hay nada
  que distinguir todavía) y el botón de volver a su propio handler.
- `_on_level_pressed()`: `get_tree().change_scene_to_file("res://scenes/main/main.tscn")`.
- `_on_back_pressed()`: `get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")`.
- No conoce nada del dominio del juego ni de `Scripts/Main/main.gd`: mismo
  nivel de independencia que ya mantiene `MainMenu`.

**`MainMenu`**: el botón Iniciar deja de ir directo al gameplay. Cambiar
`_on_start_pressed()` en `Scripts/Menu/main_menu.gd` de
`change_scene_to_file("res://scenes/main/main.tscn")` a
`change_scene_to_file("res://scenes/overworld/Overworld.tscn")` — es el
único cambio que necesita `MainMenu`, consecuencia mecánica directa de que
ahora hay un paso intermedio, no una modificación de su propio diseño.

**`Scripts/Main/main.gd`** necesita una forma de volver al overworld una vez
terminada la batalla — hoy no existe ninguna (cuando `_current_wave_index >=
_wave_schedule.size()`, el método `_on_battle_runner_state_changed()`
simplemente no hace nada más). Agregar:
- Nuevo campo `var _all_waves_finished: bool = false`.
- En `_on_battle_runner_state_changed()`: donde hoy hace `return` al
  detectar que `_current_wave_index >= _wave_schedule.size()`, antes de ese
  `return`, poner `_all_waves_finished = true`.
- En `_unhandled_input()`: agregar una condición nueva, independiente de la
  que ya existe para `ui_accept` — `if event.is_action_pressed("ui_cancel")
  and _all_waves_finished: get_tree().change_scene_to_file("res://scenes/overworld/Overworld.tscn")`.
  Mismo espíritu que el disparador temporal de "Start Battle" (Enter/Espacio)
  que ya documenta el README: sin UI definitiva todavía, un gatillo de
  teclado alcanza para esta iteración. `ui_cancel` (Escape, por defecto en
  Godot) para no pisar `ui_accept`, que ya está en uso.

**Qué queda deliberadamente fuera de esta fase** (no construirlo, ni
dejarle un lugar preparado):
- Ningún mecanismo para pasar datos entre `Overworld` y el gameplay (qué
  nivel se eligió, qué configuración cargar): no hace falta todavía porque
  los tres botones son idénticos. La fase 2 va a tener que diseñar esto
  desde cero, sabiendo ya qué forma tiene un "nivel" — diseñarlo ahora a
  ciegas sería adivinar.
- Ninguna noción de nivel bloqueado/desbloqueado: los tres botones están
  siempre habilitados.
- Ninguna pantalla de victoria/derrota distinta a lo que ya existe.

### Cambios exactos por archivo

- **Nuevo** `Scripts/Overworld/overworld.gd`.
- **Nuevo** `scenes/overworld/Overworld.tscn`.
- **`Scripts/Menu/main_menu.gd`**: cambiar el destino de `_on_start_pressed()`.
- **`Scripts/Main/main.gd`**: agregar `_all_waves_finished`, setearlo en
  `_on_battle_runner_state_changed()`, y el gatillo de `ui_cancel` en
  `_unhandled_input()`.

### Call sites verificados

Antes de tocar `main.gd`, releer completo
`Scripts/Main/main.gd` (ya lo tenés en tu worktree) para confirmar que la
estructura de `_on_battle_runner_state_changed()`/`_unhandled_input()`
sigue siendo la que describe esta spec — si cambió desde que se escribió,
parar y preguntar antes de adaptarla por tu cuenta.

### Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto a `Scripts/Main/main.gd`,
`Scripts/Menu/` y al resto de la capa de escenas sin dominio propio. La
verificación es manual, en el editor de Godot.

### Documentación a actualizar

- `README.md`: agregar una sección nueva `### Overworld` (mismo nivel que
  `### Menú principal`), documentando `Overworld`, por qué los tres nodos
  son idénticos por ahora, el nuevo gatillo de `ui_cancel` en `main.gd`, y
  el cambio de destino de `MainMenu`.
- `TODO.md`: no tiene una sección para esto; no requiere cambios.

### Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: desde el menú principal,
  Iniciar lleva al overworld (no directo al gameplay); cualquiera de los
  tres botones de nivel lleva al gameplay de siempre; Volver desde el
  overworld regresa al menú; y una vez que las dos waves del sandbox
  terminan, presionar Escape vuelve al overworld.

---

## Fase 2 — `feature/overworld-level-content` (completa)

**Estado: completa.** Mergeada a `main` (308 tests en verde). Cada nodo del
overworld carga su propio calendario de waves vía `LevelSelection` (primer
autoload del proyecto); confirmado visualmente por el usuario que los tres
niveles se sienten distintos y que `main.tscn` directo sigue funcionando.


### Objetivo de esta fase

Que los tres nodos del overworld dejen de ser idénticos: cada uno carga una
`WaveData` de la wave propia (más waves, más enemigos por wave, progresión
de dificultad simple) en vez del único calendario hardcodeado que hoy usa
`Scripts/Main/main.gd` sin importar qué botón se apretó.

### Diseño

**El problema real de esta fase, antes que nada: cómo pasar datos entre
escenas.** `get_tree().change_scene_to_file()` no acepta parámetros — no hay
forma de "pasarle argumentos" a la escena de gameplay al navegar hacia
ella. Godot resuelve esto con un **autoload** (un singleton global,
declarado en `project.godot`, accesible desde cualquier escena sin
`preload`/referencia explícita). Este proyecto no tiene ninguno todavía —
va a ser el primero. Se lo mantiene deliberadamente mínimo (un solo campo)
para no convertirlo en un cajón de basura de estado global: su única
responsabilidad es sobrevivir al cambio de escena con el dato que
`Overworld` necesita entregarle a `main.gd`.

**`Scripts/Overworld/level_selection.gd`** (nuevo, autoload):

```
extends Node
## Único autoload del proyecto: retiene la WaveData elegida en Overworld
## para que main.gd la lea al construir la partida. Sin esto no hay forma de
## pasar datos entre escenas con change_scene_to_file(). Puramente en
## memoria, se resetea en cada arranque de la aplicación — no hay
## persistencia todavía (ver fase 5 de este roadmap).

const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")

var selected_wave_schedule: Array[WaveData] = []
```

Registrar en `project.godot` (sección `[autoload]`, que no existe todavía —
agregarla):

```
[autoload]

LevelSelection="*res://Scripts/Overworld/level_selection.gd"
```

**Por qué no se creó una clase `LevelData`** envolviendo la `Array[WaveData]`
(el patrón Definition que usa el resto del proyecto para "definición pura
compartible", p. ej. `WaveData`/`EnemyData`): esta fase no necesita nada más
que un calendario de waves por nodo — ni nombre de nivel, ni id, ni estado
de bloqueado, nada de eso tiene un consumidor todavía. Envolver un único
campo en una clase nueva sería una abstracción sin ningún uso real todavía
(la clase existiría solo para poder existir). Si una fase futura necesita
más datos por nivel (nombre para mostrar, id para trackear cuál está
desbloqueado, recompensa propia), ahí sí se justifica introducir esa clase
— no antes.

**`Overworld`**: cada botón de nivel deja de compartir el mismo handler sin
argumentos. Construye su propia `Array[WaveData]` por nivel (mismo estilo
que ya usa `main.gd` para su calendario de sandbox: `EnemyData` +
`WaveData.SpawnEntry`) y la liga al handler vía `.bind()`:

```
func _ready() -> void:
	_level_1_button.pressed.connect(_on_level_pressed.bind(_build_level_1_wave_schedule()))
	_level_2_button.pressed.connect(_on_level_pressed.bind(_build_level_2_wave_schedule()))
	_level_3_button.pressed.connect(_on_level_pressed.bind(_build_level_3_wave_schedule()))
	_back_button.pressed.connect(_on_back_pressed)

func _on_level_pressed(wave_schedule: Array[WaveData]) -> void:
	LevelSelection.selected_wave_schedule = wave_schedule
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
```

Calendarios de sandbox sugeridos (valores de placeholder, ajustables — la
progresión de dificultad es lo único que importa demostrar acá):
- Nivel 1: igual al calendario actual de `main.gd`, sin cambios (2 waves: 2
  goblins, 3 goblins).
- Nivel 2: 3 waves, 3/4/5 goblins.
- Nivel 3: 3 waves, 5/6/7 goblins.

Cada `EnemyData.new(&"goblin", 60, 20.0)` se puede seguir usando igual en
los tres — no hace falta un tipo de enemigo nuevo para esta fase, solo más
cantidad.

**`Scripts/Main/main.gd`**: en `_ready()`, donde hoy asigna `_wave_schedule =
_build_sandbox_wave_schedule()` incondicionalmente, cambiar a:

```
_wave_schedule = LevelSelection.selected_wave_schedule if not LevelSelection.selected_wave_schedule.is_empty() else _build_sandbox_wave_schedule()
```

Por qué el *fallback*: si alguien corre `main.tscn` directo (F6 en el
editor, sin pasar por `Overworld`), `LevelSelection.selected_wave_schedule`
queda vacío (nunca se seteó) — sin este fallback, la partida arrancaría sin
ningún enemigo. `_build_sandbox_wave_schedule()` no se borra: sigue siendo
el calendario por defecto cuando no hay nivel seleccionado, mismo criterio
defensivo que ya usa el resto del proyecto (p. ej.
`DefenderCatalog.get_defender_data()` devuelve `null` en vez de romper ante
una clave sin mapear).

### Cambios exactos por archivo

- **Nuevo** `Scripts/Overworld/level_selection.gd` (código exacto arriba).
- **`project.godot`**: agregar la sección `[autoload]` (código exacto arriba).
- **`Scripts/Overworld/overworld.gd`**: reemplazar los tres `connect`
  idénticos por los `.bind()` con calendario propio; agregar los tres
  métodos `_build_levelN_wave_schedule()`; cambiar `_on_level_pressed` para
  recibir el calendario y setearlo en `LevelSelection` antes de navegar.
- **`Scripts/Main/main.gd`**: el cambio puntual en `_ready()` descrito
  arriba. `_build_sandbox_wave_schedule()` no cambia.

### Call sites verificados

Antes de tocar `Scripts/Overworld/overworld.gd`, releerlo completo (ya
existe, de la fase 1) para confirmar que `_on_level_pressed` sigue siendo un
único método compartido sin parámetros — si cambió, parar y preguntar.
Mismo chequeo para el bloque de `_ready()` de `Scripts/Main/main.gd` donde
se asigna `_wave_schedule`.

### Tests nuevos a agregar

Ninguno. `LevelSelection` es un autoload sin lógica de dominio (un solo
campo público, sin invariantes que proteger) — no amerita tests headless,
mismo criterio que el resto de la capa de escenas/composition roots.

### Documentación a actualizar

- `README.md`: ampliar la sección `### Overworld` explicando
  `LevelSelection` (primer autoload del proyecto, por qué existe, por qué
  se mantiene mínimo, por qué no se envolvió en una clase `LevelData`
  todavía), y que los tres nodos ahora cargan calendarios distintos.
- `TODO.md`: no requiere cambios.

### Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: desde el overworld, cada uno
  de los tres niveles debe sentirse distinto (más enemigos en Nivel 2 que en
  Nivel 1, más todavía en Nivel 3). Correr `main.tscn` directo (sin pasar
  por el overworld) debe seguir funcionando con el calendario de sandbox de
  siempre (confirma que el *fallback* funciona).

## Fase 3 — `feature/overworld-permanent-currency` (lista para implementar una vez la fase 2 esté mergeada)

### Objetivo de esta fase

Completar un nivel otorga una segunda moneda — permanente, distinta de
`PlayerEconomy` (la de escenario) — visible en el overworld. Todavía no se
puede gastar en nada (eso es la fase 4, deliberadamente fuera de alcance
acá): esta fase solo prueba que la moneda se gana y se ve.

### Diseño

**Se introduce `LevelData` ahora, no antes.** La fase 2 dejó documentado
explícitamente el criterio: envolver el calendario de waves en una clase
recién cuando un consumidor real necesite más de un dato por nivel. Esta
fase es exactamente ese momento — un nivel ahora necesita *dos* datos
(calendario de waves + recompensa de moneda permanente), así que
`LevelSelection.selected_wave_schedule: Array[WaveData]` deja de alcanzar.

**`Scripts/Gameplay/Levels/level_data.gd`** (nuevo — primera clase de una
carpeta de dominio nueva, `Levels/`, al mismo nivel que `Combat/`/
`Economy/`/`Draft/`/`Inventory/` dentro de `Scripts/Gameplay/`):

```
class_name LevelData
extends Resource
## Definición pura de un nivel jugable: su calendario de waves y cuánta
## moneda permanente otorga al completarse. No lleva estado de ejecución.
## Mismo rol que WaveData/EnemyData: definición compartible, sin estado.

const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")

@export var wave_schedule: Array[WaveData] = []
@export var permanent_currency_reward: int = 0

func _init(p_wave_schedule: Array[WaveData] = [], p_permanent_currency_reward: int = 0) -> void:
	wave_schedule = p_wave_schedule
	permanent_currency_reward = p_permanent_currency_reward
```

**`Scripts/Gameplay/Economy/permanent_currency.gd`** (nuevo). Mismo rol y
casi la misma forma que `PlayerEconomy` (única autoridad, invariante nunca
negativo, señal de cambio) — pero **deliberadamente una clase separada, no
una subclase ni una composición de `PlayerEconomy`**: son dos monedas con
propósito distinto (una de escenario, se resetea cada partida; esta
sobrevive entre niveles y partidas) que no deben acoplarse entre sí,
decisión de producto ya registrada en el roadmap del draft de fin de wave.
Solo `get_amount()`/`add_amount()` por ahora — **sin** `spend_amount()` ni
`can_afford()` todavía: nada los necesita en esta fase (mismo criterio que
ya se usó con `PlayerEconomy.spend_gold`, agregado recién cuando el draft
tuvo un gasto real que resolver, no antes).

```
class_name PermanentCurrency
extends RefCounted

signal amount_changed(new_amount: int)

var _amount: int = 0

func get_amount() -> int:
	return _amount

## amount debe ser positivo: quien llama es responsable de no invocar esto
## con una recompensa nula o negativa, mismo criterio que PlayerEconomy.add_gold.
func add_amount(amount: int) -> void:
	assert(amount > 0, "add_amount requiere un amount positivo")
	_amount += amount
	amount_changed.emit(_amount)
```

**`Scripts/Overworld/permanent_progress.gd`** (nuevo, segundo autoload del
proyecto):

```
extends Node
## Autoload: retiene la PermanentCurrency del jugador durante toda la
## sesión (sobrevive a cada cambio de escena, a diferencia de PlayerEconomy,
## que main.gd reconstruye en cada partida). Puramente en memoria — sin
## persistencia real todavía (ver fase 5 de este roadmap).

const PermanentCurrency = preload("res://Scripts/Gameplay/Economy/permanent_currency.gd")

var currency := PermanentCurrency.new()
```

Registrar en `project.godot`, junto a `LevelSelection` (la sección
`[autoload]` ya existe desde la fase 2):

```
LevelSelection="*res://Scripts/Overworld/level_selection.gd"
PermanentProgress="*res://Scripts/Overworld/permanent_progress.gd"
```

**`Scripts/Overworld/level_selection.gd`**: cambia su único campo de
`selected_wave_schedule: Array[WaveData]` a `selected_level: LevelData =
null`.

**`Scripts/Overworld/overworld.gd`**:
- Los tres `_build_levelN_wave_schedule() -> Array[WaveData]` pasan a
  `_build_levelN() -> LevelData`, devolviendo `LevelData.new(wave_schedule,
  reward)` en vez del array suelto. Recompensas de sandbox sugeridas
  (placeholder, escalan con la dificultad ya establecida en la fase 2):
  Nivel 1 → 10, Nivel 2 → 20, Nivel 3 → 30.
- `_on_level_pressed(level: LevelData)`: asigna
  `LevelSelection.selected_level = level` (en vez de `.selected_wave_schedule`)
  antes de navegar.
- Nuevo `Label` de contador (`CurrencyLabel`): en `_ready()`, conectar
  `PermanentProgress.currency.amount_changed` y pintar el valor inicial
  explícitamente (mismo criterio ya establecido para `GoldCounterView`:
  pintar el estado inicial en el momento de conectar, no depender de que se
  emita una señal durante la construcción del objeto).

**`Scripts/Main/main.gd`**:
- En `_ready()`, donde hoy se arma `_wave_schedule` directo, pasa por
  `LevelData`: `var level: LevelData = LevelSelection.selected_level if
  LevelSelection.selected_level != null else _build_sandbox_level()`, y
  `_wave_schedule = level.wave_schedule`. `_build_sandbox_wave_schedule()`
  se renombra a `_build_sandbox_level() -> LevelData`, devolviendo el mismo
  calendario de siempre envuelto en un `LevelData` con
  `permanent_currency_reward = 0` (nunca se usa: la recompensa solo se
  acredita cuando `LevelSelection.selected_level` es real, ver abajo, así
  que este valor de relleno es inerte a propósito).
- En `_on_battle_runner_state_changed()`, en la misma rama donde ya se pone
  `_all_waves_finished = true`: si `LevelSelection.selected_level != null`
  y `LevelSelection.selected_level.permanent_currency_reward > 0`, llamar
  `PermanentProgress.currency.add_amount(LevelSelection.selected_level.permanent_currency_reward)`
  — mismo patrón de guarda que ya usa `BattleRunner._on_enemy_defeated` con
  `EnemyRewardCatalog` (nunca invocar `add_amount`/`add_gold` con un valor
  no positivo). El `if != null` es necesario porque correr `main.tscn`
  directo (fallback de la fase 2) no debe otorgar ninguna moneda permanente
  real.

### Cambios exactos por archivo

- **Nuevo** `Scripts/Gameplay/Levels/level_data.gd` (código exacto arriba).
- **Nuevo** `Scripts/Gameplay/Economy/permanent_currency.gd` (código exacto
  arriba).
- **Nuevo** `Scripts/Overworld/permanent_progress.gd` (código exacto
  arriba).
- **`project.godot`**: agregar la línea de `PermanentProgress` en
  `[autoload]`.
- **`Scripts/Overworld/level_selection.gd`**: cambiar el tipo del campo.
- **`Scripts/Overworld/overworld.gd`**: los cambios descritos arriba
  (`LevelData` en vez de `Array[WaveData]` suelto, recompensas por nivel,
  `CurrencyLabel`).
- **`scenes/overworld/Overworld.tscn`**: agregar el nodo `CurrencyLabel`
  (`Label`).
- **`Scripts/Main/main.gd`**: los cambios descritos arriba
  (`_build_sandbox_level()`, acreditar la recompensa al completar).

### Call sites verificados

Confirmado por grep antes de escribir esta spec: `selected_wave_schedule`
solo aparece en `Scripts/Main/main.gd`, `Scripts/Overworld/overworld.gd` y
`Scripts/Overworld/level_selection.gd` (más las menciones en `README.md`,
que esta misma spec ya pide actualizar). `_build_sandbox_wave_schedule()`
solo se llama desde dentro de `main.gd`. Ningún test referencia ninguno de
los dos.

### Tests nuevos a agregar

1. **`Tests/Gameplay/Levels/test_level_data.gd`** (nuevo, registrar en
   `Tests/test_runner.gd`): sin indicar valores, `wave_schedule` queda
   vacío y `permanent_currency_reward` en `0`; indicados explícitamente, se
   guardan tal cual.
2. **`Tests/Gameplay/Economy/test_permanent_currency.gd`** (nuevo,
   registrar en `Tests/test_runner.gd`; mismo estilo que
   `test_player_economy.gd`, pero solo los casos de `add_amount` — no
   escribir ningún test de `spend_amount`/`can_afford`, no existen todavía):
   arranca en `0`; `add_amount` acumula; `add_amount` emite `amount_changed`
   con el nuevo total.

### Documentación a actualizar

- `README.md`: nueva sección `### Levels` (o ampliar `### Overworld`, lo
  que se sienta más natural al escribirlo) documentando `LevelData` y por
  qué se introduce recién ahora. Ampliar las notas de Overworld con
  `PermanentCurrency`/`PermanentProgress`, por qué es una clase separada de
  `PlayerEconomy` y no una extensión, y el nuevo `CurrencyLabel`.
  Actualizar toda mención existente a `selected_wave_schedule`/
  `_build_sandbox_wave_schedule()` para reflejar los nombres nuevos.
- `TODO.md`: no requiere cambios.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse.
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: completar cualquiera de los
  tres niveles y confirmar que, al volver al overworld (Escape), el
  contador de moneda permanente subió en la cantidad correcta para ese
  nivel (10/20/30 según cuál se jugó). Correr `main.tscn` directo no debe
  acreditar ninguna moneda (es el camino de *fallback*, sin nivel real
  seleccionado).

## Fases 4-5 (sin detallar aún)

Se especifican recién cuando le toque el turno a cada una, ya con el
resultado real de la fase anterior mergeado — diseñar más allá de eso ahora
sería fijar decisiones sobre un sistema que todavía no existe. Ver la tabla
de arriba para el objetivo de cada una.

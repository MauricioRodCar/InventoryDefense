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

## Fases 2-5 (sin detallar aún)

Se especifican recién cuando le toque el turno a cada una, ya con el
resultado real de la fase anterior mergeado — diseñar más allá de eso ahora
sería fijar decisiones sobre un sistema que todavía no existe. Ver la tabla
de arriba para el objetivo de cada una.

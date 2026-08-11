# Spec: menú principal

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
pueda implementarlo sin tener que re-derivar el diseño. Antes de programar:
leer `CLAUDE.md` y las secciones relevantes de `README.md`. Seguir la regla
del proyecto: **explicar el plan antes de programar** — si algo de esta spec
no cierra con el código real, parar y preguntar antes de improvisar.

Es una sola branch, autocontenida. No forma parte de la serie de
"profundidad de combate" — es la primera pieza de una nueva área
(estructura general del juego: menú, y más adelante overworld).

## Objetivo de producto

Hoy el juego arranca directo en la escena de gameplay (`scenes/main/main.tscn`,
configurada como `run/main_scene` en `project.godot`). El objetivo es una
pantalla de inicio real: un fondo, y tres opciones — Iniciar (lleva al
gameplay actual), Configuración y Galería (deshabilitadas, sin funcionalidad
todavía — no hay ningún sistema de configuración ni de galería que mostrar
ahí), y Salir (cierra la aplicación). Decisión de producto ya confirmada: no
construir pantallas de Configuración/Galería vacías todavía — mejor un botón
deshabilitado y visible (comunica que existirán) que navegación a una
pantalla sin contenido real (código muerto disfrazado de feature).

Fuera de alcance a propósito:
- Ningún botón de "volver al menú" dentro de la escena de gameplay — hoy no
  existe ninguno, y agregarlo es un cambio a `Scripts/Main/main.gd` (otro
  sistema); no se pidió y no hace falta para que el menú cumpla su función.
- Transiciones animadas, música, arte de fondo real: el fondo es un
  placeholder liso, mismo espíritu que el resto de las vistas del proyecto
  (`ProjectileView`, `CombatPathMarkersView`, etc.) — tosco a propósito, no
  arte final.
- Cualquier sistema de configuración o de galería real: no existen todavía en
  ningún lado del proyecto: esta branch no debe anticiparlos.

## Diseño

**Nueva escena** `scenes/menu/MainMenu.tscn` + script
`Scripts/Menu/main_menu.gd` — nueva carpeta de nivel superior en `Scripts/`,
al mismo nivel que `Main/`/`Gameplay/`/`UI/`, porque esto es una pantalla de
nivel superior (composition root de su propia escena, como `Scripts/Main/`
lo es de la suya), no una vista reactiva a un dominio como todo lo que vive
en `Scripts/UI/`.

`MainMenu` (`extends Control`, raíz de la escena):
- Un `ColorRect` de fondo, anclado a toda la pantalla (color placeholder
  oscuro liso).
- Cuatro `Button` (agrupados en un `VBoxContainer` centrado): Iniciar,
  Configuración, Galería, Salir.
- `main_menu.gd`: en `_ready()`, conecta `pressed` de Iniciar y Salir a sus
  handlers, y deja Configuración/Galería con `disabled = true` (sin conectar
  nada — no hace falta un handler para un botón que no debe hacer nada
  todavía).
- Iniciar (`_on_start_pressed`): `get_tree().change_scene_to_file("res://scenes/main/main.tscn")`
  — navega a la escena de gameplay existente, sin ningún cambio en ella.
- Salir (`_on_exit_pressed`): `get_tree().quit()`.
- No conoce nada del dominio del juego (`InventoryGrid`, `CombatSimulation`,
  etc.) ni de `Scripts/Main/main.gd`: solo sabe que existe un archivo de
  escena al que navegar. Misma independencia que ya mantienen entre sí
  Inventory/Combat/Economy/Draft — el menú no es parte de ningún dominio, es
  pura navegación de escena.

**`project.godot`**: `run/main_scene` pasa de `"uid://dmmvrg6midvd5"` (que
apunta a `scenes/main/main.tscn`) a `"res://scenes/menu/MainMenu.tscn"` —
usar la ruta `res://` directa, no un `uid://`, porque el `uid` de un
`.tscn` nuevo recién se genera cuando el editor lo abre/importa por primera
vez, no se puede conocer de antemano al escribir el archivo a mano. `res://`
es igual de válido para `run/main_scene` y no depende de ese paso. Confirmado
por grep: `uid://dmmvrg6midvd5` solo aparece en `project.godot` (como
`run_main_scene`) y en la propia declaración `uid=` dentro de
`scenes/main/main.tscn` — ningún otro archivo lo referencia, así que cambiar
a dónde apunta `run/main_scene` no rompe nada más.

## Cambios exactos por archivo

- **Nuevo** `Scripts/Menu/main_menu.gd`.
- **Nuevo** `scenes/menu/MainMenu.tscn` (Control raíz + `ColorRect` de fondo
  + `VBoxContainer` con los cuatro `Button`, con anchors para que se adapte
  al tamaño de ventana — el proyecto ya usa `window/stretch/mode=canvas_items`
  en `project.godot`, así que la escena debe anclarse a pantalla completa,
  no usar posiciones absolutas fijas como sí hace `DraftView.tscn`, que es un
  panel chico dentro del HUD de juego, no una pantalla completa).
- **`project.godot`**: cambiar `run/main_scene` como se describe arriba.

## Call sites verificados

Ya confirmado por grep (ver Diseño): `uid://dmmvrg6midvd5` no tiene más
referencias que `project.godot` y la propia `scenes/main/main.tscn`.
`scenes/main/main.tscn` y `Scripts/Main/main.gd` no requieren ningún cambio
— el gameplay sigue siendo exactamente el mismo, solo cambia cómo se llega
a él.

## Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto a `Scripts/Main/main.gd`
y al resto de la capa de escenas/UI sin dominio propio: no llevan tests
headless. La verificación es manual, en el editor de Godot.

## Documentación a actualizar

- `README.md`: agregar una sección nueva `### Menú principal` (mismo nivel
  que `### Battle`/`### Draft`), con el formato ya establecido (Estado,
  Incluye, Notas de diseño), explicando por qué `MainMenu` vive en su propia
  carpeta de nivel superior y no en `Scripts/UI/`, por qué Configuración/
  Galería quedan deshabilitados en vez de navegar a pantallas vacías, y el
  cambio de `run/main_scene` a una ruta `res://` explícita.
- `TODO.md`: no tiene una sección para esto; no requiere cambios (esto es el
  inicio de un área nueva del proyecto, no un ítem ya listado).

## Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: correr el proyecto (F5) y
  confirmar que arranca en el menú (no en el gameplay directamente), que se
  ve el fondo y los cuatro botones, que Configuración/Galería aparecen
  visiblemente deshabilitados, que Iniciar lleva a la escena de gameplay de
  siempre (colocar piezas, iniciar batalla, todo funciona igual que antes),
  y que Salir cierra la aplicación.

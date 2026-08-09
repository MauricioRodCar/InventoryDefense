# Roadmap: fuente real de piezas (draft de fin de wave)

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como **arquitecto** del
proyecto, para que otra instancia sin contexto general (que implementa branch por
branch) pueda ejecutar cada paso sin tener que re-derivar el diseño. Antes de
implementar cualquier branch de este roadmap: leer `CLAUDE.md` (reglas del
proyecto) y las secciones relevantes de `README.md` (documenta el "por qué" de
cada decisión de arquitectura ya tomada). Seguir la regla del proyecto: **explicar
el plan antes de programar** — si algo de esta spec no cierra con el código real
al momento de implementarla, parar y preguntar antes de improvisar.

## Objetivo de producto

Al terminar una wave, se le presentan al jugador 3 opciones para elegir una:
mayoritariamente unidades nuevas (piezas), con probabilidad menor una expansión
de espacio de grid. Las unidades son **gratis** — el único limitante es si entran
en el grid actual. El jugador puede pagar oro para rerollear las 3 opciones.

Nota de diseño ya decidida: el oro que se gasta en el reroll es la moneda **de
escenario** (`PlayerEconomy`, la que ya existe). Es una moneda distinta de la
moneda de mejora permanente que se otorgará al completar un escenario (para el
overworld) — esa segunda moneda es un sistema futuro, no existe todavía, y no se
debe anticipar código para ella en ninguna de estas branches (no crear código
muerto).

## Por qué 4 branches y en este orden

Regla del proyecto: no modificar varios sistemas en una sola tarea. El draft de
fin de wave necesariamente compone tres capacidades de dominios distintos
(Inventory, Inventory, Economy). En vez de construir todo junto, cada capacidad
se construye y testea de forma aislada en su propio dominio, y la branch final
solo las **compone** llamando a APIs públicas ya existentes — mismo patrón que
`CombatSimulationBuilder` (Bridge) nunca modifica los internals de
`InventoryGrid` ni de `CombatSimulation`, solo los conecta.

| # | Branch | Dominio que modifica | Qué agrega | Depende de |
|---|--------|----------------------|------------|------------|
| 1 | `fix/inventory-piece-identity` | Inventory | Separa identidad de instancia (`id`) de identidad de tipo (`type_id`) en `InventoryPiece`. | — |
| 2 | `feature/inventory-grid-expansion` | Inventory | `InventoryGrid` gana capacidad de agregar celdas en runtime. | — (independiente de 1) |
| 3 | `feature/player-economy-spending` | Economy | `PlayerEconomy` gana gasto de oro (hoy solo tiene `add_gold`). | — (independiente de 1 y 2) |
| 4 | `feature/end-of-wave-draft` | Nuevo dominio (cross-cutting, mismo rol que Bridge) | El sistema de draft real: 3 opciones al terminar wave, reroll pago. | 1, 2, 3 |

Las branches 1, 2 y 3 son independientes entre sí y se pueden hacer en cualquier
orden. Solo la branch 4 depende de que las tres anteriores estén mergeadas.

Las branches 1, 2 y 3 están **completamente especificadas y listas para
implementar**, cada una de forma independiente y autocontenida — cada spec
incluye todo lo que hace falta saber sobre su propio dominio sin depender de que
quien la implemente conozca el estado de las otras branches. Están pensadas para
que cada una la ejecute una instancia distinta sin contexto compartido entre
ellas (ni siquiera necesitan saber que las otras branches existen), en paralelo
si hace falta. La branch 4 queda como roadmap de alto nivel a propósito: depende
de que 1, 2 y 3 estén mergeadas, y se especificará en detalle recién cuando le
toque el turno, para no fijar decisiones de diseño antes de tiempo.

---

## Branch 1 — `fix/inventory-piece-identity` (lista para implementar)

### Problema

`InventoryPiece.id` mezcla hoy dos roles distintos:

- **Identidad de instancia**: `InventoryGrid` lo usa como clave única en su
  diccionario interno `_pieces` (`Scripts/Gameplay/Inventory/inventory_grid.gd`,
  líneas `_pieces[piece.id] = piece` / `_pieces.erase(piece.id)`).
- **Identidad de tipo**: `InventoryPieceSourceSandbox` asigna ids como
  `&"square"`/`&"bar"`/`&"corner"` que en realidad describen un tipo de pieza, no
  una instancia concreta. `DefenderTranslator` (Bridge) depende de esto: usa
  `piece.id` como clave de tipo hacia `DefenderCatalog`.

No colisiona hoy porque el sandbox nunca ofrece dos piezas del mismo tipo. Pero
cualquier fuente real que ofrezca piezas repetidas (como el draft de la branch 4,
que va a ofrecer el mismo tipo de pieza más de una vez a lo largo de una partida)
haría que la segunda pisara a la primera en `_pieces`, perdiendo una pieza
colocada de `get_pieces()` de forma silenciosa. Esta branch resuelve eso antes de
que exista una fuente real que lo dispare.

### Diseño

Separar en dos campos:

- `type_id: StringName` — qué tipo de pieza es (`&"square"`, `&"bar"`, ...).
  Compartible entre múltiples instancias del mismo tipo, igual que
  `WeaponData.id`/`EnemyData.id` identifican un tipo compartible en Combat.
- `id: StringName` — identidad única de instancia, generada automáticamente por
  `InventoryPiece` al construirse. Nadie la pasa desde afuera.

El constructor **mantiene la misma firma posicional** (`_init(p_type_id:
StringName, p_shape: ShapeData)`): el primer parámetro ya era conceptualmente un
tipo en todos los call sites existentes (confirmado por grep, ver más abajo), así
que renombrar su significado no rompe ningún call site — solo cambia qué campo
guarda ese valor.

Generación de `id`: contador estático incremental dentro de la clase
(`static var _next_instance_id: int = 0`), formateado como `StringName` (p. ej.
`"piece_%d" % _next_instance_id`). Determinista, sin dependencias del motor de
Godot (coherente con que `InventoryPiece extends RefCounted` sin nodos), no
requiere persistencia porque no existe todavía ningún sistema de guardado entre
sesiones.

### Cambios exactos por archivo

**`Scripts/Gameplay/Inventory/inventory_piece.gd`**
- Agregar `static var _next_instance_id: int = 0`.
- Agregar `var type_id: StringName`.
- En `_init`: renombrar el parámetro `p_id` a `p_type_id`, asignarlo a
  `type_id`; generar `id` desde el contador estático e incrementarlo.
- Actualizar el comentario de clase explicando la separación instancia/tipo (y
  quitar cualquier mención a la deuda técnica, que esta branch resuelve).

**`Scripts/Gameplay/Inventory/inventory_grid.gd`**
- Sin cambios funcionales — `_pieces[piece.id]` ya queda correcto una vez que
  `id` es garantizado único. Agregar sí un test nuevo (ver abajo) que pruebe
  explícitamente que el bug ya no ocurre.

**`Scripts/Gameplay/Bridge/defender_translator.gd`**
- Cambiar `catalog.get_defender_data(piece.id)` por
  `catalog.get_defender_data(piece.type_id)`.
- Actualizar el comentario de clase: hoy dice explícitamente que esta clase
  "asume temporalmente" que no hay piezas repetidas por la deuda de
  `InventoryPiece.id` — esa nota queda obsoleta y se debe quitar.

**`Scripts/UI/Inventory/inventory_piece_view.gd`** y
**`Scripts/UI/Inventory/inventory_piece_source_slot_view.gd`**
- Cambiar `_color_for_id(_piece.id)` por `_color_for_id(_piece.type_id)` en
  ambos. Importante: si no se cambia esto, es una regresión visual real — hoy
  el color coincide con el tipo porque `id` y tipo eran el mismo string; tras
  el fix, cada instancia tendría un color distinto aunque sean del mismo tipo.

**`Scripts/Gameplay/Inventory/inventory_piece_source_sandbox.gd`**
- Sin cambios — ya llama `InventoryPiece.new(&"square", ...)` etc., que sigue
  siendo válido como `type_id`.

### Call sites verificados que NO requieren cambios

Confirmado por búsqueda en todo el repo: ningún test (`test_inventory_piece.gd`,
`test_inventory_grid.gd`, `test_inventory_piece_source.gd`,
`test_defender_translator.gd`, `test_combat_archetypes.gd`,
`test_combat_simulation_builder.gd`) lee `piece.id` directamente ni asertea su
valor — todos construyen `InventoryPiece.new(&"algo", shape)` y comparan
identidad de objeto o pasan la pieza a otras APIs. Ninguno necesita tocarse por
la firma del constructor.

### Tests nuevos a agregar

1. **`Tests/Gameplay/Inventory/test_inventory_piece.gd`**: dos
   `InventoryPiece.new(&"square", shape)` construidas por separado deben tener
   `type_id` igual (`&"square"`) pero `id` distinto entre sí.
2. **`Tests/Gameplay/Inventory/test_inventory_grid.gd`**: regresión explícita del
   bug — colocar dos piezas con el mismo `type_id` (p. ej. ambas `&"square"`) en
   celdas distintas del mismo grid, y afirmar que `get_pieces().size() == 2`
   (hoy, antes del fix, la segunda pisaría a la primera en `_pieces` y esto
   fallaría).
3. **`Tests/Gameplay/Bridge/test_combat_simulation_builder.gd`**: extender con un
   caso que coloca dos piezas del mismo `type_id` en el grid y confirma que
   `CombatSimulationBuilder.build()` produce un `Defender` por cada una (no que
   la segunda desaparezca).

### Documentación a actualizar

- `README.md`: la sección "Deuda técnica conocida — `InventoryPiece.id`" queda
  resuelta. Reemplazarla por una nota breve en Inventario explicando el estado
  final (`id` = instancia, `type_id` = tipo), siguiendo el mismo estilo que el
  resto de "Notas de diseño" del documento (explican el porqué, no solo el qué).
  Quitar también la frase de la sección Bridge que dice que
  `DefenderTranslator` "asume temporalmente" no tener piezas repetidas.
- `TODO.md`: no tiene un ítem específico de esta deuda; no requiere cambios.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (excepto los tres
  archivos donde se agregan tests nuevos arriba).
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único (esta branch modifica un solo sistema: Inventory, con un ajuste
  mecánico de una línea en Bridge y dos en UI que son consecuencia directa del
  cambio de contrato, no una modificación de esos sistemas por sí misma).

---

## Branch 2 — `feature/inventory-grid-expansion` (lista para implementar)

### Problema

`InventoryGrid` tiene límites fijos (`width`/`height`) establecidos una única vez
en el constructor, sin ninguna forma de crecer en runtime. El draft de fin de
wave (branch 4) necesita poder ofrecer "más espacio de grid" como una de sus
recompensas — hoy no existe ningún mecanismo para eso.

### Diseño

El grid sigue siendo rectangular — no se introducen celdas irregulares ni
bloqueadas. El modelo actual ya es un rectángulo simple; no hay ninguna
necesidad concreta todavía de formas irregulares, y agregarla ahora sería
optimizar para un requisito que no existe (regla del proyecto: no hacer
optimizaciones prematuras).

- Nuevo método `expand(additional_width: int, additional_height: int) -> void`:
  agranda `width` y/o `height` en runtime. Solo crece, nunca encoge — reducir un
  grid con piezas ya colocadas plantea qué hacer con las piezas que quedarían
  fuera de los nuevos límites, un problema que el draft no necesita resolver
  (solo otorga espacio, nunca lo quita). `assert(additional_width >= 0 and
  additional_height >= 0)` y `assert(additional_width > 0 or additional_height >
  0)` (debe agrandar al menos una dimensión) — mismo estilo de guarda que
  `PlayerEconomy.add_gold` (falla con `assert`, no hay rama de error silenciosa).
- Nueva señal `grid_expanded(new_width: int, new_height: int)`, emitida después
  de aplicar el cambio — mismo patrón que `piece_placed`/`piece_removed`.
- `width`/`height` dejan de ser `var` públicas mutables libremente: pasan a ser
  privadas (`_width`/`_height`) con `get_width() -> int`/`get_height() -> int`.
  Esto no es un cleanup aparte: es consecuencia directa de esta feature — si
  cualquiera pudiera seguir escribiendo `grid.width = X` desde afuera, el modelo
  de "único camino de mutación + señal" que `expand()` establece quedaría roto
  (alguien podría cambiar el tamaño sin que nadie se entere). Es el mismo
  criterio de protección que ya aplican `_cells`/`_pieces` en esta misma clase.
- `is_within_bounds()` pasa a usar `_width`/`_height` en vez de `width`/`height`
  — comportamiento idéntico, solo cambia el nombre del campo interno. `can_place`
  no cambia (ya delega en `is_within_bounds`).

### Cambios exactos por archivo

**`Scripts/Gameplay/Inventory/inventory_grid.gd`**
- Renombrar `var width: int` / `var height: int` (públicas) a `_width`/`_height`
  (privadas). El constructor sigue recibiendo `p_width`/`p_height` igual que hoy.
- Agregar `get_width() -> int` y `get_height() -> int`.
- Agregar `signal grid_expanded(new_width: int, new_height: int)`.
- Agregar método `expand(additional_width: int, additional_height: int) -> void`
  con los asserts descritos arriba; aplica `_width += additional_width`,
  `_height += additional_height`, luego `grid_expanded.emit(_width, _height)`.
- Actualizar `is_within_bounds()` para usar `_width`/`_height`.
- Actualizar el comentario de clase explicando la nueva capacidad de expansión.

**`Scripts/UI/Inventory/inventory_grid_view.gd`**
- En `set_inventory_grid()`: cambiar los dos usos de `_grid.width`/`_grid.height`
  por `_grid.get_width()`/`_grid.get_height()`.
- Conectar `_grid.grid_expanded` a un nuevo handler privado
  `_on_grid_expanded(new_width, new_height)` que vuelve a llamar
  `_background.setup(new_width, new_height, cell_size)` y actualiza
  `custom_minimum_size = Vector2(new_width * cell_size, new_height * cell_size)`.
  Sin esto, expandir el grid en el dominio dejaría la vista desincronizada (el
  fondo y el tamaño del control no crecerían) — misma categoría de ajuste
  mecánico que ya se hizo en la branch 1 para no dejar una regresión visual.
- En `_disconnect_grid()`: desconectar también `grid_expanded`, mismo patrón que
  ya existe para `piece_placed`/`piece_removed`.

### Call sites verificados que NO requieren cambios

Confirmado por búsqueda en todo el repo: el único consumidor externo de
`grid.width`/`grid.height` es `InventoryGridView` (los dos usos ya listados).
Ningún test lee `grid.width`/`grid.height` directamente. `InventoryGridBackground`
recibe `width`/`height` como parámetros simples de `setup()`, no como referencia
al grid — no necesita cambios.

### Tests nuevos a agregar

1. **`Tests/Gameplay/Inventory/test_inventory_grid.gd`**:
   - `expand` agranda los límites: grid de 2x2, `expand(2, 0)` →
     `get_width() == 4`, `get_height() == 2`, y una pieza que antes no entraba
     en la columna nueva ahora sí puede colocarse ahí (`can_place`/`place_piece`
     en una celda que antes estaba fuera de límites).
   - `expand` emite `grid_expanded` exactamente una vez con los nuevos
     `width`/`height`.

### Documentación a actualizar

- `README.md`: agregar una nota de diseño nueva en la sección Inventario (mismo
  estilo que el resto: explica el porqué, no solo el qué) describiendo
  `expand()`/`grid_expanded` y por qué `width`/`height` pasaron a ser privadas
  con getters.
- `TODO.md`: no tiene un ítem específico de expansión de grid; no requiere
  cambios.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (excepto
  `test_inventory_grid.gd`, donde se agregan los casos nuevos).
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único (esta branch modifica un solo sistema: Inventory, con un ajuste
  mecánico en `InventoryGridView` que es consecuencia directa de mantener la
  vista reactiva, no una modificación de UI por sí misma).

---

## Branch 3 — `feature/player-economy-spending` (lista para implementar)

### Problema

`PlayerEconomy` (`Scripts/Gameplay/Economy/player_economy.gd`) hoy solo permite
acumular oro (`add_gold`). No existe ninguna forma de gastarlo. El draft de fin
de wave (branch 4) necesita poder cobrar oro por el reroll de sus 3 opciones.

### Diseño

- Nuevo método `spend_gold(amount: int) -> bool`: intenta descontar `amount` del
  oro actual. `assert(amount > 0)` — mismo estilo de guarda que ya usa
  `add_gold` (gastar 0 o un monto negativo no tiene sentido, es responsabilidad
  de quien llama no invocarlo así). Si `amount` es mayor al oro disponible,
  **no** falla con assert: devuelve `false` sin mutar nada ni emitir señal
  (quedarse sin oro suficiente es un caso esperado en el flujo normal del juego
  — el jugador simplemente no puede pagar el reroll —, no un error de
  programación). Si alcanza, descuenta, emite `gold_changed(new_amount)` (misma
  señal que ya usa `add_gold`, no una señal nueva — sigue siendo "el oro
  cambió") y devuelve `true`.
- Nuevo método `can_afford(amount: int) -> bool`: predicado puro,
  `amount <= get_gold()`, sin mutar nada. Permite a un consumidor futuro (branch
  4) decidir si mostrar la opción de reroll como disponible sin tener que
  intentar gastarlo primero.
- Esta moneda sigue siendo exclusivamente la de escenario. No confundir con la
  moneda de mejora permanente del overworld (ver nota en Contexto) — no agregar
  nada relacionado a esa segunda moneda en esta branch.

### Cambios exactos por archivo

**`Scripts/Gameplay/Economy/player_economy.gd`**
- Agregar `func can_afford(amount: int) -> bool: return amount <= _gold`.
- Agregar `func spend_gold(amount: int) -> bool` con el comportamiento descrito
  arriba (`assert(amount > 0)`, `false` sin mutar si no alcanza, descuenta +
  emite `gold_changed` + `true` si alcanza).
- Actualizar el comentario de clase: hoy dice "única autoridad sobre el oro del
  jugador" sin mencionar gasto — ampliar para reflejar que también gestiona el
  gasto, protegiendo que el oro nunca sea negativo tanto al sumar como al
  restar.

### Call sites verificados que NO requieren cambios

Confirmado por búsqueda en todo el repo: el único consumidor de `PlayerEconomy`
hoy es `BattleRunner` (`Scripts/Gameplay/Battle/battle_runner.gd`), y solo llama
`add_gold`. No hay ningún otro archivo que necesite actualizarse — esta branch
es puramente aditiva, sin ningún consumidor de `spend_gold`/`can_afford` todavía
(ese es el trabajo de la branch 4).

### Tests nuevos a agregar

**`Tests/Gameplay/Economy/test_player_economy.gd`**:
1. `spend_gold` descuenta el oro cuando alcanza (p. ej. 10 de oro,
   `spend_gold(4)` → devuelve `true`, `get_gold() == 6`).
2. `spend_gold` falla sin mutar cuando no alcanza (p. ej. 5 de oro,
   `spend_gold(10)` → devuelve `false`, `get_gold()` sigue siendo 5).
3. `spend_gold` emite `gold_changed` solo cuando tiene éxito (conectar la señal,
   hacer un gasto exitoso y uno fallido, verificar que solo se registró un
   evento).
4. `can_afford` refleja el oro disponible (con 10 de oro: `can_afford(10) ==
   true`, `can_afford(11) == false`).

### Documentación a actualizar

- `README.md`: en la sección "Notas de diseño — Economía", la primera nota dice
  explícitamente que "`PlayerEconomy` no expone ninguna forma de gastar oro
  todavía" — esa frase queda obsoleta. Actualizarla para describir
  `spend_gold`/`can_afford` con el mismo estilo (por qué no falla con assert
  cuando no alcanza, por qué reusa `gold_changed` en vez de una señal nueva).
- `TODO.md`: no tiene un ítem específico de gasto de oro; no requiere cambios.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (excepto
  `test_player_economy.gd`, donde se agregan los casos nuevos).
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único (esta branch modifica un solo sistema: Economy, sin ningún
  consumidor nuevo wireado).

## Branch 4 — `feature/end-of-wave-draft` (roadmap, sin detallar aún)

Nuevo dominio (nombre a definir — candidato: `Scripts/Gameplay/Draft/`) que
compone, sin modificar sus internals:

- `InventoryPieceSource` (o una fuente real derivada) para ofrecer las piezas
  candidatas.
- La capacidad de expansión de `InventoryGrid` (branch 2) como una de las
  recompensas posibles, con probabilidad menor que las piezas.
- `PlayerEconomy.spend_gold`/`can_afford` (branch 3) para el reroll pago.

Se dispara cuando `CombatSimulation`/`BattleRunner` emite el fin de wave (ver
`wave_completed` en Combat/Battle, ya existente). Presenta 3 opciones, el
jugador elige una gratis o paga por rerollear el conjunto. Detallar la spec
completa de esta branch recién cuando 1, 2 y 3 estén mergeadas.

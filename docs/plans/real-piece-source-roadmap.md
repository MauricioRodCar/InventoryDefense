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

Este documento especifica **la branch 1 en detalle, lista para implementar**. Las
branches 2-4 quedan como roadmap de alto nivel: se especificarán en detalle
cuando les toque el turno, para no fijar decisiones de diseño antes de tiempo
(evitar optimización prematura sobre un diseño que puede ajustarse con lo que se
aprenda en el camino).

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

## Branch 2 — `feature/inventory-grid-expansion` (roadmap, sin detallar aún)

`InventoryGrid` necesita una forma de crecer en runtime (agregar celdas a su
`width`/`height` o a un conjunto de celdas habilitadas, según se decida cuando
se detalle esta branch). Debe quedar como una capacidad pública y testeada de
`InventoryGrid`, sin ningún consumidor todavía — la branch 4 la va a llamar, no
la va a construir.

## Branch 3 — `feature/player-economy-spending` (roadmap, sin detallar aún)

`PlayerEconomy` gana la posibilidad de gastar oro (p. ej. `spend_gold(amount)` /
`can_afford(amount)`), protegiendo el invariante de que el oro nunca queda
negativo — mismo espíritu que ya protege `add_gold`. Es la moneda de escenario,
no la moneda de mejora permanente (ver nota en Contexto).

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

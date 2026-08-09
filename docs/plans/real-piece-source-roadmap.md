# Roadmap: fuente real de piezas (draft de fin de wave)

**Estado: completo.** Las 5 branches (1, 2, 3, 4a, 4b) están mergeadas a
`main`. El jugador puede jugar de punta a punta: colocar piezas, pelear una
wave, ganar oro por cada enemigo derrotado, elegir una de 3 recompensas al
terminar (pieza nueva o expansión de grid, con reroll pago), y continuar a la
siguiente wave del schedule de sandbox. Pendiente de verificación visual/UX
propia (forma en que aparecen las piezas nuevas, legibilidad del panel) — ver
"Próximo objetivo" en `README.md`. Este documento queda como referencia
histórica de cómo se diseñó y secuenció el trabajo.

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

## Por qué 5 branches y en este orden

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
| 4a | `feature/end-of-wave-draft-domain` | Nuevo dominio `Draft` | `DraftOption`/`DraftPool`/`Draft`: sortea 3 opciones (pieza o expansión de grid), elegir una la aplica, reroll paga oro. 100% headless, sin UI. | 2, 3 |
| 4b | `feature/end-of-wave-draft-ui` | UI + composition root (`main.gd`) | `DraftView`, contador de oro, y loop mínimo de waves de sandbox para que el draft tenga un "después" jugable. | 4a |

Las branches 1, 2 y 3 son independientes entre sí y se pueden hacer en
cualquier orden (o en paralelo). La branch 4 se partió en dos mitades
secuenciales — 4a (dominio) y 4b (UI + integración) — en vez de una sola,
porque es sustancialmente más grande y nueva que las tres anteriores
(introduce el primer sistema de aleatoriedad del proyecto y una superficie de
UI entera) y cada mitad la va a ejecutar una instancia sin contexto y sin
checkpoints intermedios: partirla permite revisar la pieza con más superficie
de bugs (el sorteo ponderado) antes de que la UI se construya encima. 4a
depende de que 2 y 3 ya estén mergeadas (usa `InventoryGrid.expand()` y
`PlayerEconomy.spend_gold()` directamente). 4b depende de que 4a esté
mergeada.

Las cinco branches (1, 2, 3, 4a, 4b) están **completamente especificadas y
listas para implementar**, cada una de forma independiente y autocontenida —
cada spec incluye todo lo que hace falta saber sobre su propio alcance sin
depender de que quien la implemente conozca el estado de las otras branches ni
por qué existe el roadmap completo. Están pensadas para que cada una la
ejecute una instancia distinta sin contexto compartido entre ellas (ni
siquiera necesitan saber que las otras branches existen — cada prompt de
implementación les indica únicamente su propia sección). 1, 2 y 3 son
independientes entre sí y se pueden ejecutar en paralelo; 4a depende de que 2
y 3 estén mergeadas, y 4b depende de que 4a esté mergeada (ver la tabla y su
nota más abajo).

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

## Branch 4a — `feature/end-of-wave-draft-domain` (lista para implementar)

### Problema

No existe ningún mecanismo que ofrezca recompensas al jugador. El pitch del
juego pide que, entre waves, el jugador reciba 3 opciones para elegir una:
mayoritariamente piezas nuevas, con probabilidad menor una expansión de
espacio de grid, con la posibilidad de pagar oro para rerollear el conjunto.
Esta branch construye únicamente el dominio que decide y aplica eso —
headless, sin ningún botón ni pantalla todavía (eso es la branch 4b).

### Diseño

Nuevo dominio en `Scripts/Gameplay/Draft/` (carpeta nueva, mismo nivel que
`Inventory/`, `Combat/`, `Economy/`) — no es "Bridge", porque Bridge tiene un
significado ya establecido y acotado ("Inventory ↔ Combat"); esto cruza
Inventory ↔ Economy y es un dominio legítimo en sí mismo, con su propia
autoridad y sus propias señales, igual que Economy lo es.

**Convención a seguir, igual que en el resto del código ya existente:**
aunque `InventoryGrid`, `InventoryPieceSource` y `PlayerEconomy` ya tienen
`class_name` global, todo archivo nuevo que los use como tipo debe declarar
su propio `const NombreDeClase = preload("res://...")` local (mismo patrón
que ya usa, por ejemplo, `defender_translator.gd` con `InventoryPiece` pese a
que también tiene `class_name` global). No depender del `class_name` global
implícito en ningún archivo nuevo.

**Dos tipos de recompensa, vía Strategy (mismo idioma que
`TargetingPolicy`/`WeaponBehavior`):**

- `DraftOption` (`draft_option.gd`) — contrato base, no se instancia
  directamente. Declara dos métodos: `apply(grid: InventoryGrid,
  piece_source: InventoryPieceSource) -> void` (aplica el efecto de esta
  opción cuando se elige) y `describe() -> String` (texto breve para la UI,
  p. ej. `"Pieza: square"`). Cada subclase implementa ambos usando solo la
  referencia que le corresponde e ignorando la otra — se reciben ambas en
  `apply()` para que el contrato no tenga que cambiar si en el futuro aparece
  un tercer tipo de recompensa que necesite una referencia distinta; agregar
  un tipo de recompensa nuevo es agregar una subclase, nunca modificar
  `Draft` ni `DraftPool` (mismo criterio ya documentado para
  `WeaponBehavior`: "agregar un patrón de ataque nuevo es agregar una
  subclase, nunca modificar `WeaponData`, `AttackPhase` ni
  `CombatSimulation`").
- `PieceDraftOption` (`piece_draft_option.gd`, extiende `DraftOption`) —
  guarda `type_id: StringName` y `shape: ShapeData` (los mismos dos datos que
  ya necesita `InventoryPiece.new()`). `apply()` llama
  `piece_source.offer_piece(InventoryPiece.new(type_id, shape))` — **no**
  coloca la pieza directamente en el grid, la ofrece igual que cualquier otra
  pieza de `InventoryPieceSource`, así que el jugador la arrastra él mismo
  (esto es lo que hace que el único limitante real sea si le entra en el
  grid, como se decidió para el draft). `describe()` devuelve `"Pieza: %s" %
  type_id`.
- `GridExpansionDraftOption` (`grid_expansion_draft_option.gd`, extiende
  `DraftOption`) — guarda `additional_width: int` y `additional_height: int`.
  `apply()` llama `grid.expand(additional_width, additional_height)`
  directamente (API ya existente de la branch 2, mergeada). `describe()`
  devuelve `"Grid +%dx%d" % [additional_width, additional_height]`.

**Pool ponderado (Definition pura, sin estado de ejecución):**

- `DraftPool` (`draft_pool.gd`) — mismo rol que `WaveData`/`DefenderCatalog`:
  compartible, sin estado, no genera nada por sí sola. Constructor recibe un
  `Array[DraftPool.Entry]`, donde `Entry` es una clase anidada (mismo patrón
  que `DefenderCatalog.Entry`/`WaveData.SpawnEntry`) con dos campos: `option:
  DraftOption` y `weight: float`.
- Método `draw_options(count: int, rng: RandomNumberGenerator) ->
  Array[DraftOption]`: sortea `count` opciones **con reemplazo** (la misma
  opción puede repetirse entre las devueltas — no hay requisito de
  unicidad) mediante selección por ruleta ponderada. `rng` se recibe como
  parámetro explícito, **nunca** `randi()`/`randf()` global, para que el
  sorteo sea determinista y testeable headless — mismo criterio que
  `CombatSimulation.advance(delta)` recibe su `delta` explícito. Algoritmo
  exacto (implementarlo tal cual, es la única parte de esta branch sin
  precedente directo en el código existente):

  ```
  func draw_options(count, rng):
      total_weight = suma de entry.weight de todas las entries
      result = []
      repetir count veces:
          roll = rng.randf_range(0.0, total_weight)
          cumulative = 0.0
          para cada entry (en orden):
              cumulative += entry.weight
              si roll < cumulative:
                  result.append(entry.option)
                  cortar el for interno
      devolver result
  ```

**Owner en runtime:**

- `Draft` (`draft.gd`) — instancia en ejecución de un draft concreto. Única
  autoridad y único emisor de señales de este dominio (mismo rol que
  `InventoryGrid`/`CombatSimulation` en los suyos). No retiene ninguna
  referencia a `InventoryGrid`/`InventoryPieceSource`/`PlayerEconomy` más
  allá de los parámetros explícitos de cada llamada — mismo criterio que
  `CombatSimulationBuilder.build()` no arrastra estado entre llamadas.
  - Constructor `_init(pool: DraftPool, rng: RandomNumberGenerator,
    reroll_cost: int)`: guarda los tres, sortea inmediatamente 3 opciones
    (constante `OPTIONS_PER_DRAFT := 3`) llamando a un método privado
    `_roll()`.
  - `_roll()`: `_current_options = _pool.draw_options(OPTIONS_PER_DRAFT,
    _rng)`, emite `options_changed(_current_options)`. (La emisión durante el
    propio `_init()` no la puede escuchar nadie todavía — igual que
    `InventoryGridView` no depende de una señal emitida durante la
    construcción de `InventoryGrid`, sino que pinta el estado inicial
    llamando explícitamente a `get_current_options()` tras conectarse; ver
    branch 4b.)
  - `get_current_options() -> Array[DraftOption]`: devuelve una copia (mismo
    patrón que `InventoryGrid.get_pieces()`).
  - `get_reroll_cost() -> int`: getter simple.
  - `choose(index: int, grid: InventoryGrid, piece_source:
    InventoryPieceSource) -> void`: `option = _current_options[index]`,
    `option.apply(grid, piece_source)`, emite `option_chosen(option)`. No
    valida que `index` esté en rango — quien llama (la UI, en branch 4b) es
    responsable de no invocarlo con un índice inválido, mismo espíritu que
    `add_gold`/`spend_gold` delegan la validación de precondiciones a quien
    llama.
  - `reroll(player_economy: PlayerEconomy) -> bool`: si
    `player_economy.spend_gold(_reroll_cost)` devuelve `false` (no alcanza el
    oro), `reroll()` también devuelve `false` sin tocar `_current_options` ni
    emitir nada. Si tiene éxito, llama `_roll()` de nuevo y devuelve `true`.
  - Señales: `options_changed(options: Array[DraftOption])` y
    `option_chosen(option: DraftOption)`.

### Cambios exactos por archivo

Todos nuevos, ninguno existente se modifica:

- `Scripts/Gameplay/Draft/draft_option.gd`
- `Scripts/Gameplay/Draft/piece_draft_option.gd`
- `Scripts/Gameplay/Draft/grid_expansion_draft_option.gd`
- `Scripts/Gameplay/Draft/draft_pool.gd`
- `Scripts/Gameplay/Draft/draft.gd`

### Tests nuevos a agregar

Carpeta nueva `Tests/Gameplay/Draft/`, registrar los 4 archivos en
`Tests/test_runner.gd` (mismo patrón que cada suite ya registrada: agregar el
`const Test... = preload(...)` y la llamada `_run_suite(Test....new())`).

1. **`test_piece_draft_option.gd`**: `apply()` sobre un `InventoryPieceSource`
   nuevo deja `get_available_pieces().size() == 1` con el `type_id`/`shape`
   correctos; `describe()` incluye el `type_id`.
2. **`test_grid_expansion_draft_option.gd`**: `apply()` sobre un
   `InventoryGrid` nuevo agranda `get_width()`/`get_height()` exactamente en
   `additional_width`/`additional_height`; `describe()` incluye las
   dimensiones.
3. **`test_draft_pool.gd`**:
   - `draw_options(count, rng)` devuelve exactamente `count` elementos.
   - Con una entry de peso `0.0` junto a otras de peso positivo, sortear
     muchas veces (p. ej. 200 llamadas de `draw_options(1, rng)` con el mismo
     `rng` reutilizado entre llamadas para no repetir la misma secuencia) y
     verificar que la entry de peso `0.0` nunca aparece entre los resultados.
   - Con un pool de una única entry, cualquier sorteo devuelve siempre esa
     opción.
4. **`test_draft.gd`** (usar un `DraftPool` de una sola `PieceDraftOption`
   conocida en los casos donde el resultado exacto importa, para no depender
   de qué tocó el sorteo):
   - Al construirse, `get_current_options().size() == OPTIONS_PER_DRAFT`
     (3).
   - `choose(index, grid, piece_source)` aplica la opción correspondiente
     (verificar el efecto sobre `piece_source`) y emite `option_chosen` con
     esa opción.
   - `reroll(economy)` con oro suficiente: devuelve `true`, descuenta
     exactamente `reroll_cost` de `economy`, emite `options_changed`.
   - `reroll(economy)` con oro insuficiente (`economy` recién creada, 0 de
     oro): devuelve `false`, `economy.get_gold()` sigue en `0`.

### Documentación a actualizar

- `README.md`: agregar una sección nueva `### Draft`, en el mismo nivel que
  `### Economía` (después de ella, antes de `### Próximo objetivo`), con el
  mismo formato que las demás (Estado, Incluye, Notas de diseño — Draft).
  Documentar ahí el porqué de cada decisión de esta spec (Strategy para las
  dos clases de recompensa, `rng` explícito, `apply()` recibe ambas
  referencias aunque cada subclase use solo una, `reroll()` no muta nada si
  falla). Actualizar también la línea de "Próximo objetivo" que menciona la
  fuente real de piezas, ya que esta branch es un paso concreto hacia eso.
- `TODO.md`: no tiene secciones de Economía/Bridge/Battle tampoco (no se ha
  mantenido por dominio desde las primeras iteraciones); no requiere cambios.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse.
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único. Cero cambios en `InventoryGrid`, `InventoryPieceSource`,
  `PlayerEconomy` ni en ningún archivo de UI — esta branch es puramente
  aditiva, un dominio nuevo que consume APIs públicas ya existentes de otros
  tres dominios sin modificar ninguno de ellos.

---

## Branch 4b — `feature/end-of-wave-draft-ui` (lista para implementar una vez 4a esté mergeada)

### Problema

El dominio `Draft` de la branch 4a no tiene ninguna forma de mostrarse ni de
dispararse todavía. Además, hoy `main.gd` solo tiene una única `WaveData` de
sandbox y no hay forma de volver a arrancar una batalla después de que
termina la primera (el gatillo de "Start Battle" solo funciona mientras
`BattleRunner.state == IDLE`, y nunca vuelve a `IDLE`) — sin esto, el draft
no tendría ninguna "siguiente wave" a la que llevar al jugador, y la
funcionalidad se sentiría incompleta. Por eso esta branch también agrega un
loop mínimo de waves de sandbox, decisión ya tomada explícitamente para esta
branch: no es un `RunController` ni progresión persistente (eso sigue fuera
de alcance, ver README "Próximo objetivo") — es la misma clase de
configuración de sandbox mínima que `main.gd` ya tiene para
`DefenderCatalog`/`WaveData`, solo que ahora es una lista corta en vez de un
único valor.

### Diseño

**`BattleRunner.start()` no tiene ningún guard de estado** (confirmado
leyendo `Scripts/Gameplay/Battle/battle_runner.gd`): se puede volver a llamar
en cualquier momento, reconstruye `_simulation` desde cero. Esto significa
que el loop de waves no requiere ningún cambio en `BattleRunner` ni en
`CombatSimulation` — toda la secuenciación vive en `main.gd`, el composition
root, igual que ya es responsable de decidir cuándo arranca la primera
batalla.

**Gold counter** — nueva vista mínima, mismo patrón reactivo que el resto de
la capa UI:

- `GoldCounterView` (`Scripts/UI/Economy/gold_counter_view.gd`, extiende
  `Label` directamente, sin `.tscn` propio — es un único nodo, se agrega
  como `Label` en `main.tscn` con este script adjunto, mismo criterio que
  `EnemyView`/`DefenderView` no tienen `.tscn` por ser triviales).
  `set_player_economy(economy: PlayerEconomy) -> void`: se conecta a
  `economy.gold_changed`, pinta el texto inicial con `economy.get_gold()`
  inmediatamente (no depende de que se emita una señal — mismo motivo que
  `Draft._roll()` durante `_init()` no es el mecanismo de pintado inicial de
  `DraftView`, ver abajo), y actualiza el texto en cada `gold_changed`.

**DraftView** — `Scripts/UI/Draft/draft_view.gd` +
`scenes/UI/Draft/DraftView.tscn` (nueva carpeta, mismo patrón que
`scenes/UI/Inventory/`). Layout simple sin pulir (no es el objetivo de esta
iteración): un `Control` raíz con un `VBoxContainer` conteniendo 3 nodos
`Button` (nombrados `Option0`/`Option1`/`Option2`) y un cuarto `Button`
(`RerollButton`) separado. Siempre exactamente 3 botones de opción — no se
crean/destruyen dinámicamente porque `Draft.OPTIONS_PER_DRAFT` es constante.

- No conoce `InventoryGrid`/`InventoryPieceSource` directamente ni les llama
  ningún método — mismo criterio que `InventoryGridView`/
  `InventoryPieceSourceView` nunca mutan el dominio directamente, solo
  `InventoryInteractionController` lo hace. `DraftView` emite intención vía
  señales (`option_selected(index: int)`, `reroll_requested()`); quien
  decide qué hacer con esa intención es `main.gd` (no se justifica una clase
  controller aparte solo para esto, a diferencia del drag de inventario: acá
  es un puñado de conexiones triviales de un botón a un método, mismo
  criterio que ya usa `main.gd` para su propio gatillo temporal de "Start
  Battle").
- `_ready()`: conecta el `pressed` de cada botón de opción a un handler que
  emite `option_selected(i)` con el índice correspondiente (usar `.bind(i)`
  o closures, lo que sea idiomático), conecta `RerollButton.pressed` a emitir
  `reroll_requested()`, y llama `hide()` — el panel arranca oculto.
- `set_draft(draft: Draft, player_economy: PlayerEconomy) -> void`:
  desconecta cualquier `draft`/`player_economy` previos (mismo patrón
  `_disconnect_...` que el resto de las vistas), se conecta a
  `draft.options_changed`, `draft.option_chosen` y
  `player_economy.gold_changed`, pinta el estado inicial explícitamente
  (`_render_options(draft.get_current_options())` +
  actualizar el botón de reroll) — no depende de que se emita ninguna señal
  durante la construcción de `draft`, mismo motivo por el que
  `InventoryGridView.set_inventory_grid()` llama `_render_all()` en vez de
  esperar una señal — y llama `show()`.
- Al recibir `options_changed`: vuelve a pintar los 3 botones (`.text =
  option.describe()`) y actualiza el estado del botón de reroll.
- Al recibir `option_chosen`: se oculta (`hide()`) y se desconecta del
  `draft`/`player_economy` actuales — un draft resuelto no debe seguir
  reaccionando a cambios de oro ajenos a él.
- Estado del botón de reroll: texto con el costo (`draft.get_reroll_cost()`)
  y `disabled = not player_economy.can_afford(draft.get_reroll_cost())` —
  recalculado tanto en `set_draft()` como en cada `gold_changed`.

**`main.gd`** — cambios en el composition root:

- Promover `piece_source` de variable local de `_ready()` a campo
  `_piece_source: InventoryPieceSource` (mismo movimiento que ya se hizo con
  `_grid` en la branch de Battle, documentado en el README: "`main.gd`
  retiene ahora `InventoryGrid` como campo... para poder entregársela a
  `BattleRunner.start()`"), porque `Draft.choose()` la necesita.
- Reemplazar el campo `_wave_data: WaveData` por `_wave_schedule:
  Array[WaveData]` y agregar `_current_wave_index: int = 0`. Renombrar
  `_build_sandbox_wave_data() -> WaveData` a
  `_build_sandbox_wave_schedule() -> Array[WaveData]`, devolviendo 2
  `WaveData` (la primera con 2 goblins, la segunda con 3 — alcanza para
  demostrar el loop sin necesitar una curva de dificultad real, que sigue
  fuera de alcance).
- Nuevos campos: `_draft_pool: DraftPool` (construido una vez en `_ready()`
  vía un nuevo `_build_sandbox_draft_pool()`, con los mismos 3 tipos de pieza
  que ya ofrece `InventoryPieceSourceSandbox` —reusar los mismos
  `type_id`/`ShapeData` literales— a peso `5.0` cada uno, más
  `GridExpansionDraftOption.new(1, 0)` y `GridExpansionDraftOption.new(0,
  1)` a peso `1.0` cada una — proporción ~5:1 piezas:expansión, "probabilidad
  menor" tal como se definió el objetivo de producto), `_rng:
  RandomNumberGenerator` (creado una vez en `_ready()`, sin seed fija —
  aleatoriedad real de juego, a diferencia de los tests de 4a que sí siembran
  su propio `rng` para reproducibilidad), `_draft: Draft` (`null` mientras no
  hay un draft activo), `const REROLL_COST := 5`.
- Nuevos `@onready`: `_gold_counter_view: GoldCounterView` y `_draft_view:
  DraftView`, apuntando a los nodos nuevos de `main.tscn` (ver abajo).
- En `_ready()`, además de lo que ya existe: `_piece_source` en vez de
  variable local; `_gold_counter_view.set_player_economy(_player_economy)`;
  conectar `_battle_runner.state_changed` a un nuevo
  `_on_battle_runner_state_changed`; conectar `_draft_view.option_selected` y
  `_draft_view.reroll_requested` a dos nuevos handlers (estas dos conexiones
  son de una sola vez, sobre el nodo persistente `_draft_view`, a diferencia
  de las conexiones a `draft` que se rehacen en cada `set_draft()`).
- Nuevo campo `_ready_for_next_wave: bool = true`.
- `_unhandled_input`: la condición pasa a ser
  `event.is_action_pressed("ui_accept") and _ready_for_next_wave and
  _current_wave_index < _wave_schedule.size()`; al disparar, poner
  `_ready_for_next_wave = false` y llamar `_battle_runner.start(_grid,
  _combat_path, _defender_catalog, _wave_schedule[_current_wave_index])`
  (reemplaza el uso de `_wave_data` por el elemento actual del schedule; ya
  no se consulta `_battle_runner.state` para el gate, `_ready_for_next_wave`
  lo reemplaza por completo).
- `_on_battle_runner_state_changed(new_state: BattleRunner.State) -> void`:
  si `new_state != BattleRunner.State.FINISHED`, no hacer nada. Si es
  `FINISHED`: incrementar `_current_wave_index`; si ya
  `_current_wave_index >= _wave_schedule.size()`, no hacer nada más (la demo
  del sandbox termina ahí, sin más waves ni draft — esperado, no es un bug).
  Si todavía queda wave siguiente: crear `_draft = Draft.new(_draft_pool,
  _rng, REROLL_COST)`, conectar `_draft.option_chosen` a un nuevo
  `_on_draft_option_chosen`, y llamar
  `_draft_view.set_draft(_draft, _player_economy)`.
- `_on_draft_option_chosen(_option: DraftOption) -> void`: `_draft = null`,
  `_ready_for_next_wave = true`. (`_draft_view` ya se oculta a sí misma al
  recibir esta misma señal — `main.gd` no la vuelve a esconder, solo
  reacciona a nivel de composition root.)
- `_on_draft_option_selected(index: int) -> void`: si `_draft == null`,
  ignorar (no debería poder pasar si `_draft_view` está oculta, pero es una
  guarda barata); si no, `_draft.choose(index, _grid, _piece_source)`.
- `_on_draft_reroll_requested() -> void`: si `_draft == null`, ignorar; si
  no, `_draft.reroll(_player_economy)`.

**`scenes/main/main.tscn`**: agregar dos nodos nuevos, hermanos de los que ya
existen:
- Un `Label` llamado `GoldCounterView` con el script `gold_counter_view.gd`.
- Un nodo instanciando `scenes/UI/Draft/DraftView.tscn`, llamado `DraftView`.

Los nombres de nodo deben coincidir exactamente con los `@onready var
_gold_counter_view: GoldCounterView = $GoldCounterView` /
`_draft_view: DraftView = $DraftView` que se agregan a `main.gd`.

### Call sites verificados que NO requieren cambios

`BattleRunner` y `CombatSimulation`: cero cambios (confirmado que
`BattleRunner.start()` no tiene guard de estado, así que el loop de waves no
los necesita tocar). `InventoryGridView`, `InventoryPieceSourceView`,
`InventoryInteractionController`: cero cambios, `_piece_source` sigue
usándose exactamente igual que hoy en su cableado existente, solo cambia de
variable local a campo.

### Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto al resto de la capa `UI/` y
a `InventoryInteractionController`/`main.gd`: no llevan tests headless. La
verificación de esta branch es manual, en el editor de Godot — ver
Definición de hecho.

### Documentación a actualizar

- `README.md`: agregar notas de diseño nuevas en la sección `### Draft`
  (agregada en 4a) describiendo `DraftView`/`GoldCounterView` y el loop de
  waves de sandbox, siguiendo el mismo estilo que las notas de "Battle" y
  "main.gd" ya documentan sus propias vistas y su propio cableado. Actualizar
  la sección "Próximo objetivo": la línea sobre reemplazar el
  `DefenderCatalog`/`WaveData` de sandbox por configuración real de ronda
  ahora aplica también al `_wave_schedule`/`_draft_pool` de sandbox
  agregados acá.
- `TODO.md`: no requiere cambios (mismo motivo que en branches anteriores).

### Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse — esta
  branch no debería romper ningún test automatizado ya que no toca ningún
  archivo con tests.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot (correr `main.tscn`): arrancar la
  primera wave con Enter, ver el contador de oro subir a medida que mueren
  enemigos, ver el panel de draft aparecer al terminar la wave con 3 opciones
  legibles, confirmar que el botón de reroll está deshabilitado si no alcanza
  el oro y descuenta + cambia las opciones si se presiona con oro suficiente,
  elegir una opción y confirmar que aplica (una pieza nueva aparece en
  `InventoryPieceSourceView`, o el grid se ve más grande), y que Enter vuelve
  a arrancar la segunda wave del schedule. Mismo tipo de verificación manual
  que ya hiciste para la branch 2 (gatillo de debug temporal si hace falta
  aislar un paso, revertido antes de commitear).

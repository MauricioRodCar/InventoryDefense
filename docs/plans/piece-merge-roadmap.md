# Roadmap: fusión de piezas

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como **arquitecto**
del proyecto, para que otra instancia sin contexto general (una por branch,
sin memoria de las demás) pueda ejecutar cada paso sin tener que re-derivar
el diseño. Antes de implementar cualquier branch: leer `CLAUDE.md` (reglas
del proyecto) y las secciones relevantes de `README.md` (documenta el "por
qué" de cada decisión de arquitectura ya tomada). Seguir la regla del
proyecto: **explicar el plan antes de programar** — si algo de esta spec no
cierra con el código real al momento de implementarla, parar y preguntar
antes de improvisar.

## Objetivo de producto

Dos piezas colocadas del mismo tipo y del mismo rango se pueden fusionar en
una sola pieza de rango superior, hasta un número definido de veces. El
jugador dispara la fusión arrastrando una pieza (desde el grid o desde la
fuente de piezas) y soltándola exactamente sobre otra pieza compatible ya
colocada — mismo gesto que ya existe para colocar, reutilizando el sistema
de drag&drop, sin un flujo de selección aparte.

Decisiones de producto ya tomadas para este roadmap:
- El límite de fusiones es un tope global de rango (no por tipo), simple:
  toda pieza puede llegar como máximo a rango 3 (dos fusiones posibles desde
  rango 1). Es un valor de sandbox ajustable, no una regla de diseño final.
- Las estadísticas de cada rango se definen a mano por completo (un
  `DefenderData` por combinación tipo+rango, mismo estilo que los arquetipos
  actuales), no por una fórmula de escalado automático.
- La apariencia visual de una pieza de rango superior queda **deliberadamente
  sin definir** en este roadmap — el usuario todavía no decidió cómo quiere
  que se vean las piezas fusionadas. Ninguna branch de este roadmap debe
  inventar esa respuesta; solo debe dejar el sistema funcionalmente completo
  y fácil de conectar a una representación visual real después.

## Por qué 3 branches y en este orden

Regla del proyecto: no modificar varios sistemas en una sola tarea. La
fusión toca tres dominios distintos que ya existen como capas separadas en
el código: Inventory (el propio concepto de rango y la operación de fusión),
UI (el gesto de arrastrar-y-soltar-sobre-otra), y Bridge (que un rango
distinto produzca un `Defender` distinto en combate). Mismo criterio que ya
se usó en el roadmap de la fuente real de piezas: cada capacidad se
construye y testea de forma aislada, y las branches que la consumen solo
llaman a su API pública ya existente.

| # | Branch | Dominio que modifica | Qué agrega | Depende de |
|---|--------|----------------------|------------|------------|
| A | `feature/inventory-piece-merge` | Inventory | `InventoryPiece` gana `rank`; `InventoryGrid` gana `can_merge`/`merge_pieces`. 100% headless, sin UI. | — |
| B | `feature/merge-drag-trigger` | UI (`InventoryInteractionController`, `InventoryPlacementPreviewView`) | Soltar una pieza sobre otra compatible fusiona en vez de fallar la colocación; el preview distingue ese caso. | A |
| C | `feature/rank-aware-defender-catalog` | Bridge | `DefenderCatalog`/`DefenderData` quedan indexados por (tipo, rango); una pieza fusionada produce un `Defender` más fuerte en combate. | A |

B y C son independientes entre sí (ambas solo dependen de A) y se pueden
ejecutar en paralelo. Ninguna de las tres depende del roadmap de fuente real
de piezas (ya completo) más allá de que ambos comparten `InventoryPiece`.

Las tres branches están **completamente especificadas y listas para
implementar**, cada una de forma independiente y autocontenida — pensadas
para que cada una la ejecute una instancia distinta sin contexto compartido
entre ellas.

---

## Branch A — `feature/inventory-piece-merge` (lista para implementar)

### Problema

No existe ningún concepto de "rango" en `InventoryPiece`, ni ninguna forma
de combinar dos piezas. El pitch del juego pide que piezas del mismo tipo se
puedan fusionar para mejorarse, un número definido de veces.

### Diseño

- `InventoryPiece` gana `var rank: int = 1` — toda pieza nueva arranca en
  rango 1 (nadie construye una pieza ya fusionada; solo se llega a rango > 1
  fusionando). Gana también `const MAX_RANK := 3` — tope simple y global,
  independiente de qué tipo de pieza sea; es una constante de sandbox
  ajustable más adelante si el diseño final pide topes distintos por tipo,
  no una decisión final de balance.
- Nuevo método privado `_increase_rank() -> void: rank += 1` — mismo patrón
  que `_place_at`/`_clear_placement`: mutador reservado por convención a
  `InventoryGrid` (única autoridad de colocación y ahora también de fusión).
- `InventoryGrid` gana `can_merge(source: InventoryPiece, target:
  InventoryPiece) -> bool`: `true` si `source`/`target` no son `null`, no
  son el mismo objeto, `target.is_placed()`, `source.type_id ==
  target.type_id`, `source.rank == target.rank`, y `source.rank <
  InventoryPiece.MAX_RANK`. **No** exige que `source` esté colocada: en el
  uso real (branch B), `source` es la pieza que se está arrastrando, que ya
  fue removida del grid (o nunca estuvo colocada, si viene de
  `InventoryPieceSource`) en el momento en que se evalúa esto — mismo
  espíritu que `can_place(piece, anchor)` ya evalúa una pieza sin colocar
  contra el estado del grid.
- `InventoryGrid` gana `merge_pieces(source: InventoryPiece, target:
  InventoryPiece) -> bool`: si `not can_merge(source, target)`, devuelve
  `false` sin mutar nada — mismo idioma que `place_piece` (se auto-valida,
  devuelve `bool`, no asume que quien llama ya validó). Si es válido, llama
  `target._increase_rank()`, emite `pieces_merged(source, target)`, y
  devuelve `true`.
- **Importante:** `merge_pieces` no hace ningún bookkeeping de grid sobre
  `source` (no la busca en `_cells`/`_pieces`, no la remueve). No hace
  falta: en el único flujo real que existirá (branch B), `source` ya está
  fuera del grid antes de que esto se llame (fue removida al empezar el
  arrastre, o nunca estuvo colocada si vino de la fuente) — la limpieza de
  su vista visual ya la resuelve el mecanismo de arrastre existente sin
  ningún cambio adicional (ver notas de branch B). `merge_pieces` confía en
  que quien la llama ya dejó a `source` fuera del grid, mismo nivel de
  confianza que `place_piece` confía en que `piece.is_placed()` refleja el
  estado real.
- Nueva señal `signal pieces_merged(source: InventoryPiece, target:
  InventoryPiece)` — `target` es la pieza sobreviviente (con el rango ya
  incrementado), `source` es la consumida. Se emite después de mutar,
  mismo patrón que `piece_placed`/`piece_removed`/`grid_expanded`.

### Cambios exactos por archivo

**`Scripts/Gameplay/Inventory/inventory_piece.gd`**
- Agregar `const MAX_RANK := 3`.
- Agregar `var rank: int = 1`.
- Agregar `func _increase_rank() -> void: rank += 1`, con el mismo comentario
  de "uso interno de InventoryGrid" que ya llevan `_place_at`/
  `_clear_placement`.
- Actualizar el comentario de clase mencionando brevemente `rank`/`MAX_RANK`.

**`Scripts/Gameplay/Inventory/inventory_grid.gd`**
- Agregar `signal pieces_merged(source: InventoryPiece, target:
  InventoryPiece)`.
- Agregar `can_merge(source, target) -> bool` y `merge_pieces(source,
  target) -> bool` con el comportamiento descrito arriba.
- Actualizar el comentario de clase mencionando la nueva capacidad.

### Call sites verificados que NO requieren cambios

Ningún archivo existente llama todavía a nada de esto — es puramente
aditivo. `InventoryPieceSourceSandbox` sigue construyendo piezas igual que
hoy (`InventoryPiece.new(type_id, shape)`), todas arrancan en `rank = 1` por
el valor por defecto del campo, sin necesidad de tocar su constructor.

### Tests nuevos a agregar

1. **`Tests/Gameplay/Inventory/test_inventory_piece.gd`**: una pieza nueva
   arranca en `rank == 1`.
2. **`Tests/Gameplay/Inventory/test_inventory_grid.gd`**:
   - `can_merge` es `true` para dos piezas colocadas, mismo `type_id`,
     mismo `rank`, `rank < MAX_RANK`.
   - `can_merge` es `false` si difiere el `type_id`, si difiere el `rank`,
     si `target` no está colocada, si `source == target`, o si `source.rank
     >= InventoryPiece.MAX_RANK`.
   - `merge_pieces` con un par válido: `target.rank` sube en 1, emite
     `pieces_merged(source, target)` exactamente una vez, devuelve `true`.
   - `merge_pieces` con un par inválido (p. ej. distinto `type_id`):
     devuelve `false`, no muta `rank` de ninguna de las dos piezas, no
     emite nada.

### Documentación a actualizar

- `README.md`: agregar una nota de diseño nueva en la sección Inventario
  (mismo estilo que el resto) describiendo `rank`/`MAX_RANK`/`can_merge`/
  `merge_pieces`/`pieces_merged`, y explicando por qué `merge_pieces` no
  hace bookkeeping de `source` (la limpieza ya la resuelve el mecanismo de
  arrastre existente, ver branch B cuando esté mergeada). Aclarar que
  `MAX_RANK` es un tope de sandbox simple, no una decisión final de balance,
  y que la apariencia visual de una pieza de rango superior queda sin
  definir a propósito.
- `TODO.md`: agregar `[x] Fusión de piezas` bajo la sección `## Inventario`
  (hoy tiene un ítem `[ ] Fusión de piezas` sin marcar) una vez que las tres
  branches de este roadmap estén completas — no marcarlo todavía en esta
  branch sola, porque el sistema no es utilizable de punta a punta hasta que
  B (el gesto) exista.

### Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (excepto los dos
  archivos donde se agregan tests nuevos).
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único (esta branch modifica un solo sistema: Inventory).

---

## Branch B — `feature/merge-drag-trigger` (lista para implementar una vez A esté mergeada)

### Problema

`InventoryGrid.can_merge`/`merge_pieces` (branch A) existen pero nada los
llama todavía. El gesto para fusionar debe ser el mismo que ya existe para
colocar: arrastrar y soltar.

### Diseño

**Detección del objetivo de fusión** — nueva función privada en
`InventoryInteractionController`:

```
func _find_merge_target(piece: InventoryPiece, candidate_anchor: Vector2i) -> InventoryPiece:
    var target := _grid.get_piece_at(candidate_anchor)
    if target == null or target.anchor != candidate_anchor:
        return null
    if not _grid.can_merge(piece, target):
        return null
    return target
```

Por qué exigir `target.anchor == candidate_anchor` y no solo "hay algo en
esa celda": como dos piezas del mismo `type_id` comparten siempre el mismo
`ShapeData` (mismo tipo → misma forma), si sus anclas coinciden, sus huellas
de celdas ocupadas coinciden exactamente — es un solapamiento total, no
parcial. Sin esta condición, arrastrar una pieza de forma irregular (p. ej.
`corner`) de manera que solo roce una esquina de otra pieza dispararía una
fusión que visualmente no tiene sentido (las piezas no quedarían
superpuestas de verdad). Esto reutiliza `candidate_anchor`, que ya se
calcula hoy para `can_place` — no hace falta ninguna geometría nueva.

**En `_end_drag()`**: agregar la detección de fusión como la primera rama,
antes del `can_place` existente:

```
func _end_drag() -> void:
    var piece: InventoryPiece = _dragged_piece
    var local_pos: Vector2 = grid_view.get_local_mouse_position()
    var cursor_cell: Vector2i = grid_view.position_to_cell(local_pos)
    var target_anchor: Vector2i = cursor_cell - _drag_grab_cell_offset
    var merge_target: InventoryPiece = _find_merge_target(piece, target_anchor)
    if merge_target != null:
        _grid.merge_pieces(piece, merge_target)
    elif _grid.can_place(piece, target_anchor):
        _settle_piece_at(piece, target_anchor)
    elif _drag_from_source:
        _piece_source.return_piece(piece)
    else:
        _settle_piece_at(piece, _drag_origin_anchor)
    _destroy_ghost()
    _destroy_preview()
    _dragged_piece = null
```

**Por qué `InventoryGridView` no necesita ningún cambio para esto** (lean
esto con cuidado antes de tocar nada de `UI/Inventory/`): la vista de la
pieza arrastrada (`piece`, la que se convierte en `source` de la fusión) ya
fue destruida al empezar el arrastre — `_try_begin_drag_from_grid()` llama
`_grid.remove_piece(piece)`, que ya emitió `piece_removed` y ya hizo que
`InventoryGridView` destruyera su vista; `_try_begin_drag_from_source()`
llama `_piece_source.take_piece(piece)`, que ya destruyó su
`InventoryPieceSourceSlotView`. En ambos casos, al llegar a `merge_pieces`
esa pieza ya no tiene ninguna vista viva en ningún lado — fusionar
simplemente significa "no volver a colocarla ni devolverla", que es
exactamente lo que hace la rama nueva (no llama `_settle_piece_at` ni
`_piece_source.return_piece` para `piece`). La pieza sobreviviente
(`target`) sigue siendo el mismo objeto de siempre en `_piece_views` de
`InventoryGridView` (su identidad no cambia, solo su `rank`), así que su
vista tampoco necesita recrearse. **No se debe agregar código a
`InventoryGridView`/`InventoryPieceView` en esta branch** — no hace falta, y
la apariencia de una pieza de rango superior queda sin definir a propósito
(ver Contexto del roadmap).

**Preview durante el arrastre** — sin este ajuste, quedaría un bug de
feedback real: hoy, pasar el cursor sobre una celda ocupada muestra el
preview en rojo (inválido) porque `can_place` falla ahí; con la fusión ya
implementada, soltar en esa misma celda a veces *sí* tendría éxito (fusión)
— el preview mentiría. Agregar un tercer estado:

- **`Scripts/UI/Inventory/inventory_placement_preview_view.gd`**: agregar
  `MERGE` al enum `State`, y una entrada nueva en `COLOR_BY_STATE` con un
  color claramente distinto de verde/rojo (p. ej. dorado/violeta — es un
  placeholder, la apariencia final queda para cuando el usuario defina el
  arte de las piezas).
- **`InventoryInteractionController._update_placement_preview()`**: antes
  de consultar `can_place`, consultar primero `_find_merge_target`; si
  encuentra un objetivo válido, usar `State.MERGE`; si no, mantener la
  lógica actual (`VALID`/`INVALID` según `can_place`).

### Cambios exactos por archivo

**`Scripts/UI/Inventory/inventory_interaction_controller.gd`**
- Agregar el método privado `_find_merge_target` descrito arriba.
- Modificar `_end_drag()` según el snippet de arriba.
- Modificar `_update_placement_preview()` para consultar `_find_merge_target`
  antes que `can_place` y elegir `State.MERGE` cuando corresponda.

**`Scripts/UI/Inventory/inventory_placement_preview_view.gd`**
- Agregar `MERGE` al enum `State` y su entrada en `COLOR_BY_STATE`.

### Call sites verificados que NO requieren cambios

`InventoryGridView`, `InventoryPieceView`, `InventoryPieceSourceSlotView`,
`InventoryDragGhostView`: cero cambios (ver razonamiento completo en
Diseño). `InventoryGrid`, `InventoryPiece`: cero cambios adicionales más
allá de lo que ya trajo la branch A.

### Tests nuevos a agregar

Ninguno. Mismo criterio que ya aplica el proyecto al resto de la capa `UI/`
(`InventoryInteractionController` no lleva tests headless hoy tampoco). La
verificación es manual, en el editor de Godot.

### Documentación a actualizar

- `README.md`: agregar una nota de diseño nueva en la sección Inventario
  (junto a las notas de interacción de drag existentes) explicando el gesto
  de fusión, `_find_merge_target`, por qué exige `target.anchor ==
  candidate_anchor`, el nuevo estado `MERGE` del preview, y por qué
  `InventoryGridView`/`InventoryPieceView` no necesitaron cambios.
- `TODO.md`: si branch C también está mergeada para este punto, marcar
  `[x] Fusión de piezas`; si no, dejarlo sin marcar todavía (el sistema
  necesita las tres branches para ser útil de punta a punta en combate).

### Definición de hecho

- Todos los tests existentes (headless) siguen pasando sin modificarse.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: colocar dos piezas del mismo
  tipo en el grid, arrastrar una exactamente sobre la otra y soltar —
  confirmar que se fusionan (una desaparece, la otra permanece) y no un
  crash ni un estado raro. Repetir arrastrando desde la fuente de piezas
  sobre una ya colocada del mismo tipo. Confirmar que el preview muestra un
  color distinto (ni verde ni rojo) al pasar por encima de un objetivo de
  fusión válido, y que fusionar tres veces seguidas la misma pieza hasta
  `MAX_RANK` deja de permitir una cuarta fusión (`can_merge` debe devolver
  `false` una vez alcanzado el tope).

---

## Branch C — `feature/rank-aware-defender-catalog` (lista para implementar una vez A esté mergeada)

### Problema

`DefenderCatalog.get_defender_data(piece_type_id)` hoy ignora por completo
el rango de la pieza — una pieza fusionada (branch A/B) pelearía
exactamente igual que una sin fusionar. La fusión no tiene ningún efecto en
combate todavía.

### Diseño

- `DefenderCatalog.Entry` gana un campo `rank: int` (además de
  `piece_type_id`/`defender_data` que ya tiene).
- `DefenderCatalog` cambia su estructura interna de `Dictionary`
  (`StringName -> DefenderData`) a un diccionario anidado (`StringName ->
  Dictionary[int, DefenderData]`) — evita inventar una clave compuesta tipo
  string (`"square#2"`), que sería más frágil y menos legible que anidar un
  diccionario por cada nivel de la clave.
- `get_defender_data(piece_type_id: StringName, rank: int) -> DefenderData`
  (gana un segundo parámetro): busca primero por `piece_type_id`, después
  por `rank` dentro de eso; devuelve `null` si falta cualquiera de los dos
  niveles — mismo comportamiento "sin entrada, sin romper nada" que ya tenía
  antes de este cambio.
- `DefenderTranslator.translate()` pasa a llamar
  `catalog.get_defender_data(piece.type_id, piece.rank)` en vez de
  `catalog.get_defender_data(piece.type_id)`.
- `main.gd`: el catálogo de sandbox (`_build_sandbox_defender_catalog()`)
  gana entradas de rango 2 y 3 para cada uno de los tres arquetipos
  existentes (Vanguardia/Rematador/Artillero), con daño mayor a mano por
  rango (no una fórmula) — valores sugeridos, ajustables libremente:
  - Vanguardia (`square`): rango 1 daño 8 (ya existe) → rango 2 daño 12 →
    rango 3 daño 18.
  - Rematador (`bar`): rango 1 daño 4 (ya existe) → rango 2 daño 6 → rango 3
    daño 9.
  - Artillero (`corner`): rango 1 daño 2 (ya existe) → rango 2 daño 3 →
    rango 3 daño 5.
  Cadencia (`attack_interval`), `WeaponBehavior` y `TargetingPolicy` se
  mantienen iguales entre rangos del mismo tipo — solo el daño escala; es
  la decisión más simple que demuestra el sistema funcionando, no un diseño
  de balance final.

### Cambios exactos por archivo

**`Scripts/Gameplay/Bridge/defender_catalog.gd`**
- `Entry` gana `var rank: int` y el parámetro correspondiente en `_init`.
- Cambiar `_entries` a diccionario anidado y actualizar `_init`/
  `get_defender_data` según lo descrito.

**`Scripts/Gameplay/Bridge/defender_translator.gd`**
- Cambiar la llamada a `catalog.get_defender_data(piece.type_id,
  piece.rank)`.

**`Scripts/Main/main.gd`**
- `_build_sandbox_defender_catalog()`: agregar las 6 entradas nuevas (rango
  2 y 3 de cada uno de los 3 arquetipos) con los valores sugeridos arriba,
  además de las 3 que ya existen (que ahora deben construirse con `rank: 1`
  explícito en su `DefenderCatalog.Entry.new(...)`).

### Call sites verificados que NO requieren cambios

Confirmado por búsqueda en el repo: `get_defender_data` solo la llama
`DefenderTranslator`. Ningún test de `test_defender_catalog.gd` asume la
firma vieja de una forma que no se pueda actualizar junto con el cambio (ver
Tests nuevos).

### Tests nuevos a agregar / a actualizar

1. **`Tests/Gameplay/Bridge/test_defender_catalog.gd`**: actualizar los
   tests existentes para pasar `rank` a `Entry.new(...)` y a
   `get_defender_data(...)` (revisar el archivo real: probablemente ya
   asume rango 1 implícito en sus casos actuales, ahora hay que pasarlo
   explícito). Agregar un caso nuevo: dos entradas con el mismo
   `piece_type_id` pero distinto `rank` devuelven `DefenderData` distintos
   cada una vía `get_defender_data(type_id, rank)`.
2. **`Tests/Gameplay/Bridge/test_defender_translator.gd`**: agregar un caso
   donde una `InventoryPiece` con `rank == 2` (asignado manualmente en el
   test, sin pasar por una fusión real) se traduce usando la entrada de
   rango 2 del catálogo, no la de rango 1.

### Documentación a actualizar

- `README.md`: actualizar la nota de Bridge que describe
  `DefenderCatalog`/`DefenderTranslator` para reflejar que la clave ahora es
  (tipo, rango), explicando por qué se usa un diccionario anidado en vez de
  una clave compuesta. Actualizar también la nota sobre los arquetipos de
  sandbox en `main.gd` mencionando que ahora tienen versiones de rango 2 y
  3. Marcar `[x] Fusión de piezas` en `TODO.md` si no se hizo ya en branch
  B (esta branch es la que completa el sistema de punta a punta: fusionar
  ahora sí cambia el resultado de una batalla).

### Definición de hecho

- Todos los tests existentes pasan (actualizando los dos archivos de test
  listados arriba, sin romper ningún otro).
- Los tests nuevos de esta branch pasan.
- `README.md`/`TODO.md` actualizados.
- Commit único (esta branch modifica un solo sistema: Bridge, con contenido
  de sandbox en `main.gd` como consecuencia directa, mismo criterio que ya
  se usó para el catálogo de arquetipos original).

# Inventory Defense

Juego 2D de estrategia que combina gestión de inventario por cuadrícula y defensa por oleadas.

## Concepto

El jugador obtiene piezas con formas geométricas y debe acomodarlas dentro de un inventario limitado.

Las piezas colocadas se convierten en unidades que combaten enemigos durante rondas automáticas.

## Estado actual

Prototipo en desarrollo.

## Tecnología

- Motor: Godot 4.7
- Lenguaje: GDScript
- Control de versiones: Git

## Filosofía de desarrollo

El proyecto se desarrolla mediante vertical slices:

- Cada funcionalidad vive en su propia branch.
- `main` siempre debe permanecer ejecutable.
- La lógica del juego debe estar desacoplada de la presentación.
- Los sistemas deben tener tests cuando sea posible.

## Sistemas implementados

### Inventario

Estado:
✅ Dominio base implementado
✅ Visualización dentro de Godot
✅ Interacción básica: seleccionar, arrastrar y colocar una pieza
✅ Fuente de piezas desacoplada del origen (PieceSource)
✅ Preview visual de validez de colocación durante el arrastre

Incluye:

- ShapeData, InventoryPiece, InventoryGrid (dominio; sin dependencias de Godot)
- InventoryPieceSource (dominio; propietario de las piezas disponibles todavía no colocadas), InventoryPieceSourceSandbox (implementación de prueba, placeholder a reemplazar por tienda/cofres/recompensas/draft/crafting)
- InventoryGridView, InventoryPieceView, InventoryGridBackground (representación visual reactiva a las señales de InventoryGrid)
- InventoryPieceSourceView, InventoryPieceSourceSlotView (representación visual reactiva a las señales de InventoryPieceSource)
- InventoryInteractionController (input de arrastre vía `_unhandled_input`; orquesta take/return sobre InventoryPieceSource y remove/can_place/place sobre InventoryGrid, sin conocer de dónde viene concretamente cada pieza)
- InventoryDragGhostView (representación visual flotante mientras se arrastra una pieza; no depende de InventoryPiece, solo de ShapeData)
- InventoryPlacementPreviewView (feedback visual verde/rojo de si la celda candidata bajo el cursor sería una colocación válida durante el arrastre; no conoce InventoryGrid ni reglas de colocación, solo un State que le empuja InventoryInteractionController)
- Tests headless

#### Notas de diseño — interacción de inventario

- `InventoryGrid` sigue siendo la única autoridad sobre el inventario: el drag se implementa como `remove_piece` al iniciar el arrastre + `place_piece` al soltar (válido o restaurando el ancla original). Esas dos llamadas están aisladas en métodos privados de `InventoryInteractionController` (`_take_piece_from_grid` / `_settle_piece_at`) para poder sustituirlas por un futuro `move_piece` atómico sin rediseñar el flujo.
- `InventoryPieceSource` es la única autoridad sobre qué piezas están disponibles sin colocar: `take_piece`/`return_piece` cumplen el mismo rol de origen/restauración que `remove_piece`/`place_piece` cumplen en el grid.
- `InventoryInteractionController` no conoce ningún tipo concreto de fuente: solo distingue dos orígenes posibles de un drag (`InventoryGrid` o `InventoryPieceSource`) mediante dos métodos privados explícitos (`_try_begin_drag_from_grid` / `_try_begin_drag_from_source`), sin introducir una jerarquía de "proveedores de drag". Si en el futuro aparece un tercer tipo de origen con reglas propias de interacción, ahí sí valdría la pena extraer un contrato común.
- `InventoryGridView` e `InventoryPieceView` no se modificaron: la representación temporal del arrastre vive en la clase `InventoryDragGhostView`, y la representación de piezas ofrecidas vive en `InventoryPieceSourceSlotView`, evitando forzar a `InventoryPieceView` a soportar geometría de una pieza no colocada.
- El punto exacto de la pieza donde el jugador hace clic se preserva durante el arrastre solo cuando el origen es el grid (en espacio de celdas, no de píxeles), de forma que la celda agarrada quede siempre bajo el cursor. TODO: al arrastrar desde `InventoryPieceSource` esto no está implementado todavía — se agarra siempre la celda (0,0) de la forma y el ghost no conserva el offset del clic; aceptado deliberadamente para esta iteración, pendiente de igualar con el comportamiento del grid.
- `InventoryPieceSourceSandbox` es intencionalmente mínimo (un puñado de piezas variadas ofrecidas al construirse); no implementa compra, economía, rareza, reroll ni reposición automática.
- El preview de colocación (`InventoryPlacementPreviewView`) es una vista independiente de `InventoryDragGhostView`, no una extensión suya: el ghost sigue el cursor en píxeles (con el offset de agarre), mientras que el preview se ancla a la celda candidata (snapeada a grid), que es lo que realmente evaluará `InventoryGrid.can_place()`. Mezclar ambos habría acoplado al ghost a una regla de dominio que no le corresponde conocer.
- `InventoryInteractionController` sigue siendo el único llamador de `InventoryGrid.can_place()`; ahora lo consulta también durante `_update_drag` (antes solo al soltar), pero cachea la última celda ancla evaluada (`_last_preview_anchor`) para no repetir la consulta en cada evento de `InputEventMouseMotion`, solo cuando el cursor cruza a una celda ancla distinta.
- El estado del preview se expresa como `InventoryPlacementPreviewView.State` (enum: `VALID`, `INVALID`) en vez de un bool, para poder añadir más estados en el futuro sin romper el contrato público de la clase.

### Combate

Estado:
✅ Entidades base del dominio implementadas
✅ `CombatSimulation` implementada: simulación determinista ejecutable headless vía `advance(delta)`

Incluye:

- `CombatPath` (dominio; longitud lógica del camino, sin posiciones de mundo)
- `WeaponData` (dominio; definición pura de daño y cadencia de ataque, compartible entre instancias)
- `WeaponInstance` (dominio; instancia de un `WeaponData` en uso, lleva su propio cooldown)
- `Enemy` (dominio; vida y progreso en el camino)
- `Defender` (dominio; compone su capacidad ofensiva vía `WeaponInstance` en vez de tener daño/cadencia embebidos)
- `MovementPhase` (algoritmo sin estado ni propiedad del dominio; calcula cuánto debería avanzar cada enemigo vivo)
- `AttackPhase` (algoritmo sin estado ni propiedad del dominio; decide qué defensor ataca a qué enemigo y con cuánto daño)
- `CombatSimulation` (dominio; única autoridad del combate: dueña del roster de enemigos/defensores y del `CombatPath`, aplica los resultados de las fases y emite las señales)
- Tests headless

#### Notas de diseño — entidades de combate

- Misma filosofía que el inventario: dominio sin dependencias de Godot, ejecutable headless, separación estricta entre dominio (`Enemy`, `Defender`, ...), orquestación (`CombatSimulation`, `MovementPhase`, `AttackPhase`) y representación visual (todavía no implementada).
- `WeaponData` juega el mismo rol que `ShapeData`: definición pura, sin estado, compartible entre múltiples instancias. `WeaponInstance` juega el rol de `InventoryPiece`: instancia con estado de ejecución propio (`cooldown_remaining`), mutado solo mediante métodos privados (`_tick`, `_reset_cooldown`) reservados a `CombatSimulation`. Esta cadena Definition → Runtime Instance → Owner evita que dos `Defender` que comparten el mismo `WeaponData` interfieran entre sí si comparten cooldown por error.
- `Defender` no tiene ni `damage` ni `attack_interval` propios: siempre los obtiene a través de su `weapon_instance`, para que el comportamiento ofensivo no quede embebido directamente en la unidad.
- `Enemy` y `Defender` no se conocen entre sí ni conocen `CombatPath`: cada uno solo protege sus propios invariantes (vida acotada a `[0, max_health]`, progreso nunca negativo). Acotar `path_progress` contra la longitud de un `CombatPath` concreto es responsabilidad de `CombatSimulation`, no de `Enemy`.
- Ninguna de estas entidades emite señales: `CombatSimulation` es la única autoridad de combate y la única emisora, igual que `InventoryGrid`/`InventoryPieceSource` lo son para el inventario.

#### Notas de diseño — `CombatSimulation`

- `CombatSimulation` es dueña del roster (`Array[Enemy]`, `Array[Defender]`) y del `CombatPath` de la ronda. Esta iteración no crea enemigos ni defensores por sí misma (eso es responsabilidad de un futuro `Wave`/integración con `InventoryGrid`): se añaden desde fuera vía `add_enemy`/`add_defender`. `get_enemies()`/`get_defenders()` devuelven copias del array (mismo patrón que `InventoryGrid.get_pieces()`), para que nadie fuera de `CombatSimulation` pueda mutar el roster.
- `MovementPhase` y `AttackPhase` son algoritmos sin estado y sin propiedad del dominio: reciben las colecciones necesarias como parámetros y devuelven resultados (`MovementPhase.Result`, `AttackPhase.Result`) describiendo qué debería pasar, sin mutar `Enemy`/`Defender`/`WeaponInstance` ni el roster. `CombatSimulation` decide si aplica cada resultado, es quien realmente invoca los métodos internos (`_advance`, `_take_damage`, `_tick`, `_reset_cooldown`) y quien emite las señales — así se mantiene como la única autoridad del dominio de combate, con un único punto de mutación en todo el sistema.
- `advance(delta)` se divide en pasos ordenados y deterministas: mover enemigos vivos (`MovementPhase`) → resolver los que llegaron al final del `CombatPath` (remover del roster, emitir `enemy_reached_end`) → tickear cooldowns y resolver ataques (`AttackPhase`, aplicar daño, reiniciar cooldown, emitir `defender_attacked`) → resolver enemigos derrotados (remover del roster, emitir `enemy_defeated`). El tick de cooldown ocurre en `CombatSimulation` antes de llamar a `AttackPhase`, porque es tiempo pasando (no una decisión de combate); `AttackPhase` solo lee `is_ready()`.
- Regla de selección de objetivo de `AttackPhase` para esta iteración: cada defensor listo ataca al enemigo vivo con mayor `path_progress` (el más cercano a llegar al final del camino). Es deliberadamente mínima porque "Alcance" está fuera de esta iteración: no hay posiciones ni rango, solo el progreso que ya existe en `Enemy`.
- `CombatSimulation` no expone `enemy_added`/`defender_added`: por ahora solo emite eventos de dominio relevantes (`enemy_reached_end`, `enemy_defeated`, `defender_attacked`).
- Todo `delta` se recibe como parámetro explícito (nunca leído de `Engine.get_process_delta_time()` ni de un `Timer`), para que la simulación sea determinista y completamente controlable desde tests headless.

### Próximo objetivo

Implementar `Wave` para poblar el roster de `CombatSimulation` con enemigos a lo largo de una ronda completa.

Integrar `CombatSimulation` con `InventoryGrid` para que las piezas colocadas se conviertan en `Defender`.

Implementar una fuente real de piezas sobre `InventoryPieceSource` (tienda, cofres, recompensas, draft o crafting).
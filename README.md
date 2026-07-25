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
✅ `Wave` implementada: puebla el roster de enemigos automáticamente según un calendario, además del `add_enemy` manual (pruebas)

Incluye:

- `CombatPath` (dominio; longitud lógica del camino, sin posiciones de mundo)
- `WeaponData` (dominio; definición pura de daño y cadencia de ataque, compartible entre instancias)
- `WeaponInstance` (dominio; instancia de un `WeaponData` en uso, lleva su propio cooldown)
- `Enemy` (dominio; vida y progreso en el camino)
- `EnemyData` (dominio; definición pura de vida máxima y velocidad de un tipo de enemigo, compartible entre entradas de una `Wave`)
- `Defender` (dominio; compone su capacidad ofensiva vía `WeaponInstance` en vez de tener daño/cadencia embebidos)
- `WaveData` (dominio; calendario ordenado de spawn — tiempo + `EnemyData` — sin estado de ejecución)
- `Wave` (dominio; instancia en ejecución de un `WaveData`, con su propio reloj y cursor; `advance(delta)` devuelve qué `EnemyData` deberían aparecer, sin crear `Enemy`)
- `MovementPhase` (algoritmo sin estado ni propiedad del dominio; calcula cuánto debería avanzar cada enemigo vivo)
- `AttackPhase` (algoritmo sin estado ni propiedad del dominio; decide qué defensor ataca a qué enemigo y con cuánto daño)
- `CombatSimulation` (dominio; única autoridad del combate: dueña del roster de enemigos/defensores, del `CombatPath` y opcionalmente de una `Wave`; aplica los resultados de las fases y emite las señales)
- Tests headless

#### Notas de diseño — entidades de combate

- Misma filosofía que el inventario: dominio sin dependencias de Godot, ejecutable headless, separación estricta entre dominio (`Enemy`, `Defender`, ...), orquestación (`CombatSimulation`, `MovementPhase`, `AttackPhase`) y representación visual (todavía no implementada).
- `WeaponData` juega el mismo rol que `ShapeData`: definición pura, sin estado, compartible entre múltiples instancias. `WeaponInstance` juega el rol de `InventoryPiece`: instancia con estado de ejecución propio (`cooldown_remaining`), mutado solo mediante métodos privados (`_tick`, `_reset_cooldown`) reservados a `CombatSimulation`. Esta cadena Definition → Runtime Instance → Owner evita que dos `Defender` que comparten el mismo `WeaponData` interfieran entre sí si comparten cooldown por error.
- `Defender` no tiene ni `damage` ni `attack_interval` propios: siempre los obtiene a través de su `weapon_instance`, para que el comportamiento ofensivo no quede embebido directamente en la unidad.
- `Enemy` y `Defender` no se conocen entre sí ni conocen `CombatPath`: cada uno solo protege sus propios invariantes (vida acotada a `[0, max_health]`, progreso nunca negativo). Acotar `path_progress` contra la longitud de un `CombatPath` concreto es responsabilidad de `CombatSimulation`, no de `Enemy`.
- Ninguna de estas entidades emite señales: `CombatSimulation` es la única autoridad de combate y la única emisora, igual que `InventoryGrid`/`InventoryPieceSource` lo son para el inventario.

#### Notas de diseño — `CombatSimulation`

- `CombatSimulation` es dueña del roster (`Array[Enemy]`, `Array[Defender]`), del `CombatPath` de la ronda y opcionalmente de una `Wave`. Esta iteración no crea defensores por sí misma (eso es responsabilidad de una futura integración con `InventoryGrid`): se añaden desde fuera vía `add_defender`. Los enemigos pueden añadirse manualmente vía `add_enemy` (uso de pruebas) o poblarse automáticamente a partir de la `Wave`, si se proporcionó una al construir la simulación. `get_enemies()`/`get_defenders()` devuelven copias del array (mismo patrón que `InventoryGrid.get_pieces()`), para que nadie fuera de `CombatSimulation` pueda mutar el roster.
- `MovementPhase` y `AttackPhase` son algoritmos sin estado y sin propiedad del dominio: reciben las colecciones necesarias como parámetros y devuelven resultados (`MovementPhase.Result`, `AttackPhase.Result`) describiendo qué debería pasar, sin mutar `Enemy`/`Defender`/`WeaponInstance` ni el roster. `CombatSimulation` decide si aplica cada resultado, es quien realmente invoca los métodos internos (`_advance`, `_take_damage`, `_tick`, `_reset_cooldown`) y quien emite las señales — así se mantiene como la única autoridad del dominio de combate, con un único punto de mutación en todo el sistema.
- `advance(delta)` se divide en pasos ordenados y deterministas: mover enemigos vivos (`MovementPhase`) → resolver los que llegaron al final del `CombatPath` (remover del roster, emitir `enemy_reached_end`) → spawnear los enemigos que correspondan según la `Wave` (crear `Enemy` a partir de los `EnemyData` liberados, añadirlos al roster, emitir `enemy_spawned`) → tickear cooldowns y resolver ataques (`AttackPhase`, aplicar daño, reiniciar cooldown, emitir `defender_attacked`) → resolver enemigos derrotados (remover del roster, emitir `enemy_defeated`). El tick de cooldown ocurre en `CombatSimulation` antes de llamar a `AttackPhase`, porque es tiempo pasando (no una decisión de combate); `AttackPhase` solo lee `is_ready()`. Spawnear después de mover implica que un enemigo recién aparecido no avanza en el mismo `advance()` en el que fue creado — no existía todavía cuando `MovementPhase` calculó los avances de ese tick.
- Regla de selección de objetivo de `AttackPhase` para esta iteración: cada defensor listo ataca al enemigo vivo con mayor `path_progress` (el más cercano a llegar al final del camino). Es deliberadamente mínima porque "Alcance" está fuera de esta iteración: no hay posiciones ni rango, solo el progreso que ya existe en `Enemy`.
- `CombatSimulation` no expone `defender_added`: por ahora solo emite eventos de dominio relevantes (`enemy_reached_end`, `enemy_defeated`, `defender_attacked`, `enemy_spawned`).
- Todo `delta` se recibe como parámetro explícito (nunca leído de `Engine.get_process_delta_time()` ni de un `Timer`), para que la simulación sea determinista y completamente controlable desde tests headless.

#### Notas de diseño — `Wave`

- Mismo patrón Definition → Runtime Instance que `WeaponData`/`WeaponInstance`: `EnemyData` es la definición pura de un tipo de enemigo (vida máxima, velocidad), compartible entre múltiples entradas de spawn sin duplicar estadísticas; `Enemy` sigue siendo la instancia en ejecución, sin cambios en su constructor. `WaveData` es la definición pura del calendario de una oleada (lista ordenada de `SpawnEntry`, cada una con un tiempo y un `EnemyData`); `Wave` es la instancia en ejecución sobre ese `WaveData`, con su propio `elapsed_time` y cursor interno.
- `Wave.advance(delta)` sigue el mismo patrón que `MovementPhase.advance()`/`AttackPhase.advance()`: es un método que responde con un resultado (`Wave.AdvanceResult`, con `spawned_entries` y `finished`) en vez de mutar nada fuera de sí misma. `Wave` nunca crea `Enemy`, nunca conoce `CombatSimulation` ni recibe una referencia a ella, nunca mueve enemigos, nunca aplica daño y no emite señales — es `CombatSimulation` quien la posee, la empuja en cada `advance(delta)` propio, y quien decide qué hacer con el resultado (instanciar `Enemy` a partir de cada `EnemyData` liberado y añadirlo al roster vía `add_enemy`).
- `finished` evita que `CombatSimulation` tenga que preguntar continuamente `wave.is_finished()`: el propio resultado de `advance()` ya indica si la oleada agotó su calendario. Deja preparado el camino para una futura señal `wave_completed` sin necesitar polling, aunque esta iteración no la introduce todavía (no hay nada que la dispare fuera de tests) para no dejar código muerto.
- `WaveData` ordena sus `SpawnEntry` por tiempo ascendente al construirse, para que `Wave` pueda consumirlas con un único cursor monótono (`_next_index`) en vez de reescanear todo el calendario en cada `advance()`.
- `CombatSimulation.advance(delta)` sigue funcionando exactamente igual que antes cuando no se le proporciona ninguna `Wave` (parámetro opcional, `null` por defecto): `_resolve_spawns()` es un no-op en ese caso, así que todos los tests existentes que pueblan el roster manualmente vía `add_enemy` no necesitaron cambios.

### Próximo objetivo

Integrar `CombatSimulation` con `InventoryGrid` para que las piezas colocadas se conviertan en `Defender`.

Implementar una fuente real de piezas sobre `InventoryPieceSource` (tienda, cofres, recompensas, draft o crafting).
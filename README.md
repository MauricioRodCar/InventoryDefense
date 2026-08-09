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
- `InventoryGrid` puede agrandarse en runtime vía `expand(additional_width, additional_height)`, que emite `grid_expanded(new_width, new_height)` tras aplicar el cambio — mismo patrón que `piece_placed`/`piece_removed`. Solo crece, nunca encoge: encoger un grid con piezas ya colocadas plantearía qué hacer con las piezas que quedarían fuera de los nuevos límites, un problema que ningún consumidor actual necesita resolver (por ahora solo se usa para otorgar espacio, nunca quitarlo). El grid sigue siendo estrictamente rectangular; no se introdujeron celdas irregulares ni bloqueadas porque no hay ninguna necesidad concreta todavía. Por esto, `width`/`height` dejaron de ser propiedades públicas mutables y pasaron a ser privadas (`_width`/`_height`) con `get_width()`/`get_height()`: si cualquiera pudiera seguir escribiéndolas desde afuera, el modelo de "único camino de mutación + señal" que introduce `expand()` quedaría roto. `InventoryGridView` se suscribe a `grid_expanded` para mantener el fondo y el tamaño del control sincronizados con el nuevo tamaño del grid.

#### Notas de diseño — identidad de `InventoryPiece`

`InventoryPiece` separa dos roles que antes vivían mezclados en un único campo `id`: `type_id` identifica el tipo de pieza (`&"square"`, `&"bar"`, `&"corner"`, ...), compartible entre múltiples instancias del mismo tipo — mismo rol que `WeaponData.id`/`EnemyData.id` en Combat; `id` identifica la instancia concreta y se genera automáticamente mediante un contador estático al construirse, nadie lo pasa desde afuera. Esto es lo que permite que `InventoryGrid` siga usando `id` como clave única en su diccionario interno `_pieces` incluso cuando una fuente real (tienda, cofres, draft) ofrezca dos piezas del mismo tipo: antes, la segunda pisaba a la primera en `_pieces`, perdiendo una pieza colocada de `get_pieces()` de forma silenciosa. El constructor mantiene la misma firma posicional (`_init(type_id, shape)`) porque ese primer parámetro ya era conceptualmente un tipo en todos los call sites existentes.

### Combate

Estado:
✅ Entidades base del dominio implementadas
✅ `CombatSimulation` implementada: simulación determinista ejecutable headless vía `advance(delta)`
✅ `Wave` implementada: puebla el roster de enemigos automáticamente según un calendario, además del `add_enemy` manual (pruebas)

Incluye:

- `CombatPath` (dominio; longitud lógica del camino, sin posiciones de mundo)
- `WeaponData` (dominio; definición pura de daño, cadencia de ataque y qué `WeaponBehavior` usa, compartible entre instancias)
- `WeaponInstance` (dominio; instancia de un `WeaponData` en uso, lleva su propio cooldown)
- `WeaponBehavior` (contrato base sin estado ni propiedad del dominio; declara `resolve(damage, primary_target, enemies)`, no se instancia directamente)
- `SingleShotWeaponBehavior` (`WeaponBehavior`; produce un único impacto sobre el objetivo prioritario, por el daño base del arma)
- `DoubleShotWeaponBehavior` (`WeaponBehavior`; produce dos impactos sobre el objetivo prioritario, cada uno por el daño base del arma)
- `Enemy` (dominio; vida y progreso en el camino)
- `EnemyData` (dominio; definición pura de vida máxima y velocidad de un tipo de enemigo, compartible entre entradas de una `Wave`)
- `Defender` (dominio; compone su capacidad ofensiva vía `WeaponInstance` y su regla de selección de objetivo vía `TargetingPolicy`, en vez de tener daño/cadencia/targeting embebidos)
- `WaveData` (dominio; calendario ordenado de spawn — tiempo + `EnemyData` — sin estado de ejecución)
- `Wave` (dominio; instancia en ejecución de un `WaveData`, con su propio reloj y cursor; `advance(delta)` devuelve qué `EnemyData` deberían aparecer, sin crear `Enemy`)
- `MovementPhase` (algoritmo sin estado ni propiedad del dominio; calcula cuánto debería avanzar cada enemigo vivo)
- `TargetingPolicy` (contrato base sin estado ni propiedad del dominio; declara `select_target(enemies)`, no se instancia directamente)
- `HighestProgressTargetingPolicy` (`TargetingPolicy`; selecciona al enemigo vivo con mayor `path_progress` — el más cercano a llegar al final del camino)
- `LowestHealthTargetingPolicy` (`TargetingPolicy`; selecciona al enemigo vivo con menor `current_health`)
- `LowestProgressTargetingPolicy` (`TargetingPolicy`; selecciona al enemigo vivo con menor `path_progress` — el más cercano al inicio del camino)
- `AttackPhase` (algoritmo sin estado ni propiedad del dominio; decide qué defensor ataca y con cuánto daño, delegando en `defender.targeting_policy` a quién)
- `CombatSimulation` (dominio; única autoridad del combate: dueña del roster de enemigos/defensores, del `CombatPath` y opcionalmente de una `Wave`; aplica los resultados de las fases y emite las señales)
- Tests headless

#### Notas de diseño — entidades de combate

- Misma filosofía que el inventario: dominio sin dependencias de Godot, ejecutable headless, separación estricta entre dominio (`Enemy`, `Defender`, ...), orquestación (`CombatSimulation`, `MovementPhase`, `AttackPhase`) y representación visual (todavía no implementada).
- `WeaponData` juega el mismo rol que `ShapeData`: definición pura, sin estado, compartible entre múltiples instancias. `WeaponInstance` juega el rol de `InventoryPiece`: instancia con estado de ejecución propio (`cooldown_remaining`), mutado solo mediante métodos privados (`_tick`, `_reset_cooldown`) reservados a `CombatSimulation`. Esta cadena Definition → Runtime Instance → Owner evita que dos `Defender` que comparten el mismo `WeaponData` interfieran entre sí si comparten cooldown por error.
- `Defender` no tiene ni `damage` ni `attack_interval` propios: siempre los obtiene a través de su `weapon_instance`, para que el comportamiento ofensivo no quede embebido directamente en la unidad.
- `Enemy` y `Defender` no se conocen entre sí ni conocen `CombatPath`: cada uno solo protege sus propios invariantes (vida acotada a `[0, max_health]`, progreso nunca negativo). Acotar `path_progress` contra la longitud de un `CombatPath` concreto es responsabilidad de `CombatSimulation`, no de `Enemy`.
- Ninguna de estas entidades emite señales: `CombatSimulation` es la única autoridad de combate y la única emisora, igual que `InventoryGrid`/`InventoryPieceSource` lo son para el inventario.
- `TargetingPolicy` se extrajo originalmente de `AttackPhase` como una única implementación concreta compartida por todos los defensores. Ahora que existe una necesidad real de que distintos defensores seleccionen objetivo de forma distinta (arquetipos de unidad), se convirtió en un contrato base (patrón Strategy vía herencia, el idioma natural en GDScript al no existir interfaces): declara únicamente `select_target(enemies) -> Enemy` y no se instancia directamente. La regla original (mayor `path_progress`) se movió sin cambios de comportamiento a `HighestProgressTargetingPolicy`; se sumaron `LowestHealthTargetingPolicy` y `LowestProgressTargetingPolicy` como reglas hermanas. El contrato no creció para soportarlas: las tres usan datos que `Enemy` ya exponía (`path_progress`, `current_health`, `is_alive()`), así que agregar una regla nueva es agregar una subclase, nunca modificar `TargetingPolicy` ni las subclases existentes.
- `Defender` compone ahora su propia `targeting_policy` (junto a `weapon_instance`), en vez de que `AttackPhase` posea una política única. Como `TargetingPolicy` no lleva ningún estado mutable por defensor (a diferencia de `WeaponInstance`, que sí lleva `cooldown_remaining`), no hace falta un patrón Definition → Runtime Instance para ella: es seguro que varios `Defender` compartan literalmente la misma instancia de una subclase de `TargetingPolicy`. Si no se indica `targeting_policy` al construir un `Defender`, usa `HighestProgressTargetingPolicy` por defecto — la misma regla que antes vivía hardcodeada en `AttackPhase` — para que cualquier `Defender` construido solo con `id` y `weapon_instance` (como el que produce hoy `DefenderTranslator`, en Bridge, sin cambios en esta iteración) conserve exactamente el comportamiento previo.
- `AttackPhase` ya no posee ninguna `TargetingPolicy` propia: para cada defensor listo, delega directamente en `defender.targeting_policy.select_target(enemies)`. Esto es lo que permite que un arquetipo de unidad nuevo (una combinación distinta de `WeaponData` + `TargetingPolicy`) nunca requiera modificar `AttackPhase` ni `CombatSimulation`.
- `WeaponBehavior` separa completamente **a quién atacar** (`TargetingPolicy`) de **cómo ocurre el ataque** (`WeaponBehavior`): son dos ejes de variación independientes que nunca se modifican entre sí. `TargetingPolicy.select_target(enemies)` sigue devolviendo un único objetivo prioritario, sin saber nada de cuántos impactos produce el arma. `WeaponBehavior.resolve(damage, primary_target, enemies)` recibe ese objetivo prioritario ya resuelto (nunca decide a quién priorizar) y devuelve la lista de impactos (`WeaponBehavior.Hit`: objetivo + daño) que produce el ataque — hoy siempre uno solo, pero el contrato ya admite devolver varios para patrones futuros (doble disparo, escopeta, área, cadena, perforación...) sin tocar `TargetingPolicy` ni `AttackPhase` de nuevo.
- Igual que `TargetingPolicy`, `WeaponBehavior` se compone como un contrato base (patrón Strategy vía herencia) del que no se instancia directamente. A diferencia de `TargetingPolicy` (que compone `Defender`, porque es un rasgo del arquetipo de unidad), `WeaponBehavior` se compone en `WeaponData` (nuevo campo `weapon_behavior`), porque el patrón de disparo es un rasgo del arma, no del defensor que la porta: dos `Defender` distintos con el mismo `WeaponData` deben atacar exactamente igual. Debe ser stateless por la misma razón que `WeaponData` es compartible entre instancias — ninguna subclase puede llevar estado propio de ejecución.
- `SingleShotWeaponBehavior` produce un único impacto sobre el objetivo prioritario, por el daño base del arma — exactamente el comportamiento que `AttackPhase` tenía hardcodeado antes de que `WeaponBehavior` existiera, sin ningún cambio observable. Es el valor por defecto de `WeaponData.weapon_behavior` si no se indica explícitamente, para que cualquier `WeaponData` construida solo con `id`/`damage`/`attack_interval` conserve exactamente el comportamiento previo. `DoubleShotWeaponBehavior` (dos impactos sobre el objetivo prioritario) se agregó como primera subclase hermana, confirmando en la práctica que agregar un patrón de ataque nuevo es agregar una subclase de `WeaponBehavior`, nunca modificar `WeaponData`, `AttackPhase` ni `CombatSimulation`.
- `AttackPhase` ahora coordina dos estrategias en vez de una: por cada defensor listo, resuelve el objetivo prioritario vía `defender.targeting_policy.select_target(enemies)` y delega en `defender.weapon_instance.weapon_data.weapon_behavior.resolve(damage, primary_target, enemies)` qué impactos produce el ataque. Convierte cada `WeaponBehavior.Hit` en un `AttackPhase.Result` independiente, así que un mismo defensor puede producir varios `Result` en el mismo `advance()` sin que `CombatSimulation` necesite saberlo: su forma (`defender`, `target`, `damage`) no cambió, solo la cantidad que puede haber por defensor.

#### Notas de diseño — `CombatSimulation`

- `CombatSimulation` es dueña del roster (`Array[Enemy]`, `Array[Defender]`), del `CombatPath` de la ronda y opcionalmente de una `Wave`. Esta iteración no crea defensores por sí misma (eso es responsabilidad de una futura integración con `InventoryGrid`): se añaden desde fuera vía `add_defender`. Los enemigos pueden añadirse manualmente vía `add_enemy` (uso de pruebas) o poblarse automáticamente a partir de la `Wave`, si se proporcionó una al construir la simulación. `get_enemies()`/`get_defenders()` devuelven copias del array (mismo patrón que `InventoryGrid.get_pieces()`), para que nadie fuera de `CombatSimulation` pueda mutar el roster.
- `MovementPhase` y `AttackPhase` son algoritmos sin estado y sin propiedad del dominio: reciben las colecciones necesarias como parámetros y devuelven resultados (`MovementPhase.Result`, `AttackPhase.Result`) describiendo qué debería pasar, sin mutar `Enemy`/`Defender`/`WeaponInstance` ni el roster. `CombatSimulation` decide si aplica cada resultado, es quien realmente invoca los métodos internos (`_advance`, `_take_damage`, `_tick`, `_reset_cooldown`) y quien emite las señales — así se mantiene como la única autoridad del dominio de combate, con un único punto de mutación en todo el sistema.
- `advance(delta)` se divide en pasos ordenados y deterministas: mover enemigos vivos (`MovementPhase`) → resolver los que llegaron al final del `CombatPath` (remover del roster, emitir `enemy_reached_end`) → spawnear los enemigos que correspondan según la `Wave` (crear `Enemy` a partir de los `EnemyData` liberados, añadirlos al roster, emitir `enemy_spawned`) → tickear cooldowns y resolver ataques (`AttackPhase`, aplicar daño, reiniciar cooldown, emitir `defender_attacked`) → resolver enemigos derrotados (remover del roster, emitir `enemy_defeated`). El tick de cooldown ocurre en `CombatSimulation` antes de llamar a `AttackPhase`, porque es tiempo pasando (no una decisión de combate); `AttackPhase` solo lee `is_ready()`. Spawnear después de mover implica que un enemigo recién aparecido no avanza en el mismo `advance()` en el que fue creado — no existía todavía cuando `MovementPhase` calculó los avances de ese tick.
- Regla de selección de objetivo de `AttackPhase`: cada defensor listo ataca al objetivo que resuelva su propia `TargetingPolicy` compuesta (ver notas de diseño de entidades de combate más arriba). Ninguna regla concreta de `TargetingPolicy` usa alcance ni posiciones todavía — "Alcance" sigue fuera de esta iteración, solo se usan `path_progress` y `current_health`, que ya existían en `Enemy`.
- `CombatSimulation` no expone `defender_added`: por ahora solo emite eventos de dominio relevantes (`enemy_reached_end`, `enemy_defeated`, `defender_attacked`, `enemy_spawned`).
- Todo `delta` se recibe como parámetro explícito (nunca leído de `Engine.get_process_delta_time()` ni de un `Timer`), para que la simulación sea determinista y completamente controlable desde tests headless.
- `is_battle_over()` es la única autoridad sobre si la batalla terminó (`Wave` agotada y roster de enemigos vacío; sin `Wave` configurada siempre es `false`, no hay noción de "fin" sin oleada). Se añadió como prerequisito aislado para `BattleRunner` (ver Battle): sin esto, nada fuera de `CombatSimulation` podía saber cuándo dejar de llamar `advance(delta)`.

#### Notas de diseño — `Wave`

- Mismo patrón Definition → Runtime Instance que `WeaponData`/`WeaponInstance`: `EnemyData` es la definición pura de un tipo de enemigo (vida máxima, velocidad), compartible entre múltiples entradas de spawn sin duplicar estadísticas; `Enemy` sigue siendo la instancia en ejecución, sin cambios en su constructor. `WaveData` es la definición pura del calendario de una oleada (lista ordenada de `SpawnEntry`, cada una con un tiempo y un `EnemyData`); `Wave` es la instancia en ejecución sobre ese `WaveData`, con su propio `elapsed_time` y cursor interno.
- `Wave.advance(delta)` sigue el mismo patrón que `MovementPhase.advance()`/`AttackPhase.advance()`: es un método que responde con un resultado (`Wave.AdvanceResult`, con `spawned_entries` y `finished`) en vez de mutar nada fuera de sí misma. `Wave` nunca crea `Enemy`, nunca conoce `CombatSimulation` ni recibe una referencia a ella, nunca mueve enemigos, nunca aplica daño y no emite señales — es `CombatSimulation` quien la posee, la empuja en cada `advance(delta)` propio, y quien decide qué hacer con el resultado (instanciar `Enemy` a partir de cada `EnemyData` liberado y añadirlo al roster vía `add_enemy`).
- `finished` evita que `CombatSimulation` tenga que preguntar continuamente `wave.is_finished()`: el propio resultado de `advance()` ya indica si la oleada agotó su calendario. `CombatSimulation` lo usa para emitir `wave_completed` una única vez, en la transición false→true (ver Battle: fue el prerequisito que desbloqueó a `BattleRunner` para saber cuándo terminó una batalla).
- `WaveData` ordena sus `SpawnEntry` por tiempo ascendente al construirse, para que `Wave` pueda consumirlas con un único cursor monótono (`_next_index`) en vez de reescanear todo el calendario en cada `advance()`.
- `CombatSimulation.advance(delta)` sigue funcionando exactamente igual que antes cuando no se le proporciona ninguna `Wave` (parámetro opcional, `null` por defecto): `_resolve_spawns()` es un no-op en ese caso, así que todos los tests existentes que pueblan el roster manualmente vía `add_enemy` no necesitaron cambios.

### Bridge (Inventory ↔ Combat)

Estado:
✅ `CombatSimulationBuilder` implementado: construye una `CombatSimulation` lista a partir del estado actual de un `InventoryGrid`

Incluye:

- `DefenderData` (dominio; definición pura de qué `WeaponData` usa un tipo de defensor y, opcionalmente, qué `TargetingPolicy` debería componer, sin estado de ejecución — mismo rol que `WeaponData`/`EnemyData`)
- `DefenderCatalog` (dominio; mapeo puro entre una clave de tipo de `InventoryPiece` y el `DefenderData` que debería producir, sin conocer `InventoryPiece` ni `Defender` — mismo rol que `WaveData` respecto a `Wave`/`Enemy`)
- `DefenderTranslator` (algoritmo sin estado ni propiedad del dominio; traduce una `InventoryPiece` en un `Defender` nuevo consultando un `DefenderCatalog` — mismo estilo que `MovementPhase`/`AttackPhase`)
- `CombatSimulationBuilder` (composition root del bridge; la única clase que conoce `InventoryGrid` y `CombatSimulation` a la vez — ninguna de las dos se entera de la existencia de la otra)
- Tests headless

#### Notas de diseño — Bridge

- `Inventory` y `Combat` siguen siendo dominios completamente independientes: ninguna clase de `Inventory` referencia nada de `Combat` ni viceversa. Todo el conocimiento cruzado vive exclusivamente en `Scripts/Gameplay/Bridge/`, una carpeta separada de ambas — lo que hace visible en la propia estructura del proyecto que este código depende de los dos dominios pero ninguno depende de él.
- `DefenderTranslator.translate()` es responsable de crear tanto la `WeaponInstance` como el `Defender` en la misma llamada, porque ambas creaciones son atómicas: no tiene sentido crear una `WeaponInstance` sin entregarla de inmediato a un `Defender` (ver la nota sobre `WeaponData`/`WeaponInstance` en Combate). Cada pieza traducida obtiene su propia `WeaponInstance`, aunque dos piezas compartan el mismo `DefenderData`/`WeaponData`, para no filtrar cooldown entre defensores.
- `DefenderTranslator` usa `piece.type_id` como clave de tipo hacia `DefenderCatalog` (ver notas de diseño de `InventoryPiece` en Inventario).
- Una pieza del grid sin entrada en el `DefenderCatalog` no produce ningún `Defender` ni interrumpe la construcción del resto: `CombatSimulationBuilder.build()` simplemente la ignora.
- `DefenderData.targeting_policy` es opcional (`null` por defecto, mismo patrón que `weapon_behavior` en `WeaponData`) y `DefenderTranslator` lo reenvía sin cambios al `Defender` que crea. Con `null`, `Defender` sigue aplicando su propio default (`HighestProgressTargetingPolicy`), así que ningún `DefenderData` existente cambió de comportamiento al agregarse este campo. Esto es lo que permite que un arquetipo de defensor completo (`WeaponData` + `WeaponBehavior` + `TargetingPolicy`) se pueda componer íntegramente desde el catálogo de Bridge y llegue intacto a combate, sin que `DefenderTranslator`, `AttackPhase` ni `CombatSimulation` necesiten conocer qué arquetipo es.
- Los arquetipos de defensor (p. ej. Vanguardia, Rematador, Artillero en el sandbox de `main.gd`) no son clases: son combinaciones distintas de los mismos tres bloques ya existentes (`WeaponData`, `WeaponBehavior`, `TargetingPolicy`) empaquetadas en un `DefenderData`. Diferenciar un arquetipo nuevo nunca requiere una subclase de `Defender`, `WeaponData` ni `DefenderData` — solo una entrada nueva en el `DefenderCatalog` con otra combinación.
- `CombatSimulationBuilder.build()` no retiene ninguna referencia entre llamadas (el `InventoryGrid`, el `CombatPath`, la `WaveData` y el `DefenderCatalog` se reciben como parámetros explícitos cada vez): puede reutilizarse para iniciar tantos combates como haga falta sin arrastrar estado entre ellos. Esto deja preparado el terreno para que distintos modos de juego (campaña, endless, jefes, etc.) reutilicen la misma pieza sin que ella necesite saber nada sobre el modo que la invoca.
- `CombatSimulationBuilder` no modifica la API pública de `CombatSimulation`: sigue construyéndola con `_init(path, wave)` y añadiendo defensores vía `add_defender()`, el mismo punto de extensión que `CombatSimulation` ya dejaba preparado desde antes de que existiera el bridge.

### Battle (ejecución de una batalla completa)

Estado:
✅ `BattleRunner` implementado: ejecuta el ciclo de vida completo de una batalla (`IDLE` → `RUNNING` → `FINISHED`) sobre una `CombatSimulation` construida vía `CombatSimulationBuilder`
✅ `BattleView` implementada: representación visual mínima (primitivas) reactiva a `CombatSimulation`, sincronizada explícitamente por `BattleRunner` tras cada `advance(delta)`
✅ Vertical slice funcional de punta a punta: colocar piezas en el grid → disparador temporal de "Start Battle" → la oleada se mueve, es atacada por los defensores traducidos desde el grid, y la batalla se da por terminada sola

Incluye:

- `BattleRunner` (`Scripts/Gameplay/Battle/`; orquestación, `Node` — necesita `_process(delta)` para avanzar la simulación cada frame y sitio en el árbol de escena para que `main.gd` lo cablee, igual que `InventoryInteractionController` en Inventory). Única responsabilidad: el ciclo de vida temporal de una batalla. Construye la `CombatSimulation` una vez vía `CombatSimulationBuilder.build()`, la entrega a `battle_view`, y cada frame llama `simulation.advance(delta)` → `battle_view.sync()` → comprueba `simulation.is_battle_over()`.
- `BattleView`, `EnemyView`, `DefenderView`, `CombatPathView` (`Scripts/UI/Battle/`; representación visual, sin dependencias del dominio hacia ellas)
- Tests headless para el prerequisito añadido a `CombatSimulation` (`wave_completed`, `is_battle_over()`); `BattleRunner`/`BattleView` y las vistas no tienen tests headless, mismo criterio que el resto de la capa de `UI/` y de `InventoryInteractionController`

#### Notas de diseño — `BattleRunner`

- `state: State` (`IDLE`/`RUNNING`/`FINISHED`) es explícito y se expone junto a la señal `state_changed`, en vez de inferirse de si `_simulation` es `null` o si `_process` está activo. Deja preparado el terreno para pausa, aceleración de tiempo o una futura fase de preparación sin tener que rediseñar cómo se consulta el estado del runner.
- `BattleRunner` posee la `CombatSimulation` directamente; no existe ningún objeto intermedio entre ambos (no había ningún problema que lo justificara).
- `BattleRunner` conoce `InventoryGrid` únicamente como parámetro de paso hacia `CombatSimulationBuilder.build()` (acoplamiento estructural, no de comportamiento): no llama ningún método de `InventoryGrid`, así que no rompe la invariante de Bridge de que "solo `CombatSimulationBuilder` conoce Inventory y Combat a la vez" en ningún sentido operativo.
- `BattleRunner` sostiene una referencia a `battle_view` (asignada desde fuera por `main.gd`, mismo patrón que `grid_view`/`source_view` en `InventoryInteractionController`) y, tras cada `advance(delta)`, llama explícitamente `battle_view.sync()`. No relee ni reinterpreta las señales de `CombatSimulation`: esas siguen fluyendo directo de la simulación a `battle_view` (conectadas en `BattleView.set_combat_simulation()`), `BattleRunner` nunca se convierte en relay de señales.

#### Notas de diseño — `BattleView` y las vistas de batalla

- Mismo patrón reactivo que `InventoryGridView`: `BattleView.set_combat_simulation()` se conecta a `enemy_spawned`/`enemy_defeated`/`enemy_reached_end` para crear/destruir `EnemyView` (Dictionary `Enemy -> EnemyView`, igual que `_piece_views` en `InventoryGridView`). `CombatSimulation` nunca conoce `BattleView` ni ninguna clase de vista.
- El movimiento (`path_progress`) y la vida no tienen señal propia — moverse no es un evento de dominio — así que no hay forma reactiva pura de mantenerlos sincronizados. En vez de que `EnemyView` haga polling del dominio en su propio `_process()`, `BattleView.sync()` (llamado explícitamente por `BattleRunner`, nunca por las vistas) empuja la posición y vida ya resueltas a cada `EnemyView` vía `update_state()`. `EnemyView`/`DefenderView` son `Node2D` puros sin `_process` propio y sin referencia al dominio: solo primitivas (`draw_circle`/`draw_rect`) que pintan lo último que se les entregó.
- `CombatPathView` es la única clase que traduce el `path_progress` lógico de un `Enemy` a una posición de mundo (línea recta entre dos puntos configurables). `CombatPath` (dominio) sigue siendo solo una longitud lógica, sin geometría — la traducción a posiciones de escena, tal como ya anticipaban las notas de Combate, vive enteramente en `CombatPathView`.
- `Defender` no lleva posición propia y `DefenderTranslator` no preserva el `anchor` original de la `InventoryPiece` traducida (ver notas de Bridge). Resolverlo tocaría Bridge, un segundo sistema. Para esta iteración, `BattleView` distribuye los `DefenderView` en una fila por índice de `get_defenders()`, sin relación con la celda original en el inventario — deuda conocida, mismo espíritu que la de `InventoryPiece.id`, pendiente de una branch de Bridge si llega a importar que el defensor se vea "en su celda".
- Como `CombatSimulation` no expone `defender_added`, `BattleView` no puede reaccionar a defensores por señal: los toma una única vez, por snapshot (`get_defenders()`), en `set_combat_simulation()`. No hace falta más porque esta iteración no añade ni remueve defensores durante la batalla.

#### Notas de diseño — integración con `main.gd`

- `main.gd` retiene ahora `InventoryGrid` como campo (antes era variable local de `_ready()`) para poder entregársela a `BattleRunner.start()` cuando arranca la batalla.
- `main.gd` construye un `DefenderCatalog` y una `WaveData` de sandbox (un `DefenderData` por cada tipo de pieza que ofrece `InventoryPieceSourceSandbox`, y un calendario fijo de enemigos de prueba), mismo espíritu que `InventoryPieceSourceSandbox`: mínimo necesario para esta vertical slice, a reemplazar cuando exista una fuente real de configuración de ronda.
- Disparador temporal de "Start Battle" (sin UI definitiva todavía): pulsar aceptar (Enter/Espacio, acción `ui_accept`) llama `BattleRunner.start()` una vez, mientras el runner siga en `IDLE`. `main.gd` sigue siendo el único composition root: no conoce nada interno de `BattleRunner`/`CombatSimulation`, solo cablea referencias y decide cuándo arranca la batalla.

### Economía

Estado:
✅ `PlayerEconomy` implementada: única autoridad sobre el oro del jugador
✅ `EnemyRewardCatalog` implementado: mapeo de `EnemyData.id` a recompensa en oro
✅ `BattleRunner` acredita oro al derrotar enemigos, sin asumir responsabilidades adicionales de progresión

Incluye:

- `PlayerEconomy` (dominio; sin dependencias de Godot; única autoridad sobre el oro del jugador — invariante: el oro nunca es negativo)
- `EnemyRewardCatalog` (dominio; mapeo puro entre `EnemyData.id` y el oro que otorga derrotar ese tipo de enemigo, sin conocer `Enemy`, `CombatSimulation` ni `PlayerEconomy` — mismo rol que `DefenderCatalog` respecto a `InventoryPiece`/`DefenderData`)
- Tests headless

#### Notas de diseño — Economía

- `PlayerEconomy` no expone ninguna forma de gastar oro todavía: no hay tienda, recompensas de fin de oleada, `BattleReward`, `BattleRewardTracker`, `RunController` ni máquinas de estados en esta iteración — solo la autoridad mínima necesaria para que exista una fuente de oro. `add_gold(amount)` asume `amount > 0` (falla con `assert`); es responsabilidad de quien llama no invocarlo con una recompensa nula o negativa.
- `EnemyRewardCatalog.get_gold_reward(enemy_id)` devuelve `0` para una clave sin entrada, en vez de fallar, igual que `DefenderCatalog.get_defender_data()` devuelve `null` para una pieza sin mapeo: un enemigo sin recompensa configurada no debe romper el resto del sistema.
- `CombatSimulation` sigue siendo completamente ajena a la economía: no conoce `PlayerEconomy` ni `EnemyRewardCatalog`, y no se modificó para esta iteración. Todo el cableado vive en `BattleRunner`.
- `BattleRunner` gana dos campos opcionales, `player_economy` y `enemy_reward_catalog`, asignados desde fuera antes de `start()` (mismo patrón que `battle_view`). Si ambos están presentes, `start()` conecta `enemy_defeated` a un método privado que consulta la recompensa y, solo si es mayor que 0, llama `player_economy.add_gold()` — evitando violar el invariante de `add_gold` para enemigos sin recompensa configurada. Sin ambos campos asignados, `BattleRunner` se comporta exactamente igual que antes de esta iteración.
- `main.gd` construye un `PlayerEconomy` y un `EnemyRewardCatalog` de sandbox (una recompensa para el único tipo de enemigo de su `WaveData` de prueba), mismo espíritu que su `DefenderCatalog`/`WaveData` de sandbox: mínimo necesario para esta vertical slice, a reemplazar cuando exista una fuente real de configuración de ronda.

### Próximo objetivo

Implementar una fuente real de piezas sobre `InventoryPieceSource` (tienda, cofres, recompensas, draft o crafting) — probablemente la primera consumidora real de `PlayerEconomy` (gastar oro), todavía sin implementar.

Introducir `BattleReward`/`BattleRewardTracker`, recompensas de fin de oleada, un `RunController` o máquinas de estados de progresión, cuando exista una necesidad concreta que los justifique — fuera de alcance deliberado hasta ahora.

Reemplazar el disparador temporal de "Start Battle" (Enter/Espacio) por una UI real, y el `DefenderCatalog`/`WaveData` de sandbox de `main.gd` por una configuración real de ronda.

Resolver, en una branch de Bridge, que un `DefenderView` se posicione según el `anchor` original de su `InventoryPiece` en vez de en una fila por índice.

Sprites, animaciones, proyectiles, efectos, barra de vida, múltiples caminos, varias oleadas, pausa, aceleración de tiempo, replay y distintos modos de juego siguen fuera de alcance; el diseño de Battle (estado explícito en `BattleRunner`, `delta` explícito en `advance()`, vistas puramente reactivas) quedó pensado para no requerir tocar `CombatSimulation` al añadirlos, salvo múltiples caminos/oleadas, que sí son extensiones de dominio legítimas.
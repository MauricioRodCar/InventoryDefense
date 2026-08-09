# Spec: golpes críticos

**Estado: completo.** Mergeado a `main`. Todo defensor puede tener crítico
hoy (`crit_chance`/`crit_multiplier` viven en `WeaponData`, y los tres
arquetipos de sandbox lo tienen configurado por igual).

**Nota para una iteración futura** (no implementar todavía, decisión
pendiente del usuario): actualmente cualquier arma puede tener crítico si su
`WeaponData` lo configura — no hay ninguna restricción de diseño que lo
limite a un arquetipo en particular. El usuario planteó que preferiría que
el crítico fuera un rasgo distintivo de *ciertas* unidades (p. ej. un
arquetipo "Francotirador" con alto `crit_chance` y el resto en 0), no una
propiedad genérica que todos los arquetipos de sandbox comparten por igual
como hoy. Esto no requeriría ningún cambio de arquitectura — ya es posible
hoy mismo ajustando los valores por arquetipo en `main.gd` — es una decisión
de contenido/balance, no de diseño. Retomar cuando el usuario defina qué
arquetipos deberían tener crítico y cuáles no.

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
pueda implementarlo sin tener que re-derivar el diseño. Antes de programar:
leer `CLAUDE.md` y las secciones relevantes de `README.md` (en particular
Combate y Battle). Seguir la regla del proyecto: **explicar el plan antes de
programar** — si algo de esta spec no cierra con el código real, parar y
preguntar antes de improvisar.

Es una sola branch, no un roadmap de varias. Primera de una serie más grande
de "profundidad de combate" (daño de área, efectos de estado, resistencias,
vuelo/esquive vendrán después, en specs separadas).

## Objetivo de producto

Un arma puede tener probabilidad de crítico: al impactar, con cierta
probabilidad el daño de ese impacto se multiplica. El jugador tiene que
poder **verlo pasar** en pantalla (no solo en los números), y tiene que
poder **notarlo** en la duración de una pelea — con la vida actual de los
enemigos de sandbox, cualquier disparo básico los mata al instante, así que
un crítico no se distinguiría de un golpe normal. Esta branch resuelve las
tres cosas juntas: la mecánica, el feedback visual, y el ajuste de vida de
enemigos que hace falta para que se pueda apreciar.

## Diseño

### Dónde vive la probabilidad de crítico

`crit_chance`/`crit_multiplier` son campos de `WeaponData` (definición pura,
igual que `damage`/`attack_interval`), **no** de `WeaponBehavior`. Por qué:
`WeaponBehavior` decide cuántos impactos produce un ataque y contra quién
(`SingleShotWeaponBehavior`, `DoubleShotWeaponBehavior`); crítico es un eje
ortogonal — "cuánto daño hace *cada* impacto ya decidido", no "cuántos
impactos hay". Si viviera en `WeaponBehavior`, cada subclase (presente y
futura) tendría que reimplementar el mismo cálculo de crítico. Con
`crit_chance`/`crit_multiplier` en `WeaponData` y el cálculo centralizado en
`AttackPhase` (ver abajo), ningún `WeaponBehavior` necesita saber que los
críticos existen — un `DoubleShotWeaponBehavior` produce sus dos impactos
exactamente igual que hoy, y cada uno se evalúa para crítico de forma
independiente después, sin que la clase lo sepa.

### Dónde se resuelve el sorteo

En `AttackPhase.advance()`, después de que `weapon_behavior.resolve()`
devuelve sus `Hit` — no antes. Recibe un `RandomNumberGenerator` como
parámetro explícito (nunca `randi()`/`randf()` global), mismo criterio ya
establecido por `DraftPool.draw_options(count, rng)`: determinista y
testeable headless. Por cada `Hit`, se sortea independientemente si es
crítico; con `DoubleShotWeaponBehavior` esto significa que cada uno de los
dos impactos puede ser o no crítico por separado — sin ningún caso especial,
mismo motivo por el que la branch de visualización de ataques ya demostró
que cada impacto dispara su propio proyectil.

`AttackPhase.advance(defenders, enemies, rng: RandomNumberGenerator = null)`
gana un tercer parámetro **opcional**: si se omite, `AttackPhase` crea un
`RandomNumberGenerator` efímero internamente para esa llamada. Esto es
deliberado para no romper ningún call site existente (ver "Call sites
verificados" — hay 9 en `test_attack_phase.gd` y 1 en
`CombatSimulation._resolve_attacks()` que llaman `advance(defenders,
enemies)` con dos argumentos únicamente).

`CombatSimulation` gana un tercer parámetro opcional en su constructor,
`p_rng: RandomNumberGenerator = null` (si se omite, crea el suyo), lo
guarda en `_rng`, y se lo pasa a `_attack_phase.advance(_defenders,
_enemies, _rng)`. Mismo motivo: no romper los ~15 call sites existentes de
`CombatSimulation.new(path)`/`CombatSimulation.new(path, wave)`.

### `AttackPhase.Result` gana `is_critical`

`Result` pasa a llevar `var is_critical: bool` (parámetro nuevo al final del
constructor). Confirmado por grep: el único lugar del repo que construye
`AttackPhase.Result` es el propio `attack_phase.gd` — no hace falta un
default por compatibilidad, pero agregar `= false` igual no cuesta nada y
es más seguro a futuro. `CombatSimulation._resolve_attacks()` propaga esto
al emitir la señal.

### Señal `defender_attacked` gana un parámetro

`signal defender_attacked(defender: Defender, target: Enemy, damage: int,
is_critical: bool)`. Esto es un cambio de firma que rompe compilación de
cualquier callable conectado con menos parámetros — hay que actualizar los
tres lugares que se conectan a esta señal (ver "Call sites verificados").

### Feedback visual

`BattleView._on_defender_attacked` recibe el nuevo parámetro y se lo pasa a
`ProjectileView.setup()`. `ProjectileView` gana un cuarto parámetro opcional
`is_critical: bool = false`: si es `true`, dibuja un círculo más grande y de
otro color (p. ej. `Color.ORANGE`, radio mayor) en vez del punto blanco
chico de siempre — mismo espíritu de placeholder tosco que el resto de
`ProjectileView`/`CombatPathMarkersView` (ver README, notas de Battle): no
es arte final, es para que se note mientras se prueba.

### Vida de enemigos de sandbox

Con `EnemyData.new(&"goblin", 10, 20.0)` (10 de vida) y los daños actuales
de los arquetipos de sandbox (Vanguardia 8/12/18, Rematador 4/6/9, Artillero
2/3/5 x2), casi cualquier impacto mata a un goblin de un golpe — no hay
margen para notar la diferencia entre un golpe normal y uno crítico. Subir
`max_health` del goblin de sandbox a **60** (valor de ajuste, no una curva
de balance final) alcanza para que haga falta más de un impacto de
cualquier arquetipo, y así se pueda ver tanto el patrón de ataque normal
como el crítico ocurriendo en la misma pelea.

### Valores de crítico de sandbox

Los tres arquetipos (`Vanguardia`/`Rematador`/`Artillero`) ganan
`crit_chance = 0.2` (20%) y `crit_multiplier = 2.0`, iguales en **todos**
los rangos del mismo arquetipo — mismo criterio que ya se usó para
cadencia/`WeaponBehavior`/`TargetingPolicy` en la branch de fusión: solo el
daño base escala por rango, el resto se mantiene constante.

## Cambios exactos por archivo

**`Scripts/Gameplay/Combat/weapon_data.gd`**
- Agregar `@export var crit_chance: float = 0.0` y `@export var
  crit_multiplier: float = 2.0`.
- `_init` gana `p_crit_chance: float = 0.0, p_crit_multiplier: float = 2.0`
  al final de la lista de parámetros (después de `p_weapon_behavior`), para
  no romper ningún call site posicional existente.
- Actualizar el comentario de clase mencionando ambos campos.

**`Scripts/Gameplay/Combat/attack_phase.gd`**
- `Result` gana `var is_critical: bool` y el parámetro correspondiente en
  `_init` (con default `false` si hace falta preservar compatibilidad —
  verificar si algo construye `Result` directamente).
- `advance(defenders: Array[Defender], enemies: Array[Enemy], rng:
  RandomNumberGenerator = null) -> Array[Result]`: si `rng == null`, crear
  uno efímero al principio del método. Dentro del `for hit in hits:`, sortear
  el crítico usando `weapon_data.crit_chance` (ya calculado más arriba en el
  método) y aplicar `weapon_data.crit_multiplier` al daño del `Hit` cuando
  corresponda (usar `roundi()` para volver a `int`), pasando el resultado a
  `Result.new(defender, hit.target, damage_final, is_critical)`.
- Actualizar el comentario de clase mencionando el nuevo parámetro.

**`Scripts/Gameplay/Combat/combat_simulation.gd`**
- `signal defender_attacked(defender: Defender, target: Enemy, damage: int,
  is_critical: bool)`.
- `_init(p_path: CombatPath, p_wave: Wave = null, p_rng:
  RandomNumberGenerator = null) -> void`: guardar `_rng = p_rng if p_rng !=
  null else RandomNumberGenerator.new()` en un nuevo campo `var _rng:
  RandomNumberGenerator`.
- `_resolve_attacks()`: pasar `_rng` a `_attack_phase.advance(_defenders,
  _enemies, _rng)`, y propagar `result.is_critical` al emitir
  `defender_attacked`.

**`Scripts/UI/Battle/projectile_view.gd`**
- `setup(from: Vector2, to: Vector2, is_critical: bool = false) -> void`:
  guardar `is_critical` en un campo privado, `queue_redraw()`.
- `_draw()`: si `is_critical`, dibujar con radio mayor y color distinto
  (p. ej. `Color.ORANGE`, radio 8.0) en vez del blanco/4.0 de siempre.

**`Scripts/UI/Battle/battle_view.gd`**
- `_on_defender_attacked(defender: Defender, target: Enemy, _damage: int,
  is_critical: bool) -> void`: pasar `is_critical` a
  `projectile.setup(defender_view.position, enemy_view.position,
  is_critical)`.

**`Scripts/Main/main.gd`**
- `_build_sandbox_wave_schedule()`: cambiar `EnemyData.new(&"goblin", 10,
  20.0)` a `EnemyData.new(&"goblin", 60, 20.0)`.
- `_build_sandbox_defender_catalog()`: agregar `0.2, 2.0` (crit_chance,
  crit_multiplier) a las 9 llamadas de `WeaponData.new(...)` existentes
  (los tres rangos de los tres arquetipos), sin cambiar ningún otro valor.

## Call sites verificados (confirmados por grep antes de escribir esta spec)

- `AttackPhase.advance(...)` con dos argumentos: 9 veces en
  `Tests/Gameplay/Combat/test_attack_phase.gd`, 1 vez en
  `Scripts/Gameplay/Combat/combat_simulation.gd`. Todos siguen compilando
  sin cambios porque `rng` es opcional.
- `CombatSimulation.new(...)` con uno o dos argumentos: ~15 veces entre
  `Tests/Gameplay/Combat/test_combat_simulation.gd`,
  `Tests/Gameplay/Bridge/test_combat_archetypes.gd`, y
  `Scripts/Gameplay/Bridge/combat_simulation_builder.gd`. Todos siguen
  compilando sin cambios porque `p_rng` es opcional.
- `defender_attacked.connect(...)` con una lambda/callable de 3 parámetros:
  **hay que actualizar los tres** a 4 parámetros (agregar `is_critical`,
  aunque no lo usen) para que la conexión siga siendo válida:
  - `Scripts/UI/Battle/battle_view.gd` (`_on_defender_attacked`, ver arriba).
  - `Tests/Gameplay/Bridge/test_combat_archetypes.gd`, línea con
    `simulation.defender_attacked.connect(func(_defender, _target,
    _damage): attack_count[0] += 1)` — agregar un cuarto parámetro
    `_is_critical` a la lambda.
  - `Tests/Gameplay/Combat/test_combat_simulation.gd`, línea con
    `simulation.defender_attacked.connect(func(d, target, damage):
    attack_events.append([d, target, damage]))` — agregar un cuarto
    parámetro y decidir si conviene registrarlo también en
    `attack_events` (ver Tests nuevos, puede reusarse para el test de
    crítico).

## Tests nuevos a agregar

1. **`Tests/Gameplay/Combat/test_weapon_data.gd`**: sin indicar
   `crit_chance`/`crit_multiplier`, quedan en `0.0`/`2.0`; indicados
   explícitamente, se guardan tal cual.
2. **`Tests/Gameplay/Combat/test_attack_phase.gd`**:
   - Con `crit_chance = 0.0` (default), `is_critical` es siempre `false` y
     `damage` es exactamente el daño base, sin importar el `rng` — regresión
     que prueba que esta branch no cambia el comportamiento previo cuando
     nadie configura críticos.
   - Con `crit_chance = 1.0`, `is_critical` es `true` y `damage ==
     roundi(base_damage * crit_multiplier)` — determinista, no hace falta
     sembrar el `rng` porque `randf() < 1.0` siempre es cierto.
   - Con un `DoubleShotWeaponBehavior` (o el `DoubleHitWeaponBehaviorStub`
     que ya existe en este archivo de test) y `crit_chance = 1.0`: los dos
     `Result` producidos tienen `is_critical == true` cada uno — confirma
     que el sorteo es por impacto, no por ataque.
3. **`Tests/Gameplay/Combat/test_combat_simulation.gd`**: con un `rng`
   sembrado para forzar/evitar el crítico (o directamente `crit_chance =
   1.0` en el `WeaponData` del test, más simple y determinista sin depender
   de sembrar nada), `defender_attacked` emite con `is_critical == true`.

## Documentación a actualizar

- `README.md`: nota de diseño nueva en Combate explicando por qué
  `crit_chance`/`crit_multiplier` viven en `WeaponData` y no en
  `WeaponBehavior`, por qué el sorteo ocurre en `AttackPhase` con `rng`
  explícito, y por qué es por impacto y no por ataque. Nota nueva en Battle
  explicando la distinción visual de `ProjectileView` para críticos, mismo
  estilo que las notas ya existentes de esa vista (placeholder, no arte
  final). Actualizar la nota de arquetipos de sandbox en Bridge/main.gd
  mencionando que ahora también incluyen crítico.
- `TODO.md`: marcar `[x] Projectiles` bajo `## Combate` — quedó sin marcar
  en la branch anterior (visualización de ataques) porque esa spec no tocó
  `TODO.md`; es una corrección menor, no relacionada al resto del archivo.
  No tocar ningún otro ítem de `TODO.md` (varios están desactualizados,
  pero corregirlos todos es un trabajo aparte, no de esta branch).

## Definición de hecho

- Todos los tests existentes pasan (actualizando únicamente las dos lambdas
  de test listadas en "Call sites verificados", sin romper ningún otro).
- Los tests nuevos de esta branch pasan.
- `README.md`/`TODO.md` actualizados.
- Commit único (esta branch es una sola pieza de funcionalidad: mecánica de
  crítico + su propagación mecánica a través de capas ya existentes + el
  contenido de sandbox necesario para que se pueda apreciar, no varios
  sistemas independientes).
- Verificación manual en el editor de Godot: colocar piezas, iniciar una
  wave, y confirmar que (a) los goblins ahora aguantan varios impactos en
  vez de morir de uno, y (b) de vez en cuando (aprox. 1 de cada 5 ataques)
  se ve un proyectil más grande y de otro color viajar hacia un enemigo.

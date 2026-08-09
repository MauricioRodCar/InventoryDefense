# Spec: daño de área

**Estado: completo.** Mergeado a `main`. Artillero (`corner`) ataca con
`AreaWeaponBehavior` en sus tres rangos, radio 60.0 de sandbox. Confirmado
en juego: con el espaciado actual de enemigos en las waves de sandbox, el
efecto práctico más común es golpear a dos enemigos cercanos a la vez.

## Contexto y rol

Este documento lo escribe la instancia de Claude que actúa como
**arquitecto** del proyecto, para que otra instancia sin contexto general
pueda implementarlo sin tener que re-derivar el diseño. Antes de programar:
leer `CLAUDE.md` y las secciones relevantes de `README.md` (en particular
Combate, las notas de `WeaponBehavior` y de arquetipos de sandbox). Seguir
la regla del proyecto: **explicar el plan antes de programar** — si algo de
esta spec no cierra con el código real, parar y preguntar antes de
improvisar.

Segunda de la serie de "profundidad de combate" (después de críticos, ya
mergeada). Es una sola branch, autocontenida.

## Objetivo de producto

Un arma puede golpear a varios enemigos a la vez si están lo bastante cerca
del objetivo prioritario, no solo a uno. Decisión de producto ya tomada
(confirmada con el usuario): el arquetipo Artillero (`corner`) pasa de
`DoubleShotWeaponBehavior` a esta nueva `AreaWeaponBehavior`, en los tres
rangos de su entrada en el catálogo de sandbox. Se pierde la demo de "doble
disparo" en el sandbox, pero `DoubleShotWeaponBehavior` ya quedó probada y
documentada de sobra en su propia branch — sigue existiendo en el código,
solo deja de estar mapeada a ningún arquetipo de sandbox por ahora.

## Diseño

### Por qué esto no toca ningún contrato existente

`WeaponBehavior.resolve(damage, primary_target, enemies)` **ya recibe la
lista completa de enemigos vivos** — el propio comentario de la clase base
lo anticipa explícitamente: "disponible para patrones que golpeen más de un
objetivo". `AreaWeaponBehavior` es la primera subclase que efectivamente usa
ese tercer parámetro; ninguna firma cambia.

### Radio en unidades de `path_progress`, no posición 2D

El dominio de Combate no tiene ni va a tener posiciones 2D (`CombatPathView`,
en la capa de presentación, es la única que traduce `path_progress` a
mundo). "Área" se define entonces como *cercanía a lo largo del camino*:
todo enemigo vivo cuya distancia en `path_progress` al objetivo prioritario
sea `<= radius` recibe un impacto por el daño base del arma (sin falloff por
distancia — cada enemigo alcanzado recibe el mismo daño, mismo criterio de
simplicidad que `DoubleShotWeaponBehavior` no reduce daño en su segundo
impacto). El objetivo prioritario mismo siempre queda incluido (su propia
distancia a sí mismo es 0).

### `AreaWeaponBehavior` (nuevo)

`Scripts/Gameplay/Combat/area_weapon_behavior.gd`, extiende `WeaponBehavior`
— mismo patrón exacto que `SingleShotWeaponBehavior`/
`DoubleShotWeaponBehavior` (ambas ya leídas para esta spec: son clases
mínimas, sin campos, que solo implementan `resolve()`). A diferencia de
esas dos, `AreaWeaponBehavior` sí necesita un campo de configuración
(`radius`) — no es "estado de ejecución" en el sentido que preocupa al
proyecto (nada muta después de construirse), es configuración fija, misma
categoría que `WeaponData.damage` en un objeto que igual se considera
"stateless" y compartible.

```
class_name AreaWeaponBehavior
extends WeaponBehavior

var _radius: float

func _init(p_radius: float) -> void:
	_radius = p_radius

func resolve(damage: int, primary_target: Enemy, enemies: Array[Enemy]) -> Array[Hit]:
	var hits: Array[Hit] = []
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if absf(enemy.path_progress - primary_target.path_progress) <= _radius:
			hits.append(Hit.new(enemy, damage))
	return hits
```

Filtra por `is_alive()` aunque en la práctica `CombatSimulation` ya solo
tiene enemigos vivos en su roster al momento de resolver ataques (
`_resolve_defeated()` corre al final del `advance()` anterior) — es
consistente con el resto del dominio: las `TargetingPolicy` ya filtran
enemigos muertos aunque tampoco deberían encontrar ninguno en la práctica.

### Por qué esto no requiere tocar `AttackPhase`, `CombatSimulation` ni ninguna vista de Battle

`AttackPhase.advance()` ya convierte **cada** `Hit` devuelto por
`resolve()` en su propio `Result` independiente — esto ya se demostró con
`DoubleShotWeaponBehavior` (dos `Hit` → dos `Result` → dos emisiones de
`defender_attacked` → dos `ProjectileView`). `AreaWeaponBehavior` devolviendo
N `Hit` (uno por enemigo alcanzado) produce exactamente el mismo
comportamiento en cascada sin ningún cambio: N `Result`, N emisiones de
`defender_attacked` (cada una con su propio sorteo de crítico independiente,
gracias a la branch anterior), y `BattleView` ya crea un `ProjectileView`
por cada una — el jugador va a ver varios proyectiles salir del mismo
defensor hacia distintos enemigos en el mismo instante, sin que nadie tenga
que programarlo especialmente.

### Cambio de arquetipo en el sandbox

En `main.gd`, las tres entradas de Artillero (`corner`, ranks 1/2/3) cambian
su `weapon_behavior` de `DoubleShotWeaponBehavior.new()` a
`AreaWeaponBehavior.new(radius)`. Radio sugerido: **60.0** (valor de
sandbox, ajustable) — con los goblins de sandbox spawneando cada 2 segundos
a velocidad 20, quedan espaciados en torno a 40 unidades de `path_progress`
entre sí mientras avanzan a la misma velocidad, así que un radio de 60
alcanza para agarrar al vecino más cercano de forma consistente y que el
efecto se note. Los valores de daño por rango (2/3/5) se mantienen sin
cambios — cambiar de dos impactos sobre un único objetivo a un impacto sobre
varios es un cambio de comportamiento intencional de esta branch (menos daño
concentrado, más daño repartido), no algo a compensar subiendo el daño base
todavía; es contenido de sandbox, ajustable después si hace falta.

## Cambios exactos por archivo

- **Nuevo** `Scripts/Gameplay/Combat/area_weapon_behavior.gd` (código exacto
  arriba).
- **`Scripts/Main/main.gd`**: en `_build_sandbox_defender_catalog()`,
  reemplazar `DoubleShotWeaponBehavior.new()` por
  `AreaWeaponBehavior.new(60.0)` en las tres entradas de `&"corner"`. Quitar
  el `const DoubleShotWeaponBehavior = preload(...)` si deja de usarse en
  el archivo (verificar); agregar el `const AreaWeaponBehavior =
  preload(...)` correspondiente.

## Call sites verificados que NO requieren cambios

`AttackPhase`, `CombatSimulation`, `BattleView`, `ProjectileView`: cero
cambios (razonamiento completo arriba, en Diseño). `WeaponData`,
`WeaponBehavior` (contrato base): cero cambios — `AreaWeaponBehavior` es
una subclase más, mismo punto de extensión que ya usaron
`SingleShotWeaponBehavior`/`DoubleShotWeaponBehavior`.
`DoubleShotWeaponBehavior` en sí (el archivo): cero cambios, sigue
existiendo y con sus tests intactos, solo deja de estar referenciada desde
`main.gd`.

## Tests nuevos a agregar

**`Tests/Gameplay/Combat/test_area_weapon_behavior.gd`** (nuevo archivo,
mismo estilo que `test_double_shot_weapon_behavior.gd`), registrar en
`Tests/test_runner.gd`:

1. Incluye siempre al objetivo prioritario (distancia 0 a sí mismo, para
   cualquier `radius >= 0`).
2. Incluye a otro enemigo vivo cuya distancia en `path_progress` al
   objetivo prioritario sea menor o igual al radio.
3. No incluye a un enemigo cuya distancia sea mayor al radio.
4. Un enemigo exactamente en el borde (`distancia == radius`) sí se
   incluye (el operador es `<=`, no `<`).
5. Ignora enemigos muertos aunque estén dentro del radio.
6. Cada `Hit` producido lleva el daño base completo, sin falloff por
   distancia (dos enemigos a distinta distancia dentro del radio reciben el
   mismo daño).

## Documentación a actualizar

- `README.md`: nota de diseño nueva en Combate (junto a las de
  `WeaponBehavior`/`SingleShotWeaponBehavior`/`DoubleShotWeaponBehavior`)
  explicando `AreaWeaponBehavior`, por qué el radio es en unidades de
  `path_progress` y no posición 2D, y por qué no hace falta tocar
  `AttackPhase`/`CombatSimulation`/`BattleView`. Actualizar la nota de
  arquetipos de sandbox (Bridge/`main.gd`) para reflejar que Artillero
  ahora usa `AreaWeaponBehavior` en vez de `DoubleShotWeaponBehavior`, y por
  qué (decisión de producto: hacer visible el área en el sandbox actual sin
  agregar un cuarto tipo de pieza).
- `TODO.md`: no tiene un ítem específico de daño de área; no requiere
  cambios.

## Definición de hecho

- Todos los tests existentes siguen pasando sin modificarse (los tests de
  `DoubleShotWeaponBehavior` en particular deben seguir en verde: la clase
  sigue existiendo, solo dejó de usarse en el sandbox).
- Los tests nuevos de esta branch pasan.
- `README.md` actualizado.
- Commit único.
- Verificación manual en el editor de Godot: colocar una pieza `corner`
  (Artillero), iniciar una wave con varios goblins en camino, y confirmar
  que cuando ataca, salen varios proyectiles hacia distintos enemigos
  cercanos en el mismo instante (no siempre — depende de qué tan juntos
  estén los enemigos en ese momento, pero con el radio sugerido debería
  notarse casi siempre que hay más de un goblin en la wave).

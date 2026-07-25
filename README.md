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

Incluye:

- ShapeData, InventoryPiece, InventoryGrid (dominio; sin dependencias de Godot)
- InventoryGridView, InventoryPieceView, InventoryGridBackground (representación visual reactiva a las señales del dominio)
- InventoryInteractionController (input de arrastre vía `_unhandled_input`; orquesta remove/can_place/place sobre InventoryGrid)
- InventoryDragGhostView (representación visual flotante mientras se arrastra una pieza; no depende de InventoryPiece, solo de ShapeData)
- InventorySandbox (proveedor temporal de una pieza de prueba ya colocada; placeholder a reemplazar por tienda/cofres/recompensas)
- Tests headless

#### Notas de diseño — interacción de inventario

- `InventoryGrid` sigue siendo la única autoridad: el drag se implementa como `remove_piece` al iniciar el arrastre + `place_piece` al soltar (válido o restaurando el ancla original). Esas dos llamadas están aisladas en métodos privados de `InventoryInteractionController` (`_take_piece_from_grid` / `_settle_piece_at`) para poder sustituirlas por un futuro `move_piece` atómico sin rediseñar el flujo.
- `InventoryGridView` e `InventoryPieceView` no se modificaron: la representación temporal del arrastre vive en la clase nueva `InventoryDragGhostView`, evitando forzar a `InventoryPieceView` a soportar geometría de una pieza no colocada.
- El punto exacto de la pieza donde el jugador hace clic se preserva durante todo el arrastre y se usa (en espacio de celdas, no de píxeles) para calcular el ancla final al soltar, de forma que la celda agarrada quede siempre bajo el cursor.
- `InventorySandbox` es intencionalmente mínimo (una pieza de prueba); no hay todavía un inventario de piezas disponibles para arrastrar hacia el grid.

### Próximo objetivo

Reemplazar `InventorySandbox` por una fuente real de piezas disponibles (inventario de piezas / draft) antes de encarar tienda, cofres o recompensas.
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

Incluye:

- ShapeData
- InventoryPiece
- InventoryGrid
- Tests headless

### Próximo objetivo

Visualización del inventario dentro de Godot.
# Proyecto

Juego 2D inspirado en Backpack Hero + Tower Defense + Merge.

## Objetivo

Desarrollar un MVP comercial.

## Reglas

- No modificar varios sistemas en una sola tarea.
- Explicar el plan antes de programar.
- Mantener bajo acoplamiento.
- No crear código muerto.
- No hacer optimizaciones prematuras.
- Preferir composición.
- Usar señales cuando sea posible.
- La lógica no debe depender de la UI.

## Ownership

InventoryPiece always has exactly one owner.

Possible owners:

- InventoryPieceSource
- InventoryGrid
- InventoryInteractionController (temporary during drag)

Ownership is transferred, never shared.
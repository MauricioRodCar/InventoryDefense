## Inventario

[x] Dominio del inventario
[x] Visualización básica
[x] Drag & drop
    - Piezas de prueba ofrecidas por InventoryPieceSourceSandbox, arrastrables hasta el grid.
[x] Preview de validez de colocación durante el arrastre (verde/rojo), vía InventoryPlacementPreviewView
[x] Fuente de piezas (InventoryPieceSource) desacoplada del inventario y del controller
[ ] TODO: arrastre desde InventoryPieceSource no preserva el punto exacto de agarre dentro de la pieza (siempre agarra la celda (0,0) de la forma); el drag desde el grid sí lo hace
[ ] Fuentes reales de piezas (tienda, cofres, recompensas, draft, crafting) sobre InventoryPieceSource
[ ] Rotación visual
[x] Fusión de piezas
[ ] Inventario durante partida

## Combate

[x] Dominio base (CombatPath, WeaponData, WeaponInstance, Enemy, Defender)
[x] CombatSimulation (MovementPhase + AttackPhase): simulación determinista headless vía advance(delta)
[ ] Wave: generación de enemigos a lo largo de una ronda
[ ] Integración con InventoryGrid (piezas colocadas -> Defender)
[ ] Representación visual / UI de combate
[ ] Animaciones
[x] Projectiles
[ ] Efectos de estado
[ ] Resistencias
[ ] Alcance
[ ] Recompensas
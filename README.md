# SpinDraw

Draw your own spinning top, pick how it moves, and watch it battle in a hexagon arena.
Godot 4 (4.3+), 2D, landscape 1280x720, pixel-art style.

## Run
1. Open Godot 4 -> Import -> select `project.godot`
2. Press F5

## How to play (Phase 2)
1. Draw in the green box (bigger = tanky and slow, smaller = fast glass cannon)
2. Pick an archetype: ATTACK / SPEED / DEFENSE
3. LOCK IN to the selected slot (P1 / P2). Tap a filled slot to edit it again
4. FIGHT! (an empty slot gets a random CPU top)

Keys: `R` rematch, `Esc` back, `P` toggle the pixel shader.

## Roadmap
- [x] Phase 1: drawing canvas, hull collider, stats from area, pixel look
- [x] Phase 2: hexagon arena, collision layers, movement AI (Attack / Speed / Defense)
- [ ] Phase 3: weapons (3a melee + status effects, 3b projectiles)
- [ ] Phase 4: match loop, HP bars, ultimates

## Physics layers
1 walls, 2 tops, 3 projectiles (see `scripts/game_const.gd`)

## Credits
Font: Press Start 2P (SIL OFL 1.1, see assets/fonts/OFL.txt). Palette: PICO-8.

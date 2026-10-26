class_name GameConst
extends RefCounted
## Shared numbers for the whole game. Change them here, nowhere else.

const MAX_SIZE := 640            # drawing box, in px
const GRID := 16                 # one "pixel" of the drawing, in px
const GRID_N := 40               # cells per side (MAX_SIZE / GRID)
const BATTLE_SCALE := 0.35       # tops are shrunk by this on the stage
const MIN_AREA := 768.0          # smaller than ~3 cells = too tiny to spawn
const AREA_REF := 204800.0       # hull area that counts as "huge" for stats
const SPIN_DIV := 8.0            # slows the visual spin (RPM -> rad/s)
const MAX_TOPS := 6              # oldest top is removed past this

# Physics layers (bit values). Names are set in project.godot.
const LAYER_WALLS := 1           # layer 1
const LAYER_TOPS := 2            # layer 2
const LAYER_PROJECTILES := 4     # layer 3 (used in Phase 3)

class_name GameConst
extends RefCounted
## Shared numbers for the whole game. Change them here, nowhere else.

const MAX_SIZE := 640            # drawing box, in px
const GRID := 16                 # one "pixel" of the drawing, in px
const GRID_N := 40               # cells per side (MAX_SIZE / GRID)
const BATTLE_SCALE := 0.35       # tops are shrunk by this in the arena
const MIN_AREA := 768.0          # smaller than ~3 cells = too tiny to spawn
const AREA_REF := 204800.0       # hull area that counts as "huge" for stats
const SPIN_DIV := 8.0            # slows the visual spin (RPM -> rad/s)

# ---- Physics layers (bit values). Names are set in project.godot.
const LAYER_WALLS := 1           # layer 1
const LAYER_TOPS := 2            # layer 2
const LAYER_PROJECTILES := 4     # layer 3 (used in Phase 3)

# What each thing COLLIDES WITH (its mask).
const MASK_TOP := LAYER_WALLS | LAYER_TOPS
const MASK_PROJECTILE := LAYER_WALLS | LAYER_TOPS   # bullets ignore other bullets

# ---- Arena
const ARENA_RADIUS := 400.0      # hexagon corner radius -> 693 px tall, fits 720

# ---- Movement archetypes (index = enum value)
enum Archetype { ATTACK, SPEED, DEFENSE }
const ARCH_NAMES := ["ATTACK", "SPEED", "DEFENSE"]
const ARCH_DESC := ["HUNTS DOWN THE ENEMY", "FAST, WILD RICOCHETS", "HOLDS THE CENTER, HARD TO PUSH"]
const ARCH_COLORS := [Pal.ORANGE, Pal.YELLOW, Pal.GREEN]
const ARCH_MASS_MULT := [1.0, 0.9, 2.0]     # Defense is much heavier
const ARCH_SPEED_MULT := [1.0, 1.1, 0.7]    # multiplies the size-based top speed
const ARCH_DAMP := [0.2, 0.0, 1.2]          # linear damping (Defense resists drifting)

# Body color of each player slot
const SLOT_COLORS := [Pal.RED, Pal.BLUE]

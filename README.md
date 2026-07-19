# Starter Game

A Godot 4 learning/prototype project: a third-person zombie character you control with WASD + mouse, collectible coins with a running score, and a sample modular city level built from Kenney's City Kit and Road Kit assets.

## Requirements

- Godot 4.5 (the project uses `config/features="4.5"`)

## Running it

Open the project in Godot and press **Play**. The main scene is set to `levels/level_city.tscn`.

> **Known issue:** the player currently gets stuck immediately on load in `level_city.tscn` (reported: character ends up pressed up against a building and can't move). This was mid-investigation when we paused - see "Known Issues" below before spending time on this level.
>
> `Main.tscn` (a simple flat grass field with a few coins) is unaffected and playable if you want to try the character/coins without the city level.

## Controls

| Input | Action |
|---|---|
| `W` `A` `S` `D` | Move (relative to where you're facing - full strafe/backpedal supported) |
| Mouse | Look around (rotates the character left/right, pitches the camera up/down) |
| `Shift` | Sprint (1.6x speed, animation speeds up to match) |
| `Space` / `Enter` | Jump |
| `Esc` | Toggle mouse capture (lets you get the cursor back, e.g. to alt-tab) |

Mouse is captured automatically on start.

## Project structure

```
zombie_character.tscn / .gd   - the player: movement, mouse-look, animation, HUD, chase camera
coin.tscn / .gd               - collectible coin (spins, bobs, adds to score on pickup)
score_manager.gd              - autoload singleton tracking the coin count (see project.godot [autoload])
score_label.gd                - HUD label that listens for score changes

Main.tscn                     - original simple test level (flat grass field + a few coins)
levels/
  level_city.tscn             - sample city level built on a GridMap
  city_mesh_library.tres      - MeshLibrary of city/road tiles used by that GridMap

tools/                        - one-off/reusable generator scripts, run via the Godot CLI (see below)

Assets/
  city/, roads/                - Kenney City Kit + Road Kit (CC0, see their License.txt)
  zombie/                       - zombie character model, skins, and animations
  grass/                        - grass ground texture

player.gd / player.tscn       - legacy placeholder box player from early in the project, unused
```

## The `tools/` scripts

These are small Godot scripts meant to be run from the command line (not from inside the editor) to generate or regenerate content. They're kept in the repo so the city level can be rebuilt or extended later without redoing this work by hand.

Run them from the project root:

```
"path/to/Godot.exe" --headless --script res://tools/<script>.gd
```

- **`build_city_mesh_library.gd`** - scans `Assets/city/Models/GLB format` and `Assets/roads/Models/GLB format` and builds `levels/city_mesh_library.tres`, one MeshLibrary item per GLB, with a box collision shape per item. The first 15 items keep fixed IDs (0-14) because `level_city.tscn`'s GridMap references them by number - add new tiles by extending the `ORIGINAL_TILES`/discovery logic rather than reordering.

- **`generate_mesh_library_previews.gd`** - renders a thumbnail for every MeshLibrary item so the GridMap palette dock shows real icons instead of blank tiles with just names. **Must run WITHOUT `--headless`** (it needs real GPU rendering):
  ```
  "path/to/Godot.exe" --script res://tools/generate_mesh_library_previews.gd
  ```
  Re-run this any time `build_city_mesh_library.gd` is re-run, since a freshly built library starts with no previews.

- **`build_level_city.gd`** - one-shot generator that assembled the original small sample `level_city.tscn` (road cross intersection, sidewalks, a handful of buildings, grass, lighting, the player, some coins). Not meant to be re-run now that the level has real hand-built content in it - it would overwrite the file from scratch.

- **`extend_city_grid.gd`** - re-run this any time you want to grow the hand-built road grid. It detects the grid's current extent from the crossroad tiles already placed, extends it by one more "ring" in each direction (matching the existing tile/orientation pattern), and fills every empty 3x3 block - old gaps and newly created ones - with a random building. Blocks that already have anything in them are left alone.

## Known issues

- **Player gets stuck in `level_city.tscn`.** Confirmed via testing that the character's collision capsule was reading back at full size (radius 0.4) instead of the scaled-down size `character_scale = 0.1` should produce, in this specific saved scene. Ruled out (reproduced in isolation without the bug): GridMap scale/complexity, tile-to-tile collision seams, the ground-plane/GridMap coincident surfaces, and buildings flanking the road corridor. Next step is checking whether repeatedly re-saving the scene via `PackedScene.pack()` (used by `extend_city_grid.gd`) is reintroducing a property-application-order issue similar to one fixed earlier (where a script's default value was overwriting a scale that should have applied first).
- The road-end caps and a few other directional pieces in `level_city.tscn` had their rotation guessed without being able to visually preview them - a piece or two may be facing the wrong way; nudge 90 degrees in the GridMap palette if so.
- `city_mesh_library.tres` and its previews are regenerated as binary/text resource files - if you edit tile placements a lot, expect large diffs in that file; that's normal.

## Asset credits

- **City Kit (Commercial)** and **City Kit (Roads)** by [Kenney](https://kenney.nl) - CC0. See `Assets/city/License.txt` and `Assets/roads/License.txt`.
- Zombie character model/animations and grass texture: included in `Assets/zombie/` and `Assets/grass/` without an accompanying license file - if you know the original source, it's worth adding one.

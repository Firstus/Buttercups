# AGENTS.md

Guidance for coding agents working in this repository.

## Project overview

"buttercups" is a 2D top-down game built with **Godot 4.7.2** and GDScript (no C# / GDExtension). The player is a ghost baker walking around a kitchen, cracking eggs, kneading dough, mixing ingredients and browsing the fridge for recipes.

Game flow: `scenes/intro/intro.tscn` (typewriter intro, the main scene) → switches to `scenes/kitchen/kitchen.tscn` (hub with the player and interaction stations) → mini-games at the fridge, kneading, mixing and egg-cracking stations.

There is no unit test suite and no CI. Verification means parse checks, headless scene runs and a manual play test in the editor.

## Engine and tooling

- Godot 4.7.2 stable, Forward+ renderer (D3D12 on Windows), 2D with `canvas_items` stretch mode.
- Editor binary, also configured for godot-tools in `.vscode/settings.json`:
  `C:\Users\Maxi\Downloads\Godot_v4.7.2\Godot_v4.7.2-stable_win64.exe`
- Use the **console** build in a terminal so stdout is captured:
  `C:\Users\Maxi\Downloads\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe`

All commands below assume the project directory as the working directory:

```powershell
$godot = "C:\Users\Maxi\Downloads\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe"
```

## Commands

```powershell
# Play the game (starts with the intro)
& $godot --path .

# Run a single scene (skips the intro), e.g. the kitchen hub
& $godot --path . --scene res://scenes/kitchen/kitchen.tscn

# Open the editor
& $godot --path . --editor

# Import new/changed assets without opening the editor
& $godot --path . --headless --import

# Parse-check one script (non-zero exit code on errors)
& $godot --path . --headless --check-only --script res://scenes/player/player.gd

# Parse-check every script
$root = (Resolve-Path .).Path
Get-ChildItem -Path $root -Recurse -Filter *.gd | Where-Object { $_.FullName -notmatch '\\\.godot\\' } | ForEach-Object {
  $rel = "res://" + $_.FullName.Substring($root.Length + 1).Replace("\", "/")
  & $godot --path $root --headless --check-only --script $rel
  if ($LASTEXITCODE -ne 0) { Write-Error "parse failed: $rel" }
}

# Headless smoke test: loads the scene and its scripts, runs 10 frames
& $godot --path . --headless --scene res://scenes/kitchen/kitchen.tscn --quit-after 10
```

Notes:

- `--headless` uses dummy display/audio and receives no input, so mini-games can only be exercised by actually playing a scene.
- While iterating on gameplay, run the kitchen scene directly to skip the intro.
- The project uses `uid://` references and `unique_id` attributes in scenes; let Godot write those and never hand-edit them.

## Project layout

```
project.godot                 # input map, rendering, main scene = intro
intro.gd                      # intro typewriter script (root, next to intro.tscn)
assets/                       # art and data resources
  Character/                  # player spritesheet (walkingcycle.png)
  Items/*.tres                # Item resources (Mehl, Ei, Butter, ...)
  Recipes/*.tres              # Recipe resources (Butterkeks, ...)
  Inventar.tscn               # inventory UI (not yet wired into any scene)
scripts/                      # shared classes: Item, Recipe, InventorySlot, inventar, SellBucked (stub)
scenes/
  intro/                      # typewriter intro -> switches to kitchen
  kitchen/                    # hub scene: player, camera, boundaries, stations
  player/                     # CharacterBody2D player + AnimatedSprite2D + collision
  fridge/                     # fridge Area2D + recipe menu UI
  knead/  mixing/  egg_cracking/  # mini-game stations
  oven/                       # timed bake station (Timer + spawned oven_clock.tscn)
  interaction_element/        # reusable glowing "interact" marker (shader + breathing tween)
```

## Architecture and conventions

- GDScript only, tab indentation, `snake_case` for variables/functions, `PascalCase` for `class_name` types, `_leading_underscore` for private members. Tunable values are `@export`s with `##` doc comments.
- Each scene keeps its script next to it (`scenes/<name>/<name>.gd` + `<name>.tscn`). Reusable data/UI classes live in `scripts/` (`Item`, `Recipe`, `InventorySlot`).
- No autoloads/singletons. Stations get the player either from the exported `player` NodePath wired in `kitchen.tscn` or via `get_tree().get_first_node_in_group("player")`. The player node is in the `player` group.
- Input actions are defined in `project.godot`: `player_left/right/up/down` (arrow keys), `action_command` (Space; interact/confirm/advance), `ui_cancel` (Escape; close menus).
- Interaction pattern: an `Area2D` tracks the player with `body_entered`/`body_exited` plus `is_in_group("player")`, shows a prompt label, Space starts the mini-game, `player.freeze()` runs while it is active, `player.unfreeze()` when it ends. Completion is reported through signals (`egg_cracked`, `knead_completed`, `mix_complete`, `recipe_selected`, `baking_finished`).
- `player.freeze()` stops movement and resets the walk animation to the idle frame; always pair it with `unfreeze()`. The oven is the exception: it is timer-based (a `Timer` node drives the countdown), never freezes the player, and spawns `scenes/oven/oven_clock.tscn` as a world-space indicator driven by `set_progress()` while the bake runs.
- Player animation is handled in `player.gd::_update_animation`: frame 0 while idle, the walk cycle while moving, `flip_h` when moving left. The scene node is named `Sprite2D` but is an `AnimatedSprite2D`.
- Items/recipes are custom `Resource`s (`scripts/Item.gd`, `scripts/Recipe.gd`) stored in `assets/Items` and `assets/Recipes`. The ingredients array is spelled `Recipe.incredients` (sic) and used everywhere. `fridge.gd` loads every `*.tres` in `assets/Recipes` at runtime.
- Mini-games read input in `_process`/`_unhandled_input`; hints use `RichTextLabel` BBCode (e.g. `[color=#8bc34a]`, `[b]`).
- Game text is a German/English mix: intro/story in German, mini-game UI in English. Keep files UTF-8 so umlauts survive.
- Never edit `.godot/` (generated, git-ignored). Commit `*.uid` and `*.import` sidecar files.
- Commit messages are short and plain (mostly lowercase, e.g. "player animation", "add fridge ui"); no prefixes or issue references.

## Known gaps

- Fridge contents and the recipe-unlock list are hardcoded placeholders in `scenes/fridge/fridge.gd` (see its TODOs); selecting a recipe only shows details and does not craft anything yet.
- `scenes/mixing/mixing.gd` does not put the mixed result into the inventory yet, and the oven's finished bake is not handed to any crafting/inventory system.
- The inventory (`assets/Inventar.tscn`, `scripts/inventar.gd`) is not instanced in the kitchen yet.
- `scripts/SellBucked.gd` and `scenes/egg_cracking/area_2d.gd` are empty stubs.

# Fenceward

A 2D landscape mobile tower-defense game for Android, built in Godot 4.4 (GDScript).

Defend a wooden fence across 5 lanes using a squad of up to 5 collected,
levelable, evolvable monsters. Catch new monsters with Balls, farm dungeons
for evolution materials, and fight a World Boss for rare rewards.

## On the name

This project was originally scoped against a doc modeled on an existing,
actively-maintained Roblox game called "Catch a Monster" (117+ monsters,
E–SS rank tiers, an active fan wiki/Discord). This project is **not** that
game, reskinned — it's a different genre (tower defense vs. auto-battler/
collector) with its own name, its own roster, and its own systems. If you're
iterating on this further, keep it that way: don't rename it back, and don't
match roster size or terminology closely enough to read as a copy.

Everything else — the fence/lane mechanic, evolution, rank fragments, the
World Boss chest table — is original design from the spec and is yours to
extend freely.

## Project structure

```
scenes/
  battle/       BattleArena.tscn (the one reusable battle scene) + Enemy.tscn, Lane.tscn
  menus/        Main menu, squad builder, stage/dungeon select, shop
  ui/           HUD, chest reward popup, monster cards
resources/
  monsters/     MonsterData .tres files — the whole roster lives here, data-driven
  battle_configs/  BattleConfig .tres files for each Stage/Dungeon/World Boss
scripts/
  autoload/     GameState, SaveSystem, MonsterDB (registered in project.godot)
  battle/       BattleArena, Lane, Enemy, BattleMonster runtime logic
  data/         Resource class definitions (MonsterData, MonsterInstance, BattleConfig, WaveDefinition)
```

## What's scaffolded vs. what you still need to do

**Scaffolded (this commit):**
- Full data-driven monster schema + 6 sample species (Emberpup, Pebblit, Driftail, Sparkit, Gustling, Glimmox)
- GameState/SaveSystem/MonsterDB autoloads with JSON persistence
- BattleArena core loop: lane engagement rule, wave spawning, enemy archetypes
  (Walker/Rusher/Tank/Ranged/Mini-boss), World Boss mode (time limit, chest table),
  skill system (5 skill types), 3-star reward tracking
- Android export preset (`Android`, arm64-v8a, Gradle build enabled)
- GitHub Actions CI: builds signed AAB + debug APK, tags trigger a Release

**You still need to (can't be scaffolded sight-unseen):**
- Build the actual `.tscn` scene files in the Godot editor (node trees, sprites,
  UI layout) — the scripts above are ready to attach to nodes, but scenes
  need visual assembly in-editor
- Add `min_sdk`/`target_sdk` — these aren't in `export_presets.cfg` in Godot 4.4;
  they're set via **Project → Export → Android preset → Advanced → Manifest**,
  or by editing the generated `AndroidManifest.xml` template after a "Custom
  build" export. Set min SDK 24, target SDK 36 there.
- Generate your own upload keystore (`keytool -genkey -v -keystore release.keystore
  -alias upload -keyalg RSA -keysize 2048 -validity 10000`) and add the three
  repo secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
- Replace `com.yourstudio.fenceward` with your real package identifier before
  first release (can't change after)
- Art: all monsters currently have no sprites assigned (`evolution_sprites` is empty)
- Balance pass: every number here (stats, wave counts, chest odds) is a starting point

## Architecture note

`BattleArena` is a single reusable scene. `Enemy` and `BattleMonster` look it
up at runtime via `get_tree().get_first_node_in_group("battle_arena")` rather
than treating it as an autoload — a scene can have multiple potential battle
scenes loaded in memory (menus, previews) but only one active fight, so a true
global singleton would be wrong here. Make sure `BattleArena.tscn`'s root node
has this script attached; `_ready()` adds it to the group automatically.

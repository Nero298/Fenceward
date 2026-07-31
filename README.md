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
- **Complete, wired scene flow**: Main Menu → Squad Builder, Stage Select,
  Dungeon Select, World Boss (squad-gated ≥4), Shop, Settings — every button
  is connected to a real handler, no dead links
- **Playable content**: 3 stages, all 3 dungeon types (Evolution/Gold/Ball),
  1 World Boss config, all cross-checked so every node path a script
  references actually exists in its `.tscn`
- Android export preset (`Android`, arm64-v8a, Gradle build enabled)
- GitHub Actions CI: builds signed AAB + debug APK, tags trigger a Release

**You still need to:**
- Open it in Godot 4.4 and let the editor re-save the `.tscn`/`.tres` files at
  least once — these were hand-written as plain text (no Godot instance was
  available to author them interactively), so while every reference has been
  manually cross-checked, only the editor's own parser can catch subtle
  formatting issues text inspection can't
- Add more stages (spec suggests 8–12; only 3 exist) and a weekly rotating
  Elemental Dungeon (the `favored_element` field exists on BattleConfig but
  no dungeon sets it yet)
- Add `min_sdk`/`target_sdk` — these aren't in `export_presets.cfg` in Godot 4.4;
  set via **Project → Export → Android preset → Advanced → Manifest**. Use
  min SDK 24, target SDK 36
- Generate your own upload keystore (`keytool -genkey -v -keystore release.keystore
  -alias upload -keyalg RSA -keysize 2048 -validity 10000`) and add the three
  repo secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
- Replace `com.yourstudio.fenceward` with your real package identifier before
  first release (can't change after)
- Art: everything is colored rectangles right now — no sprites anywhere
- Real drag-and-drop in Squad Builder (currently tap-a-slot-then-tap-a-monster)
- Balance pass: every number here (stats, wave counts, chest odds) is a starting point
- The World Boss config currently reuses `emberpup` as a placeholder reward
  species — the spec implies a unique boss-exclusive monster; add one when
  the roster grows

## Architecture note

`BattleArena` is a single reusable scene. `Enemy` and `BattleMonster` look it
up at runtime via `get_tree().get_first_node_in_group("battle_arena")` rather
than treating it as an autoload — a scene can have multiple potential battle
scenes loaded in memory (menus, previews) but only one active fight, so a true
global singleton would be wrong here. Make sure `BattleArena.tscn`'s root node
has this script attached; `_ready()` adds it to the group automatically.

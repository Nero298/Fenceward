extends Control

## Dungeon Select: Evolution / Gold / Ball dungeons, each with limited free
## entries per day (GameState.dungeon_free_entries_today), refillable with Balls.

const DUNGEON_CONFIG_PATH := "res://resources/battle_configs/dungeons/"
const REFILL_BALL_COST := 10

@onready var dungeon_list: ItemList = $DungeonList
@onready var entries_label: Label = $EntriesLabel
@onready var back_button: Button = $BackButton

var _configs: Array[BattleConfig] = []
var _dungeon_keys: Array[String] = [] # matches GameState.dungeon_free_entries_today keys, inferred from filename

func _ready() -> void:
	_load_dungeon_configs()
	dungeon_list.item_activated.connect(_on_dungeon_activated)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	_refresh_entries_label()

func _load_dungeon_configs() -> void:
	_configs.clear()
	_dungeon_keys.clear()
	dungeon_list.clear()
	var dir := DirAccess.open(DUNGEON_CONFIG_PATH)
	if dir == null:
		dungeon_list.add_item("(No dungeons configured yet — add .tres files to %s)" % DUNGEON_CONFIG_PATH)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var cfg: BattleConfig = load(DUNGEON_CONFIG_PATH + file_name)
			_configs.append(cfg)
			var key := file_name.get_basename().to_lower() # e.g. "evolution", "gold", "ball"
			_dungeon_keys.append(key)
			var free_left: int = GameState.dungeon_free_entries_today.get(key, 0)
			dungeon_list.add_item("%s (Free entries left: %d)" % [cfg.display_name, free_left])
		file_name = dir.get_next()
	dir.list_dir_end()

func _refresh_entries_label() -> void:
	entries_label.text = "Free entries refresh daily. Out of free entries? Refill with %d Balls." % REFILL_BALL_COST

func _on_dungeon_activated(index: int) -> void:
	if index < 0 or index >= _configs.size():
		return
	var key := _dungeon_keys[index]
	var free_left: int = GameState.dungeon_free_entries_today.get(key, 0)
	if free_left <= 0:
		if not GameState.spend_balls(REFILL_BALL_COST):
			return # not enough balls to refill; stay on this screen
	else:
		GameState.dungeon_free_entries_today[key] = free_left - 1

	var battle_scene: PackedScene = load("res://scenes/battle/battle_arena.tscn")
	var arena := battle_scene.instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = arena
	arena.start_battle(_configs[index])

extends Control

## Stage Select: lists available BattleConfig .tres resources from
## resources/battle_configs/stages/ and, on selection, instances BattleArena
## with that config — the same reusable scene Dungeons and World Boss use.

const STAGE_CONFIG_PATH := "res://resources/battle_configs/stages/"

@onready var stage_list: ItemList = $StageList
@onready var back_button: Button = $BackButton

var _configs: Array[BattleConfig] = []

func _ready() -> void:
	_load_stage_configs()
	stage_list.item_activated.connect(_on_stage_activated)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))

func _load_stage_configs() -> void:
	_configs.clear()
	stage_list.clear()
	var dir := DirAccess.open(STAGE_CONFIG_PATH)
	if dir == null:
		stage_list.add_item("(No stages configured yet — add .tres files to %s)" % STAGE_CONFIG_PATH)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var cfg: BattleConfig = load(STAGE_CONFIG_PATH + file_name)
			_configs.append(cfg)
			stage_list.add_item(cfg.display_name if cfg.display_name != "" else file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_stage_activated(index: int) -> void:
	if index < 0 or index >= _configs.size():
		return
	var battle_scene: PackedScene = load("res://scenes/battle/battle_arena.tscn")
	var arena := battle_scene.instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = arena
	arena.start_battle(_configs[index])

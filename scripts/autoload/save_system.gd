extends Node

## Autoload singleton: SaveSystem
## Serializes GameState to user://save.json and back. Simple JSON, no cloud sync
## (see design notes: offline-first, cloud saves are an additive layer later).

const SAVE_PATH := "user://save.json"

func save_game() -> bool:
	var data := GameState.to_dict()
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing: %s" % FileAccess.get_open_error())
		return false
	file.store_string(json_string)
	file.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: could not open save file for reading: %s" % FileAccess.get_open_error())
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SaveSystem: save file JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false
	GameState.load_from_dict(json.data)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

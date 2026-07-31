extends Node

## Autoload singleton: MonsterDB
## Loads every MonsterData .tres in resources/monsters/ at startup and exposes
## lookup by species_id. This is what makes the roster fully data-driven —
## add a new .tres file and it's in the game, no code changes.

const ROSTER_PATH := "res://resources/monsters/"

var _species: Dictionary = {} # species_id -> MonsterData

func _ready() -> void:
	_load_roster()

func _load_roster() -> void:
	_species.clear()
	var dir := DirAccess.open(ROSTER_PATH)
	if dir == null:
		push_warning("MonsterDB: roster folder not found at %s" % ROSTER_PATH)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(ROSTER_PATH + file_name)
			if res is MonsterData:
				if res.species_id == "":
					push_warning("MonsterDB: %s has empty species_id, skipping" % file_name)
				else:
					_species[res.species_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_species(species_id: String) -> MonsterData:
	return _species.get(species_id, null)

func get_all_species() -> Array[MonsterData]:
	var result: Array[MonsterData] = []
	for key in _species.keys():
		result.append(_species[key])
	return result

func get_all_species_ids() -> Array:
	return _species.keys()

func get_random_species_id(rarity_filter: String = "") -> String:
	var candidates: Array = []
	for id in _species.keys():
		if rarity_filter == "" or _species[id].rarity == rarity_filter:
			candidates.append(id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]

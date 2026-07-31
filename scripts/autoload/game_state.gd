extends Node

## Autoload singleton: GameState
## Central source of truth for the player's persistent progress.
## Battle-scene code reads/writes here; SaveSystem serializes this to disk.

signal currency_changed
signal collection_changed
signal squad_changed

var money: int = 500
var balls: int = 10

var materials: Dictionary = {}      # material_id (String) -> count (int)
var collection: Array[MonsterInstance] = []   # every monster ever owned
var squad_instance_ids: Array[String] = ["", "", "", "", ""] # 5 lane slots, "" = empty

var unlocked_stage_index: int = 0
var dungeon_free_entries_today: Dictionary = {"evolution": 3, "gold": 3, "ball": 3}
var last_daily_reset_day: int = -1

var world_boss_daily_tickets: int = 1

func _ready() -> void:
	_maybe_reset_daily()

func _maybe_reset_daily() -> void:
	var today := Time.get_date_dict_from_system().get("day", 0) + Time.get_date_dict_from_system().get("month", 0) * 31
	if today != last_daily_reset_day:
		dungeon_free_entries_today = {"evolution": 3, "gold": 3, "ball": 3}
		world_boss_daily_tickets = 1
		last_daily_reset_day = today

# ---- Currency ----

func add_money(amount: int) -> void:
	money += amount
	currency_changed.emit()

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	currency_changed.emit()
	return true

func add_balls(amount: int) -> void:
	balls += amount
	currency_changed.emit()

func spend_balls(amount: int) -> bool:
	if balls < amount:
		return false
	balls -= amount
	currency_changed.emit()
	return true

func get_material_count(material_id: String) -> int:
	return materials.get(material_id, 0)

func add_material(material_id: String, amount: int) -> void:
	materials[material_id] = get_material_count(material_id) + amount
	currency_changed.emit()

func spend_material(material_id: String, amount: int) -> bool:
	if get_material_count(material_id) < amount:
		return false
	materials[material_id] -= amount
	currency_changed.emit()
	return true

# ---- Collection / Squad ----

func add_monster(species_id: String, level: int = 1) -> MonsterInstance:
	var m := MonsterInstance.new()
	m.instance_id = _generate_instance_id()
	m.species_id = species_id
	m.level = level
	# Duplicate handling: if already owned, convert this catch into rank fragments instead.
	var existing := find_owned_of_species(species_id)
	if existing != null:
		existing.fragments += 1
		collection_changed.emit()
		return existing
	collection.append(m)
	collection_changed.emit()
	return m

func find_owned_of_species(species_id: String) -> MonsterInstance:
	for m in collection:
		if m.species_id == species_id:
			return m
	return null

func find_instance(instance_id: String) -> MonsterInstance:
	for m in collection:
		if m.instance_id == instance_id:
			return m
	return null

func set_squad_slot(lane_index: int, instance_id: String) -> void:
	if lane_index < 0 or lane_index >= squad_instance_ids.size():
		return
	squad_instance_ids[lane_index] = instance_id
	squad_changed.emit()

func get_squad_monsters() -> Array[MonsterInstance]:
	var result: Array[MonsterInstance] = []
	for id in squad_instance_ids:
		if id != "":
			var m := find_instance(id)
			if m != null:
				result.append(m)
	return result

func squad_size() -> int:
	return get_squad_monsters().size()

func _generate_instance_id() -> String:
	return str(Time.get_ticks_usec()) + "_" + str(randi())

# ---- Serialization ----

func to_dict() -> Dictionary:
	var collection_data: Array = []
	for m in collection:
		collection_data.append(m.to_dict())
	return {
		"money": money,
		"balls": balls,
		"materials": materials,
		"collection": collection_data,
		"squad_instance_ids": squad_instance_ids,
		"unlocked_stage_index": unlocked_stage_index,
		"dungeon_free_entries_today": dungeon_free_entries_today,
		"last_daily_reset_day": last_daily_reset_day,
		"world_boss_daily_tickets": world_boss_daily_tickets,
	}

func load_from_dict(d: Dictionary) -> void:
	money = d.get("money", 500)
	balls = d.get("balls", 10)
	materials = d.get("materials", {})
	collection.clear()
	for entry in d.get("collection", []):
		collection.append(MonsterInstance.from_dict(entry))
	squad_instance_ids = d.get("squad_instance_ids", ["", "", "", "", ""])
	unlocked_stage_index = d.get("unlocked_stage_index", 0)
	dungeon_free_entries_today = d.get("dungeon_free_entries_today", {"evolution": 3, "gold": 3, "ball": 3})
	last_daily_reset_day = d.get("last_daily_reset_day", -1)
	world_boss_daily_tickets = d.get("world_boss_daily_tickets", 1)
	currency_changed.emit()
	collection_changed.emit()
	squad_changed.emit()

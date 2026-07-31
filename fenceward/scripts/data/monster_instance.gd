extends RefCounted
class_name MonsterInstance

## A single owned monster: species + progression state. Not a Resource — this is
## per-save runtime data, serialized to/from Dictionary for JSON persistence.

var instance_id: String       # unique per catch/summon, generated at creation
var species_id: String
var level: int = 1
var evolution_stage: int = 0
var rank_index: int = 0       # 0=E, 1=D, 2=C, 3=B, 4=A, 5=S
var xp: int = 0
var fragments: int = 0

var current_hp: int = 0       # runtime-only during battle, not persisted meaningfully beyond max

func get_data() -> MonsterData:
	return MonsterDB.get_species(species_id)

func get_stats() -> Dictionary:
	var data := get_data()
	if data == null:
		return {"hp": 1, "atk": 1, "def": 1, "spd": 1}
	return data.get_stat_at(level, evolution_stage, rank_index)

func can_evolve() -> bool:
	var data := get_data()
	if data == null:
		return false
	if evolution_stage >= data.evolution_names.size() - 1:
		return false
	var max_lvl := data.evolution_max_level[evolution_stage]
	if level < max_lvl:
		return false
	var mat_id: String = data.evolution_material_id[evolution_stage] if evolution_stage < data.evolution_material_id.size() else ""
	if mat_id != "" and GameState.get_material_count(mat_id) <= 0:
		return false
	var cost: int = data.evolution_money_cost[evolution_stage] if evolution_stage < data.evolution_money_cost.size() else 0
	if GameState.money < cost:
		return false
	return true

func evolve() -> bool:
	if not can_evolve():
		return false
	var data := get_data()
	var mat_id: String = data.evolution_material_id[evolution_stage] if evolution_stage < data.evolution_material_id.size() else ""
	var cost: int = data.evolution_money_cost[evolution_stage] if evolution_stage < data.evolution_money_cost.size() else 0
	if mat_id != "":
		GameState.spend_material(mat_id, 1)
	GameState.spend_money(cost)
	evolution_stage += 1
	return true

func can_rank_up() -> bool:
	if rank_index >= 5:
		return false
	var data := get_data()
	if data == null:
		return false
	var needed: int = data.rank_fragments_required[rank_index]
	return fragments >= needed

func rank_up() -> bool:
	if not can_rank_up():
		return false
	var data := get_data()
	var needed: int = data.rank_fragments_required[rank_index]
	fragments -= needed
	rank_index += 1
	return true

func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"species_id": species_id,
		"level": level,
		"evolution_stage": evolution_stage,
		"rank_index": rank_index,
		"xp": xp,
		"fragments": fragments,
	}

static func from_dict(d: Dictionary) -> MonsterInstance:
	var m := MonsterInstance.new()
	m.instance_id = d.get("instance_id", "")
	m.species_id = d.get("species_id", "")
	m.level = d.get("level", 1)
	m.evolution_stage = d.get("evolution_stage", 0)
	m.rank_index = d.get("rank_index", 0)
	m.xp = d.get("xp", 0)
	m.fragments = d.get("fragments", 0)
	return m

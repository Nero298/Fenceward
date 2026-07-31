extends Resource
class_name MonsterData

## Data-driven definition for a monster species.
## One .tres resource per species; the roster is a folder of these, not hardcoded logic.

@export var species_id: String = ""
@export var display_name: String = ""
@export var element: String = "Neutral" # Fire, Water, Earth, Electric, Wind, Light, Dark, Neutral
@export var rarity: String = "Common"   # Common, Rare, Epic, Legendary

## Evolution chain: array of stage names, e.g. ["Emberpup", "Cinderfang", "Infernus"]
## evolution_stage index (0-based) selects into this array for display + sprite lookup.
@export var evolution_names: Array[String] = []
@export var evolution_sprites: Array[Texture2D] = []
@export var evolution_max_level: Array[int] = [15, 30, 999] # level cap per stage before evolution is possible

## Base stats at Stage 1, Level 1, Rank E. Everything else is derived from these.
@export var base_hp: int = 300
@export var base_atk: int = 40
@export var base_def: int = 20
@export var base_spd: int = 100

## Per-level growth (flat additive per level, simplest curve — tune later)
@export var hp_per_level: float = 12.0
@export var atk_per_level: float = 2.0
@export var def_per_level: float = 1.0
@export var spd_per_level: float = 0.5

## Stat multiplier gained per evolution stage (applied on top of level scaling)
@export var evolution_stat_multiplier: float = 1.35

## Active skill (player-triggered, on cooldown)
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_cooldown_seconds: float = 8.0
@export var skill_type: String = "single_target" # single_target, aoe_lane, aoe_adjacent, heal_fence, slow, buff_def

## Evolution material required to advance past each stage (resource id string, or "" if final stage)
@export var evolution_material_id: Array[String] = []
@export var evolution_money_cost: Array[int] = [500, 2500]

## Rank fragment requirements to advance E->D->C->B->A->S (index 0 = frags needed for D, etc.)
@export var rank_fragments_required: Array[int] = [5, 10, 20, 40, 80]
@export var rank_stat_multiplier: Array[float] = [1.0, 1.15, 1.32, 1.52, 1.75, 2.0] # E,D,C,B,A,S

func get_stage_name(evolution_stage: int) -> String:
	if evolution_stage >= 0 and evolution_stage < evolution_names.size():
		return evolution_names[evolution_stage]
	return display_name

func get_stat_at(level: int, evolution_stage: int, rank_index: int) -> Dictionary:
	var evo_mult := pow(evolution_stat_multiplier, evolution_stage)
	var rank_mult := 1.0
	if rank_index >= 0 and rank_index < rank_stat_multiplier.size():
		rank_mult = rank_stat_multiplier[rank_index]
	var total_mult := evo_mult * rank_mult
	return {
		"hp": int((base_hp + hp_per_level * (level - 1)) * total_mult),
		"atk": int((base_atk + atk_per_level * (level - 1)) * total_mult),
		"def": int((base_def + def_per_level * (level - 1)) * total_mult),
		"spd": int((base_spd + spd_per_level * (level - 1)) * total_mult),
	}

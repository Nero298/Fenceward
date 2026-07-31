extends Resource
class_name BattleConfig

## Drives the one reusable BattleArena scene. Stages, Dungeons, and the World Boss
## all instance BattleArena with a different BattleConfig — never fork the scene.

@export var config_id: String = ""
@export var display_name: String = ""

@export var is_boss_fight: bool = false
@export var min_squad_size: int = 1 # World Boss sets this to 4

## Standard wave-based fight (Stage / Dungeon)
@export var wave_definitions: Array[WaveDefinition] = []

## Boss fight fields (used when is_boss_fight == true)
@export var boss_species_id: String = ""
@export var boss_level: int = 1
@export var boss_hp_pool: int = 50000
@export var boss_time_limit_seconds: float = 120.0
@export var boss_special_attack_interval: float = 15.0

## Rewards
@export var reward_money: int = 100
@export var reward_xp: int = 50
@export var reward_ball_chance: float = 0.15
@export var reward_material_id: String = ""
@export var reward_material_amount: int = 0
@export var three_star_money_bonus_mult: float = 1.5

## Dungeon-only: element that gets bonus this rotation ("" = no bonus active)
@export var favored_element: String = ""
@export var favored_element_bonus_mult: float = 1.25

## World Boss chest weighted table: array of {type, weight, payload}
@export var chest_table: Array[Dictionary] = [
	{"type": "balls", "weight": 70, "amount": 20},
	{"type": "money", "weight": 25, "amount": 5000},
	{"type": "monster", "weight": 5, "species_id": ""},
]

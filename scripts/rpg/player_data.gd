extends Resource
class_name PlayerData
## The player's authoritative stat/equipment/inventory block. Owned by
## Agent 3 (RPG/Gear). See GAME_DESIGN.md Section 10 and
## AGENT_CONTRACTS.md.

@export var level: int = 1
@export var xp: int = 0
@export var max_hp: int = 20
@export var hp: int = 20
@export var max_mp: int = 10
@export var mp: int = 10
@export var attack: int = 5
@export var defense: int = 3
@export var magic_power: int = 2
@export var speed: int = 5
@export var gold: int = 0

@export var equipped_weapon: EquipmentData = null
@export var equipped_armor: EquipmentData = null
@export var equipped_accessory: EquipmentData = null
@export var inventory: Array[ItemData] = []
